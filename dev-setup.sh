#!/bin/bash
# One-time setup script for Carbonyl development environment
# Usage: ./dev-setup.sh

set -e

# Set environment defaults
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-build}"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"

echo "🎯 Setting up Carbonyl development environment..."
echo "   CARGO_TARGET_DIR: $CARGO_TARGET_DIR"
echo "   MACOSX_DEPLOYMENT_TARGET: $MACOSX_DEPLOYMENT_TARGET"
echo ""

# Check if runtime already exists
if [ -d "carbonyl-runtime" ] && [ -f "carbonyl-runtime/carbonyl" ]; then
    echo "✓ Runtime already exists in carbonyl-runtime/"
else
    echo "📥 Downloading Carbonyl runtime for macOS ARM64..."
    curl -L https://github.com/fathyb/carbonyl/releases/download/v0.0.3/carbonyl.macos-arm64.zip -o carbonyl.zip
    
    echo "📦 Extracting runtime..."
    unzip -q carbonyl.zip -d carbonyl-runtime-tmp
    mv carbonyl-runtime-tmp/carbonyl-*/* carbonyl-runtime/ 2>/dev/null || mv carbonyl-runtime-tmp/* carbonyl-runtime/
    rmdir carbonyl-runtime-tmp 2>/dev/null || true
    rm carbonyl.zip
    
    echo "✓ Runtime extracted to carbonyl-runtime/"
fi

echo ""
echo "🔨 Building libcarbonyl..."
cargo build --release --target aarch64-apple-darwin

echo ""
echo "📦 Copying library to runtime..."

# Backup existing library if present
[ -f carbonyl-runtime/libcarbonyl.dylib ] && \
  cp -a carbonyl-runtime/libcarbonyl.dylib carbonyl-runtime/libcarbonyl.dylib.bak && \
  echo "   Backed up existing library to libcarbonyl.dylib.bak"

# Copy the built library
cp "$CARGO_TARGET_DIR/aarch64-apple-darwin/release/libcarbonyl.dylib" carbonyl-runtime/

# Fix the install name to use @executable_path
echo "🔧 Fixing dylib install name..."
install_name_tool -id @executable_path/libcarbonyl.dylib carbonyl-runtime/libcarbonyl.dylib
echo "   Set install name to @executable_path/libcarbonyl.dylib"

echo ""
echo "✅ Setup complete! You can now run:"
echo "  ./dev-run.sh https://example.com    # Run with a URL"
echo "  ./dev-test.sh                       # Run test suite"
echo "  ./dev-verify.sh                     # Verify setup"