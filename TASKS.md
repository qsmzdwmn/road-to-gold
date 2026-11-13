# ROAD TO GOLD — Tasks

Status: v0.5.1 Stadium Audio has owner listening and UI approval. Final native/browser/export verification and feature-branch PR preparation are authorized. Production main remains v0.5.0. Merge and deployment require separate approval. Historical milestone results follow; current release results are in tests/V0_5_1_RELEASE_PREPARATION.md.

## Completed initialization
- [x] Inspect /workspace and search for project and AGENTS.md files; no existing project found.
- [x] Check Godot command availability and version: godot and godot4 report 4.6.3 stable. CLI warning and verification limits recorded in TECHNICAL_DESIGN.md.
- [x] Create GAME_DESIGN.md, TECHNICAL_DESIGN.md, ROADMAP.md and TASKS.md.
- [x] Define proposed folders, module boundaries, Alpha scope, acceptance criteria and risks.

## First technical milestone — Implementation 01
- [ ] T01 (partially complete): Create the minimal Godot Compatibility project and Web feasibility probe. Pin engine and matching templates; configure single-thread Web export if supported. Use a placeholder scene, one keyboard action and a disposable versioned user:// value to check export, focus and persistence. Verify reload/browser restart, report actual behavior, test on Windows 10 / 4 GB when available, and record commands/versions/host requirements. Do not start career or race systems until this gate is understood.

Done when: the project imports cleanly; a served Web export renders and receives keyboard input; save/read behavior is observed and honestly recorded; template, browser and host constraints are documented. Any unavailable Windows test remains explicitly pending. Disposable probe data must be separate from real career saves.

## Ordered implementation backlog
- [ ] T02 (after T01): Add typed data contracts and validated data-driven country/origin/race/story resources. Verify appearance cannot affect sporting attributes.
- [ ] T03 (after T02): Implement SaveRepository schema v1, backup/recovery, migration boundary, failure reporting, revision handling and JSON export/import. Exercise corrupt, future-version and denied-storage paths.
- [ ] T04 (after T02–T03): Build app navigation and keyboard-operable creator with procedural preview, origin selection, introductory choices and hub. Verify all three origins and saved consequences.
- [ ] T05 (after T01–T02): Implement simulation independent of visuals: start states, valid input intents, reaction, bounded acceleration, stamina, rhythm, 100m crossing and seed. Verify known finish cases and equivalent simulation at varied rendering rates.
- [ ] T06 (after T05): Add player input edge/alternation filtering, remapping and focus pause/resume. Verify held keys, repeats and false starts.
- [ ] T07 (after T05): Add seven seeded AI controllers and low-cost runner/track visuals. Verify all eight finish or receive explicit DNF without blocking results.
- [ ] T08 (after T03–T07): Add full results, raw-time ranking/ties and exactly-once PB/result commit. Verify faster/slower/invalid attempts and reload.
- [ ] T09 (after T08): Integrate full journey; run Web, persistence, accessibility and ten-race low-end checks from ROADMAP.md. Optimize measured bottlenecks.
- [ ] T10 (after T09): Review asset licenses and branding; record build/version and known issues; release Alpha only when acceptance is met or scope exceptions are explicitly approved.

## Implementation 01 completed
- [x] Godot 4.6.3 Compatibility project, main scene and single-thread Web preset.
- [x] Dark main menu: title, New Career, Continue, Settings; Settings has Back.
- [x] Procedural static track, original low-poly athlete, camera and simple shadow-free lighting.
- [x] Bounded WASD/arrow movement; focus-loss pause with explicit Resume.
- [x] Isolated versioned prototype position save, validation, failed-write messages and Continue availability.
- [x] Confirmation before replacing an existing probe save. No full career schema or simulation.
- [x] Headless import and main-scene smoke check; native input/save/menu integration checks and separate-process reload check.
- [x] UI container bounds checks at 1024×600, 1280×720, 1366×768 and 1920×1080.
- [x] Initial Web export identified missing templates; follow-up installed official matching templates with verified SHA-512 and successfully exported.
- [x] README with exact template installation/export/run/test steps, observed results, limitations and browser checklist.
- [x] Install matching single-thread Web templates (4.6.3.stable) and export successfully. Fix only the export resource filter to include missing preloaded scripts.
- [x] Real Chromium 156.0.8078.79: rendering, browser keyboard events, UI navigation, save/Continue, IndexedDB reload and complete browser restart pass (23 assertions; software WebGL 2).
- [ ] Human physical keyboard, browser focus-loss, storage denial/private/quota/eviction paths and additional browsers/HTTPS host verification.
- [x] Inspect menu and restored-track browser screenshots; check menu at four desktop resolutions.
- [ ] Test Windows 10 / 4 GB hardware and hardware GPU; no performance measurements yet.

