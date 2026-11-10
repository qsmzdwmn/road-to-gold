# Athlete Studio 2.0 — pre-implementation UI/data map

Inspected main `ae46254`, Godot 4.6.3, before replacing controls. Baseline import/main smoke and all 332 existing native assertions pass. No local modifications or new main commits were found.

| Existing field/control | Stored field / exact meanings | Studio control |
| --- | --- | --- |
| Category toggle buttons | `career.athlete_category`: explicit `male` / `female`; empty legacy remains omitted | Two selectable silhouette cards |
| Origin toggle buttons | `origin_id`: `from_nothing`, `the_legacy`, `the_chosen_one`; derived age 15/17/20 | Three narrative cards; read-only age |
| First/last LineEdit | `athlete.first_name` / `last_name`: nonblank trimmed commit, max 32 chars, no control characters | Labeled identity inputs; raw draft retained |
| Country OptionButton | `athlete.country`: same 195 authored real-country codes, default US | Existing native country dropdown |
| Skin OptionButton | `appearance.skin` integers 0–5; same six hex colors/order | Six labeled swatches in Skin tab |
| Hairstyle OptionButton | `appearance.hairstyle` 0 Bald, 1 Cropped, 2 Short curls, 3 Ponytail | Four lightweight drawn visual tiles in Hair tab |
| Hair color OptionButton | `appearance.hair_color` 0 Black, 1 Brown, 2 Blond, 3 Auburn, 4 Gray | Five labeled color swatches in Hair tab |
| Height SpinBox | `appearance.height`: 140–220 cm, step 1 | Slider + precise SpinBox; linked Body and Identity views |
| Weight SpinBox | `appearance.weight`: 40–150 kg, step 1 | Slider + precise SpinBox; linked Body and Identity views |
| Shoulder SpinBox | `appearance.shoulders`: 0.80–1.30×, step 0.05 | Body slider + precise SpinBox |
| Leg SpinBox | `appearance.legs`: 0.85–1.15×, step 0.05 | Body slider + precise SpinBox |
| Plain summary Label | Actual category/origin/age, identity and all seven appearance fields | Grouped Player Card, no fabricated ratings/statistics |

Height and weight intentionally appear in both Body and Identity as requested. Native Range sharing will bind each pair to one canonical value. No duplicate data fields are introduced. Selection components retain the small `.select(index)` / `.selected` interface used by existing integration checks; actual visible tiles/swatches own this state, with no hidden legacy dropdowns.

All numbers remain finite and within existing validation bounds; selection indices remain integers. Proportions retain the existing decimal serialization. Country/name/skin/height/weight remain cosmetic and do not alter movement or ability.

The creator owns one session draft and emits the same final career signal. One existing SubViewport/model/locker room is retained, with the same orthographic camera and static 180° preview rotation. Final confirmation alone may write through App/SaveRepository. An existing file requires the existing explicit replacement dialog and repository authorization. Cancel preserves old bytes and draft.

SaveRepository is unchanged: same `user://prototype_v1.json`, custom directory, schema 1 track probes, schema 2 uncategorized careers and schema 3 explicitly categorized careers. No migration, classification, field reordering, extra appearance attributes or save-on-tab-change is allowed. UI tabs are session state only. Original Golden Path PNGs and the Golden Road menu/loader remain unchanged except the single version metadata update.
