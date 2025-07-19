#!/bin/bash

TOOL_NAME="user-manager.sh"
INSTALL_PATH="/usr/local/bin/usermgr"

# ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# make main script executable
chmod +x "$TOOL_NAME"

# copy to /usr/local/bin with simple command name
cp "$TOOL_NAME" "$INSTALL_PATH"

echo "Tool installed. You can now run it using: usermgr"
