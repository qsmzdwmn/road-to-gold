# Experimental preservation — v0.2.5 (paused, NOT approved)

This branch preserves the unreviewed Athlete Lab and earlier rejected model experiments separately from the production v0.2.4 commit. The owner explicitly authorized this preservation commit; it does not constitute visual approval, production integration or approval to deploy. Do not merge into main without further approval.

The production athlete generator has been restored to the ae46254 implementation. This standalone nested project is hidden from the production Godot importer by prototypes/.gdignore. Source files, including historical notes describing intermediate integration attempts, are retained verbatim. Those notes are history rather than the current integration state.

## Contents

- assets/athletes/male.glb and female.glb: original Blender-generated prototypes, approximately 484 KB and 479 KB; six material definitions, no textures/external buffers, 22 bones each.
- assets/athletes/source/: Blender source files; tools/generate_athletes.py and tools/audit_meshes.py preserve generation/audit workflows.
- scripts/: isolated GLB adapter, stable original fallback, rejected polished fallback, customization-data copies and mesh helper.
- scenes/ and tests/: review scene and 57-assertion native lab suite. Future skinning/animation readiness is preliminary; sports clips and deformation quality have NOT been approved.
- evidence/archive/: actual screenshots, comparisons, raw browser/mesh audit results, earlier rejected GLBs/Blender sources, source backups, scripts and logs. Failed/intermediate runs are intentionally retained alongside successful runs. Browser profiles, engine caches and large generated Web runtimes are excluded from the commit; original workspace files remain preserved separately.
- The original mixed TASKS.md is preserved on this experimental branch; main has only its v0.2.4 section.

## Run manually

From this experimental worktree:

```sh
godot --path prototypes/athlete_lab --editor
# Isolated native checks:
godot --headless --path prototypes/athlete_lab --script tests/athlete_evolution_test.gd
# Offline asset generation (requires Blender; does not touch production):
blender --background --python prototypes/athlete_lab/tools/generate_athletes.py -- "$PWD/prototypes/athlete_lab/assets/athletes"
```

Preserved active geometry ranges from 5,368 to 6,304 indexed triangles depending on category/style, with six or seven rendered material surfaces. This exceeds the aspirational 1,500–3,000 reference and needs future artistic/optimization review. Lab Chromium used software SwiftShader, not a physical 4 GB Windows benchmark. No final visual approval, hardware performance certification, production integration, merge, push or deployment is implied.

Character development and v0.3 Career Hub are paused. Wait for explicit approval before further development.
