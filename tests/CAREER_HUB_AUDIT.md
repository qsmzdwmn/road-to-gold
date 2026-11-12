> Historical implementation/review evidence. Visual approval has now been received; see [finalization](CAREER_HUB_FINALIZATION.md) for final checks and PR scope.

# Career Hub foundation — audit and implementation boundary

Baseline main and origin/main: `e88438ac27a2a8d96a21807e0daf440fe151d57b` (released v0.2.4.1). Working tree was clean; all 521 native assertions passed before implementation. Its GitHub Actions run 42807227842 completed successfully; the prior optional live-browser check was blocked by local certificate trust, not a missing release commit or failed deployment. No release blocker was found.

Work is isolated on `feature/v0.3.0-career-hub`; main and the experimental Blender branch remain unchanged. The baseline is archived outside the checkout. No commit/push/merge/workflow dispatch/deployment is authorized for this milestone.

## Reused architecture

- `Main` already owns creator confirmation, the one-slot repository, current career and track/menu routing. A dedicated CareerHub scene now receives the same validated career resource after the original save succeeds.
- Repository path, schema 1/2/3 readers, atomic temporary-file/rename writer, maximum size and validation remain untouched. No new hub state, profile collection, generated schedule, record or progression field is serialized.
- Begin Career writes through the same protected `save_career` call, then opens Hub. Continue routes schema 2/3 careers to Hub without writing their files. Schema 1 position probes retain the original track path because they contain no athlete to display.
- Overview is 2D. My Athlete reuses the approved unmodified Player Card and existing procedural model/locker-room classes. Its separate static preview is lazy and paused when hidden; no GLBs, new character design or heavy scene is introduced.
- Settings reuses the existing screen with a return signal. The existing movement sandbox remains explicitly labeled and reachable; no training/race/AI logic is added.

## Save-safety boundary

Hub navigation and profile viewing are read-only. Save & Menu uses the existing writer only after verifying that the slot still contains the same career. A missing, invalid or externally replaced slot yields a visible error and leaves the session open; it is not silently downgraded to a position-only save. This is a guard, not a new save schema or a full multi-tab transaction system.

No incompatible save architecture was discovered. Legacy uncategorized careers remain uncategorized and retain their old appearance IDs. Replacement still requires the original explicit dialog. The approved Creator/Player Card, appearance catalogs, body/hair generators, repository and career-data files are preserved; only routing and reused settings/HUD navigation need integration changes.

## Planned verification

Retain all baseline native coverage with the expected new Hub landing state and explicit sandbox entry before track-input tests. Add Hub tests for both categories × all origins, accurate profile values, navigation/settings, no writes on read-only viewing, legacy bytes/schema preservation, save protection, window sizing and keyboard focus. Export official Godot 4.6.3 single-thread Web and run real local Chromium, capturing Overview at 1280×720/800×600 and My Athlete. No physical 4 GB Windows performance or deployment claim is implied.

## Completed checks

The final native run passes 708 assertions, the official single-thread Web export succeeds, and real local Chromium checks cover creation, Hub routing/navigation, persistence, movement and legacy fixtures. See [verification and screenshots](CAREER_HUB_VERIFICATION.md) for exact scope, evidence and limitations. All production preservation hashes match. No commits or deployment actions were performed.
