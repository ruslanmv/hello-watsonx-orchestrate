#!/bin/bash
# run.sh - Import agents and tools, then optionally start the chat UI

set -e  # Exit on any error

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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}=== watsonx Orchestrate Agent Setup ===${NC}"
echo "Working directory: $SCRIPT_DIR"

# Function to check if a command was successful
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Function to check if orchestrate command is available
check_orchestrate() {
    if ! command -v orchestrate &> /dev/null; then
        echo -e "${RED}Error: 'orchestrate' command not found${NC}"
        echo "Please make sure the watsonx Orchestrate ADK is installed and in your PATH"
        exit 1
    fi
}

# Function to check if server is running
check_server() {
    echo -e "${YELLOW}Checking if orchestrate server is running...${NC}"
    
    # Try to ping the server
    if curl -s http://localhost:4321/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server is running${NC}"
    else
        echo -e "${RED}✗ Server is not running or not ready${NC}"
        echo "Please start the server first with: ./start.sh"
        echo "Or run: orchestrate server start --env-file=.env"
        exit 1
    fi
}

# Function to activate local environment
activate_environment() {
    echo -e "${CYAN}Step 1: Activating local environment...${NC}"
    orchestrate env activate local
    check_command "Environment activation"
}

# Function to import tools
import_tools() {
    echo -e "${CYAN}Step 2: Importing tools...${NC}"
    
    # Check if tools directory exists
    if [ ! -d "tools" ]; then
        echo -e "${RED}Error: tools/ directory not found${NC}"
        echo "Please make sure you have a tools/ directory with your tool files"
        exit 1
    fi
    
    # Import calculator tool
    if [ -f "tools/calculator_tool.py" ]; then
        echo "Importing calculator tool..."
        orchestrate tools import -k python -f tools/calculator_tool.py
        check_command "Calculator tool import"
    else
        echo -e "${YELLOW}Warning: tools/calculator_tool.py not found, skipping...${NC}"
    fi
    
    # Import any other Python tools in the tools directory
    for tool_file in tools/*.py; do
        if [ -f "$tool_file" ] && [ "$tool_file" != "tools/calculator_tool.py" ]; then
            echo "Importing $(basename "$tool_file")..."
            orchestrate tools import -k python -f "$tool_file"
            check_command "$(basename "$tool_file") import"
        fi
    done
    
    # Import any OpenAPI tools
    for tool_file in tools/*.yaml tools/*.yml; do
        if [ -f "$tool_file" ]; then
            echo "Importing $(basename "$tool_file")..."
            orchestrate tools import -k openapi -f "$tool_file"
            check_command "$(basename "$tool_file") import"
        fi
    done
}

# Function to import agents
import_agents() {
    echo -e "${CYAN}Step 3: Importing agents...${NC}"
    
    # Check if agents directory exists
    if [ ! -d "agents" ]; then
        echo -e "${RED}Error: agents/ directory not found${NC}"
        echo "Please make sure you have an agents/ directory with your agent files"
        exit 1
    fi
    
    # Import individual agents first (not the orchestrator)
    declare -a individual_agents=("greeting_agent.yaml" "calculator_agent.yaml" "echo_agent.yaml")
    
    for agent in "${individual_agents[@]}"; do
        if [ -f "agents/$agent" ]; then
            echo "Importing $agent..."
            orchestrate agents import -f "agents/$agent"
            check_command "$agent import"
        else
            echo -e "${YELLOW}Warning: agents/$agent not found, skipping...${NC}"
        fi
    done
    
    # Import any other agent files (except orchestrator)
    for agent_file in agents/*.yaml agents/*.yml; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file")
            # Skip if it's the orchestrator or already imported
            if [[ "$agent_name" != "orchestrator_agent.yaml" ]] && [[ ! " ${individual_agents[@]} " =~ " ${agent_name} " ]]; then
                echo "Importing $agent_name..."
                orchestrate agents import -f "$agent_file"
                check_command "$agent_name import"
            fi
        fi
    done
    
    # Import orchestrator agent last
    if [ -f "agents/orchestrator_agent.yaml" ]; then
        echo "Importing orchestrator agent (final step)..."
        orchestrate agents import -f agents/orchestrator_agent.yaml
        check_command "Orchestrator agent import"
    else
        echo -e "${YELLOW}Warning: agents/orchestrator_agent.yaml not found${NC}"
    fi
}

# Function to list imported agents
list_agents() {
    echo -e "${CYAN}Step 4: Checking imported agents...${NC}"
    echo "Currently imported agents:"
    orchestrate agents list
    check_command "Agent listing"
}

# Function to ask about starting UI
# Function to ask about starting UI
ask_start_ui_old() {
    echo -e "${CYAN}Step 5: Chat Interface${NC}"
    echo ""
    echo "All agents have been imported successfully!"
    echo ""
    
    # Show available options
    echo "You can now:"
    echo "1. Start the chat UI (opens in browser)"
    echo "2. Exit and start the UI later"
    echo ""
    
    while true; do
        read -p "What would you like to do? (1/2): " choice
        case $choice in
            1)
                echo -e "${GREEN}Starting chat UI...${NC}"
                echo "Opening chat interface in your browser..."
                orchestrate chat start
                break
                ;;
            2)
                echo -e "${YELLOW}Exiting. You can start the chat UI later with:${NC}"
                echo "  orchestrate chat start"
                echo ""
                echo "The chat UI will be available at: http://localhost:3000/chat-lite"
                break
                ;;
            *)
                echo "Please enter 1 or 2"
                ;;
        esac
    done
}

# Function to ask about starting UI
ask_start_ui() {
    echo -e "${CYAN}Step 5: Chat Interface${NC}"
    echo ""
    echo "All agents have been imported successfully!"
    echo ""
    
    while true; do
        read -p "Would you like to start the chat UI now? (y/n): " choice
        case $choice in
            [Yy]*)
                echo -e "${GREEN}Starting chat UI...${NC}"
                orchestrate chat start &
                sleep 2
                echo ""
                echo -e "${GREEN}✓ Chat UI is starting!${NC}"
                echo -e "${YELLOW}📌 Open your browser and go to: http://localhost:3000/chat-lite${NC}"
                echo ""
                break
                ;;
            [Nn]*)
                echo -e "${YELLOW}You can start the chat UI later with: orchestrate chat start${NC}"
                echo "The chat UI will be available at: http://localhost:3000/chat-lite"
                break
                ;;
            *)
                echo "Please enter y or n"
                ;;
        esac
    done
}


# Function to show helpful information
show_info() {
    echo ""
    echo -e "${BLUE}=== Helpful Information ===${NC}"
    echo "• Chat UI will be available at: http://localhost:3000/chat-lite"
    echo "• API documentation: http://localhost:4321/docs"
    echo "• To stop the server: orchestrate server stop"
    echo "• To view logs: orchestrate server logs"
    echo "• To list agents: orchestrate agents list"
    echo "• To list tools: orchestrate tools list"
    echo ""
}

# Main execution
main() {
    echo -e "${GREEN}Starting agent import and setup process...${NC}"
    echo ""
    
    # Run all steps
    check_orchestrate
    check_server
    activate_environment
    import_tools
    import_agents
    list_agents
    show_info
    ask_start_ui
    
    echo ""
    echo -e "${GREEN}=== Setup Complete! ===${NC}"
}

# Run main function
main