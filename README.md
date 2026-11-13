# road-to-gold

## ROAD TO GOLD — Version 0.4.0: Training foundation (review build)

A Godot **4.6.3 standard / GDScript** career-creation prototype using the **Compatibility** renderer. No paid assets, APIs, plugins, services, or project dependencies. Version 0.2.3 adds the approved Golden Path branding and a static cinematic Golden Road main menu. The existing category, origin and athlete data remain in THE LOCKER ROOM: a five-step creator with a static full-body procedural preview, midnight/graphite panels, ivory text and muted gold accents. The existing dark menu, settings/help, test track, camera, lighting and keyboard movement are preserved. Version 0.3.0 adds a responsive Career Hub with real athlete data and honest unavailable states. Version 0.4.0 adds deterministic Training with previews, fatigue management and protected schema 4 migration. There is no story, career-year simulation or sprint race yet.

## Run locally

1. Install/extract Godot 4.6.3 **standard**, not the .NET build. Import `project.godot` in the Project Manager.
2. Press **F6** with `scenes/app/main.tscn` open, or **F5** to run the project.
3. Select **New Career** → **Choose Your Athlete** → **Your Story** → **Your Appearance** → **Your Identity** → **Begin Your Legacy** → **Begin Career**. Use Back/Continue without losing choices. The last button saves and opens **Career Hub**; existing progress requires a replacement confirmation. **Continue** opens Hub for schema 2/3 careers; schema 1 position-only saves retain the original test track. Overview displays saved athlete data and honest empty states. My Athlete reuses the approved Player Card and stable appearance preview. Training, Calendar and Records are informational only. Settings reuses the existing screen. **Explore Track** opens the existing movement sandbox; **Career HQ** returns to Hub.
4. In the track sandbox, move with **WASD or arrow keys**. **Escape** returns to the menu without saving. **Save & Menu** writes the current position. **Continue** restores it. **Settings → Back** returns to the menu.
5. Losing application focus pauses movement; choose **Resume** to continue. The track limits exploration to its marked area.

Command-line alternative, from the project root:

```sh
godot --path .
```

On Windows use the Godot executable's full path if it is not on PATH. For terminal logs/headless checks, use the corresponding `_console.exe` executable. Godot is the only requirement to run or test the native project. No audio, AI, story events, career progression, sprint timing or sports mechanics are implemented.

## Save behavior

`user://prototype_v1.json` remains the local slot for compatibility. Version 1 `track_probe` saves contain a position only; Version 2 `career` saves add origin, derived starting age, names, country code and all appearance fields. Version 3 adds an explicitly selected `athlete_category` (`male` or `female`). Position stays separate. Existing v2 careers without a category remain unselected; loading or saving their position does not add a category or upgrade the schema. The custom user directory remains `road-to-gold-prototype`; on Windows the normal path is `%APPDATA%/road-to-gold-prototype/prototype_v1.json`. Use Godot's **Project → Open User Data Folder** to locate it.

Opening New Career never writes this file. All creator steps share an in-memory draft; Back/Next and returning to the menu retain it within the session. A page reload discards unconfirmed drafts. Only final BEGIN CAREER commits a new record; if any slot already exists, a confirmation dialog must be accepted before replacement. Invalid names/data block creation. Failed writes leave the old save intact and keep the editable summary visible with an error.

Continue reads schemas 1–4; a legacy save is never automatically rewritten or assigned an invented athlete. Save & Menu stores track position while preserving the complete career or the original legacy format. Escape/menu without saving does not update position. Invalid/unsupported saves disable Continue, show an error and remain unchanged even if New Career replacement is confirmed. Writes use a temporary file then rename. Schema 4 training migration keeps a verified original-save backup. General backup/restore UI, multi-tab conflict handling and import/export remain future work.

In Web builds, Godot maps `user://` to browser storage, normally backed by IndexedDB. The UI warns when the filesystem reports nonpersistent storage. A successful write does not guarantee a browser has durably synchronized it. Wait briefly before closing/reloading, and verify on the actual browser/host. Saves are scoped to profile and site origin; they are not synced to another device. Private browsing, denied storage, clearing site data or changing host may lose saves. Use one tab for this prototype.

## Web export — verified locally

Engine: `4.6.3.stable.official.7d41c59c4`. Expected and installed template version: **4.6.3.stable**. The official standard archive was downloaded from:

https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz

Its SHA-512 matched the official release's `SHA512-SUMS.txt`:

```text
da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
```

Only the required single-thread Web debug/release templates and version marker were extracted into `/workspace/work/data/godot/export_templates/4.6.3.stable/`. Templates are development tools, not committed project assets. Use the XDG_DATA_HOME shown below to export with this installation, or install matching templates normally on your machine.

The existing Web preset exported successfully. Real Chromium tests then exposed missing preloaded GDScript resources in the selected-scenes export. The compatibility fix changes only `export_filter` to `all_resources`, retaining the `tests/*,work/*,*.md` exclusions. No gameplay scripts or mechanics changed. The corrected build loaded and passed browser checks.

The single-thread, non-GDExtension export is in `builds/web/` (generated, ignored by Git). Its nine files total **38,097,506 bytes**, without HTTP compression; this is not a measured compressed-transfer budget. No server or paid dependency is required at runtime beyond static file serving. A GitHub source ZIP contains the project, not these generated binaries.

### Install templates on another machine and export

