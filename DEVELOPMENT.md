# Development Guide

This document provides comprehensive information about the development setup, build process, and release workflow for macdefaultbrowsy.

## Project Structure

```
macdefaultbrowsy/
├── src/macdefaultbrowsy/          # Main package source code
│   ├── __init__.py               # Package initialization
│   ├── __main__.py               # CLI entry point
│   ├── macdefaultbrowsy.py       # Core functionality
│   ├── launch_services.py        # macOS Launch Services wrapper
│   └── dialog_automation.py      # Dialog automation utilities
├── tests/                        # Test suite
│   ├── test_browser_manager.py   # Core functionality tests
│   ├── test_launch_services.py   # Launch Services tests
│   ├── test_dialog_automation.py # Dialog automation tests
│   └── test_cli.py               # CLI tests
├── scripts/                      # Build and release scripts
│   ├── validate.sh               # Validation script
│   ├── build.sh                  # Build Python package
│   ├── test.sh                   # Run test suite
│   ├── build-binary.sh           # Build standalone binary
│   ├── release.sh                # Create release tag
│   ├── install.sh                # Installation script
│   └── all.sh                    # Complete workflow
├── .github/workflows/            # GitHub Actions
│   ├── push.yml                  # CI for builds and PRs
│   └── release.yml               # Release workflow
├── pyproject.toml                # Project configuration
├── pyinstaller.spec              # PyInstaller configuration
└── README.md                     # Main documentation
```

## Versioning System

The project uses **git-tag-based semantic versioning** with the following components:

- **hatch-vcs**: Automatically generates version from git tags
- **Version format**: `vX.Y.Z` (e.g., `v2.2.3`)
- **Development versions**: Include git hash and commit count
- **Release versions**: Clean semantic versions from tags

### Version Generation

```bash
# Development version example
2.2.4.dev3+g835a463.d20250717

# Release version example  
2.2.3
```

## Development Setup

### Prerequisites

- **macOS**: Required for full functionality (uses PyObjC)
- **Python 3.10+**: Required minimum version
- **Git**: For version control and tagging
- **Optional**: `uv` for faster package management

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/twardoch/macdefaultbrowsy.git
   cd macdefaultbrowsy
   ```

2. **Validate setup**:
   ```bash
   ./scripts/validate.sh
   ```

3. **Install dependencies**:
   ```bash
   # With uv (recommended)
   uv pip install -e ".[dev,test]"
   
   # Or with pip
   pip install -e ".[dev,test]"
   ```

## Build Scripts

### 1. Validation Script (`scripts/validate.sh`)

Checks project setup and dependencies:
```bash
./scripts/validate.sh
```

### 2. Test Script (`scripts/test.sh`)

Runs the complete test suite:
```bash
./scripts/test.sh
```

Features:
- Code quality checks with Ruff
- Type checking with mypy
- Unit tests with pytest
- Coverage reporting

### 3. Build Script (`scripts/build.sh`)

Builds Python distributions:
```bash
./scripts/build.sh
```

Creates:
- Wheel distribution (`.whl`)
- Source distribution (`.tar.gz`)

### 4. Binary Build Script (`scripts/build-binary.sh`)

Creates standalone binaries (macOS only):
```bash
./scripts/build-binary.sh
```

Creates:
- Standalone binary executable
- Distributable tarball

### 5. Release Script (`scripts/release.sh`)

Creates git tags and triggers releases:
```bash
./scripts/release.sh 1.2.3        # Release version 1.2.3
./scripts/release.sh 1.2.3-rc1    # Release candidate
./scripts/release.sh 1.2.3 --dry-run  # Test without releasing
```

Features:
- Validates version format
- Checks for clean working directory
- Runs tests and builds
- Creates and pushes git tags
- Triggers GitHub Actions

### 6. Complete Workflow (`scripts/all.sh`)

Runs the entire build and test workflow:
```bash
./scripts/all.sh                  # Run everything
./scripts/all.sh --skip-tests     # Skip tests
./scripts/all.sh --skip-binary    # Skip binary build
./scripts/all.sh --dry-run        # Show what would be done
```

## Testing

### Test Structure

- **Unit tests**: Mock external dependencies
- **Integration tests**: Test component interactions
- **Coverage**: Comprehensive test coverage reporting
- **Cross-platform**: Tests run on macOS and Linux (with limitations)

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Run specific test file
pytest tests/test_browser_manager.py -v

# Run with coverage
pytest --cov=src/macdefaultbrowsy --cov-report=html tests/
```

