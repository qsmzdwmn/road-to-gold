# ROAD TO GOLD — Technical Design

Status: historical initialization notes followed by implemented contracts through Version 0.2.4, 2026-11-09.

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

## Version 0.2.1 category contract
`AthleteCategory` is the shared enum/label/profile/namespace utility (`scripts/data/athlete_category.gd`). `CareerData.athlete_category` stores `male` or `female` only after explicit selection. Empty in-memory category means never selected; `to_dict()` omits the field in that case. `CareerData.competition_scope(event_id)` returns `male/<event_id>` or `female/<event_id>` for a valid identifier such as `sprint_100m`, and empty for an unselected category or invalid event identifier. Future records, opponents and progression must use this common context and must not route an empty context to a default category. No such competition systems exist yet.

New careers use schema v3 and require `career.athlete_category`. V1 track probes and v2 careers remain readable at the unchanged local path. Loading a missing v2 category does not inject a field, infer a category or rewrite a file. Position saves preserve the original schema and missing category. The v2 procedural silhouette remains the neutral fallback; v1 retains the original placeholder. A future explicit legacy-category selection/migration flow would be needed before category-specific competition, and is outside this patch. V3 missing/invalid categories disable Continue and cannot be overwritten by normal track saving. Creation still requires explicit existing-slot replacement confirmation.

Category profiles adjust only existing torso, hip and limb placement transforms; material/mesh counts, outfits, control ranges and the parent movement node are unchanged. No extra textures, brand assets, dependencies, animation, race simulation or server calls are added. The existing interface and manual-only Pages workflow remain in place; CI adds category regression/reload checks.

## Version 0.2.2 presentation boundary
`career_creator.gd` retains one draft and the same ten field controls, now divided between appearance (step 2, zero-based) and identity (step 3). Category and origin steps use the existing identifiers and catalog. Validation occurs at identity/review; final confirmation still emits the existing career object to App. Numeric text is applied only for edited inputs, preventing stale text in a hidden SpinBox from replacing its current value during navigation.

`scripts/customization/locker_room.gd` owns the bounded procedural set, shared materials, ambient/directional lighting and a fixed orthographic camera. It has no physics or per-frame callback. The existing single SubViewport/athlete architecture is reused, updating only while visible. The model adds low-segment/box details for selected categories; the empty legacy category hides those details and preserves the old transforms/materials. Body geometry is cosmetic and cannot change the parent movement controller.

UI uses actual window dimensions (`window/stretch/mode="disabled"`); the creator stacks below 900 px with an independently scrolling form that follows keyboard focus and a fixed footer. Its local theme does not replace the menu/HUD theme. There are no new resources fetched at runtime, texture downloads, dependencies, shadow maps, camera animation, schema changes or migrations. The single-thread Compatibility Web preset, JSON inclusion, custom loading shell and manual-only Pages deployment contract are unchanged. Native QA covers maximum body framing at multiple viewports, camera invariance on all five screens, all four hairstyles/both models, proportions, step ordering and identity validation in addition to the preserved regression suites.

## Version 0.2.3 menu and branding boundary
`scenes/menu/golden_road.tscn` / `scripts/menu/golden_road.gd` own a small static menu set and camera. `Main._set_track_visible()` switches visibility/current camera between this set and the original Track. Both main-world sets hide during career creation; the Locker Room keeps its independent SubViewport and fixed full-body camera. Track scene/scripts/materials, movement and data objects are unchanged.

`golden_menu.gd` owns only the presentation panel, logo, action buttons, caption and version. `prototype_ui.gd` adapts it to the existing app signals and retains the previous settings and track HUD. `scripts/branding/brand.gd` shares optimized textures and derives version text from the single project metadata setting. The creator adds only the small official emblem to its existing header. Native tests preserve the original suites and add menu action/scene switching, responsive control bounds, version, immutable source-logo hashes and long-name handling.

