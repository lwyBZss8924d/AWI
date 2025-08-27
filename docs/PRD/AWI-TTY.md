# [new-features] Agent Web Interface TTY (AWI-TTY) — AWI Feature Proposal (based on Carbonyl)

Author: Agent Mode
Date: 2025-08-27
Status: Design draft (MVP implementable)

1. Summary (TL;DR)
- Purpose: Allow agents to programmatically drive Carbonyl without taking over a real TTY, in an orchestrable and observable way. Agents can load pages, navigate, send keys/scroll, and read back the rendered state for automation, testing, and data extraction.
- Approach: Add a local Unix Socket JSON-RPC control endpoint inside Carbonyl (localhost-only). Expose methods like send_key, scroll, navigate, snapshot. When enabled, Carbonyl does not render directly to the terminal; instead, snapshots are pulled on demand.
- Outcome: No tmux or external wrappers required. RPC gives deterministic control and observation of the terminal-rendered web. Easier to integrate, test, and extend.

2. Background and Problem Statement
- Today: Carbonyl targets human interaction. It writes frames to stdout (TTY) and reads input from stdin.
- Need: Users want agents to "use Carbonyl themselves" to browse and operate pages inside a terminal context, then validate the experience and build higher-level "terminal web environments" for agents.
- Challenges:
  - Full-screen TTY programs take over the terminal, which is not ideal for agent-driven, non-interactive orchestration.
  - Input is read from stdin, which is hard to inject programmatically and reliably.
  - We need a way to observe what Carbonyl has rendered (text/colors/bitmap), not just dump bytes to a TTY.

3. Goals and Non-goals
- Goals (MVP)
  - CLI flag to enable "Agent Mode" listening on a local Unix Socket (JSON-RPC 2.0).
- Core methods (MVP): navigate, send_key, scroll, snapshot (text), get_title, get_url, get_nav_state, set_viewport, get_capabilities.
  - CLI façade (MVP): ship an official awi-tty wrapper that maps simple shell subcommands/flags to the JSON-RPC, so agents avoid composing nested JSON; stable quoting and exit codes.
  - Agent Mode behavior: do not enter ALT screen, suppress stdout frame writes and OSC title writes; keep render state in-memory and expose snapshots via RPC.
  - Security defaults: bind to a secure UDS path with strict permissions; robust error handling; clean up socket at exit.
- Non-goals (MVP)
  - DOM-level selectors or scraping APIs (Carbonyl does not expose DOM).
  - Remote TCP/WebSocket access (can be added by an external gateway later).
  - Pixel-perfect PNG output guarantees (can be added later).

4. User Stories
- As an automation agent, I can:
  - Start Carbonyl at a URL → take a text snapshot of the rendered output → detect the top 2 stories on HN → send Tab/Enter to open the comments → scroll and capture the top-level comments → produce a summary.
  - Repeat the same flow in CI to assert output stability and detect regressions.

5. Acceptance Criteria
- CLI enables: --agent-socket=/path/to.sock (default path chosen securely) with an initial URL.
- Agent Mode disables the stdin TTY listener and suppresses ALT screen + OSC title writes; stdout remains clean.
- JSON-RPC calls work: navigate/send_key/scroll/snapshot/get_title/get_url/get_nav_state/set_viewport/get_capabilities return in ~200ms on localhost.
- Viewport sizing: if not explicitly set via set_viewport {cols, rows}, defaults to 140x45.
- snapshot returns the full visible viewport as text (width/height and lines) based on the internal cell grid; when include_meta=true, returns cursor, url, title, dpi, scale, and basic scroll/nav state.
- Socket is removed on process exit; invalid requests produce standard JSON-RPC errors plus domain-specific errors.

6. Success Metrics
- Stability: No crashes/deadlocks during a 1-hour scripted interaction sequence.
- Performance: Text snapshot export for a 140x45 viewport < 10ms; end-to-end RPC p95 latency < 100ms.
- Usability: < 30 lines of script to demo "open HN → summarize top-2 comment threads" end-to-end.

