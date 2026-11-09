# ROAD TO GOLD — Tasks

Status: Implementation 01 authorized and implemented on 2026-11-09. Native checks and local Chromium verification pass. Official matching Web templates are installed and Web export succeeds; T01 retains Windows hardware and actual-host verification. Further implementation waits for approval.

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
