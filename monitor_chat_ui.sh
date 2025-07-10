#!/usr/bin/env bash
#
# monitor_chat_ui.sh
# Monitors the Docker container exposing http://localhost:3000/chat-lite
#
# Usage: ./monitor_chat_ui.sh [interval_seconds]
# e.g.: ./monitor_chat_ui.sh 15
#

INTERVAL=${1:-30}
URL="http://localhost:3000/chat-lite"

# Try to detect the container running port 3000
detect_container() {
  # match any container mapping host port 3000
  docker ps --format '{{.ID}} {{.Names}} {{.Ports}}' \
    | awk '/0\.0\.0\.0:3000->/ {print $1}'
}

# Main loop
while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  CONTAINER_ID=$(detect_container)

  if [ -z "$CONTAINER_ID" ]; then
    echo "[$TIMESTAMP] ❌ No container found publishing port 3000"
  else
    # 1) Container status
    STATUS=$(docker inspect --format '{{.State.Status}}' "$CONTAINER_ID")
    HEALTH=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER_ID")

    # 2) HTTP check
    HTTP_OUT=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" "$URL")

    # 3) Recent logs (last 20 lines)
    LOGS=$(docker logs --tail 20 "$CONTAINER_ID" 2>&1)

    echo "[$TIMESTAMP] ✅ Container $CONTAINER_ID Status: $STATUS (Health: $HEALTH)"
    echo "            HTTP: $HTTP_OUT     URL: $URL"
    echo "            ─── Last logs ─────────────────────────────────────────"
    # Highlight errors if present
    echo "$LOGS" | sed -e '/[Ee][Rr][Rr][Oo][Rr]/!d' -e 's/^/            ⚠️ &/' \
                     -e 't' -e 's/^/               /'
    # Also show the last 5 lines in full
    echo "$LOGS" | tail -n5 | sed 's/^/               /'
  fi

  echo
  sleep "$INTERVAL"
done
