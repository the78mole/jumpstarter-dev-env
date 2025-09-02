# Pre-commit Setup

This repository uses [pre-commit](https://pre-commit.com/) to ensure code quality and consistency.

## What's included

- **Code formatting**: Black and Ruff for Python code
- **Linting**: Ruff for Python code quality checks
- **General checks**: Trailing whitespace, YAML syntax, TOML syntax, etc.
- **YAML formatting**: Prettier for consistent YAML formatting

## Installation

Pre-commit is already included in the development dependencies. After installing the project dependencies, run:

```bash
# Install dependencies (includes pre-commit)
uv sync

# Install the pre-commit git hooks
uv run pre-commit install
```

## Usage

Pre-commit will now automatically run on every `git commit`. You can also run it manually:

```bash
# Run on all files
uv run pre-commit run --all-files

# Run on specific files
uv run pre-commit run --files path/to/file.py

# Update hooks to latest versions
uv run pre-commit autoupdate
```

## Configuration

The pre-commit configuration is in `.pre-commit-config.yaml`. It includes:

- Standard pre-commit hooks (trailing whitespace, YAML checks, etc.)
- Black code formatting with 88 character line length
- Ruff linting and formatting
- Prettier for YAML formatting (excluding GitHub workflows)

## Bypassing pre-commit

If you need to bypass pre-commit in exceptional cases:

```bash
git commit --no-verify -m "Emergency commit"
```

**Note**: This should be used sparingly and any issues should be fixed in a follow-up commit.
