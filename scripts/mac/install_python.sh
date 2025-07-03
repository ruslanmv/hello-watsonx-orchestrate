#!/bin/bash
#
# Script to install Python 3.11 on macOS using Homebrew.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting Python 3.11 installation on macOS."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew first..."
    echo "This script will attempt to install Homebrew."
    echo "You may be prompted for your macOS password."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the current session if it's not already there
    if [ -f "/opt/homebrew/bin/brew" ]; then # For Apple Silicon Macs
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then # For Intel Macs
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew installation failed or could not be added to PATH." >&2
        echo "Please install Homebrew manually from https://brew.sh/ and run this script again." >&2
        exit 1
    fi
    echo "Homebrew installed successfully."
else
    echo "Homebrew is already installed. Updating Homebrew..."
    brew update
fi

echo "🚀 Installing Python 3.11 using Homebrew..."
# Use --force-bottle to ensure a pre-built bottle is used, which is faster
# Use --overwrite to ensure it replaces any existing links if needed
brew install python@3.11

echo "\n🎉 Python 3.11 installation complete!"
echo "You can now use 'python3.11' command."
echo "To check the version: python3.11 --version"
echo "To install packages for Python 3.11, use 'pip3.11 install <package_name>'"

# Optional: Suggest adding Python 3.11 to the default PATH if not already there
echo "\nNote: If 'python3.11' is not immediately available in your terminal,"
echo "you might need to restart your terminal or add Homebrew's Python path to your shell profile."
echo "Homebrew usually symlinks it correctly, but sometimes a shell restart helps."