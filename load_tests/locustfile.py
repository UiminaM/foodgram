import os
import random

from locust import HttpUser, between, events, task


API_PREFIX = os.getenv("FOODGRAM_API_PREFIX", "/api").rstrip("/")
MIN_WAIT = float(os.getenv("LOCUST_MIN_WAIT", "1"))
MAX_WAIT = float(os.getenv("LOCUST_MAX_WAIT", "3"))
AVG_RESPONSE_LIMIT_MS = int(os.getenv("LOCUST_AVG_RESPONSE_LIMIT_MS", "7000"))


def paginated_results(payload):
    if isinstance(payload, dict):
        results = payload.get("results")
        return results if isinstance(results, list) else []
    return payload if isinstance(payload, list) else []


class FoodgramApiUser(HttpUser):
    wait_time = between(MIN_WAIT, MAX_WAIT)
    recipe_ids = []
    ingredient_names = []

    def on_start(self):
        self.bootstrap_recipes()
        self.bootstrap_ingredients()

    def get_json(self, path, name):
        with self.client.get(path, name=name, catch_response=True) as response:
            if response.status_code >= 400:
                response.failure(f"HTTP {response.status_code}")
                return None

            try:
                return response.json()
            except ValueError:
                response.failure("Response is not valid JSON")
                return None

    def bootstrap_recipes(self):
        if FoodgramApiUser.recipe_ids:
            return

        payload = self.get_json(
            f"{API_PREFIX}/recipes/?page=1&limit=20",
            "GET /api/recipes/ [bootstrap]",
        )
        if not payload:
            return

        FoodgramApiUser.recipe_ids = [
            recipe["id"]
            for recipe in paginated_results(payload)
            if isinstance(recipe, dict) and recipe.get("id") is not None
        ]

    def bootstrap_ingredients(self):
        if FoodgramApiUser.ingredient_names:
            return

        payload = self.get_json(
            f"{API_PREFIX}/ingredients/",
            "GET /api/ingredients/ [bootstrap]",
        )
        if not payload:
            return

        FoodgramApiUser.ingredient_names = [
            ingredient["name"]
            for ingredient in paginated_results(payload)[:20]
            if isinstance(ingredient, dict) and ingredient.get("name")
        ]

    @task(5)
    def list_recipes(self):
        limit = random.choice([6, 12, 24])
        self.get_json(
            f"{API_PREFIX}/recipes/?page=1&limit={limit}",
            "GET /api/recipes/",
        )

    @task(4)
    def list_ingredients(self):
        if FoodgramApiUser.ingredient_names and random.random() < 0.5:
            name = random.choice(FoodgramApiUser.ingredient_names)[:3]
            path = f"{API_PREFIX}/ingredients/?name={name}"
        else:
            path = f"{API_PREFIX}/ingredients/"

        self.get_json(path, "GET /api/ingredients/")

    @task(2)
    def list_users(self):
        self.get_json(
            f"{API_PREFIX}/users/?page=1&limit=6",
            "GET /api/users/",
        )

    @task(2)
    def retrieve_recipe(self):
        if not FoodgramApiUser.recipe_ids:
            self.list_recipes()
            return

        recipe_id = random.choice(FoodgramApiUser.recipe_ids)
        self.get_json(
            f"{API_PREFIX}/recipes/{recipe_id}/",
            "GET /api/recipes/:id/",
        )

    @task(1)
    def recipe_short_link(self):
        if not FoodgramApiUser.recipe_ids:
            self.list_recipes()
            return

        recipe_id = random.choice(FoodgramApiUser.recipe_ids)
        self.get_json(
            f"{API_PREFIX}/recipes/{recipe_id}/get-link/",
            "GET /api/recipes/:id/get-link/",
        )


@events.quitting.add_listener
def enforce_sla(environment, **kwargs):
    total = environment.stats.total
    if total.num_failures:
        environment.process_exit_code = 1
        print(f"SLA failed: {total.num_failures} requests failed.")
        return

    if total.avg_response_time > AVG_RESPONSE_LIMIT_MS:
        environment.process_exit_code = 1
        print(
            "SLA failed: average response time "
            f"{total.avg_response_time:.0f} ms > {AVG_RESPONSE_LIMIT_MS} ms."
        )
