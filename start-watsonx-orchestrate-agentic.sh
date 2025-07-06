#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  watsonx Orchestrate Developer Edition Startup Script
# ─────────────────────────────────────────────────────────────────────────────
set -e  # Exit on any error

# ─── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print()       { echo -e "${BLUE}[INFO]${NC} $1";   }
print_ok()    { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_err()   { echo -e "${RED}[ERROR]${NC} $1";   }

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
TOOLS_DIR="$SCRIPT_DIR/tools"
AGENTS_DIR="$SCRIPT_DIR/agents"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup_specific_resources.sh"

print "Starting watsonx Orchestrate Developer Edition…"
print "Script directory: $SCRIPT_DIR"

# ─── Pre-flight checks ───────────────────────────────────────────────────────
print "Running pre-flight checks…"

[[ -f "$ENV_FILE" ]] || { print_err ".env file not found"; exit 1; }

docker info   >/dev/null 2>&1 || { print_err "Docker is not running"; exit 1; }
docker compose version 2>/dev/null | grep -q 'v2\.' || { print_err "Docker Compose v2 is required"; exit 1; }

if [[ -z "$VIRTUAL_ENV" ]]; then
  print_warn "No Python venv detected"
  read -p "Continue anyway? (y/N): " -n 1 -r; echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

command -v orchestrate >/dev/null 2>&1 || {
  print_err "'orchestrate' command not found – install with: pip install ibm-watsonx-orchestrate-adk"
  exit 1
}

print_ok "Pre-flight checks passed"

# ─── Load .env ───────────────────────────────────────────────────────────────
set -a; source "$ENV_FILE"; set +a
required_vars=(WO_DEVELOPER_EDITION_SOURCE WO_ENTITLEMENT_KEY WO_INSTANCE WO_API_KEY WATSONX_APIKEY WATSONX_SPACE_ID)
for v in "${required_vars[@]}"; do
  [[ -z "${!v:-}" ]] && { missing=yes; print_err "Missing env var: $v"; }
done
[[ $missing == yes ]] && exit 1
[[ "$WO_INSTANCE" == *"YOUR_INSTANCE_ID"* ]] && { print_err "Replace YOUR_INSTANCE_ID in WO_INSTANCE"; exit 1; }
print_ok "Environment validated"

# ─── Stop any running server ────────────────────────────────────────────────
print "Stopping any existing watsonx Orchestrate services…"
orchestrate server stop 2>/dev/null || true

# ─── Helper to start the server ──────────────────────────────────────────────
export COMPOSE_INTERACTIVE_NO_CLI=1 DOCKER_BUILDKIT=1
start_server() {
  local max=3 attempt=1
  while (( attempt <= max )); do
    print "Attempt $attempt of $max…"

    if (( attempt == 3 )); then
      print_warn "Running in pseudo-TTY to avoid TTY error…"
      script -q -c "orchestrate server start --env-file=$ENV_FILE" /dev/null
    else
      orchestrate server start --env-file="$ENV_FILE"
    fi

    if [[ $? -eq 0 ]]; then
      print_ok "Server started successfully"; return 0
    fi

    print_warn "Server start attempt $attempt failed"

    if (( attempt == 1 )); then
      print "Running cleanup_specific_resources.sh before retry…"
      bash "$CLEANUP_SCRIPT" || print_warn "Cleanup encountered an error"
    fi

    (( attempt++ ))
    if (( attempt <= max )); then
      print "Waiting 10 s before retry…"; sleep 10
      print "Resetting server before retry…"
      echo "I accept" | orchestrate server reset --env-file="$ENV_FILE" 2>/dev/null || true
      sleep 5
    fi
  done
  print_err "Failed to start server after $max attempts"; return 1
}

# ─── Launch the server ───────────────────────────────────────────────────────
start_server

print "Waiting for services to initialise…"; sleep 30

# ─── Activate local environment ─────────────────────────────────────────────
for i in {1..3}; do
  orchestrate env activate local && { print_ok "Local env activated"; break; }
  (( i == 3 )) && print_warn "Failed after 3 tries – activate manually" && break
  print_warn "Activation failed (attempt $i/3) – retrying in 10 s…"; sleep 10
done

# ─────────────────────────────────────────────────────────────────────────────
#  NEW: Ask whether to install demo tools & agents
# ─────────────────────────────────────────────────────────────────────────────
read -p $'\e[34m[INFO]\e[0m Would you like to install the sample tools & agents included in this project? (y/N): ' -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # ── 1) Import every Python tool first ──────────────────────────────────────
  if [[ -d "$TOOLS_DIR" ]]; then
    shopt -s nullglob
    mapfile -t tool_files < <(printf '%s\n' "$TOOLS_DIR"/*.py)
    if (( ${#tool_files[@]} )); then
      print "Installing ${#tool_files[@]} tool(s)…"
      for tool_file in "${tool_files[@]}"; do
        base="$(basename "$tool_file")"
        print "Importing tool $base…"
        orchestrate tools import -f "$tool_file" \
          && print_ok "$base imported" \
          || print_err "Failed to import $base (might already exist)"
      done
    else
      print_warn "No *.py tools found in $TOOLS_DIR"
    fi
  else
    print_warn "Tools directory not found: $TOOLS_DIR"
  fi

  # ── 2) Import agents (leaf first, orchestrator last) ───────────────────────
  if [[ -d "$AGENTS_DIR" ]]; then
    shopt -s nullglob
    mapfile -t agent_files < <(printf '%s\n' "$AGENTS_DIR"/*.yaml "$AGENTS_DIR"/*.yml)

    # Separate orchestrators from the rest
    orchestrators=()
    regular_agents=()
    for f in "${agent_files[@]}"; do
      if [[ "$(basename "$f")" == orchestrator* ]]; then
        orchestrators+=("$f")
      else
        regular_agents+=("$f")
      fi
    done

    print "Installing ${#agent_files[@]} agent(s)…"
    for f in "${regular_agents[@]}" "${orchestrators[@]}"; do
      base="$(basename "$f")"
      print "Importing $base…"
      orchestrate agents import -f "$f" \
        && print_ok "$base imported" \
        || print_err "Failed to import $base (might already exist or have missing dependencies)"
    done
  else
    print_warn "Agents directory not found: $AGENTS_DIR"
  fi
fi
# ─────────────────────────────────────────────────────────────────────────────

# ─── Final messages ─────────────────────────────────────────────────────────-
print_ok "watsonx Orchestrate Developer Edition is ready!"
echo -e "
  ▸ UI  : http://localhost:3000/chat-lite
  ▸ API : http://localhost:4321/api/v1
  ▸ Docs : http://localhost:4321/docs
"
read -p $'\e[34m[INFO]\e[0m Start the chat interface now? (y/N): ' -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  print "Starting chat…"
  orchestrate chat start
fi

print_ok "Script completed."
