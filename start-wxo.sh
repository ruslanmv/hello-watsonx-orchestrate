#!/bin/bash

# ────────────────────────────────────────────────────────────────────────────
#  watsonx Orchestrate Developer Edition Startup Script
# ────────────────────────────────────────────────────────────────────────────

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ────────────────────────────────────────────────────────────────────────────
#  Configuration
# ────────────────────────────────────────────────────────────────────────────
ENV_FILE="./.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "Starting watsonx Orchestrate Developer Edition..."
print_info "Script directory: $SCRIPT_DIR"

# ────────────────────────────────────────────────────────────────────────────
#  Pre-flight checks
# ────────────────────────────────────────────────────────────────────────────
print_info "Running pre-flight checks..."

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    print_error ".env file not found in current directory"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose v2 is available
if ! docker compose version 2>/dev/null | grep -q 'v2\.'; then
    print_error "Docker Compose v2 is required. Please upgrade Docker Compose."
    exit 1
fi

# Check if we're in a Python virtual environment
if [[ -z "$VIRTUAL_ENV" ]]; then
    print_warning "No Python virtual environment detected. It's recommended to use a venv."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if orchestrate command is available
if ! command -v orchestrate >/dev/null 2>&1; then
    print_error "orchestrate command not found. Please install the watsonx Orchestrate ADK first."
    print_info "Install with: pip install ibm-watsonx-orchestrate"
    exit 1
fi

print_success "Pre-flight checks completed"

# ────────────────────────────────────────────────────────────────────────────
#  Load and validate .env file
# ────────────────────────────────────────────────────────────────────────────
print_info "Loading environment variables from $ENV_FILE"

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Validate required variables
required_vars=("WO_DEVELOPER_EDITION_SOURCE" "WO_ENTITLEMENT_KEY" "WO_INSTANCE" "WO_API_KEY" "WATSONX_APIKEY" "WATSONX_SPACE_ID")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    print_error "Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

# Check if WO_INSTANCE contains YOUR_INSTANCE_ID placeholder
if [[ "$WO_INSTANCE" == *"YOUR_INSTANCE_ID"* ]]; then
    print_error "Please replace YOUR_INSTANCE_ID in WO_INSTANCE with your actual instance ID"
    exit 1
fi

print_success "Environment variables validated"

# ────────────────────────────────────────────────────────────────────────────
#  Stop any existing services
# ────────────────────────────────────────────────────────────────────────────
print_info "Stopping any existing watsonx Orchestrate services..."
orchestrate server stop 2>/dev/null || true

# ────────────────────────────────────────────────────────────────────────────
#  Start the server with proper TTY handling
# ────────────────────────────────────────────────────────────────────────────
print_info "Starting watsonx Orchestrate Developer Edition server..."

# Set environment variables to handle TTY issues
export COMPOSE_INTERACTIVE_NO_CLI=1
export DOCKER_BUILDKIT=1

# Function to start server with automatic acceptance
start_server() {
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "Attempt $attempt of $max_attempts to start server..."
        
        # Use expect if available, otherwise use echo with pipe
        if command -v expect >/dev/null 2>&1; then
            expect << EOF
set timeout 300
spawn orchestrate server start --env-file=$ENV_FILE
expect {
    "I accept" {
        send "I accept\r"
        exp_continue
    }
    "Do you accept" {
        send "I accept\r"
        exp_continue
    }
    "Accept" {
        send "I accept\r"
        exp_continue
    }
    "successfully" {
        exit 0
    }
    timeout {
        exit 1
    }
    eof {
        exit 0
    }
}
EOF
        else
            # Fallback method using echo and pipe
            echo "I accept" | orchestrate server start --env-file="$ENV_FILE" 2>&1
        fi
        
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            print_success "Server started successfully"
            break
        else
            print_warning "Server start attempt $attempt failed"
            if [[ $attempt -lt $max_attempts ]]; then
                print_info "Waiting 10 seconds before retry..."
                sleep 10
                print_info "Resetting server before retry..."
                echo "I accept" | orchestrate server reset --env-file="$ENV_FILE" 2>/dev/null || true
                sleep 5
            fi
        fi
        
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_error "Failed to start server after $max_attempts attempts"
        return 1
    fi
    
    return 0
}

# Start the server
if ! start_server; then
    print_error "Failed to start watsonx Orchestrate Developer Edition"
    exit 1
fi

# ────────────────────────────────────────────────────────────────────────────
#  Wait for services to be ready
# ────────────────────────────────────────────────────────────────────────────
print_info "Waiting for services to be fully initialized..."
sleep 30

# ────────────────────────────────────────────────────────────────────────────
#  Activate local environment
# ────────────────────────────────────────────────────────────────────────────
print_info "Activating local environment..."

# Try to activate local environment
max_retries=3
retry_count=0

while [[ $retry_count -lt $max_retries ]]; do
    if orchestrate env activate local; then
        print_success "Local environment activated successfully"
        break
    else
        print_warning "Failed to activate local environment (attempt $((retry_count + 1))/$max_retries)"
        ((retry_count++))
        if [[ $retry_count -lt $max_retries ]]; then
            print_info "Waiting 10 seconds before retry..."
            sleep 10
        fi
    fi
done

if [[ $retry_count -eq $max_retries ]]; then
    print_error "Failed to activate local environment after $max_retries attempts"
    print_info "You can try manually with: orchestrate env activate local"
fi

# ────────────────────────────────────────────────────────────────────────────
#  Final status and instructions
# ────────────────────────────────────────────────────────────────────────────
print_success "watsonx Orchestrate Developer Edition startup completed!"
echo
print_info "Available services:"
echo "  • UI: http://localhost:3000/chat-lite"
echo "  • API: http://localhost:4321/api/v1"
echo "  • OpenAPI Docs: http://localhost:4321/docs"
echo
print_info "Useful commands:"
echo "  • Start chat: orchestrate chat start"
echo "  • Check environment: orchestrate env list"
echo "  • Import tools: orchestrate tools import -k python -f <file>"
echo "  • Import agents: orchestrate agents import -f <file>"
echo "  • Stop server: orchestrate server stop"
echo
print_info "If you encounter issues, try:"
echo "  • orchestrate server logs (to view logs)"
echo "  • orchestrate server reset --env-file=.env (to reset completely)"
echo

# Optional: Ask if user wants to start chat immediately
read -p "Would you like to start the chat interface now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Starting chat interface..."
    orchestrate chat start
fi

print_success "Script completed successfully!"