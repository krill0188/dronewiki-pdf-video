#!/bin/bash
set -euo pipefail
ROOT="/Users/amaster/projectm/dronewiki-pdf-video"
cd "$ROOT"
mkdir -p clips renders
rm -f clips/*.mp4 renders/* audio/narration.txt audio/narration.m4a audio/mix.m4a
python3 - <<'PY'
import json
from pathlib import Path
root=Path('/Users/amaster/projectm/dronewiki-pdf-video')
rows=[]
for p in sorted((root/'audio').glob('page-*.json')):
    d=json.loads(p.read_text())
    rows.append(d)
(root/'audio'/'durations.txt').write_text('\n'.join(f"{x['page']} {x['durationSeconds']:.6f}" for x in rows)+'\n')
with (root/'audio'/'narration.txt').open('w') as f:
    for x in rows: f.write(f"file '{(root/'audio'/('page-%02d.mp3'%x['page'])).as_posix()}'\n")
print('total',sum(x['durationSeconds'] for x in rows))
PY
while read -r page dur; do
  printf -v img "pdf-pages/page-%02d.png" "$page"
  printf -v out "clips/page-%02d.mp4" "$page"
  ffmpeg -y -loop 1 -i "$img" -t "$dur" -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='min(zoom+0.00035,1.055)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=24,fade=t=in:st=0:d=0.35,fade=t=out:st=$(python3 -c "print(max(0,$dur-0.35))"):d=0.35,format=yuv420p" -an -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p "$out" </dev/null
 done < audio/durations.txt
printf "file '%s'\n" "$ROOT/clips/page-01.mp4" > clips/concat.txt
for n in 02 03 04 05 06 07 08 09 10; do printf "file '%s'\n" "$ROOT/clips/page-$n.mp4" >> clips/concat.txt; done
ffmpeg -y -f concat -safe 0 -i clips/concat.txt -c copy renders/pdf-pages-video.mp4
ffmpeg -y -f concat -safe 0 -i audio/narration.txt -ar 48000 -ac 2 -c:a pcm_s16le audio/narration.wav
TOTAL=$(python3 -c "import json,glob; print(sum(json.load(open(p))['durationSeconds'] for p in glob.glob('audio/page-*.json')))" )
ffmpeg -y -stream_loop -1 -i /Users/amaster/projectm/dronewiki-hyperframes/bgm-tech-documentary-v2-processed.wav -t "$TOTAL" -af "volume=0.13,afade=t=in:st=0:d=3,afade=t=out:st=$(python3 -c "print(max(0,float('$TOTAL')-4))"):d=4" -ar 48000 -ac 2 audio/bgm.wav
ffmpeg -y -i audio/narration.wav -i audio/bgm.wav -filter_complex "[0:a]acompressor=threshold=-24dB:ratio=2.5:attack=10:release=180:makeup=2[n];[n][1:a]amix=inputs=2:duration=longest:normalize=0,alimiter=limit=0.88[m]" -map '[m]' -ar 48000 -ac 2 -c:a aac -b:a 192k audio/mix.m4a
ffmpeg -y -i renders/pdf-pages-video.mp4 -i audio/mix.m4a -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy -shortest renders/dronewiki-pdf-original-final.mp4
ffprobe -v error -show_entries format=duration,size:stream=codec_name,codec_type,sample_rate,channels -of default=nw=1 renders/dronewiki-pdf-original-final.mp4
