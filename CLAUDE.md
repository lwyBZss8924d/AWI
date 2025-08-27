# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Local Development Setup (Without Chromium Source)

The project includes development helper scripts for rapid iteration without needing the full Chromium source:

### Quick Start
```bash
# One-time setup (downloads runtime, builds library)
./dev-setup.sh

# Build and run with any URL
./dev-run.sh https://example.com

# Run test suite with common sites
./dev-test.sh
```

### Directory Structure
```
AWI/
├── carbonyl-runtime/        # Pre-built runtime (downloaded)
│   ├── carbonyl            # Main executable
│   ├── libcarbonyl.dylib   # Replaced by our builds
│   └── [support files]
├── build/                  # Rust build output (not target/)
│   └── aarch64-apple-darwin/release/
│       └── libcarbonyl.dylib
├── dev-run.sh             # Quick build & test script
├── dev-test.sh            # Test suite script
└── dev-setup.sh           # Initial setup script
```

### Development Workflow
1. Make changes to Rust code in `src/`
2. Run `./dev-run.sh https://example.com` to build and test
3. The script automatically builds and copies the library to runtime

**Note**: The build output is in `build/` directory, NOT `target/` directory.

## Project Overview

Carbonyl is a Chromium-based browser that runs entirely in a terminal. It consists of two main components:
- **libcarbonyl**: A Rust library that handles terminal I/O and rendering
- **Chromium runtime**: A modified Chromium headless shell that integrates with libcarbonyl

## Essential Commands

### For Quick Rust Development (Most Common)
```bash
# Build the Rust library only
cargo build --release

# The built library will be in:
# Linux: target/release/libcarbonyl.so
# macOS: target/release/libcarbonyl.dylib
```

### For Full Build (Rust + Chromium)
```bash
# Build everything (assumes Chromium is already fetched)
./scripts/build.sh Default

# Run the browser
./scripts/run.sh Default https://example.com
```

### Initial Chromium Setup (One-time, ~100GB disk space required)
```bash
# 1. Fetch Chromium source
./scripts/gclient.sh sync

# 2. Apply Carbonyl patches
./scripts/patches.sh apply

# 3. Configure build target
./scripts/gn.sh args out/Default
# When prompted, use the config from readme.md
```

## Architecture

### Core Library Structure (Rust)
- `src/input/` - Terminal input handling
  - `keyboard.rs`, `mouse.rs` - Input event processing
  - `dcs/` - DCS escape sequence parsing
  - `tty.rs` - TTY mode management
  
- `src/output/` - Terminal rendering pipeline
  - `renderer.rs` - Main rendering logic
  - `cell.rs` - Terminal cell management
  - `quantizer.rs` - Color quantization for terminal
  - `frame_sync.rs` - 60 FPS frame synchronization
  
- `src/browser/` - Chromium integration
  - `bridge.rs/cc/h` - FFI bridge between Rust and C++
  - `carbonyl.mojom` - Mojo IPC interface definition
  - `render_service_impl.cc` - Chromium-side implementation
  
- `src/gfx/` - Graphics primitives (point, rect, color, size, vector)
- `src/ui/` - UI components and navigation
- `src/cli/` - Command-line interface

### Key Integration Points
- The Rust library is compiled as a C dynamic library (cdylib)
- Chromium loads libcarbonyl at runtime
- Communication happens through Mojo IPC defined in `carbonyl.mojom`
- The browser renders web content to terminal cells instead of pixels

### Build Outputs Location
After building, find binaries in `chromium/src/out/Default/`:
- `headless_shell` - Main executable
- `libcarbonyl.so/.dylib` - Rust library
- `icudtl.dat`, `v8_context_snapshot.bin` - Required support files
- `libEGL.so`, `libGLESv2.so` - Graphics libraries (Linux)

## Development Workflow Tips

1. **For Rust-only changes**: Just run `cargo build --release` and copy the library to an existing Carbonyl build
2. **Platform differences**: Linux uses `.so` files, macOS uses `.dylib` files with `install_name_tool`
3. **No explicit test/lint commands**: The project focuses on integration testing by running the browser
4. **Performance targets**: Should maintain 60 FPS and 0% idle CPU usage

## Important Notes
- When modifying FFI interfaces in `src/browser/`, update both Rust and C++ sides
- The project uses platform-specific sysroots on Linux (see `build.rs`)
- Scripts in `scripts/` wrap Chromium build tools (gn, ninja, gclient)