7. Architecture Overview
- CLI flag: --agent-socket=/path/to.sock → enables Agent Mode (Headless-TTY).
- Runtime components:
  - JSON-RPC server (UnixListener + per-connection handlers), localhost-only.
  - Render thread (RenderThread) stays as-is; add snapshot export that reads the cell grid and synthesizes text (later ANSI/bitmap).
  - Input source in Agent Mode is the RPC queue (stdin listener disabled). Events are mapped to existing renderer/navigation/bridge flows.
  - Output suppression in Agent Mode: Painter does not write frames to stdout; set_title() does not emit OSC. State is cached for RPC.

8. Module-level Design and Changes
1) CLI / Mode Switch (src/cli/cli.rs)
- Add --agent-socket=<path>.
- Extend CommandLine with agent_socket: Option<String>.
- When present, set env CARBONYL_AGENT_HEADLESS=1.

2) TTY Management (src/input/tty.rs)
- In Agent Mode:
  - setup(): skip raw mode and ALT screen; do not enable mouse reporting.
  - teardown(): skip corresponding revert operations.
- Rationale: never take over the caller’s terminal; expose capabilities via RPC only.

3) Painter / Renderer (src/output/painter.rs, src/output/renderer.rs)
- Painter.end(): in Agent Mode, do not write to stdout (keep buffer lifecycle intact).
- Renderer.set_title(): in Agent Mode, suppress OSC writes and only update cached title.
- Renderer: add snapshot_text() (internal):
  - Iterate the cell grid. If a cell has grapheme with index==0, output grapheme.char and advance by its width; otherwise write a space.
  - Optionally trim trailing spaces per line.
- RenderThread: support executing a "read snapshot" closure on the render thread and returning results via a oneshot.

4) Input Source / Event Injection (src/browser/bridge.rs)
- Disable stdin listen() thread in Agent Mode. Replace with an internal channel fed by RPC handlers.
- Methods dispatch:
  - navigate(url): call delegate.go_to().
  - send_key(key, modifiers): call renderer.keypress(); forward to Chromium via delegate if needed.
  - scroll(delta): scale to pixels via window.scale and call delegate.scroll.

5) RPC Server (src/browser/bridge.rs)
- Thread hosting std::os::unix::net::UnixListener; parse JSON-RPC via serde_json.
- Concurrency: serialize access to Renderer by scheduling closures on the render thread; return results via oneshot.

6) Error Model & Limits
- JSON-RPC: standard errors (-32600, -32601, -32602, -32603).
- Domain-specific (-32000..-32099):
  - -32010 navigation-timeout
  - -32011 invalid-key
  - -32012 snapshot-unavailable
  - -32013 rate-limited
  - -32014 invalid-viewport
- Rate limiting/backpressure: coalesce frequent snapshot requests; optionally enforce per-connection minimum interval; return rate-limited when exceeded.

7) Security (UDS Path)
- Default path: $XDG_RUNTIME_DIR/carbonyl/agent.sock, or fallback /tmp/carbonyl-$UID/agent.sock.
- Ensure parent directory exists with 0700; set umask 0077; verify ownership and no symlinks before bind.

8) Platform Compatibility
- Unix (macOS/Linux) via Unix Sockets.
- Windows (later): Named Pipes with a parity JSON-RPC API.

9. JSON-RPC API
- Protocol: JSON-RPC 2.0 ("jsonrpc": "2.0"). Single connection, multiple requests. Batch optional later.
- All methods return either {"ok":true} or typed payloads; on error, include code/message/data.

MVP Endpoints
- navigate
  - Request:
    ```json path=null start=null
    {"id":1,"jsonrpc":"2.0","method":"navigate","params":{"url":"https://news.ycombinator.com/"}}
    ```
  - Response:
    ```json path=null start=null
    {"id":1,"jsonrpc":"2.0","result":{"ok":true}}
    ```

