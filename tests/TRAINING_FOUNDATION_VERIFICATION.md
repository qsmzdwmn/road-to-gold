> Implementation and screenshots approved. Feature-branch commit/push and PR are authorized; merge/deployment require separate approval. See [finalization](TRAINING_FOUNDATION_FINALIZATION.md) for the latest rerun and polish evidence.

# v0.4.0 Training foundation — pending visual and functional approval

## Repository and scope

Work is isolated on `feature/v0.4.0-training-foundation`, based on verified latest main `7ffe6264e0e89ac96d714079a9073eef845fea73`. No commit, push, merge, workflow dispatch or deployment. The experimental Blender branch remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58`.

Implemented the approved deterministic training baseline: four ratings at 50.00; fatigue 0–100; four activities; two actions per training day; explicit End Training Day; diminishing returns; pre-session fatigue modifiers; integer hundredths and half-up rounding. Recovery uses the pre-session Recovery rating. Preview and confirmed actions call the exact same pure rules function. No clocks, random gains, offline progression, age/calendar advancement, racing or sandbox speed changes.

Rules/data live in `scripts/training/`; `scripts/ui/hub/training_panel.gd` presents state and emits commands. The existing application controller and repository remain responsible for routing and saving. Candidate state is published only after a successful write; failure keeps visible authoritative values unchanged. Successful actions show explicit before/after values and browser storage guidance. Daily limits and restrictions appear on the activity cards.

## Persistence and migration

- Retain the existing `user://prototype_v1.json` slot and original career/position layout. Schema 4 adds a validated top-level training block with rules version, integer ratings, fatigue, day, daily usage and revision.
- Schema 1 remains position-only and goes to the original sandbox. Schema 2/3 Continue and viewing Training never write. New careers initially use schema 3; their first training operation upgrades them.
- Before a first training write, keep and verify the exact original bytes in `prototype_v1.json.pre-training-<original-content-hash>.bak`. Existing conflicting backup contents block migration. Backup failure prevents the primary write. A failed primary write may leave the safe original backup, but applies no training.
- Schema 2 category absence, hairstyle IDs, identity, origin, starting age and appearance remain unchanged after upgrade. Schema 4 accepts an absent legacy category without guessing it.
- Reject malformed, incompatible, future-schema and future-training-rules data on all write paths, including explicitly confirmed New Career replacement. This intentionally strengthens the older behavior that permitted replacing a damaged slot. Disposable native test fixtures are explicitly cleared when a subsequent valid fixture is needed.
- Validate JSON numbers before normalizing training integers. Invalid training is never replaced by defaults. Original legacy bytes remain untouched until an actual confirmed migration.
- Save position reads/preserves the entire snapshot. Application save paths compare the expected full-file content token. UI pending-command/empty-command guards and stale-token rejection prevent duplicate application.
- This remains optimistic concurrency protection, not an atomic multi-tab system. Use one active tab. Original backups live in the same browser storage and can be cleared with it; no backup-download/restore UI is implemented. Older game versions cannot read schema 4.

## Native verification

**868 assertions pass**, plus editor import and main-scene headless startup, with no recorded errors/warnings in the final run. Includes all existing regression coverage, updated only for the intended version/Training behavior and stricter damaged-save protection. New suites:

| Suite | Assertions | Coverage |
|---|---:|---|
| Training rules | 41 | Baseline activities, thresholds, caps, half-up rounding, diminishing returns, daily limits, recovery, unknown actions and 2,000 valid day transitions without free attribute gains |
| Training persistence | 29 | Schema 2/3 → 4, exact backup bytes, reload, preserved legacy data, duplicate tokens, failed backups/writes, future/malformed data and protected schema 1 |
| Training integration | 86 | Both categories × all three origins; preview/cancel/confirm, real repository autosave, equal outcomes, explicit results, duplicate submission, recovery/day reset, position saves, failed-save rollback, stale slot protection and both layouts |
| Separate-process reload | 2 | Exact schema 4 state and age separation after a fresh process |

The earlier 709-assertion baseline retains its coverage; a valid-fixture setup assertion was added for the newly protected damaged-slot case, giving 710 existing assertions plus 158 training assertions.

[Native results](web-evidence/training-0.4.0/native-results.json). Tests use isolated writable XDG storage and disposable `user://tests/` files. An initial default-path launch failed because the managed environment's home data/cache directories were unwritable; all reported final tests use the correct isolated paths.

## Web / Chromium verification

