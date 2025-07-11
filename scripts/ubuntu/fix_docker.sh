#!/usr/bin/env bash
# fix_docker.sh – Diagnose and remediate Docker "connection reset by peer" pulls from Docker Hub
# Tested on Ubuntu 22.04 with Docker Engine 24+.
# Run as root: sudo ./fix_docker.sh

set -euo pipefail

## ────────────────────────────────────────────────────────────────
## Helper functions
## ────────────────────────────────────────────────────────────────
log()   { printf "\e[1;34m[INFO ]\e[0m %s\n" "$*"; }
warn()  { printf "\e[1;33m[WARN ]\e[0m %s\n" "$*"; }
error() { printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }
fail()  { error "$1"; exit 1; }

## ────────────────────────────────────────────────────────────────
## Pre-flight – root check & prerequisites
## ────────────────────────────────────────────────────────────────
[[ $(id -u) -eq 0 ]] || fail "Run this script with sudo or as root."
command -v curl >/dev/null || apt-get install -y curl
command -v dig  >/dev/null || apt-get install -y dnsutils

DAEMON_JSON=/etc/docker/daemon.json
BACKUP_JSON=/etc/docker/daemon.json.bak.$(date +%s)

## ────────────────────────────────────────────────────────────────
## Step 1 – Quick service restart
## ────────────────────────────────────────────────────────────────
log "Restarting Docker and containerd…"
systemctl restart docker.service containerd.service || fail "Unable to restart Docker service."

## ────────────────────────────────────────────────────────────────
## Step 2 – Network & DNS diagnostics
## ────────────────────────────────────────────────────────────────
log "Testing DNS resolution for registry-1.docker.io…"
if ! dig +short registry-1.docker.io | grep -qE "[0-9.]+"; then
  warn "DNS lookup failed. Adding Google DNS (8.8.8.8, 8.8.4.4) to daemon.json."
  if [[ -f $DAEMON_JSON ]]; then
    cp "$DAEMON_JSON" "$BACKUP_JSON"
  fi
  jq '.dns=["8.8.8.8","8.8.4.4"]' "$DAEMON_JSON" 2>/dev/null || echo '{"dns":["8.8.8.8","8.8.4.4"]}' > "$DAEMON_JSON"
  systemctl restart docker.service
fi

## ────────────────────────────────────────────────────────────────
## Step 3 – Test TLS handshake to Docker Hub
## ────────────────────────────────────────────────────────────────
log "Testing HTTPS connectivity to Docker Hub…"
if ! curl -fsSL https://registry-1.docker.io/v2/ > /dev/null; then
  warn "Direct connectivity to Docker Hub failed. Configuring registry mirrors."
  MIRRORS=("https://mirror.gcr.io" "https://registry.docker-cn.com")
  if [[ -f $DAEMON_JSON ]]; then
    cp "$DAEMON_JSON" "$BACKUP_JSON"
    jq --argjson mirrors "$(printf '%s\n' "${MIRRORS[@]}" | jq -R . | jq -s .)" '(."registry-mirrors" // []) += $mirrors | unique' "$BACKUP_JSON" > "$DAEMON_JSON" || echo '{"registry-mirrors":["https://mirror.gcr.io","https://registry.docker-cn.com"]}' > "$DAEMON_JSON"
  else
    echo '{"registry-mirrors":["https://mirror.gcr.io","https://registry.docker-cn.com"]}' > "$DAEMON_JSON"
  fi
  systemctl restart docker.service
fi

## ────────────────────────────────────────────────────────────────
## Step 4 – Verify with hello-world
## ────────────────────────────────────────────────────────────────
log "Pull-running hello-world (this may pull via mirror)…"
if docker run --rm hello-world 2>&1 | tee /tmp/hello_world.log | grep -q "Hello from Docker"; then
  log "Success! Docker is able to pull images."
  exit 0
else
  error "Docker still cannot pull images. Review /tmp/hello_world.log for details."
  [[ -f $BACKUP_JSON ]] && warn "A backup of your original daemon.json was saved to $BACKUP_JSON."
  exit 1
fi
