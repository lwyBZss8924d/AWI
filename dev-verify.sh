#!/bin/bash
# Verify Carbonyl development setup
# Usage: ./dev-verify.sh

set -e

echo "🔍 Verifying Carbonyl development setup..."
echo ""

# Check if runtime directory exists
if [ ! -d "carbonyl-runtime" ]; then
    echo "❌ carbonyl-runtime directory not found"
    echo "   Please run ./dev-setup.sh first"
    exit 1
fi

# Check if required files exist
echo "📂 Checking required files..."
required_files=(
    "carbonyl-runtime/carbonyl"
    "carbonyl-runtime/libcarbonyl.dylib"
    "carbonyl-runtime/icudtl.dat"
    "carbonyl-runtime/v8_context_snapshot.arm64.bin"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (missing)"
    fi
done

echo ""
echo "🏗️ Checking architectures..."
file carbonyl-runtime/carbonyl carbonyl-runtime/libcarbonyl.dylib

echo ""
echo "📚 Checking library dependencies..."
echo "libcarbonyl.dylib install name:"
otool -L carbonyl-runtime/libcarbonyl.dylib | head -2

# Verify install name is correct
echo ""
if otool -L carbonyl-runtime/libcarbonyl.dylib | head -2 | grep -q "@executable_path"; then
    echo "✅ Install name is correctly set to @executable_path"
else
    echo "⚠️  Install name is not using @executable_path"
    echo "   Run ./dev-setup.sh or ./dev-run.sh to fix this"
fi

# Check for backup
echo ""
if [ -f "carbonyl-runtime/libcarbonyl.dylib.bak" ]; then
    echo "💾 Backup found: carbonyl-runtime/libcarbonyl.dylib.bak"
else
    echo "ℹ️  No backup found (will be created on next update)"
fi

# Check Rust build
echo ""
echo "🦀 Checking Rust build..."
if [ -f "build/aarch64-apple-darwin/release/libcarbonyl.dylib" ]; then
    echo "   ✅ libcarbonyl.dylib found in build directory"
    built_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "build/aarch64-apple-darwin/release/libcarbonyl.dylib")
    echo "   Last built: $built_time"
else
    echo "   ℹ️  No build found yet (will be created when you run dev-run.sh)"
fi

# Check environment
echo ""
echo "🌍 Environment:"
echo "   CARGO_TARGET_DIR: ${CARGO_TARGET_DIR:-build (default)}"
echo "   MACOSX_DEPLOYMENT_TARGET: ${MACOSX_DEPLOYMENT_TARGET:-10.13 (default)}"
echo "   Rust version: $(rustc --version)"
echo "   System arch: $(uname -m)"

echo ""
echo "✨ Verification complete!"