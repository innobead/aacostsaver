#!/usr/bin/env bash
# compress-memory.sh — Compress CLAUDE.md / RTK.md into caveman format
# Saves ~60% input tokens from system prompt on every session start.
# Uses the compression rules from the caveman project.
set -euo pipefail

FILES_TO_COMPRESS=(
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/RTK.md"
)

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
info() { printf '  \033[36mℹ  %s\033[0m\n' "$*"; }
warn() { printf '  \033[33m⚠️  %s\033[0m\n' "$*"; }

compress_file() {
  local filepath="$1"

  if [[ ! -f "$filepath" ]]; then
    warn "File not found: $filepath"
    return
  fi

  local backup="${filepath%.md}.original.md"
  local original_size
  original_size=$(wc -c < "$filepath")

  # Don't compress if already backed up (already compressed once)
  if [[ -f "$backup" ]]; then
    info "Already compressed (backup exists): $backup"
    info "To recompress, delete the backup first"
    return
  fi

  echo ""
  bold "Compressing: $filepath"
  info "Original size: $original_size bytes"

  # Backup original
  cp "$filepath" "$backup"
  info "Backup saved: $backup"

  # Apply compression via Python (respects code blocks)
  python3 - "$filepath" <<'PYEOF'
import sys, re

filepath = sys.argv[1]
with open(filepath) as f:
    content = f.read()

# Split into segments: code blocks vs prose
CODE_BLOCK = re.compile(r'(```[\s\S]*?```|`[^`]+`)', re.MULTILINE)

segments = CODE_BLOCK.split(content)

def compress_prose(text):
    # Remove articles
    text = re.sub(r'\b(a|an|the)\b ', '', text, flags=re.IGNORECASE)
    # Remove filler words
    fillers = r'\b(just|really|basically|actually|simply|essentially|generally|certainly|of course)\b'
    text = re.sub(fillers, '', text, flags=re.IGNORECASE)
    # Remove pleasantries
    text = re.sub(r'\b(sure|certainly|happy to|I\'d recommend|please note that|note that)\b[,]?\s*', '', text, flags=re.IGNORECASE)
    # Remove hedging
    text = re.sub(r'it might be worth\s+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'you could consider\s+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'it would be good to\s+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'you should\s+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'make sure to\s+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'remember to\s+', '', text, flags=re.IGNORECASE)
    # Shorten common phrases
    text = text.replace('in order to', 'to')
    text = text.replace('make sure to', 'ensure')
    text = text.replace('the reason is because', 'because')
    text = text.replace('however,', '')
    text = text.replace('furthermore,', '')
    text = text.replace('additionally,', '')
    text = text.replace('in addition,', '')
    # Collapse multiple spaces
    text = re.sub(r'  +', ' ', text)
    # Collapse multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text

result = []
for i, seg in enumerate(segments):
    if CODE_BLOCK.match(seg):
        result.append(seg)  # preserve code exactly
    else:
        result.append(compress_prose(seg))

with open(filepath, 'w') as f:
    f.write(''.join(result))

print(f"Done")
PYEOF

  local new_size
  new_size=$(wc -c < "$filepath")
  local saved=$(( original_size - new_size ))
  local pct=$(( saved * 100 / original_size ))

  ok "Compressed: $original_size → $new_size bytes ($pct% saved)"
}

bold "Caveman Compress — Memory File Optimizer"
echo "========================================="

for f in "${FILES_TO_COMPRESS[@]}"; do
  compress_file "$f"
done

echo ""
bold "Done. Compressed files save tokens on every session start."
echo ""
echo "To restore originals:"
for f in "${FILES_TO_COMPRESS[@]}"; do
  echo "  cp ${f%.md}.original.md $f"
done
