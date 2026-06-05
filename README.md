Foodgram - сервис, который помощник в приготовлении вкусных блюд

Homework 1(k8s) - infra/k8s/...
Homework 2(helm+vault) - foodgram-chart/...
Homework 3(rabbitmq) - foodgram-chart/charts/rabbitmq/...
Homework 4(redis+cache) - foodgram-chart/charts/redis/...
                        - backend/services/...
Homework 7(locust+HPA+VPA)
Homework 8(CI/CD) - см. ниже
Homework 9(werf)

## Homework 8 — CI/CD

### Часть 1. Semantic-release и деплой образа

Цепочка при push в `main`:

1. **Release** (`.github/workflows/release.yml`) — `semantic-release` создаёт тег `vX.Y.Z`, GitHub Release и обновляет `CHANGELOG.md`.
2. **Docker Build & Push** (`.github/workflows/docker-build.yml`) — при теге `v*` собирает backend/frontend и пушит в Docker Hub.
3. Автокоммит с обновлением `tag` в `foodgram-chart/charts/backend|frontend/values.yaml`.

Конфиг semantic-release: `.releaserc.json`, `package.json`.

Коммиты в формате [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` — minor версия
- `fix:` — patch версия
- `feat!:` или `BREAKING CHANGE:` — major версия

### Часть 2. Self-hosted runner

Helm-chart: `foodgram-chart/charts/actions-runner/`

```bash
# 1. Создать secret с токеном runner (Settings → Actions → Runners → New self-hosted runner)
kubectl create namespace actions-runner

kubectl create secret generic runner-secret -n actions-runner \
  --from-literal=RUNNER_NAME=foodgram-k8s-runner \
  --from-literal=ACCESS_TOKEN=<github_pat_with_repo_scope>

# 2. Установить runner
helm upgrade --install actions-runner \
  ./foodgram-chart/charts/actions-runner \
  -n actions-runner --create-namespace
```

Пайплайн на runner: `.github/workflows/docker-build-self-hosted.yml`  
Labels: `self-hosted`, `linux`, `k8s`.

### Секреты GitHub (Settings → Secrets and variables → Actions)

| Secret | Назначение |
|--------|------------|
| `GH_PAT` | Personal Access Token для semantic-release |
| `DOCKER_USERNAME` | Логин Docker Hub |
| `DOCKER_PASSWORD` | Token Docker Hub |

### Ручной запуск сборки образов

Actions → **Docker Build & Push** или **Docker Build & Push (self-hosted runner)** → Run workflow.
