#!/usr/bin/env bash
# docker_login.sh — Check Docker login status and provides a menu for logging in.
#
# This script will:
# 1. Check if the user is already logged in and offer to log out.
# 2. Present a menu to choose between a WatsonX or Standard Docker login.
# 3. For WatsonX login, it will prompt for the .env file path.
#
# Usage: ./docker_login.sh

set -euo pipefail

# --- Configuration ---
DEFAULT_REGISTRY="docker.io"
IBM_REGISTRY="cp.icr.io"

#############################################
# Helper: ensure Docker CLI is present
#############################################
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker CLI is not installed or not in PATH." >&2
  exit 1
fi

#############################################
# Helper: determine whether we are logged in
#############################################
function logged_in() {
  local reg="$1"
  # For custom registries, look for its auth entry in ~/.docker/config.json
  # This is a more reliable check than parsing `docker info`.
  local cfg="$HOME/.docker/config.json"
  if [[ -f "$cfg" ]] && grep -q "\"$reg\"" "$cfg"; then
    return 0 # true, logged in
  else
    return 1 # false, not logged in
  fi
}

#############################################
# Logic for WatsonX Entitlement Key Login
#############################################
function perform_watsonx_login() {
  # Determine the default path to the .env file, assuming this script is in scripts/ubuntu
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  local default_env_path="$script_dir/../../.env"

  echo "Please provide the path to your .env file containing the WO_ENTITLEMENT_KEY."
  read -rp "Press ENTER to use the default path [$default_env_path]: " user_env_path

  # Use the user's path, or the default if they just hit enter.
  local env_file="${user_env_path:-$default_env_path}"

  if [[ ! -f "$env_file" ]]; then
    echo "[ERROR] .env file not found at the specified path: $env_file" >&2
    exit 1
  fi

  # Read the key from the .env file, ignoring commented out lines.
  # The `cut -d '=' -f2-` handles cases where the key itself might contain an '='.
  local key
  key=$(grep -E '^WO_ENTITLEMENT_KEY=' "$env_file" | cut -d '=' -f2-)

  if [[ -z "$key" ]]; then
    echo "[ERROR] WO_ENTITLEMENT_KEY not found or is empty in $env_file" >&2
    exit 1
  fi

  echo "Attempting login to $IBM_REGISTRY with your entitlement key..."
  docker login -u cp -p "$key" "$IBM_REGISTRY" || {
    echo "[ERROR] Login to $IBM_REGISTRY failed. Please check your entitlement key and network connection." >&2
    exit 1
  }
  echo "Successfully logged in to $IBM_REGISTRY."
}

#############################################
# Logic for Standard Docker Login
#############################################
function perform_standard_login() {
  echo "Performing standard login to $DEFAULT_REGISTRY."
  docker login "$DEFAULT_REGISTRY" || {
    echo "[ERROR] Login to $DEFAULT_REGISTRY failed." >&2
    exit 1
  }
}

#############################################
# Main routine
#############################################
function main() {
  # Check if logged in to either registry and offer to log out
  if logged_in "$IBM_REGISTRY" || logged_in "$DEFAULT_REGISTRY"; then
    echo "You appear to be logged in to a Docker registry."
    if logged_in "$IBM_REGISTRY"; then echo " -> Logged into: $IBM_REGISTRY"; fi
    if logged_in "$DEFAULT_REGISTRY"; then echo " -> Logged into: $DEFAULT_REGISTRY"; fi

    read -rp "Do you want to log out and log in again? [y/N] " LOGOUT_ANSWER
    case "$LOGOUT_ANSWER" in
      [Yy]*)
        echo "Logging out..."
        if logged_in "$IBM_REGISTRY"; then docker logout "$IBM_REGISTRY"; fi
        if logged_in "$DEFAULT_REGISTRY"; then docker logout "$DEFAULT_REGISTRY"; fi
        echo "Logged out successfully."
        ;;
      *)
        echo "Exiting without changing login status."
        exit 0
        ;;
    esac
  fi

  # --- Login Menu ---
  echo
  echo "Please choose a login method:"
  echo "  1) Login with WatsonX Entitlement Key"
  echo "  2) Standard Docker Login ($DEFAULT_REGISTRY)"
  echo "  3) Exit"
  read -rp "Enter your choice [1-3]: " LOGIN_CHOICE

  case "$LOGIN_CHOICE" in
    1)
      perform_watsonx_login
      ;;
    2)
      perform_standard_login
      ;;
    3)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
}

# --- Run the main function ---
main