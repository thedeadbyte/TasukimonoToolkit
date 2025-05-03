#!/bin/bash

# Exit on any error
set -e

# Step 1: Import the Kali GPG key
echo "Importing Kali GPG key..."
wget -q -O - https://archive.kali.org/archive-key.asc | sudo gpg --import

# Step 2: Export the key to APT trusted keyring
echo "Exporting key to APT trusted keyring..."
sudo gpg --export ED65462EC8D5E4C5 | sudo tee /etc/apt/trusted.gpg.d/kali-archive-key.gpg > /dev/null

# Step 3: Remove any incorrect .asc key file
echo "Removing any incorrect .asc key file..."
sudo rm -f /etc/apt/trusted.gpg.d/kali-archive-key.asc

# Step 4: Ensure correct Kali repository configuration
echo "Configuring Kali repository..."
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

# Step 5: Clean APT cache
echo "Cleaning APT cache..."
sudo apt clean

# Step 6: Update package lists
echo "Updating package lists..."
sudo apt update

echo "Process completed successfully!"
