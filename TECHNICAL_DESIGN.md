# ROAD TO GOLD — Technical Design

Status: proposed architecture; documentation only, 2026-11-09.

## Repository and engine inspection
Inspected /workspace including hidden entries and searched for AGENTS.md. No project, source files, project.godot, or local agent instructions were found. The .git directory is empty and `git status --short` reports that this is not a Git repository. Existing library-files, scratch and shared directories are environment scaffolding; preserve them.

Both /usr/local/bin/godot and /usr/local/bin/godot4 are accessible. Both `--version` invocations returned `4.6.3.stable.official.7d41c59c4` with a Fontconfig writable-cache warning. This establishes CLI availability only. No project import, editor launch, scene, performance test, race test, save test, or Web export was run. Export-template directories were not found at /root/.local/share/godot/export_templates, /home/agent/.local/share/godot/export_templates or /usr/share/godot/export_templates; other locations were not exhaustively searched. Template availability remains unverified. The cloud check does not establish installation on the user's Windows PC.

## Toolchain and setup
Propose pinning Godot 4.6.3 standard (GDScript) and matching export templates, subject to the first Web spike. Use Compatibility, not Forward+ or Mobile. No C# runtime or external package manager is required.

Windows 10 setup if Godot is absent: download the free standard Windows build from https://godotengine.org/download/windows/; extract to a writable folder, launch the executable, and verify its version with the console executable's `--version`. Install exactly matching templates through Editor → Manage Export Templates. After approval, create/import project.godot with Compatibility and add a Web export preset. Serve exports over localhost using a lightweight HTTP server (for example Python's `python -m http.server 8000` from the export directory if Python is installed), then open localhost:8000. Do not open exports via file://. Test the intended free HTTPS host separately. Offline editor setup and Web template downloads are separate prerequisites. Consult the matching Godot version's Web export documentation before selecting export options.

## Planned folder structure
Only the four Markdown documents exist as deliverables now. The following directories and files are planned, not created:

```text
project.godot
export_presets.cfg
GAME_DESIGN.md
TECHNICAL_DESIGN.md
ROADMAP.md
TASKS.md
assets/
  materials/
  audio/
  fonts/
  licenses/                 # license text and attribution manifest
scenes/
  app/                     # root, transitions
  ui/                      # menu, creator, origin, story, hub, results
  athletes/                # procedural visual rig
  race/                    # track, race scene, runner visual
scripts/
  data/                    # AthleteData, AppearanceData, configuration
  customization/           # preview builder and validators
  career/                  # CareerState and transitions
  story/                   # event loading and effects
  race/                    # RaceSimulation, RaceSession, FinishRecord
  input/                   # PlayerSprintInput, remapping
  ai/                      # AIRunnerController
  results/                 # ranking, PB updates
  persistence/             # SaveRepository, migrations, validation
resources/
  origins/
  story_events/
  race_configs/
  countries/
tests/                     # headless logic checks and manual Web checklist
builds/web/                # generated, excluded from version control
```

Keep .godot/, generated builds, and temporary files out of version control. Commit source resources and project settings, never credentials. Add a real Git repository only after implementation approval.

## Ownership and contracts
Use typed modular GDScript classes, small scenes and signals. App scene owns navigation and the current CareerState. SaveRepository is the only persistence boundary; no broad mutable global service locator. Autoload use, if any, must be minimal and explicit.

| Module | Owns | Boundary |
| --- | --- | --- |
| AthleteData | Stable ID, name, country code, birth/start age, sporting attributes | Validated data, no UI or file access |
| AppearanceData/customizer | Colors, hair IDs, dimensions, procedural preview | Reads appearance only; cannot mutate sporting stats |
| CareerState | Origin, age, story flags, support, confidence, PB, last result | Sole authoritative career snapshot |
| StoryEvent | ID, text, choices, conditions, allowed effects | Data-driven resources, validated IDs; no arbitrary script execution |
| RaceSession | Roster, config, seed, transient state | Snapshot career data; never mutate career mid-race |
| RaceSimulation | Fixed-step movement, reaction, stamina, finish crossings | Accepts intent, emits state/results; no UI/input/save access |
| PlayerSprintInput | Action edges, alternation, focus and repeat filtering | Emits timestamped intent |
| AIRunnerController | Seeded reactions and rhythm intentions | Same movement rules as player |
| ResultsService | Immutable records, ranks, valid PB comparison | Commits completed result to CareerState once |
| SaveRepository | Schema, serialization, validation, migrations, recovery | Reads/writes primitive dictionaries at user:// |

Use custom Resources for authored origin, race and story configuration; stable IDs, bounded numeric fields, and validated references. Serialize saves as explicit JSON dictionaries, never arbitrary object deserialization. Runtime race state is separate from reusable authored resources to avoid shared-resource mutation.

