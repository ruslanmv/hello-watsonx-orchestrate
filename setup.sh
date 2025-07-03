#!/usr/bin/env bash
#
# One-shot bootstrap script for first-time users.
# Creates a venv, installs deps, starts the local Orchestrate server
# and imports tools + agents.

set -e

echo "📦  Creating Python virtual-environment…"
python3.11 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate

echo "⬇️  Installing Python requirements…"
python -m pip install --upgrade pip
pip install -r requirements.txt

echo "🚀  Starting Orchestrate Developer-Edition server (in background)…"
# -d → detach; we’ll capture the container name to stop later if needed
orchestrate server start --accept-license -d
sleep 5    # give the container a few seconds to boot

echo "🔧  Importing calculator tool…"
orchestrate tools import -k python -f tools/calculator_tool.py

echo "🤖  Importing agents (greeting, echo, calculator, orchestrator)…"
for file in agents/*.yaml; do
  orchestrate agents import -f "$file"
done

echo "✅  All set!  Run:  orchestrate chat start --agents orchestrator_agent"
