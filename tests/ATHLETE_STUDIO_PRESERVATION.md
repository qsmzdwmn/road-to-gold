# v0.2.4 production preservation — 2026-11-10

Owner-authorized source preservation before v0.3. No new gameplay or character-model work is included.

## Separation

The original working tree had 11 modified and 66 untracked files (77 total). A SHA-256 manifest, full changed-source archive, tracked binary patch and original TASKS.md were saved before staging. Forty files are production v0.2.4 changes, 36 belong to prototypes/, and TASKS.md contains separable production/experimental sections. The production commit contains only the v0.2.4 section; the full original remains preserved in the experimental branch and backup. No reset, discard or destructive cleanup is used.

Production contains the Athlete Studio UI/components, version update, documentation, tests, screenshots and a single added native-test command in the existing manual-only Pages workflow. Experimental Blender/GLB assets, generators, rejected variants and evidence belong to the separate experimental/v0.2.5-athlete-lab branch. They are not merged into main. Existing original files are preserved verbatim; generated reports document this operation separately.

## Actual regression results

- Official Godot 4.6.3.stable.official.7d41c59c4; import and main-scene smoke checks pass.
- All **422 native assertions** pass: 332 existing plus 90 focused Athlete Studio checks. A fresh dedicated XDG data directory keeps existing user saves untouched.
- **54 real Chromium 156.0.8078.79 checks** pass against this new production export: five-step flow, both categories, origins, customization, validation, back/forward retention, compact actual-data Player Card, supported layouts, replacement/cancel, movement, saving, reload, browser restart and genuine schema 1/2/3 profiles.
- Legacy fixtures retain their original localhost origin through a test-only response route to this export, rather than testing against a stale server or modifying fixture bytes. Legacy category is never inferred.
- Matching official 4.6.3 single-thread Web release export succeeds. Running its PCK from an empty directory confirms version 0.2.4, production model present, experimental directory/GLBs absent. No recorded runtime/JavaScript/WebAssembly/storage/network warnings or errors in the completed browser run.

[Raw current results](athlete_studio_preservation.json). [Earlier complete Studio report/screenshots](ATHLETE_STUDIO_VERIFICATION.md).

## Stable model and saves

Production scripts/customization/procedural_athlete.gd, locker_room.gd, data/career/persistence/input/race classes, track, loading page and branding match ae46254. Both creator/gameplay still preload the original production generator. The approved creator-only 230-degree instance yaw is retained; shared model, gameplay orientation and static camera are unchanged. Save schemas 1/2/3, paths, identifiers, legacy behavior and overwrite protection are unchanged.

## Limits and stop condition

Physical Windows 10/4 GB performance, additional browsers, live deployment and denied/private/quota storage remain untested. The v0.2.5 GLBs are unapproved experimental assets with preliminary rigging; they are not production-ready. This operation creates local preservation commits only, with no push or deployment. Character development and v0.3 Career Hub remain paused pending explicit approval.
