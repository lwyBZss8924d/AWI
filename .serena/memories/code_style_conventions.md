# AWI Code Style and Conventions

## Rust Code Style
- **Edition**: Rust 2021
- **Module Organization**: 
  - Public modules exposed in lib.rs: browser, cli, gfx, input, output, ui
  - Internal utils module
  - Each major module has its own directory with submodules
- **FFI Bridge**: The browser module contains C++ bridge code for Chromium integration
- **Dependencies**: Minimal - only libc, unicode-width, unicode-segmentation, chrono

## C++ Code Style (Chromium Integration)
- Follows Chromium coding standards
- Bridge code in `src/browser/` directory
- Uses Mojo IPC for communication (awi.mojom)
- Headers use `.h` extension, implementations use `.cc`

## Build Configuration
- Uses GN build system for Chromium
- Cargo for Rust library
- Platform-specific sysroot linking for Linux builds
- Supports cross-compilation for arm64/amd64

## File Organization Patterns
- Terminal I/O separated: `input/` for keyboard/mouse, `output/` for rendering
- Graphics primitives in `gfx/` module
- UI components separated from core logic
- Clear separation between Rust core and C++ runtime

## Testing & Quality
- No explicit testing framework detected in the Rust codebase
- Project focuses on integration with Chromium's existing test infrastructure
- Build scripts handle platform detection and architecture-specific builds