The isolated probe uses `user://prototype_v1.json`, not the planned career schema. Full backup/migrations, import/export and multi-tab conflict handling remain T03 work. All Alpha gameplay acceptance items in ROADMAP.md remain pending.

## Verification and approval boundary
Read README.md for commands and the dated test report. Repeat native checks with Godot 4.6.3; run both test invocations in order. Browser verification requires matching templates and a served export. Original design documents retain their initialization baseline; this task log and README record current implementation status.

Implementation stops here. Request approval before additional implementation, including T02. Template/export/Chromium blockers are resolved. Windows hardware, further browsers and actual-host checks remain pending; do not represent the local Chromium probe as a broadly validated release.

## Repository delivery — 2026-11-09
The original /workspace has an empty read-only .git directory and was never a Git checkout: it had no branch, commits or remote. The source files existed locally but had not been committed or pushed. The connected GitHub repository is `qsmzdwmn/road-to-gold`, default branch `main`, initially at `d19b5786562ec1c3169de6a2bbda17461862e24c` with only README.md.

An isolated real checkout at `/workspace/work/github-checkout` is used to commit and push the project to `main`, preserving the initial commit and README heading. Generated builds, template archives, browser profiles and .godot caches are excluded. GitHub source ZIPs must be downloaded from the branch containing the project files. No gameplay features were added during export verification or repository delivery.

## Web compatibility and Pages preparation — 2026-11-09
- [x] Reconfirm exact Godot/template versions and installed Web ZIP integrity.
- [x] Export the existing single-thread Compatibility project again without gameplay changes.
- [x] Real Chromium under `/road-to-gold/`: 23 assertions pass for navigation, browser keyboard movement, save/load, IndexedDB, reload/restart, confirmation and desktop resolutions; no observed console/JS/WASM/storage/network errors.
- [x] Add `tests/web_pages_verification.json` and restored-track screenshot evidence without replacing the previous verification report.
- [x] Prepare `.github/workflows/web-pages.yml`: manual build by default, explicit optional deployment on main, fixed official binary/template checksums, native checks and artifact upload.
- [x] Check workflow structure/shell/Python syntax; run exact install/native/export scripts locally successfully (34 native assertions preserved).
- [x] Document Windows local HTTP serving and Pages instructions/limits in README.md. User reports native Windows launch succeeds; Windows browser/performance testing is still pending.
- [ ] Run the workflow on GitHub when desired; hosted Actions execution has not been tested.
- [ ] Confirm Pages eligibility for this currently private repository within the $0 budget. Do not change visibility, plan or hosting settings automatically.
- [ ] After explicit publication approval, configure Pages if eligible, deploy and test real HTTPS behavior. No deployment was performed in this milestone.
- [ ] Validate Windows desktop browser/hardware performance, additional browsers, focus-loss and adverse-storage cases.

Stop after this milestone. All gameplay and input/save implementations remain unchanged; only workflow, verification evidence and documentation were added.

## Remove default startup branding — 2026-11-09
- [x] Confirm Godot 4.6.3 boot splash settings; disable boot image and minimum display time, match dark background.
- [x] Add minimal custom Web loading shell and original track-mark project/favicon artwork. No external assets/fonts, timer or CSS animation.
- [x] Export and test in real Chromium: 13 startup assertions plus 23 browser regression assertions pass. Inspect all 14 recorded startup frames; no Godot logo observed. Default splash PNG never requested.
- [x] Preserve an existing browser-profile save byte-for-byte; verify movement/navigation and save/reload/restart in the full browser regression run.
- [x] Preserve all 34 native assertions and existing licensing/attribution notes.
- [x] Record startup screenshots/filmstrip and combined report; leave the existing Pages workflow unchanged.
- [ ] After the source push, dispatch the existing Pages deployment workflow to update the already deployed site, then check the actual HTTPS page. No deployment is dispatched in this task.

No gameplay scripts, save schema/user directory, or navigation mechanics were modified. Startup visuals are changed through project/export configuration and the standalone HTML shell only.

