#!/usr/bin/env bash
# post-tool-hook.sh — PostToolUse: compress large bash outputs via rtk pipe
# Claude Code PostToolUse hook reads JSON from stdin.
# If output > 2KB, pipes it through rtk pipe (smart log filter) and returns modified JSON.
# Install via: add to hooks.PostToolUse in ~/.claude/settings.json

set -euo pipefail

INPUT=$(cat)

python3 - <<PYEOF
import json, subprocess, sys, os

data = json.loads("""$INPUT""".replace('"""', '"'))

# PostToolUse payload shape: {tool_name, tool_input, tool_response: {output, is_error}}
response = data.get("tool_response", {})
output = response.get("output", "")

# Only compress if output is large (> 2048 chars)
if len(output) > 2048 and not response.get("is_error", False):
    try:
        result = subprocess.run(
            ["rtk", "pipe"],
            input=output,
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and result.stdout:
            compressed = result.stdout
            savings = len(output) - len(compressed)
            if savings > 100:
                response["output"] = compressed
                data["tool_response"] = response
    except Exception:
        pass  # Passthrough on failure

print(json.dumps(data))
PYEOF
