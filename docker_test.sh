#!/bin/bash
# docker_test.sh - Test Docker registry connection for watsonx Orchestrate Developer Edition

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Docker Registry Connection Test ===${NC}"

# Function to load .env file
load_env_file() {
    local env_file="$1"
    
    if [[ ! -f "$env_file" ]]; then
        echo -e "${RED}❌ Error: .env file not found at $env_file${NC}"
        echo -e "${CYAN}💡 Troubleshooting: https://ibm.github.io/watsonx-orchestrate-adk-docs/getting_started/wxOde_setup${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}📄 Loading environment variables from: $env_file${NC}"
    
    # Load .env file and export variables
    set -a  # automatically export all variables
    source "$env_file"
    set +a  # stop automatically exporting
    
    echo -e "${GREEN}✅ Environment file loaded${NC}"
}

# Function to validate required environment variables
validate_env_vars() {
    echo -e "${YELLOW}🔍 Validating environment variables...${NC}"
    
    if [[ -z "$WO_DEVELOPER_EDITION_SOURCE" ]]; then
        echo -e "${RED}❌ WO_DEVELOPER_EDITION_SOURCE is not set${NC}"
        echo -e "${CYAN}💡 Troubleshooting: https://ibm.github.io/watsonx-orchestrate-adk-docs/getting_started/wxOde_setup${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ WO_DEVELOPER_EDITION_SOURCE: $WO_DEVELOPER_EDITION_SOURCE${NC}"
    
    if [[ "$WO_DEVELOPER_EDITION_SOURCE" == "myibm" ]]; then
        if [[ -z "$WO_ENTITLEMENT_KEY" ]]; then
            echo -e "${RED}❌ WO_ENTITLEMENT_KEY is required for myibm source${NC}"
            echo -e "${CYAN}💡 Get entitlement key: https://myibm.ibm.com/${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ WO_ENTITLEMENT_KEY is set (length: ${#WO_ENTITLEMENT_KEY})${NC}"
        
        if [[ -z "$WATSONX_APIKEY" ]]; then
            echo -e "${YELLOW}⚠️  WATSONX_APIKEY is not set${NC}"
        else
            echo -e "${GREEN}✅ WATSONX_APIKEY is set${NC}"
        fi
        
        if [[ -z "$WATSONX_SPACE_ID" ]]; then
            echo -e "${YELLOW}⚠️  WATSONX_SPACE_ID is not set${NC}"
        else
            echo -e "${GREEN}✅ WATSONX_SPACE_ID is set${NC}"
        fi
        
    elif [[ "$WO_DEVELOPER_EDITION_SOURCE" == "orchestrate" ]]; then
        if [[ -z "$WO_INSTANCE" ]]; then
            echo -e "${RED}❌ WO_INSTANCE is required for orchestrate source${NC}"
            exit 1
        fi
        if [[ -z "$WO_API_KEY" ]]; then
            echo -e "${RED}❌ WO_API_KEY is required for orchestrate source${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ WO_INSTANCE and WO_API_KEY are set${NC}"
    fi
}

# Function to test basic connectivity
test_connectivity() {
    echo -e "${YELLOW}🌐 Testing network connectivity...${NC}"
    
    # Test basic internet connectivity
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}✅ Internet connectivity: OK${NC}"
    else
        echo -e "${RED}❌ No internet connectivity${NC}"
        echo -e "${CYAN}💡 Check your network connection${NC}"
        exit 1
    fi
    
    # Test Docker registry connectivity
    if curl -s --connect-timeout 10 https://cp.icr.io &> /dev/null; then
        echo -e "${GREEN}✅ Docker registry reachable: cp.icr.io${NC}"
    else
        echo -e "${RED}❌ Cannot reach Docker registry: cp.icr.io${NC}"
        echo -e "${CYAN}💡 Check firewall/proxy settings${NC}"
        exit 1
    fi
}

# Function to test Docker installation
test_docker() {
    echo -e "${YELLOW}🐳 Testing Docker installation...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        echo -e "${CYAN}💡 Install Docker: https://docs.docker.com/engine/install/${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker command found${NC}"
    
    # Test Docker daemon
    if docker info &> /dev/null; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
        echo -e "${GREEN}   Docker version: $(docker --version)${NC}"
    else
        echo -e "${RED}❌ Docker daemon is not running or permission denied${NC}"
        echo -e "${CYAN}💡 Troubleshooting: https://ibm.github.io/watsonx-orchestrate-adk-docs/release/troubleshooting${NC}"
        exit 1
    fi
    
    # Test Docker Compose
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose v2 available${NC}"
        echo -e "${GREEN}   $(docker compose version)${NC}"
    elif docker-compose --version &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker Compose v1 detected - v2 recommended${NC}"
        echo -e "${CYAN}💡 Upgrade to Docker Compose v2${NC}"
    else
        echo -e "${RED}❌ Docker Compose not found${NC}"
        echo -e "${CYAN}💡 Install Docker Compose: https://docs.docker.com/compose/install/${NC}"
    fi
}

