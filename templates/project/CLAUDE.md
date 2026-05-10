# CLAUDE.md — Project Instructions
# Claude Code reads this at project scope (alongside ~/.claude/CLAUDE.md).

## CLI Proxy: RTK

RTK is installed. Hooks auto-rewrite commands. Use `rtk <cmd>` explicitly if hooks aren't active.

```bash
rtk git status       # instead of: git status
rtk grep -r foo .    # instead of: grep -r foo .
rtk go test ./...    # instead of: go test ./...
```

Meta: `rtk gain` (savings), `rtk discover` (missed ops), `rtk proxy <cmd>` (debug).

## Response Style

- Concise. No verbose preamble or filler.
- Compact formats: bullets over prose, diffs over full files.
- Errors: root cause + fix, ≤3 lines.
- Say "caveman mode" for ultra-compressed output (~75% token reduction).
