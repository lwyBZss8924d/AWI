# Task Completion Checklist for Carbonyl

When completing a development task in Carbonyl, ensure the following:

## For Rust Code Changes (libcarbonyl)
1. Build the library in release mode: `cargo build --release`
2. Ensure the library compiles without warnings
3. If changing FFI interfaces, update corresponding C++ bridge code in `src/browser/`

## For C++ Code Changes (Chromium runtime)
1. Run the full build: `./scripts/build.sh Default`
2. Test the changes with: `./scripts/run.sh Default [test-url]`
3. Ensure Chromium patches still apply cleanly

## For Cross-Platform Changes
1. Consider platform-specific code paths (Linux sysroot, macOS dylib vs Linux .so)
2. Test on target platform if possible
3. Update build.rs if build configuration changes

## Integration Testing
1. Run the built browser with various websites to ensure rendering works
2. Test terminal-specific features (resize, mouse input, keyboard navigation)
3. Verify performance (should maintain 60 FPS, 0% idle CPU)

## Before Committing
1. Ensure no sensitive information in code
2. Follow existing code patterns and style
3. Update relevant documentation if behavior changes

Note: There are no explicit linting or formatting commands detected in the project.
The focus is on integration with Chromium and terminal rendering functionality.