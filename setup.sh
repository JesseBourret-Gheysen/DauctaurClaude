#!/usr/bin/env bash
# DauctaurClaude — one-click tiered Claude Code setup (Linux / macOS)
# Installs: opusplan main model + high effort, deep-reasoner (Opus) and
# fast-worker (Sonnet) subagents. Non-destructive: backs up anything it touches.
#
# Usage:
#   ./setup.sh                 # install settings + agents to ~/.claude
#   ./setup.sh --with-claude   # also install a global ~/.claude/CLAUDE.md orchestration memory
#   ./setup.sh --dry-run       # show what would change, do nothing
#   CLAUDE_HOME=/path ./setup.sh   # override target (default ~/.claude)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/config"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
WITH_CLAUDE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --with-claude) WITH_CLAUDE=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then say "[dry-run] $*"; else eval "$*"; fi; }

echo "DauctaurClaude setup -> $DEST"
[ "$DRY_RUN" -eq 1 ] && echo "(dry run — no changes will be written)"

# 0. sanity
if [ ! -d "$SRC" ]; then echo "ERROR: config/ not found next to setup.sh" >&2; exit 1; fi

# 1. dirs
run "mkdir -p '$DEST/agents'"

# 2. subagents (back up any existing file of the same name)
for f in deep-reasoner fast-worker; do
  target="$DEST/agents/$f.md"
  if [ -f "$target" ]; then run "cp '$target' '$target.bak-$STAMP'"; say "backed up existing $f.md"; fi
  run "cp '$SRC/agents/$f.md' '$target'"
  say "installed agents/$f.md"
done

# 3. settings.json — merge our keys into existing settings, don't clobber the rest
SETTINGS="$DEST/settings.json"
if [ -f "$SETTINGS" ]; then run "cp '$SETTINGS' '$SETTINGS.bak-$STAMP'"; say "backed up existing settings.json"; fi

if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] would merge model=opusplan, effortLevel=high into settings.json"
else
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$SETTINGS" "$SRC/settings.json" <<'PY'
import json, os, sys
dest, src = sys.argv[1], sys.argv[2]
base = {}
if os.path.exists(dest):
    try:
        with open(dest) as fh: base = json.load(fh) or {}
    except Exception: base = {}
with open(src) as fh: add = json.load(fh)
base.update(add)
with open(dest, "w") as fh: json.dump(base, fh, indent=2); fh.write("\n")
print("  merged settings.json (model=opusplan, effortLevel=high)")
PY
  elif command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    if [ -f "$SETTINGS" ]; then
      jq -s '.[0] * .[1]' "$SETTINGS" "$SRC/settings.json" > "$tmp"
    else
      cp "$SRC/settings.json" "$tmp"
    fi
    mv "$tmp" "$SETTINGS"
    say "merged settings.json via jq"
  else
    # no merge tool: only write if absent, else warn
    if [ -f "$SETTINGS" ]; then
      echo "  WARN: python3/jq not found; left existing settings.json untouched." >&2
      echo "        Add manually: \"model\": \"opusplan\", \"effortLevel\": \"high\"" >&2
    else
      cp "$SRC/settings.json" "$SETTINGS"; say "wrote settings.json"
    fi
  fi
fi

# 4. optional global CLAUDE.md
if [ "$WITH_CLAUDE" -eq 1 ]; then
  CM="$DEST/CLAUDE.md"
  if [ -f "$CM" ]; then run "cp '$CM' '$CM.bak-$STAMP'"; say "backed up existing CLAUDE.md"; fi
  run "cp '$SRC/CLAUDE.md.template' '$CM'"
  say "installed global CLAUDE.md"
fi

cat <<EOF

Done.
Verify:
  1. Start Claude Code:            claude
  2. Confirm main model:           /model     (should show opusplan)
  3. List agents:                  /agents    (deep-reasoner, fast-worker)
  4. Test routing (KNOWN BUG on some versions): invoke deep-reasoner and confirm
     the response is labeled Opus, not the parent model. If it resolves to the
     parent, rely on opusplan alone — it is reliable.

Per-project orchestration: copy config/CLAUDE.md.template into a repo as CLAUDE.md
and fill in the repo facts. (Or re-run with --with-claude for a global one.)

Backups (if any) are alongside the originals with suffix .bak-$STAMP
EOF
