# AWI Project Overview

## What is AWI?

AWI (Agent Web Interface) — Use [AWI-TTY](docs/PRD/AWI-TTY.md) for Agent Computer Interface. Use [carbonyl](https://github.com/fathyb/carbonyl) as the runtime foundation.

Carbonyl is a Chromium-based browser built to run entirely in a terminal. It's a unique project that renders web content directly to the terminal without requiring a window server.

## Key Features
- Supports modern Web APIs including WebGL, WebGPU, audio/video playback, animations
- Runs at 60 FPS with 0% idle CPU usage
- Starts in less than a second
- Works over SSH and in safe-mode console
- No window server required

## Technology Stack
- **Core Library (libawi)**: Written in Rust
  - Uses unicode-width, unicode-segmentation for terminal rendering
  - Compiled as a cdylib (C dynamic library)
- **Runtime**: Modified Chromium headless shell (C++)
  - Uses Chromium's Blink rendering engine
  - Integrates with the Rust core via FFI

## Project Structure
- `src/` - Rust source code for libawi
  - `browser/` - C++ bridge code and Chromium integration
  - `input/` - Terminal input handling (keyboard, mouse, TTY)
  - `output/` - Terminal rendering (cells, quantizer, renderer)
  - `gfx/` - Graphics primitives (color, point, rect, size, vector)
  - `ui/` - UI components and navigation
  - `cli/` - Command-line interface
- `chromium/` - Chromium source code (submodule)
- `scripts/` - Build and development scripts
- `build.rs` - Rust build configuration (links to Chromium sysroot on Linux)

## Build Outputs
- `libawi.so` (Linux) / `libawi.dylib` (macOS) - Core Rust library
- `headless_shell` - Modified Chromium binary
- Supporting files: `icudtl.dat`, `libEGL.so`, `libGLESv2.so`, `v8_context_snapshot.bin`