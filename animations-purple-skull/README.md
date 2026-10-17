# Purple skull — magical idle loop

A calm animation based on the supplied purple skull emblem: gently drifting purple smoke and a soft skull glow, with the gold frame and red decorations held still. The eight key poses were generated from the reference, so this is a recreation rather than a pixel-exact edit of the original artwork.

![Animated purple skull](purple-skull.gif)

- [Animated WebP](purple-skull.webp): lossless, looping, 60 fps, recommended for playback.
- [MP4](purple-skull.mp4): 60 fps H.264 video for editing and sharing; enable looping in the player.
- [GIF](purple-skull.gif): 20 fps looping preview with reduced color precision. Use WebP or MP4 for the smoothest playback.
- [Sprite sheet](purple-skull-sheet.png) and [frame metadata](sprites.json): game-engine import.
- [Still poster](poster.png) and [eight generated key poses](keyframes.png).

The animation contains **360 frames at 60 fps**, for a **six-second loop** at **384 × 512 pixels** on a **black background**. The sprite sheet is **7680 × 9216 pixels**, with 20 columns and 18 rows, read left to right and top to bottom. The GIF preview uses 120 frames at 20 fps. WebP/GIF timing is rounded to whole milliseconds/centiseconds. Transparency is not included.

Compared with the first version, motion is three times slower and the changing layer contributes only 25% of the final image. A weighted temporal filter softens transitions across the loop seam. The GIF uses a fixed dithering pattern to reduce flickering grain.

To regenerate, use ImageMagick 7 and FFmpeg with `minterpolate`, `libwebp_anim`, and `libx264`:

```bash
cd /workspace/what-ever
bash animations-purple-skull/generate.sh
```

The script overwrites only the generated files in this directory. It crops the eight key poses, holds non-purple regions static with a shared color mask, and interpolates repeated cycles with optical flow. It then slows the cycle, applies weighted smoothing over seven frames with loop context on both sides, blends intermediate frames at 60 fps, and mixes 25% of the moving layer with 75% of the still image. It exports the middle cycle for a continuous loop. Subtle interpolation artifacts can remain in the smoke.
