#!/bin/bash

# A script to configure a static IP address on CentOS Stream 9 using nmcli.
# It takes the desired static IP as the first argument.

# --- Configuration & Safety Checks ---

# 1. Check if running as root
if [[ "${EUID}" -ne 0 ]]; then
  echo "❌ This script must be run as root or with sudo."
  exit 1
fi

# 2. Check for the IP address argument
STATIC_IP=$1
if [[ -z "$STATIC_IP" ]]; then
  echo "Usage: sudo $0 <desired_static_ip>"
  echo "Example: sudo $0 192.168.1.100"
  exit 1
fi

# --- Gather Network Information ---

# 3. Auto-detect the primary network interface (the one with the default route)
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
if [[ -z "$INTERFACE" ]]; then
    echo "❌ Could not automatically determine the primary network interface."
    exit 1
fi
echo "✅ Network interface detected: $INTERFACE"

# 4. Get the active connection name for that interface
CONNECTION_NAME=$(nmcli -t -f NAME,DEVICE con show --active | grep "$INTERFACE" | cut -d: -f1)
if [[ -z "$CONNECTION_NAME" ]]; then
    echo "❌ Could not find an active connection for interface $INTERFACE."
    exit 1
fi
echo "✅ Connection name detected: $CONNECTION_NAME"


# 5. Prompt user for Gateway and DNS information
read -p "Enter Gateway IP: " GATEWAY
read -p "Enter DNS Server (e.g., 8.8.8.8): " DNS1

if [[ -z "$GATEWAY" || -z "$DNS1" ]]; then
    echo "❌ Gateway and DNS server cannot be empty."
    exit 1
fi

# --- Apply Network Configuration ---

echo -e "\nApplying the following configuration:"
echo "-----------------------------------"
echo "Connection:      $CONNECTION_NAME"
echo "IP Address:      $STATIC_IP/24"
echo "Gateway:         $GATEWAY"
echo "DNS:             $DNS1"
echo "-----------------------------------"
read -p "Is this correct? (y/n) " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

echo "\n⚙️  Configuring static IP..."
# The /24 subnet mask is common, but you may need to change it.
nmcli con mod "$CONNECTION_NAME" ipv4.method manual
nmcli con mod "$CONNECTION_NAME" ipv4.addresses "$STATIC_IP/24"
nmcli con mod "$CONNECTION_NAME" ipv4.gateway "$GATEWAY"
nmcli con mod "$CONNECTION_NAME" ipv4.dns "$DNS1"
nmcli con mod "$CONNECTION_NAME" connection.autoconnect yes

echo "⚙️  Restarting connection to apply settings..."
# Bring the connection down and then up to apply changes
nmcli con down "$CONNECTION_NAME" && nmcli con up "$CONNECTION_NAME"

echo -e "\n🎉 Configuration complete! Run 'ip a' to verify your new IP address."
