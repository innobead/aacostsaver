#!/usr/bin/env bash
# apply-copilot-hook.sh — Wire rtk hook copilot as Copilot CLI preToolUse hook
set -euo pipefail

SETTINGS="$HOME/.copilot/settings.json"
BACKUP="$HOME/.copilot/settings.json.bak.$(date +%Y%m%d%H%M%S)"

if [[ ! -f "$SETTINGS" ]]; then
  echo "ERROR: $SETTINGS not found. Is Copilot CLI installed?"
  exit 1
fi

echo "Backing up $SETTINGS → $BACKUP"
cp "$SETTINGS" "$BACKUP"

# Check if hook already configured
if python3 -c "
import json, sys
d = json.load(open('$SETTINGS'))
hooks = d.get('hooks', {}).get('preToolUse', [])
for h in hooks:
    if 'rtk hook copilot' in str(h):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  echo "✅ rtk hook copilot already configured in preToolUse"
  exit 0
fi

echo "Patching preToolUse hook..."
python3 - <<'PYEOF'
import json, os

settings_path = f"{os.environ['HOME']}/.copilot/settings.json"
with open(settings_path) as f:
    content = f.read().strip()
    # Handle empty or comment-only file
    if not content or content.startswith("//"):
        d = {}
    else:
        d = json.loads(content)

hook_entry = {
    "matcher": "Bash",
    "hooks": [
        {
            "type": "command",
            "command": "rtk hook copilot"
        }
    ]
}

if "hooks" not in d:
    d["hooks"] = {}
if "preToolUse" not in d["hooks"]:
    d["hooks"]["preToolUse"] = []

existing = d["hooks"]["preToolUse"]
for h in existing:
    for hook in h.get("hooks", []):
        if "rtk hook copilot" in hook.get("command", ""):
            print("Already present, skipping")
            exit(0)

existing.append(hook_entry)

with open(settings_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")

print("✅ preToolUse hook added: rtk hook copilot")
PYEOF
