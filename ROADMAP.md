# ROAD TO GOLD — Roadmap

Updated for Version 0.2.4, 2026-11-09. Gates are evidence-based; implementation stops at the currently approved milestone.

## Milestones
1. **Approval and feasibility:** agree Alpha scope and unresolved defaults; scaffold the minimal Compatibility project; pin engine/templates; export a placeholder Web scene and validate hosting, keyboard focus and persistence on a desktop browser. Check the Windows 10 / 4 GB machine early. Gate: documented real Web results and no unresolved export blocker.
2. **Data and navigation:** athlete/appearance/career contracts, versioned saving, customization, origins, one branching introductory event per origin, and hub. Gate: keyboard-accessible journey to hub and reloadable career.
3. **Sprint vertical slice:** one controlled runner first, then seven AI; start/reaction, rhythm, acceleration, stamina, finish timing and results/PB. Gate: repeatable complete races with correct order and no frame-rate-dependent simulation.
4. **Alpha 0.1 integration:** full journey, recovery, browser save import/export, low-end optimization, legal/asset review and manual acceptance pass. Gate: criteria below verified, with actual evidence and known issues recorded.
5. **Post-Alpha:** training/recovery and calendar, longer branching career, aging and retirement; expand content toward 15–20 years. Add long jump, javelin and 100m swimming one at a time after sprint is stable. Do not imply these are included in Alpha.

## Version 0.2 — Career creation
Current scope: a complete four-step creator behind New Career, three origins, all requested customization with procedural live preview, summary/final confirmation, versioned career saving and legacy Continue. No story or sports progression is implemented.

Acceptance: no customization on startup; Back/Next retain choices; origin ages are 15/17/20; invalid identity/appearance cannot save; all fields reach summary/save; existing progress survives cancel; Continue and track saving preserve full career data; legacy v1 saves remain readable without automatic rewrite; native and actual Chromium navigation, preview and reload checks pass. Record actual results in TASKS.md and README.md, rather than treating this list as test evidence.

Future work after approval: narrative introduction and career hub, then the sprint vertical slice. Full save backup/migration infrastructure, manual import/export, multi-tab conflict handling and long-career progression remain future scope. Windows 4 GB performance and cross-browser hosting measurements remain outstanding.

## Alpha 0.1 acceptance criteria
These refer to the future full sprint Alpha. Partial creator/local persistence behavior now exists in Version 0.2; the full Alpha criteria remain pending. A document or version command does not satisfy gameplay acceptance.

- [ ] Export runs over HTTP localhost and the chosen HTTPS host in current stable Chrome/Edge and Firefox on desktop; record browser/engine/template versions. No project-breaking console errors.
- [ ] Entire Menu → Creator → Origin → Intro → Hub → Race → Results → Hub flow works without developer tools; Continue restores a valid saved career.
- [ ] Creator supports all specified identity and appearance fields with a visible preview, bounded dimensions and validation. Changing appearance/country alone leaves sporting attributes and simulation outcomes unchanged for the same seed/input.
- [ ] All three origins have the correct ages (15/17/20), distinct premise, at least one two-choice introductory event, and a visible saved consequence.
- [ ] Race has exactly eight runners, direct keyboard control, randomized start signal, measured reaction time, false-start handling, bounded acceleration, stamina and meaningful alternating rhythm input. Repeated/held keys cannot generate artificial alternating input.
- [ ] All runners traverse the same logical 100m distance. Signal-based timing and interpolated finish crossings produce ordered raw times, shared exact-tie ranks, displayed hundredths and DNF handling. Test synthetic known finishes and render-rate variation.
- [ ] Results show all eight athletes, times/ranks, player reaction and PB status; a valid faster time updates PB once, slower/invalid/DNF attempts never replace it. Returning to hub and reloading preserves it.
- [ ] Loss of focus pauses the race, clears stale input, and explicit resume produces no time or position jump. Test pre-signal held keys, rapid repeats, tab switching and resize.
- [ ] Career survives reload and browser restart on the same persistent profile/origin. Test denied/unavailable storage, corrupt/truncated save, backup recovery, unsupported version, and revision conflict. Failures are visible and do not silently erase a valid career.
- [ ] Valid JSON export/import round-trips identity, appearance, origin, story consequence and PB; invalid/oversized/unsupported input is rejected; replacement requires confirmation.
- [ ] Menus are keyboard usable, readable at 1280×720 and browser zoom, with visible focus and non-color-only cues. Explain controls before the signal; audio is optional. Record accessibility limitations of the canvas UI.
- [ ] Meet the provisional 30 FPS minimum target in a ten-race session at 1280×720 on an identified Windows 10 / 4 GB machine; record CPU/GPU/browser and frame/memory evidence. Confirm or revise transfer and memory budgets explicitly before release; no unsupported performance claims.
- [ ] No paid dependency, account, server requirement, unauthorized asset or protected Olympic branding. Asset ledger covers all external assets; all four planned sports except sprint remain out of Alpha gameplay scope.

