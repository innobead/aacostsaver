---
name: compress-memory
description: >
  Compress natural language memory files (CLAUDE.md, RTK.md, todos) into caveman format
  to save input tokens. Preserves all technical substance, code, URLs, and structure.
  Compressed version overwrites the original file. Human-readable backup saved as FILE.original.md.
  Trigger: /compress <filepath> or "compress memory file" or "compress CLAUDE.md"
user-invocable: true
---

# Compress Memory Files

Compress natural language files into caveman-speak to reduce input tokens on every session start.

## Trigger

`/compress <filepath>` or when user asks to compress a memory file.

## Process

1. Read the file
2. Apply compression rules (preserve code exactly, compress prose)
3. Backup original as `<file>.original.md`
4. Write compressed version

## Compression Rules

### Remove
- Articles: a, an, the
- Filler: just, really, basically, actually, simply, essentially
- Pleasantries: sure, certainly, of course, happy to, I'd recommend
- Hedging: it might be worth, you could consider, it would be good to
- Redundant: "in order to" → "to", "make sure to" → "ensure"

### Preserve EXACTLY
- Code blocks (fenced ``` and indented)
- Inline code (`backtick content`)
- URLs and links
- File paths
- Commands (npm install, git commit, etc.)
- Technical terms, library names, API names
- Proper nouns, version numbers

### Compress
- Short synonyms: "big" not "extensive", "fix" not "implement a solution for"
- Fragments OK: "Run tests before commit" not "You should always run tests before committing"
- Drop "you should", "make sure to", "remember to" — just state the action
- Merge redundant bullets

## Boundaries

- Only compress: .md, .txt, .typst, .tex, extensionless files
- Never modify: .py, .js, .ts, .json, .yaml, .toml, .env, .sh
- Always backup original before overwriting

---
*Adapted from: https://github.com/JuliusBrussee/caveman — MIT License*
