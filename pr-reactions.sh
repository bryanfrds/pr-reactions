#!/bin/bash
# pr-reactions: pop up a reaction when a Claude Code pr-reviewer subagent
# finishes. One picture and sound for an approval, another for requested changes.
#
# Runs as a Claude Code SubagentStop hook and reads the hook's JSON on stdin.
#   pr-reactions.sh                 hook mode (reads stdin)
#   pr-reactions.sh --show approve  show a reaction now, to try it out
#   pr-reactions.sh --show fail
#
# Your own pictures and sounds go in ~/.config/pr-reactions/ (see README).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${PR_REACTIONS_CONFIG:-$HOME/.config/pr-reactions}"

# Seconds each reaction stays fully visible. Fading in and out adds about 1s.
APPROVE_SECONDS=2
FAIL_SECONDS=1.5
VOLUME=0.35
[ -f "$CONFIG_DIR/config" ] && . "$CONFIG_DIR/config"

if [ "${1:-}" = "--show" ]; then
  RESULT="${2:-approve}"
else
  RESULT=$(python3 "$HERE/verdict.py" 2>/dev/null)
fi
case "$RESULT" in
  approve) HOLD="$APPROVE_SECONDS" ;;
  fail)    HOLD="$FAIL_SECONDS" ;;
  *)       exit 0 ;;
esac

# First match wins: your files in the config folder, then the defaults here.
find_file() {   # find_file <name> <ext>...
  local name="$1"; shift
  for dir in "$CONFIG_DIR" "$HERE/media"; do
    for ext in "$@"; do
      [ -f "$dir/$name.$ext" ] && { echo "$dir/$name.$ext"; return; }
    done
  done
}
IMG=$(find_file "$RESULT" png gif jpg jpeg)
SOUND=$(find_file "$RESULT" mp3 m4a wav aiff)

if [ -n "${PR_REACTIONS_DRY_RUN:-}" ]; then
  echo "$RESULT ${IMG:-no-image} ${SOUND:-no-sound} ${HOLD}s"
  exit 0
fi
[ -n "$IMG" ] || exit 0
[ "$(uname)" = "Darwin" ] || exit 0          # the popup is macOS-only for now

[ -n "$SOUND" ] && { nohup afplay -v "$VOLUME" "$SOUND" >/dev/null 2>&1 & }
nohup osascript -l JavaScript "$HERE/popup.js" "$IMG" "$HOLD" >/dev/null 2>&1 &
exit 0
