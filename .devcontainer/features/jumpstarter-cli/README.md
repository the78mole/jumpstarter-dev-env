# Jumpstarter CLI Feature

This DevContainer feature installs [Jumpstarter CLI](https://github.com/jumpstarter-dev/jumpstarter), providing `jmp` and `j` commands for interacting with Jumpstarter exporters and controllers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | "latest" | Version of jumpstarter-cli to install |
| packageRepo | string | "jumpstarter" | Repository: 'jumpstarter', 'pypi', or custom URL |

## Package Repositories

### Jumpstarter Repository (`packageRepo: "jumpstarter"`)

- **URL**: `https://pkg.jumpstarter.dev/`
- **Available versions**:
  - `latest` - Currently 0.7.0
  - `main` - Latest development version from main branch
- **Use case**: Latest features and cutting-edge development
- **URL for main**: `https://pkg.jumpstarter.dev/main/`

### PyPI Repository (`packageRepo: "pypi"`)

- **URL**: `https://pypi.org`
- **Available versions**: Specific semantic versions (e.g., `0.6.0`)
- **Use case**: Stable releases and version-specific installations
- **Note**: Latest versions (like 0.7.0) may not be available immediately on PyPI

### Custom Repository (`packageRepo: "https://your-repo.example.com/simple/"`)

- **URL**: Any valid Python package index URL
- **Available versions**: Depends on the custom repository
- **Use case**: Private repositories, corporate package indexes, alternative mirrors
- **Implementation**: Uses `--extra-index-url` to supplement PyPI

## Usage

### Default (Jumpstarter Repository)

```json
{
    "features": {
        "./features/jumpstarter-cli": {
            "version": "latest"
        }
    }
}
```

### Using PyPI for Specific Version

```json
{
    "features": {
        "./features/jumpstarter-cli": {
            "version": "0.6.0",
            "packageRepo": "pypi"
        }
    }
}
```

### Using Main Branch Development Version

```json
{
    "features": {
        "./features/jumpstarter-cli": {
            "version": "main",
            "packageRepo": "jumpstarter"
        }
    }
}
```

### Using Custom Package Repository

```json
{
    "features": {
        "./features/jumpstarter-cli": {
            "version": "latest",
            "packageRepo": "https://your-private-repo.example.com/simple/"
        }
    }
}
```

## What's Installed

- `jmp` - Full Jumpstarter CLI command
- `j` - Short alias for Jumpstarter CLI
- Global PATH configuration for all users

## Version and Repository Matrix

| Repository | Version | Available | Description |
|-----------|---------|-----------|-------------|
| jumpstarter | `latest` | ✅ 0.7.0 | Latest stable from pkg.jumpstarter.dev |
| jumpstarter | `main` | ✅ | Development version from main branch |
| pypi | `0.6.0` | ✅ | Specific version from PyPI |
| pypi | `latest` | ✅ | Latest available on PyPI (may be older) |
| pypi | `0.7.0` | ❌ | Not yet available on PyPI |
| custom URL | `latest` | ✅ | Latest from custom repository + PyPI fallback |
| custom URL | `specific` | ✅ | Specific version from custom repository + PyPI fallback |

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
