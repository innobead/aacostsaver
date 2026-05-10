# GEMINI.md — Project Instructions
# Gemini CLI reads this file for project-scoped instructions.

## CLI Proxy: RTK

RTK (Rust Token Killer) is a token-optimized CLI proxy on this machine.
Hooks auto-rewrite commands through RTK. Use `rtk <cmd>` explicitly if needed.

```
rtk git   rtk grep  rtk ls    rtk find  rtk read
rtk curl  rtk go    rtk cargo rtk npm   rtk docker
```

## Response Style

- Concise. Skip filler phrases and verbose explanations.
- Show diffs/changed sections, not full files.
- Errors: cause + fix in ≤3 lines.

## Caveman Mode

Say "caveman mode" → ultra-compressed responses (~75% fewer output tokens).
Say "stop caveman" to return to normal.
