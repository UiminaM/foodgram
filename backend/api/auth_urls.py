from django.urls import path, include
from django.views.generic import TemplateView


urlpatterns = [
    path('accounts/', include('allauth.urls')),
    path(
        "github-login/",
        TemplateView.as_view(template_name="oauth_forms/github_login.html"),
        name="github_login_page"
    ),
]