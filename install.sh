#!/usr/bin/env bash
# install.sh — detect OS and run platform-specific installers

set -euo pipefail
IFS=$'\n\t'


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


# helper: run a script and exit if it fails
run_script() {
  local script_path="$1"
  echo "→ Running ${script_path}"
  if [[ ! -x "${script_path}" ]]; then
    echo "  (Making ${script_path} executable)"
    chmod +x "${script_path}"
  fi
  "${script_path}"
}

# Detect the OS via uname
OS_TYPE="$(uname -s)"

case "${OS_TYPE}" in
  Linux*)
    echo "🖥  Detected Linux"
    # Verify it's Ubuntu
    if grep -qi '^ID=ubuntu' /etc/os-release; then
      echo "✔  Ubuntu identified"
      run_script "./scripts/ubuntu/install_python311.sh"
      run_script "./scripts/ubuntu/install_docker.sh"
      run_script "./install_watsonx_pc.sh"
      run_script "./start.sh"
      run_script "./run.sh"
    else
      echo "❌  Unsupported Linux distro. This script only supports Ubuntu."
      exit 1
    fi
    ;;
  Darwin*)
    echo "🍎 Detected macOS"
    run_script "./scripts/mac/install_docker.sh"
    run_script "./install_watsonx_mac.sh"
    run_script "./start.sh"
    run_script "./run.sh"
    ;;
  *)
    echo "❓ Unknown OS: ${OS_TYPE}"
    echo "This script supports only Ubuntu (Linux) and macOS."
    exit 1
    ;;
esac

echo "✅ All done!"
