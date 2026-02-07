#!/bin/bash

# VibeSVN Launcher Script
echo "Starting VibeSVN..."

# Check if app exists
if [ -d "/Applications/vibesvn.app" ]; then
    open /Applications/vibesvn.app
    echo "VibeSVN launched successfully!"
else
    echo "Error: VibeSVN.app not found in Applications folder."
    echo "Please copy VibeSVN.app to Applications folder first."
    exit 1
fi
