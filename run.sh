#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────────
#  watsonx Orchestrate Developer Edition - UI Only Runner
# ────────────────────────────────────────────────────────────────────────────

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "watsonx Orchestrate Developer Edition - UI Runner"
print_info "Script directory: $SCRIPT_DIR"

# ────────────────────────────────────────────────────────────────────────────
#  Check if services are running
# ────────────────────────────────────────────────────────────────────────────
print_info "Checking if watsonx Orchestrate services are running..."

# Check if Docker containers are running
if ! docker ps --format "table {{.Names}}" | grep -q "wxo-server"; then
    print_error "watsonx Orchestrate containers are not running!"
    print_info "Please start the services first using your startup script."
    exit 1
fi

print_success "watsonx Orchestrate containers are running"

# ────────────────────────────────────────────────────────────────────────────
#  Check service health
# ────────────────────────────────────────────────────────────────────────────
print_info "Checking service health..."

# Function to check if a URL is responding
check_url() {
    local url=$1
    local service_name=$2
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$service_name is responding"
            return 0
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_warning "$service_name is not responding at $url"
            return 1
        fi
        
        print_info "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 3
        ((attempt++))
    done
}

# Check API health
check_url "http://localhost:4321/health" "API Service"

# Check if UI port is accessible (we don't need the full UI to be ready)
if netstat -tuln 2>/dev/null | grep -q ":3000 " || ss -tuln 2>/dev/null | grep -q ":3000 "; then
    print_success "UI port 3000 is accessible"
else
    print_warning "UI port 3000 might not be ready yet"
fi

# ────────────────────────────────────────────────────────────────────────────
#  Activate local environment (if needed)
# ────────────────────────────────────────────────────────────────────────────
print_info "Ensuring local environment is active..."

# Check current environment
current_env=$(orchestrate env list 2>/dev/null | grep "(active)" | awk '{print $1}' || echo "none")

if [[ "$current_env" != "local" ]]; then
    print_info "Activating local environment..."
    if orchestrate env activate local; then
        print_success "Local environment activated"
    else
        print_warning "Could not activate local environment, but services should still be accessible"
    fi
else
    print_success "Local environment is already active"
fi

# ────────────────────────────────────────────────────────────────────────────
#  Display service information
# ────────────────────────────────────────────────────────────────────────────
echo
print_success "watsonx Orchestrate Developer Edition is running!"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Available Services:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo -e "🌐 ${BLUE}Web UI (Chat Interface):${NC}"
echo -e "   ${YELLOW}http://localhost:3000/chat-lite${NC}"
echo
echo -e "🔧 ${BLUE}API Endpoint:${NC}"
echo -e "   ${YELLOW}http://localhost:4321/api/v1${NC}"
echo
echo -e "📚 ${BLUE}API Documentation:${NC}"
echo -e "   ${YELLOW}http://localhost:4321/docs${NC}"
echo
echo -e "💚 ${BLUE}Health Check:${NC}"
echo -e "   ${YELLOW}http://localhost:4321/health${NC}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo -e "📝 ${BLUE}To create and import tools:${NC}"
echo -e "   ${YELLOW}orchestrate tools import -k python -f <your_tool_file.py>${NC}"
echo -e "   ${YELLOW}orchestrate tools import -k openapi -f <your_openapi_spec.yaml>${NC}"
echo
echo -e "🤖 ${BLUE}To create and import agents:${NC}"
echo -e "   ${YELLOW}orchestrate agents import -f <your_agent_file.yaml>${NC}"
echo
echo -e "💬 ${BLUE}To start chat (after creating agents):${NC}"
echo -e "   ${YELLOW}orchestrate chat start${NC}"
echo
echo -e "📋 ${BLUE}To list current resources:${NC}"
echo -e "   ${YELLOW}orchestrate tools list${NC}"
echo -e "   ${YELLOW}orchestrate agents list${NC}"
echo -e "   ${YELLOW}orchestrate env list${NC}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ────────────────────────────────────────────────────────────────────────────
#  Optional: Open browser
# ────────────────────────────────────────────────────────────────────────────
echo
read -p "$(echo -e "${BLUE}[INFO]${NC} Would you like to open the Web UI in your browser? (y/N): ")" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Opening Web UI in browser..."
    
    # Try different browser commands based on the system
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "http://localhost:3000/chat-lite" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
        open "http://localhost:3000/chat-lite" >/dev/null 2>&1 &
    elif command -v start >/dev/null 2>&1; then
        start "http://localhost:3000/chat-lite" >/dev/null 2>&1 &
    else
        print_warning "Could not detect browser command. Please manually open:"
        echo -e "   ${YELLOW}http://localhost:3000/chat-lite${NC}"
    fi
    
    print_success "Browser should open shortly"
fi

echo
print_success "UI runner completed successfully!"
print_info "The services will continue running in the background."
print_info "Use 'orchestrate server stop' to stop all services when done."