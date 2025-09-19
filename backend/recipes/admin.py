from django.contrib import admin
from .models import Ingredient, Recipe, RecipeIngredient


class IngredientAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "measurement_unit",
    )
    list_display_links = ("name",)
    list_editable = ("measurement_unit",)
    search_fields = ("name",)


class RecipeAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "author",
    )
    list_display_links = ("name",)
    list_editable = ("author",)
    search_fields = (
        "name",
        "author__email",
    )
    readonly_fields = ("get_favorite_count",)

    def get_favorite_count(self, obj):
        return obj.in_favourites.count()

    get_favorite_count.short_description = "Добавлений в избранное"


admin.site.register(Ingredient, IngredientAdmin)
admin.site.register(Recipe, RecipeAdmin)
admin.site.register(RecipeIngredient)
