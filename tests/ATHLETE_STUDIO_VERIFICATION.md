# Athlete Studio 2.0 verification — 2026-11-10

Completed before Athlete Evolution geometry work. Delivery was paused by the user's v0.2.5 request; no commit, push or deployment occurred.

Godot 4.6.3.stable.official.7d41c59c4 Compatibility: all 332 existing native assertions and 90 new Studio assertions pass (422). Import and main-scene smoke checks pass. The matching official single-thread Web release export succeeds.

Real Chromium 156.0.8078.79: 54 core checks and 30 final compact-card/preview checks pass. Core covers both categories, origins, fields, validation, navigation, overwrite/cancel, movement, save/load, page/browser restart and schema 1/2/3 fixtures. The final run covers the corrected card, pinned content, keyboard category selection, complete saved identity/appearance and Continue. No recorded engine/JavaScript/WebAssembly/storage/network errors or warnings. The runs are separate stages, not 84 checks rerun after each intermediate change.

The card uses horizontal minimum width/no-wrap/expansion, not text rotation. One preview instance has yaw 230 degrees; static camera remains (1.8,1.65,5), size 3.3, with local -Z front about 30 degrees from the camera. Runtime front-dot-camera .864 and rear ponytail-dot-camera -.216; gameplay rotation zero. The user selected rotation-only, without new facial cues in this milestone.

Changed: creator presentation; new `scripts/ui/studio/{choice_card,choice_grid,studio_icon,player_card}.gd` and UIDs; version; mapping and focused tests; version/tab context adaptations in existing tests; design/technical/roadmap/tasks/readme/license documentation; one manual-workflow native test command. No save/catalog/gameplay/shared-model changes were part of v0.2.4.

[Raw evidence](athlete_studio_verification.json).

| View | 1280×720 | 800×600 |
|---|---|---|
| Athlete | [Screenshot](web-evidence/studio-01-athlete-1280.png) | [Screenshot](web-evidence/studio-01-athlete-800.png) |
| Story | [Screenshot](web-evidence/studio-02-story-1280.png) | [Screenshot](web-evidence/studio-02-story-800.png) |
| Hair | [Screenshot](web-evidence/studio-03-hair-1280.png) | [Top](web-evidence/studio-03-hair-top-800.png), [bottom](web-evidence/studio-03-hair-bottom-800.png) |
| Skin | [Screenshot](web-evidence/studio-03-skin-1280.png) | [Screenshot](web-evidence/studio-03-skin-800.png) |
| Body | [Screenshot](web-evidence/studio-03-body-1280.png) | [Bottom](web-evidence/studio-03-body-bottom-800.png) |
| Identity | [Screenshot](web-evidence/studio-04-identity-1280.png) | [Screenshot](web-evidence/studio-04-identity-800.png) |
| Legacy | [Top](web-evidence/studio-05-legacy-top-1280.png), [bottom](web-evidence/studio-05-legacy-bottom-1280.png) | [Top](web-evidence/studio-05-legacy-top-800.png), [bottom](web-evidence/studio-05-legacy-bottom-800.png) |

Native layout checks cover 800×600,1024×600,1280×720,1366×768,1920×1080. Windows 10/4 GB hardware performance, other browsers, screen readers, zoom, live hosting and denied/private/quota storage remain untested. Manual-only Pages workflow was not dispatched.
