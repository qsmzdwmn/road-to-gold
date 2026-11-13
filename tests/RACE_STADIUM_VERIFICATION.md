# v0.5.0 race balance, camera and Stadium 1.0 verification

Review date: 2026-11-12. Work remains uncommitted on `feature/v0.5.0-stadium-rebuild`, branched from the race development branch. HEAD/main baseline is `27e2a3c2053a5c8e1d3151257e4389b1de66dfcc`. No commit, push, merge, workflow dispatch or deployment was performed. Experimental branch remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58`.

## Balance investigation

The pre-refinement SHA-256 baseline matches the current sprint physics, input, session, AI roster, classification, repository, Training rules/state, creator, Player Card and sandbox input/movement files. No balance changes were needed. Appearance/category/origin do not enter the sprint formulas. Recovery still acts through Training rather than direct sprint speed.

Controlled native runs used attributes 50.00, fatigue 0, seed 123, identical 0.200s reaction, Hold continuously pressed or ideal alternating rhythm every 15 physics ticks. Both modes reach effort 1.0 and produce identical runner states and times. These are simulation seconds; the UI rounds displayed hundredths upward.

| Athlete | Hold finish | Ideal Rhythm finish | Place in either run |
| --- | ---: | ---: | ---: |
| Owen Ash | 12.409118 | 12.409118 | 1 |
| Player | 12.471338 | 12.471338 | 2 |
| Noah Vale | 12.613381 | 12.613381 | 3 |
| Adam Reed | 12.732463 | 12.732463 | 4 |
| Luca Stone | 12.810102 | 12.810102 | 5 |
| Leo March | 12.903605 | 12.903605 | 6 |
| Eli Rowan | 13.003984 | 13.003984 | 7 |
| Kai Mercer | 13.150785 | 13.150785 | 8 |

The questioned screenshot's actual console log recorded `reaction_us=1983333`, with one valid Hold press. The driver captured a starting-line screenshot before sending that press; screenshot/render overhead delayed input. Replaying that reaction at full effort gives **47.678m at 8.35s**, finish **14.254671s**, place **8**. With a 0.200s reaction, distance at the same instant is **64.238m**. This reproduces the screenshot without a sprint defect or dropped Hold input. The driver now presses immediately after observing GO and captures afterwards. Real browser input timing is reported separately from ideal controlled inputs.

## Presentation fixes and camera

The shared procedural model originally had no running animation. Race-only hip/shoulder pivots now swing the original arm/hand/leg/shoe meshes according to actual simulated speed, with opposing strides, small acceleration lean and smooth idle easing. No skeleton, shared-model change, new appearance IDs or save fields were added. Static head/hair/clothing stay batched. Two shared cube MultiMeshes render 48 skin pieces and 16 shoes for eight categorized runners. Unknown legacy previews retain the original neutral static model until explicit category selection.

Actual Web renders exposed a stale/misrendered limb-upload path. A fresh packed transform/color buffer per frame and resource-level MultiMesh bounds keep limbs at their moving bodies. Native tests validate immutable prior uploads; a real Chromium image assertion checks visible legs at the player position beyond 50m. This fixes apparent body size without changing sprint balance or the approved camera composition.

The lower player-follow camera remains primary. It binds to the player's actual distance, not the leader. Measured projected 1.8m body height stays equal at start and while trailing: **85.8px at 1280×720; 71.5px at 800×600**. The gold `YOU · L4` overlay follows the projected player position. It does not zoom out to force the entire separated field into view. Optional `Stadium View` is available only during readiness; Ready immediately cuts to the lower camera with no delay. The approved compact navy HUD is preserved.

The stadium uses one coherent decorative oval joined tangentially to the original straight. Active sprint lane centres remain `x=lane−3.5`, start `z=0`, finish `z=−100`. Curve and straight markings share boundary positions. The visible 14m extensions are joined sprint run-in/run-out chutes. The oval is stylized, not a certified 400m course. A material/index batching defect that hid the bends was corrected by explicitly indexing arc meshes before append. The outer light strip is an intentional solid perimeter concourse, not a missing mesh, crack or sky hole.

## Actual verification

- **993 native assertions passed**, including all 869 existing assertions and 124 race/stadium/animation assertions; import and 120-frame main-scene smoke also passed. No warnings/errors in those completed headless suites. New cases cover exact baseline times, category parity, attribute/fatigue effects, equal effort ceilings, repeat/spam rejection, false starts, GO-relative reaction, DNF/ties, eight render-instance distance bindings, camera projection, animated shoe contact, neutral legacy previews, table layout and safe persistence.
- **27 checks passed in the final focused Chromium runs**: 10 trailing/optional-view/Hold/leg-render/Escape/restart checks; 12 explicit legacy-category/byte-original backup/female race/reload/future-save protection checks; 5 final Rhythm-at-800/save/results checks. Chromium **156.0.8078.79**, real WebGL2 via SwiftShader. Both result resolutions captured. No recorded engine/JavaScript/WebAssembly/storage/network warnings or errors in these completed runs.
- An additional earlier successful 16-check full Hold/Rhythm/false-start/results/reload run supplied the motion recording. It is not added to the 27 final-export checks. Earlier failed layout/driver/renderer experiments are not counted as passing tests.
- Official **Godot 4.6.3.stable.official.7d41c59c4**, matching **4.6.3.stable** templates: Compatibility `Web` release export succeeds with `variant/thread_support=false`. No workflow edits or deployment. Existing README HTTP-serving instructions apply; `file://` is not supported.
- Native rendered inspections on the cloud X11 software driver warn that V-Sync changes are unsupported. Dummy audio was selected for these inspections. This is separate from the warning-free headless suites and completed Chromium runs.

