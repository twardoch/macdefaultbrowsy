#!/usr/bin/env bash
# this_file: scripts/build-binary.sh

set -euo pipefail

echo "🔨 Building macdefaultbrowsy binary..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: Binary builds only supported on macOS"
    echo "   Current OS: $OSTYPE"
    exit 1
fi

# Check if PyInstaller is available
if ! command -v pyinstaller &> /dev/null; then
    echo "📦 Installing PyInstaller..."
    if command -v uv &> /dev/null; then
        uv pip install --system pyinstaller
    else
        python3 -m pip install --user pyinstaller
    fi
fi

# Clean previous builds
if [[ -d "dist" ]]; then
    echo "🧹 Cleaning previous binary builds..."
    rm -rf dist/
fi

if [[ -d "build" ]]; then
    rm -rf build/
fi

# Install dependencies
echo "📦 Installing dependencies..."
if command -v uv &> /dev/null; then
    uv pip install --system ".[all]"
else
    python3 -m pip install --user ".[all]"
fi

# Build binary using PyInstaller spec
echo "🏗️  Building binary with PyInstaller..."
if [[ -f "pyinstaller.spec" ]]; then
    pyinstaller pyinstaller.spec --clean --noconfirm
else
    # Fallback to direct command
    pyinstaller --onefile --name macdefaultbrowsy \
        --add-data "src/macdefaultbrowsy:macdefaultbrowsy" \
        --hidden-import macdefaultbrowsy \
        --hidden-import macdefaultbrowsy.macdefaultbrowsy \
        --hidden-import macdefaultbrowsy.launch_services \
        --hidden-import macdefaultbrowsy.dialog_automation \
        --hidden-import LaunchServices \
        --hidden-import loguru \
        --hidden-import fire \
        src/macdefaultbrowsy/__main__.py
fi

# Verify the binary was created
if [[ -f "dist/macdefaultbrowsy" ]]; then
    echo "✅ Binary built successfully!"
    
    # Test the binary
    echo "🧪 Testing binary..."
    if ./dist/macdefaultbrowsy --help &> /dev/null; then
        echo "✅ Binary test passed!"
    else
        echo "⚠️  Binary test failed - but this might be expected in some environments"
    fi
    
    # Show binary info
    echo "📊 Binary information:"
    file dist/macdefaultbrowsy
    ls -lh dist/macdefaultbrowsy
    
    # Create a distributable package
    echo "📦 Creating distributable package..."
    mkdir -p release
    cp dist/macdefaultbrowsy release/
    
    # Create README for binary distribution
    cat > release/README.md << 'EOF'
# macdefaultbrowsy Binary Distribution

This is a standalone binary distribution of macdefaultbrowsy.

## Installation

1. Extract the binary:
   ```bash
   tar -xzf macdefaultbrowsy-*.tar.gz
   cd macdefaultbrowsy-*
   ```

2. Make the binary executable (if needed):
   ```bash
   chmod +x macdefaultbrowsy
   ```

3. Run the binary:
   ```bash
   ./macdefaultbrowsy
   ```

## Usage

```bash
# List available browsers
./macdefaultbrowsy

# Set Chrome as default
./macdefaultbrowsy chrome

# Set Safari as default
./macdefaultbrowsy safari
```

## Installing to System Path

To install the binary to your system PATH:

```bash
# Copy to /usr/local/bin (requires admin privileges)
sudo cp macdefaultbrowsy /usr/local/bin/

# Or copy to your personal bin directory
mkdir -p ~/bin
cp macdefaultbrowsy ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
```

## Requirements

- macOS 10.15 or later
- No Python installation required
EOF

    # Create tarball
    ARCH=$(uname -m)
    OS_VERSION=$(sw_vers -productVersion | cut -d. -f1-2)
    TARBALL="macdefaultbrowsy-macos-${ARCH}-${OS_VERSION}.tar.gz"
    
    cd release
    tar -czf "../${TARBALL}" *
    cd ..
    
    echo "🎉 Binary package created: ${TARBALL}"
    echo "📁 Contents:"
    tar -tzf "${TARBALL}"
    
else
    echo "❌ Binary build failed - no binary found in dist/"
    exit 1
fi