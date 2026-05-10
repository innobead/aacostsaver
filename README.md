# aacostsaver

Token cost reduction toolkit for Claude Code, GitHub Copilot, and Gemini CLI.
Wires RTK CLI proxy, agent hooks, skills, MCP servers, and per-project instruction files.

---

## Quick Start

```bash
# 1. Machine-level setup (run once per machine)
./install.sh

# 2. Per-project setup (run in each repo root)
./install-project.sh
```

Both support `--dry-run` to preview changes before applying.

Both scripts are **idempotent** — safe to re-run at any time. Each step checks whether it's already applied and skips if so. Re-running will install only what's missing.

---

## What Each Installs

### `install.sh` — machine-level (global)

| Step | What | Effect |
|---|---|---|
| 1 | Claude Code **PreToolUse hook** | Auto-rewrites all bash calls through RTK |
| 2 | Copilot CLI **preToolUse hook** | Same for Copilot CLI agent |
| 3 | **PostToolUse filter** | Compresses tool outputs >2KB via `rtk pipe` |
| 4 | **MCP servers** (context7 + memory) | On-demand docs; cross-session memory |
| 5 | RTK **ultra-compact** in hooks | 5–10% extra savings on all RTK outputs |
| 6 | `.claudeignore` template | Stored for project use (per-project only) |
| 7 | **CLAUDE.md** response style | Enforces concise replies |
| 8 | **TOML filters** (brew, nix, kubectl) | Appended to `~/Library/Application Support/rtk/filters.toml` |
| 9 | **AGENTS.md** → `~/.agents/` + `~/.codex/` | Global instructions for Zed, Codex |
| 10 | **Skills** → `~/.copilot/skills/` + `~/.agents/skills/` | caveman, token-cost-optimizer, compress |
| 11 | **Compress memory files** (optional) | ~60% input token reduction on system prompt |

> **Note on Copilot:** GitHub Copilot has no global instructions file. Global Copilot behavior is handled by hooks (step 2) and skills (step 10). Project-level `.github/copilot-instructions.md` is written by `install-project.sh --agents copilot`.

### `install-project.sh` — per-repo

| Agent | File written |
|---|---|
| Universal | `AGENTS.md` |
| Claude Code | `CLAUDE.md`, `.claudeignore` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Gemini CLI | `GEMINI.md` |

Select agents interactively or via flag:

```bash
./install-project.sh --agents all
./install-project.sh --agents claude,copilot
./install-project.sh --agents gemini
```

---

## Skills

Three skills are installed to `~/.copilot/skills/` and `~/.agents/skills/`:

| Skill | Trigger | Effect |
|---|---|---|
| **caveman** | "caveman mode" / "less tokens" | ~75% output token reduction |
| **token-cost-optimizer** | "optimize tokens" | Pre-task cost planning |
| **compress** | "/compress \<file\>" | Compress .md memory files (saves input tokens) |

---

## Prerequisites

- [RTK](https://github.com/innobead/rtk) installed and on `$PATH`
- Claude Code and/or Copilot CLI installed
- `npx` available (for MCP servers)

---

## Structure

```
install.sh              Machine-level setup
install-project.sh      Per-project agent instruction files

configs/
  mcp.json              MCP server definitions (context7, memory)
  post-tool-hook.sh     PostToolUse output filter
  rtk-config.toml       RTK hooks ultra-compact config

filters/
  brew.toml             RTK TOML filter for brew
  nix.toml              RTK TOML filter for nix
  kubectl.toml          RTK TOML filter for kubectl

scripts/
  apply-claude-hook.sh      Wire rtk hook claude → PreToolUse
  apply-copilot-hook.sh     Wire rtk hook copilot → preToolUse
  apply-agents-md.sh        Install AGENTS.md globally (~/.agents/, ~/.codex/)
  apply-claudeignore.sh     Copy .claudeignore to current project
  install-mcp.sh            Install MCP servers
  install-caveman.sh        Install caveman + cost skills
  compress-memory.sh        Compress CLAUDE.md / RTK.md

skills/
  caveman/SKILL.md
  token-cost-optimizer/SKILL.md
  compress/SKILL.md

templates/
  AGENTS.md               Global agent instructions template
  CLAUDE.md               Global CLAUDE.md additions
  .claudeignore           Project-level file exclusions
  project/
    CLAUDE.md             Project-scoped Claude instructions
    copilot-instructions.md
    GEMINI.md
```