1. Open the project in **Godot 4.6.3**.
2. Select **Editor → Manage Export Templates**. Confirm the current version is **4.6.3.stable** and choose **Download and Install**.
3. If downloading through the editor fails, obtain the official **4.6.3 export templates `.tpz`** from https://godotengine.org/download/archive/4.6.3-stable/ and choose **Install from File** in that same dialog. Do not mix versions.
4. Confirm the template manager shows the current version installed. On Windows the usual template directory is `%APPDATA%/Godot/export_templates/4.6.3.stable/`; it should include both `web_nothreads_debug.zip` and `web_nothreads_release.zip`.
5. Select **Project → Export → Web**. Leave **Thread Support** and **Extensions Support** off. Create `builds/web/` if needed and export to `builds/web/index.html` (Export Project).
6. Serve all exported files together over HTTP localhost or HTTPS, not `file://`. The browser needs WebGL 2; the server must serve `.wasm` as `application/wasm`. No account or paid host is required. The single-thread preset avoids the usual threaded-build cross-origin isolation requirement; verify the actual host before deployment.

Command-line export after installing templates:

```sh
godot --headless --path . --export-release Web builds/web/index.html
```

For local serving, if Python is already available (optional development tool, not a game dependency):

```sh
python -m http.server 8000 --directory builds/web
```

Open `http://localhost:8000/index.html`. Godot's editor Web run facility is another local testing option. Do not publish a build or change hosting as part of this milestone.

## Verification

Native Godot-only checks:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/prototype_test.gd
godot --headless --path . --script tests/prototype_test.gd -- --reload-check
godot --headless --path . --script tests/career_creation_test.gd
godot --headless --path . --script tests/career_creation_test.gd -- --reload-career
godot --headless --path . --script tests/category_support_test.gd
godot --headless --path . --script tests/category_support_test.gd -- --reload-categories
```

Run each suite followed by its matching reload check with the same user data directory. Prototype tests use `user://tests/prototype.json`; career tests use `user://tests/career.json`. The reload checks verify their respective fixtures in separate processes. They do not overwrite the interactive prototype save. Keyboard verification uses injected physical key events through Godot's InputMap, not a human pressing keys or a browser. UI-fit checks inspect container bounds; they are not screenshots or visual/accessibility certification.

In this cloud sandbox, Godot's normal home configuration path was not writable. Checks were rerun with the following per-command prefixes; use the same data directory for both test invocations:

```sh
XDG_CONFIG_HOME=/workspace/work/config XDG_DATA_HOME=/workspace/work/test-data XDG_CACHE_HOME=/workspace/work/cache godot --headless --path . --script tests/prototype_test.gd
XDG_CONFIG_HOME=/workspace/work/config XDG_DATA_HOME=/workspace/work/test-data XDG_CACHE_HOME=/workspace/work/cache godot --headless --path . --script tests/prototype_test.gd -- --reload-check
```

Import/main/export checks used `/workspace/work/data` instead of `/workspace/work/test-data`. These Linux shell environment prefixes are unnecessary on a normally configured Windows installation. Test logs are local intermediate files under `work/`, excluded from version control.

### Native verification — 2026-11-09

- Engine: `4.6.3.stable.official.7d41c59c4`, Linux cloud environment.
- Final headless editor import/validation: exit 0, no reported errors/warnings.
- Main scene: ran 120 headless iterations and exited 0, no reported runtime errors/warnings. No rendered-window visual inspection was performed.
- Integration checks: all passed (menu/settings/Back; missing save; start/confirmation; W and Right-arrow input; bounds; pause/resume; save/Continue; invalid version; nonfinite position; failed write; UI bounds at 1024×600, 1280×720, 1366×768 and 1920×1080).
- Separate-process native reload check: passed.
- Initial Web export failed for missing templates. The subsequent verification installed matching official templates, corrected resource packaging and successfully exported and ran the browser build (details below).
- Initial version checks emitted a Fontconfig cache warning, and the first editor import reported an unwritable home configuration directory. Writable XDG paths resolved these environment errors on subsequent runs. An initial test used exact floating-point equality at the boundary; it was corrected to approximate equality and all checks rerun successfully.
- Native regression checks were rerun after the export-filter fix: import, main scene, 33 integration assertions and the separate-process reload assertion all passed. No existing tests were changed for Web verification. Windows hardware performance remains unmeasured.

### Actual browser verification — 2026-11-09

Served with `python3 -m http.server 8000 --bind 127.0.0.1 --directory builds/web` at **http://127.0.0.1:8000/index.html**. The `.wasm` response was HTTP 200 with `Content-Type: application/wasm`. No COOP/COEP headers were needed for this single-thread localhost run.

Used real **Chromium 156.0.8078.79**, headless Linux, driven by the environment's existing Playwright installation with SwiftShader software WebGL 2 (`--use-angle=swiftshader --enable-unsafe-swiftshader`). The automation used browser mouse/keyboard events and read rendered canvas text through screenshots/OCR; it did not inject Godot state or replace the save implementation. This proves browser execution, not hardware GPU performance or human physical-keyboard testing.

Passed 23 browser assertions covering:

