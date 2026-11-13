# v0.5.1 Stadium Audio verification

The owner personally listened to and approved all ten original audio assets and
the updated Settings UI. This release prepares the feature PR; it does not merge
or deploy the game. Final rerun counts and package evidence are recorded in
[V0_5_1_RELEASE_PREPARATION.md](V0_5_1_RELEASE_PREPARATION.md).

## Architecture and preservation

Main owns one persistent AudioDirector. Music, Sound Effects and Stadium Crowd
have separate buses and preferences; Master mute retains individual values.
Seven fixed players bound simultaneous voices. All synthesis is offline; no
new game dependency, DSP effect, spatial emitters or per-opponent footfalls exist.

The race presentation observer reads authoritative phase, player speed/distance
and existing gait phase. Set → Running triggers one pistol per attempt. Finish
and successful new-PB outcomes are once-only. Cancel/retry/exit clear race
one-shots; crowd fades out on Hub return. Hub music is permitted to continue.
No sprint formula, Training balance, camera, stadium, appearance or schema was
changed. Audio preferences use user://audio_settings.cfg, separate from career
and graphics files. Invalid/future preference versions and failed saves have
explicit handling. Existing schemas 1–4, category parity and legacy backups
remain covered by the native suite.

## UI and browser checks

Settings has 56×28 switch icons, a 40px Mute All row and explicit ON/OFF text.
At 800×600 and 1280×720, native checks scroll every control into view and verify
its whole rectangle lies within the scroll clip above Back. Keyboard and mouse
navigation, three independent gains, Mute All and reload persistence are checked
in Chromium. Existing Performance/Enhanced controls remain functional.

The browser suite exercises a full created career, actual Web Audio output,
Hub/crowd repetition, a Training action, both sprint modes, false starts, race
exit sound cleanup, saved PBs, browser reload and AudioContext suspension.
The separate legacy suite uses an isolated local browser profile to test schema
2 category confirmation, schema 4 migration/backups, female PBs and future-data
protection. Tests must never target production storage.

## Honest limits

The environment uses SwiftShader, not a hardware GPU. Physical low-end Windows
10 / 4 GB GPU performance, physical audio output latency and physical iPhone
Safari remain unverified. Earlier same-session software comparisons measured
501.16 ms muted versus 501.56 ms enabled, with 115 draw calls in both runs; these
figures are not normal GPU estimates or proof of zero audio cost. Renderer RSS
grew between runs, with scene allocation, audio decoding and GC confounded.
Godot's exported static-memory monitor returned zero and was treated as unavailable.

Genuine headed browser focus loss was previously verified with Playwright focus
emulation disabled. The final headless suite separately records focus state and
uses Escape to ensure interruption; it does not mislabel that as genuine blur.
Actual AudioContext suspension/resumption is exercised. Synthetic DOM freeze/
resume checks verify handlers but do not freeze a real page. True hidden-tab
page freezing remains unverified because this environment did not deliver it.

The cloud browser initially reported a running AudioContext under the tested
autoplay-policy flags. The application emitted no samples before interaction;
first trusted input permitted playback. This verifies the app gate, not an
independent claim of a naturally browser-blocked initial context. Browser storage
may be transient; filesystem success does not guarantee durability after immediate
closure or browser data cleanup.

## Audio and release scope

assets/audio/manifest.json records the approved source hashes, sizes and durations.
All ten bytes hashes must remain unchanged. Source audio totals 259,762 bytes;
source PCM totals 3,989,040 bytes. Browser resampling/decoding and buffers use
additional memory. Asset provenance and Godot notices remain in assets/licenses.

The temporary preview website, WAV review copies, its generator, preview-only
tests and listening recordings are preserved outside the release repository.
The original offline audio generator remains as provenance/developer tooling,
no longer creates a preview webpage, and tools/ is excluded from Web exports.
Package inspection verifies all ten imported streams load, the four buses exist,
Performance is the default, and no preview site/test/tool resources are bundled.
