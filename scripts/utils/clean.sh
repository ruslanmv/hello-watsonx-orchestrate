#!/bin/bash

# Interactive script to manage agents and tools.
# It fetches data, then enters a loop allowing the user to
# run multiple commands until they choose to exit.

# --- Initial Setup & Data Fetch ---
header() {
    # Function to print the header, clears the screen for a clean look
    clear
    echo "=== Watsonx Orchestrate Management Script ==="
    echo "Last refresh: $(date)"
    echo "------------------------------------------"
}

# Initial header print
header
echo "Running initial setup..."

# Define JSON filenames
AGENT_FILE="agents.json"
TOOLS_FILE="tools.json"

# Check if the orchestrate command exists
if ! command -v orchestrate &> /dev/null; then
    echo "❌ Error: 'orchestrate' command not found."
    echo "Please ensure the watsonx Orchestrate CLI is installed and in your PATH."
    exit 1
fi

echo "🔄 Fetching latest agents and tools lists..."
orchestrate agents list -v > "$AGENT_FILE"
orchestrate tools list -v > "$TOOLS_FILE"
echo "✅ Files updated: $AGENT_FILE, $TOOLS_FILE"
echo
read -n 1 -s -r -p "Press any key to continue to the main menu..."

# --- Main Interactive Loop ---
while true; do
    header # Redraw header each time the menu is shown
    
    # The 'select' command creates a menu from the options
    PS3="👉 Please choose an operation: "
    options=("list.py" "clean.py" "purge.py" "Quit")

    select script in "${options[@]}"; do
        case $script in
            "list.py"|"clean.py"|"purge.py")
                echo
                echo "🚀 Running $script..."
                echo "------------------------------------------"
                python3 "$script" # Execute the selected Python script
                echo "------------------------------------------"
                read -n 1 -s -r -p "✅ Operation finished. Press any key to return to the menu..."
                break # Exit the 'select' and restart the 'while' loop
                ;;
            "Quit")
                echo
                echo "👋 Exiting."
                exit 0 # Exit the entire script
                ;;
            *) 
                echo "❌ Invalid option '$REPLY'. Please try again."
                sleep 1
                break # Exit the 'select' to redraw the menu
                ;;
        esac
    done
done