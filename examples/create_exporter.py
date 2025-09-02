#!/usr/bin/env python3
"""
Jumpstarter Exporter Creation Example

This script demonstrates how to create and configure a Jumpstarter exporter
using the controller service API with mock drivers for testing.
"""

import subprocess
import sys
import yaml
from pathlib import Path


def run_command(cmd, capture_output=True, check=True):
    """Run a shell command and return the result."""
    print(f"🔧 Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd, capture_output=capture_output, text=True, check=check
        )
        if capture_output:
            return result.stdout.strip()
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {e}")
        if capture_output and e.stdout:
            print(f"stdout: {e.stdout}")
        if capture_output and e.stderr:
            print(f"stderr: {e.stderr}")
        raise


def check_jumpstarter_service():
    """Check if Jumpstarter service is running."""
    print("🔍 Checking Jumpstarter service status...")
    try:
        result = run_command(["kubectl", "get", "pods", "-n", "jumpstarter-lab"])
        if "jumpstarter-controller" in result and "Running" in result:
            print("✅ Jumpstarter service is running")
            return True
        else:
            print("❌ Jumpstarter service not found or not running")
            return False
    except Exception as e:
        print(f"❌ Error checking service: {e}")
        return False


def create_exporter():
    """Create a new exporter using jmp admin CLI."""
    print("🚀 Creating new exporter...")

    exporter_name = "example-distributed"

    try:
        # Create exporter with jmp admin CLI
        cmd = [
            "jmp",
            "admin",
            "create",
            "exporter",
            exporter_name,
            "--label",
            "example.com/board=foo",
            "--label",
            "environment=development",
            "--save",
            "--insecure-tls-config",
            "--controller-endpoint",
            "localhost:8082",
        ]

        run_command(cmd, capture_output=False)
        print(f"✅ Exporter '{exporter_name}' created successfully")

        # Check if config file was created
        config_path = (
            Path.home()
            / ".config"
            / "jumpstarter"
            / "exporters"
            / f"{exporter_name}.yaml"
        )
        if config_path.exists():
            print(f"📄 Configuration saved to: {config_path}")
            return config_path
        else:
            # Try alternative path
            config_path = Path("/etc/jumpstarter/exporters") / f"{exporter_name}.yaml"
            if config_path.exists():
                print(f"📄 Configuration found at: {config_path}")
                return config_path
            else:
                print("⚠️  Configuration file not found in expected locations")
                return None

    except Exception as e:
        print(f"❌ Failed to create exporter: {e}")
        return None


def update_exporter_config(config_path):
    """Update the exporter configuration with mock drivers."""
    if not config_path or not config_path.exists():
        print("❌ Configuration file not found")
        return False

    print(f"📝 Updating exporter configuration at {config_path}")

    try:
        # Read existing config
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)

        # Add mock drivers
        if "export" not in config:
            config["export"] = {}

        config["export"]["storage"] = {
            "type": "jumpstarter_driver_opendal.driver.MockStorageMux"
        }

        config["export"]["power"] = {
            "type": "jumpstarter_driver_power.driver.MockPower"
        }

        # Write updated config
        with open(config_path, "w") as f:
            yaml.dump(config, f, default_flow_style=False, indent=2)

        print("✅ Configuration updated with mock drivers")
        print("📄 Config content:")
        print("=" * 50)
        with open(config_path, "r") as f:
            print(f.read())
        print("=" * 50)

        return True

    except Exception as e:
        print(f"❌ Failed to update configuration: {e}")
        return False


def create_client():
    """Create a client to connect to the exporter."""
    print("👤 Creating client...")

    client_name = "hello"

    try:
        cmd = [
            "jmp",
            "admin",
            "create",
            "client",
            client_name,
            "--save",
            "--unsafe",
            "--insecure-tls-config",
            "--controller-endpoint",
            "localhost:8082",
        ]

        run_command(cmd, capture_output=False)
        print(f"✅ Client '{client_name}' created successfully")
        return True

    except Exception as e:
        print(f"❌ Failed to create client: {e}")
        return False


def show_usage_instructions():
    """Show instructions for using the exporter."""
    print("\n" + "=" * 60)
    print("🎉 Exporter Setup Complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Run the exporter:")
    print("   uv run jmp run --exporter example-distributed")
    print("\n2. In another terminal, connect with client:")
    print("   uv run jmp shell --client hello --selector example.com/board=foo")
    print("\n3. Test the connection in the client shell:")
    print("   power.get()")
    print("   storage.list()")
    print("\n4. Exit the shell:")
    print("   exit")
    print("\n💡 Tip: Use 'make python-shell' for interactive Python access")
    print("=" * 60)


def main():
    """Main function to orchestrate exporter creation."""
    print("🚀 Jumpstarter Distributed Mode Setup")
    print("=" * 50)

    # Check if Jumpstarter service is running
    if not check_jumpstarter_service():
        print("\n❌ Please ensure Jumpstarter service is running:")
        print("   make dev")
        sys.exit(1)

    # Create exporter
    config_path = create_exporter()
    if not config_path:
        print("❌ Failed to create exporter")
        sys.exit(1)

    # Update configuration
    if not update_exporter_config(config_path):
        print("❌ Failed to update exporter configuration")
        sys.exit(1)

    # Create client
    if not create_client():
        print("❌ Failed to create client")
        sys.exit(1)

    # Show usage instructions
    show_usage_instructions()


if __name__ == "__main__":
    main()