Official Godot `4.6.3.stable.official.7d41c59c4`, matching official `4.6.3.stable` templates and the existing Compatibility single-thread release preset export successfully. Exported-pack probing confirms version 0.4.0, Training resources present, exact baseline Speed after Sprint Drills (5060 hundredths), and no experimental prototype directory. [Pack result](web-evidence/training-0.4.0/pack-probe.log). Generated binaries remain outside Git.

**74 real Chromium 156.0.8078.79 checks pass** across four recorded runs over local HTTP. Headless SwiftShader renders the actual exported Godot game. Real mouse/keyboard UI input covers:

- Male From Nothing creation, all initial ratings, exact preview, cancellation without migration, Sprint Drills, Start Practice, exhausted actions, End Training Day and Recovery Session.
- Autosaved schema 4, original IndexedDB backup, unchanged age, track movement/Save & Menu, page reload and complete browser restart with progress/backup retained.
- Female Legacy creation, Endurance Run and Recovery Session rounding.
- Uncategorized Chosen One legacy schema 2 migration, original Ponytail ID, byte-identical backup, Hub saving and reload.
- Future training rules left untouched; schema 1 still opens the original sandbox.
- Final readable before/after rendering, exact 50.70 → 51.29 preview/commit, 800×600 scrolling and cancelled day confirmation.
- A final small-window legacy migration confirmed through the real button, exact 50.00 → 50.60 gain, absent category and byte-identical browser backup.

The main flow creates genuine saves through the UI. Legacy/future fixtures are explicitly seeded in an isolated browser IndexedDB profile and then loaded through the application, not injected into live game state. Native tests inject backup/write failures; actual browser quota exhaustion/denied storage was not simulated. No recorded engine, JavaScript, WebAssembly, storage or request errors/warnings in the completed passing browser runs.

[Main flow](web-evidence/training-0.4.0/flow-verification.json) · [female/legacy](web-evidence/training-0.4.0/legacy-verification.json) · [final UI](web-evidence/training-0.4.0/final-ui-verification.json) · [final migration](web-evidence/training-0.4.0/migration-final-verification.json).

## Actual Godot-rendered screenshots

- [Training 1280×720 — initial state](web-evidence/training-0.4.0/training-1280.png)
- [Training 800×600 — trained state](web-evidence/training-0.4.0/training-800.png)
- [Before/after result 1280×720](web-evidence/training-0.4.0/training-result-1280.png) · [800×600 scrolled result](web-evidence/training-0.4.0/training-result-800.png)
- [Migration preview 800×600](web-evidence/training-0.4.0/migration-preview-800.png) · [successful migration result](web-evidence/training-0.4.0/migration-result-800.png)
- [Female career initial Training](web-evidence/training-0.4.0/female-training-1280.png)

Screenshot review found an unsupported arrow glyph and a small-window confirmation reflow/click issue. Result text now uses portable ASCII `->`; dialog text uses 16px within a navy/gold panel. The corrected final migration check verifies visible Saved feedback as well as persisted data. The unsuccessful click left the original legacy save unchanged; the completed recheck passes.

## Preservation and changed files

Protected SHA-256 checks confirm Athlete Studio, approved Player Card, career/appearance data, hairstyle catalog, procedural athlete/hair and locker room unchanged. Sandbox input/movement scripts and Golden Path branding are untouched. [Preservation results](web-evidence/training-0.4.0/protected-results.json).

New: `scripts/training/training_state.gd`, `training_service.gd`, `scripts/ui/hub/training_panel.gd`, three training test scripts (with Godot UIDs), this report and `tests/web-evidence/training-0.4.0/`.

Updated: `scripts/app/main.gd`, `scripts/persistence/prototype_save_repository.gd`, `scripts/ui/hub/career_hub.gd`, `project.godot`, existing career/Hub/menu tests, README/design/roadmap/tasks. The existing manual-only Pages workflow gains training test commands; its triggers/deployment gate are unchanged. [Exact file list](web-evidence/training-0.4.0/changed-files.txt).

## Limits and next approval gate

- Abstract training days do not consume years or calendar dates. Ratings can eventually reach the cap through repeated days; there is no arbitrary designed career-length cap. Day/revision precision is bounded only by JSON's exact integer range.
- No competitions, race performance mapping, AI, training minigames, career aging or paid boosts.
- Constant-size rules/state and 2D controls; no new models, textures, shaders or runtime dependencies. No physical Windows 10 / 4 GB RAM benchmark or FPS/draw-call guarantee is claimed.
- Browser persistence is origin/profile scoped and asynchronous; storage clearing, forced close, private mode and quota conditions remain risks. Multi-tab coordination and backup import/export remain future work.
- Performance/browser evidence is local Chromium software rendering, not deployed-host or other-browser/screen-reader verification.

Await visual and functional approval. Nothing committed, pushed, merged or deployed.
