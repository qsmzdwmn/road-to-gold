# Asset provenance
All track and athlete geometry and UI styles are original procedural primitives made for ROAD TO GOLD. Apart from the approved owner-supplied branding described below, no external art, audio, fonts or commercial assets are included. The UI uses Godot's bundled default font; engine-bundled components retain their upstream licenses. No official sporting branding is used.

The ROAD TO GOLD track-mark icon (`assets/branding/road_to_gold.svg`) and HTML loading screen are original project artwork/styles. Removing startup branding does not change Godot's licensing: retain Godot's MIT license and applicable third-party notices when distributing the engine. Official license information: https://godotengine.org/license/ and https://docs.godotengine.org/en/4.6/about/complying_with_licenses.html .

Version 0.2's athlete preview geometry and hair are original procedural primitives. Country labels/codes and origin descriptions are a small authored factual text catalog, without downloaded art, flags or official sporting branding. No large external assets or runtime dependencies were added.

## Version 0.2.3 approved branding
The project owner supplied and approved `golden_path_full.png` and `golden_path_emblem.png` verified on main at c085d57. These source PNGs and the supplied ZIP are kept unchanged. `golden_path_full_ui.png` and `golden_path_emblem_ui.png` are aspect-preserving, lossless PNG derivatives: fully transparent outer padding is cropped to the alpha bounding box, then the artwork is resized without recoloring or redrawing. `golden_path_icon.png` fits the emblem into a transparent square without stretching. Source SHA-256 hashes, crop rectangles and derivative dimensions are recorded in `assets/branding/golden_path_manifest.json` and asserted by native tests.

Only the optimized derivatives are used at runtime. Original full-resolution images and the archival ZIP are excluded from Web exports. The small emblem embedded in `web/loading.html` is derived from the same approved icon. No new official title, third-party art download, font, commercial service, sporting affiliation or external dependency is introduced. The Golden Road geometry and the 64×64 radial light gradient are generated procedurally. Godot's license and third-party attribution obligations above remain in force.

Version 0.2.4 adds original procedural 2D category/origin/hair pictograms and two tiny generated slider-grabber textures. These are UI-only primitives, without external art/font downloads. Official branding masters and the existing 3D model/environment are unchanged.

The v0.2.4.1 review build adds original procedural hairstyle meshes and category-specific 2D hair pictograms. No external assets, textures, fonts, Blender prototypes or paid dependencies are used.
