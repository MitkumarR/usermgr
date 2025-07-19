#!/bin/bash

INSTALL_PATH="/usr/local/bin/usermgr"
LOG_DIR="logs"

# check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Remove installed command
if [ -f "$INSTALL_PATH" ]; then
    rm -f "$INSTALL_PATH"
    echo "Removed command: usermgr"
else
    echo "usermgr not found in /usr/local/bin"
fi

# Optional: Remove logs
read -p "Do you also want to delete log files? (y/n): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    rm -rf "$LOG_DIR"
    echo "Logs directory removed."
else
    echo "Logs preserved at ./$LOG_DIR"
fi

echo "Uninstall complete."