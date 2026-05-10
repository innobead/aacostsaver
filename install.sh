#!/usr/bin/env bash
# install.sh — aacostsaver: apply all token cost reduction optimizations
# Usage: ./install.sh [--dry-run] [--skip-mcp] [--skip-hooks] [--skip-filters]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
SKIP_MCP=false
SKIP_HOOKS=false
SKIP_FILTERS=false

for arg in "$@"; do
  case $arg in
    --dry-run)    DRY_RUN=true ;;
    --skip-mcp)   SKIP_MCP=true ;;
    --skip-hooks) SKIP_HOOKS=true ;;
    --skip-filters) SKIP_FILTERS=true ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
skip() { printf '  \033[33m⏭  %s\033[0m\n' "$*"; }
info() { printf '  \033[36mℹ  %s\033[0m\n' "$*"; }
dry()  { printf '  \033[90m[dry-run] %s\033[0m\n' "$*"; }

run() {
  if $DRY_RUN; then
    dry "$*"
  else
    "$@"
  fi
}

echo ""
bold "aacostsaver — Token Cost Reduction Installer"
echo "=============================================="
$DRY_RUN && info "DRY RUN mode — no changes will be made"
echo ""

###############################################################################
# 1. Claude Code PreToolUse hook
###############################################################################
bold "1. Claude Code PreToolUse hook (rtk hook claude)"
if $SKIP_HOOKS; then
  skip "Skipped (--skip-hooks)"
