#!/bin/bash
# Carbonyl development runner - Build and test quickly
# Usage: ./dev-run.sh [URL]

set -e

# Set environment defaults
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-build}"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.13}"

# Verify runtime architecture
if ! file carbonyl-runtime/carbonyl 2>/dev/null | grep -q 'arm64'; then
    echo "❌ Error: Runtime is not arm64 architecture or not found"
    echo "   Please run ./dev-setup.sh first"
    exit 1
fi

echo "🔨 Building libcarbonyl..."
cargo build --release --target aarch64-apple-darwin

echo "📦 Copying library to runtime..."

# Backup existing library if present
[ -f carbonyl-runtime/libcarbonyl.dylib ] && \
  cp -a carbonyl-runtime/libcarbonyl.dylib carbonyl-runtime/libcarbonyl.dylib.bak || true

# Copy the built library
cp "$CARGO_TARGET_DIR/aarch64-apple-darwin/release/libcarbonyl.dylib" carbonyl-runtime/

# Fix the install name to use @executable_path
install_name_tool -id @executable_path/libcarbonyl.dylib carbonyl-runtime/libcarbonyl.dylib

echo "🚀 Running Carbonyl..."
./carbonyl-runtime/carbonyl "$@"