## Race and transitions
Start with fixed 60 Hz simulation; evaluate performance before changing it. All timing uses simulation ticks plus sub-step crossing fractions, not rendered frames or system wall time. Input edges are consumed once. Keep simulation independent of Node3D transforms; visuals interpolate progress. Seven AI controllers use seeded local randomness. Finish order waits for all eight athletes; a configurable timeout handles stalled runners as DNF, never fabricated times. Define shared-rank display for exact ties and preserve raw times.

Use explicit app/race state enums and guarded transitions to prevent duplicate result commits. Pause on focus loss; clear held inputs and accumulator on resume. Save career on confirmed creation, story choice and result commit. Interrupted races restart from the hub and do not create a result. No mid-race restoration in Alpha.

## Browser persistence
Use Godot user:// through FileAccess; Web persistence depends on the engine's browser virtual filesystem backed by IndexedDB and its synchronization behavior. Verify exact flush behavior for the pinned engine; closing a tab immediately after a write is not proof of durability. Do not promise guaranteed saves from a successful file-open alone.

Schema v1: schema_version, revision, athlete, appearance, career (origin/start age/current age, flags, consequences), personal_best, last_result, settings. Store only completed career transactions. Validate required fields, finite numbers, ranges, known IDs and schema versions. Reject future schemas without overwriting them. Implement explicit migrations when versions change. Keep a last-known-good backup and use staged writes/rename where supported; verify browser behavior rather than assuming desktop atomicity. Restore backup only after validation and user notice. Corrupt data must show recovery/new-career options without silently deleting it.

Storage is scoped to browser profile and site origin. Private browsing, denied storage, quota limits, site-data clearing, browser eviction, switching host/domain or using another device can lose access. On failure, keep session playable and show an honest unsaved-state warning. Provide manual JSON export/import of the versioned career with validation, file-size limits and explicit replacement confirmation. Document that browser-local saves do not sync. Prefer a single active tab; detect conflicting revisions and warn before overwriting where feasible.

## Web and performance risks
| Risk | Mitigation / required evidence |
| --- | --- |
| WebGL 2 unavailable or GPU/driver blocked | Compatibility still requires suitable WebGL 2 support; test target browsers and show a clear unsupported-browser message |
| Export templates/options mismatch | Pin engine/templates; verify exported minimal page before gameplay investment |
| Threading and host headers | Prefer a single-thread Web export where the pinned version supports it; verify. If threads are enabled, validate HTTPS, cross-origin isolation and COOP/COEP headers and embedding restrictions |
| 4 GB shared RAM / integrated GPU | Tiny procedural assets, shared meshes/materials, bounded geometry, no heavy physics, post-processing or real-time shadows initially; profile Windows hardware, not cloud hardware alone |
| Main-thread stalls | Prebuild/prewarm eight runners; avoid allocation, resource loading or save writes during a race; cap catch-up work |
| Browser background throttling | Explicit pause/resume and simulation clock; test focus changes and held keys |
| Local data loss / write failure | Recovery, backup, import/export, unsaved warning and reload tests on the same origin |
| Input repeat, focus, keyboard layout | InputMap actions, edge filtering, control remapping and browser keyboard tests |
| Audio/autoplay and network loading | Start audio from user interaction; optional audio; test asset paths and MIME types on actual host |
| Asset/IP errors | Procedural originals and attribution ledger; no protected branding |

Provisional budgets, not measured results: 30 FPS minimum during eight-runner race at 1280×720 on the agreed 4 GB Windows 10 baseline; stretch 60 FPS. Target initial compressed transfer ≤20 MB and browser process memory ≤512 MB after warm-up, with repeated-race growth investigated. Measure using a fixed browser version, hardware/GPU record, ten-race run and frame-time capture. Total system memory pressure matters; editor, browser and background applications must be accounted for. Baseline CPU/GPU and browser versions remain open, so performance acceptance cannot yet be claimed.

## Version 0.2 implemented boundaries
Career creation uses `AppearanceData`, `AthleteData`, `CareerData` (typed RefCounted data objects), an authored JSON catalog of origins/countries, a separate `CareerCreator` scene, and a procedural cosmetic model shared between preview and the track athlete. App owns screen transitions and final save commits; the preview and data objects cannot alter movement speed. Story/career simulation is not implemented.

The existing SaveRepository now reads the unchanged v1 `track_probe` record or v2 `career` record from the same `user://prototype_v1.json` path. V2 adds `career: {origin_id, age, athlete: {first_name, last_name, country, appearance}}`; track position remains separate. Loading v1 never rewrites/migrates it. Save & Menu keeps its loaded schema and preserves career fields. Unknown, malformed or oversized records disable Continue and remain untouched. New career replacement requires explicit authorization in both App and repository; commits use temp-write/rename. Full backup/recovery, migration chains, import/export and multi-tab revision handling remain future work; they are not claimed by this schema extension.

Export includes authored `*.json` while retaining exclusions for tests/work. The standalone ROAD TO GOLD loading shell and boot branding are unchanged. The existing single-thread Compatibility export and static procedural track remain in place.

Appearance preset indices are stable within schema v2; changing their ordering requires a migration. Proportions serialize to two decimal places using decimal division, so valid minimum/maximum settings remain inside their declared ranges.