- send_key
  - Params: key enum ("Tab","Enter","Up","Down","Left","Right","Space","Char"). If key=="Char", provide a single-byte "char".
  - Request:
    ```json path=null start=null
    {"id":2,"jsonrpc":"2.0","method":"send_key","params":{"key":"Tab"}}
    ```
  - Response:
    ```json path=null start=null
    {"id":2,"jsonrpc":"2.0","result":{"ok":true}}
    ```

- scroll
  - Request:
    ```json path=null start=null
    {"id":3,"jsonrpc":"2.0","method":"scroll","params":{"delta":3}}
    ```
  - Response:
    ```json path=null start=null
    {"id":3,"jsonrpc":"2.0","result":{"ok":true}}
    ```

- snapshot (format: "text")
  - Params: {format:"text", include_meta?:true}
  - Request:
    ```json path=null start=null
    {"id":4,"jsonrpc":"2.0","method":"snapshot","params":{"format":"text","include_meta":true}}
    ```
  - Response (example):
    ```json path=null start=null
    {
      "id":4,
      "jsonrpc":"2.0",
      "result":{
        "width":140,
        "height":45,
        "lines":["Hacker News  new | past | ...","1. Uncomfortable Questions...","..."],
        "meta":{
          "cursor":{"x":11,"y":0},
          "url":"https://news.ycombinator.com/",
          "title":"Hacker News",
          "dpi":1.25,
          "scale":{"width":2.0,"height":4.0},
          "nav":{"can_go_back":false,"can_go_forward":false}
        }
      }
    }
    ```

- get_title
  - Request:
    ```json path=null start=null
    {"id":5,"jsonrpc":"2.0","method":"get_title"}
    ```
  - Response:
    ```json path=null start=null
    {"id":5,"jsonrpc":"2.0","result":{"title":"Hacker News"}}
    ```

- get_url
  - Request:
    ```json path=null start=null
    {"id":6,"jsonrpc":"2.0","method":"get_url"}
    ```
  - Response:
    ```json path=null start=null
    {"id":6,"jsonrpc":"2.0","result":{"url":"https://news.ycombinator.com/"}}
    ```

- get_nav_state
  - Request:
    ```json path=null start=null
    {"id":7,"jsonrpc":"2.0","method":"get_nav_state"}
    ```
  - Response:
    ```json path=null start=null
    {"id":7,"jsonrpc":"2.0","result":{"can_go_back":false,"can_go_forward":false}}
    ```

- set_viewport
  - Request:
    ```json path=null start=null
    {"id":8,"jsonrpc":"2.0","method":"set_viewport","params":{"cols":140,"rows":45}}
    ```
  - Response:
    ```json path=null start=null
    {"id":8,"jsonrpc":"2.0","result":{"ok":true}}
    ```

- get_capabilities
  - Request:
    ```json path=null start=null
    {"id":9,"jsonrpc":"2.0","method":"get_capabilities"}
    ```
  - Response:
    ```json path=null start=null
    {"id":9,"jsonrpc":"2.0","result":{"version":"0.0.3","features":["navigate","send_key","scroll","snapshot:text","get_title","get_url","get_nav_state","set_viewport"],"snapshot_formats":["text"],"platform":"unix","session_id":"..."}}
    ```

P1 Endpoints (post-MVP, explicitly marked)
- type_text {text}
- paste {text}
- wait_for_frame_quiescence {idle_ms}
- wait_for_title_contains {substring, timeout_ms}
- snapshot {format:"ansi"}
- click {row,col}, mouse_move/mouse_down/mouse_up
- ping
- subscribe_events (push-based observability)

9A. CLI Façade for Agents (MVP)
- Name: awi-tty (installed alongside Carbonyl; available in PATH)
- Purpose: Provide a simple shell command surface so agents do not need to craft JSON. The tool formats JSON-RPC requests and connects to the Unix socket.
- Socket selection:
  - Default from $AWI_SOCK, then $XDG_RUNTIME_DIR/carbonyl/agent.sock, then /tmp/carbonyl-$UID/agent.sock
  - Overridable via --socket PATH