## Version 0.2 — Career creation completed
- [x] Main Menu → Create Career → Choose Origin → Customize Athlete → Career Summary → Confirm Career; creator hidden until New Career.
- [x] Back/Next/Escape retain draft values; opening/canceling a draft never writes saved progress.
- [x] Three described origins with correct derived ages 15, 17 and 20; no story simulation.
- [x] First/last name, authored 195-country catalog, six skin tones, four hairstyles, five hair colors, height, weight, shoulder/leg proportions. All cosmetic; movement ability remains independent of appearance/country.
- [x] Lightweight procedural live preview shared with the track athlete; summary shows required identity/origin/dimensions and appearance.
- [x] Version 2 career records in the existing local slot, with read-only v1 compatibility; Continue and position saving preserve identity/appearance/origin.
- [x] Explicit replacement confirmation in the UI and repository guard; validation/failed-write errors keep drafts and existing saves.
- [x] 114 native assertions pass, including every appearance bound, legacy/new-format separate-process reloads, and existing movement/focus/settings checks.
- [x] 55 actual Chromium assertions across core flow, save/reload/restart, explicit replacement, unchanged v1 records and four desktop layouts. No recorded engine/JS/network errors in these verified scenarios.
- [x] Fresh Web export includes authored JSON; ROAD TO GOLD startup/track graphics and input controller retained.
- [x] Update GAME_DESIGN.md, TECHNICAL_DESIGN.md, ROADMAP.md, README.md, task log and evidence. Manual workflow adds the career-native suite; no automatic deployment trigger added.
- [ ] Windows low-end browser/hardware performance and additional browser/HTTPS testing remain unmeasured.
- [ ] Future approval: introductory story events and career hub; full save backups/import-export/migrations/conflict handling; then sprint development. No such features are implemented in v0.2.

T02/T04 data and creator portions are now implemented. Their original story/race/hub scope remains deferred. T03 now supports validated v1/v2 records and explicit replacement, but its full recovery/migration/import-export scope remains open. Version 0.2 delivery targets main after source verification; deployment remains manual. Stop after this milestone.

## Version 0.2.1 — Male and female categories completed
- [x] Choose Athlete Category immediately after New Career; Male Athlete/Female Athlete, no fresh-draft default. Existing welcome/origin/customization/summary layout follows unchanged.
- [x] Both categories have all three origins/ages and all existing customization options; Back/Next and switching categories retain entered values.
- [x] Respectful, modest procedural shoulder/hip profiles using the same meshes/materials/kit. No logo or branding asset changes; no movement or athletic-stat changes.
- [x] Schema v3 explicitly saves category. V1/v2 remain supported; absent v2 category remains absent, neutral and visibly labeled unselected. Position saves never silently migrate or classify it.
- [x] New career validation and existing-slot confirmation/authorization remain mandatory. Missing/invalid v3 category disables Continue without overwriting progress.
- [x] Shared category IDs and `CareerData.competition_scope(event_id)` prepare future category-isolated records/opponents/progression. Empty legacy context has no default category. No separate competition systems implemented.
- [x] 198 native assertions, including six category/origin combinations, customization, confirmation guards, legacy behavior, invalid data, distinct silhouettes and separate-process male/female reloads.
- [x] 48 real Chromium assertions for both paths, visible preview differences, data validation, movement, saved category, page/browser restart and unchanged v2 legacy category state. No recorded console/network errors or warnings.
- [x] Update design/technical/roadmap/README documentation, native tests, browser evidence and manual workflow test commands. Web export succeeds.
- [ ] Future explicit legacy-category migration UI, competition systems and branding changes are deferred. Creator redesign is implemented in v0.2.2 below.
- [ ] Windows low-end hardware/additional browser/live HTTPS testing remains outstanding.

Stop after source delivery to main. No automatic deployment is authorized or dispatched.

