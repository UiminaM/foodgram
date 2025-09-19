from django.db import migrations


def is_valid_slug(slug):
    if not slug:
        return False
    return not slug.startswith("-") and "-" in slug


def fix_slugs(apps, schema_editor):
    Recipe = apps.get_model("recipes", "Recipe")
    for recipe in Recipe.objects.all():
        if not is_valid_slug(recipe.slug):
            import uuid
            from django.utils.text import slugify

            base_slug = slugify(recipe.name)
            if not base_slug:
                base_slug = "recipe"

            unique_suffix = str(uuid.uuid4())[:8]
            new_slug = f"{base_slug}-{unique_suffix}".strip("-")

            if not new_slug:
                new_slug = f"recipe-{unique_suffix}"

            recipe.slug = new_slug
            recipe.save(update_fields=["slug"])


class Migration(migrations.Migration):
    dependencies = [
        ("recipes", "0006_recipeingredient_amount"),
    ]
    operations = [
        migrations.RunPython(fix_slugs),
    ]