- Clean persistent profile: no save, Continue remains unavailable.
- Settings opens, Back returns, and Enter activates the focused Back button.
- New Career enters the rendered track. Browser `W` and Right-arrow events visibly change position.
- Save & Menu writes the moved position to actual IndexedDB database `/userfs`, store `FILE_DATA`, key `/userfs/road-to-gold-prototype/prototype_v1.json`.
- Reload on the same origin enables Continue and restores the position.
- New Career requests confirmation; cancel leaves the saved IndexedDB value intact.
- Menu rendering at 1024×600, 1280×720, 1366×768 and 1920×1080. Menu and restored-track screenshots were visually inspected. This is not a full zoom/accessibility review of every screen.
- Closing the entire browser context/process and reopening the same persistent profile restores the same saved position through Continue. Saved coordinates were `[2.00000071525574, -2.66666674613953]`, displayed as `2.0 / -2.7 m`; stored JSON was unchanged after restart.
- Corrected build: **zero uncaught JavaScript errors, zero browser-console errors, zero failed requests and zero HTTP errors** during this test. No WebAssembly or IndexedDB errors were observed. Engine startup logged Compatibility/WebGL 2, Emscripten 4.0.20, single-threaded, no GDExtension support.

The initial export's browser console did report missing `prototype_save_repository.gd` and `placeholder_input.gd` preloads and consequent parse errors. Including all project resources resolved those errors; the final verification used the rebuilt artifact. Verification evidence is in `tests/web_verification.json` and `tests/web-evidence/`.

Remaining verification limits: Windows 10 / 4 GB hardware, hardware GPU performance, Firefox/Edge, real HTTPS hosting, storage-denied/private/quota/eviction paths, browser zoom/accessibility and browser focus-loss behavior were not tested in this browser run. Native focus-pause and failed-write tests still pass. Persistence success applies to the tested profile/origin and clean browser restart; it does not guarantee storage survival after eviction, power loss or site-data clearing. These are outstanding checks, not current export or Chromium startup blockers.

To reproduce the cloud export with installed templates:

```sh
XDG_CONFIG_HOME=/workspace/work/config XDG_DATA_HOME=/workspace/work/data XDG_CACHE_HOME=/workspace/work/cache godot --headless --path . --export-release Web builds/web/index.html
```

### Manual browser checklist after export

- Clean profile on a fixed localhost origin: Continue disabled; New Career opens track; WASD/arrows move; Settings and Back work; buttons have visible keyboard focus.
- Save a nonzero position, wait briefly, reload, then Continue. Close/reopen the browser using the same profile and origin and check again. Record versions and actual outcomes.
- Confirm canceling New Career preserves the position; confirming resets it. Escape does not overwrite the saved position.
- Switch tabs while moving; return and explicitly Resume. Check no unwanted movement or position jump.
- Try 1024×600, 1280×720, 1366×768 and 1920×1080, plus browser zoom. Inspect legibility, clipping and athlete visibility.
- Check browser console/network errors, WebGL 2 availability, IndexedDB persistence and denied/private-storage behavior. Record issues instead of assuming the native results apply.

## File map and next step

`scenes/app/main.tscn` and `scripts/app/main.gd` own navigation. `scenes/ui/` and `scripts/ui/` own the interface. `scenes/race/` and `scripts/race/` build the static probe track; this is not a race simulator. `scenes/athletes/` and `scripts/input/` contain the placeholder and movement actions. `scripts/persistence/` alone handles probe storage. `tests/prototype_test.gd` is the native integration test. Original asset provenance is recorded in `assets/licenses/README.md`.

Next recommended task: verify Windows 10 / 4 GB hardware, additional desktop browsers and the intended HTTPS host. The matching-template, Web export and Chromium persistence blockers are resolved; T01 retains the explicitly pending hardware/host checks. Only after that gate and approval should T02 athlete/appearance/career data contracts begin. Stop at this technical milestone; no further implementation is authorized.

## Local Web run on Windows

The user reports that the native prototype launches on Windows; browser and performance testing on that machine is still separate. With Godot 4.6.3 and matching templates installed, export the existing **Web** preset from **Project → Export** to `builds/web/index.html`. Keep every exported file together.

From a terminal in the project root, if Python is installed:

```powershell
py -m http.server 8000 --bind 127.0.0.1 --directory builds/web
```

Open **http://127.0.0.1:8000/index.html** in Chrome/Edge. Use the same address, port and browser profile for save testing; `localhost` and `127.0.0.1` are different origins. Do not double-click the HTML file. Stop the server with Ctrl+C. Python is only an optional local development server, not a dependency of the exported game.

The build retains Compatibility/WebGL 2, single-thread operation, primitive geometry, static lighting and no real-time shadows. No gameplay, resolution, movement or save mechanics were changed for Pages preparation. This avoids adding load, but does not establish an FPS or memory guarantee on a 4 GB Windows computer.

## Prepared GitHub Pages workflow

`.github/workflows/web-pages.yml` is **manual only**. There is no push trigger and no automatic publication. It uses official GitHub actions and downloads the official Godot 4.6.3 Linux binary and standard template archive, verifying both against fixed SHA-512 values from the release. It installs only the required Web templates, imports the project, runs the existing native checks, exports the existing single-thread preset and uploads a Pages-ready artifact. It does not automate the separate Chromium/OCR checks.

To build without publishing after the workflow is on GitHub: **Actions → Web build and optional Pages deployment → Run workflow**, select `main`, leave **deploy** unchecked, then run. The `github-pages` artifact contains the static export; extract the artifact's tar archive before serving it. GitHub-hosted execution has not yet been run or validated; the installation, native-check and export scripts were exercised locally.

To publish later, first confirm repository/plan eligibility and explicitly approve publication, then configure **Settings → Pages → Build and deployment → Source: GitHub Actions**. Dispatch the same workflow on `main` with **deploy** checked. The deployment job uses the `github-pages` environment and only that job receives Pages-write/OIDC permissions. Its `configure-pages` step does not enable a site automatically. Merely committing this workflow does not deploy anything.