## Version 0.2.2 — THE LOCKER ROOM
- [x] Inspect clean main at 328a71f; preserve v0.2.1 data, category and persistence implementation.
- [x] Reorganize the creator into Athlete → Story → Appearance → Identity → Summary, with numbered progress and final BEGIN CAREER.
- [x] Apply midnight/graphite/ivory/muted-gold local UI styling; retain original logo assets, menu, settings and track.
- [x] Add one bounded procedural locker room with shared simple materials, shadow-free lighting and a static full-body orthographic camera visible on all steps.
- [x] Refine both explicitly selected category models with neck/shoulder transitions, hands, balanced arms and shoes; keep neutral legacy geometry/materials unchanged.
- [x] Responsive actual-window UI, stacked below 900 px, independently scrolling controls and persistent navigation; native keyboard/mouse controls with visible focus.
- [x] Keep ten customization/identity controls and original validation bounds; track pending numeric text without applying stale hidden control text.
- [x] Preserve save schemas 1/2/3, same path, no inferred legacy category, no migration, final replacement authorization and Cancel protection.
- [x] All 198 existing native assertions preserved with navigation/title adaptations; 62 additional locker-room assertions pass. Import and main-scene smoke check pass from the actual Git checkout without logged warnings/errors.
- [x] Official 4.6.3 single-thread Web export succeeds; Pages workflow remains manual-only and adds the new native suite.
- [x] 135 real Chromium checks pass: both paths, all origins/appearance controls, validation, draft retention, confirmation, movement, Continue, page/browser restart, v1/v2 legacy profiles, five steps at five resolutions and final checkout keyboard/menu checks. No recorded engine/JavaScript/storage/network warnings/errors.
- [x] Capture all five steps, both models, numeric controls, responsive layouts and keyboard scrolling; save raw verification JSON and dated report.
- [ ] Windows 10 / 4 GB hardware performance, other browsers, screen readers, live-host and denied/private/quota storage paths remain unverified.

No story, competition, record or progression systems, new branding assets or automatic deployment are part of this milestone. Stop after tested source delivery to main.

## Version 0.2.3 — GOLDEN ROAD
- [x] Synchronize main through c085d57 and verify both approved owner-supplied PNGs; record immutable SHA-256 hashes. Preserve originals and uploaded ZIP.
- [x] Add optimized transparent logo/emblem/icon derivatives, central Brand helper and a single project version setting (0.2.3).
- [x] Implement the approved cinematic split menu; refine the full logo size by about 25%, use the three-line tagline, consistent button spacing and gold hover/focus accents.
- [x] Add a static curved symbolic road, subtle edge bevel/highlights, dark horizon layers and one tiny radial warm glow. Keep the road extending beyond the right viewport edge; no camera motion, fog, bloom or particles.
- [x] Show Your journey begins here with no save; show validated existing athlete names when available; preserve generic position-only legacy caption, readable disabled Continue, full-name tooltips and visible save failures/nonpersistent warnings.
- [x] Skip disabled Continue in keyboard focus order; enable keyboard access when valid progress exists. Preserve existing menu signals, settings, new-career entry and original playable track/camera/movement.
- [x] Brand the real-progress Web loader, existing Locker Room header and icon without redesigning career creation or changing its static preview camera.
- [x] Preserve save/data/catalog/movement classes, schema 1/2/3 and the user-data directory. No migration or invented legacy category.
- [x] Run all 260 existing native assertions unchanged and 72 focused main-menu/branding/name/focus/orientation checks. Import/main smoke and matching 4.6.3 single-thread export pass without logged warnings/errors.
- [x] Verify 104 real Chromium core menu/loader/layout/career/persistence checks, followed by 25 final-build front-facing preview checks (129 total), all passing without recorded engine/JavaScript/storage/network warnings/errors.
- [x] Rotate only the preview instance toward the static camera; both category-facing checks and gameplay-orientation preservation pass native regression.
- [x] 25 final-build Chromium orientation checks pass for both categories, identical identity/summary framing, customization retention, confirmation and unchanged save schema; combined with 104 core Chromium checks, total 129. Package final screenshots/report.
- [ ] Windows 10 / 4 GB hardware performance, additional browsers, screen readers, live-host and denied/private/quota storage remain unverified.

Updated screenshots were shown before committing, as requested. Source delivery and a normal push to main follow successful verification. No deployment is authorized or dispatched.

