#!/bin/bash
set -e

# Parse input arguments
VERSION=${VERSION:-"latest"}

echo "Installing Jumpstarter CLI..."

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "❌ uv not found - Jumpstarter CLI requires uv to be installed first"
    exit 1
fi

# Install jumpstarter-cli as a uv tool for global access
echo "Installing Jumpstarter CLI as global tool (version: $VERSION)..."

# Determine the installation command based on version
if [ "$VERSION" = "latest" ]; then
    INSTALL_CMD="uv tool install jumpstarter-cli"
else
    INSTALL_CMD="uv tool install jumpstarter-cli==$VERSION"
fi

# Install jumpstarter-cli for the vscode user (or current user)
if id "vscode" &>/dev/null; then
    sudo -u vscode $INSTALL_CMD
    echo "✅ Jumpstarter CLI $VERSION installed for vscode user"
elif [ "$USER" != "root" ]; then
    $INSTALL_CMD
    echo "✅ Jumpstarter CLI $VERSION installed for $USER"
else
    # For root user, install globally accessible
    $INSTALL_CMD
    # Make sure the tools are available in PATH for all users
    if [ -f "/root/.local/bin/jmp" ]; then
        ln -sf /root/.local/bin/jmp /usr/local/bin/jmp
    fi
    if [ -f "/root/.local/bin/j" ]; then
        ln -sf /root/.local/bin/j /usr/local/bin/j
    fi
    echo "✅ Jumpstarter CLI $VERSION installed globally"
fi

# Verify installation
echo "Verifying Jumpstarter CLI installation..."
if command -v jmp &> /dev/null; then
    echo "✅ jmp command available: $(jmp --version 2>/dev/null || echo 'installed')"
else
    echo "⚠️ jmp installed but not in PATH - may need container restart"
fi

if command -v j &> /dev/null; then
    echo "✅ j command (short alias) available"
else
    echo "ℹ️ j command not found - may be available after container restart"
fi

echo "✅ Jumpstarter CLI feature installation complete!"
