#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ Error: This script must be run as root."
        echo "🔹 Try running: sudo $0"
        exit 1
    fi
}

# Function to display a header
print_header() {
    echo "======================================"
    echo "        MKROOT SSH  Conf. Tool        "
    echo "======================================"
}

# Function to get user input for the root password
get_root_password() {
    echo -n "Enter your preferred root password: "
    read -s ROOT_PASSWORD
    echo
    echo -n "Confirm your root password: "
    read -s ROOT_PASSWORD_CONFIRM
    echo

    if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
        echo "Error: Passwords do not match. Please try again."
        get_root_password
    fi
}

# Function to get the server's public IP (fallback to internal IP if needed)
get_ip_address() {
    # Ensure curl is installed
    if ! command -v curl &>/dev/null; then
        echo "curl not found. Installing..."
        apt update && apt install -y curl
    fi

    # Try to get public IP (requires internet access)
    PUBLIC_IP=$(curl -s https://api.ipify.org)

    # If no public IP found, fallback to internal IP
    if [[ -z "$PUBLIC_IP" ]]; then
        echo "⚠️ Could not detect public IP. Falling back to internal IP."
        PUBLIC_IP=$(ip route get 1 | awk '{print $7; exit}')
    fi

    SERVER_IP="$PUBLIC_IP"
}

# Function to copy text to clipboard (Linux & macOS support)
copy_to_clipboard() {
    if command -v xclip &>/dev/null; then
        echo -n "$1" | xclip -selection clipboard
    elif command -v pbcopy &>/dev/null; then
        echo -n "$1" | pbcopy
    else
        echo "⚠️ Clipboard copy not supported. Install 'xclip' or 'pbcopy' manually."
    fi
}

# Start of the script
check_root  # Ensure script is run as root
clear
print_header

echo "This script will enable root login and password authentication for SSH."
echo "It will also allow you to set a new root password."
echo
read -p "Do you want to proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Operation canceled. Exiting..."
    exit 1
fi

# Backup the original sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
echo "Backup of sshd_config created at /etc/ssh/sshd_config.bak."

# Allow root login
if grep -q '^#PermitRootLogin' /etc/ssh/sshd_config; then
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
elif grep -q '^PermitRootLogin' /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# Allow password authentication
if grep -q '^#PasswordAuthentication' /etc/ssh/sshd_config; then
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
elif grep -q '^PasswordAuthentication' /etc/ssh/sshd_config; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

# Check and modify files in /etc/ssh/sshd_config.d/*.conf
for conf_file in /etc/ssh/sshd_config.d/*.conf; do
    if [ -f "$conf_file" ]; then
        if grep -q '^PasswordAuthentication no' "$conf_file"; then
            sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$conf_file"
        fi
    fi
done

# Get the user's preferred root password
get_root_password

# Change the root password
echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd root
echo "Root password has been updated successfully."

# Restart the SSH service
if systemctl is-active --quiet sshd; then
    systemctl restart sshd
else
    service ssh restart
fi

# Get server IP
get_ip_address

# Generate SSH connection command
SSH_COMMAND="ssh root@$SERVER_IP"

# Copy IP and SSH command to clipboard
copy_to_clipboard "$SSH_COMMAND"

# Final Summary
echo
echo "======================================"
echo "       ✅ SSH Access Information       "
echo "======================================"
echo "🌍 Server IP Address  : $SERVER_IP"
echo "👤 Username for login : root"
echo "🔑 Password for root  : $ROOT_PASSWORD"
echo "🚀 SSH Command       : $SSH_COMMAND"
echo "📋 (Command copied to clipboard!)"
echo "======================================"
