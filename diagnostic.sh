#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────────────────
#  watsonx Orchestrate Developer Edition - Diagnostic Script
# ────────────────────────────────────────────────────────────────────────────

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}watsonx Orchestrate Developer Edition - Diagnostics${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Docker containers
print_info "Checking Docker containers..."
echo
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|wxo|orchestrate)" || {
    print_error "No watsonx Orchestrate containers found running"
    echo
    print_info "All running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

echo
print_info "Checking for containers with port 3000..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":3000" || print_warning "No containers exposing port 3000 found"

echo
print_info "Checking for containers with port 4321..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":4321" || print_warning "No containers exposing port 4321 found"

# Check port availability
echo
print_info "Checking port availability..."
for port in 3000 4321; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_success "Port $port is in use"
    else
        print_error "Port $port is not in use"
    fi
done

# Check service responses
echo
print_info "Testing service endpoints..."

# Test API health
if curl -s -f "http://localhost:4321/health" >/dev/null 2>&1; then
    print_success "API health endpoint responding"
    echo "Response: $(curl -s http://localhost:4321/health)"
else
    print_error "API health endpoint not responding"
fi

# Test API docs
if curl -s -f "http://localhost:4321/docs" >/dev/null 2>&1; then
    print_success "API docs endpoint responding"
else
    print_error "API docs endpoint not responding"
fi

# Test UI endpoint
if curl -s -f "http://localhost:3000" >/dev/null 2>&1; then
    print_success "UI endpoint responding"
else
    print_error "UI endpoint not responding"
fi

# Test chat-lite endpoint
if curl -s -f "http://localhost:3000/chat-lite" >/dev/null 2>&1; then
    print_success "Chat-lite endpoint responding"
else
    print_error "Chat-lite endpoint not responding"
fi

# Check Docker Compose services
echo
print_info "Checking Docker Compose status..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose ps 2>/dev/null || print_warning "No docker-compose.yml found or not using compose"
elif docker compose version >/dev/null 2>&1; then
    docker compose ps 2>/dev/null || print_warning "No docker-compose.yml found or not using compose"
fi

# Check container logs for errors
echo
print_info "Checking recent container logs for errors..."
for container in $(docker ps --format "{{.Names}}" | grep -E "(wxo|orchestrate)"); do
    echo
    print_info "Logs for $container (last 10 lines):"
    docker logs --tail 10 "$container" 2>&1 | head -10
done

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Diagnostic completed"