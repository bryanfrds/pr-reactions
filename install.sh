#!/bin/bash
# Install pr-reactions: add the SubagentStop hook to ~/.claude/settings.json and
# create ~/.config/pr-reactions for your own pictures and sounds.
#   ./install.sh            install
#   ./install.sh --remove   take the hook back out
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
CMD="bash '$HERE/pr-reactions.sh'"
MODE="${1:-install}"

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"          # one backup, in case anything looks off

python3 - "$SETTINGS" "$CMD" "$MODE" <<'PY'
import json, sys
path, cmd, mode = sys.argv[1:]
with open(path) as f:
    settings = json.load(f)
groups = settings.setdefault("hooks", {}).setdefault("SubagentStop", [])
# Drop any earlier pr-reactions entry, so installing twice doesn't add two.
for g in groups:
    g["hooks"] = [h for h in g.get("hooks", []) if "pr-reactions.sh" not in h.get("command", "")]
groups[:] = [g for g in groups if g.get("hooks")]
if mode != "--remove":
    groups.append({"hooks": [{"type": "command", "command": cmd, "timeout": 10}]})
if not groups:
    del settings["hooks"]["SubagentStop"]
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY

if [ "$MODE" = "--remove" ]; then
  echo "Removed the pr-reactions hook from $SETTINGS."
else
  mkdir -p "$HOME/.config/pr-reactions"
  echo "Installed. Hook added to $SETTINGS (backup at $SETTINGS.bak)."
  echo "Your own files go in ~/.config/pr-reactions/ - see the README."
  echo "Try it: bash '$HERE/pr-reactions.sh' --show approve"
  echo "Open Claude Code chats pick it up after /hooks or a restart."
fi
