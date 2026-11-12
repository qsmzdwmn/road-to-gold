> Historical implementation/review evidence. Visual approval has now been received; see [finalization](CAREER_HUB_FINALIZATION.md) for final checks and PR scope.

# v0.3.0 Career Hub — initial review build

The subsequent [UI polish report and fresh screenshots](CAREER_HUB_UI_POLISH.md) supersede the initial visual evidence below.

## Repository boundary

Based on released main/origin/main `e88438ac27a2a8d96a21807e0daf440fe151d57b` (v0.2.4.1); isolated on `feature/v0.3.0-career-hub`. No commit, push, merge, deployment or workflow dispatch. Experimental branch remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58`; no Blender files integrated. See [audit](CAREER_HUB_AUDIT.md).

## Implemented behavior

Begin Career still validates and confirms replacement through the original creator/repository before writing; successful creation now opens Hub. Continue opens Hub for schema 2/3 careers, original track for position-only schema 1. Overview shows the actual saved name, country, category, origin and starting age. My Athlete reuses the unchanged Player Card and static stable model/room. Sidebar pages and Settings work with mouse/keyboard; unavailable training/calendar/records have explicit information-only states. The movement sandbox remains reachable and returns through Career HQ.

No extra career is created, no progression/competition/record fields are invented and no save schema changes. Hub viewing is read-only; explicit Save & Menu preserves the career and track position. Missing/replaced slots are guarded before saving. This guard is not an atomic multi-tab conflict-resolution system.

## Native verification

Official `4.6.3.stable.official.7d41c59c4`. Editor import and main-scene headless startup pass. **708 assertions pass**: all 521 baseline assertions retained with expected new landing-state/sandbox-entry adaptations, plus 185 Hub assertions and 2 separate-process Hub reload assertions. Coverage includes male/female × all three origins, exact saved appearance/identity/age, original overwrite protection, read-only navigation, shared Settings return, responsive bounds/scrolling/keyboard focus, movement position, schema 1/2/3, legacy hair/category preservation, invalid/future/missing/replaced save protection. Test data is isolated outside interactive user storage.

SHA-256 checks confirm byte-identical creator, Player Card, save repository, career/appearance data, hairstyle catalog, procedural athlete/hair and locker room. [Results](web-evidence/career-hub-0.3.0/native-results.json) · [preservation checks](web-evidence/career-hub-0.3.0/protected-results.json).

## Web and Chromium verification

Matching official `4.6.3.stable` single-thread templates; existing Compatibility Web release preset exports successfully. Generated files total **38,483,011 bytes**, uncompressed. The exported pack reports version 0.3.0, stable production model present and no experimental prototype/GLB directory. Exported binaries remain outside source control. The manual-only Pages workflow gains the Hub test commands; its deployment gate is unchanged and it was not run.

Real local Chromium **156.0.8078.79** (headless, software-rendered SwiftShader) loads the exported build over HTTP. Mouse/keyboard tests exercise the complete female Chosen One creator flow, actual saved values, Overview/My Athlete, 1280×720 and 800×600 scrolling, all sidebar pages, shared Settings, Escape/menu/Continue, Save & Menu, page reload, complete browser restart, track movement and return to HQ. A second isolated browser creates a male Legacy career and loads From Nothing legacy fixtures. Schema 2 remains category-unselected with original Ponytail ID; explicit saving retains schema 2. Schema 1 continues to the existing track without an invented athlete. Legacy fixtures are seeded into the isolated browser IndexedDB slot, then loaded through the real application; no runtime game-state injection is used. No recorded engine/JavaScript/WebAssembly/storage/network errors or warnings in these runs.

**52 browser checks pass** (34 final flow checks + 18 male/legacy checks). [Final browser results](web-evidence/career-hub-0.3.0/browser-verification.json) · [legacy results](web-evidence/career-hub-0.3.0/browser-legacy-verification.json). Browser logs and screenshots below provide the exact checks. The main flow writes genuine saves using the UI; browser IndexedDB is read for assertions. Persistence is verified on this localhost origin/profile, not across hosts or devices.

## Screenshots (actual Chromium, exported game)

- [Overview 1280×720](web-evidence/career-hub-0.3.0/hub-overview-1280.png)
- [Overview 800×600 top](web-evidence/career-hub-0.3.0/hub-overview-800-top.png) · [bottom](web-evidence/career-hub-0.3.0/hub-overview-800-bottom.png)
- [My Athlete 1280×720](web-evidence/career-hub-0.3.0/hub-my-athlete-1280.png)
- [My Athlete 800×600 top](web-evidence/career-hub-0.3.0/hub-my-athlete-800-top.png) · [bottom/preview](web-evidence/career-hub-0.3.0/hub-my-athlete-800-bottom.png)
- [Male profile](web-evidence/career-hub-0.3.0/male-my-athlete-1280.png) · [uncategorized legacy profile](web-evidence/career-hub-0.3.0/legacy-my-athlete-1280.png)
- [Creator final Player Card preserved](web-evidence/career-hub-0.3.0/creator-legacy-unchanged.png)

## Changed files

New: `scenes/ui/career_hub.tscn`, `scripts/ui/hub/career_hub.gd` (+ Godot UID), `tests/career_hub_test.gd` (+ UID), audit/verification documents and `tests/web-evidence/career-hub-0.3.0/`.

Updated: `project.godot` (review version/description), `scripts/app/main.gd` (routing/save guard/settings return), `scripts/ui/prototype_ui.gd` (shared Settings return and Career HQ sandbox button); `tests/prototype_test.gd`, `career_creation_test.gd`, `category_support_test.gd`, `golden_menu_test.gd`, `athlete_studio_test.gd` (retain assertions, update intended routing/version); `.github/workflows/web-pages.yml` (manual build test coverage); `README.md`, `GAME_DESIGN.md`, `TECHNICAL_DESIGN.md`, `ROADMAP.md`, `TASKS.md`.

## Limitations / approval gate

No training, calendar scheduling, records, race simulation, career progression or editable profile is implemented. Long dashboard/profile pages scroll at 800×600. Overview is 2D; My Athlete allocates one lazy stable preview and pauses it when hidden. No new heavy assets or shaders. This cloud software-rendered run is not a benchmark of Windows 10 hardware with 4 GB RAM; no FPS/RAM guarantee, physical-device, other-browser or screen-reader verification is claimed. Browser storage remains profile/origin-scoped and may be cleared by the browser. Full multi-tab handling and backup/export are future work.

Await user visual and functional approval. Nothing committed, pushed, merged or deployed.
