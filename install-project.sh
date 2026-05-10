#!/usr/bin/env bash
# install-project.sh — Drop per-project agent instruction files into current repo
# Run from the project root directory.
#
# Usage:
#   ./install-project.sh                    # interactive agent selection
#   ./install-project.sh --agents all       # install all agents
#   ./install-project.sh --agents claude,copilot
#   ./install-project.sh --dry-run
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPL="$SCRIPT_DIR/templates"
TMPL_P="$TMPL/project"

DRY_RUN=false
AGENTS_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)       DRY_RUN=true ;;
    --agents=*)      AGENTS_ARG="${1#--agents=}" ;;
    --agents)        shift; AGENTS_ARG="${1:-}" ;;
  esac
  shift
done

# ── Colours ────────────────────────────────────────────────────────────────
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
skip() { printf '  \033[33m⏭  %s\033[0m\n' "$*"; }
info() { printf '  \033[36mℹ  %s\033[0m\n' "$*"; }
dry()  { printf '  \033[90m[dry-run] %s\033[0m\n' "$*"; }

# ── Guard: must run from inside a directory ────────────────────────────────
PROJECT_ROOT="$PWD"
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "ERROR: Cannot determine project root."
  exit 1
fi
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null 2>&1; then
  info "Not a git repo — files will still be written to $PROJECT_ROOT"
fi

# ── Agent selection ────────────────────────────────────────────────────────
ALL_AGENTS=("claude" "copilot" "gemini" "universal")

resolve_agents() {
  local input="$1"
  if [[ "$input" == "all" ]]; then
    echo "${ALL_AGENTS[@]}"
    return
  fi
  # Comma-separated
  echo "$input" | tr ',' ' '
}

if [[ -z "$AGENTS_ARG" ]]; then
  echo ""
  bold "Which agents do you want to configure for this project?"
  echo "  Options: claude, copilot, gemini, universal, all"
  echo ""
  printf "  Agents [all]: "
  read -r AGENTS_ARG
  AGENTS_ARG="${AGENTS_ARG:-all}"
fi

SELECTED_AGENTS=$(resolve_agents "$AGENTS_ARG")

has_agent() { echo "$SELECTED_AGENTS" | grep -qw "$1"; }

# ── Install helper ─────────────────────────────────────────────────────────
install_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ ! -f "$src" ]]; then
    skip "$label — template not found: $src"
    return
  fi

  local dest_dir
  dest_dir="$(dirname "$dest")"

  if $DRY_RUN; then
    dry "Would write $label → ${dest#$PROJECT_ROOT/}"
    return
  fi

  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    if diff -q "$src" "$dest" &>/dev/null; then
      ok "$label — already up to date"
      return
    fi
    cp "$dest" "${dest}.bak"
    info "Backed up existing → ${dest#$PROJECT_ROOT/}.bak"
  fi

  cp "$src" "$dest"
  ok "$label → ${dest#$PROJECT_ROOT/}"
}

# ── Main ───────────────────────────────────────────────────────────────────
echo ""
bold "aacostsaver — Project Install"
echo "================================"
echo "  Project: $PROJECT_ROOT"
echo "  Agents:  $SELECTED_AGENTS"
$DRY_RUN && info "DRY RUN — no files will be written"
echo ""

# 1. Universal — AGENTS.md
if has_agent "universal" || has_agent "all"; then
  bold "Universal — AGENTS.md"
  install_file "$TMPL/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" "AGENTS.md"
  echo ""
fi

# 2. Claude Code — CLAUDE.md + .claudeignore
if has_agent "claude" || has_agent "all"; then
  bold "Claude Code"
  install_file "$TMPL_P/CLAUDE.md"    "$PROJECT_ROOT/CLAUDE.md"    "CLAUDE.md"
  install_file "$TMPL/.claudeignore"  "$PROJECT_ROOT/.claudeignore" ".claudeignore"
  echo ""
fi

# 3. GitHub Copilot — .github/copilot-instructions.md
if has_agent "copilot" || has_agent "all"; then
  bold "GitHub Copilot"
  install_file "$TMPL_P/copilot-instructions.md" \
    "$PROJECT_ROOT/.github/copilot-instructions.md" \
    ".github/copilot-instructions.md"
  echo ""
fi

# 4. Gemini CLI — GEMINI.md
if has_agent "gemini" || has_agent "all"; then
  bold "Gemini CLI"
  install_file "$TMPL_P/GEMINI.md" "$PROJECT_ROOT/GEMINI.md" "GEMINI.md"
  echo ""
fi

# ── Summary ────────────────────────────────────────────────────────────────
bold "Done."
echo ""
if ! $DRY_RUN; then
  echo "  Files written to: $PROJECT_ROOT"
  echo "  Tip: commit AGENTS.md, CLAUDE.md, GEMINI.md, and .github/copilot-instructions.md"
  echo "       so teammates benefit. Keep .claudeignore project-local or commit it too."
fi
