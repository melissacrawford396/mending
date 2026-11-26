#!/usr/bin/env bash
# Records the Unity movement clips to visuals/<movement-name>.mp4,
# then refreshes visuals/thumbnails.
#
#   scripts/record-clips.sh                         every movement
#   scripts/record-clips.sh "Toe flex" "Arch roll"  only those movements
#
# The open Unity editor can stay open. Recording runs on a copy of the project.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="$repo/unity/Mending"
output="$repo/visuals"
clone="${MENDING_CLIP_CLONE:-/tmp/mending-figure}"
limit="${RECORD_TIMEOUT:-900}"
version="$(sed -n 's/^m_EditorVersion: //p' "$project/ProjectSettings/ProjectVersion.txt")"
unity="${UNITY_PATH:-/Applications/Unity/Hub/Editor/$version/Unity.app/Contents/MacOS/Unity}"
ffmpeg="${FFMPEG_PATH:-$(command -v ffmpeg || true)}"
log="$clone/Logs/clip-record.log"
result="$clone/Logs/clip-record-result.txt"

if [ ! -x "$unity" ]; then
  echo "Unity $version not found at $unity. Set UNITY_PATH." >&2
  exit 1
fi
if [ -z "$ffmpeg" ] || [ ! -x "$ffmpeg" ]; then
  echo "ffmpeg not found. Install it with: brew install ffmpeg" >&2
  exit 1
fi

mkdir -p "$clone/Logs" "$output"
rsync -a --delete \
  --exclude Library --exclude Logs --exclude Temp --exclude UserSettings \
  --exclude obj --exclude .vs --exclude .vscode \
  --exclude '*.csproj' --exclude '*.sln' --exclude '*.slnx' \
  "$project/" "$clone/"
rm -f "$result"

args=(-batchmode -projectPath "$clone" -executeMethod ClipRecorder.Run
  -recordClips -recordOutput "$output" -recordLog "$result" -ffmpeg "$ffmpeg"
  -logFile "$log")
if [ $# -gt 0 ]; then
  only="$(IFS='|'; echo "$*")"
  args+=(-recordOnly "$only")
fi

echo "Recording to $output ..."
"$unity" "${args[@]}" &
pid=$!
waited=0
while kill -0 "$pid" 2>/dev/null; do
  if [ "$waited" -ge "$limit" ]; then
    kill "$pid" 2>/dev/null || true
    sleep 3
    kill -9 "$pid" 2>/dev/null || true
    echo "Unity did not finish in ${limit}s. Log: $log" >&2
    exit 1
  fi
  sleep 2
  waited=$((waited + 2))
done
set +e
wait "$pid"
status=$?
set -e

if [ ! -f "$result" ]; then
  echo "Recording failed (exit $status). Log: $log" >&2
  grep -E "error CS|Scripts have compiler errors" "$log" | sort -u | head -20 >&2 || true
  exit 1
fi
cat "$result"
if [ "$status" -ne 0 ]; then
  echo "Recording failed (exit $status). Log: $log" >&2
  exit 1
fi

if [ -x "$output/make-thumbnails.sh" ]; then
  "$output/make-thumbnails.sh"
fi
