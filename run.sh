#!/bin/bash

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: This script must be run as root."
    echo "🔹 Try running: sudo $0"
    exit 1
fi

# URL of the script
SCRIPT_URL="https://raw.githubusercontent.com/prjkt-nv404/mkroot/refs/heads/main/mkroot.sh"
SCRIPT_PATH="/tmp/mkroot.sh"

# Function to download the script
download_script() {
    echo "🚀 Downloading mkroot.sh..."
    
    # Try wget first
    if command -v wget &>/dev/null; then
        wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"
    elif command -v curl &>/dev/null; then
        curl -s -o "$SCRIPT_PATH" "$SCRIPT_URL"
    else
        echo "❌ Error: Neither wget nor curl is installed. Please install one and retry."
        exit 1
    fi

    # Check if the download was successful
    if [[ ! -s "$SCRIPT_PATH" ]]; then
        echo "❌ Error: Failed to download mkroot.sh. Please check the URL or your internet connection."
        exit 1
    fi

    echo "✅ Download successful!"
}

# Function to run the script
run_script() {
    echo "🔹 Granting execute permission..."
    chmod +x "$SCRIPT_PATH"

    echo "🚀 Running mkroot.sh..."
    bash "$SCRIPT_PATH"

    if [[ $? -eq 0 ]]; then
        echo "✅ mkroot.sh executed successfully!"
    else
        echo "❌ Error: mkroot.sh encountered an issue while running."
        exit 1
    fi
}

# Execute functions
download_script
run_script
