#!/usr/bin/env bash
# this_file: scripts/validate.sh

set -euo pipefail

echo "✅ Validating macdefaultbrowsy setup..."

# Check if we're in the right directory
if [[ ! -f "pyproject.toml" ]] || [[ ! -f "src/macdefaultbrowsy/__init__.py" ]]; then
    echo "❌ Error: Not in macdefaultbrowsy root directory"
    echo "   Please run this script from the project root."
    exit 1
fi

# Check Python version
echo "🐍 Checking Python version..."
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "   Python version: $PYTHON_VERSION"

REQUIRED_VERSION="3.10"
if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Error: Python $REQUIRED_VERSION or higher is required"
    echo "   Current version: $PYTHON_VERSION"
    exit 1
fi

# Check OS
echo "🖥️  Checking operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   OS: macOS (✅ fully supported)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "   OS: Linux (⚠️  limited support - some features may not work)"
else
    echo "   OS: $OSTYPE (❌ unsupported)"
fi

# Check git setup
echo "📋 Checking git setup..."
if command -v git &> /dev/null; then
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "   Git repository: ✅"
        
        # Check tags
        TAG_COUNT=$(git tag --list | wc -l)
        echo "   Git tags: $TAG_COUNT"
        
        if [[ $TAG_COUNT -gt 0 ]]; then
            LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
            echo "   Latest tag: $LATEST_TAG"
        fi
    else
        echo "   Git repository: ❌ not in a git repository"
    fi
else
    echo "   Git: ❌ not installed"
fi

# Check scripts
echo "📜 Checking scripts..."
SCRIPTS_DIR="scripts"
if [[ -d "$SCRIPTS_DIR" ]]; then
    for script in build.sh test.sh release.sh install.sh build-binary.sh all.sh; do
        if [[ -f "$SCRIPTS_DIR/$script" ]]; then
            if [[ -x "$SCRIPTS_DIR/$script" ]]; then
                echo "   $script: ✅ exists and executable"
            else
                echo "   $script: ⚠️  exists but not executable"
            fi
        else
            echo "   $script: ❌ missing"
        fi
    done
else
    echo "   Scripts directory: ❌ missing"
fi

# Check GitHub Actions
echo "⚙️  Checking GitHub Actions..."
if [[ -d ".github/workflows" ]]; then
    for workflow in push.yml release.yml; do
        if [[ -f ".github/workflows/$workflow" ]]; then
            echo "   $workflow: ✅ exists"
        else
            echo "   $workflow: ❌ missing"
        fi
    done
else
    echo "   GitHub Actions: ❌ .github/workflows directory missing"
fi

# Check dependencies
echo "📦 Checking key dependencies..."
if python3 -c "import fire" &> /dev/null; then
    echo "   fire: ✅ available"
else
    echo "   fire: ❌ not available"
fi

if python3 -c "import loguru" &> /dev/null; then
    echo "   loguru: ✅ available"
else
    echo "   loguru: ❌ not available"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    if python3 -c "import LaunchServices" &> /dev/null; then
        echo "   LaunchServices: ✅ available"
    else
        echo "   LaunchServices: ❌ not available (install pyobjc-framework-LaunchServices)"
    fi
fi

# Check pyproject.toml configuration
echo "⚙️  Checking pyproject.toml..."
if python3 -c "import tomllib; f=open('pyproject.toml','rb'); data=tomllib.load(f); print('✅ Valid TOML syntax')" 2>/dev/null; then
    echo "   TOML syntax: ✅ valid"
else
    echo "   TOML syntax: ❌ invalid"
fi

# Check version configuration
if grep -q "hatch-vcs" pyproject.toml; then
    echo "   Versioning: ✅ hatch-vcs configured"
else
    echo "   Versioning: ❌ hatch-vcs not configured"
fi

# Test import
echo "🧪 Testing package import..."
if python3 -c "import sys; sys.path.insert(0, 'src'); import macdefaultbrowsy; print('✅ Package import successful')" 2>/dev/null; then
    echo "   Package import: ✅ successful"
else
    echo "   Package import: ❌ failed"
fi

echo ""
echo "🎉 Validation complete!"
echo ""
echo "Summary:"
echo "- Python version: $PYTHON_VERSION"
echo "- Operating system: $OSTYPE"
echo "- Git tags: $TAG_COUNT"
echo ""
echo "Next steps:"
echo "1. Run './scripts/test.sh' to run tests"
echo "2. Run './scripts/build.sh' to build the package"
echo "3. Run './scripts/all.sh' to run the complete workflow"