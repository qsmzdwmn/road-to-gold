# v0.5.1 Stadium Audio — release PR preparation

All ten original audio assets, audio design and Settings UI have explicit owner
listening/visual approval. Commit/push/PR preparation is authorized; merge and
deployment require later explicit approval. No v0.6.0 development is included.

## Branch and scope

`feature/v0.5.1-stadium-audio` is based on fetched `origin/main` at
`361b85e1d7286eb0b2c6fb5daa84740bc4946317` (v0.5.0). The experimental Blender branch
remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58` and was not modified.

Changes add the persistent mixer, three category buses, validated independent
preferences, Settings controls, authoritative race presentation hooks, ten
original assets, offline source generator, native/browser/package tests and
documentation. No race formula, AI profile, Training rule, save schema, athlete
model, Player Card, stadium geometry, sandbox movement or camera was changed.
Project and visible menu metadata are v0.5.1.

Temporary preview websites, converted listening copies, preview-site builder,
preview-only tests and audio-review recordings were preserved outside this
repository. They are absent from this release and from the exported package.
The offline source generator no longer writes a listening webpage. tools/, tests/
and work/ are excluded from Web exports. Original approved Ogg/WAV files were
not regenerated or modified; their ten SHA-256 hashes match the approved manifest.

## Final fresh verification

| Verification | Result |
|---|---|
| Complete native suite | **1,088 assertions passed**, 26 import/start/test invocations |
| Main Chromium audio/gameplay suite | **50 checks passed** |
| Chromium legacy compatibility suite | **13 checks passed** |
| Official Web export | Godot **4.6.3.stable.official.7d41c59c4**, Compatibility, single-thread release |
| Export inspection | **13 assertions passed**: ten streams load with expected duration, buses, quality and scope |
| Native/browser runtime errors | None recorded in final runs |
| Approved audio bytes | All ten original source hashes unchanged |

The main browser suite verifies interaction gating; original music/crowd looping;
independent sliders and Mute All; separate audio/graphics configuration; persistence
after reload; Enhanced selection and restored Performance; character creation;
a real Training action; both Hold and alternating-key Rhythm races; false starts
and retry; exactly one pistol per actual GO; gait footsteps; finish/new-PB cues;
saved PBs and Training preservation; race audio cleanup on Hub return; interrupted
attempts; and actual AudioContext suspension/resumption. The race-exit check waits
for actual Web Audio sources to stop, allowing intended Hub music/UI audio.

The separate local-only legacy suite confirms uncategorized schema 2 readiness
is read-only, category selection is explicit, migration preserves legacy appearance
and age, the exact original save is backed up, a female-category PB is saved with
Training unchanged, reload retains it, and future competition data is not overwritten.
Native coverage also retains schemas 1–4 and protected failed/stale/future writes.

The exported PCK header identifies Godot 4.6.3; project metadata reads 0.5.1.
Every PCK entry checksum is verified. All ten imported AudioStreams are loaded
from the PCK in a fresh isolated Godot process, with no source-project resource
cache. The inspector confirms four buses, Performance default and the absence
of preview HTML, tools, tests, work files and experimental GLB/Blender models.
`tests/verify_audio_export.py` reproduces this and is registered in the existing
manual build workflow. Its deployment trigger/gating remain unchanged.

## Evidence and reproduction

Fresh JSON results and screenshots are under
`tests/web-evidence/audio-release-0.5.1/`. Historical audio UI/focus/performance
observations are retained under the earlier audio evidence folders and are not
counted again in these fresh totals. Developer-local browser profiles, PCK/WASM
build output and temporary review media are not committed.

Use the manual workflow's native command list with isolated test user storage.
For the Web package:

```sh
godot --headless --path . --export-release Web builds/web/index.html
python3 tests/verify_audio_export.py builds/web/index.pck
python3 -m http.server 8000 --directory builds/web
python3 tests/browser_audio_verification.py --url http://localhost:8000/index.html
python3 tests/browser_audio_legacy_verification.py --url http://localhost:8000/index.html
```

Browser QA needs developer-only Playwright, Chromium, Tesseract, Pillow and NumPy.
The game needs none of these. Both scripts create disposable browser profiles;
legacy fixtures enforce a local-only origin and never access production saves.
The audio generator is provenance tooling; do not regenerate approved source
files without review. No paid services or runtime dependencies were introduced.

## Remaining limitations

- Physical Windows 10 / 4 GB RAM GPU performance is unverified. This executor
  uses SwiftShader; software FPS is not representative of normal GPU performance.
- Earlier audio-on/off software comparisons showed similar frame times and
  unchanged draw calls, but do not prove zero cost or establish a hardware budget.
  Renderer/JS memory observations include scene allocations and garbage collection;
  Godot's exported static-memory monitor is unavailable here.
- Physical speaker latency and physical iPhone Safari behavior are unverified.
  Actual Web Audio output and buffer dispatch were tested in Chromium; audible
  physical synchronization is not claimed as sample-exact.
- Real headed browser focus loss passed in earlier verification with Playwright
  focus emulation disabled. The fresh headless interruption test explicitly records
  focus state and uses Escape. Actual AudioContext suspension passed. Synthetic
  freeze/resume events test callbacks, not actual browser page freezing; genuine
  hidden-tab freezing remains unverified in this environment.
- The application emitted no audio before trusted interaction. The test browser
  initially allowed its AudioContext to run, so naturally blocked first-load
  autoplay is not independently claimed. Recheck additional browser policies.
- Browser-local storage can be temporary or cleared. Existing filesystem-write
  success does not guarantee persistence after immediately closing a tab; the UI
  preserves the existing storage notices and failed-save protections.

The owner has approved the sounds themselves. Final merge and deployment remain
separate decisions; this milestone prepares a PR only.
