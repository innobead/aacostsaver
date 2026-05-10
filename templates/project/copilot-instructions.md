# Copilot Instructions
# GitHub Copilot custom instructions for this project.
# Read by: GitHub Copilot (VS Code, JetBrains, PR reviews via .github/copilot-instructions.md)

## CLI Proxy: RTK

RTK (Rust Token Killer) is a token-optimized CLI proxy on this machine.
Use `rtk <cmd>` instead of raw commands when possible. Hooks auto-rewrite common commands.

```
rtk git   rtk grep  rtk ls    rtk find  rtk read
rtk curl  rtk go    rtk cargo rtk npm   rtk docker
```

## Response Style

- Be concise. No filler, no hedging, no repeated questions.
- Show only changed code sections, not full files.
- Errors: cause + fix in ≤3 lines.

## Caveman Mode

Say "caveman mode" → ultra-compressed responses (~75% fewer tokens). "stop caveman" → normal.