## Version 0.2.4 — Athlete Studio 2.0
- [x] Sync clean main at ae46254; inspect data/validation/persistence, branding, creator and reports; run 332 baseline assertions before editing.
- [x] Record existing UI-to-data mapping in tests/ATHLETE_STUDIO_MAPPINGS.md.
- [x] Reusable original 2D silhouette/hair cards, all catalog swatches, and the existing shared front-facing preview; no new 3D graphics.
- [x] Pin title/subtitle and Hair/Skin/Body tabs outside scrolling options; add 16 px right/bottom content padding and keep footer reachable.
- [x] Preserve all existing values/ranges/steps and link precise Body/Identity height-weight controls through native Range sharing.
- [x] Compact Player Card with correctly sized horizontal header, small official emblem, prominent identity/origin/age, and seven actual attributes in two columns. No fabricated ratings.
- [x] Correct header wrapping through minimum width/no-wrap/expansion constraints; add card-layout/data regression tests.
- [x] Keep shared model, camera, gameplay and saves unchanged; preview-only fixed yaw clarified to 230° at user's rotation-only preference (about 30° from camera view).
- [x] All 332 existing assertions retained with version/tab-context adaptations; 90 focused Studio tests pass, total 422. Covers keyboard increments, card layout, data, retention, orientation, bounds and modal fitting.
- [x] Matching Godot 4.6.3 single-thread Web export succeeds.
- [x] Complete core Chromium run verifies both categories, tabs, all controls, actual saving/replacement/reload/restart, and legacy schemas.
- [x] Finish 30 final corrected-card/preview Chromium checks and fresh desktop/small screenshots; 54 earlier core checks also pass (84 staged browser checks). No recorded runtime/storage/network warnings or errors.
- [ ] Windows 10 / 4 GB FPS/memory, other browsers, screen readers, zoom and restricted/private/quota storage remain unverified.

The user reviewed and approved the compact Legacy layout, selected rotation-only orientation clarification, and authorized commit/push after final testing. Do not deploy automatically.

## Version 0.2.4.1 — Athlete Studio refinement (approved)
- [x] Fetch main at 17119be; keep the stable production body, camera, Story, Player Card and gameplay.
- [x] Preserve saved hair IDs 0–3 exactly; append male IDs 4–9 and female IDs 10–15, without changing schemas 1/2/3 or other appearance fields.
- [x] Six category-specific hair choices; initial Crew Cut / Long Straight; remember each category's selected hair during editing.
- [x] Cached procedural hair meshes, one material surface per style; no experimental GLB assets or dependencies.
- [x] Remove duplicate Identity height/weight editors; retain canonical Appearance values and Player Card metrics.
- [x] 521 native assertions pass, including winding, bounds, style geometry, ID compatibility and actual save/reload.
- [x] Complete staged Chromium verification: 35 flow/persistence checks, 14 clean legacy rechecks after fixing the local fixture server, and 18 final visual/accessibility checks. All twelve final hairstyle captures are included.
- [x] User visual/test approval received 2026-11-10; main commit/push and manual Pages release explicitly authorized. Experimental Blender branch must remain separate.

### v0.2.4.1 final hair polish — approved
- [x] Target only Buzz Cut, Crew Cut, Side Part, Long Straight, Long Wavy, Shoulder Length and Braided Hair; verify the other five meshes are unchanged.
- [x] Re-run 521 native assertions, official Web export and real Chromium comparisons/accessibility checks; record scalp coverage and matched before/after evidence.
- [x] Final hairstyles visually approved 2026-11-10; preserve existing v0.2.4.1 UI/save work unchanged during release.

## v0.3.0 Career Hub foundation — review only
- [x] Audit released v0.2.4.1 main and clean tree; isolate `feature/v0.3.0-career-hub`.
- [x] Add Overview, read-only My Athlete, sidebar and shared Settings.
- [x] Route confirmed new/continued careers to Hub through existing save system.
- [x] Keep legacy category unselected; preserve schemas, appearance IDs and approved Player Card.
- [x] Label unavailable training/calendar/records honestly; retain movement sandbox.
- [x] Add native Hub regression, responsive screenshots and local real Chromium checks; see verification report for exact coverage/results.
- [x] User visual and functional approval received; feature-branch commit/push and PR authorized.
- [ ] Commit/push/merge/deploy only after separate authorization; none performed.

### Career Hub UI polish — pending visual approval
- [x] Compact athlete/status band, event/record columns, lightweight sandbox row and upper-right Save & Menu.
- [x] Clean single-line Training sidebar label; Coming Soon inside Training.
- [x] Preserve My Athlete, Player Card, model, routing and saves.
- [x] Fresh Chromium screenshots and visual polish approved; finalize through a feature-branch PR. No merge or deployment.

### v0.3.0 finalization
- [x] Fetch remote main and confirm feature branch is based on latest `e88438a`.
- [x] Review intended production changes and preserve experimental branch separately.
- [ ] Merge and deployment await separate user approval.

