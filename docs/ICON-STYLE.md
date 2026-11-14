# ASR icon style

These four icons were approved by the project owner on 2026-11-14. Use them as the visual references for future ASR addons. Preserve this family rather than inventing a new visual direction for every module.

## Approved artwork

The master PNG files are in `assets/branding/icons/`:

| Addon | File | Symbol |
| --- | --- | --- |
| Advisor | [asr-advisor.png](../assets/branding/icons/asr-advisor.png) | Three green gemstone nodes joined by a branching silver path |
| Stats | [asr-stats.png](../assets/branding/icons/asr-stats.png) | Three ascending bars inside a silver crest |
| Combat Text | [asr-combat-text.png](../assets/branding/icons/asr-combat-text.png) | Silver lightning bolt over green impact streaks |
| Suite | [asr-suite.png](../assets/branding/icons/asr-suite.png) | Three connected metal panels around a central green gemstone |

All four masters are 1254 × 1254 RGBA PNGs. Keep these masters unchanged; export runtime sizes or formats as separate files when needed. The artwork is approved, but has not yet been wired into the addons or the catalogue. Adding it here does not change an existing release ZIP.

## Shared appearance

- Square tile with a thin silver/gunmetal perimeter frame and chamfered outer corners. Preserve the square and the metal frame.
- Dark charcoal textured background **inside** the frame. This background stays in the finished icon.
- Transparency **only outside** the outer frame silhouette, including the exterior corner triangles. Do not remove the interior dark background, the frame, or negative spaces within the tile.
- Central emblem of chunky beveled silver metal, with dark side faces and bright silver-white edge highlights. Restrained hand-painted fantasy RPG inventory-icon finish.
- ASR brand accent: lime green `#8CD123`, rendered as luminous gemstone faces or inlays with brighter highlights. Match the approved PNG references for the actual shaded appearance.
- One clear symbol per module. Center it, let it occupy most of the tile, and keep it readable at 32 × 32 and 64 × 64.
- No lettering, numbers, addon names, watermarks, scenery, characters, copied game logos, or tiny decorative clutter.
- Match border thickness, bevel depth, lighting, charcoal texture and green treatment across the family. Use an existing approved PNG as a style reference when generating a new icon.

## Reusable generation prompt

Use the approved icons as **style references**, not as edit targets when creating a new module's symbol. Replace only the subject placeholder below.

> Create ONE original square ASR fantasy RPG addon icon. Match the attached approved ASR icon family: a thin silver/gunmetal square perimeter frame with chamfered outer corners, a dark charcoal textured background INSIDE the frame, and a bold central emblem made of chunky beveled silver metal with vivid lime green #8CD123 luminous gemstones or inlays. Preserve the established frame proportions, controlled highlights, dark side faces and restrained hand-painted inventory-icon finish. Subject: [a single clear symbol representing the new addon's function]. Center the emblem and make its silhouette immediately readable at 32x32 and 64x64. Keep the entire square tile interior opaque, including the dark background and spaces between emblem parts. Genuine transparent alpha ONLY OUTSIDE the outermost frame silhouette, including exterior corner triangles. No text, numbers, watermark, scenery, floor, exterior cast shadow, or existing game logos. Do not remove the square frame or the dark interior background.

For the built-in image generation tool, set `transparent_background: true` and explicitly retain the interior background in the prompt. Inspect the result before accepting it: that option alone does not establish which areas should be transparent.

## Acceptance checks

1. Frame, dark interior and central symbol are all present.
2. Exterior corners have genuine transparency, without a painted checkerboard or a rectangular black surround.
3. Interior spaces retain the dark background; the icon is not an isolated emblem or an empty frame.
4. The symbol reads at small UI sizes and remains distinguishable from the four existing icons.
5. Compare against the approved masters rather than relying on the written prompt alone.

The approved masters were generated and edited using the built-in image generation tool. They are original ASR artwork, not extracted game textures. Catalogue support for custom uploaded images must be checked separately; a field accepting built-in game icon names does not imply support for these PNGs.
