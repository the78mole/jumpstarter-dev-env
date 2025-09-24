# Jumpstarter CLI DevContainer Feature - Configuration Examples

This document shows different ways to configure the Jumpstarter CLI feature in your DevContainer.

## Examples

### Example 1: Default Configuration (Recommended)
Uses the Jumpstarter package repository with the latest version.

```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "latest"
    }
  }
}
```

**Result**: Installs latest version (0.7.0) from `https://pkg.jumpstarter.dev/`

### Example 2: Development Version from Main Branch
Get the latest development version directly from the main branch.

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

**Result**: Installs latest development version from `https://pkg.jumpstarter.dev/main/`

### Example 3: Specific Version from PyPI
Install a specific version that's available on PyPI.

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

**Result**: Installs version 0.6.0 from PyPI

### Example 4: Latest from PyPI
Install the latest available version from PyPI (may be older than jumpstarter repo).

```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "latest",
      "packageRepo": "pypi"
    }
  }
}
```

**Result**: Installs latest available version from PyPI

### Example 5: Custom Package Repository
Install from a custom or private package repository.

```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "latest",
      "packageRepo": "https://packages.your-company.com/simple/"
    }
  }
}
```

**Result**: Uses `--extra-index-url https://packages.your-company.com/simple/` with PyPI fallback

### Example 6: Corporate Nexus Repository
Install from a corporate Nexus repository with specific version.

```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "0.7.0-custom.1",
      "packageRepo": "https://nexus.corp.example.com/repository/pypi-proxy/simple/"
    }
  }
}
```

**Result**: Installs custom version from corporate repository with PyPI fallback

## Repository Comparison

| Aspect | Jumpstarter Repo | PyPI | Custom URL |
|--------|------------------|------|------------|
| **URL** | pkg.jumpstarter.dev | pypi.org | Your custom URL |
| **Latest Version** | 0.7.0 | ~0.6.0 | Depends on repo |
| **Development Access** | ✅ (main branch) | ❌ | Depends on repo |
| **Specific Versions** | Limited | ✅ | Depends on repo |
| **Update Frequency** | High | Standard | Your control |
| **Stability** | Cutting-edge | Stable releases | Your choice |
| **Use Case** | Official latest | Public stable | Private/Corporate |
| **Fallback** | None | None | PyPI fallback |

## Migration Guide

### From Old Configuration
If you were using:
```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "0.7.0"
    }
  }
}
```

### To New Configuration
Change to:
```json
{
  "features": {
    "./features/jumpstarter-cli": {
      "version": "latest",
      "packageRepo": "jumpstarter"
    }
  }
}
```

This ensures you get the latest 0.7.0 from the official Jumpstarter repository.

## Troubleshooting

### Version Not Found
If you get a "version not found" error:
1. Check if the version exists in the chosen repository
2. Use `packageRepo: "pypi"` for older versions like 0.6.0
3. Use `packageRepo: "jumpstarter"` for latest versions like 0.7.0

### Installation Fails
If installation fails:
1. Ensure `uv` feature is installed before `jumpstarter-cli`
2. Check your DevContainer features installation order
3. Rebuild the DevContainer to apply changes
