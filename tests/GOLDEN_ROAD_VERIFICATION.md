# Version 0.2.3 — GOLDEN ROAD verification

Date: 2026-11-09. Latest main synchronized through `c085d57`; the v0.2.2 baseline is `409e779`. Official source logos were verified before implementation and remain unchanged.

## Final implementation

The approved Cinematic Split menu has the official full logo enlarged about 25%, intentional three-line tagline, consistent buttons and a static curved pathway with beveled edge highlights, restrained horizon depth and soft golden warmth. The path continues outside the right viewport edge. The final polish preserves the approved path geometry, logo, layout and palette; disabled Continue text is brighter and cannot receive keyboard focus until enabled. A new session says Your journey begins here. Existing careers show the stored athlete name; legacy position-only sessions receive a generic caption. Long names and messages use ellipsis with full tooltips. Failed/nonpersistent saves retain visible warnings.

The approved emblem appears in the real-progress loader, project/Web icon and existing Locker Room header. No redesign of career creation or athlete meshes is included. Investigating the apparent rear view found that local +Z (the ponytail/rear side) faced the camera. Only the creator preview instance is now rotated 180°, producing a front/slight three-quarter view on every step. Camera position/rotation/size, shared body geometry, gameplay orientation, customization data and save formats stay unchanged.

One tiny generated 64×64 radial texture supplies the static distant glow. There are no particles, bloom, volumetric fog, camera animation, forced startup delays, paid assets or runtime dependencies. Original full-resolution logo PNGs and the supplied ZIP remain in Git and are excluded from Web exports. Optimized PNG derivatives preserve transparency, geometry, typography and metallic colors through aspect-preserving crop/resize, with hashes/dimensions in the branding manifest.

## Native results

**332 assertions pass**, Godot `4.6.3.stable.official.7d41c59c4`, Linux headless, Compatibility. Import and the 120-frame main-scene smoke pass. Final native logs contain no warnings/errors.

| Suite | Assertions |
| --- | ---: |
| Original prototype + separate-process reload | 35 + 1 |
| Career creation + separate-process reload | 81 + 2 |
| Category support + separate-process reload | 77 + 2 |
| Existing Locker Room | 62 |
| New menu / branding / names / facing | 72 |

All 260 existing assertions and their test files are preserved unchanged. The new suite checks immutable original-logo hashes, derivative loading/transparency, aspect ratio, version metadata, tagline, disabled/enabled focus, actions, scene/camera switching, control bounds at five sizes, fixed camera, legacy Continue, career captions, long names, failure feedback, both preview facing directions, unchanged gameplay orientation and loading shell integration. Existing maximum-body framing, all four hairstyles, all proportions, six category/origin combinations, save protection and schema 1/2/3 coverage continue to pass.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/prototype_test.gd
godot --headless --path . --script tests/prototype_test.gd -- --reload-check
godot --headless --path . --script tests/career_creation_test.gd
godot --headless --path . --script tests/career_creation_test.gd -- --reload-career
godot --headless --path . --script tests/category_support_test.gd
godot --headless --path . --script tests/category_support_test.gd -- --reload-categories
godot --headless --path . --script tests/locker_room_test.gd
godot --headless --path . --script tests/golden_menu_test.gd
```

Tests use `user://tests/` fixtures rather than the real save slot. Cloud runs additionally isolated writable XDG config/cache/data under `/workspace/work`; these paths are not requirements on Windows.

## Real Chromium results

**129 checks pass** using Chromium `156.0.8078.79`, Linux headless, SwiftShader software WebGL 2 and real Playwright keyboard/mouse input. The build was served locally at `http://127.0.0.1:8001/road-to-gold/index.html`, exercising a Pages-style subdirectory.

The 104 core checks verify the branded loader while a real WASM request is temporarily held by QA tooling, actual increasing engine progress through completion, menu/official-logo/path rendering at **800×600, 1024×600, 1280×720, 1366×768 and 1920×1080**, static background, keyboard Settings/Back and New Career, disabled Continue traversal, validation, both full category flows, every appearance control, draft retention, accurate summary, cancellation/authorization, athlete captions, original keyboard movement, Continue, page reload and browser restart. Copies of genuine pre-update schema-1, schema-2 and schema-3 profiles load without changing saved bytes; position saving preserves schema/career, and old unknown categories remain unknown. IndexedDB was inspected read-only.

After the isolated preview-yaw correction, 25 final-build checks revisit both categories through all five steps, ponytail customization, Back/Continue retention, identical identity/summary render framing, confirmation, original gameplay entry and saving. No orientation field is added to a career. The entire native suite and Web export were also rerun after this correction. Main menu, loader, persistence code and shared athlete model were unchanged by that correction.