- Output mode:
  - Default: print JSON responses to stdout
  - --plain: for snapshot --format text, print only the text lines (joined by \n)
  - --json: force JSON (default)
- Exit codes (sysexits-inspired):
  - 0 success; 64 usage; 65 data; 69 service-unavailable; 70 internal; 73 rate-limited; 74 io; 77 permission; others as needed
- Commands (MVP parity with RPC):
  - navigate <url> [--socket PATH]
  - send-key <Tab|Enter|Up|Down|Left|Right|Space|Char:<byte>> [--alt] [--meta] [--shift] [--ctrl] [--socket PATH]
  - scroll <delta:int> [--socket PATH]
  - snapshot [--format text|ansi] [--include-meta] [--trim] [--out FILE] [--plain|--json] [--socket PATH]
  - get-title [--socket PATH]
  - get-url [--socket PATH]
  - get-nav-state [--socket PATH]
  - set-viewport <cols:int> <rows:int> [--socket PATH]
  - get-capabilities [--socket PATH]
- P1 commands:
  - type-text <string>
  - paste <string>
  - wait-for-frame-quiescence <idle_ms>
  - wait-for-title-contains <substring> [--timeout-ms N]
  - snapshot --format ansi
  - click <row:int> <col:int>; mouse-move/mouse-down/mouse-up
  - ping; subscribe-events
- Examples:
  - awi-tty snapshot --format text --plain | sed -n '1,40p'
  - awi-tty navigate https://news.ycombinator.com/
  - awi-tty send-key Tab && awi-tty send-key Enter && awi-tty scroll 5 && awi-tty snapshot --format text --plain
- Implementation:
  - MVP as a small Rust binary (preferred) or POSIX shell script under scripts/ (falls back to socat). Rust avoids quoting pitfalls and provides robust JSON building.

9B. CLI Design Rationale
- Bridges the gap between low-level JSON-RPC and high-level agent operations, making AWI-TTY immediately usable for any shell-capable LLM agent.
- Sysexits-inspired exit codes (64=usage, 73=rate-limited, etc.) deliver semantic error handling that agents can reliably act upon.
- Snapshot --plain mode: allows agents to pipe raw text directly to classic Unix tools (grep, sed, awk) with no JSON parsing.
- ACI (Agent Computer Interface): awi-tty turns AWI-TTY from a developer API into an agent-ready interactive interface for terminal-rendered web pages.
  1) Zero JSON friction: Agents (Claude Code, WARP Agent, Gemini-CLI) call simple commands without constructing JSON.
  2) Unix philosophy: composable commands, pipelines, and meaningful exit codes.
  3) Progressive disclosure: simple agents use simple commands; advanced agents still have full JSON-RPC access.

9C. Implementation Strategy (suggested Rust structure)
- File: src/cli/awi_tty.rs (or a small standalone bin)
- Structure:
```rust
pub struct AwiTtyCommand {
  socket_path: std::path::PathBuf,
  output_mode: OutputMode,
}

enum OutputMode {
  Json,      // default: print JSON
  Plain,     // text only for snapshots (or scalar values)
  Quiet,     // success/failure only
}

impl AwiTtyCommand {
  fn find_socket() -> std::path::PathBuf {
      // 1) $AWI_SOCK
      // 2) $XDG_RUNTIME_DIR/carbonyl/agent.sock
      // 3) /tmp/carbonyl-$UID/agent.sock
  }

  fn execute(&self, subcommand: SubCommand) -> ExitCode {
      // Connect UDS → send JSON-RPC → format output → return semantic exit code
  }
}

#[repr(i32)]
pub enum ExitCode {
  Success = 0,
  Usage = 64,         // EX_USAGE
  DataErr = 65,       // EX_DATAERR
  Unavailable = 69,   // EX_UNAVAILABLE
  Software = 70,      // EX_SOFTWARE
  RateLimited = 73,   // custom
  IoErr = 74,         // EX_IOERR
  NoPerm = 77,        // EX_NOPERM
}
```

