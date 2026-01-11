import os
from typing import Optional, Union
import redis

from services.redis import get_redis_client


JsonValue = Union[dict, list[dict]]

class CacheManager:
    DEFAULT_TTL = int(os.getenv("DEFAULT_CACHE_TTL", str(60 * 60)))

    def __init__(self):
        self.r: redis.Redis = get_redis_client()

    def exists(self, key: str) -> bool:
        return self.r.exists(key) == 1

    def get_data(self, key: str):
        return self.r.json().get(key)

    def set_data(self, key: str, data: JsonValue, ttl: int = DEFAULT_TTL) -> bool:
        if self.exists(key):
            return False
        self.r.json().set(name=key, path="$", obj=data)
        self.r.expire(key, int(ttl))
        return True


cache = CacheManager()
