# v0.5.0 performance release gate

Date: 2026-11-12. Uncommitted on `feature/v0.5.0-stadium-rebuild`; no push, merge or deployment. This follow-up supersedes the prior performance/default-quality discussion, not the approved balance or camera.

## GPU availability

**Hardware-accelerated browser testing is unavailable in this environment.** There is no exposed `/dev/dri` device or `/sys/class/drm`. Chromium 156.0.8078.79 reports `ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)` through the unmasked WebGL renderer and CDP device information. Default launch and an explicit OpenGL/ANGLE attempt both fall back to SwiftShader. A running browser GPU process and enabled WebGL do not establish physical GPU acceleration. Native X11 rendering also uses llvmpipe.

The earlier 3.08–3.16 FPS therefore measured CPU software rendering. It is **not representative evidence for normal GPU rendering**, and no physical Windows 10 / 4 GB performance claim is made.

## Controlled bottleneck checks — software only

Fresh single-page browsers, no recording or concurrent native/app tests, 1280×720 output, 640×360 3D, fixed camera/positions, eight animated athletes, 20 warm-up frames and 39 measured intervals. Individual ablations are short diagnostic samples, not precise causal percentages. Full and combined-low were repeated.

| Rendering configuration | FPS | Mean frame time | Max draw calls |
| --- | ---: | ---: | ---: |
| Approved full, first / last runs | 3.00 / 3.14 | 332.81 / 318.10ms | 131 |
| Crowd hidden | 3.53 | 282.98ms | 130 |
| Dynamic shadows disabled | 4.11 | 243.19ms | 82 |
| MSAA disabled | 4.11 | 243.39ms | 131 |
| Reduced crowd and optional vegetation/planter batches | 3.72 | 268.90ms | 122 |
| Combined reduced diagnostic, two runs | 5.71 / 5.99 | 175.24 / 166.99ms | 76 |

The crowd is already **one shared MultiMesh**, not 346 individual spectator nodes/draw calls. Removing it saves one draw call, though fewer vertices still help software rendering. Shadows add 49 draw calls in this view; MSAA adds significant sample/resolve cost without changing draw counts. The render submission count and software rasterization remain limiting; these tests do not isolate every CPU/GPU driver cost.

The reduced-decoration diagnostic hid foliage, trunk and planter material batches (including a shared pit-border material). This was an experimental ablation only. **The shipped Performance profile retains every stadium structure, prop and decorative mesh.** No architectural geometry was removed to obtain the production result below.

## Implemented race-only quality preference

Existing Settings now offers:

- **Performance (default/recommended):** no dynamic shadow map, no MSAA, 116 evenly distributed spectators, and one inexpensive feathered contact-shadow batch for all eight athletes.
- **Enhanced:** the approved original dynamic daylight shadows, 2× MSAA and all 346 spectators; contact approximations are hidden.

Both retain the same half-resolution 3D viewport/full-resolution UI, eight runners, animation, original stadium vertex geometry/materials, approved camera and HUD. Full/reduced crowds share one mesh/material. Reduced instances sample the whole stand instead of disappearing from later seating sections. `race_course.gd` only retains its already-generated crowd transforms/colors for this purpose; no geometry-generating values changed.

The preference is stored separately in `user://race_graphics.cfg`, applied on the next race. It does not add a career field or migration, change Training or save schemas, or affect Athlete Studio/sandbox rendering. Invalid preferences fall back to Performance. A preference-write failure retains the previous choice. Both profiles are available by keyboard and mouse at 1280×720 and 800×600.

Contact shadows use the same explicit transform/color instance layout as the existing animated batches. A real-render image regression checks visible legs at the moving player position, preventing apparent performance gains from missing athlete geometry.

## Finished-profile comparison — software only

Same controlled setup, order Enhanced / Performance / Performance / Enhanced, using the actual quality implementation including contact shadows and the complete decorative geometry:

| Profile | FPS range | Mean frame-time range | p95 range | Max draw calls |
| --- | ---: | ---: | ---: | ---: |
| Enhanced | 3.23–3.36 | 297.55–309.95ms | 359.1–365.2ms | 131 |
| Performance | 5.45–5.97 | 167.41–183.62ms | 240.3–352.1ms | 83 |

Mean frame time is about **42% lower**, with **48 fewer draw calls**, without removing runners or stadium meshes. This is an improvement in the constrained software environment, **not a smooth-playback or hardware-performance pass**.

Process-memory snapshots: the largest application renderer RSS is about **261–264MiB** across these samples. The separate SwiftShader GPU-process RSS is **185–193MiB** in Performance versus **237–240MiB** in Enhanced. V8 JS heap is approximately **46.5–46.7MiB**. These are instantaneous process measurements, not peaks, total browser RAM or physical GPU VRAM; shared pages prevent simply summing RSS. Other browser processes consume additional memory. Godot's release Web static-memory monitor returns zero and is treated as unavailable.

## Final verification and limits

- **1,007 native assertions pass**: all prior 993 plus 14 quality/default/persistence/layout/eight-runner/geometry-preservation checks. Import and 120-frame smoke pass. No errors/warnings in completed headless suites.
- **13 new real Chromium quality checks pass**: default/settings at both sizes, Enhanced selection, preference/career separation, Performance race finish with eight results, animated-leg image assertion, training/position preservation, preference reload and career reload. No recorded engine/JavaScript/WebAssembly/storage/network errors or warnings. The previously approved 27 Chromium checks remain historical evidence; they are not added to this follow-up count.
- Official **Godot 4.6.3.stable.official.7d41c59c4** and matching **4.6.3.stable** Compatibility single-thread `Web` export pass. Export preset and Pages workflow are unchanged. No deployment.
- Protected hashes for sprint physics, input/session, roster, results, career repository, Training, creator, Player Card and sandbox remain identical to the pre-refinement baseline. Both quality modes only change presentation properties. Experimental branch remains unchanged.

**The remaining release-gate gap is physical GPU testing.** On the user's Windows computer, inspect `chrome://gpu` and verify hardware acceleration plus an Intel/AMD/NVIDIA renderer rather than SwiftShader/llvmpipe. Serve the export over HTTP, use the same window size/career/readiness for both settings, warm up, and record repeated race FPS/frame times with Chrome Performance tools and process memory with Chrome Task Manager. A GPU/low-end suitability claim requires those actual measurements. The prior real-window blur verification limitation also remains; this quality pass does not claim to resolve it.

## Files and evidence

Changed for this follow-up: `scripts/race/race_world.gd`, `race_course.gd` (crowd metadata only), `scripts/ui/race_screen.gd` (preference application only), `scripts/ui/prototype_ui.gd` (Settings selector); new `scripts/race/race_quality.gd`, `race_contact_shadows.gd`, their UID sidecars, `tests/race_quality_test.gd`/UID, this report/raw results/screenshots, and README/TASKS/technical documentation. Approved race HUD construction, camera calculations and stadium mesh-generation logic are unchanged.

- [Raw GPU audit, ablations, profile measurements and test results](performance_release_gate.json)
- [Settings at 800×600](web-evidence/race-quality/settings-800.jpg)
- [Performance race](web-evidence/race-quality/performance-race-1280.jpg)
- [Enhanced readiness](web-evidence/race-quality/enhanced-readiness-1280.jpg)

Reproduce native quality checks with `godot --headless --path . --script tests/race_quality_test.gd` using disposable test storage. Existing Web export/HTTP-serving instructions remain valid. No commit, push, merge or deployment is authorized until approval.
