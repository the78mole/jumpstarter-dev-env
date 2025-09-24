#!/bin/bash
set -e

# Parse input arguments
VERSION=${VERSION:-"latest"}
PRE_COMMIT_VERSION=${PRECOMMIT:-"false"}

echo "Installing uv (Python package manager)..."

# Install uv using the official installer to system location
export CARGO_HOME=/usr/local/cargo
export RUSTUP_HOME=/usr/local/rustup

# Download and install uv to /usr/local/bin directly
curl -LsSf https://astral.sh/uv/install.sh | sh
mv ~/.cargo/bin/uv /usr/local/bin/uv 2>/dev/null || true
mv ~/.local/bin/uv /usr/local/bin/uv 2>/dev/null || true

# Ensure permissions are correct
chmod +x /usr/local/bin/uv

# Add to PATH for all users
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc

# Make sure it's available for the vscode user
chown root:root /usr/local/bin/uv

# Verify installation
if command -v uv &> /dev/null; then
    echo "✅ uv installed successfully"
    uv --version
else
    echo "❌ uv installation failed"
    exit 1
fi

# Install pre-commit as a uv tool if version is specified (not "false")
if [ "$PRE_COMMIT_VERSION" != "false" ] && [ -n "$PRE_COMMIT_VERSION" ]; then
    echo "Installing pre-commit as uv tool (version: $PRE_COMMIT_VERSION)..."

    # Determine the installation command based on version
    if [ "$PRE_COMMIT_VERSION" = "latest" ]; then
        INSTALL_CMD="uv tool install pre-commit"
    else
        INSTALL_CMD="uv tool install pre-commit==$PRE_COMMIT_VERSION"
    fi

    # Install pre-commit for the vscode user (or current user)
    if id "vscode" &>/dev/null; then
        sudo -u vscode $INSTALL_CMD
        echo "✅ pre-commit $PRE_COMMIT_VERSION installed for vscode user"
    elif [ "$USER" != "root" ]; then
        $INSTALL_CMD
        echo "✅ pre-commit $PRE_COMMIT_VERSION installed for $USER"
    else
        # For root user, install globally accessible
        $INSTALL_CMD
        # Make sure the tool is available in PATH for all users
        if [ -f "/root/.local/bin/pre-commit" ]; then
            ln -sf /root/.local/bin/pre-commit /usr/local/bin/pre-commit
        fi
        echo "✅ pre-commit $PRE_COMMIT_VERSION installed globally"
    fi

    # Verify pre-commit installation
    if command -v pre-commit &> /dev/null; then
        echo "✅ pre-commit available: $(pre-commit --version)"
        echo "✅ Initializing pre-commit in /workspace..."
        if [ -d "/workspace" ]; then
            cd /workspace
            pre-commit
        fi
    else
        echo "⚠️ pre-commit installed but not in PATH - may need container restart"
    fi
else
    echo "ℹ️ Skipping pre-commit installation (preCommit: '$PRE_COMMIT_VERSION')"
fi

echo "✅ uv feature installation complete!"