**Hosting note from the initial setup:** this repository was private when the workflow was prepared; the user now reports that Pages is deployed. Version 0.2 source changes are not deployed by this task. GitHub Pages on GitHub Free supports public repositories; private-repository Pages availability depends on the account plan. No paid plan or repository visibility change is authorized or required for the local build. Do not purchase a plan or make the repository public automatically. To keep hosting at $0, a public-repository option would require an explicit visibility decision, or a separate free static-host choice. The account's actual Pages eligibility has not been verified.

The workflow serializes Pages runs, refuses its deployment job outside `main`, and defaults to an artifact-only build. If the site is later enabled with the normal project-site URL, it would use the `/road-to-gold/` path. The real production HTTPS origin, headers and persistence must still be tested after an approved deployment. Changing from localhost to Pages creates a different save-storage origin; existing local browser saves will not transfer automatically. Pages serves static public content even when source-repository access is restricted, unless account-specific private-site access controls apply.

### Follow-up Web/Pages-path verification — 2026-11-09

Reconfirmed Godot `4.6.3.stable.official.7d41c59c4` and the installed `4.6.3.stable` template marker. Both installed Web template ZIPs passed full CRC/integrity checks. A fresh release export succeeded without changing the preset or any gameplay script.

Ran real Chromium **156.0.8078.79** again with a new persistent profile and software WebGL 2, this time at **http://127.0.0.1:8001/road-to-gold/index.html** to exercise a GitHub Pages-style subdirectory. All **23 browser assertions passed**: menu/settings/Back, keyboard movement, Save & Menu, actual IndexedDB values, Continue after reload, replacement cancellation, four desktop sizes and recovery after full browser restart. There were **no browser-console errors, uncaught JavaScript errors, failed requests, HTTP errors, or observed WebAssembly/storage errors** in this run. The saved position was `[1.60000050067902, -2.86666655540466]`, and the stored JSON remained identical after restart. Evidence: `tests/web_pages_verification.json` and `tests/web-evidence/pages-restored-track.png`.

Validated workflow YAML structure, all embedded shell syntax and Python syntax. Ran the workflow's exact checksum/install Python against official downloaded archives, then its native-regression and export shell steps locally using the extracted official binary. Import/main checks and all **34 existing native assertions** passed, and the Web export step succeeded. This is local verification of those scripts; no GitHub Actions run, Pages configuration change or deployment was performed.

No new Web-specific runtime defect was found. Single-thread Compatibility settings, shadow-free lighting and lightweight geometry remain unchanged. The remaining blockers to claiming production/low-end compatibility are the actual Windows browser/GPU and 4 GB performance checks, cross-browser/adverse-storage tests, Pages account eligibility, and an approved HTTPS deployment test. The local Web build itself has no outstanding startup/input/save blocker in the tested Chromium environment.

## ROAD TO GOLD startup branding — 2026-11-09

Godot 4.6.3 project settings now use `application/boot_splash/show_image=false`, `application/boot_splash/minimum_display_time=0` and a dark `application/boot_splash/bg_color`. The original track-mark icon in `assets/branding/road_to_gold.svg` replaces the default project/favicon artwork. No gameplay script, input mapping, user directory or save schema changed.

The Web preset's `html/custom_html_shell` is `res://web/loading.html`. This small standalone shell displays ROAD TO GOLD, Loading… and a download-progress bar on the game's dark background. It uses system fonts and no external requests, animation, fake progress or startup timer. It removes the loader on the engine's actual startup promise and focuses the canvas. Unsupported-browser/load failures stay visible as plain text. It contains no default splash-image element or request. Godot may still export an unused default splash PNG; the custom page never loads or displays it. Engine names in technical startup console logs are retained.

Export and test the same way as documented above. Chromium 156.0.8078.79 (real browser, headless Linux/SwiftShader WebGL 2) passed **13 targeted startup assertions**, **23 browser regression assertions**, and the native suite retained **34 passing assertions**. Startup testing held the engine JS request only in the test harness, checked that the custom loading page was already visible, then released it and recorded 14 compositor frames through the menu appearing. All recorded frames were inspected: the ROAD TO GOLD loader transitions directly to the main menu with no Godot splash seen. The generated default splash PNG was not requested, and the branded favicon was visually checked.

A copied browser profile from the preceding milestone still recognized its existing save, with identical IndexedDB save bytes after startup. A separate clean-profile regression run verified settings/Back, keyboard movement, Save & Menu, reload/Continue and browser-restart persistence under `/road-to-gold/`. No JavaScript/engine console errors or failed requests were observed in the successful startup or regression runs. Evidence: `tests/splash_verification.json`, `tests/web-evidence/road-to-gold-loading.png` and `tests/web-evidence/startup-filmstrip.png`. Godot licensing/attribution documentation remains in `assets/licenses/README.md`; removing branding does not remove the engine's license obligations.

The user reports that Pages is already deployed. The existing workflow needs no modification: its normal export consumes the custom shell and icon. This task commits/pushes the source changes but does not dispatch a new deployment. Run the existing Pages workflow on main with deploy selected to publish the updated loading screen. The hosted HTTPS deployment has not been retested with these changes; local Chromium verification does not establish low-end Windows performance.

## Version 0.2 career creation

The dedicated creator is available only after New Career. It has an introduction, three described origins (ages 15/17/20), customization and summary. The summary includes an appearance preview and explicit Create Career action. Starting age derives from origin; there is no calendar or story simulation. Names must contain 1–32 characters, countries come from a small authored 195-entry catalog, and appearance controls use bounded values. Skin/country/name choices never change athletic ability or keyboard movement.

