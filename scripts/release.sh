#!/usr/bin/env bash
# this_file: scripts/release.sh

set -euo pipefail

echo "🚀 Preparing release for macdefaultbrowsy..."

# Function to check if we're on the main branch
check_main_branch() {
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" ]]; then
        echo "❌ Error: Releases must be made from the main branch"
        echo "   Current branch: $current_branch"
        echo "   Please checkout main and merge your changes first."
        exit 1
    fi
}

# Function to check if working directory is clean
check_clean_working_dir() {
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "❌ Error: Working directory is not clean"
        echo "   Please commit or stash your changes first."
        git status --short
        exit 1
    fi
}

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        echo "❌ Error: Invalid version format: $version"
        echo "   Expected format: X.Y.Z or X.Y.Z-suffix (e.g., 1.2.3, 1.2.3-alpha1)"
        exit 1
    fi
}

# Function to check if version tag already exists
check_version_exists() {
    local version="$1"
    local tag="v$version"
    if git tag -l | grep -q "^$tag$"; then
        echo "❌ Error: Version tag $tag already exists"
        echo "   Please use a different version number."
        exit 1
    fi
}

# Function to generate changelog entry
generate_changelog_entry() {
    local version="$1"
    local date=$(date '+%Y-%m-%d')
    local previous_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    echo "## [$version] - $date"
    echo ""
    
    if [[ -n "$previous_tag" ]]; then
        echo "### Changes since $previous_tag"
        echo ""
        # Get commits since last tag
        git log --oneline --no-merges "${previous_tag}..HEAD" | sed 's/^/- /'
    else
        echo "### Changes"
        echo ""
        echo "- Initial release"
    fi
    echo ""
}

# Check command line arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <version> [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  $0 1.2.3        # Release version 1.2.3"
    echo "  $0 1.2.3-rc1    # Release version 1.2.3-rc1"
    echo "  $0 1.2.3 --dry-run  # Dry run (no actual release)"
    echo ""
    exit 1
fi

VERSION="$1"
DRY_RUN=false

if [[ $# -eq 2 ]] && [[ "$2" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Validate inputs
validate_version "$VERSION"

if [[ "$DRY_RUN" == "false" ]]; then
    check_main_branch
    check_clean_working_dir
    check_version_exists "$VERSION"
fi

TAG="v$VERSION"

echo "🔍 Pre-release checks..."
echo "   Version: $VERSION"
echo "   Tag: $TAG"
echo "   Dry run: $DRY_RUN"
echo ""

# Run tests
echo "🧪 Running tests..."
if [[ "$DRY_RUN" == "false" ]]; then
    ./scripts/test.sh
else
    echo "   (Skipped in dry run)"
fi

# Build the package
echo "🏗️  Building package..."
if [[ "$DRY_RUN" == "false" ]]; then
    ./scripts/build.sh
else
    echo "   (Skipped in dry run)"
fi

# Update CHANGELOG if it doesn't exist
if [[ ! -f "CHANGELOG.md" ]] && [[ "$DRY_RUN" == "false" ]]; then
    echo "📝 Creating CHANGELOG.md..."
    cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

$(generate_changelog_entry "$VERSION")
EOF
    git add CHANGELOG.md
    git commit -m "Add CHANGELOG.md for release $VERSION"
fi

# Create and push tag
if [[ "$DRY_RUN" == "false" ]]; then
    echo "🏷️  Creating and pushing tag $TAG..."
    git tag -a "$TAG" -m "Release $VERSION"
    git push origin "$TAG"
    
    echo "✅ Release tag $TAG created and pushed!"
    echo ""
    echo "🚀 GitHub Actions will now:"
    echo "   1. Run tests"
    echo "   2. Build the package"
    echo "   3. Publish to PyPI"
    echo "   4. Create GitHub release"
    echo ""
    echo "You can monitor the release at:"
    echo "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git.*/\1/')/actions"
else
    echo "🏷️  Would create and push tag $TAG"
    echo "✅ Dry run completed successfully!"
fi