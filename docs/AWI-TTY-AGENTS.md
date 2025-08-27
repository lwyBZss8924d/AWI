# AWI-TTY for Agents: Quick Start and Patterns

This guide helps agent developers use the AWI-TTY CLI façade (awi-tty) to control Carbonyl without writing JSON.

1. Quick Start
- Start Carbonyl in Agent Mode (example):
```bash
./carbonyl-runtime/carbonyl --agent-socket=/tmp/carbonyl.sock https://news.ycombinator.com/
```
- Point awi-tty to the socket (optional if default path works):
```bash
export AWI_SOCK=/tmp/carbonyl.sock
```
- Take a snapshot (text):
```bash
awi-tty snapshot --format text --plain | sed -n '1,40p'
```

2. Common Commands (MVP)
- Navigate:
```bash
awi-tty navigate "https://news.ycombinator.com/"
```
- Send keys:
```bash
awi-tty send-key Tab
awi-tty send-key Enter
```
- Scroll:
```bash
awi-tty scroll 5
```
- Get title / URL / navigation state:
```bash
awi-tty get-title
awi-tty get-url
awi-tty get-nav-state --json | jq .
```
- Set viewport:
```bash
awi-tty set-viewport 140 45
```

3. Usage Patterns
- Pattern 1: Navigation + Extraction
```bash
awi-tty navigate "https://news.ycombinator.com/"
content=$(awi-tty snapshot --plain | head -20)
# process $content with your LLM or shell tools
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
  awi-tty send-key Left
fi
```

4. Exit Codes (sysexits-inspired)
- 0 Success
- 64 Usage (invalid flags/arguments)
- 65 Data error (invalid URL, malformed input)
- 69 Service unavailable (socket/connectivity)
- 70 Software error (internal)
- 73 Rate-limited (throttling)
- 74 IO error
- 77 No permission (permissions or ownership issues)

5. Socket Discovery
- $AWI_SOCK
- $XDG_RUNTIME_DIR/carbonyl/agent.sock
- /tmp/carbonyl-$UID/agent.sock

6. Tips
- Prefer --plain for snapshot text if you intend to pipe to grep/sed/awk.
- Use --json when parsing through jq.
- In CI, validate the presence of expected text via:
```bash
awi-tty snapshot --plain | grep -q "Hacker News"
```

7. Troubleshooting
- Socket not found: ensure Carbonyl is running with --agent-socket and that your user owns the socket path.
- Permission denied: verify parent directory perms (0700) and umask (0077) are applied.
- Rate-limited: slow down snapshot frequency, or insert waits between calls.