else
  CLAUDE_SETTINGS="$HOME/.claude/settings.json"
  if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    skip "~/.claude/settings.json not found — is Claude Code installed?"
  else
    ALREADY=$(python3 -c "
import json, sys
d = json.load(open('$CLAUDE_SETTINGS'))
hooks = d.get('hooks', {}).get('PreToolUse', [])
found = any('rtk hook claude' in str(h) for h in hooks)
print('yes' if found else 'no')
" 2>/dev/null || echo "no")
    if [[ "$ALREADY" == "yes" ]]; then
      ok "Already configured"
    else
      run bash "$SCRIPT_DIR/scripts/apply-claude-hook.sh"
      ok "Configured"
    fi
  fi
fi
echo ""

###############################################################################
# 2. Copilot CLI preToolUse hook
###############################################################################
bold "2. Copilot CLI preToolUse hook (rtk hook copilot)"
if $SKIP_HOOKS; then
  skip "Skipped (--skip-hooks)"
else
  COPILOT_SETTINGS="$HOME/.copilot/settings.json"
  if [[ ! -f "$COPILOT_SETTINGS" ]]; then
    skip "~/.copilot/settings.json not found — is Copilot CLI installed?"
  else
    ALREADY=$(python3 -c "
import json, sys
try:
    d = json.load(open('$COPILOT_SETTINGS'))
except: d = {}
hooks = d.get('hooks', {}).get('preToolUse', [])
found = any('rtk hook copilot' in str(h) for h in hooks)
print('yes' if found else 'no')
" 2>/dev/null || echo "no")
    if [[ "$ALREADY" == "yes" ]]; then
      ok "Already configured"
    else
      run bash "$SCRIPT_DIR/scripts/apply-copilot-hook.sh"
      ok "Configured"
    fi
  fi
fi
echo ""

###############################################################################
# 3. PostToolUse hook (output compression)
###############################################################################
bold "3. PostToolUse output filter hook"
if $SKIP_HOOKS; then
  skip "Skipped (--skip-hooks)"
else
  CLAUDE_SETTINGS="$HOME/.claude/settings.json"
  if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    skip "~/.claude/settings.json not found"
  else
    HOOK_SCRIPT="$SCRIPT_DIR/configs/post-tool-hook.sh"
    chmod +x "$HOOK_SCRIPT" 2>/dev/null || true
    ALREADY=$(python3 -c "
import json, sys
d = json.load(open('$CLAUDE_SETTINGS'))
hooks = d.get('hooks', {}).get('PostToolUse', [])
found = any('post-tool-hook' in str(h) for h in hooks)
print('yes' if found else 'no')
" 2>/dev/null || echo "no")
    if [[ "$ALREADY" == "yes" ]]; then
      ok "Already configured"
    else
      if $DRY_RUN; then
        dry "Would add PostToolUse hook: $HOOK_SCRIPT"
      else
        python3 - <<PYEOF
import json, os
settings_path = os.path.expanduser("~/.claude/settings.json")
with open(settings_path) as f:
    d = json.load(f)
if "hooks" not in d:
    d["hooks"] = {}
if "PostToolUse" not in d["hooks"]:
    d["hooks"]["PostToolUse"] = []
hook_entry = {
    "matcher": "Bash",
    "hooks": [{"type": "command", "command": "$HOOK_SCRIPT"}]
}
d["hooks"]["PostToolUse"].append(hook_entry)
with open(settings_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
print("Done")
PYEOF
        ok "Configured"
      fi
    fi
  fi
fi
echo ""

###############################################################################
# 4. MCP servers (context7 + memory)
###############################################################################
bold "4. MCP servers (context7, memory)"
if $SKIP_MCP; then
  skip "Skipped (--skip-mcp)"
else
  MCP_CONFIG="$HOME/.claude/mcp.json"
  if [[ -f "$MCP_CONFIG" ]]; then
    ok "Already exists — review $MCP_CONFIG if changes needed"
    info "Tip: run 'rtk discover' after restart to verify"
  else
    run bash "$SCRIPT_DIR/scripts/install-mcp.sh"
    ok "MCP config installed"
  fi
fi
echo ""

###############################################################################
# 5. RTK ultra-compact in hooks
###############################################################################
bold "5. RTK ultra-compact mode in hooks"
RTK_CONFIG_PATH="$HOME/Library/Application Support/rtk/config.toml"
if [[ ! -f "$RTK_CONFIG_PATH" ]]; then
  RTK_CONFIG_PATH="$HOME/.config/rtk/config.toml"
fi
if [[ -f "$RTK_CONFIG_PATH" ]]; then
  if grep -q "ultra_compact" "$RTK_CONFIG_PATH" 2>/dev/null; then
    ok "Already set in RTK config"
  else
    if $DRY_RUN; then
      dry "Would add ultra_compact=true to [hooks] in $RTK_CONFIG_PATH"
    else
      python3 - <<PYEOF
import re
path = "$RTK_CONFIG_PATH"
with open(path) as f:
    content = f.read()
if '[hooks]' in content:
    # Insert ultra_compact after the [hooks] line
    content = re.sub(r'(\[hooks\]\n)', r'\1ultra_compact = true\n', content, count=1)
else:
    content += '\n[hooks]\nultra_compact = true\n'
with open(path, 'w') as f:
    f.write(content)
print('Done')
PYEOF
      ok "ultra_compact = true added to hooks section"
    fi
  fi
else
  skip "RTK config not found at expected path — run: rtk config"
fi
echo ""

###############################################################################
# 6. .claudeignore template (per-project only — no global support)
###############################################################################
bold "6. .claudeignore template"
# NOTE: .claudeignore is per-project only (project root, alongside .gitignore).
# There is no global .claudeignore — Claude Code also respects .gitignore by default.
# We store the template here for use with: bash scripts/apply-claudeignore.sh
info ".claudeignore is per-project only (no global support in Claude Code)"
info "Template stored at: $SCRIPT_DIR/templates/.claudeignore"
info "To apply to a project: cp $SCRIPT_DIR/templates/.claudeignore /path/to/project/"
info "Or run: bash $SCRIPT_DIR/scripts/apply-claudeignore.sh  (in project root)"
echo ""

###############################################################################
# 7. CLAUDE.md response style instructions
###############################################################################
bold "7. CLAUDE.md response style optimization"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if grep -q "Response Style" "$CLAUDE_MD" 2>/dev/null; then
  ok "Response Style section already present"
else
  if $DRY_RUN; then
    dry "Would append response style instructions to $CLAUDE_MD"
  else
    cat >> "$CLAUDE_MD" <<'MDEOF'

## Response Style

- Be concise. Skip verbose explanations unless explicitly asked.
- Use compact formats: short bullet points, no filler phrases.
- For code changes: show only the diff/changed section, not full files.
- For errors: state the cause + fix in ≤3 lines.
- Never repeat the question back before answering.
MDEOF
    ok "Response Style instructions appended to $CLAUDE_MD"
  fi
fi
echo ""

###############################################################################
# 8. TOML filters
###############################################################################
bold "8. Custom TOML filters (brew, nix, kubectl)"
if $SKIP_FILTERS; then
  skip "Skipped (--skip-filters)"
else
  # RTK uses a single global filters.toml file
  if [[ -f "$HOME/Library/Application Support/rtk/filters.toml" ]]; then
    RTK_FILTERS="$HOME/Library/Application Support/rtk/filters.toml"
  elif [[ -f "$HOME/.config/rtk/filters.toml" ]]; then
    RTK_FILTERS="$HOME/.config/rtk/filters.toml"
  else
    RTK_FILTERS=""
  fi

  if [[ -z "$RTK_FILTERS" ]]; then
    skip "RTK filters.toml not found — run: rtk config  to initialize"
  else
    for f in "$SCRIPT_DIR/filters"/*.toml; do
      name=$(basename "$f" .toml)
      if grep -q "\[filters\.$name-" "$RTK_FILTERS" 2>/dev/null || grep -q "\[filters\.${name}" "$RTK_FILTERS" 2>/dev/null; then
        ok "$name filters — already present"
      else
        if $DRY_RUN; then
          dry "Would append $name filters to $RTK_FILTERS"
        else
          echo "" >> "$RTK_FILTERS"
          echo "# --- $name filters (added by aacostsaver) ---" >> "$RTK_FILTERS"
          # strip comment header lines from source files before appending
          grep -v "^#" "$f" >> "$RTK_FILTERS"
          ok "$name filters — appended to $RTK_FILTERS"
        fi
      fi
    done
  fi
fi
echo ""

###############################################################################
# 9. AGENTS.md — universal agent instructions (Codex, Zed, etc.)
###############################################################################
bold "9. AGENTS.md global installation (~/.agents/ + ~/.codex/)"
chmod +x "$SCRIPT_DIR/scripts/apply-agents-md.sh" 2>/dev/null || true
if [[ "$DRY_RUN" == "true" ]]; then
  DRY_RUN=1 bash "$SCRIPT_DIR/scripts/apply-agents-md.sh"
else
  bash "$SCRIPT_DIR/scripts/apply-agents-md.sh"
fi
echo ""

###############################################################################
# 10. Caveman + cost-saving skills
###############################################################################
bold "10. Caveman + cost-saving skills (caveman, token-cost-optimizer, compress)"
if $SKIP_HOOKS; then
  skip "Skipped (--skip-hooks)"
else
  chmod +x "$SCRIPT_DIR/scripts/install-caveman.sh" 2>/dev/null || true
  if $DRY_RUN; then
    DRY_RUN=1 bash "$SCRIPT_DIR/scripts/install-caveman.sh"
  else
    bash "$SCRIPT_DIR/scripts/install-caveman.sh"
  fi
fi
echo ""

###############################################################################
# 11. Compress CLAUDE.md / RTK.md (optional — saves ~60% system prompt tokens)
###############################################################################
bold "11. Compress memory files (CLAUDE.md, RTK.md)"
info "This saves ~60% system prompt input tokens. Backups are created first."
if $DRY_RUN; then
  dry "Would run: scripts/compress-memory.sh"
  info "Skipping in dry-run. Run manually: bash $SCRIPT_DIR/scripts/compress-memory.sh"
else
  ask_compress() {
    read -r -p "  Compress CLAUDE.md and RTK.md now? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
  }
  if ask_compress; then
    chmod +x "$SCRIPT_DIR/scripts/compress-memory.sh" 2>/dev/null || true
    bash "$SCRIPT_DIR/scripts/compress-memory.sh"
  else
    info "Skipped. Run manually later: bash $SCRIPT_DIR/scripts/compress-memory.sh"
  fi
fi
echo ""

###############################################################################
# 12. Copilot CLI LSP config (~/.copilot/lsp-config.json)
###############################################################################
bold "12. Copilot CLI LSP config (Go, TypeScript/JS, Rust, Python, C/C++)"
info "Prerequisite: LSP binaries must be installed separately (gopls, typescript-language-server, rust-analyzer, pyright-langserver, clangd)"
COPILOT_LSP="$HOME/.copilot/lsp-config.json"
LSP_TEMPLATE="$SCRIPT_DIR/configs/lsp-config.json"
if $DRY_RUN; then
  dry "Would write LSP config → $COPILOT_LSP"
else
  if [[ -f "$COPILOT_LSP" ]]; then
    if diff -q "$LSP_TEMPLATE" "$COPILOT_LSP" &>/dev/null; then
      ok "Already up to date"
    else
      cp "$COPILOT_LSP" "${COPILOT_LSP}.bak"
      info "Backed up existing → ${COPILOT_LSP}.bak"
      cp "$LSP_TEMPLATE" "$COPILOT_LSP"
      ok "Updated $COPILOT_LSP"
    fi
  else
    cp "$LSP_TEMPLATE" "$COPILOT_LSP"
    ok "Installed $COPILOT_LSP"
  fi
fi
echo ""

###############################################################################
# 13. Claude Code LSP plugins
###############################################################################
bold "13. Claude Code LSP plugins (Go, TypeScript/JS, Rust, Python, C/C++)"
CLAUDE_LSP_PLUGINS=(
  "gopls-lsp@claude-plugins-official"
  "typescript-lsp@claude-plugins-official"
  "rust-analyzer-lsp@claude-plugins-official"
  "pyright-lsp@claude-plugins-official"
  "clangd-lsp@claude-plugins-official"
)
if ! command -v claude &>/dev/null; then
  skip "claude CLI not found — skipping Claude Code LSP plugins"
else
  for plugin in "${CLAUDE_LSP_PLUGINS[@]}"; do
    plugin_name="${plugin%@*}"
    already=$(claude plugin list 2>/dev/null | grep -w "$plugin_name" || true)
    if [[ -n "$already" ]]; then
      ok "$plugin_name — already installed"
    elif $DRY_RUN; then
      dry "Would install: claude plugin install $plugin"
    else
      claude plugin install "$plugin" 2>/dev/null && ok "$plugin_name — installed" || skip "$plugin_name — install failed (check marketplace)"
    fi
  done
fi
echo ""

###############################################################################
# Summary
###############################################################################
bold "Installation complete!"
echo ""
echo "  Next steps:"
echo "  1. Restart Claude Code + Copilot CLI to activate hook and skill changes"
echo "  2. Run: rtk discover   (should now scan sessions)"
echo "  3. Run: rtk gain       (check token savings improvement)"
echo "  4. Run: rtk cc-economics  (track cost trend)"
echo "  5. Say 'caveman mode' in any chat → ~75% output token reduction"
echo "  6. Say 'optimize tokens' before large tasks → cost-aware planning"
echo "  7. For new projects: bash scripts/apply-agents-md.sh --project"
echo ""
echo "  Reference: aacostsaver/configs/, skills/, templates/ for all configurations"