## v0.4.0 Training foundation — review branch
- [x] Verify latest main and isolate `feature/v0.4.0-training-foundation`.
- [x] Deterministic rules, integer hundredths, preview/confirmation shared path, two actions/day and explicit End Training Day.
- [x] Schema4 validation, schema2/3 original backups, legacy category preservation, incompatible-save protection, duplicate/stale/failure tests before enabling UI writes.
- [x] Training UI and autosave integration; retain training through sandbox/Save & Menu.
- [x] 869 native assertions, 74 real Chromium checks, official Web export and final screenshots; see training report.
- [x] User visual/functional approval; feature-branch commit/push and PR authorized.
- [ ] Merge and deployment require separate approval.

## v0.5.0 — Development Meet and Stadium 1.0 (uncommitted review)

- [x] Isolate race implementation from main, then branch `feature/v0.5.0-stadium-rebuild` from the race branch.
- [x] Eight deterministic runners, Rhythm/Hold controls, false starts, GO-relative reaction, interruption and exact finish classification.
- [x] Schema4 competition/PB integration, original backups, category confirmation, failed/stale/duplicate/future-save protection.
- [x] Compact responsive readiness and leaderboard; player identification and fixed action buttons.
- [x] Coherent decorative oval, original authoritative straight/lane coordinates, two stands, static instanced crowd, infield equipment, daylight and perimeter concourse.
- [x] Optional static venue establishing view during readiness; immediate player-follow cut at Ready with no extra delay.
- [x] Race-only speed-driven procedural strides, acceleration lean, idle easing, two shared limb batches and compact navy HUD.
- [x] 993 native assertions, 27 final focused Chromium checks, official Web export, controlled balance comparison, screenshots/video and browser performance comparison recorded in `tests/RACE_STADIUM_VERIFICATION.md`.
- [x] Visual/functional approval received for v0.5.0 feature-branch commit/push and PR preparation; merge and deployment await separate approval.

Physical 4 GB Windows hardware, other browser engines and skeletal running animation remain unverified/deferred. No experimental models or Training balance changes.

## v0.5.0 final performance release gate

- [x] Identify default and explicitly requested browser rendering backends: SwiftShader; no exposed hardware GPU.
- [x] Isolate shadows, MSAA, crowd and optional decoration; retain complete stadium architecture in both production modes.
- [x] Add race-only Performance/Enhanced preference with conservative default and separate graphics storage.
- [x] 1,007 native assertions, 13 additional real Chromium checks and matching official Web export pass.
- [x] Record FPS/frame-time/draw-call/process-memory measurements with software-rendering limitations.
- [ ] Hardware-accelerated low-end Windows measurements remain unverified.
- [x] Owner approved release PR preparation with documented limitations.
- [x] Commit/push/PR preparation authorized; do not merge or deploy without separate approval.

## v0.5.0 integration PR preparation

- [x] Fetch origin/main and verify no divergence from the v0.4.0 merge baseline.
- [x] Review the intended race/stadium/quality integration and preserve the experimental branch.
- [x] Rerun 1,007 native assertions, 45 real Chromium checks and official Godot 4.6.3 single-thread Web export.
- [x] Document physical GPU, browser-focus and asynchronous storage limitations.
- [x] Extend only the manual workflow validation commands with six new native suites.
- [x] Release candidate reviewed and validated for commit/push/PR; final remote verification is reported with the PR URL.
- [ ] Merge and deployment require explicit later approval; no v0.5.1 work.

## v0.5.1 Stadium Audio — approved release PR

- [x] Owner listening approval received for all ten assets and Settings UI.
- [x] Music / Sound Effects / Stadium Crowd buses, bounded mixer and Mute All.
- [x] Validated audio preferences separate from careers and graphics settings.
- [x] Responsive Settings, visible ON/OFF switch, pinned Back and keyboard access.
- [x] Hub fades, authoritative race cues, gait footsteps and saved-PB reaction.
- [x] Preserve preview-site work outside the game release and exclude tools/ from Web.
- [x] Complete 1,088 native assertions, 63 Chromium checks and 13 package-load assertions; all ten approved audio hashes unchanged.
- [x] Release candidate verified for authorized feature commit/push/PR; final remote status is reported with the PR.
- [ ] Verify true hidden-tab freezing and physical low-end GPU/audio hardware (limitations).
- [ ] Merge only with explicit owner approval; do not deploy in this milestone.
