#!/bin/bash
# =============================================================================
# Ibex Release Script
# Builds a release binary and uploads it to GitHub Releases
# =============================================================================
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ibex"
BINARY_NAME="ibex"
ARCH=$(uname -m)  # arm64 or x86_64

# Parse version from git tag or use provided argument
VERSION="${1:-}"

# =============================================================================
# Helper Functions
# =============================================================================

print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
    exit 1
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    # Check for gh CLI
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is required. Install via: brew install gh"
    fi
    
    # Check if logged in to gh
    if ! gh auth status &> /dev/null; then
        print_error "You must be logged in to GitHub CLI. Run: gh auth login"
    fi
    
    # Check for swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift toolchain is required."
    fi
    
    echo "  ✓ All dependencies found"
}

get_version() {
    if [ -z "$VERSION" ]; then
        # Try to get version from latest git tag
        VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        
        if [ -z "$VERSION" ]; then
            # Prompt user for version
            echo ""
            read -p "Enter version (e.g., v1.0.0): " VERSION
        fi
    fi
    
    # Validate version format
    if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format. Expected: v1.0.0"
    fi
    
    echo "  Version: $VERSION"
}

# =============================================================================
# Build
# =============================================================================

build_release() {
    print_step "Building release binary..."
    
    # Clean previous builds
    swift package clean
    
    # Build release
    swift build -c release
    
    # Verify binary exists
    BINARY_PATH=".build/release/${BINARY_NAME}"
    if [ ! -f "$BINARY_PATH" ]; then
        print_error "Build failed. Binary not found at $BINARY_PATH"
    fi
    
    echo "  ✓ Build successful"
}

# =============================================================================
# Package
# =============================================================================

package_release() {
    print_step "Packaging release..."
    
    # Create release directory
    RELEASE_DIR="release"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    # Copy binary
    cp ".build/release/${BINARY_NAME}" "$RELEASE_DIR/"
    
    # Create archive name with architecture
    ARCHIVE_NAME="${PROJECT_NAME}-${VERSION}-macos-${ARCH}.tar.gz"
    
    # Create compressed archive
    cd "$RELEASE_DIR"
    tar -czvf "../${ARCHIVE_NAME}" "${BINARY_NAME}"
    cd ..
    
    # Clean up
    rm -rf "$RELEASE_DIR"
    
    echo "  ✓ Created: $ARCHIVE_NAME"
}

# =============================================================================
# Upload to GitHub
# =============================================================================

upload_to_github() {
    print_step "Uploading to GitHub Releases..."
    
    ARCHIVE_NAME="${PROJECT_NAME}-${VERSION}-macos-${ARCH}.tar.gz"
    
    # Check if release already exists
    if gh release view "$VERSION" &> /dev/null; then
        print_warning "Release $VERSION already exists. Uploading asset to existing release..."
        gh release upload "$VERSION" "$ARCHIVE_NAME" --clobber
    else
        # Create new release with the archive
        echo "  Creating new release: $VERSION"
        gh release create "$VERSION" "$ARCHIVE_NAME" \
            --title "Ibex $VERSION" \
            --notes "## What's New

### Installation

Download the binary and extract:
\`\`\`bash
tar -xzf ${ARCHIVE_NAME}
chmod +x ibex
sudo mv ibex /usr/local/bin/
\`\`\`

### Usage
\`\`\`bash
# Pull a model
ibex pull mlx-community/Llama-3.2-1B-Instruct-4bit

# Run interactive chat
ibex run

# Start server
ibex serve --model mlx-community/Llama-3.2-1B-Instruct-4bit
\`\`\`
"
    fi
    
    # Clean up archive
    rm -f "$ARCHIVE_NAME"
    
    echo "  ✓ Uploaded to GitHub Releases"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "==========================================="
    echo "  Ibex Release Script"
    echo "==========================================="
    echo ""
    
    check_dependencies
    get_version
    build_release
    package_release
    upload_to_github
    
    echo ""
    echo -e "${GREEN}✓ Release $VERSION published successfully!${NC}"
    echo ""
    echo "View release: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/$VERSION"
    echo ""
}

main
