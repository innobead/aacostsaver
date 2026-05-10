#!/usr/bin/env bash
# install-mcp.sh — Install context7 and memory MCP servers for Claude Code
# context7: fetches library docs on-demand (no raw doc pasting)
# memory:   persists learned patterns across sessions
set -euo pipefail

MCP_CONFIG="$HOME/.claude/mcp.json"

echo "=== Installing MCP servers for token efficiency ==="

# 1. Install via npx (no global install needed; Claude Code runs them on-demand)
echo ""
echo "Verifying npx is available..."
if ! command -v npx &>/dev/null; then
  echo "ERROR: npx not found. Install Node.js first."
  exit 1
fi

# 2. Write MCP config
echo ""
echo "Writing MCP config to $MCP_CONFIG..."

cat > "$MCP_CONFIG" <<'MCPEOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "description": "Fetches library docs on-demand. Use: 'use context7' in prompt."
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "description": "Persistent cross-session memory. Stores project patterns."
    }
  }
}
MCPEOF

echo "✅ MCP config written"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to pick up MCP servers"
echo "  2. In prompts, say 'use context7' to fetch library docs instead of pasting them"
echo "  3. Memory MCP auto-persists entities — no extra steps needed"
