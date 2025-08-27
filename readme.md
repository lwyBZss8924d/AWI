<table align="center">
  <tbody>
    <tr>
      <td>
        <p></p>
<pre>

    ______  _  _  _ _____ 
    |_____| |  |  |   |    Agent Web Interface
    |     | |__|__| __|__  (TTY)

</pre>
      </td>
      <td><h1>AWI</h1></td>
    </tr>
  </tbody>
</table>

AWI (Agent Web Interface) — Use [AWI-TTY](docs/PRD/AWI-TTY.md) for Agent Computer Interface. Use [carbonyl](https://github.com/fathyb/carbonyl) as the runtime foundation.

# What is AWI?
AWI is an agent-first terminal web interface. It lets LLM agents browse and operate web pages in a terminal, programmatically and observably. AWI focuses on:
- Orchestrable control: navigate, send keys, scroll
- Observable output: fetch terminal-rendered snapshots (text/ANSI)
- Agent-ready tooling: a simple CLI façade (awi-tty) so agents don't need to emit JSON

AWI is powered by Carbonyl for rendering fidelity and performance, but centers the agent workflow with AWI-TTY.

# Key Features
- AWI-TTY CLI for agents (no JSON handcrafting)
- Local JSON-RPC over Unix Socket for robust automation
- Text snapshots of the rendered terminal output (ANSI planned)
- Stable, semantic exit codes for programmatic control
- Works locally and over SSH

# Quick Start (Agents)
1) Start AWI in Agent Mode (local socket):
```bash
./carbonyl-runtime/carbonyl --agent-socket=/tmp/carbonyl.sock https://news.ycombinator.com/
```
2) Use AWI-TTY to control and observe:
```bash
export AWI_SOCK=/tmp/carbonyl.sock
awi-tty navigate https://news.ycombinator.com/
awi-tty send-key Tab && awi-tty send-key Enter
awi-tty scroll 5
awi-tty snapshot --format text --plain | sed -n '1,40p'
```
More patterns and tips: see [docs/AWI-TTY-AGENTS.md](docs/AWI-TTY-AGENTS.md).

# AWI-TTY Command Surface (MVP)
- navigate <url>
- send-key <Tab|Enter|Up|Down|Left|Right|Space|Char:<byte>> [--alt|--meta|--shift|--ctrl]
- scroll <delta>
- snapshot [--format text] [--include-meta] [--plain|--json]
- get-title | get-url | get-nav-state
- set-viewport <cols> <rows> | get-capabilities

P1 additions: type-text, paste, wait-for-*, snapshot --format ansi, click/mouse-*, subscribe-events.

# Architecture (High-level)
- Agent façade: awi-tty (CLI)
- Control plane: JSON-RPC over Unix Socket
- Render thread: terminal rendering pipeline and snapshot export
- Powered by: Carbonyl (Chromium headless + Rust core)

# Development (AWI)
- Rust core quick build:
```bash
cargo build --release
```
- Verify runtime + build:
```bash
./dev-verify.sh
```
- Run a URL (fast path using downloaded runtime):
```bash
./dev-run.sh https://example.com
```

# Powered by Carbonyl
For deep Chromium + Carbonyl workflows (optional):
- Fetch Chromium:
```bash
./scripts/gclient.sh sync
```
- Apply patches:
```bash
./scripts/patches.sh apply
```
- Configure & Build:
```bash
./scripts/gn.sh args out/Default
./scripts/build.sh Default
```
- Run:
```bash
./scripts/run.sh Default https://wikipedia.org
```

# OS Support
- Linux • macOS • Windows 11/WSL

# License
BSD-3-Clause
