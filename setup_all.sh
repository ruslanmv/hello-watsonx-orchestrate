#!/bin/bash
# setup_all.sh - Complete setup: start server, import agents, start UI


set -euo pipefail

# ── Blue runtime logo ────────────────────────────────────────────────────────
print_logo() {
  local BLUE="\033[1;34m"; local NC="\033[0m"
  echo -e "${BLUE}"
  cat <<'EOF'
                _
               | |
 _ __ _   _ ___| | __ _ _ __   _ __ _____   __
| '__| | | / __| |/ _` | '_ \| '_ ` _ \ \ / /
| |  | |_| \__ \ | (_| | | | | | | | | \ V /
|_|   \__,_|___/_|\__,_|_| |_|_| |_| |_|\_/

EOF
  echo -e "${NC}"
}

print_logo


echo "=== Complete watsonx Orchestrate Setup ==="

# Start server in background
echo "Starting server..."
./start.sh &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to initialize..."
sleep 30

# Run the import process
echo "Running agent import..."
./run.sh

# Clean up
echo "Setup complete!"