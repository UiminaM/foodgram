from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin


urlpatterns = [
    path("api/", include("api.urls", namespace="api")),
    path("admin/", admin.site.urls),
    path("api/", include('api.auth_urls')),
]


if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )
