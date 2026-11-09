# ROAD TO GOLD — Game Design

Status: Version 0.2.3 GOLDEN ROAD, 2026-11-09. Current behavior and future Alpha scope are distinguished below.

## Vision and constraints
A zero-budget, desktop-first browser 3D sports career RPG. The player creates a fictional athlete representing a real country and directly controls competitions. Godot 4, GDScript, Compatibility renderer; minimalist procedural low-poly characters and venues, lightweight materials. Development must remain practical on Windows 10 with 4 GB RAM. No paid services, mandatory commercial assets, accounts, or servers. Use original or appropriately licensed assets; record attribution. No official Olympic logos, protected mascots, or implied Olympic affiliation.

The full career is approximately 15–20 in-game years, with branching events, development, setbacks, and retirement. Planned sports: 100m sprint, long jump, javelin throw, 100m swimming. Alpha 0.1 contains only sprint and a short career slice; it does not promise the complete multi-decade simulation.

## Athlete creation
Required fields: first name, last name, real country, skin tone, hair color, hairstyle, height, weight, and body proportions. Use a bounded, data-driven country list with stable codes and text labels; flags are optional and deferred. Provide text labels and keyboard-operable controls. Names have sensible length limits and are displayed as text.

Appearance is cosmetic in Alpha, including height, weight, and proportions. Skin tone, ethnicity, country, names, and hair never determine ability. Sporting attributes are explicit data separate from appearance. Proposed initial attributes: acceleration, maximum speed, stamina, and rhythm tolerance. Bound body controls to prevent broken meshes; use the same collision and race model for all appearances.

## Origins
| Origin | Starting age | Narrative and support |
| --- | --- | --- |
| FROM NOTHING | 15 | Poor background, limited resources; resourceful choices and access barriers. |
| THE LEGACY | 17 | Famous sporting family, excellent support, high expectations. |
| THE CHOSEN ONE | 20 | Elite potential, ambition, psychological challenges. |

For Alpha, each origin has one introductory event with at least two choices and a visible persisted consequence (for example support or confidence). Proposed: equal starting race attributes across origins for tuning; support and story differ. Long-term potential differences and psychological systems require approval. Treat psychological struggles respectfully; avoid diagnostic labels or punitive stereotypes.

## Version 0.2.2 player journey
Main Menu → Choose Your Athlete → Your Story → Your Appearance → Your Identity → Begin Your Legacy → Begin Career → existing test track.

The creator is hidden until New Career is pressed. Five persistent draft screens support Back/Next and Escape; moving between steps never discards selected fields. Opening a draft does not alter saved progress. The final BEGIN CAREER button validates and saves; an existing saved career or legacy test session requires an explicit replacement confirmation. Canceling replacement preserves both the old save and the editable draft. Leaving or reloading without confirming does not save the draft.

Origins use the specified ages (15/17/20) and short premise descriptions only. No story event, training, stat progression, race or career-year simulation is included in Version 0.2. Confirming/Continue enters the original movement test track, with a customized low-poly athlete for new careers and the original placeholder for legacy saves.

Customization: first/last name (1–32 characters, trimmed on commit, no blank/control-only names), one of 195 real-country entries with stable two-letter codes, six skin tones, four hairstyles, five hair colors, height 140–220 cm, weight 40–150 kg, shoulder width 0.80–1.30× and leg proportion 0.85–1.15×. Height/weight/build adjust only procedural visuals. Names/country/origin never change the movement controller. Hair color naturally has no visible hair surface when Bald is selected.

The shared live 3D preview stays visible during all five creator steps. Summary displays origin, name, country, derived starting age, height/weight and appearance choices. Controls are native keyboard/mouse widgets in a scrolling form with fixed navigation buttons and an independent lightweight preview. No existing track materials, camera or movement mechanics are redesigned.

## Planned Alpha player journey
Main Menu → Choose Your Athlete → Your Story → Your Appearance → Your Identity → Begin Your Legacy → Begin Career → Introductory Story Event → Career Hub → 100m Race → Results → Career Hub.

Menu offers New Career and Continue when a valid save exists. New Career opens an unsaved draft; final creation must confirm before replacing a save. Creator previews appearance and validates fields. Origin selection shows age and narrative. Intro choices explain their immediate consequence. Hub displays identity, origin, age, story consequence, personal best, and race entry. Results displays all eight finishers, times, player place, reaction time, and personal best status. Returning to hub preserves results. Replay is available; Alpha races do not advance age automatically. No training economy or full calendar yet.

## Sprint design proposal
Eight lanes, one player and seven AI athletes; straight 100m track, readable lane markers, lightweight fixed follow camera. No lane changes or collisions. Explicit focus/start overlay before racing.

Race states: staging → set → randomized signal delay → running → complete. Proposed controls: Space arms the start; alternate Left/Right arrows after the signal to accelerate and maintain rhythm. Provide remappable actions and a readable control hint. Early input after arming but before the signal is a false start; restart the attempt with no official result or PB. Pre-signal held keys must be released before accepting a start. Randomized delay and AI reactions use race seeds for debugging.

Reaction time is elapsed simulation time from signal to first valid player input. Rhythm rewards a moderate configurable cadence, with tolerance and diminishing rewards; unlimited key mashing must not dominate. Repeated same-key input and operating-system repeats do not count as alternating presses. Acceleration and top speed are bounded. Stamina drains with effort and influences sustainable speed; it must not lock the player out of finishing. AI uses the same movement constraints with seeded reaction and cadence variation. Country and appearance never enter AI or player performance formulas.

Time starts at the signal. Finish occurs when the athlete's logical race position crosses 100m; interpolate the crossing within the simulation step. Rank by unrounded finish times, display hundredths; exact simulation ties share rank. PB uses unrounded valid player time, stores its context, and updates only after a completed valid race. A background tab pauses and requires an explicit resume; discard wall-clock gaps. No online ranking or anti-cheat claims.

## Beyond Alpha
Training and recovery, season scheduling, qualification, branching relationships, aging, retirement and the other sports are later milestones. Add them only after sprint, Web export and saving are validated.

## Open design decisions
Approve control cadence and accessibility alternatives; origin balance and potential; stat ranges and progression; calendar granularity and retirement; country list maintenance; further model art direction; audio direction and optional sound cues. These are proposals, not completed mechanics.

## Version 0.2.1 — Athlete categories
New Career immediately opens Choose Athlete Category. Male Athlete and Female Athlete are explicit choices; neither is preselected for a fresh draft. Next requires a selection. Both have the same three origins, starting ages, country list, hairstyles/colors, skin tones, height/weight and shoulder/leg controls. Back/Next retains category and all customization. The category also appears in the summary and loaded-career status. No creator redesign, logo or branding asset change is part of this patch.

Both wear the existing sports kit. Modest shoulder/hip silhouette profiles distinguish the procedural models without exaggerated anatomy or additional mesh assets. Hair, height, weight, skin and proportion choices remain independent; category selection never resets them. Movement and athletic ability are unchanged. The selected competition category is an explicit player choice, never inferred from name, country or appearance.

Future competition paths will use the stored category to distinguish records, opponents and progression. No separate competition, opponent, record, story or progression system is implemented here. Older careers that never selected a category remain unselected and keep their original neutral v0.2 visual profile; they are not automatically assigned to either future path.

## Version 0.2.2 — THE LOCKER ROOM presentation
The five steps separate athlete category, origin, cosmetic appearance, identity and final review. The former welcome screen is folded into concise step descriptions. All existing category, origin and customization choices remain available; identity validation blocks review until names are valid. The selected origin determines the displayed starting age. Summary includes every saved appearance choice and the unchanged final replacement guard.

The visual palette is Midnight #101820, Graphite #28333B, Ivory #E9E8E3 and Muted Gold #C6A66B. Existing ROAD TO GOLD typography and logo assets remain in use. The creator places compact controls on the left and a full-body athlete in a quiet procedural locker room on the right, with a numbered progress indicator above and persistent navigation below. Narrow windows stack the form and preview; form scrolling does not move navigation. Both category models have modest neck/shoulder/limb refinements and simple training clothing. The neutral legacy visual remains unchanged. Camera position, rotation and orthographic size never animate or change between steps.

This is presentation and navigation work only: no story progression, competition paths, new sporting attributes or gameplay are added. Skin tone and all other appearance controls remain cosmetic. The single-slot save and explicit replacement policy are unchanged.

## Version 0.2.3 — GOLDEN ROAD main menu
The approved Golden Path full logo is the primary brand element in a cinematic split menu: roughly 40% left content, symbolic curved pathway on the right, restrained warm horizon light and negative space. The logo is about 25% larger than the first implementation; the intentional three-line tagline reads Your Story. / Your Sacrifice. / Your Legacy. Buttons retain their existing actions and keyboard support, with gold focus/hover accents and readable disabled Continue text. The menu supports 800×600 and larger desktop windows.

Fresh sessions say Your journey begins here. Valid careers display the existing athlete name; position-only sessions use a generic saved-progress caption. Long names can truncate visually with a full tooltip. Original logos remain unchanged. The standalone emblem appears in loading and the existing Locker Room header without changing its five steps or static full-body camera. No gameplay, athletic performance, competition or save-format change is included. The menu pathway is symbolic and cannot be played.

The v0.2.3 preview-facing correction rotates only the creator preview instance 180°: model-forward (-Z) faces the fixed camera on +Z, with the ponytail behind the head. This constant orientation is shared by all five steps and both categories. Camera transforms, the shared athlete model, gameplay instance and serialized appearance data are unchanged.
