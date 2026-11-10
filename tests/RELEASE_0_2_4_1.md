# v0.2.4.1 Athlete Studio Refinement — release verification

2026-11-10. Final male/female hairstyles received explicit visual approval. The owner authorized a production commit/push and dispatch of the existing GitHub Pages workflow on main with deploy enabled. Earlier review reports retain their original status as historical evidence.

## Approved scope

Six male and six female hairstyles with category-specific defaults and session selection memory; final targeted hairstyle polish; Appearance-only height/weight controls; stable body, camera and Player Card. Legacy IDs 0–3 retain their exact original meaning/geometry; IDs 4–15 are appended. Save schemas 1/2/3, keys, path, legacy category behavior, replacement confirmation and gameplay are unchanged. No experimental Blender/GLB branch is merged or imported.

The release updates the existing workflow by one native-suite command so CI runs all 521 assertions. Its trigger remains workflow_dispatch only, deploy defaults false, and publishing remains gated to main with explicit deploy=true.

## Fresh final verification

- Official Godot 4.6.3.stable.official.7d41c59c4 Compatibility; fresh native test-data directory.
- All **521 native assertions** pass, including import/main smoke, career/customization/schema compatibility, exact Legacy data, cached hair geometry, maximum-body framing and winding.
- **36 real Chromium 156.0.8078.79 checks** pass against a new export: all 12 styles, both category paths, Identity/Body separation, Player Card values, new IDs stored through schema 3, movement, overwrite/cancel, page reload and complete browser restart persistence. No recorded Godot/JavaScript/WebAssembly/storage/network warnings or errors.
- Matching official 4.6.3 single-thread Web release export returns zero. An isolated packed-build check confirms version 0.2.4.1, production model present, experimental directories/GLBs absent.
- Approved runtime-file hashes are unchanged during finalization. Story, Player Card file, gameplay, save repository/schema classes, loader and branding are unchanged from their approved production behavior.

[Raw final local results](release_0_2_4_1_verification.json). [Approved polish screenshots/statistics](HAIRSTYLE_POLISH_VERIFICATION.md). [Refinement flow/compatibility report](STUDIO_REFINEMENT_VERIFICATION.md).

## Publication procedure

After committing: fetch origin, verify remote main can fast-forward, push without force, and verify the remote SHA. Then dispatch the existing workflow using:

```sh
gh workflow run web-pages.yml --repo qsmzdwmn/road-to-gold --ref main -f deploy=true
```

Monitor the run for that exact source SHA; require both build and deploy jobs to succeed. Read the Pages URL from the configured site/deployment environment and verify the live browser reports VERSION 0.2.4.1. No site visibility/settings change, experimental merge or destructive recovery is part of this release. Stop and report any project-test, push or deployment failure.

This commit records tests completed before publication; it does not claim a deployment already happened. The release operation's final report records the resulting commit, workflow run, deployment status and live URL.

## Remaining limits

Physical low-end Windows/4 GB performance, additional browsers, screen readers and denied/private/quota storage remain unmeasured. Existing saves are backward compatible; older application binaries cannot interpret newly introduced hairstyle IDs. The experimental character milestone and Career Hub remain outside this release.
