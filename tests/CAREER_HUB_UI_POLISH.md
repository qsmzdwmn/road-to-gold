> Historical implementation/review evidence. Visual approval has now been received; see [finalization](CAREER_HUB_FINALIZATION.md) for final checks and PR scope.

# Career Hub UI polish — pending visual approval

Branch: `feature/v0.3.0-career-hub`. No commit, push, merge or deployment. Main remains `e88438ac27a2a8d96a21807e0daf440fe151d57b`; the experimental athlete branch is untouched.

## UI changes

- Replaced the four large Overview boxes with a compact identity/status band, a restrained origin description, two aligned Upcoming Event / Personal Best panels and a lightweight sandbox utility row. All athlete values still come from the existing career binding. No statistics or results are invented.
- Career status explicitly says Profile ready; training remains unavailable. This is presentation text, not a new serialized career state.
- Save & Menu uses its natural 132-pixel minimum width at the upper right rather than expanding across half the header. Its signal and routing are unchanged.
- Training navigation now says only Training. Its information page prominently says Coming Soon and explains that no sessions can be started.
- Overview retains two readable columns at both target resolutions. At 1280×720 it fits without scrolling; at 800×600 a short scroll exposes the complete sandbox row. Navigation, header and footer remain fixed. Long names/descriptions retain wrapping and scrolling.
- My Athlete retains the approved two-column desktop composition and existing narrow-window stack. No Player Card, athlete model, camera, appearance identifiers or settings change.

## Verification

709 native assertions pass (the existing 708 plus the compact-button / clean-nav regression). Editor import and main scene startup pass. Training's existing honest-empty-state assertion now verifies Coming Soon and the retained no-training explanation.

Official Godot `4.6.3.stable.official.7d41c59c4`, matching `4.6.3.stable` templates and the existing Compatibility single-thread release preset export successfully. Real Chromium tests load that Web export over localhost HTTP, using actual UI input. 52 browser checks pass (34 main flow + 18 male/legacy); no recorded engine/JavaScript/WebAssembly/storage/network errors or warnings. Coverage includes Begin Career, Continue, every navigation page, shared Settings, Save & Menu, reload/browser restart persistence, movement sandbox return, both categories, schema 2 legacy category/hair preservation and schema 1 position-only compatibility. Legacy fixtures use an isolated IndexedDB slot before reloading through the application, as documented in the foundation report.

Protected SHA-256 checks confirm the creator, Player Card, repository, career/appearance data, hairstyle catalog, procedural model/hair and locker room are byte-identical to the approved baseline. No career/save/gameplay changes in this polish pass.

## Fresh screenshots — actual exported Godot game in Chromium

- [Overview 1280×720](web-evidence/career-hub-polish-0.3.0/hub-overview-1280.png)
- [Overview 800×600](web-evidence/career-hub-polish-0.3.0/hub-overview-800-top.png) · [scrolled bottom](web-evidence/career-hub-polish-0.3.0/hub-overview-800-bottom.png)
- [My Athlete 1280×720](web-evidence/career-hub-polish-0.3.0/hub-my-athlete-1280.png)
- [Training Coming Soon](web-evidence/career-hub-polish-0.3.0/hub-training.png)

Results: [native](web-evidence/career-hub-polish-0.3.0/native-results.json), [Chromium flow](web-evidence/career-hub-polish-0.3.0/browser-verification.json), [male and legacy](web-evidence/career-hub-polish-0.3.0/browser-legacy-verification.json).

## Scope and limitations

This pass changes `scripts/ui/hub/career_hub.gd`, `tests/career_hub_test.gd`, `TECHNICAL_DESIGN.md`, `TASKS.md`, `README.md`, the verification documents and the new screenshot/results directory. Previously uncommitted foundation work is preserved. Browser checks use headless Chromium/SwiftShader; physical 4 GB Windows performance, additional browsers and screen-reader testing remain unmeasured. No training, competitions, progression or records mechanics are implemented.

Await visual approval. Nothing committed, pushed, merged or deployed.
