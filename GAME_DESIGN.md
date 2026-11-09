# ROAD TO GOLD — Game Design

Status: documentation proposal, 2026-11-09. No implementation authorized yet.

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

## Alpha player journey
Main Menu → Character Creator → Career Origin → Introductory Story Event → Career Hub → 100m Race → Results → Career Hub.

Menu offers New Career and Continue when a valid save exists. New Career must confirm before replacing a save. Creator previews appearance and validates fields. Origin selection shows age and narrative. Intro choices explain their immediate consequence. Hub displays identity, origin, age, story consequence, personal best, and race entry. Results displays all eight finishers, times, player place, reaction time, and personal best status. Returning to hub preserves results. Replay is available; Alpha races do not advance age automatically. No training economy or full calendar yet.

## Sprint design proposal
Eight lanes, one player and seven AI athletes; straight 100m track, readable lane markers, lightweight fixed follow camera. No lane changes or collisions. Explicit focus/start overlay before racing.

Race states: staging → set → randomized signal delay → running → complete. Proposed controls: Space arms the start; alternate Left/Right arrows after the signal to accelerate and maintain rhythm. Provide remappable actions and a readable control hint. Early input after arming but before the signal is a false start; restart the attempt with no official result or PB. Pre-signal held keys must be released before accepting a start. Randomized delay and AI reactions use race seeds for debugging.

Reaction time is elapsed simulation time from signal to first valid player input. Rhythm rewards a moderate configurable cadence, with tolerance and diminishing rewards; unlimited key mashing must not dominate. Repeated same-key input and operating-system repeats do not count as alternating presses. Acceleration and top speed are bounded. Stamina drains with effort and influences sustainable speed; it must not lock the player out of finishing. AI uses the same movement constraints with seeded reaction and cadence variation. Country and appearance never enter AI or player performance formulas.

Time starts at the signal. Finish occurs when the athlete's logical race position crosses 100m; interpolate the crossing within the simulation step. Rank by unrounded finish times, display hundredths; exact simulation ties share rank. PB uses unrounded valid player time, stores its context, and updates only after a completed valid race. A background tab pauses and requires an explicit resume; discard wall-clock gaps. No online ranking or anti-cheat claims.

## Beyond Alpha
Training and recovery, season scheduling, qualification, branching relationships, aging, retirement and the other sports are later milestones. Add them only after sprint, Web export and saving are validated.

## Open design decisions
Approve control cadence and accessibility alternatives; origin balance and potential; stat ranges and progression; calendar granularity and retirement; country list maintenance; final visual palette and proportions; audio direction and optional sound cues. These are proposals, not completed mechanics.