Model layers: `scripts/data/` holds catalog/appearance/identity, `scripts/career/career_data.gd` holds the origin and athlete snapshot, `scenes/ui/career_creator.tscn` and its script hold draft navigation, and `scripts/customization/procedural_athlete.gd` owns cosmetic geometry. Preview updates reuse primitives/materials instead of downloading models. The scrolling form and fixed footer support keyboard/mouse; the preview uses one small independent viewport and no shadows. The existing track rendering/controller and ROAD TO GOLD startup branding remain intact.

The Web preset explicitly includes authored JSON catalog files; test/work files remain excluded. The manual Pages workflow now runs the career-native checks as well as the existing regression tests. No push-trigger or automatic deployment was added. Version 0.2 must be manually deployed after review; pushing source does not publish it.

### Version 0.2 observed verification — 2026-11-09

- Godot 4.6.3 import and main scene pass without reported errors. **114 native assertions pass**: 35 prototype regressions adapted for the new wizard entry, 76 career creation/validation/preview/navigation/compatibility assertions, and three separate-process reload assertions across both save formats. Native checks include all 14 appearance-limit endpoints, each origin's age, blank names, malformed/future saves, canceled replacement, failed writes, and original movement/pause/settings behavior.
- The current Web preset exports successfully with both JSON catalogs included. Runtime pack is **60588 bytes**; no large external assets or runtime dependencies were added.
- **55 verified real Chromium 156.0.8078.79 assertions**, across staged core, replacement/legacy and layout scenarios at `http://127.0.0.1:8001/road-to-gold/index.html`. Actual browser events exercise New Career, origin selection, every customization field, live 3D changes, summary, final creation, keyboard movement, Save & Menu, replacement cancellation and acceptance, page reload, full browser restart and a copied v1 profile. IndexedDB inspection verifies the stored values and unchanged legacy/canceled records. No test writes were injected into the browser save store.
- Rendered screenshots were reviewed at 800×600, 1024×600, 1366×768 and 1920×1080; forms scroll with navigation available, using the game's existing aspect scaling. The preview camera has enough margin for maximum height/weight/proportions; the actual maximum values were confirmed in saved data.
- No JavaScript/engine console errors, failed requests or HTTP errors were recorded in the verified browser scenarios. The initial exploratory test driver had OCR/focus-timing failures; remaining cases were completed separately with explicit per-screen synchronization, as recorded in `tests/career_verification.json`. This is not a claim that every exploratory script completed successfully.
- Development checks caught and fixed numeric edit commit timing, hidden-creator focus stealing, and a floating-point edge at the allowed 1.15 leg proportion. The final native boundaries and browser maximum-setting save pass.
- Evidence: `tests/career_verification.json` and the four `tests/web-evidence/career-*.png` images. These are actual browser captures, not mockups.

Remaining scope/limits: one local save slot; unconfirmed drafts are session memory only; no story system, training, career-year progression or sprint competition. Full backup/migration chains, JSON import/export and multi-tab conflict handling remain future work. Windows 10 / 4 GB performance, additional browsers, adverse browser storage conditions and the newly built version on the live HTTPS site were not tested here. No automatic deployment was performed; use the existing manual workflow when ready.

## Version 0.2.1 — Male and female careers

New Career first asks for Male Athlete or Female Athlete. A fresh draft has no choice selected. Both use the existing creator layout, kit, three origins and every existing customization option. Back/Next retain the selection; summary and Continue show the category. Procedural shoulder/hip profiles are modest visual defaults, not athletic modifiers; all body/hair/color controls remain available and unchanged. Logo, branding assets, track and movement input are unchanged.

The new `AthleteCategory` utility supplies stable IDs, labels and future `category/event_id` namespaces. No category-specific competitions, records, opponents or progression are implemented. The new v3 save requires a selected category; existing v1/v2 records still load. V2 missing category stays absent in serialized data and is shown as Not selected (legacy), using the original neutral appearance. It is never guessed from a name or body. Normal position saves do not silently reclassify or migrate a legacy career. The existing replacement dialog and backend authorization guard still apply.

The existing manual-only Pages workflow also runs the category-native suite and a separate-process reload check for both categories. No deployment is dispatched by this change.

### Version 0.2.1 observed verification — 2026-11-09

- **198 native assertions pass** across prototype, creator, category and reload suites. Both categories traverse all three origins with every customization control; Back/Next and switching category preserve entered appearance/identity. Tests check category-aware save/load, modest distinct model profiles, future namespace isolation, invalid/missing categories, cancellation/replacement authorization, v1/v2 compatibility and separate-process reload for both male/female fixtures.
- **48 real Chromium assertions pass** (Chromium 156.0.8078.79, Linux headless/SwiftShader WebGL 2), served under `/road-to-gold/` locally. The browser verifies the immediate category screen, no implicit selection, differing rendered silhouettes with equal measurements, both full creation/customization/summary paths, Back/Next, schema-3 saving, cancellation and acceptance of female-over-male replacement, movement/position saving, page reload and full browser restart for both categories. A copied v2 profile stays unselected; Continue leaves its save bytes unchanged and position saving retains schema 2 with no category.
- No browser/engine console errors or warnings, uncaught JavaScript errors, failed requests or HTTP errors were recorded in the verified run. An initial OCR assertion missed a category label wrapped across two HUD lines; the test driver was corrected and the full run repeated successfully.
- Web export succeeds with the existing single-thread Compatibility preset. No new branding assets, textures, mesh types, runtime dependencies or category-specific sport mechanics were added. Native regression testing caught a schema-number comparison issue (JSON numeric values versus array membership); explicit version comparisons corrected it before the successful native/browser runs.
- Evidence: `tests/category_verification.json`, `tests/web-evidence/male-category-preview.png` and `tests/web-evidence/female-category-preview.png`. Native reproduction: run `tests/category_support_test.gd`, then `-- --reload-categories` with the same user data directory. Existing prototype/creator suites remain available and are also run by the manual workflow.

