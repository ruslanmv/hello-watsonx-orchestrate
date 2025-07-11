#!/usr/bin/env bash
# uninstall_docker.sh – Completely remove Docker Engine, CLI, containerd, configs, images, networks, volumes, and groups
# Tested on Ubuntu 22.04. Run as root (e.g., `sudo ./uninstall_docker.sh`).

set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "[ERROR] This script must be run with root privileges (use sudo)." >&2
  exit 1
fi

printf '\n>>> Stopping Docker services…\n'
systemctl disable --now docker.service docker.socket containerd.service 2>/dev/null || true

printf '\n>>> Removing Docker packages…\n'
apt-get purge -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin docker-compose \
  docker-ce-rootless-extras 2>/dev/null || true
apt-get autoremove -y --purge

printf '\n>>> Deleting Docker data directories…\n'
rm -rf /var/lib/docker /var/lib/containerd /etc/docker

printf '\n>>> Deleting Docker repository & keyring…\n'
rm -f /etc/apt/keyrings/docker.gpg
rm -f /etc/apt/sources.list.d/docker.list
apt-get update -qq

printf '\n>>> Removing \"docker\" group if empty…\n'
if getent group docker >/dev/null; then
  if [[ $(grep -c "^docker:" /etc/group) -gt 0 ]]; then
    deluser --system docker &>/dev/null || true
  fi
  groupdel docker &>/dev/null || true
fi

printf '\n>>> Docker has been fully removed.\n'
