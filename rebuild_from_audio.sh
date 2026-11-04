#!/bin/bash
set -euo pipefail
ROOT="/Users/amaster/projectm/dronewiki-pdf-video"
cd "$ROOT"
mkdir -p rebuild-audio renders
rm -f rebuild-audio/* renders/dronewiki-pdf-original-final-revised.mp4

# Read actual durations from the current MP3 files; JSON metadata may be stale.
: > rebuild-audio/narration.txt
: > rebuild-audio/durations.txt
for n in 01 02 03 04 05 06 07 08 09 10; do
  file="$ROOT/audio/page-$n.mp3"
  test -s "$file"
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file")
  printf '%s %s\n' "$n" "$duration" >> rebuild-audio/durations.txt
  printf "file '%s'\n" "$file" >> rebuild-audio/narration.txt
done
TOTAL=$(awk '{s+=$2} END {printf "%.6f",s}' rebuild-audio/durations.txt)

# Reuse the existing PDF page clips when their source audio duration matches;
# render fresh clips so changed audio controls visual holds exactly.
rm -f rebuild-audio/page-*.mp4
while read -r n dur; do
  img="$ROOT/pdf-pages/page-$n.png"
  out="$ROOT/rebuild-audio/page-$n.mp4"
  fadeout=$(python3 -c "print(max(0,float('$dur')-0.35))")
  ffmpeg -y -loglevel error -loop 1 -i "$img" -t "$dur" \
    -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='min(zoom+0.00035,1.055)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=24,fade=t=in:st=0:d=0.35,fade=t=out:st=$fadeout:d=0.35,format=yuv420p" \
    -an -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p "$out" </dev/null
done < rebuild-audio/durations.txt

: > rebuild-audio/concat.txt
for n in 01 02 03 04 05 06 07 08 09 10; do printf "file '%s/rebuild-audio/page-%s.mp4'\n" "$ROOT" "$n" >> rebuild-audio/concat.txt; done
ffmpeg -y -loglevel error -f concat -safe 0 -i rebuild-audio/concat.txt -c copy rebuild-audio/video.mp4
ffmpeg -y -loglevel error -f concat -safe 0 -i rebuild-audio/narration.txt -ar 48000 -ac 2 -c:a pcm_s16le rebuild-audio/narration.wav

# Use the user's current background file when present.
BG="$ROOT/audio/bgm.wav"
test -s "$BG"
fadeout_bgm=$(python3 -c "print(max(0,float('$TOTAL')-4))")
ffmpeg -y -loglevel error -stream_loop -1 -i "$BG" -t "$TOTAL" \
  -af "volume=0.13,afade=t=in:st=0:d=3,afade=t=out:st=$fadeout_bgm:d=4" \
  -ar 48000 -ac 2 rebuild-audio/bgm-trimmed.wav
ffmpeg -y -loglevel error -i rebuild-audio/narration.wav -i rebuild-audio/bgm-trimmed.wav \
  -filter_complex "[0:a]acompressor=threshold=-24dB:ratio=2.5:attack=10:release=180:makeup=2[n];[n][1:a]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.88[m]" \
  -map '[m]' -ar 48000 -ac 2 -c:a aac -b:a 192k rebuild-audio/mix.m4a
ffmpeg -y -loglevel error -i rebuild-audio/video.mp4 -i rebuild-audio/mix.m4a \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy -shortest renders/dronewiki-pdf-original-final-revised.mp4

printf 'total_narration=%s\n' "$TOTAL"
ffprobe -v error -show_entries format=duration,size:stream=codec_name,codec_type,width,height,r_frame_rate,sample_rate,channels -of default=nw=1 renders/dronewiki-pdf-original-final-revised.mp4
