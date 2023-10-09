#!/bin/bash
# Jbrowse Install script by @shreyas-a-s

# Install system pre-requisites
sudo apt update && sudo apt install build-essential zlib1g-dev unzip -y

# Download and setup jbrowse
curl -L -O https://github.com/GMOD/jbrowse/releases/download/1.16.11-release/JBrowse-1.16.11.zip
unzip JBrowse-1.16.11.zip
sudo mv JBrowse-1.16.11 /var/www/html/jbrowse
cd /var/www/html
sudo chown $USER jbrowse
cd jbrowse
./setup.sh

# Test out the install
echo "To check if the installation succeeded, go to http://localhost/jbrowse/"