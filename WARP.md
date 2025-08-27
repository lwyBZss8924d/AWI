# WARP.md

This file provides guidance to WARP (warp.dev) when working with AWI (Agent Web Interface) — built on top of Carbonyl — in this repository.

AWI (Agent Web Interface) — Use [AWI-TTY](docs/PRD/AWI-TTY.md) for Agent Computer Interface. Use [carbonyl](https://github.com/fathyb/carbonyl) as the runtime foundation.

Carbonyl is a Chromium-based browser that runs entirely in a terminal. The project consists of a Rust core library (libcarbonyl) and a modified Chromium headless shell runtime that loads the library and renders directly to terminal cells.

Key references read to produce this guide:
- readme.md
- CLAUDE.md
- scripts/* (build.sh, run.sh, gclient.sh, gn.sh, patches.sh, env.sh, platform-triple.sh)
- src/* (notably browser/bridge.rs, browser/renderer.{cc,h}, output/renderer.rs, cli/*, browser/args.gn)
- build.rs

Common commands
- Rust core (fast iteration)
  - Build release library
    - macOS minimum target is set by scripts; adjust as needed
    ```bash
    cargo build --release
    # Outputs:
    #  - macOS: target/release/libcarbonyl.dylib
    #  - Linux: target/release/libcarbonyl.so
    ```

- Full runtime (Chromium + Rust)
  - One-time Chromium fetch (~100GB disk; long build times)
    ```bash
    ./scripts/gclient.sh sync
    ```
  - Apply Carbonyl patches to Chromium/Skia/WebRTC (warns: stashes local changes)
    ```bash
    ./scripts/patches.sh apply
    ```
  - Configure build args (creates out/<Target>)
    ```bash
    ./scripts/gn.sh args out/Default
    # When prompted, use:
    # import("//carbonyl/src/browser/args.gn")
    #
    # # target_cpu = "arm64"   # uncomment for arm64
    # cc_wrapper = "env CCACHE_SLOPPINESS=time_macros ccache"
    # is_debug = false
    # symbol_level = 0
    # is_official_build = true
    ```
  - Build binaries (copies libcarbonyl.* into Chromium out/<Target> and builds headless_shell)
    ```bash
    ./scripts/build.sh Default
    # Outputs in chromium/src/out/Default/:
    #   headless_shell
    #   libcarbonyl.so|dylib
    #   icudtl.dat, v8_context_snapshot.bin, libEGL.so, libGLESv2.so (Linux)
    ```
  - Run
    ```bash
    ./scripts/run.sh Default https://wikipedia.org
    ```

- Docker
  - Build image from pre-built binaries for an architecture
    ```bash
    ./scripts/docker-build.sh arm64
    ./scripts/docker-build.sh amd64
    ```
  - Run published image (from README)
    ```bash
    docker run --rm -ti fathyb/carbonyl https://youtube.com
    ```

- npm (published package usage)
  ```bash
  npm install --global carbonyl
  carbonyl https://github.com
  ```

Notes on tests and linting
- No explicit unit tests or lint/format commands are defined in this repository. Validation is typically done by building and running the browser as above.

High-level architecture and structure
- Two-part system
  - Rust core library (cdylib): terminal I/O, rendering, navigation/UI, CLI parsing
    - Entry modules: src/lib.rs; exposes browser, cli, gfx, input, output, ui
    - Rendering pipeline: src/output/renderer.rs
      - Renders to a grid of terminal “cells” with quadrant color composition for background pixels
      - Text rendering uses Unicode grapheme segmentation and width calculation
      - Frame pacing utility in src/output/frame_sync.rs for steady FPS
    - Input handling: src/input/* (keyboard, mouse, parser, tty) → emits NavigationAction
    - CLI: src/cli/{cli.rs,program.rs}, flags include --fps, --zoom, --debug, --bitmap; also sets CARBONYL_ENV_* env vars
  - Chromium headless runtime (C++): loads libcarbonyl and drives rendering
    - FFI bridge: src/browser/bridge.rs provides extern "C" functions consumed by C++
    - C++ side: src/browser/renderer.{cc,h} calls into Rust bridge to create/start/resize renderer, push nav, draw text/bitmaps, and forward input events
    - Browser delegate (C callbacks) used by Rust to request navigation actions (refresh, go_to, back/forward, scroll, key/mouse)
    - Build configuration: src/browser/args.gn
      - Enables proprietary codecs (H.264) and disables unused subsystems, sets ozone headless, etc.

- Control/data flow
  - CLI parse → environment flags → when not in shell mode, Rust spawns Chromium with same executable and args; stderr captured for --debug
  - Chromium process loads libcarbonyl, queries DPI/bitmap mode, creates renderer via FFI
  - Chromium provides pixels and text regions to Rust; Rust updates terminal cells and flushes to stdout
  - Input events captured in Rust (thread) → translated to delegate calls back into Chromium; navigation state maintained in Rust UI module

- Build system and environment
  - Rust via Cargo; Linux builds may link against Chromium sysroots (build.rs prints link args when sysroot directories exist)
  - Chromium via GN/Ninja driven by scripts/*; scripts/env.sh defines CHROMIUM_ROOT/SRC, adds depot_tools to PATH (fetched as submodule on first use)
  - Cross-compilation helper: scripts/platform-triple.sh normalizes cpu/platform triples for cargo and docker build contexts

Platform and performance notes (from README)
- Building Chromium is resource-intensive (time, CPU, disk). Expect ~1 hour on fast hardware and ~100GB disk usage.
- Building Chromium for arm64 on Linux requires an amd64 host.
- Fullscreen not yet supported.
- Targets tested primarily on Linux and macOS.

Troubleshooting tips
- If Chromium sysroot warnings appear on Linux during cargo build, ensure chromium/src/build/linux/*-sysroot folders exist or complete the Chromium fetch step.
- If depot_tools commands (gn, gclient, ninja) are missing, re-run scripts that source scripts/env.sh; the submodule is auto-initialized when needed.
- Use --debug to have stderr printed on exit for easier diagnosis.

Source highlights
- CLI flags and env wiring: src/cli/cli.rs, src/cli/program.rs
- FFI boundary (Rust↔C++): src/browser/bridge.rs and src/browser/renderer.{cc,h}
- Terminal rendering core: src/output/renderer.rs, src/output/window.rs, src/output/painter.rs
- Build args presets: src/browser/args.gn
- Linux sysroot linkage: build.rs

Keep this file concise. For deeper details, prefer reading readme.md and CLAUDE.md, and inspect scripts/* when changing build flows.

