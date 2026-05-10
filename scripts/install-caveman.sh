#!/usr/bin/env bash
# install-caveman.sh — Install caveman for Claude Code and Copilot CLI
# Source: https://github.com/JuliusBrussee/caveman
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"

dry_run() { [[ "$DRY_RUN" == "1" ]]; }
ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
info() { printf '  \033[36mℹ  %s\033[0m\n' "$*"; }
dry()  { printf '  \033[90m[dry-run] %s\033[0m\n' "$*"; }

SKILLS_SRC="$SCRIPT_DIR/../skills"

install_skill() {
  local skill_name="$1"
  local dest_dir="$2"
  local src="$SKILLS_SRC/$skill_name/SKILL.md"

  if [[ ! -f "$src" ]]; then
    echo "  ⚠️  Skill source not found: $src"
    return
  fi

  if dry_run; then
    dry "Would install $skill_name SKILL.md → $dest_dir/$skill_name/SKILL.md"
  else
    mkdir -p "$dest_dir/$skill_name"
    cp "$src" "$dest_dir/$skill_name/SKILL.md"
    ok "$skill_name → $dest_dir/$skill_name/"
  fi
}

# ── 1. Copilot CLI personal skills (~/.copilot/skills/) ────────────────────
COPILOT_SKILLS="$HOME/.copilot/skills"
if [[ -d "$HOME/.copilot" ]]; then
  echo ""
  echo "Installing skills to Copilot CLI: $COPILOT_SKILLS"
  dry_run || mkdir -p "$COPILOT_SKILLS"
  install_skill "caveman"              "$COPILOT_SKILLS"
  install_skill "token-cost-optimizer" "$COPILOT_SKILLS"
  install_skill "compress"             "$COPILOT_SKILLS"
else
  info "~/.copilot not found — skipping Copilot CLI skills"
fi

# ── 2. ~/.agents/skills/ (universal agent skills dir) ─────────────────────
AGENTS_SKILLS="$HOME/.agents/skills"
echo ""
echo "Installing skills to ~/.agents/skills/"
if dry_run; then
  dry "Would install skills to $AGENTS_SKILLS"
else
  mkdir -p "$AGENTS_SKILLS"
  install_skill "caveman"              "$AGENTS_SKILLS"
  install_skill "token-cost-optimizer" "$AGENTS_SKILLS"
  install_skill "compress"             "$AGENTS_SKILLS"
fi

# ── 3. Claude Code: run caveman's official installer ──────────────────────
echo ""
echo "Installing caveman for Claude Code (official installer)..."
if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
  if dry_run; then
    dry "Would run: curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash -s -- --only claude --minimal"
  else
    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash -s -- --only claude --minimal
    ok "Caveman installed for Claude Code"
  fi
else
  info "Claude Code not detected — skipping"
fi

echo ""
echo "Skills installed. Restart Copilot CLI to pick them up."
echo "Usage:"
echo "  Say 'caveman mode' or 'less tokens' → activates caveman ultra-compression"
echo "  Say 'optimize tokens' → activates token-cost-optimizer"
echo "  Say '/compress ~/.claude/CLAUDE.md' → compresses memory file"
