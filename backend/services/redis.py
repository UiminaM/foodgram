import os
from typing import Any, Dict, Optional

import redis

_client: Optional[redis.Redis] = None


def get_redis_connection_config() -> Dict[str, Any]:
    return {
        "host": os.getenv("REDIS_HOST", "localhost"),
        "port": int(os.getenv("REDIS_PORT", "6379")),
        "password": os.getenv("REDIS_PASSWORD", None),
    }


def get_redis_client() -> redis.Redis:
    global _client
    if _client is None:
        _client = redis.Redis(**get_redis_connection_config())
    return _client