### Test Categories

- `test_browser_manager.py`: Core browser management functionality
- `test_launch_services.py`: macOS Launch Services integration
- `test_dialog_automation.py`: Dialog automation system
- `test_cli.py`: Command-line interface

## Release Process

### Automated Release Workflow

1. **Create release tag**:
   ```bash
   ./scripts/release.sh 1.2.3
   ```

2. **GitHub Actions automatically**:
   - Runs tests on multiple Python versions and platforms
   - Builds Python distributions
   - Creates multiplatform binaries
   - Publishes to PyPI
   - Creates GitHub release with assets

### Manual Release Steps

1. **Ensure clean main branch**:
   ```bash
   git checkout main
   git pull origin main
   git status  # Should be clean
   ```

2. **Run complete workflow**:
   ```bash
   ./scripts/all.sh
   ```

3. **Create release tag**:
   ```bash
   ./scripts/release.sh <version>
   ```

4. **Monitor GitHub Actions**:
   - Check workflow status
   - Verify PyPI publication
   - Confirm GitHub release creation

## GitHub Actions

### CI Workflow (`.github/workflows/push.yml`)

Triggers on:
- Push to main branch
- Pull requests
- Manual dispatch

Jobs:
- **Code Quality**: Ruff linting and formatting
- **Testing**: Matrix testing across Python versions and platforms
- **Build**: Creates Python distributions

### Release Workflow (`.github/workflows/release.yml`)

Triggers on:
- Git tags matching `v*`

Jobs:
- **Test**: Run tests on multiple platforms
- **Build Python**: Create wheel and source distributions
- **Build Binaries**: Create standalone binaries for macOS
- **Publish PyPI**: Upload to PyPI
- **Create Release**: Generate GitHub release with assets

## Binary Releases

### Supported Platforms

- **macOS Intel (x86_64)**: Latest macOS
- **macOS Intel (x86_64-legacy)**: macOS 13 and earlier
- **macOS Apple Silicon (arm64)**: M1/M2 Macs

### Binary Features

- **Standalone**: No Python installation required
- **Single file**: All dependencies bundled
- **Cross-architecture**: Separate builds for Intel and ARM

### PyInstaller Configuration

The `pyinstaller.spec` file configures:
- Hidden imports for macOS frameworks
- Dependency bundling
- Executable optimization

## Development Tips

### Code Style

- **Ruff**: Linting and formatting
- **mypy**: Type checking
- **Pre-commit**: Automated code quality checks

### Testing Strategy

- **Mock external dependencies**: Avoid system dependencies in tests
- **Test edge cases**: Handle errors gracefully
- **Platform compatibility**: Consider macOS-specific behavior

### Version Management

- **Semantic versioning**: Follow semver for releases
- **Development versions**: Include git metadata
- **Tag format**: Always use `vX.Y.Z` format

## Troubleshooting

### Common Issues

1. **PyObjC installation fails on Linux**:
   - Expected behavior - package is macOS-only
   - Use `--skip-binary` flag for Linux development

2. **Version not updating**:
   - Ensure you're building from git repository
   - Check that hatch-vcs is installed

3. **Binary build fails**:
   - Requires macOS with PyInstaller
   - Install with `pip install pyinstaller`

### Debug Commands

```bash
# Check version generation
python -c "import macdefaultbrowsy; print(macdefaultbrowsy.__version__)"

# Test CLI without installation
python -m macdefaultbrowsy --help

# Check build environment
./scripts/validate.sh
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Run tests: `./scripts/test.sh`
4. Submit pull request
5. Ensure CI passes

## Resources

- [PyPI Package](https://pypi.org/project/macdefaultbrowsy/)
- [GitHub Repository](https://github.com/twardoch/macdefaultbrowsy)
- [Issue Tracker](https://github.com/twardoch/macdefaultbrowsy/issues)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)