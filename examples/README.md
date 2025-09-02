# Jumpstarter Examples

This directory contains Python examples for working with Jumpstarter in distributed mode.

## Quick Start

1. **Setup development environment:**
   ```bash
   # Ensure Jumpstarter is running (automatic in DevContainer)
   make dev

   # Check services are accessible
   make network-test
   ```

2. **Create and test an exporter:**
   ```bash
   # Create exporter configuration
   make create-exporter

   # Start exporter (in one terminal)
   make run-exporter

   # Connect with client (in another terminal)
   make client-shell
   ```

3. **Test the connection in client shell:**
   ```python
   # In the client shell, test mock drivers:
   power.get()         # Test power driver
   storage.list()      # Test storage driver
   exit                # Exit shell
   ```

## Files

- **`create_exporter.py`** - Automated script to create a distributed mode exporter with mock drivers
- **Configuration files** - Created in `~/.config/jumpstarter/` during setup

## Manual Usage

You can also use the Jumpstarter CLI directly:

```bash
# Create exporter manually (using DevContainer services)
uv run jmp admin create exporter my-exporter \
  --label example.com/board=foo \
  --save --insecure-tls-config \
  --controller-endpoint localhost:30010

# Edit exporter config
uv run jmp config exporter edit my-exporter

# Run exporter
uv run jmp run --exporter my-exporter

# Create client
uv run jmp admin create client my-client \
  --save --unsafe --insecure-tls-config \
  --controller-endpoint localhost:30010

# Connect with client
uv run jmp shell --client my-client --selector example.com/board=foo
```

## Mock Drivers

The examples use mock drivers for testing without physical hardware:

- **`jumpstarter_driver_opendal.driver.MockStorageMux`** - Mock storage driver
- **`jumpstarter_driver_power.driver.MockPower`** - Mock power control driver

These allow you to test the distributed architecture and API without requiring actual hardware devices.

## Next Steps

- Try creating custom exporters with different labels and selectors
- Explore the Jumpstarter CLI: `uv run jmp --help`
- Check the [official examples](https://jumpstarter.dev/main/getting-started/guides/examples.html)
- Learn about [integration patterns](https://jumpstarter.dev/main/getting-started/guides/integration-patterns.html)
