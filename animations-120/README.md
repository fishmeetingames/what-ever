# Rabbit animations — 120 frames each

Three transparent animation sprite sheets and looping WebP previews:

| Animation | Sprite sheet | Preview |
| --- | --- | --- |
| Idle | [idle-120-sheet.png](idle-120-sheet.png) | [idle-120.webp](idle-120.webp) |
| Angry foot tapping | [angry-120-sheet.png](angry-120-sheet.png) | [angry-120.webp](angry-120.webp) |
| Happy bounce | [happy-120-sheet.png](happy-120-sheet.png) | [happy-120.webp](happy-120.webp) |

Each sheet contains **120 frames**, arranged in **12 columns × 10 rows**, with no padding. Each frame is **280 × 360 pixels**, making each sheet **3360 × 3600 pixels**. Read left to right, then top to bottom. Play at **60 fps** for a **2-second loop**.

These are motion-interpolated expansions of the six original poses per animation, not 120 individually drawn poses. Optical-flow interpolation smooths transitions, but some deformation or edge artifacts can remain around fast-moving ears, paws, and facial features.

`sprites.json` contains frame rectangles and playback information for importing into a game engine. Existing six-frame source strips in the repository root are retained.

To reproduce the exports, install FFmpeg (with `minterpolate` and `libwebp_anim`) and ImageMagick 7, then run `bash animations-120/generate.sh` from the repository root. To regenerate only one animation, append `idle`, `angry`, or `happy`.

On GitHub, open a PNG and use **Download raw file** to save the full-resolution image. Repository ZIP downloads include all three sheets and previews.