There are no recorded Godot/JavaScript/WebAssembly/browser-storage errors, console warnings, failed requests or HTTP errors in either completed browser run. OCR needed a neutral-text mask for focused button labels and context handling for Tone S / Tone 5; final saved appearance values verify actual choices. Raw assertions, download progress, console/network observations and export sizes are in [golden_road_verification.json](golden_road_verification.json).

## Web export and local run

Export succeeds with official matching `4.6.3.stable` single-thread templates. Compatibility, non-GDExtension, authored JSON inclusion and the existing manual-only Pages workflow remain in place. The workflow adds only the new native suite; no dispatch or deployment was performed.

```sh
godot --headless --path . --export-release Web builds/web/index.html
python -m http.server 8000 --directory builds/web
```

Open `http://localhost:8000/index.html`, never `file://`. Godot/editor Web run is another option. Confirm a disposable career, move, Save & Menu, reload and Continue, then close/reopen the same browser profile/origin to reproduce persistence checks. Do not test confirmed replacement against irreplaceable progress.

## Screenshots

All images below are real Chromium captures. Menu/loader captures remain valid after the preview-only correction because those visuals did not change. Locker Room captures show the corrected front orientation. QA images are excluded from exports.

| Capture | Screenshot |
| --- | --- |
| Menu 800×600 | [View](web-evidence/golden-menu-800.png) |
| Menu 1024×600 | [View](web-evidence/golden-menu-1024.png) |
| Menu 1280×720 | [View](web-evidence/golden-menu-1280.png) |
| Menu 1366×768 | [View](web-evidence/golden-menu-1366.png) |
| Menu 1920×1080 | [View](web-evidence/golden-menu-1920.png) |
| Saved athlete caption | [View](web-evidence/golden-menu-saved.png) |
| Branded actual-progress loader | [View](web-evidence/golden-loading.png) |
| Male front-facing summary | [View](web-evidence/golden-locker-male.png) |
| Female front-facing summary | [View](web-evidence/golden-locker-female.png) |
| Male customization | [View](web-evidence/golden-preview-male.png) |
| Female customization | [View](web-evidence/golden-preview-female.png) |

## Save and gameplay compatibility

No migration or schema update is needed. `user://prototype_v1.json` and the custom user directory are unchanged. Explicit category selection, schema 1/2/3, origin IDs/ages, country codes, appearance values, validation, replacement authorization, model geometry and original track/input/physics are unchanged. Main reads only validated names for display. The preview direction is a constant scene transform and is neither serialized nor applied to the gameplay athlete.

## Changed files

- `project.godot`: one version value, description and approved icon.
- `export_presets.cfg`: exclude master PNGs and the archival ZIP from runtime export.
- `scenes/app/main.tscn`, `scenes/menu/golden_road.tscn`, `scripts/menu/golden_road.gd` (+ UID): separate static menu set.
- `scripts/app/main.gd`: scene/camera visibility, focus availability and menu captions/save feedback presentation; no writer/data changes.
- `scripts/ui/golden_menu.gd` (+ UID), `scripts/ui/prototype_ui.gd`: branded panel and adapter to existing actions/settings/HUD.
- `scripts/branding/brand.gd` (+ UID): shared logo textures and project-derived version.
- `scripts/ui/career_creator.gd`: small header emblem and preview-only facing correction.
- `assets/branding/golden_path_full_ui.png`, `golden_path_emblem_ui.png`, `golden_path_icon.png` and their imports; original PNG import metadata; `golden_path_manifest.json`. Original source PNGs/ZIP are unchanged.
- `web/loading.html`: embedded approved emblem, palette and real indeterminate progress when total is unknown.
- `tests/golden_menu_test.gd` (+ UID), this report, raw JSON and eleven `golden-*.png` captures.
- `.github/workflows/web-pages.yml`: focused native suite added; triggers/deploy contract unchanged.
- `README.md`, `GAME_DESIGN.md`, `TECHNICAL_DESIGN.md`, `ROADMAP.md`, `TASKS.md`, `assets/licenses/README.md`: current behavior, provenance, verification and limits.

## Remaining limits

This is local Linux/software-WebGL functional verification, not a Windows 10 / 4 GB FPS/memory measurement or live HTTPS deployment test. Other browsers, screen readers, zoom, denied/private/quota/eviction storage and multi-tab conflicts remain unverified. No measured performance improvement is claimed. Browser saves remain profile/origin local; unconfirmed drafts remain session-only. No new story, progression, record or competition system is included. The main menu and loader are approved; this milestone stops after tested source delivery, with deployment manual.
