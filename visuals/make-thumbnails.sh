#!/bin/sh
# Writes thumbnails/<name>.jpg from each <name>.mp4. Needs ffmpeg.
# Run again after re-recording a clip.
set -e
cd "$(dirname "$0")"
mkdir -p thumbnails

# Where in the clip to grab (0 to 1) and the crop box (w:h:x:y in clip pixels)
# that frames the figure. A new clip gets the middle frame, uncropped.
shot_for() {
  case "$1" in
    arch-roll) echo "0.5 420:420:160:0" ;;
    toe-flex) echo "0.5 470:470:30:0" ;;
    small-shoulder-circles) echo "0.25 470:470:125:225" ;;
    large-arm-circles) echo "0.5 470:470:125:225" ;;
    ankle-stretch) echo "0.25 380:380:200:0" ;;
    *) echo "0.5 in_w:in_h:0:0" ;;
  esac
}

for video in *.mp4; do
  name="${video%.mp4}"
  set -- $(shot_for "$name")
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
  at=$(awk "BEGIN { print $duration * $1 }")
  ffmpeg -v error -y -ss "$at" -i "$video" -frames:v 1 \
    -vf "crop=$2,scale=240:240" -q:v 3 "thumbnails/$name.jpg"
  echo "thumbnails/$name.jpg"
done
