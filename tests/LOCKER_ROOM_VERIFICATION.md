# Version 0.2.2 — THE LOCKER ROOM verification

Date: 2026-11-09. Baseline inspected/fetched: main at `328a71f`.

## Native and export

Godot `4.6.3.stable.official.7d41c59c4`, Linux headless, Compatibility. Official template marker `4.6.3.stable`, `web_nothreads_release.zip`. No new downloads or dependencies were required.

Import and a 120-frame main-scene smoke check pass. All **260 native assertions pass**, including all 198 baseline assertions (only title/step navigation adapted) and 62 new checks. No warnings/errors were logged in the final actual-checkout runs.

| Suite | Assertions |
| --- | ---: |
| Prototype integration + separate-process reload | 35 + 1 |
| Career creation + separate-process reload | 81 + 2 |
| Category support + separate-process male/female reload | 77 + 2 |
| Locker room | 62 |

The new suite checks step order, identity validation, final action, both models' four proportional controls and four hairstyles, refined body details, fixed camera on all five steps at four viewport sizes, maximum-body framing, bounded room geometry and unchanged legacy details. Existing suites retain the six category/origin combinations, all data validation boundaries, Back/Continue retention, keyboard movement, confirmation/authorization, malformed/future-save protection and schema 1/2/3 compatibility.

Commands from project root:

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
godot --headless --path . --export-release Web builds/web/index.html
python -m http.server 8000 --directory builds/web
```

Use a disposable user-data directory/profile for regression tests. Linux cloud checks used writable XDG config/cache/data directories under `/workspace/work`; test fixtures use `user://tests/`, separate from the real slot. Tests do not need these particular cloud paths on Windows.

Single-thread Web export succeeds from both the source working copy and actual Git checkout. The Web preset/loading shell and existing logo assets are unchanged. The manual Pages workflow adds only the new native suite; it was not dispatched and no deployment was performed.

## Chromium

**135 real Chromium checks pass** across staged Playwright runs: 120 flow/persistence/responsive checks and 15 final keyboard/menu checks against the Git checkout's exported build. Chromium `156.0.8078.79`, Linux headless with SwiftShader software WebGL 2. The main build was served under `http://127.0.0.1:8001/road-to-gold/index.html` to exercise a Pages-style subdirectory; the final checkout export was served separately at `http://127.0.0.1:8002/index.html`.

Verified both full category paths; every origin on each path; visible changes from all seven appearance controls; invalid blank names; origin-derived age; accurate summary; full Back/Continue draft retention; replacement cancellation/acceptance; all schema-3 fields; real W-key movement; Continue after page reload; full browser restart durability; and schema-1/schema-2 copied legacy profiles. Legacy Continue leaves bytes unchanged, position saves retain schema/career, and v2 remains explicitly uncategorized. No save data was injected into the app: old browser profiles were copied for legacy checks and IndexedDB was inspected read-only.

All five steps navigated at **800×600, 1024×600, 1280×720, 1366×768 and 1920×1080**. Final checkout checks exercise Settings/Back, keyboard New Career, explicit category selection, origin selection, dropdown selection, offscreen-field focus scrolling, Escape from navigation focus, returning to the menu, 800px Settings and no draft writes.

No recorded Godot/JavaScript/WebAssembly/browser-storage errors, console warnings, failed requests or HTTP errors in the completed runs. Screenshot OCR needed sparse/raw fallbacks for wrapped or highlighted labels; actual screenshots were reviewed. Keyboard checks use normal widget semantics: arrow selection relative to the current option, and Tab to navigation before top-level Escape. No product code was changed to accommodate OCR assumptions. Raw assertions and console/network observations: [locker_room_verification.json](locker_room_verification.json).

## Save contract

No migration or new field is needed. Existing schema 3 careers retain category, origin, derived age, names, country, appearance and track position. Schema 1 track sessions and schema 2 careers retain their formats. Continue never rewrites a legacy file or invents a missing category; position saves preserve category absence. The selected-category refinements are visual only; neutral legacy geometry/materials remain unchanged. Explicit confirmation is still required to replace any existing slot, and cancellation retains the old save and editable draft.

## Limits

Functional browser checks use local HTTP and software WebGL 2 on Linux, not the live HTTPS deployment or Windows 10 / 4 GB hardware. No FPS/memory improvement is claimed. Additional browsers, human keyboard/layout accessibility, screen readers, browser zoom, denied/private/quota/eviction storage and multi-tab conflicts remain unverified. The game remains desktop-first. Back/Continue retain an in-memory draft, but page reload discards an unconfirmed draft. Browser saves remain local to their profile/origin and do not synchronize. Story progression, records and competitions remain out of scope.

## Screenshots

These are real Chromium captures, not mockups. The primary sequence shows the female path; the same room/camera and controls support both categories. QA images are excluded from Web exports.

| Step | Capture |
| --- | --- |
| 1 — Choose Your Athlete | [Athlete/category selection](web-evidence/locker-step-1.png) |
| 2 — Your Story | [Origin selection](web-evidence/locker-step-2.png) |
| 3 — Your Appearance | [Live customization](web-evidence/locker-step-3.png) |
| 4 — Your Identity | [Identity and starting age](web-evidence/locker-step-4.png) |
| 5 — Begin Your Legacy | [Summary and final action](web-evidence/locker-step-5.png) |

Additional captures: [male model](web-evidence/locker-male-preview.png), [proportion controls](web-evidence/locker-appearance-proportions.png), [800×600](web-evidence/locker-layout-800.png), [1024×600](web-evidence/locker-layout-1024.png), [1366×768](web-evidence/locker-layout-1366.png).

Keyboard scrolling evidence: [focused offscreen proportion control](web-evidence/locker-keyboard-focus.png).

## Changed files

- `project.godot`: v0.2.2 description and native window-sized UI.
- `scripts/ui/career_creator.gd`: five-step flow, local theme, responsive layout, keyboard focus scrolling, edited-number capture, shared preview integration.
- `scripts/ui/prototype_ui.gd`: version label only.
- `scripts/customization/procedural_athlete.gd`: modest selected-category geometry refinements; neutral legacy fallback retained.
- `scripts/customization/locker_room.gd` and `.uid`: static procedural set/camera.
- `tests/career_creation_test.gd`, `tests/category_support_test.gd`: step/title adaptations, original assertions preserved.
- `tests/locker_room_test.gd` and `.uid`: 62 additional native assertions.
- `.github/workflows/web-pages.yml`: one additional native-test command; no trigger/deploy changes.
- `README.md`, `GAME_DESIGN.md`, `TECHNICAL_DESIGN.md`, `ROADMAP.md`, `TASKS.md`: current design, controls, verification and limits.
- This report, `tests/locker_room_verification.json` and eleven `tests/web-evidence/locker-*.png` QA captures.

Persistence, category/data classes, catalogs, main app logic, input/movement, track scenes, Web preset/loading shell and license/branding assets are unchanged.
