#!/bin/bash
# pr-reactions: pop up a reaction when a Claude Code pr-reviewer subagent
# finishes. One picture and sound for an approval, another for requested changes,
# each optionally taking turns with a video clip.
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
VIDEO_VOLUME=0.3     # videos carry their own sound, usually mixed loud
PLAY=both            # both: a picture and a video take turns; or image / video
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
  local dirs=("$CONFIG_DIR"); [ -n "${_PRR_ONLY_CONFIG:-}" ] || dirs+=("$HERE/media")
  local dir; for dir in "${dirs[@]}"; do
    for ext in "$@"; do
      [ -f "$dir/$name.$ext" ] && { echo "$dir/$name.$ext"; return; }
    done
  done
}
IMG=$(find_file "$RESULT" png gif jpg jpeg)
SOUND=$(find_file "$RESULT" mp3 m4a wav aiff)
VIDEO=$(find_file "$RESULT" mov mp4 m4v)

# With both your own picture and a video for this reaction, they take turns. A video
# on its own always plays (the built-in card doesn't count as a picture of yours).
# A video plays to its end with its own sound, so the separate sound is skipped.
OWN_IMG=$(_PRR_ONLY_CONFIG=1 find_file "$RESULT" png gif jpg jpeg)
pick="image"
case "$PLAY" in
  video) [ -n "$VIDEO" ] && pick=video ;;
  image) ;;
  *)
    if [ -n "$VIDEO" ] && [ -n "$OWN_IMG" ]; then
      turn="$CONFIG_DIR/.next-$RESULT"
      [ "$(cat "$turn" 2>/dev/null)" = video ] && pick=video
      # (dry runs move the turn too, so --show tries each in order)
      [ -w "$CONFIG_DIR" ] && { [ "$pick" = video ] && echo image || echo video; } 2>/dev/null > "$turn"
    elif [ -n "$VIDEO" ]; then
      pick=video
    fi ;;
esac
if [ "$pick" = video ]; then IMG="$VIDEO"; SOUND=""; fi

if [ -n "${PR_REACTIONS_DRY_RUN:-}" ]; then
  echo "$RESULT ${IMG:-no-image} ${SOUND:-no-sound} ${HOLD}s"
  exit 0
fi
[ -n "$IMG" ] || exit 0
[ "$(uname)" = "Darwin" ] || exit 0          # the popup is macOS-only for now

[ -n "$SOUND" ] && { nohup afplay -v "$VOLUME" "$SOUND" >/dev/null 2>&1 & }
nohup osascript -l JavaScript "$HERE/popup.js" "$IMG" "$HOLD" "$VIDEO_VOLUME" >/dev/null 2>&1 &
exit 0
