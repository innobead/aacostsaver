# AGENTS.md — Global AI Agent Instructions
# Applies to: OpenAI Codex, Zed, and any agent reading AGENTS.md
# Mirrors: ~/.claude/CLAUDE.md + ~/.claude/RTK.md

## CLI Proxy: RTK (Rust Token Killer)

RTK is a token-optimized CLI proxy installed on this machine (60-90% savings on dev operations).
All standard CLI commands are automatically rewritten through RTK via hooks.

**Meta commands (call directly):**
```bash
rtk gain              # Token savings analytics
rtk gain --history    # Command usage history with savings
rtk discover          # Find missed RTK opportunities
rtk proxy <cmd>       # Raw command without filtering (debug only)
```

**Supported commands (use `rtk <cmd>` explicitly if hooks not active):**
```
rtk git       rtk grep      rtk ls        rtk find
rtk read      rtk curl      rtk docker    rtk kubectl
rtk go        rtk cargo     rtk npm       rtk pnpm
rtk tsc       rtk pytest    rtk gh        rtk diff
```

Hook rewrites automatically: `git status` → `rtk git status` (transparent, 0 overhead)

⚠️ Name collision: if `rtk gain` fails, you may have reachingforthejack/rtk installed instead.

## Response Style

- Concise. No filler phrases, hedging, or repeated questions.
- Use compact formats: short bullets, no verbose preamble.
- For code changes: show only the changed section, not full files.
- For errors: cause + fix in ≤3 lines.

## Caveman Mode

Say "caveman mode" or "less tokens" to activate ultra-compressed responses (~75% fewer output tokens).
Technical accuracy preserved. Code blocks unchanged.

Levels: `lite` | `full` (default) | `ultra`
Deactivate: "stop caveman" or "normal mode"

## Skills Available

- **caveman** — ultra-compact responses (`~/.copilot/skills/caveman/`, `~/.agents/skills/caveman/`)
- **token-cost-optimizer** — pre-task cost planning (`~/.copilot/skills/token-cost-optimizer/`)
- **compress** — compress memory files to save input tokens (`~/.copilot/skills/compress/`)
