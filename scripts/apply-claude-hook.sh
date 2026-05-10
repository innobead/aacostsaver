#!/usr/bin/env bash
# apply-claude-hook.sh — Wire rtk hook claude as Claude Code PreToolUse hook
set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
BACKUP="$HOME/.claude/settings.json.bak.$(date +%Y%m%d%H%M%S)"

if [[ ! -f "$SETTINGS" ]]; then
  echo "ERROR: $SETTINGS not found"
  exit 1
fi

echo "Backing up $SETTINGS → $BACKUP"
cp "$SETTINGS" "$BACKUP"

# Check if hook already configured
if python3 -c "
import json, sys
d = json.load(open('$SETTINGS'))
hooks = d.get('hooks', {}).get('PreToolUse', [])
for h in hooks:
    if 'rtk hook claude' in str(h):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  echo "✅ rtk hook claude already configured in PreToolUse"
  exit 0
fi

echo "Patching PreToolUse hook..."
python3 - <<'PYEOF'
import json

settings_path = f"{__import__('os').environ['HOME']}/.claude/settings.json"
with open(settings_path) as f:
    d = json.load(f)

hook_entry = {
    "matcher": "Bash",
    "hooks": [
        {
            "type": "command",
            "command": "rtk hook claude"
        }
    ]
}

if "hooks" not in d:
    d["hooks"] = {}
if "PreToolUse" not in d["hooks"]:
    d["hooks"]["PreToolUse"] = []

# Avoid duplicates
existing = d["hooks"]["PreToolUse"]
for h in existing:
    for hook in h.get("hooks", []):
        if "rtk hook claude" in hook.get("command", ""):
            print("Already present, skipping")
            exit(0)

existing.append(hook_entry)

with open(settings_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")

print("✅ PreToolUse hook added: rtk hook claude")
PYEOF
