#!/usr/bin/env bash
#
# Script to install Python 3.12 on Ubuntu/Debian-based systems,
# and set it as the default `python3`.
#
# Usage: sudo ./install_python312.sh

set -euo pipefail

echo "🔎 Checking OS compatibility..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"debian"* ]]; then
        echo "❌ Unsupported OS: this is for Ubuntu/Debian derivatives." >&2
        exit 1
    fi
else
    echo "❌ Cannot detect OS. Exiting." >&2
    exit 1
fi

echo "🔎 Checking for existing Python 3.12..."
if command -v python3.12 >/dev/null 2>&1; then
    echo "✅ Found $(python3.12 --version)."
else
    echo "🚀 Installing Python 3.12 and prerequisites..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.12 python3.12-venv python3.12-dev python3.12-distutils
    # Ensure pip for 3.12
    sudo python3.12 -m ensurepip --upgrade
fi

echo "🔧 Configuring update-alternatives for python3..."
# Register Python 3.12 with a higher priority than system version (e.g. 1)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2

# If there are multiple python3 versions, this lets user choose interactively:
if [ "$(update-alternatives --query python3 | grep 'Value: ' | awk '{print $2}')" != "/usr/bin/python3.12" ]; then
    echo ""
    echo "⚙️  Multiple python3 versions detected. Selecting default:"
    sudo update-alternatives --config python3
else
    echo "✅ /usr/bin/python3 now points to Python 3.12"
fi

echo ""
echo "🎉 Done! Verify with:"
echo "    python3 --version"
echo "    python3 -m venv myenv && source myenv/bin/activate"
