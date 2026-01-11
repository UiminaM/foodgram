from rest_framework.response import Response
from services.cache import cache
from urllib.parse import urlencode


def make_cache_key(prefix: str, **params) -> str:
    if not params:
        return prefix
    sorted_params = sorted(params.items())
    query_string = urlencode(sorted_params)
    return f"sql|{prefix}:{query_string}"


class CachedSQL:
    cache_prefix = None
    cache_ttl = 3600

    def list(self, request, *args, **kwargs):
        cache_key = make_cache_key(
            self.cache_prefix,
            **request.query_params.dict()
        )

        if cache.exists(cache_key):
            return Response(cache.get_data(cache_key))

        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            cache.r.json().set(name=cache_key, path="$", obj=response.data)
            cache.r.expire(cache_key, self.cache_ttl)
            return response

        serializer = self.get_serializer(queryset, many=True)
        cache.r.json().set(name=cache_key, path="$", obj=serializer.data)
        cache.r.expire(cache_key, self.cache_ttl)
        return Response(serializer.data)