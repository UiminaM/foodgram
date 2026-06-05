#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-http://127.0.0.1:8000}"
USER_STEPS="${USER_STEPS:-10 25 50 75 100}"
SPAWN_RATE="${SPAWN_RATE:-5}"
RUN_TIME="${RUN_TIME:-2m}"
AVG_RESPONSE_LIMIT_MS="${AVG_RESPONSE_LIMIT_MS:-7000}"
K8S_NAMESPACE="${K8S_NAMESPACE:-foodgram}"
REPORT_ROOT="${REPORT_ROOT:-load_tests/reports}"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${REPORT_ROOT}/${STAMP}"
BEST_USERS=0

mkdir -p "${REPORT_DIR}"

echo "Host: ${HOST}"
echo "User steps: ${USER_STEPS}"
echo "Spawn rate: ${SPAWN_RATE}/s"
echo "Run time: ${RUN_TIME}"
echo "Average response limit: ${AVG_RESPONSE_LIMIT_MS} ms"
echo "Reports: ${REPORT_DIR}"
echo

for USERS in ${USER_STEPS}; do
  PREFIX="${REPORT_DIR}/users-${USERS}"
  echo "=== Running ${USERS} users ==="

  set +e
  LOCUST_AVG_RESPONSE_LIMIT_MS="${AVG_RESPONSE_LIMIT_MS}" \
    locust \
      -f load_tests/locustfile.py \
      --headless \
      --host "${HOST}" \
      --users "${USERS}" \
      --spawn-rate "${SPAWN_RATE}" \
      --run-time "${RUN_TIME}" \
      --html "${PREFIX}.html" \
      --csv "${PREFIX}" \
      --only-summary
  LOCUST_EXIT_CODE=$?
  set -e

  if command -v kubectl >/dev/null 2>&1; then
    kubectl top pods -n "${K8S_NAMESPACE}" > "${PREFIX}-kubectl-top.txt" 2>&1 || true
  fi

  ANALYSIS="$(python3 - "${PREFIX}_stats.csv" "${AVG_RESPONSE_LIMIT_MS}" <<'PY'
import csv
import sys

stats_path = sys.argv[1]
avg_limit = float(sys.argv[2])

with open(stats_path, newline="") as stats_file:
    rows = list(csv.DictReader(stats_file))

aggregated = next((row for row in rows if row.get("Name") == "Aggregated"), None)
if aggregated is None:
    print("FAIL no aggregated stats row")
    sys.exit(0)

failures = int(float(aggregated.get("Failure Count") or 0))
avg_ms = float(aggregated.get("Average Response Time") or 0)
requests = int(float(aggregated.get("Request Count") or 0))

status = "PASS" if failures == 0 and avg_ms <= avg_limit else "FAIL"
print(f"{status} requests={requests} failures={failures} avg_ms={avg_ms:.0f}")
PY
)"

  echo "${ANALYSIS}" | tee "${PREFIX}-summary.txt"
  echo

  if [[ ${LOCUST_EXIT_CODE} -eq 0 && "${ANALYSIS}" == PASS* ]]; then
    BEST_USERS="${USERS}"
  else
    echo "Stopping search at ${USERS} users."
    break
  fi
done

echo "Best successful user count: ${BEST_USERS}" | tee "${REPORT_DIR}/capacity-summary.txt"