Remaining limits: older careers remain unselected; this patch does not add an edit/migration UI for assigning a category to existing progress. Separate competitions, records, opponents, story paths and progression are future work; only explicit identifiers/context hooks are prepared. Windows 10 / 4 GB performance and additional browsers remain unmeasured. Source is committed/pushed to main; deployment remains an explicit manual action, not part of this task.

## Version 0.2.2 — THE LOCKER ROOM

The creator has five steps: **Choose Your Athlete**, **Your Story**, **Your Appearance**, **Your Identity**, **Begin Your Legacy**. Both categories share all three origins and every original control. Identity displays the age derived from the origin. Back/Continue, Escape and returning from the main menu preserve the session draft; final **BEGIN CAREER** uses the existing replacement dialog and repository authorization.

One shared procedural room contains lockers, a bench, dark floor/walls and a simple overhead light strip. An orthographic camera stays fixed across all steps and all appearance choices. The preview updates only while visible; lighting has no shadow maps, textures, animation or post-processing. Explicit male/female models gain modest neck/shoulder transitions, balanced arms, hands and training shoes. Uncategorized legacy models retain their original geometry and kit. No logo asset, track, movement or competition system is changed.

UI now uses native window dimensions instead of shrinking the whole interface into a 1280×720 letterbox. Below 900 pixels wide, the form and preview stack vertically. Forms scroll independently and follow keyboard focus; navigation stays outside the scroll area. Native buttons, dropdowns and inputs support Tab/Shift+Tab, Enter/Space and arrow keys; a gold outline identifies keyboard focus, text labels identify all options, and selection uses text plus a border. Editing widgets/popups consume their own cancel keys; Tab to Back/Continue for step navigation. Canvas-based Godot UI does not supply an HTML form accessibility tree; screen-reader support has not been verified. Desktop browser use remains the target.

There are **no new save fields or migrations**. The path, validation limits, country and origin IDs, category contract and schemas 1/2/3 are preserved. Continue never invents a category for a legacy career. Browser-local limitations described above still apply.

### Reproduce the locker-room checks

Run all existing native commands above, then:

```sh
godot --headless --path . --script tests/locker_room_test.gd
```

The manual-only Pages workflow includes this additional native suite. It remains `workflow_dispatch` only, with deployment disabled by default. This update does not dispatch it.

Export and serve using the existing instructions above (`godot --headless --path . --export-release Web builds/web/index.html`, then `python -m http.server 8000 --directory builds/web`). Open `http://localhost:8000/index.html`; never use `file://`. To test persistence, confirm a career, move with WASD, choose Save & Menu, reload, then Continue; close and reopen the same browser/profile/origin and repeat. Back up real progress before testing confirmed replacement. Use a disposable browser profile for destructive replacement checks.

Screenshots, actual test totals and remaining verification limits are recorded in [the 0.2.2 verification report](tests/LOCKER_ROOM_VERIFICATION.md). Historical reports below/above retain the behavior and counts of their dated versions.

### Version 0.2.2 observed verification — 2026-11-09

**260 native assertions and 135 real Chromium checks pass.** Import, 120-frame main-scene smoke and official matching single-thread Web exports pass, including from the actual Git checkout. Both category paths, every origin/appearance control, identity validation, draft retention, summary, replacement protection, movement, Continue, page/browser restart, legacy formats, keyboard focus scrolling and five-step navigation at five resolutions were exercised. No warnings/errors were recorded in the completed runs. [Full results, all five screenshots, changed files and limits](tests/LOCKER_ROOM_VERIFICATION.md); [raw evidence](tests/locker_room_verification.json). No deployment was performed. Windows 10 / 4 GB performance and live-host/other-browser verification remain pending.

## Version 0.2.3 — GOLDEN ROAD

The approved Cinematic Split menu uses the official full logo, three-line tagline, New Career / Continue / Settings actions and a discreet version from `application/config/version`. Its symbolic road curves into a distant warm light with subtle edge bevels and dark horizon layers. The camera and lighting are static. A single generated 64×64 radial texture supplies the soft glow; there is no bloom, fog, particle system, camera movement or intro delay. The actual athletics track, its camera, controls and physics remain unchanged, and are shown only when playing.

The full logo is approximately 25% larger than the initial 0.2.3 foundation, with aspect ratio/transparency preserved. Original approved PNGs remain byte-for-byte unchanged. Small derivatives provide the menu image, the Locker Room header emblem, project/Web icon and embedded loading emblem. The loader still reports actual engine download progress and disappears as soon as startup finishes. The country/origin catalogs, five creator steps, body models, independent full-body preview camera, save schemas and user-data directory are unchanged.

A fresh menu says **Your journey begins here.** Continue stays disabled until a valid save exists. Career saves show the saved athlete's first and last name; position-only legacy saves say Saved progress available. Long names use an ellipsis with the full text available on hover. Successful Save & Menu keeps the athlete caption with save feedback in its tooltip; failed saves or nonpersistent browser storage still show a visible warning. No name or category is invented for old saves.

