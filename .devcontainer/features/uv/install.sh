#!/bin/bash
set -e

# Parse input arguments
VERSION=${VERSION:-"latest"}

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

echo "✅ uv feature installation complete!"
