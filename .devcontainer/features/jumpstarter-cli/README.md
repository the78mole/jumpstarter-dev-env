# Jumpstarter CLI Feature

This DevContainer feature installs [Jumpstarter CLI](https://github.com/jumpstarter-dev/jumpstarter), providing `jmp` and `j` commands for interacting with Jumpstarter exporters and controllers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | "latest" | Version of jumpstarter-cli to install |

## Usage

```json
{
    "features": {
        "./features/jumpstarter-cli": {
            "version": "latest"
        }
    }
}
```

## What's Installed

- `jmp` - Full Jumpstarter CLI command
- `j` - Short alias for Jumpstarter CLI
- Global PATH configuration for all users

## Commands Available

Once installed, you can use:

```bash
# Full command examples
jmp admin get exporter
jmp shell --client myclient --selector environment=dev
jmp admin create exporter myexporter --label environment=dev

# Short command examples
j admin get exporter
j shell --client myclient --selector environment=dev
j admin create exporter myexporter --label environment=dev
```

## Notes

- This feature requires the `uv` feature to be installed first
- Commands are available directly without `uv run` prefix
- Works with both local Kind clusters and remote Jumpstarter installations
- Installation is user-aware (works properly in DevContainers with vscode user)

## Dependencies

- Requires `uv` (Python package manager) to be installed first
- Will install `jumpstarter-cli` Python package as a global uv tool
