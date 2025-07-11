#!/bin/bash
# start.sh - Start watsonx Orchestrate Developer Edition

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


if [[ -d "venv" ]]; then
  echo "📦 Found existing venv. Activating…"
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🔧 Python $(python --version)"
  ADK_VERSION=$(pip show ibm-watsonx-orchestrate 2>/dev/null \
                | awk '/^Version:/{print $2}')
  if [[ -z "$ADK_VERSION" ]]; then
    echo "⚠️ Could not detect installed ADK version."
  else
    echo "✅ Detected ADK version $ADK_VERSION"
  fi
else
  echo "❌ venv environment not found. Cannot proceed—please create it first."
  exit 1
fi
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}Starting watsonx Orchestrate Developer Edition...${NC}"
echo "Working directory: $SCRIPT_DIR"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found in $SCRIPT_DIR${NC}"
    echo "Please create a .env file with the required configuration."
    echo "Example:"
    echo "WO_DEVELOPER_EDITION_SOURCE=myibm"
    echo "WO_ENTITLEMENT_KEY=your_key_here"
    echo "WATSONX_APIKEY=your_api_key_here"
    echo "WATSONX_SPACE_ID=your_space_id_here"
    exit 1
fi

echo -e "${YELLOW}Using .env file: $SCRIPT_DIR/.env${NC}"

# Check if orchestrate command is available
if ! command -v orchestrate &> /dev/null; then
    echo -e "${RED}Error: 'orchestrate' command not found${NC}"
    echo "Please make sure the watsonx Orchestrate ADK is installed and in your PATH"
    exit 1
fi
# Start the server
echo -e "${GREEN}Starting server...${NC}"
orchestrate server start --env-file=.env