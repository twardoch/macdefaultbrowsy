#!/usr/bin/env bash
# this_file: scripts/install.sh

set -euo pipefail

echo "📦 Installing macdefaultbrowsy..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This package only works on macOS"
    echo "   Current OS: $OSTYPE"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
REQUIRED_VERSION="3.10"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Error: Python $REQUIRED_VERSION or higher is required"
    echo "   Current version: $PYTHON_VERSION"
    echo "   Please upgrade Python and try again."
    exit 1
fi

# Install methods
install_from_pypi() {
    echo "🐍 Installing from PyPI..."
    if command -v uv &> /dev/null; then
        uv pip install --system macdefaultbrowsy
    elif command -v pipx &> /dev/null; then
        pipx install macdefaultbrowsy
    else
        python3 -m pip install --user macdefaultbrowsy
    fi
}

install_from_source() {
    echo "📚 Installing from source..."
    if command -v uv &> /dev/null; then
        uv pip install --system -e .
    else
        python3 -m pip install --user -e .
    fi
}

# Check if we're in the source directory
if [[ -f "pyproject.toml" ]] && [[ -f "src/macdefaultbrowsy/__init__.py" ]]; then
    echo "🔧 Detected source directory installation"
    install_from_source
else
    echo "🌐 Installing from PyPI"
    install_from_pypi
fi

# Verify installation
echo "✅ Verifying installation..."
if command -v macdefaultbrowsy &> /dev/null; then
    echo "🎉 Installation successful!"
    echo "📋 Usage:"
    echo "   macdefaultbrowsy              # List available browsers"
    echo "   macdefaultbrowsy chrome       # Set Chrome as default"
    echo "   macdefaultbrowsy safari       # Set Safari as default"
    echo ""
    echo "🔍 Current browsers:"
    macdefaultbrowsy || echo "   (Unable to list browsers - may need to run in Terminal)"
else
    echo "❌ Installation failed - macdefaultbrowsy command not found"
    echo "   Please check your Python PATH or try running:"
    echo "   python3 -m macdefaultbrowsy"
    exit 1
fi