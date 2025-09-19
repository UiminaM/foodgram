from django.contrib.auth.models import AbstractUser
from django.core import validators
from django.db import models
from django.dispatch import receiver
from recipes.models import Recipe


class User(AbstractUser):
    email = models.EmailField(
        unique=True,
        max_length=254,
        verbose_name="Почта",
    )
    username = models.CharField(
        unique=True,
        max_length=150,
        validators=[
            validators.RegexValidator(
                regex=r"^[\w\.@+-]+\Z",
            )
        ],
        verbose_name="Имя пользователя",
    )
    first_name = models.CharField(
        max_length=150,
        verbose_name="Имя",
    )
    last_name = models.CharField(
        max_length=150,
        verbose_name="Фамилия",
    )
    avatar = models.ImageField(
        upload_to="users/avatars/",
        null=True,
        blank=True,
        verbose_name="Аватар",
    )
    is_subscribed = models.BooleanField(
        default=False,
        verbose_name="Подписан",
    )
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username",
                       "first_name",
                       "last_name",
                       "is_subscribed",
                       "avatar"
                       ]

    groups = models.ManyToManyField(
        "auth.Group", related_name="custom_user_set", blank=True
    )
    user_permissions = models.ManyToManyField(
        "auth.Permission",
        related_name="custom_user_permissions_set",
        blank=True
    )

    class Meta:
        verbose_name = "пользователь"
        verbose_name_plural = "Пользователи"

    def __str__(self):
        return self.username


class Follow(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name="Пользователь",
        related_name="follower",
    )
    following = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name="Подписки",
        related_name="following",
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "following"],
                name="unique_user_following"
            )
        ]
        verbose_name = "подписка"
        verbose_name_plural = "Подписки"


class Favourite(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="favourites",
        verbose_name="Пользователь",
    )
    recipe = models.ForeignKey(
        Recipe,
        on_delete=models.CASCADE,
        related_name="in_favourites",
        verbose_name="Рецепт",
    )

    class Meta:
        verbose_name = "избранное"
        verbose_name_plural = "Избранное"


@receiver(models.signals.post_save, sender=Favourite)
def update_recipe_favorite_status(sender, instance, created, **kwargs):
    if created:
        instance.recipe.is_favorited = True
        instance.recipe.save()


@receiver(models.signals.post_save, sender=Favourite)
def update_recipe_unfavourite_status(sender, instance, created, **kwargs):
    if created:
        instance.recipe.is_favorited = Favourite.objects.filter(
            recipe=instance.recipe
        ).exists()
        instance.recipe.save()


class ShoppingCart(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="shopping_carts",
        verbose_name="Пользователь",
    )
    recipe = models.ForeignKey(
        Recipe,
        on_delete=models.CASCADE,
        related_name="in_shopping_carts",
        verbose_name="Рецепт",
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "recipe"], name="unique_user_recipe"
            )
        ]
        verbose_name = "список покупок"
        verbose_name_plural = "Список покупок"