9D. Agent Usage Patterns
- Pattern 1: Navigation + Extraction
```bash
awi-tty navigate "https://news.ycombinator.com/"
content=$(awi-tty snapshot --plain | head -20)
# feed $content to an LLM or parse via grep/sed/awk
```
- Pattern 2: Interactive Navigation
```bash
awi-tty navigate "https://example.com/search"
awi-tty type-text "carbonyl browser"
awi-tty send-key Enter
awi-tty wait-for-frame-quiescence 500
results=$(awi-tty snapshot --plain)
```
- Pattern 3: State Verification
```bash
if awi-tty get-nav-state --json | jq -e '.can_go_back == true' >/dev/null; then
  awi-tty send-key Left  # or a dedicated go-back command (P1)
fi
```

9E. CLI Test Strategy
- Socket discovery:
```bash
unset AWI_SOCK; awi-tty ping
```
- Output modes:
```bash
diff <(awi-tty get-title --json | jq -r .title) <(awi-tty get-title --plain)
```
- Exit codes:
```bash
awi-tty navigate "invalid://url"; test $? -eq 65  # EX_DATAERR
```
- Piping:
```bash
awi-tty snapshot --plain | grep -q "Hacker News"
```

9F. Documentation Recommendations
- Add docs/AWI-TTY-AGENTS.md: Quick start for agent developers, common patterns, exit code reference with recovery strategies, integration examples (Claude Code, WARP, Gemini-CLI, OpenHands).

10. Lifecycle
- Start: parse CLI; if agent_socket present, create/bind UDS and set Headless-TTY env var.
- Run:
  - Render thread remains lazily started as today.
  - RPC thread accepts connections and dispatches to render-thread closures or to browser delegate calls.
- Exit:
  - RPC thread closes connections, unlinks the UDS.
  - Render thread stops cleanly (stop()).

11. Development Plan & Milestones (MVP)
- M1 (1–2 hours): CLI + Agent Mode scaffolding; Painter no-output; UDS server skeleton.
- M2 (2–3 hours): Wire up navigate/send_key/scroll; implement snapshot_text; cache title/url; set_viewport; ship awi-tty CLI façade with parity commands (navigate/send-key/scroll/snapshot/get-title/get-url/get-nav-state/set-viewport/get-capabilities).
- M3 (1–2 hours): Errors/permissions/cleanup; regression tests; docs and example scripts.

12. Test Plan
- Unit tests:
  - Snapshot export (cells → text): width handling, CJK/Emoji graphemes, trimming.
  - Key mapping and modifier combinations.
  - Viewport override via set_viewport.
- Integration tests:
  - Start Agent Mode → navigate HN → snapshot contains expected strings (e.g., "Hacker News").
  - send_key/scroll change the snapshot (detect diffs).
  - get_nav_state/get_title/get_url reflect state changes.
  - CLI façade: each command returns expected JSON; snapshot --plain emits text only; exit codes map to errors (rate-limited, invalid-viewport, etc.).
- End-to-end (E2E) sample:
  ```bash path=null start=null
  # start
  ./carbonyl-runtime/carbonyl --zoom=130 --agent-socket=/tmp/carbonyl.sock https://news.ycombinator.com/ &
  sleep 1
  # snapshot
  printf '{"id":1,"jsonrpc":"2.0","method":"snapshot","params":{"format":"text"}}\n' \
    | socat - UNIX-CONNECT:/tmp/carbonyl.sock > /tmp/snap1.json
  # send Tab, Enter, scroll
  printf '{"id":2,"jsonrpc":"2.0","method":"send_key","params":{"key":"Tab"}}\n' \
    | socat - UNIX-CONNECT:/tmp/carbonyl.sock >/dev/null
  printf '{"id":3,"jsonrpc":"2.0","method":"send_key","params":{"key":"Enter"}}\n' \
    | socat - UNIX-CONNECT:/tmp/carbonyl.sock >/dev/null
  printf '{"id":4,"jsonrpc":"2.0","method":"scroll","params":{"delta":5}}\n' \
    | socat - UNIX-CONNECT:/tmp/carbonyl.sock >/dev/null
  # snapshot again
  printf '{"id":5,"jsonrpc":"2.0","method":"snapshot","params":{"format":"text","include_meta":true}}\n' \
    | socat - UNIX-CONNECT:/tmp/carbonyl.sock > /tmp/snap2.json
  ```

