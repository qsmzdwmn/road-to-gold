# road-to-gold

## ROAD TO GOLD — Implementation 01

A small Godot **4.6.3 standard / GDScript** technical prototype using the **Compatibility** renderer. No paid assets, APIs, plugins, services, or project dependencies. It contains a dark menu, settings/help panel, procedural flat track, low-poly placeholder athlete, static camera and basic lighting. It is not Alpha 0.1 or a career/race simulation.

## Run locally

1. Install/extract Godot 4.6.3 **standard**, not the .NET build. Import `project.godot` in the Project Manager.
2. Press **F6** with `scenes/app/main.tscn` open, or **F5** to run the project.
3. Select **New Career** to start the track probe. If a prototype save already exists, confirm before replacing it. **Continue** is enabled only for a readable, supported save.
4. Move with **WASD or arrow keys**. **Escape** returns to the menu without saving. **Save & Menu** writes the current position. **Continue** restores it. **Settings → Back** returns to the menu.
5. Losing application focus pauses movement; choose **Resume** to continue. The track limits exploration to its marked area.

Command-line alternative, from the project root:

```sh
godot --path .
```

On Windows use the Godot executable's full path if it is not on PATH. For terminal logs/headless checks, use the corresponding `_console.exe` executable. Godot is the only requirement to run or test the native project. No audio, character creation, AI, career progression, sprint timing or sports mechanics are implemented.

## Save behavior

`user://prototype_v1.json` contains only `{schema_version: 1, kind: "track_probe", position: [x, z]}`. This deliberately separate probe file is not the future career schema. The custom user directory is `road-to-gold-prototype`; on Windows the normal path is `%APPDATA%/road-to-gold-prototype/prototype_v1.json`. Use Godot's **Project → Open User Data Folder** to locate it. Do not delete unrelated files.

New Career writes an initial position; later movement is saved only with Save & Menu. No automatic save on tab close or Escape. Invalid/unsupported saves disable Continue, show an error and remain unchanged until the player explicitly confirms replacement. Writes use a temporary file then rename; failures show an unsaved warning and leave the session playable. Full backup/migration, conflict detection and import/export belong to later T03, not this probe.

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
```

Run the last two in order with the same user data directory: the first creates an isolated `user://tests/prototype.json` fixture, and the second verifies it in a separate process. They do not overwrite the interactive prototype save. Keyboard verification uses injected physical key events through Godot's InputMap, not a human pressing keys or a browser. UI-fit checks inspect container bounds; they are not screenshots or visual/accessibility certification.

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
