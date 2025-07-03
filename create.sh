#!/bin/bash

# Create root level files
touch README.md
touch LICENSE
touch .gitignore
touch requirements.txt
touch setup.sh

# Create agents directory and files
mkdir -p agents/
touch agents/greeting_agent.yaml
touch agents/echo_agent.yaml
touch agents/calculator_agent.yaml
touch agents/orchestrator_agent.yaml

# Create tools directory and files
mkdir -p tools/
touch tools/calculator_tool.py

# Create tests directory and files
mkdir -p tests/
touch tests/test_router.py

# Create .github/workflows directory and files
mkdir -p .github/workflows/
touch .github/workflows/ci.yml

echo "File tree created successfully!"
