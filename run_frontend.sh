#!/usr/bin/env bash
#
# run_frontend.sh ─ Open watsonx Orchestrate Chat-Lite UI only
# -----------------------------------------------------------------
set -euo pipefail

FRONTEND_URL="http://localhost:3000/chat-lite"
UI_CONTAINER="docker-wxo-builder-1"   # the container that serves the built UI

# ─── (Optional) Sanity check ─────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  if ! docker ps --format '{{.Names}}' | grep -q "^${UI_CONTAINER}$"; then
    echo "[WARNING] Container '${UI_CONTAINER}' is not running."
    echo "          The UI may not be reachable until the full stack is up."
  fi
fi

# ─── Display & open URL ──────────────────────────────────────────
echo
echo "[INFO] Chat-Lite UI:"
echo "       ${FRONTEND_URL}"
echo

# Try to open the default browser (best effort, no extra deps)
if command -v xdg-open >/dev/null 2>&1; then          # Linux desktop, WSLg
  xdg-open "${FRONTEND_URL}" >/dev/null 2>&1 &
elif command -v wslview >/dev/null 2>&1; then         # WSL without GUI
  wslview "${FRONTEND_URL}" &
elif command -v open >/dev/null 2>&1; then            # macOS
  open "${FRONTEND_URL}" &
elif [[ "$OSTYPE" =~ ^msys|cygwin|win32 ]]; then      # Git-Bash / Cygwin
  start "" "${FRONTEND_URL}"
fi

echo "[SUCCESS] If the browser didn’t open automatically, copy the URL above."