Use the existing native/export/local-server instructions above. The new focused suite is:

```sh
godot --headless --path . --script tests/golden_menu_test.gd
```

Official matching Godot 4.6.3 Web templates remain required. The manual Pages workflow includes this suite and still requires explicit dispatch; no automatic deployment is enabled. Source full-resolution PNGs and the owner's ZIP remain in Git but are excluded from Web exports. The game adds no runtime dependencies. See [asset provenance](assets/licenses/README.md) and [the Golden Road verification report](tests/GOLDEN_ROAD_VERIFICATION.md) for actual tests, screenshots, changed files and limits.

The v0.2.3 preview-facing correction rotates only the creator preview instance 180°: model-forward (-Z) faces the fixed camera on +Z, with the ponytail behind the head. This constant orientation is shared by all five steps and both categories. Camera transforms, the shared athlete model, gameplay instance and serialized appearance data are unchanged.

### Version 0.2.3 observed verification — 2026-11-09

**332 native assertions and 129 real Chromium checks pass.** All existing native suites remain unchanged; 72 additional menu/branding/name/facing checks pass. The final facing correction rotates only the preview instance toward the unchanged camera, leaving shared/gameplay models and save data alone. Core browser checks cover menu/loader/five resolutions, both complete creation paths, every appearance field, names, confirmation, input, page/browser restart and genuine schema 1/2/3 profiles; final focused checks cover both front-facing previews and stable framing. Official matching single-thread Web export succeeds. No runtime/console/storage/network warnings/errors were recorded in completed runs. [Full report, changed files, screenshots and limits](tests/GOLDEN_ROAD_VERIFICATION.md); [raw evidence](tests/golden_road_verification.json). Windows low-end performance, other browsers and live-host verification remain untested. No deployment was performed.

## Version 0.2.4 — Athlete Studio 2.0

The five-step creator now uses selectable category/origin cards, a pinned Appearance title/subtitle/tab bar, and native Hair / Skin / Body panels. Drawn 2D silhouettes are larger; hairstyle icons use small procedural shapes. All four hairstyles, five hair colors, six tones and existing numeric bounds remain unchanged. Gold sliders have exact numeric companions. Height/weight appear in Body and Identity but share the same native Range values, so either view updates the other immediately. Tabs retain their state in the session and reuse one preview/model/locker room.

The fixed right preview keeps the existing orthographic camera and shared model. Only the preview instance has a clearer, constant three-quarter yaw; neither the camera nor gameplay athlete rotates. No facial cues, new models, textures or 3D environment changes are added. Controls scroll beneath the pinned heading/tabs with 16 px right/bottom padding; Back/Continue/Begin Career remain outside that scroll area.

Legacy now uses a compact graphite Player Card: a small official emblem and horizontal ATHLETE PROFILE heading, prominent name, country/category/origin/derived age, then seven actual appearance metrics in two columns. The header has an explicit minimum width and horizontal expansion rather than rotating text. There are no invented sporting ratings. Unconfirmed drafts never write, and replacement still requires the original dialog and backend authorization.

All three save schemas, field meanings, catalogs, validation, category handling, menu, loader, movement and gameplay track are preserved. No migrations or new saved fields are introduced. See [the pre-implementation mapping](tests/ATHLETE_STUDIO_MAPPINGS.md) and [Studio verification](tests/ATHLETE_STUDIO_VERIFICATION.md) for controls, screenshots, actual results and remaining limitations.

Run the existing native commands above and:

```sh
godot --headless --path . --script tests/athlete_studio_test.gd
```

Web export/local serving instructions remain unchanged. The workflow remains manual-only; this milestone does not deploy automatically.

## v0.2.4.1 — Athlete Studio Refinement

This release adds six male and six female hairstyles, category-specific draft selections, and Appearance-only height/weight controls. Original saved hair IDs 0–3 retain their names and geometry; new IDs 4–15 are appended without a schema change. Story and Player Card layout are unchanged. The production body is retained; no experimental GLBs are used.

Run `godot --headless --path . --script tests/studio_refinement_test.gd` in addition to the existing regression suites. Browser export/serving instructions above still apply. See [refinement verification and screenshots](tests/STUDIO_REFINEMENT_VERIFICATION.md). Visual approval and release authorization were received on 2026-11-10. The manual Pages workflow runs all 521 native assertions, including this refinement suite.

The latest geometry-only follow-up is documented in [final hairstyle polish comparisons and verification](tests/HAIRSTYLE_POLISH_VERIFICATION.md). This supersedes the earlier hairstyle pictures and records the visually approved geometry. Historical review reports retain their original pre-approval status for provenance.

Release verification is recorded in [the v0.2.4.1 release report](tests/RELEASE_0_2_4_1.md). Publication uses the existing manual workflow on main with deploy enabled; pushing alone does not deploy.

## Career Hub review build

Work is isolated on `feature/v0.3.0-career-hub`, based on released v0.2.4.1 (`e88438a`). The Hub is visually approved and prepared for PR review; merging and deployment require separate approval. [Audit](tests/CAREER_HUB_AUDIT.md) and [verification/screenshots](tests/CAREER_HUB_VERIFICATION.md) document this milestone.

Hub navigation is read-only. Main Menu/Escape leaves without writing; Save & Menu explicitly saves the existing position and career through the original repository. The Hub guards against missing/replaced career slots. This does not implement full multi-tab conflict resolution. No save schemas or customization IDs change.

Run the new native regression after the existing suites using isolated user data (the tests write disposable local save fixtures):

