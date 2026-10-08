#!/bin/bash
# End-to-end checks of pr-reactions.sh in dry-run mode (nothing is shown).
# Run with: bash tests/test_hook.sh
set -u
cd "$(dirname "$0")/.."
export PR_REACTIONS_DRY_RUN=1 PR_REACTIONS_CONFIG="$(mktemp -d)"
fails=0
check() {   # check <name> <expected start of output> <stdin json | "--show x">
  local out
  if [[ "$3" == --show* ]]; then out=$(bash pr-reactions.sh $3); else out=$(printf '%s' "$3" | bash pr-reactions.sh); fi
  # An empty expectation means no output at all, not "starts with nothing".
  if { [ -z "$2" ] && [ -z "$out" ]; } || { [ -n "$2" ] && [[ "$out" == "$2"* ]]; }; then echo "ok   $1"; else echo "FAIL $1: got '$out'"; fails=$((fails + 1)); fi
}
check "approve uses the default card"  "approve $PWD/media/approve.png no-sound 2s" '{"agent_type":"pr-reviewer","last_assistant_message":"VERDICT: APPROVE"}'
check "fail uses the default card"     "fail $PWD/media/fail.png no-sound 1.5s"     '{"agent_type":"pr-reviewer","last_assistant_message":"VERDICT: REQUEST_CHANGES"}'
check "comment shows nothing"          ""                                            '{"agent_type":"pr-reviewer","last_assistant_message":"VERDICT: COMMENT"}'
check "bad JSON shows nothing"         ""                                            'not json'
touch "$PR_REACTIONS_CONFIG/approve.gif" "$PR_REACTIONS_CONFIG/approve.mp3"
printf 'APPROVE_SECONDS=4\n' > "$PR_REACTIONS_CONFIG/config"
check "your own files and config win"  "approve $PR_REACTIONS_CONFIG/approve.gif $PR_REACTIONS_CONFIG/approve.mp3 4s" '--show approve'
# A video for the same reaction takes turns with the picture, with its own sound.
touch "$PR_REACTIONS_CONFIG/approve.mov"
check "with a video too, the picture comes first" "approve $PR_REACTIONS_CONFIG/approve.gif $PR_REACTIONS_CONFIG/approve.mp3" '--show approve'
check "then the video, with no separate sound"    "approve $PR_REACTIONS_CONFIG/approve.mov no-sound" '--show approve'
check "then the picture again"                     "approve $PR_REACTIONS_CONFIG/approve.gif" '--show approve'
check "fail keeps its own turn"                    "fail $PWD/media/fail.png" '--show fail'
touch "$PR_REACTIONS_CONFIG/fail.mp4"
check "fail with a video starts on its picture"   "fail $PWD/media/fail.png" '--show fail'
check "and then its video"                         "fail $PR_REACTIONS_CONFIG/fail.mp4 no-sound" '--show fail'
printf 'APPROVE_SECONDS=4\nPLAY=video\n' > "$PR_REACTIONS_CONFIG/config"
check "PLAY=video always shows the video"         "approve $PR_REACTIONS_CONFIG/approve.mov" '--show approve'
check "every time"                                 "approve $PR_REACTIONS_CONFIG/approve.mov" '--show approve'
printf 'PLAY=image\n' > "$PR_REACTIONS_CONFIG/config"
check "PLAY=image never shows it"                 "approve $PR_REACTIONS_CONFIG/approve.gif" '--show approve'
rm "$PR_REACTIONS_CONFIG/approve.gif" "$PR_REACTIONS_CONFIG/config"
check "a video alone always shows"                "approve $PR_REACTIONS_CONFIG/approve.mov" '--show approve'

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
