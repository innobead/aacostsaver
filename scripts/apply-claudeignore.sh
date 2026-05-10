#!/usr/bin/env bash
# apply-claudeignore.sh — Copy .claudeignore template to current project root
# .claudeignore is PER-PROJECT only (no global support in Claude Code).
# Claude Code also respects .gitignore by default when .claudeignore is absent.
# Run this from inside a project repo root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/.claudeignore"
DEST="$PWD/.claudeignore"

ok()   { printf '\033[32m✅ %s\033[0m\n' "$*"; }
info() { printf '\033[36mℹ  %s\033[0m\n' "$*"; }
warn() { printf '\033[33m⚠️  %s\033[0m\n' "$*"; }

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template not found: $TEMPLATE"
  exit 1
fi

if [[ -f "$DEST" ]]; then
  warn ".claudeignore already exists at $DEST"
  info "Review and merge manually if needed: $TEMPLATE"
  exit 0
fi

cp "$TEMPLATE" "$DEST"
ok "Installed: $DEST"
info "Claude Code will now exclude matched files from its context in this project."
info "Tip: commit .claudeignore alongside .gitignore so teammates benefit."