## Performance and limits

Controlled fresh-browser comparison: eight runners, identical fixed camera and positions, 1280×720 output, 640×360 3D viewport, 30 warm-up frames then 79 sampled intervals. Run order base/refined/refined/base; no video recording or concurrent app tests. Baseline is the coherent pre-decoration static stadium. Refinement includes infield/opposite-side details, procedural animation and 2× MSAA. This measures the combined presentation cost, not animation in isolation.

| Build | Mean frame time | Approx. FPS | p95 | Max draw calls |
| --- | ---: | ---: | ---: | ---: |
| Baseline, run 1 | 232.51ms | 4.30 | 291.6ms | 124 |
| Refined, run 1 | 324.50ms | 3.08 | 417.2ms | 131 |
| Refined, run 2 | 316.66ms | 3.16 | 414.6ms | 131 |
| Baseline, run 2 | 250.89ms | 3.99 | 323.9ms | 124 |

This software-rendered cloud result is **not a smooth-playback performance pass** and is not evidence for physical 4 GB Windows hardware. Refined architecture has 30,504 static mesh triangles in 34 batches, one 346-instance mostly static crowd, plus existing athlete bodies and two animated limb batches. V8 reports about 49.2–49.3MB JS heap in baseline samples and 10.3–10.4MB in refined samples; allocation/GC differs and these exclude total engine/WASM/GPU memory, so no total-RAM improvement is claimed. Godot's Web release static-memory monitor returns zero and is treated as unavailable.

Recommended follow-up before a performance release claim: profile a real low-end Windows WebGL2 GPU; separately measure MSAA/shadow costs and trim decoration only if measurements justify it. No geometry, lighting, HUD or balance was changed in response to this investigation.

Browser window/tab blur remains a verification limitation: automation focus emulation and earlier stalled frames prevented an independently confirmed real DOM-blur callback. Native focus-interruption tests and real Chromium Escape/long-frame interruption paths pass; the inconclusive headed-focus experiment is excluded from the 27 checks. A manual real-window focus-loss check is still recommended before release. Other browsers, screen readers and long multi-tab storage races remain unverified. Existing file tokens prevent observed stale writes but do not provide cross-tab atomic transactions; IndexedDB synchronization is asynchronous.

## Evidence

All images below are actual Godot renders. Gameplay screenshots come from real Chromium keyboard runs; wide/overhead and finish inspection are explicitly staged views of the same geometry, not proof of input timing. Delayed-start photos intentionally show a trailing player; they are not full-effort baseline results.

- [Trailing player, 1280×720](web-evidence/race-stadium/player-trailing-1280.jpg) · [800×600](web-evidence/race-stadium/player-trailing-800.jpg)
- [Readiness, primary camera](web-evidence/race-stadium/readiness-1280.jpg) · [800×600 primary view](web-evidence/race-stadium/readiness-800.jpg) · [optional stadium view](web-evidence/race-stadium/readiness-stadium-1280.jpg) · [800×600 optional view](web-evidence/race-stadium/readiness-stadium-800.jpg)
- [Starting line during real gameplay](web-evidence/race-stadium/start-1280.jpg) · [running field](web-evidence/race-stadium/mid-race-1280.jpg)
- [Results, 1280×720](web-evidence/race-stadium/results-1280.jpg) · [800×600](web-evidence/race-stadium/results-800.jpg) · [final Rhythm results](web-evidence/race-stadium/results-rhythm-800.jpg)
- [Wide perspective, both stands](web-evidence/race-stadium/wide-1280.png) · [overhead](web-evidence/race-stadium/overhead-1280.png) · [finish-line inspection](web-evidence/race-stadium/finish-inspection-1280.png)
- [Five-second real Chromium motion clip](web-evidence/race-stadium/race-motion.mp4). Encoded video frame rate is not an engine FPS measurement.
- [Raw final checks, balance and performance](race_stadium_verification.json) · [controlled race rows](race_balance_comparison.json).

## Modified-file summary

Production integration: `project.godot`, `scripts/app/main.gd`, `scripts/persistence/prototype_save_repository.gd`, `scripts/ui/hub/career_hub.gd`. New race scenes: `scenes/race/race_course.tscn`, `scenes/race/race_screen.tscn`. Race modules: `sprint_physics.gd`, `sprint_input.gd`, `race_roster.gd`, `competition_data.gd`, `race_session.gd`, `race_course.gd`, `race_world.gd`, `static_mesh_batch.gd`, `race_animation.gd`, `race_limb_batch.gd`. UI: `scripts/ui/race_screen.gd`, `race_leaderboard.gd`. New focused tests: `race_simulation_test.gd`, `race_persistence_test.gd`, `race_integration_test.gd`, `stadium_environment_test.gd`, `race_animation_test.gd`; `golden_menu_test.gd` only updates expected version. Documentation: README, GAME_DESIGN, TECHNICAL_DESIGN, ROADMAP, TASKS and this report/evidence. New GDScripts include generated UID sidecars.

Athlete Studio, Player Card, shared character/hair sources, Training, sandbox, branding, export preset and deployment workflow are unchanged. Await visual/functional approval; do not commit, push, merge or deploy.