```sh
godot --headless --path . --script tests/career_hub_test.gd
godot --headless --path . --script tests/career_hub_test.gd -- --reload-hub
```

For a local browser build, export with the matching official 4.6.3 templates, then serve rather than opening `file://`:

```sh
mkdir -p builds/web
godot --headless --path . --export-release Web builds/web/index.html
python3 -m http.server 8000 --directory builds/web
```

Open `http://localhost:8000/index.html` in Chromium. Keep the same origin/port/profile for persistence tests. Create a career, inspect Hub and My Athlete, use Save & Menu, reload and Continue. Verify responsive scrolling at 1280×720 and 800×600. The existing Pages workflow remains manual-only; no workflow was dispatched.

Latest Career Hub UI polish and fresh Chromium screenshots: [review report](tests/CAREER_HUB_UI_POLISH.md). This remains a feature-branch PR review build; it is not merged or deployed.

## v0.4.0 Training foundation — PR review

In Career Hub, choose Training. Ratings start at 50.00, independently of category, origin and appearance. Each Training Day has two actions. Select Sprint Drills, Start Practice, Endurance Run or Recovery Session to preview exact changes, then Confirm & Save. Cancel changes nothing. End Training Day previews fatigue reduction and resets daily actions; it never advances athlete age or the calendar. No timers or offline gains.

The first confirmed training operation migrates a schema 2/3 career to schema 4 and keeps a verified, byte-identical original at `user://prototype_v1.json.pre-training-<content-hash>.bak`. Opening Training or cancelling does not migrate. The backup belongs to browser-local storage too; clearing site data removes it. Schema 4 is unreadable by older game versions. New careers initially use schema 3 until their first training operation. Legacy category absence and appearance IDs remain unchanged. Schema 1 still opens the original position sandbox.

Malformed/incompatible/future saves are protected even from confirmed New Career replacement; they must be deliberately backed up/recovered outside the game rather than silently replaced. Schema 4 requires valid known training rules. Position saves preserve the entire training block. Training writes compare the expected saved-file hash and only publish the candidate state after a successful write. Duplicate confirmation and stale actions are rejected. This is optimistic protection; multiple active tabs remain unsupported. Web save completion cannot guarantee survival of browser storage clearing or an immediate forced close; keep the tab open briefly.

Additional native checks, with isolated test user storage:

```sh
godot --headless --path . --script tests/training_rules_test.gd
godot --headless --path . --script tests/training_persistence_test.gd
godot --headless --path . --script tests/training_integration_test.gd
godot --headless --path . --script tests/training_integration_test.gd -- --reload-training
```

Godot 4.6.3 Compatibility single-thread Web export and local HTTP serving instructions above remain valid. No workflow has been dispatched. See [finalization](tests/TRAINING_FOUNDATION_FINALIZATION.md) and [training verification](tests/TRAINING_FOUNDATION_VERIFICATION.md) for real test results, migration evidence, screenshots and limitations.

## v0.5.0 — Development Meet and Stadium 1.0 review

The uncommitted review build on `feature/v0.5.0-stadium-rebuild` extends the race development branch. Career Hub → Enter 100m opens readiness. Choose Rhythm Sprint (alternate A/D or arrows around four presses/second) or Hold Sprint (hold Space after GO). Release sprint keys before Ready. Early presses recall the attempt; Escape or focus loss interrupts it. Eight runners race the authoritative 100m straight; the surrounding oval and athletics equipment are decorative.

Completed results show Place, Lane, Athlete and Time, with the player highlighted. Results/PB save through the existing repository; legacy athletes must explicitly select a category before racing. Original saves are backed up on migration, and training/sandbox saves retain competition data. Invalid/future/stale saves are protected.

Run all existing tests plus these focused suites in disposable user storage:

```sh
godot --headless --path . --script tests/race_simulation_test.gd
godot --headless --path . --script tests/race_persistence_test.gd
godot --headless --path . --script tests/race_integration_test.gd
godot --headless --path . --script tests/stadium_environment_test.gd
godot --headless --path . --script tests/race_animation_test.gd
```

The existing official Godot 4.6.3 single-thread `Web` preset and HTTP-server instructions still apply. No workflow or deployment is triggered. See [stadium verification, screenshots and measured limits](tests/RACE_STADIUM_VERIFICATION.md).

### v0.5.0 performance gate follow-up

Settings → Race graphics now offers **Performance (default)** and **Enhanced**. Both retain all eight runners and the complete stadium. Performance reduces the crowd and replaces costly dynamic shadows/MSAA with cheap contact shadows; Enhanced restores the approved appearance. Preferences use `user://race_graphics.cfg`, independently of career saves. The setting applies to the next race.

**1,007 native assertions, 13 additional Chromium quality checks and the official single-thread Web export pass.** Hardware GPU testing is unavailable in this cloud environment; SwiftShader FPS is not representative of normal GPU performance. See [measurements, memory, screenshots and the remaining release gate](tests/PERFORMANCE_RELEASE_GATE.md). No commit, push or deployment performed.

### v0.5.0 release PR preparation

Approved for feature-branch integration review. Fresh validation: **1,007 native assertions, 45 Chromium checks and the official Godot 4.6.3 single-thread Web export pass**. Performance is the default graphics profile; Enhanced remains selectable. Existing career/Training/PB and legacy-save protections are verified. Physical low-end Windows GPU performance and genuine browser-window blur remain unverified. See [release preparation and limitations](tests/V0_5_0_RELEASE_PREPARATION.md). The manual workflow includes all new native suites; no merge or deployment is authorized by this preparation.
