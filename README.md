# road-to-gold

## ROAD TO GOLD — Version 0.2

A Godot **4.6.3 standard / GDScript** career-creation prototype using the **Compatibility** renderer. No paid assets, APIs, plugins, services, or project dependencies. Version 0.2 adds origins, athlete customization with a live procedural 3D preview, a summary and confirmed local career saving. The existing dark menu, settings/help, test track, camera, lighting and keyboard movement are preserved. There is no story, career-year simulation or sprint race yet.

## Run locally

1. Install/extract Godot 4.6.3 **standard**, not the .NET build. Import `project.godot` in the Project Manager.
2. Press **F6** with `scenes/app/main.tscn` open, or **F5** to run the project.
3. Select **New Career** → **Choose Origin** → **Customize Athlete** → **Review Career** → **Create Career**. Use Back/Next without losing choices. The last button saves and opens the test track; existing progress requires a replacement confirmation. **Continue** loads either an existing v0.1 track session or a v0.2 career.
4. Move with **WASD or arrow keys**. **Escape** returns to the menu without saving. **Save & Menu** writes the current position. **Continue** restores it. **Settings → Back** returns to the menu.
5. Losing application focus pauses movement; choose **Resume** to continue. The track limits exploration to its marked area.

Command-line alternative, from the project root:

```sh
godot --path .
```

On Windows use the Godot executable's full path if it is not on PATH. For terminal logs/headless checks, use the corresponding `_console.exe` executable. Godot is the only requirement to run or test the native project. No audio, AI, story events, career progression, sprint timing or sports mechanics are implemented.

## Save behavior

`user://prototype_v1.json` remains the local slot for compatibility. Version 1 `track_probe` saves contain a position only; Version 2 `career` saves add origin, derived starting age, names, country code and all appearance fields, while retaining position separately. The custom user directory remains `road-to-gold-prototype`; on Windows the normal path is `%APPDATA%/road-to-gold-prototype/prototype_v1.json`. Use Godot's **Project → Open User Data Folder** to locate it.

Opening New Career never writes this file. All creator steps share an in-memory draft; Back/Next and returning to the menu retain it within the session. A page reload discards unconfirmed drafts. Only final Create Career commits a new record; if any slot already exists, a confirmation dialog must be accepted before replacement. Invalid names/data block creation. Failed writes leave the old save intact and keep the editable summary visible with an error.

Continue reads either schema; a legacy save is never automatically rewritten or assigned an invented athlete. Save & Menu stores track position while preserving the complete career or the original legacy format. Escape/menu without saving does not update position. Invalid/unsupported saves disable Continue, show an error and remain unchanged unless the user explicitly confirms replacement. Writes use a temporary file then rename. Full backup/migration, multi-tab conflict handling and import/export remain future work.

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