The path is a gently curved sampled ribbon with lightweight beveled edge strips and two low dark horizon silhouettes. A static 64×64 radial texture on one transparent billboard provides distant warmth, with no depth test so the glow can soften the horizon. It has no fog, bloom, particles, animation or per-frame work. Original PNGs and archival ZIP are excluded from exports, while aspect-preserving lossless derivatives remain included. Loading embeds the small emblem to avoid another path/request dependency, keeps actual engine progress (indeterminate while total is unknown) and removes its overlay on the existing startup promise. The single-thread export and manual-only Pages workflow are retained.

SaveRepository, schema 1/2/3, career/category/appearance classes, country/origin IDs and user-data paths do not change. Main reads already validated athlete names for the menu caption; it never writes names, categories or migrations. Successful menu saving retains the name with save feedback in a tooltip; actual failed/nonpersistent saves retain visible warnings. Long menu captions/errors use one-line ellipsis with full text in the tooltip to preserve layout.

The v0.2.3 preview-facing correction rotates only the creator preview instance 180°: model-forward (-Z) faces the fixed camera on +Z, with the ponytail behind the head. This constant orientation is shared by all five steps and both categories. Camera transforms, the shared athlete model, gameplay instance and serialized appearance data are unchanged.

## Version 0.2.4 presentation components
`studio/choice_card.gd` keeps native Button input/focus/action text while arranging lightweight pictograms and labels; `choice_grid.gd` owns visible selection state and preserves `.select(index)` / `.selected` semantics. `studio_icon.gd` draws small original silhouettes/hair icons without extra assets or 3D scenes. `player_card.gd` renders actual CareerData into a compact panel; its text getter derives semantic content from the visible labels rather than a hidden summary. Horizontal profile header sizing (no wrap, min width, expansion) prevents one-character wrapping.

Creator retains one draft, one model and one SubViewport. Heading/subtitle/tab nodes live outside ScrollContainer; its content uses 16 px right/bottom padding. Native Range sharing links each HSlider/SpinBox and the Body/Identity height-weight views to the same values. Edited text is applied before tab/step changes; hidden stale text never overwrites values. UI tab state is session-only. Data classes, SaveRepository, resources/catalogs, movement, shared model and locker-room camera remain unchanged.

The preview-only yaw is 230°: model-forward (-Z) is about 30° from the fixed camera's horizontal viewing direction, with the ponytail behind the head. This stronger three-quarter view was chosen after the user requested rotation-only clarification; no face cues are added. Native tests verify positive camera-facing dot product, rear hair behind the head, unchanged camera and identity gameplay rotation, as well as maximum-body bounds. Main menu/loader use the same assets and design; only the central version becomes 0.2.4.

## v0.2.4.1 refinement (uncommitted review build)

`hairstyle_catalog.gd` reserves IDs 0–3 for the exact legacy names/geometry. New male IDs 4–9 and female IDs 10–15 are append-only; the creator's six tile indices map to these IDs. Category-specific draft memories are session-only. Appearance validation accepts integers 0–15; schema versions and serialized keys are unchanged, with no automatic rewriting of old saves. Older application versions cannot interpret the new IDs and will reject rather than overwrite those saves.

`procedural_hair.gd` bakes closed low-resolution forms into one material surface and shares immutable style meshes. Only hairstyle changes build a previously uncached mesh; color and body changes reuse it. The existing production body dimensions, preview yaw/static camera and movement are retained. IDs 0–3 still use the original hair primitives. No Blender assets enter production.

Height and weight now have one canonical numeric editor each, in Appearance Body alongside shoulders and legs. Identity contains names, country and derived age only. Player Card code/layout and Story logic remain unchanged.

## v0.3.0 Hub integration
`scenes/ui/career_hub.tscn` and `scripts/ui/hub/career_hub.gd` own read-only presentation; Main owns routing and save requests. The existing repository, career DTO, schemas 1/2/3 and customization identifiers remain unchanged. Overview is 2D; My Athlete lazily reuses the stable procedural athlete/locker room in a static viewport, disabled when hidden. Content scrolls independently of sidebar/header/footer; Overview retains two compact event/record columns at both supported widths; My Athlete stacks at narrow widths. Existing Player Card and creator sources are unchanged. Hub Save & Menu verifies the current slot still holds the same career before delegating to the existing writer; no multi-profile or transactional multi-tab system is introduced. Shared Settings returns to the prior Hub page.

