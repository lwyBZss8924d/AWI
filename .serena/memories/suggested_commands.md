# Carbonyl Development Commands

## Core (Rust Library) Development
- `cargo build` - Build the Rust library in debug mode
- `cargo build --release` - Build the Rust library in release mode
- `cargo build --target [triple] --release` - Build for specific target architecture

## Runtime (Chromium) Development

### Initial Setup
1. `./scripts/gclient.sh sync` - Fetch Chromium source code (requires ~100GB disk space)
2. `./scripts/patches.sh apply` - Apply Carbonyl patches to Chromium

### Configuration
- `./scripts/gn.sh args out/Default` - Configure build target
  - Use different target names for different configs (e.g., out/release, out/debug, out/arm64)

### Building
- `./scripts/build.sh Default` - Build both libcarbonyl and Chromium runtime
- `./scripts/build.sh Default [cpu]` - Build for specific CPU architecture

### Running
- `./scripts/run.sh Default [URL]` - Run Carbonyl with the specified build
  - Example: `./scripts/run.sh Default https://wikipedia.org`

## Docker
- `./scripts/docker-build.sh Default arm64` - Build arm64 Docker image
- `./scripts/docker-build.sh Default amd64` - Build amd64 Docker image
- `docker run --rm -ti fathyb/carbonyl https://youtube.com` - Run Carbonyl in Docker

## Release & Publishing
- `./scripts/release.sh` - Create release build
- `./scripts/npm-publish.sh` - Publish to npm
- `./scripts/changelog.sh` - Generate changelog

## Platform Detection
- `./scripts/platform-triple.sh [cpu]` - Get platform triple for current system

## Quick Development Workflow
For Rust-only changes (most common):
1. `cargo build --release` - Build libcarbonyl
2. Copy the built library to a release version of Carbonyl
3. Test changes