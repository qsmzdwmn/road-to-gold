# Athlete Evolution architecture — inspection before geometry changes

The v0.2.4 working tree is intentionally retained and uncommitted. Its final native run passes 422 assertions; the exported build passes 54 core and 30 final Chromium checks. Before v0.2.5 edits, the existing suites are rerun and the generator/Web build are backed up outside the repository.

`procedural_athlete.gd` is instantiated once in the creator's existing SubViewport/locker room and once beneath the gameplay athlete. `apply_appearance(data, category)` updates materials, scales and positions. Local -Z is the face, +Z the ponytail. The creator instance yaw is 230 degrees; its static camera and gameplay instance rotation remain untouched. Named `parts`, material properties, visibility and dimension updates are also inspected by existing tests.

Appearance IDs: Bald/Cropped/Short curls/Ponytail = 0/1/2/3; Black/Brown/Blond/Auburn/Gray = 0..4; six skin tones = 0..5. Height 140..220 cm; weight 40..150 kg; shoulders .8..1.3; legs .85..1.15. Skin/color do not affect proportions, movement or ability.

Category IDs remain `male`, `female`, or empty for an unselected legacy career. Schema 1 stores a test position; schema 2 an uncategorized career; schema 3 an explicitly categorized career. The repository, path, validation, country/origin catalogs and serialized fields will not change. Empty-category models keep the old neutral geometry; no category is inferred.

Movement remains in `placeholder_athlete.gd`, with unchanged speed, input and position clamps. Cosmetic geometry contains no physics bodies. The shared generator changes both explicit-category preview and gameplay appearance without modifying either camera, creator UI, character controls or career progression.

Plan: reusable smooth low-poly ellipsoids, tapered ring meshes and small face/kit details; batch visible geometry into one mesh with shared material surfaces. Retain named source parts for customization/debugging and existing tests, with rendering disabled on their layers when batched. Rebuild only on geometry changes; skin/hair color changes update existing materials. Measure visible triangles/surfaces and actual renderer counters rather than prescribe an appearance-limiting triangle cap. A separate test-only showcase provides front/side/three-quarter views without moving production cameras.

## New Generation brief — additional audit before asset changes

Blender 4.3.2 is installed at /usr/bin/blender. Godot remains official 4.6.3. Baseline after Anatomy Polish: all 422 existing assertions pass and the focused geometry tests pass; real Chromium palette checks cover both categories and all hair/skin IDs. The full browser regression is running separately. The current implementation is preserved as `fallback_polished_athlete.gd`; the original v0.2.4 generator is preserved as `fallback_athlete.gd`.

Hierarchy/API dependencies: production callers require `new()`, `apply_appearance(AppearanceData, category)`, no animation/movement API. Tests inspect named `parts` transforms/visibility/AABBs, DETAILS, `skin_material`, `hair_material`, `kit_material` and model scale. Preview yaw230/camera/static scene are external to this model and must not change. Serialized values belong exclusively to existing data/repository classes; neither meshes, bones, materials, geometry counters nor facial coordinates are saved.

Implementation proposal: original Blender-generated connected body topology, low-poly face/hair/kit, humanoid armature with useful spine/limb joints and skin weights, compact male/female GLB assets. A Godot compatibility adapter keeps original API and named reference dimensions while rendering imported assets. Category-empty saves render the original neutral fallback; no category inference. Preserve current polish fallback for comparison/debugging.

Customization deforms geometry/rest positions using the existing height/weight/shoulder/leg values, and updates original color materials/style visibility. No data fields change. Confirm GLB axis conversion keeps local -Z front. Reuse a static review scene for matched before/after, and verify actual creator/gameplay instances separately. Asset generation is offline; Blender is not a runtime dependency.

Blockers/risks: visual fidelity needs actual review, not a claim of concept equivalence; Web skin/morph compatibility must be verified; extreme allowed body combinations need framing checks; software-renderer timing cannot establish Windows4GB performance. Full sports animation, retargeting/LOD tuning and physical-hardware performance are outside the first visual prototype. Stop for visual review before committing/pushing/deploying.
