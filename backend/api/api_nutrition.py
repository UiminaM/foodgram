import requests
import os
from services.cache import cache

NUTRIENTS = {
    "ENERC_KCAL": "Калории",
    "PROCNT": "Белок",
    "FAT": "Жиры",
    "CHOCDF": "Углеводы",
    "FIBTG": "Клетчатка",
    "SUGAR": "Сахара",
}


def analyze_nutrition_by_ingredients(app_id: str, app_key: str, ingredients: list[str]) -> dict:
    url = "https://api.edamam.com/api/nutrition-details"
    params = {
        "app_id": app_id,
        "app_key": app_key,
    }
    payload = {
        "ingr": ingredients
    }

    response = requests.post(url, params=params, json=payload)
    response.raise_for_status()
    data = response.json()
    
    return data


def get_product_nutrients(product: str, app_id: str, app_key: str) -> dict:
    cache_key = f"api|nutrition:product:{product}"

    if cache.exists(cache_key):
        return cache.get_data(cache_key)

    recipe = analyze_nutrition_by_ingredients(
        app_id=app_id,
        app_key=app_key,
        ingredients=[product],
    )

    result = {code: 0.0 for code in NUTRIENTS}

    ingredient = recipe.get("ingredients", [])[0]
    for parsed in ingredient.get("parsed", []):
        nutrients = parsed.get("nutrients", {})
        for code in NUTRIENTS:
            if code in nutrients:
                result[code] += nutrients[code]["quantity"]

    response = {NUTRIENTS[k]: round(v, 2) for k, v in result.items()}
    cache.set_data(cache_key, response)

    return response


def get_recipe_nutrients(recipe_id: int, ingredients: list[str], app_id: str, app_key: str) -> dict:
    cache_key = f"api|nutrition:{recipe_id}"

    if cache.exists(cache_key):
        return cache.get_data(cache_key)

    recipe = analyze_nutrition_by_ingredients(
        app_id=app_id,
        app_key=app_key,
        ingredients=ingredients,
    )

    result = {code: 0.0 for code in NUTRIENTS}

    for ingredient in recipe.get("ingredients", []):
        for parsed in ingredient.get("parsed", []):
            nutrients = parsed.get("nutrients", {})
            for code in NUTRIENTS:
                if code in nutrients:
                    result[code] += nutrients[code]["quantity"]

    response = {NUTRIENTS[k]: round(v, 2) for k, v in result.items()}
    cache.set_data(cache_key, response)

    return response
