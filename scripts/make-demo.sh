#!/bin/bash
# Redraw docs/demo.gif: the two default cards fading in and out at the bottom of a
# plain backdrop, with the popup's own timings (popup.js: 0.35s in, hold, 0.6s out).
# It is drawn, not screen-recorded, so nobody's desktop ends up in the repo.
#   scripts/make-demo.sh        needs ffmpeg
set -euo pipefail
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Rounded corners, as popup.js's cornerRadius gives the real window.
ROUND='if(gt(abs(X-W/2),W/2-20)*gt(abs(Y-H/2),H/2-20),if(lte(hypot(abs(X-W/2)-(W/2-20),abs(Y-H/2)-(H/2-20)),20),255,0),255)'

clip() {  # clip <reaction> <seconds fully visible>
  local hold=$2
  local len; len=$(echo "$hold + 1.55" | bc)
  ffmpeg -v error -y \
    -f lavfi -i "gradients=s=560x380:c0=0x1d2b45:c1=0x3b2a4d:x0=0:y0=0:x1=560:y1=380:speed=0:d=$len" \
    -loop 1 -t "$(echo "$hold + 0.95" | bc)" -i "media/$1.png" \
    -filter_complex "[1]scale=200:200,format=rgba,geq=r='p(X,Y)':g='p(X,Y)':b='p(X,Y)':a='$ROUND',\
fade=in:st=0:d=0.35:alpha=1,fade=out:st=$(echo "0.35 + $hold" | bc):d=0.6:alpha=1[card];\
[0][card]overlay=x=(W-w)/2:y=H-h-36:eof_action=pass,format=yuv420p" \
    -r 25 -t "$len" "$TMP/$1.mp4"
}

clip approve 1.6
clip fail 1.2
printf "file '%s'\nfile '%s'\n" "$TMP/approve.mp4" "$TMP/fail.mp4" > "$TMP/list.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$TMP/list.txt" \
  -vf "fps=20,scale=420:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 docs/demo.gif
echo "wrote docs/demo.gif"