13. Operations & Observability
- Logs: with --debug, log RPC server events (connections, request ids, durations, errors), and bound socket path.
- Backpressure: document throttling policy and error; optionally expose metrics via get_capabilities.data.
- Resource metrics (optional): time spent exporting snapshots and per-frame render times.

14. Compatibility & Rollback
- Default behavior unchanged when --agent-socket is not provided.
- Rollback: simply stop using the flag; code paths are isolated by param/env.

15. Risks & Mitigations
- Risk: concurrent connections race on renderer state.
  - Mitigation: render thread is the single writer; RPC handlers only enqueue closures and await results.
- Risk: snapshot text differs from a real terminal (colors/combining specifics).
  - Mitigation: MVP focuses on text; add ANSI/bitmap snapshots later for higher fidelity.
- Risk: complex input scenarios (IME, clipboard) are not covered.
  - Mitigation: extend API later (paste, type_text, composition events).
- Risk: UDS path tampering under /tmp.
  - Mitigation: secure defaults, ownership and permission checks, no symlinks.

16. Future Work (Roadmap)
- Snapshot formats: ansi (color + cursor), png (compose from quadrant colors for visual diff reports).
- Mouse actions: click(x,y)/drag(from,to) with coordinate mapping via window.scale.
- Web gateway: wrap UDS with local HTTP/WebSocket + auth for browser-side or remote agents.
- Multi-session: multiple concurrent sessions with distinct socket paths and session ids.
- Windows: Named Pipe support under a unified RPC abstraction.

17. Open Questions
- How to abstract international input and IME composition events over RPC?
- Should snapshots support incremental/diff mode to reduce payload size and latency?
- Do we need server-side rate limiting/timeouts to protect against abusive clients?

18. Appendix: CLI and Client Examples
- Start (MVP):
  ```bash path=null start=null
  ./carbonyl-runtime/carbonyl --zoom=130 --agent-socket=/tmp/carbonyl.sock https://news.ycombinator.com/
  ```
- CLI façade examples:
  ```bash path=null start=null
  export AWI_SOCK=/tmp/carbonyl.sock
  awi-tty snapshot --format text --plain | sed -n '1,40p'
  awi-tty navigate https://news.ycombinator.com/
  awi-tty send-key Tab && awi-tty send-key Enter
  awi-tty scroll 5
  awi-tty get-title
  ```
- Send a request (socat):
  ```bash path=null start=null
  printf '{"id":1,"jsonrpc":"2.0","method":"snapshot","params":{"format":"text"}}\n' | \
    socat - UNIX-CONNECT:/tmp/carbonyl.sock
  ```
- Minimal Node.js UDS client:
  ```js path=null start=null
  import net from 'node:net';
  const sock = '/tmp/carbonyl.sock';
  const req = JSON.stringify({id:1,jsonrpc:'2.0',method:'snapshot',params:{format:'text'}})+'\n';
  const client = net.createConnection(sock, () => client.write(req));
  client.on('data', d => { console.log(d.toString()); client.end(); });
  ```
- Minimal Python UDS client:
  ```python path=null start=null
  import socket, json
  s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
  s.connect('/tmp/carbonyl.sock')
  s.sendall((json.dumps({"id":1,"jsonrpc":"2.0","method":"snapshot","params":{"format":"text"}})+"\n").encode())
  print(s.recv(65536).decode())
  s.close()
  ```

— End —

