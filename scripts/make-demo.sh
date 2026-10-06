#!/bin/bash
# Redraw docs/demo.gif: the two default cards fading in and out at the bottom of a
# plain backdrop, with the popup's own timings (popup.js fades in for 0.35s and out
# for 0.6s; pr-reactions.sh holds approve 2s and fail 1.5s). The fades here are
# linear where popup.js eases them.
# It is drawn, not screen-recorded, so nobody's desktop ends up in the repo.
#   scripts/make-demo.sh        needs ffmpeg
set -euo pipefail
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Rounded corners, as popup.js's cornerRadius gives the real window.
ROUND='if(gt(abs(X-W/2),W/2-20)*gt(abs(Y-H/2),H/2-20),if(lte(hypot(abs(X-W/2)-(W/2-20),abs(Y-H/2)-(H/2-20)),20),255,0),255)'

add() { awk -v a="$1" -v b="$2" 'BEGIN { print a + b }'; }

clip() {  # clip <reaction> <seconds fully visible>
  local hold=$2
  local len; len=$(add "$hold" 1.55)
  ffmpeg -v error -y \
    -f lavfi -i "gradients=s=560x380:c0=0x1d2b45:c1=0x3b2a4d:x0=0:y0=0:x1=560:y1=380:speed=0:seed=1:d=$len" \
    -loop 1 -t "$(add "$hold" 0.95)" -i "media/$1.png" \
    -filter_complex "[1]scale=240:240,format=rgba,geq=r='p(X,Y)':g='p(X,Y)':b='p(X,Y)':a='$ROUND',\
fade=in:st=0:d=0.35:alpha=1,fade=out:st=$(add 0.35 "$hold"):d=0.6:alpha=1[card];\
[0][card]overlay=x=(W-w)/2:y=H-h-48:eof_action=pass,format=yuv420p" \
    -r 25 -t "$len" "$TMP/$1.mp4"
}

clip approve 2
clip fail 1.5
printf "file '%s'\nfile '%s'\n" "$TMP/approve.mp4" "$TMP/fail.mp4" > "$TMP/list.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$TMP/list.txt" \
  -vf "fps=20,scale=420:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 docs/demo.gif
echo "wrote docs/demo.gif"
