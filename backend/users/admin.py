from django.contrib import admin
from .models import User, Follow, Favourite, ShoppingCart


class UserAdmin(admin.ModelAdmin):
    search_fields = ("email", "username")
    list_display = (
        "email",
        "username",
        "first_name",
        "last_name",
        "avatar",
        "is_subscribed",
    )
    list_display_links = ("email",)
    list_editable = (
        "username",
        "first_name",
        "last_name",
        "avatar",
        "is_subscribed",
    )


class FollowAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "following",
    )
    list_display_links = ("user",)
    list_editable = ("following",)


class ShoppingCartAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "recipe",
    )
    list_display_links = ("user",)
    list_editable = ("recipe",)


class FavouriteAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "recipe",
    )
    list_display_links = ("user",)
    list_editable = ("recipe",)


admin.site.register(User, UserAdmin)
admin.site.register(Follow, FollowAdmin)
admin.site.register(Favourite, FavouriteAdmin)
admin.site.register(ShoppingCart, ShoppingCartAdmin)
