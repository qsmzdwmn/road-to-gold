# v0.4.0 Training foundation — PR finalization

User approved the implementation and authorized a feature-branch commit/push and PR targeting main. Merge and deployment still require separate approval.

## Final scope review

`feature/v0.4.0-training-foundation` is based on fetched main `7ffe6264e0e89ac96d714079a9073eef845fea73`. Scope is deterministic training rules/state, schema 4 migration and backups, Hub/controller integration, tests, version/documentation and actual-render evidence. The manual Pages workflow only adds training test commands; its dispatch/deployment gates remain unchanged and were not triggered.

Athlete Studio, Player Card, career/appearance data, procedural models/hair, locker room, branding and sandbox input/speed remain unchanged. The experimental branch remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58`; no experimental assets are included.

## Small UI polish

Changed ratings share one wrapping saved-result line; fatigue, day/actions and storage guidance remain visible. The complete original result is also available as a tooltip. No calculations or serialized values change.

A shorter confirmation window was tried but not retained after mouse-driven confirmation failed in a browser check. The approved dialog dimensions were restored. Browser automation now waits for the canvas button position to settle before its single click, and polls IndexedDB for the resulting revision rather than relying on a fixed delay. It never retries an action or bypasses the UI. This preserves the approved dialog behavior while retaining the safe result-formatting improvement.

## Final verification

- **869 native assertions pass**, plus editor import and main-scene headless startup. Includes progression/rounding/fatigue limits, category/origin parity, schema 1–4 compatibility, byte-identical original backups, stale/duplicate rejection, failed backup/write rollback, sandbox saving and separate-process reload. No recorded warnings/errors in the final run.
- A final maximum-size boundary check ensures adding training cannot produce a save larger than the existing reader limit. The writer rejects an oversized candidate before touching the primary file; the new regression verifies the original legacy file remains readable and unchanged. This does not change the schema or training balance.
- Official Godot `4.6.3.stable.official.7d41c59c4` Compatibility single-thread Web release export succeeds using matching `4.6.3.stable` templates. Pack probing confirms version 0.4.0, Training resources, baseline Speed 5060 hundredths after Sprint Drills, and no experimental prototype directory. Generated build files remain outside Git.
- **74 fresh real Chromium checks pass**, with no recorded runtime/storage/network errors or warnings. Fresh runs cover the complete new-career Training flow, exact previews/gains, cancellation, fatigue/day/recovery, browser-local original backup, sandbox Save & Menu, page reload, complete browser restart, female gains, uncategorized legacy migration, future-rule protection and schema 1 sandbox compatibility. Additional final UI and 800×600 migration checks verify the resulting presentation and saving.

Current raw results and fresh screenshots are in `tests/web-evidence/training-0.4.0-finalization/`. Earlier implementation evidence is retained in [the original verification report](TRAINING_FOUNDATION_VERIFICATION.md).

## Remaining limitations

Browser saves/backups are local to the origin/profile and asynchronous; clearing site data removes both. No backup-download/restore UI or atomic multi-tab coordination; use one active tab. Abstract training days do not advance age/calendar or create competition commitments, so eventual stat-cap attainment is possible. No race/competition/AI implementation. Physical 4 GB Windows performance, other browsers, screen readers and browser quota-denial scenarios remain unmeasured. Native failure-injection tests cover rollback.

No merge, deployment or experimental-branch modification is authorized by this finalization.

## Fresh evidence

[Native results](web-evidence/training-0.4.0-finalization/native-results.json) · [main Chromium flow](web-evidence/training-0.4.0-finalization/flow-verification.json) · [female/legacy](web-evidence/training-0.4.0-finalization/legacy-verification.json) · [final UI](web-evidence/training-0.4.0-finalization/final-ui-verification.json) · [final migration](web-evidence/training-0.4.0-finalization/migration-verification.json).

[Compact saved result](web-evidence/training-0.4.0-finalization/training-1280-result.png) · [800×600 saved result](web-evidence/training-0.4.0-finalization/training-800-final-result.png) · [800×600 confirmation](web-evidence/training-0.4.0-finalization/training-confirmation-800.png).

The maximum-size guard was checked by the final native run and official export, followed by another fresh 800×600 browser migration on that build; the original backup and saved gains were verified again.
