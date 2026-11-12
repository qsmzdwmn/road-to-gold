# v0.5.0 release pull request preparation

The owner approved First 100m Race, Stadium 1.0, the running-animation fix, camera, HUD, deterministic balance and graphics-quality settings for feature-branch commit/push and a PR to main. **Merging and deployment require separate explicit approval. No v0.5.1 work is included.** This report supersedes earlier review-stage authorization statuses; their dated measurements remain historical evidence.

## Repository and scope review

Fetched GitHub before preparation. `origin/main`, local main and feature HEAD shared `27e2a3c2053a5c8e1d3151257e4389b1de66dfcc`, with no upstream divergence. Work is on `feature/v0.5.0-stadium-rebuild`, originally created from the race-development branch. The experimental Blender branch stays at `535404809708ab0d27ff56c8bb1d3f4ac736ba58`, locally and remotely; no experimental files/models were imported.

Reviewed changes: version metadata; dedicated race scenes and modular simulation/input/AI/results/rendering/animation/quality classes; Career Hub entry and real PB/results; safe optional schema4 competition persistence; race-only graphics preferences; tests, screenshots/video and design/verification documentation. Existing stable athlete/hair assets, Athlete Studio, approved Player Card, Training rules and sandbox movement remain unchanged. No generated Web build, `.godot` cache, browser profile, test save or secret is included.

The existing manual Pages workflow now runs all six new native suites. Its only changes are those six command lines. It remains `workflow_dispatch`-only, defaults `deploy` to false, and only permits its deployment job on main with explicit deploy input. No workflow was dispatched for this preparation.

## Fresh validation

- **1,007 native assertions pass**, including every existing suite, six race/stadium/animation/quality suites, import and a 120-frame main-scene smoke. No errors/warnings in completed headless suites.
- **45 real Chromium checks pass** on Chromium 156.0.8078.79: quality 13; gameplay 15; legacy 12; Rhythm 5. These fresh runs use the current release Web build, not the counts of earlier review iterations.
- Gameplay checks cover Hold and physical alternating-key Rhythm finishes, pre-held Space rejection, false-start retry, Escape interruption without writes, eight classified finishers, readable results at desktop/small sizes, visible animated legs at moving-player position, slower races preserving PB, full browser restart and page reload.
- Save checks cover original schema2 backup bytes and explicit legacy category selection without rewriting appearance IDs, categorized female results, schema4 Training/position preservation, PB/latest race retention and protected future competition data. Native cases additionally cover schemas1/2/3/4, failed and stale writes, duplicate results and category parity.
- Performance remains the default when no valid graphics preference exists; Enhanced is selectable from Settings. Real UI selections persist separately to `user://race_graphics.cfg`, with no career changes. Both settings retain all eight runners and the stadium architecture.
- Official engine **4.6.3.stable.official.7d41c59c4** and matching **4.6.3.stable** templates: Compatibility `Web` release export passes with `variant/thread_support=false`. The export preset and production user-data directory are unchanged.
- Protected pre-refinement source hashes for sprint formulas, input/session, AI, classification/persistence, Training, creator, Player Card and sandbox match. No balance adjustments were made for release preparation.

Native reproduction: run the commands in `.github/workflows/web-pages.yml` through its validation step, using disposable user storage. The workflow is not automatically triggered by a push or PR. Local browser reproduction: export using the README instructions, serve over HTTP and test both modes plus Settings at 1280×720 and 800×600 with a disposable browser profile. Do not use `file://`.

## Remaining limitations

**Physical low-end GPU performance has not been verified.** This environment exposes no hardware GPU; default and OpenGL/ANGLE Chromium launches use SwiftShader. Previously measured software FPS is not representative of normal Intel/AMD/NVIDIA GPU performance and does not establish Windows 10 / 4 GB suitability. Performance profile avoids dynamic shadow maps/MSAA and reduces the instanced crowd while preserving the complete venue. Enhanced restores approved original rendering. See the [performance gate](PERFORMANCE_RELEASE_GATE.md) for controlled software frame times, draw calls and memory, with measurement caveats.

Real-window/tab blur handling remains unconfirmed by a genuine DOM-blur callback in automation; native focus interruption and real Chromium Escape/long-frame paths pass. Other browser engines, screen readers and multi-tab atomic persistence are not verified. Browser IndexedDB synchronization is asynchronous; file tokens/verified backups protect observed stale or malformed saves but do not provide cross-tab transactions. The decorative oval/infield are not additional playable sports.

## Evidence

[Fresh raw release results](release_v0_5_0_verification.json), [stadium/balance evidence and motion clip](RACE_STADIUM_VERIFICATION.md), and [graphics-quality results](PERFORMANCE_RELEASE_GATE.md). Previous reports retain their original counts and statuses for provenance. Commit and PR identifiers are reported in the PR/assistant delivery to avoid self-referential commit metadata inside this commit.
