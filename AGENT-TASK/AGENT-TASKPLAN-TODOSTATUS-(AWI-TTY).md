# AWI-TTY AGENT (CLAUDE/WARP/CURSOR) TASK TODO & STATUS

Document owner: Agent Mode
Last updated: 2025-08-27
Scope: MVP for AWI-TTY (Agent Mode + JSON-RPC + text snapshot + awi-tty CLI façade)

References
- PRD: docs/PRD/AWI-TTY.md
- Agent Guide: docs/AWI-TTY-AGENTS.md

Conventions
- Status: TODO | DOING | BLOCKED | DONE | DEFERRED
- Owner: initials or @github
- Exit criteria: measurable outcomes

1) Repo Bootstrap and Branching
- [DONE] Rename local directory to AWI
- [DONE] Point origin to https://github.com/lwyBZss8924d/AWI.git
- [TODO] Push main to new origin (first push)
  - Owner: @arthur
  - Exit: remote main exists with latest docs
- [TODO] Create feature worktree feature/awi-tty and push
  - Owner: Agent Mode
  - Exit: remote branch origin/feature/awi-tty exists

2) Agent Mode (Headless-TTY) Core (MVP)
- [TODO] CLI flag --agent-socket=<path> in src/cli/cli.rs; parse to CommandLine
  - Exit: --agent-socket appears in --help and parsed into CommandLine
- [TODO] Suppress ALT-screen, OSC title writes, and frame stdout in Agent Mode
  - Files: src/input/tty.rs, src/output/painter.rs, src/output/renderer.rs
  - Exit: Running with --agent-socket keeps stdout clean, no UI hijack
- [TODO] Disable stdin listener in Agent Mode; route events from RPC to renderer
  - Files: src/browser/bridge.rs (listen thread gate)
  - Exit: No blocking on stdin; navigation/keys come via RPC

3) JSON-RPC Server (MVP)
- [TODO] UDS bind with secure path (XDG_RUNTIME_DIR or /tmp/carbonyl-$UID)
  - Exit: socket created with 0600; parent 0700; ownership verified
- [TODO] Methods: navigate, send_key, scroll, snapshot(text[, include_meta]), get_title, get_url, get_nav_state, set_viewport, get_capabilities
  - Exit: Each method returns JSON-RPC 2.0 compliant response
- [TODO] Error model and throttling
  - Exit: Domain errors (-32010..-32014) + rate-limited behavior covered by tests

4) Renderer Snapshot (MVP)
- [TODO] Implement snapshot_text() reading cells safely on render thread
  - Exit: snapshot returns width/height/lines[]; include_meta option returns cursor/url/title/dpi/scale/nav

5) awi-tty CLI Façade (MVP)
- [TODO] Implement awi-tty binary (Rust or shell fallback)
  - Commands: navigate, send-key, scroll, snapshot, get-title, get-url, get-nav-state, set-viewport, get-capabilities
  - Exit: Commands work end-to-end against local socket; semantic exit codes

6) Docs, Tests, CI
- [TODO] Update README snippet (getting started with AWI-TTY)
- [TODO] Unit tests: snapshot (CJK/emoji), key mapping, viewport override
- [TODO] Integration tests: simple navigation + snapshot path; throttling test
- [TODO] Add docs/AWI-TTY-AGENTS.md to site index

Milestones
- M1: Agent Mode scaffolding + UDS server skeleton [target: 1–2 days]
- M2: RPC methods + snapshot + awi-tty CLI parity [target: 2–3 days]
- M3: Error/permissions/throttling + docs/tests [target: 1–2 days]

Progress Log
- 2025-08-27: Created PRD and Agents guide; renamed repo to AWI; updated origin; preparing branches

