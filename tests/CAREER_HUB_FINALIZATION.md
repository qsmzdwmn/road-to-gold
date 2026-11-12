# v0.3.0 Career Hub — PR finalization

User approved the visual design and authorized feature-branch commit, push and a PR targeting main. Merge and deployment remain prohibited pending separate approval.

- Branch: `feature/v0.3.0-career-hub`; fetched main base: `e88438ac27a2a8d96a21807e0daf440fe151d57b`. No upstream changes at final audit.
- Final native run: **709 assertions passed**, including all 521 original assertions, plus editor import and main-scene startup. No test errors/warnings. [Final native results](web-evidence/career-hub-polish-0.3.0/native-results.json).
- Final official Godot `4.6.3.stable.official.7d41c59c4` Compatibility single-thread Web release export passed using matching 4.6.3.stable templates. Exported-pack check confirms version 0.3.0, stable model present and no experimental GLB/prototype directory. Generated binaries remain outside Git.
- The approved polish build previously passed 52 real Chromium checks, plus a fresh Coming Soon render/error check. These were not rerun during finalization. [Browser flow](web-evidence/career-hub-polish-0.3.0/browser-verification.json), [male/legacy](web-evidence/career-hub-polish-0.3.0/browser-legacy-verification.json), [screenshots](CAREER_HUB_UI_POLISH.md).
- Protected hashes confirm the creator, approved Player Card, save repository, career/appearance data, hairstyle catalog, athlete/hair generators and locker room remain unchanged from the v0.2.4.1 base. Schemas 1/2/3 and customization IDs remain intact.
- Experimental branch remains `535404809708ab0d27ff56c8bb1d3f4ac736ba58`; no experimental files are included.

Scope: the Hub scene/presentation, Begin/Continue routing, shared Settings/HQ navigation, save-slot verification guard, version metadata, regression adaptations/new Hub coverage, design/task/run documentation and actual screenshot/test evidence. Pages workflow only gains Hub test commands; its manual dispatch/deploy gate is unchanged. No training, race, AI, career progression or competition systems. No deployment workflow dispatch.

Known limits: physical low-end Windows performance and screen-reader/other-browser coverage are unmeasured. Browser saves remain origin/profile-scoped. The slot guard is not full atomic multi-tab conflict resolution.
