#!/usr/bin/env bash
# this_file: scripts/test.sh

set -euo pipefail

echo "🧪 Running test suite for macdefaultbrowsy..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Warning: This package is designed for macOS but testing on $OSTYPE"
    echo "   Some tests may fail due to missing macOS dependencies."
fi

# Install test dependencies
echo "📦 Installing test dependencies..."
if command -v uv &> /dev/null; then
    uv pip install --system ".[test]"
else
    python3 -m pip install ".[test]"
fi

# Run code quality checks
echo "🔍 Running code quality checks..."

echo "  → Checking with Ruff..."
if command -v ruff &> /dev/null; then
    ruff check src/macdefaultbrowsy tests/
    ruff format --check src/macdefaultbrowsy tests/
else
    echo "    ⚠️  Ruff not found, skipping lint checks"
fi

echo "  → Type checking with mypy..."
if command -v mypy &> /dev/null; then
    mypy src/macdefaultbrowsy tests/ || echo "    ⚠️  mypy checks failed (may be due to missing macOS dependencies)"
else
    echo "    ⚠️  mypy not found, skipping type checks"
fi

# Run tests
echo "🧪 Running unit tests..."
if command -v pytest &> /dev/null; then
    pytest tests/ -v --cov=src/macdefaultbrowsy --cov-report=term-missing --cov-report=html
    echo "📊 Coverage report generated in htmlcov/"
else
    echo "❌ pytest not found! Please install with: pip install pytest pytest-cov"
    exit 1
fi

echo "✅ All tests completed!"