#!/usr/bin/env bash
# apply-agents-md.sh — Install AGENTS.md to global agent instruction locations
# Targets:
#   ~/.agents/AGENTS.md     — Zed, universal agents, Copilot CLI agent discovery
#   ~/.codex/AGENTS.md      — OpenAI Codex CLI global instructions
#   $PWD/AGENTS.md          — Project-local (with --project flag)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/AGENTS.md"
PROJECT_MODE=false
DRY_RUN="${DRY_RUN:-0}"

for arg in "$@"; do
  case $arg in
    --project) PROJECT_MODE=true ;;
    --dry-run) DRY_RUN=1 ;;
  esac
done

ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
warn() { printf '  \033[33m⚠️  %s\033[0m\n' "$*"; }
info() { printf '  \033[36mℹ  %s\033[0m\n' "$*"; }
dry()  { printf '  \033[90m[dry-run] %s\033[0m\n' "$*"; }

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template not found: $TEMPLATE"
  exit 1
fi

install_agents_md() {
  local dest="$1"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  if [[ "$DRY_RUN" == "1" ]]; then
    dry "Would write AGENTS.md → $dest"
    return
  fi

  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    # Backup existing if it's not already ours
    if ! grep -q "RTK - Rust Token Killer" "$dest" 2>/dev/null; then
      local backup="${dest%.md}.original.md"
      cp "$dest" "$backup"
      info "Backed up existing: $backup"
    fi
  fi

  cp "$TEMPLATE" "$dest"
  ok "Installed: $dest"
}

if $PROJECT_MODE; then
  echo "Installing project-local AGENTS.md to: $PWD/AGENTS.md"
  if [[ -f "$PWD/AGENTS.md" ]] && grep -q "RTK - Rust Token Killer" "$PWD/AGENTS.md" 2>/dev/null; then
    ok "Already installed (up to date)"
  else
    install_agents_md "$PWD/AGENTS.md"
  fi
  exit 0
fi

# Global installs
echo "Installing AGENTS.md to global locations..."

# 1. ~/.agents/AGENTS.md — Zed + universal
install_agents_md "$HOME/.agents/AGENTS.md"

# 2. ~/.codex/AGENTS.md — OpenAI Codex CLI
install_agents_md "$HOME/.codex/AGENTS.md"

echo ""
info "AGENTS.md installed. Agents reading these locations will pick up RTK + caveman instructions."
info "For project-local: run with --project flag in the repo root"
info "  bash $0 --project"
