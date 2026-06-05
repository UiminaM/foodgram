set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

WERF_ENV="${1:-${WERF_ENV:-development}}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-foodgram}"
WERF_REPO="${WERF_REPO:-}"

log() { echo "[werf-deploy] $*"; }

if command -v trdl &>/dev/null; then
  log "Activating werf via trdl ..."
  # shellcheck disable=SC1090
  source "$(trdl use werf 2 stable)" 2>/dev/null || true
fi

if ! command -v werf &>/dev/null; then
  echo "ERROR: werf is not installed. Run: curl -sSL https://werf.io/install.sh | bash -s -- --version 2 --channel stable" >&2
  exit 1
fi

log "werf version: $(werf version)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  log "Loading .env ..."
  set -a; source "${ROOT_DIR}/.env"; set +a
fi

log "Running Vault integration ..."
source "${SCRIPT_DIR}/vault-integration.sh"
log() { echo "[werf-deploy] $*"; }

if [[ -z "${WERF_REPO}" ]]; then
  if [[ -n "${DOCKER_USERNAME:-}" ]]; then
    WERF_REPO="docker.io/${DOCKER_USERNAME}/foodgram"
  else
    WERF_REPO="docker.io/UiminaM/foodgram"
  fi
fi
log "Using werf repo: ${WERF_REPO}"

kubectl create namespace "${KUBE_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

VAULT_ADDR_FOR_PODS="${VAULT_ADDR_FOR_PODS:-http://vault.vault.svc.cluster.local}"

kubectl create secret generic app-env \
  --namespace="${KUBE_NAMESPACE}" \
  --from-literal=VAULT_ADDR="${VAULT_ADDR_FOR_PODS}" \
  --from-literal=VAULT_ROLE_ID="${VAULT_ROLE_ID}" \
  --from-literal=VAULT_SECRET_ID="${VAULT_SECRET_ID}" \
  --from-literal=SECRET_KEY="${DJANGO_SECRET_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Restarting workloads to pick up updated app-env secret ..."
kubectl rollout restart deployment/django-deployment deployment/nginx-deployment -n "${KUBE_NAMESPACE}" 2>/dev/null || true

log "Removing old one-off jobs (Jobs are immutable in Kubernetes) ..."
kubectl delete job migrate-job collectstatic-job -n "${KUBE_NAMESPACE}" --ignore-not-found

log "Starting werf converge (env=${WERF_ENV}) ..."

if [[ "$(uname -m)" == "arm64" ]]; then
  export WERF_PLATFORM=linux/arm64
  log "Building for platform: linux/arm64"
fi

WERF_ARGS=(
  --env "${WERF_ENV}"
  --namespace "${KUBE_NAMESPACE}"
  --force-adoption
)

if [[ "${WERF_ENV}" == "development" ]]; then
  WERF_ARGS+=(--dev)
  log "Using werf --dev mode (allows uncommitted config files)"
fi

WERF_ARGS+=(
  --set "global.db.user=${POSTGRES_USER}"
  --set "global.db.password=${POSTGRES_PASSWORD}"
  --set "global.db.name=${POSTGRES_DB}"
  --set "global.django.secretKey=${DJANGO_SECRET_KEY}"
  --set "global.redis.password=${REDIS_PASSWORD}"
  --set "redis.auth.password=${REDIS_PASSWORD}"
  --set "jobs.auth.username=${POSTGRES_USER}"
  --set "jobs.auth.password=${POSTGRES_PASSWORD}"
  --set "jobs.auth.database=${POSTGRES_DB}"
  --set "backend.consumers.enabled=false"
)

WERF_ARGS+=(--repo "${WERF_REPO}")

werf converge "${WERF_ARGS[@]}"

log "Deployment complete!"
log "Namespace: ${KUBE_NAMESPACE}"
log "Environment: ${WERF_ENV}"

log "Pod status:"
kubectl get pods -n "${KUBE_NAMESPACE}"
