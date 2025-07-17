#!/usr/bin/env bash
# this_file: scripts/all.sh

set -euo pipefail

echo "🚀 Running complete build, test, and release workflow..."

# Function to print section headers
print_section() {
    echo ""
    echo "================================"
    echo "$1"
    echo "================================"
    echo ""
}

# Function to check if we're on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  Warning: This package is designed for macOS but running on $OSTYPE"
        echo "   Some steps may fail due to missing macOS dependencies."
        return 1
    fi
    return 0
}

# Parse command line arguments
RUN_TESTS=true
RUN_BUILD=true
RUN_BINARY=true
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            RUN_TESTS=false
            shift
            ;;
        --skip-build)
            RUN_BUILD=false
            shift
            ;;
        --skip-binary)
            RUN_BINARY=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-tests    Skip running tests"
            echo "  --skip-build    Skip building Python package"
            echo "  --skip-binary   Skip building binary"
            echo "  --dry-run       Show what would be done without doing it"
            echo "  --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run everything"
            echo "  $0 --skip-tests       # Skip tests, build everything else"
            echo "  $0 --skip-binary      # Skip binary build"
            echo "  $0 --dry-run          # Show what would be done"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if we're on macOS
IS_MACOS=false
if check_macos; then
    IS_MACOS=true
fi

# Run tests
if [[ "$RUN_TESTS" == "true" ]]; then
    print_section "🧪 RUNNING TESTS"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would run: ./scripts/test.sh"
    else
        if [[ -x "./scripts/test.sh" ]]; then
            ./scripts/test.sh
        else
            echo "❌ Test script not found or not executable"
            exit 1
        fi
    fi
fi

# Build Python package
if [[ "$RUN_BUILD" == "true" ]]; then
    print_section "🏗️  BUILDING PYTHON PACKAGE"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would run: ./scripts/build.sh"
    else
        if [[ -x "./scripts/build.sh" ]]; then
            ./scripts/build.sh
        else
            echo "❌ Build script not found or not executable"
            exit 1
        fi
    fi
fi

# Build binary (macOS only)
if [[ "$RUN_BINARY" == "true" ]]; then
    if [[ "$IS_MACOS" == "true" ]]; then
        print_section "🔨 BUILDING BINARY"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would run: ./scripts/build-binary.sh"
        else
            if [[ -x "./scripts/build-binary.sh" ]]; then
                ./scripts/build-binary.sh
            else
                echo "❌ Binary build script not found or not executable"
                exit 1
            fi
        fi
    else
        echo "⚠️  Skipping binary build (not on macOS)"
    fi
fi

# Summary
print_section "📊 SUMMARY"
echo "✅ Workflow completed successfully!"
echo ""
echo "Generated artifacts:"
if [[ "$RUN_BUILD" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
    if [[ -d "dist" ]]; then
        echo "📦 Python packages:"
        find dist -name "*.whl" -o -name "*.tar.gz" | while read file; do
            echo "   - $(basename "$file")"
        done
    fi
fi

if [[ "$RUN_BINARY" == "true" ]] && [[ "$IS_MACOS" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
    echo "🔨 Binary packages:"
    find . -maxdepth 1 -name "macdefaultbrowsy-*.tar.gz" | while read file; do
        echo "   - $(basename "$file")"
    done
fi

echo ""
echo "🎉 Ready for release!"
echo ""
echo "Next steps:"
echo "1. Test the artifacts manually"
echo "2. Use scripts/release.sh to create a git tag and trigger release"
echo "3. Monitor GitHub Actions for automated release"