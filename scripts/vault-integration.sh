set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_ROLE_ID="${VAULT_ROLE_ID:?VAULT_ROLE_ID is not set}"
VAULT_SECRET_ID="${VAULT_SECRET_ID:?VAULT_SECRET_ID is not set}"

log() { echo "[vault-integration] $*" >&2; }

vault_curl() {
  local response http_code body
  response=$(curl -sS --max-time 10 "$@" -w $'\n%{http_code}') || {
    echo "ERROR: Cannot reach Vault at ${VAULT_ADDR}" >&2
    echo "Check that Vault is up and vault.local is reachable." >&2
    exit 1
  }
  http_code=$(echo "${response}" | tail -n1)
  body=$(echo "${response}" | sed '$d')
  if [[ "${http_code}" != "200" ]]; then
    echo "ERROR: Vault request failed (${http_code}): ${body}" >&2
    exit 1
  fi
  echo "${body}"
}

export VAULT_ADDR

log "Authenticating via AppRole at ${VAULT_ADDR} ..."

AUTH_RESPONSE=$(vault_curl --request POST \
  --data "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"${VAULT_SECRET_ID}\"}" \
  "${VAULT_ADDR}/v1/auth/approle/login")

VAULT_TOKEN=$(echo "${AUTH_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin)['auth']['client_token'])")

export VAULT_TOKEN
log "AppRole auth OK, token obtained."
log "Fetching Docker Hub credentials from Vault (foodgram/docker) ..."

DOCKER_RESPONSE=$(vault_curl \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  "${VAULT_ADDR}/v1/foodgram/data/docker")
DOCKER_VAULT_DATA=$(echo "${DOCKER_RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']['data']; print(d.get('username','')); print(d.get('password',''))")

DOCKER_USERNAME=$(echo "${DOCKER_VAULT_DATA}" | sed -n '1p')
DOCKER_PASSWORD=$(echo "${DOCKER_VAULT_DATA}" | sed -n '2p')

if [[ -z "${DOCKER_USERNAME}" || -z "${DOCKER_PASSWORD}" ]]; then
  log "WARNING: Docker credentials not found in Vault (foodgram/docker)."
  log "Falling back to env vars DOCKER_USERNAME / DOCKER_PASSWORD."
  DOCKER_USERNAME="${DOCKER_USERNAME:-${DOCKER_HUB_USERNAME:-}}"
  DOCKER_PASSWORD="${DOCKER_PASSWORD:-${DOCKER_HUB_PASSWORD:-}}"
fi

export DOCKER_USERNAME DOCKER_PASSWORD

if [[ -n "${DOCKER_USERNAME}" ]]; then
  log "Docker Hub login as ${DOCKER_USERNAME} ..."
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  log "Docker Hub login OK."
else
  log "WARNING: No Docker credentials — skipping docker login."
fi

log "Fetching application secrets from Vault ..."

get_vault_field() {
  local path="$1" field="$2"
  local response
  response=$(vault_curl \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/foodgram/data/${path}")
  echo "${response}" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['data']['${field}'])"
}

get_vault_field_optional() {
  local path="$1" field="$2" default="${3:-}"
  if value=$(get_vault_field "${path}" "${field}" 2>/dev/null); then
    echo "${value}"
  else
    echo "${default}"
  fi
}

export POSTGRES_USER=$(get_vault_field db POSTGRES_USER)
export POSTGRES_PASSWORD=$(get_vault_field db POSTGRES_PASSWORD)
export POSTGRES_DB=$(get_vault_field db POSTGRES_DB)
export DJANGO_SECRET_KEY=$(get_vault_field backend secret_key)
export REDIS_PASSWORD=$(get_vault_field redis password)
export RABBITMQ_USERNAME=$(get_vault_field_optional rabbitmq username guest)
export RABBITMQ_PASSWORD=$(get_vault_field_optional rabbitmq password guest)

log "All secrets fetched successfully."
log "PostgreSQL: user=${POSTGRES_USER}, db=${POSTGRES_DB}"
log "Vault integration complete — environment is ready for werf converge."
