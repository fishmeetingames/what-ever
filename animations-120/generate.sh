#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
output_dir=$PWD
task_tmp=$(mktemp -d)
trap 'rm -rf "$task_tmp"' EXIT

for name in "${@:-idle angry happy}"; do
  # No arguments exports all three; explicit arguments select animations.
  for animation in $name; do
    mkdir -p "$task_tmp/$animation"
    frame_dir="$task_tmp/$animation"
    magick "../$animation-strip.png" +repage -crop 6x1@ +repage "$frame_dir/key-%02d.png"
    for i in $(seq 0 23); do
      source_id=$(printf '%02d' "$((i % 6))")
      target_id=$(printf '%02d' "$i")
      ln -s "key-$source_id.png" "$frame_dir/frame-$target_id.png"
    done
    # Interpolate repeated cycles, then take a middle cycle so the seam has
    # motion-estimation context on both sides. Preserve RGBA transparency.
    ffmpeg -hide_banner -loglevel error -y -filter_threads 2 \
      -framerate 3 -i "$frame_dir/frame-%02d.png" \
      -vf 'format=yuva444p,minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:mb_size=8:vsbmc=1:scd=none,format=rgba,trim=start_frame=120:end_frame=240,setpts=PTS-STARTPTS' \
      -frames:v 120 -fps_mode passthrough -threads 2 "$frame_dir/out-%03d.png"
    count=$(find "$frame_dir" -name 'out-*.png' -type f | wc -l)
    test "$count" -eq 120
    magick montage "$frame_dir"/out-*.png -tile 12x10 -geometry 280x360+0+0 \
      -background none +repage "$output_dir/$animation-120-sheet.png"
    ffmpeg -hide_banner -loglevel error -y -framerate 60 \
      -i "$frame_dir/out-%03d.png" -frames:v 120 -c:v libwebp_anim \
      -lossless 1 -compression_level 4 -loop 0 "$output_dir/$animation-120.webp"
    printf '%s: exported 120 frames\n' "$animation"
  done
done
