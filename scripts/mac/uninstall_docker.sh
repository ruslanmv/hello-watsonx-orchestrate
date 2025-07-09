#!/bin/bash

# Interactive Docker Environment Uninstall Script for macOS
# Cleans up Rancher Desktop, Colima, and standard Docker Desktop installations.

# Exit on any error to prevent unexpected behavior
set -e

# --- Configuration: Colors for script output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# --- Helper Functions ---

# Function to print messages in a specific color
# Arguments: $1 = Color, $2 = Message
print_color() {
    printf "${1}${2}${NC}\n"
}

# Function to print a formatted header
# Arguments: $1 = Header Text
print_header() {
    echo
    print_color "$BLUE" "================================================="
    print_color "$BLUE" "$1"
    print_color "$BLUE" "================================================="
    echo
}

# Function to check if a command exists
# Arguments: $1 = Command Name
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ask for user confirmation before proceeding
# Arguments: $1 = Prompt Message
ask_for_confirmation() {
    read -p "$1 (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Operation cancelled."
        return 1
    fi
    return 0
}

# --- Uninstall Functions ---

# Function to uninstall Rancher Desktop and its data
uninstall_rancher() {
    print_header "Uninstalling Rancher Desktop"
    if [[ ! -d "/Applications/Rancher Desktop.app" ]]; then
        print_color "$GREEN" "✓ Rancher Desktop is not installed."
        return
    fi

    print_color "$YELLOW" "Found Rancher Desktop installation."
    if ! ask_for_confirmation "Do you want to uninstall it and remove all its data?"; then
        return
    fi

    print_color "$BLUE" "Stopping Rancher Desktop processes..."
    # Kill the app process if it's running
    pkill -f "Rancher Desktop" || true
    sleep 2

    print_color "$BLUE" "Uninstalling Rancher Desktop application via Homebrew..."
    if brew list --cask | grep -q "rancher-desktop"; then
        brew uninstall --cask rancher-desktop --zap
    else
        print_color "$YELLOW" "Rancher Desktop not found in Homebrew casks. Deleting application file..."
        rm -rf "/Applications/Rancher Desktop.app"
    fi

    print_color "$BLUE" "Removing Rancher Desktop configuration and data files..."
    rm -rf "~/Library/Application Support/rancher-desktop"
    rm -rf "~/Library/Caches/rancher-desktop"
    rm -rf "~/Library/Preferences/io.rancherdesktop.app.plist"
    rm -rf "~/Library/Logs/rancher-desktop"
    rm -rf "~/.rd"

    print_color "$BLUE" "Removing Rancher Desktop context from Docker..."
    if command_exists docker && docker context ls | grep -q "rancher-desktop"; then
        docker context rm rancher-desktop
    fi

    print_color "$GREEN" "✓ Rancher Desktop uninstallation complete."
}

# Function to uninstall Colima and related Docker tools
uninstall_colima() {
    print_header "Uninstalling Colima and Docker CLI"
    if ! command_exists colima; then
        print_color "$GREEN" "✓ Colima is not installed."
        return
    fi

    print_color "$YELLOW" "Found Colima installation."
    if ! ask_for_confirmation "Do you want to uninstall Colima and the associated Docker CLI tools?"; then
        return
    fi

    print_color "$BLUE" "Stopping and deleting Colima VM..."
    colima stop || true
    colima delete || true

    print_color "$BLUE" "Uninstalling packages via Homebrew..."
    brew uninstall colima docker docker-compose

    print_color "$BLUE" "Removing Colima configuration files..."
    rm -rf "~/.colima"

    print_color "$BLUE" "Removing Colima context from Docker..."
    if command_exists docker && docker context ls | grep -q "colima"; then
        docker context rm colima
    fi

    print_color "$GREEN" "✓ Colima and Docker CLI uninstallation complete."
}

# Function to perform a deep clean of Docker system data (containers, images, etc.)
cleanup_docker_data() {
    print_header "Deep Cleaning Docker System Data"
    if ! command_exists docker; then
        print_color "$GREEN" "✓ Docker command not found, skipping data cleanup."
        return
    fi

    print_color "$YELLOW" "This will permanently delete all Docker containers, images, volumes, and networks."
    if ! ask_for_confirmation "Are you absolutely sure you want to proceed?"; then
        return
    fi

    print_color "$BLUE" "Pruning Docker system..."
    docker system prune --all --force --volumes

    print_color "$GREEN" "✓ Docker system data has been cleaned."
}


# --- Verification Function ---

# Function to verify that components have been uninstalled
verify_cleanup() {
    print_header "Verifying Cleanup"
    local all_clean=true

    # Check for Docker CLI
    if command_exists docker; then
        print_color "$RED" "✗ Docker CLI is still installed: $(command -v docker)"
        all_clean=false
    else
        print_color "$GREEN" "✓ Docker CLI is not found."
    fi

    # Check for Docker Compose
    if command_exists docker-compose; then
        print_color "$RED" "✗ Docker Compose is still installed: $(command -v docker-compose)"
        all_clean=false
    else
        print_color "$GREEN" "✓ Docker Compose is not found."
    fi

    # Check for Colima
    if command_exists colima; then
        print_color "$RED" "✗ Colima is still installed: $(command -v colima)"
        all_clean=false
    else
        print_color "$GREEN" "✓ Colima is not found."
    fi

    # Check for Rancher Desktop App
    if [[ -d "/Applications/Rancher Desktop.app" ]]; then
        print_color "$RED" "✗ Rancher Desktop application still exists."
        all_clean=false
    else
        print_color "$GREEN" "✓ Rancher Desktop application is not found."
    fi

    echo
    if [ "$all_clean" = true ]; then
        print_color "$GREEN" "🎉 Verification complete. System appears clean!"
    else
        print_color "$YELLOW" "Verification complete. Some components remain."
    fi
}

# --- Main Menu and Script Logic ---

# Function to display the main menu
show_menu() {
    clear
    print_header "Interactive Docker Environment Uninstaller"
    print_color "$BLUE" "System: macOS $(sw_vers -productVersion)"
    echo
    print_color "$YELLOW" "Choose an option to uninstall:"
    echo
    echo " 1) Uninstall Rancher Desktop"
    echo " 2) Uninstall Colima and Docker CLI tools"
    echo
    print_color "$PURPLE" " 3) Deep Clean Docker Data (Images, Containers, etc.)"
    echo
    print_color "$GREEN" " 4) Verify Cleanup"
    print_color "$RED" " 5) Exit"
    echo
}

# Main script execution logic
main() {
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_color "$RED" "This script is designed for macOS only!"
        exit 1
    fi

    while true; do
        show_menu
        read -p "Enter your choice (1-5): " choice

        case $choice in
            1)
                uninstall_rancher
                read -p "Press Enter to return to the menu..."
                ;;
            2)
                uninstall_colima
                read -p "Press Enter to return to the menu..."
                ;;
            3)
                cleanup_docker_data
                read -p "Press Enter to return to the menu..."
                ;;
            4)
                verify_cleanup
                read -p "Press Enter to return to the menu..."
                ;;
            5)
                print_color "$GREEN" "Goodbye!"
                exit 0
                ;;
            *)
                print_color "$RED" "Invalid option. Please choose 1-5."
                sleep 2
                ;;
        esac
    done
}

# Run the main function
main "$@"
