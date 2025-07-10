#!/usr/bin/env bash
#
# monitor_wxo_server.sh
# Monitors the Orchestrate server container "docker-wxo-server-1" on localhost:4321
#
# Usage: ./monitor_wxo_server.sh [interval_seconds]
# e.g.: ./monitor_wxo_server.sh 15
#

INTERVAL=${1:-30}
API_URL="http://localhost:4321/docs"
CONTAINER_NAME="docker-wxo-server-1"

# Find the container by name
detect_container() {
  docker ps -q -f "name=^${CONTAINER_NAME}$"
}

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  CID=$(detect_container)

  if [ -z "$CID" ]; then
    echo "[$TIMESTAMP] ❌ Container '${CONTAINER_NAME}' not running"
  else
    # 1) Container status & health
    STATE=$(docker inspect --format '{{.State.Status}}' "$CID")
    HEALTH=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CID")

    # 2) HTTP check against the docs endpoint
    HTTP_OUT=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" "$API_URL")

    # 3) Recent logs (tail 20) highlighting errors or greeting_agent hiccups
    LOGS=$(docker logs --tail 20 "$CID" 2>&1)

    echo "[$TIMESTAMP] ✅ $CONTAINER_NAME ($CID) Status: $STATE (Health: $HEALTH)"
    echo "            HTTP: $HTTP_OUT     URL: $API_URL"
    echo "            ─── Last logs ─────────────────────────────────────────"
    # Highlight ERRORs
    echo "$LOGS" | sed -n -e '/[Ee][Rr][Rr][Oo][Rr]/{s/^/            ⚠️ &/;p}'
    # Highlight any greeting_agent messages
    echo "$LOGS" | grep -i 'greeting_agent' | sed 's/^/            🔍 &/' || :
    # Print last 5 lines for context
    echo "$LOGS" | tail -n5 | sed 's/^/               /'
  fi

  echo
  sleep "$INTERVAL"
done