## Release evidence
Maintain an acceptance checklist with date, build identifier, test environment, steps, observed result and unresolved issues. Separate automated logic checks, manual browser checks and hardware measurements. Any unmet acceptance item requires an explicit scope decision, not a fabricated pass.

## Open approval items
Control rhythm and accessible alternative; origin sporting balance; pinned engine version after Web spike; target browser versions and exact low-end CPU/GPU; free hosting choice; final performance budgets; country dataset/license; full-career progression. Proposed Alpha defaults are documented in GAME_DESIGN.md and TECHNICAL_DESIGN.md.

## Version 0.2.1 — Male and female career support
Scope: category selection first after New Career; equal origin/customization access; modest procedural silhouette profiles; category-aware summaries/Continue; validated schema v3 and unchanged legacy v1/v2 behavior. Shared future competition namespace is prepared without implementing records, opponents or progression.

Acceptance: no preselected category in a fresh draft; selection required to advance; both categories support all three origin ages and every customization field; Back/Next preserve selections; categorized saves survive reload; legacy careers remain unselected; replacement protection remains intact; actual native and Chromium results are recorded in README/TASKS and test evidence.

Deferred: creator redesign and new branding, explicit legacy-category migration UI, all separate competition/record/opponent/progression systems, full story and sports gameplay, additional browser and low-end hardware measurements. Do not deploy automatically.

## Version 0.2.2 — THE LOCKER ROOM
Scope: implement the approved five-step creator presentation, midnight/graphite/ivory/muted-gold UI, lightweight procedural room, fixed full-body camera, modest selected-category model refinements and responsive native-sized controls. Preserve all v0.2.1 data, validation, save authorization, legacy handling and tests. No progression or competition implementation, new logo, framework or automatic deployment.

Acceptance: both categories traverse all three origins; every appearance control updates the preview; identity validation and accurate summary remain intact; Back/Continue retain drafts; camera framing stays fixed and includes maximum-sized athletes; replacement cancel/accept and schema 1/2/3 saving/loading pass native and real Chromium checks; capture all five screens; record actual export/persistence results and remaining limitations. Source delivery is followed by a stop for approval. Windows 10 / 4 GB performance, additional browsers, screen readers and live-host verification remain separate gates.

## Version 0.2.3 — GOLDEN ROAD
Scope: approved official-logo integration, cinematic split main menu with a lightweight static curved pathway, refined tagline/buttons, named career caption, branded real-progress loader and small Locker Room emblem. Preserve all career creation, data and save contracts, gameplay track and camera. No automatic deployment.

Acceptance: verify immutable source PNGs and optimized transparency/aspect ratio; all existing native suites plus focused menu tests; real Chromium loader/progress, brand rendering, keyboard/mouse menu actions, five target resolutions, new career/Continue/settings, schema 1/2/3 and restart persistence; screenshots of menu/loader/Locker Room; exact export/version evidence. Commit/push only after tests and updated screenshots. Windows 10 / 4 GB performance, additional browsers and live-host checks remain outside observed cloud evidence.

## Version 0.2.4 — Athlete Studio 2.0
Scope: complete visual creator redesign with category/origin cards, pinned Hair/Skin/Body tabs, visible swatches/tiles, linked numeric sliders, polished identity form and actual-data Player Card. Keep one medium full-body preview in the existing locker room, fixed camera, and preview-only three-quarter orientation. Preserve all schema 1/2/3 and draft/replacement behavior; no gameplay or 3D graphics milestone work.

Acceptance: all existing native coverage preserved with version/tab-context adaptations, focused Studio/binding/card/header/facing/modal tests, actual Chromium full creator/persistence/legacy checks at desktop/small sizes, fresh seven-view evidence at 1280×720 and 800×600 including scroll-bottom captures, matching Web export, updated docs. No automatic deployment. Low-end physical hardware/accessibility/extra-browser measurements remain separate gates.

## v0.3.0 — Golden Legacy + Athlete HQ foundation
Review scope: responsive Overview/My Athlete, real saved athlete data, Begin/Continue routing, unchanged Player Card/appearance, shared Settings, and honest unavailable pages. Preserve schema 1/2/3 and movement sandbox. Acceptance: existing native coverage, both categories × three origins, legacy compatibility, local Chromium persistence/navigation/layout screenshots and official single-thread Web export. No training, races, AI, progression or experimental GLBs. Await visual/functional approval before any commit, push, merge or deployment.
