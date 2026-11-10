# Model review scene

Run `godot --path . res://tests/visual/athlete_showcase.tscn` for the current model. Keys 1/2/3 show front/side/three-quarter by rotating only the review instances, H cycles hairstyles, C hair colors, S skin tones. This scene never writes saves. Production creator and gameplay cameras are untouched.

Both models are 180 cm, 75 kg, shoulders/legs 1.0. Male on the left uses Cropped/Black/Tone 3; female on the right uses Ponytail/Black/Tone 5. Orthographic camera at (0,1.05,-5), looking at (0,1.05,0), size 2.35. Identical ambient and directional lighting are defined in the script. Screenshots use 1280×900.

`reference_pre_anatomy.gd` freezes the initial v0.2.5 geometry parameters (before Anatomy Polish, not the older block mannequin). It was reconstructed from the initial implementation parameters for fresh matched re-renders; it is not evidence of a separate historical commit. A test-only project copy substitutes it for `scripts/customization/procedural_athlete.gd`, keeping the review scene, camera and all customization identical.

For browser review, use a disposable project copy, change only that copy's main scene to this scene and remove `tests/*` from that copy's export exclusions. Export with matching official 4.6.3 templates and serve over HTTP. Production preset continues excluding all test files and has its original main scene. Do not edit the production camera or export preset to run review comparisons.

The Web review scene publishes `window.athleteReviewMetrics` (triangle counts, material surfaces, rebuild count, appearance/material colors, frame deltas and whole-viewport renderer counters). This hook is excluded from the production build. Frame samples from Chromium SwiftShader are software-renderer observations, not a benchmark of Windows 10/4 GB graphics hardware.