## v0.4.0 Training architecture
`training_state.gd` owns defaults, strict validation and JSON-to-integer normalization. `training_service.gd` owns the authored activity catalog and a pure deterministic calculate function shared by preview and repository confirmation. Ratings use integer hundredths; gains use integer arithmetic/half-up rounding. `training_panel.gd` presents ratings, fatigue, actions, previews and explicit before/after results. The existing Hub/application/repository retain their routing/write responsibilities.
Schema4 adds a versioned top-level training block beside unchanged career/position data. Schemas1/2/3 remain readable without writes. First training commit verifies an original-content-hash backup, validates/recalculates the command, checks the expected full-file token and writes through the original temporary/rename path. Only successful writes publish the new authoritative UI state. Every position-save path preserves training. The UI pending-command guard plus content tokens prevent duplicate/stale application; they are not cross-tab atomic transactions. Day/revision use JSON's exact integer range, a storage precision constraint rather than a designed career-length cap. Future career calendars/competition systems must explicitly map abstract training days and consume a read-only rating profile; sandbox speed remains fixed.

## v0.5.0 review — race and stadium boundary

`sprint_physics.gd` advances pure metre-space runner state at 60Hz with interpolated finish crossing. `sprint_input.gd` validates edge/alternation/repeat input and effort; `race_session.gd` owns starter phases, reaction, interruption and completion. `race_roster.gd` supplies seven fixed profiles. `competition_data.gd` validates canonical eight-runner results, classification, content identity and category PB.

The repository adds an optional versioned `competition` block inside schema 4, preserving its training and position fields through every writer. Result commands carry the expected full-save token and career fingerprint. Incompatible/future/malformed or changed saves are rejected; duplicate result IDs are idempotent. Schema 2/3 migration keeps a byte-original verified backup before writing. This remains local file storage plus asynchronous browser IndexedDB synchronization, not an atomic multi-tab database.

`race_screen.gd` presents readiness/HUD/results in a race-only reduced-resolution 3D SubViewport; the 2D UI stays full resolution. `race_leaderboard.gd` is a read-only classification view with a separately scrolling table and fixed action buttons. `race_world.gd` binds each model to lane x=lane−3.5 and z=−distance and uses a fixed-offset follow camera. A small race-instance-only vertical lift clears the stable model’s shoe geometry from the new track surface.

`race_course.gd` builds a coherent oval plus the authoritative straight, covered stands, shared static material batches, one instanced crowd, infield props and perimeter structures. Arcs are explicitly indexed before appending to indexed box batches, preventing unreferenced bend geometry. The track is 100m on the original 1m lane-centre spacing; the decorative oval is stylized, not a certified 400m layout. Lighting uses one directional orthogonal shadow map; no dynamic crowd simulation, textures, experimental models or post-processing effects are added.

Race-only presentation now extracts the stable model’s existing limb boxes into simple hip/shoulder pivots. `race_animation.gd` drives opposing strides from actual runner speed, smooths idle and acceleration lean, and corrects shoe contact without touching simulation coordinates. `race_limb_batch.gd` renders 48 skin parts and 16 shoes through two shared cube MultiMeshes with per-athlete colors; static body/hair/clothing stay batched under the lean pivot. No skeleton, animation asset, shared-model edit or save field is introduced. The lower player-follow view is primary. An optional static establishing view is available only in readiness; Ready cuts directly to the lower camera. The live HUD has a compact navy panel.

Race quality preferences are isolated in `race_quality.gd`/`user://race_graphics.cfg`; no career schema or writer changes. Performance is the production default and uses no shadow map/MSAA, a uniformly sampled 116-instance crowd sharing the original mesh/material, and one feathered unlit contact-shadow batch. Enhanced restores the original 346-instance crowd, dynamic shadows and 2× MSAA. All static architectural mesh data and actor simulation/camera/HUD contracts remain unchanged. See `tests/PERFORMANCE_RELEASE_GATE.md` for actual measurements and unsupported hardware claims.