# Function to test Docker registry authentication
test_docker_auth() {
    echo -e "${YELLOW}🔐 Testing Docker registry authentication...${NC}"
    
    if [[ "$WO_DEVELOPER_EDITION_SOURCE" == "myibm" && -n "$WO_ENTITLEMENT_KEY" ]]; then
        echo -e "${YELLOW}   Attempting login to cp.icr.io with entitlement key...${NC}"
        
        # Test Docker login
        if echo "$WO_ENTITLEMENT_KEY" | docker login cp.icr.io -u cp --password-stdin &> /dev/null; then
            echo -e "${GREEN}✅ Docker registry authentication successful${NC}"
            
            # Test pulling a small image to verify access
            echo -e "${YELLOW}   Testing image pull access...${NC}"
            if docker pull cp.icr.io/cp/wxo-lite/wxo-server-db:24-06-2025-v1 --quiet &> /dev/null; then
                echo -e "${GREEN}✅ Image pull test successful${NC}"
                # Clean up the test image
                docker rmi cp.icr.io/cp/wxo-lite/wxo-server-db:24-06-2025-v1 &> /dev/null || true
            else
                echo -e "${RED}❌ Image pull failed - TLS/authentication error${NC}"
                echo -e "${CYAN}💡 This is likely the 'tls: bad record MAC' error${NC}"
                echo -e "${CYAN}💡 Troubleshooting: https://ibm.github.io/watsonx-orchestrate-adk-docs/release/troubleshooting${NC}"
                
                # Suggest Docker config fix
                echo -e "${YELLOW}   Suggested fix: Update Docker config${NC}"
                echo -e "${CYAN}   1. Create/edit ~/.docker/config.json${NC}"
                echo -e "${CYAN}   2. Add authentication entry for cp.icr.io${NC}"
                echo -e "${CYAN}   3. Use base64 encoded 'cp:your_entitlement_key'${NC}"
                
                return 1
            fi
        else
            echo -e "${RED}❌ Docker registry authentication failed${NC}"
            echo -e "${CYAN}💡 Check your entitlement key: https://myibm.ibm.com/${NC}"
            echo -e "${CYAN}💡 Troubleshooting: https://ibm.github.io/watsonx-orchestrate-adk-docs/release/troubleshooting${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Skipping Docker auth test (orchestrate source or missing key)${NC}"
    fi
}

# Function to check Docker configuration
check_docker_config() {
    echo -e "${YELLOW}🔧 Checking Docker configuration...${NC}"
    
    local docker_config="$HOME/.docker/config.json"
    
    if [[ -f "$docker_config" ]]; then
        echo -e "${GREEN}✅ Docker config file exists: $docker_config${NC}"
        
        if grep -q "cp.icr.io" "$docker_config" 2>/dev/null; then
            echo -e "${GREEN}✅ cp.icr.io entry found in Docker config${NC}"
        else
            echo -e "${YELLOW}⚠️  No cp.icr.io entry in Docker config${NC}"
            echo -e "${CYAN}💡 You may need to add authentication entry manually${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No Docker config file found${NC}"
        echo -e "${CYAN}💡 Docker will create one after first login${NC}"
    fi
}

# Function to provide troubleshooting summary
troubleshooting_summary() {
    echo -e "\n${BLUE}=== Troubleshooting Resources ===${NC}"
    echo -e "${CYAN}📚 Main Documentation: https://ibm.github.io/watsonx-orchestrate-adk-docs/${NC}"
    echo -e "${CYAN}🔧 Installation Guide: https://ibm.github.io/watsonx-orchestrate-adk-docs/getting_started/wxOde_setup${NC}"
    echo -e "${CYAN}🛠️  Troubleshooting Guide: https://ibm.github.io/watsonx-orchestrate-adk-docs/release/troubleshooting${NC}"
    echo -e "${CYAN}🔑 Get Entitlement Key: https://myibm.ibm.com/${NC}"
    echo -e "${CYAN}🐳 Docker Installation: https://docs.docker.com/engine/install/${NC}"
    echo -e "${CYAN}📦 Docker Compose v2: https://docs.docker.com/compose/install/${NC}"
}

# Main execution
main() {
    local env_file="${1:-.env}"
    
    echo -e "${BLUE}Starting Docker registry connection test...${NC}\n"
    
    # Run all tests
    load_env_file "$env_file"
    echo ""
    
    validate_env_vars
    echo ""
    
    test_connectivity
    echo ""
    
    test_docker
    echo ""
    
    check_docker_config
    echo ""
    
    if test_docker_auth; then
        echo -e "\n${GREEN}🎉 All tests passed! Docker registry connection is working.${NC}"
        echo -e "${GREEN}You should be able to run: orchestrate server start --env-file=$env_file${NC}"
    else
        echo -e "\n${RED}❌ Docker authentication test failed.${NC}"
        echo -e "${YELLOW}This is likely the cause of your 'tls: bad record MAC' error.${NC}"
    fi
    
    troubleshooting_summary
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [path_to_env_file]"
    echo ""
    echo "Test Docker registry connection for watsonx Orchestrate Developer Edition"
    echo ""
    echo "Arguments:"
    echo "  path_to_env_file    Path to .env file (default: .env)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Use .env in current directory"
    echo "  $0 /path/to/.env    # Use specific .env file"
    exit 0
fi

# Run main function
main "$@"