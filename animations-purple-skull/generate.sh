#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export MAGICK_THREAD_LIMIT=2
export OMP_NUM_THREADS=2
task_tmp=$(mktemp -d)
trap 'rm -rf "$task_tmp"' EXIT
export XDG_CACHE_HOME="$task_tmp/cache"
mkdir -p "$XDG_CACHE_HOME"

# Eight generated phases, read left to right, top to bottom.
magick keyframes.png -crop 384x512 +repage "$task_tmp/key-%02d.png"
# Keep the gold frame and red ornaments fixed. Only purple regions animate.
for i in $(seq 0 7); do
  key=$(printf '%02d' "$i")
  magick "$task_tmp/key-$key.png" -fx 'b>0.22 && b>g*1.45 && b>r*0.9 ? 1 : 0' "$task_tmp/mask-$key.png"
done
magick "$task_tmp"/mask-*.png -evaluate-sequence max \
  -morphology Dilate Disk:2 -blur 0x1 "$task_tmp/mask.png"
for i in $(seq 0 7); do
  key=$(printf '%02d' "$i")
  magick "$task_tmp/key-$key.png" "$task_tmp/mask.png" \
    -alpha off -compose CopyOpacity -composite "$task_tmp/layer.png"
  magick "$task_tmp/key-00.png" "$task_tmp/layer.png" \
    -compose Over -composite "$task_tmp/phase-$key.png"
done
# Repeat the loop to give optical flow context on both sides of the seam.
for i in $(seq 0 23); do
  source_id=$(printf '%02d' "$((i % 8))")
  target_id=$(printf '%02d' "$i")
  ln -s "phase-$source_id.png" "$task_tmp/input-$target_id.png"
done
ffmpeg -hide_banner -loglevel error -y -filter_threads 2 \
  -framerate 4 -i "$task_tmp/input-%02d.png" \
  -vf 'minterpolate=fps=30:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:mb_size=8:vsbmc=1:scd=none,trim=start_frame=60:end_frame=120,setpts=PTS-STARTPTS' \
  -frames:v 60 -fps_mode passthrough -threads 2 "$task_tmp/smooth-%03d.png"
test "$(find "$task_tmp" -name 'smooth-*.png' -type f | wc -l)" -eq 60
# Reapply the static border after interpolation so it cannot drift.
for i in $(seq 1 60); do
  frame=$(printf '%03d' "$i")
  magick "$task_tmp/smooth-$frame.png" "$task_tmp/mask.png" \
    -alpha off -compose CopyOpacity -composite "$task_tmp/layer.png"
  magick "$task_tmp/key-00.png" "$task_tmp/layer.png" \
    -compose Over -composite "$task_tmp/out-$frame.png"
done
ffmpeg -hide_banner -loglevel error -y -framerate 30 \
  -i "$task_tmp/out-%03d.png" -frames:v 60 -c:v libwebp_anim \
  -lossless 1 -compression_level 4 -loop 0 purple-skull.webp
ffmpeg -hide_banner -loglevel error -y -framerate 30 \
  -i "$task_tmp/out-%03d.png" -frames:v 60 -c:v libx264 \
  -crf 18 -pix_fmt yuv420p -movflags +faststart -threads 2 purple-skull.mp4
ffmpeg -hide_banner -loglevel error -y -framerate 30 \
  -i "$task_tmp/out-%03d.png" \
  -filter_complex_threads 2 \
  -filter_complex '[0:v]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a' \
  -loop 0 purple-skull.gif
magick montage "$task_tmp"/out-*.png -tile 10x6 -geometry 384x512+0+0 \
  -background black +repage purple-skull-sheet.png
cp "$task_tmp/out-001.png" poster.png
printf 'Exported 60 frames at 30 fps: WebP, MP4, GIF, and sprite sheet.\n'
