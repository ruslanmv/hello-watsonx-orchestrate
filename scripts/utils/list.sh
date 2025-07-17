#!/bin/bash

# Script to list agents and tools with details
# Creates JSON files and then calls the Python listing script

echo "=== Watsonx Orchestrate Agents and Tools Listing ==="
echo "Date: $(date)"
echo

# Define JSON filenames
AGENT_FILE="agents.json"
TOOLS_FILE="tools.json"

echo "Fetching agents list with details..."
orchestrate agents list -v > "$AGENT_FILE"

echo "Fetching tools list with details..."
orchestrate tools list -v > "$TOOLS_FILE"

echo
echo "Files created:"
echo "- Agents: $AGENT_FILE"
echo "- Tools:  $TOOLS_FILE"
echo
echo "Now running Python enumeration..."
echo "=========================================="

# Invoke the Python script to list & enumerate
python3 list.py
