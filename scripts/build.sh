#!/usr/bin/env bash
# this_file: scripts/build.sh

set -euo pipefail

echo "🔧 Building macdefaultbrowsy..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Warning: This package is designed for macOS but building on $OSTYPE"
    echo "   Dependencies may not install correctly."
fi

# Create a clean build environment
if [[ -d "dist" ]]; then
    echo "🧹 Cleaning previous build artifacts..."
    rm -rf dist/
fi

if [[ -d "build" ]]; then
    rm -rf build/
fi

if [[ -d "src/macdefaultbrowsy.egg-info" ]]; then
    rm -rf src/macdefaultbrowsy.egg-info/
fi

# Install build dependencies
echo "📦 Installing build dependencies..."
if command -v uv &> /dev/null; then
    uv pip install --system build hatchling hatch-vcs
else
    # Try different installation methods
    if python3 -m pip install --user build hatchling hatch-vcs; then
        echo "✅ Installed build dependencies to user directory"
    elif python3 -m pip install --break-system-packages build hatchling hatch-vcs; then
        echo "⚠️  Installed build dependencies system-wide (breaking system packages)"
    else
        echo "❌ Failed to install build dependencies"
        echo "   Please create a virtual environment or install manually"
        exit 1
    fi
fi

# Build the package
echo "🏗️  Building wheel and source distribution..."
python3 -m build --outdir dist

# Verify the build
echo "✅ Build completed successfully!"
echo "📄 Generated files:"
ls -la dist/

# Check if files were created
if [[ -n "$(find dist -name '*.whl' 2>/dev/null)" ]] && [[ -n "$(find dist -name '*.tar.gz' 2>/dev/null)" ]]; then
    echo "🎉 Build successful! Created wheel and source distribution."
    
    # Extract version from the built files
    WHEEL_FILE=$(find dist -name '*.whl' | head -1)
    VERSION=$(basename "$WHEEL_FILE" | sed 's/macdefaultbrowsy-\(.*\)-py3-.*/\1/')
    echo "📋 Version: $VERSION"
else
    echo "❌ Build failed: Missing wheel or source distribution files"
    exit 1
fi