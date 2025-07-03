#!/bin/bash
#
# Script to install Python 3.11 on Ubuntu.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting Python 3.11 installation on Ubuntu."

# Check if the operating system is Ubuntu/Debian-based
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID_LIKE" != "debian" ]]; then
        echo "This script is designed for Ubuntu/Debian-based Linux systems." >&2
        exit 1
    fi
else
    echo "Cannot determine OS. This script is designed for Ubuntu/Debian-based Linux systems." >&2
    exit 1
fi

echo "🚀 Updating package list..."
sudo apt update

echo "🚀 Installing software-properties-common..."
sudo apt install -y software-properties-common

echo "🚀 Adding deadsnakes PPA..."
# The -y flag automatically accepts adding the PPA
sudo add-apt-repository -y ppa:deadsnakes/ppa

echo "🚀 Updating package list after adding PPA..."
sudo apt update

echo "🚀 Installing Python 3.11..."
sudo apt install -y python3.11

echo "🚀 Installing python3.11-venv..."
sudo apt install -y python3.11-venv

echo "🚀 Installing python3.11-dev..."
sudo apt install -y python3.11-dev

echo "\n🎉 Python 3.11 installation complete!"
echo "You can now use 'python3.11' command."
echo "To check the version: python3.11 --version"