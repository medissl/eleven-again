# Gameplay batch — 28 October 2026

User requested a larger implementation batch covering gameplay, attributes, AI, tactics and researched signature traits with real action-driven effects. Three-minute regulation and the accepted UI direction remain fixed. Work proceeds in local tested increments on `codex/gameplay-batch`.

Boundary increment: earliest whole-ball boundary crossing, actual last-touch throw/corner/goal-kick classification, physical restart deliveries and contact-conditioned basic fouls. Native runner: 113,087 assertions, zero failures, including full presented/headless 1×/2× equality. Authored crossing/near-corner/own-goal/restart-delivery checks added. Rendered batch acceptance and remaining rule details will be recorded after integration; this checkpoint alone does not complete all football rules.

## Match-system integration checkpoint

- Native immutable fictional card Resources; all six outfield and five keeper attributes, exact role OVR/familiarity, four derived tiers and one effective-attribute path. Role/trait/fatigue apply once, with no OVR multiplier.
- Native preparation: legal XI/bench, three formations, nine attack/defence combinations, width/chance route, captain/takers, penalty order and automatic substitution plans. Private submitted plans isolate the match from later widget changes. Enlarged native preparation renders and actual Enter submission passed at 720p/1080p.
- Contextual support triangles, one-two/third-player intentions, elected pressure with cover, direct/counter/possession utilities, finite acceleration/turning, actual first-touch contacts, ground/aerial delivery and simulated curved shots.
- Work/PHY/tactic-dependent fatigue, legal template/pinned substitutions with limits and no re-entry. Original event actor identities survive substitutions.
- All 36 trait eligibility/modifier definitions wired to real action families; use/cooldown/stamina limits, stable action IDs and idempotent activation/resolution. Aura/overhead label and action-family icon read simulation state; no VFX RNG in football. Two fictional fixture squad choices collectively expose all traits. Ordinary football does not require a trait.
- Pass-time positional offside with actual ball involvement and direct-restart exemptions; contact-conditioned fouls, cards, penalties, trained/emergency keeper replacement and fewer-than-seven forfeit. Basic circle-centre offside does not model every interference-with-opponent edge case. Automatic restart setup omits referee delay protocols and full 3D body anatomy.
- Plain-data, engine-versioned in-memory snapshots preserve ball/curve, offside, cards, substitutions, trait windows/uses and RNG. Binary round trips and future-state equality pass during kickoff, flight, dead ball, trait activity and substitutions. This is not yet a disk save/Continue feature.

Full native runner after contact correction: **110,902 assertions, zero failures**. Focused batch runner: **328 assertions, zero failures**, before the final specialist-coverage assertions. Native GL trait-motion sequence completed 70 frames; final rendered review remains part of the continuing batch. No balance, full run, historical catalogue, permanent collection or exported build is claimed.

Paired 60/100 attribute comparisons over 96 seeds: pass displacement sum 99.38/60.11; difficult receptions 74/85; clean DEF wins 26/40; PHY shielding losses 34/29; REF saves 39/53; HAN holds 29/35; DIV reachable saves 0/44. Separate PAC, keeper POS/KIC and PHY-endurance comparisons pass. These authored isolated scenarios establish domain effects, not match balance.

Next increment in this user-authorized batch: extra time/shootouts, remaining trait/rule edge cases, final rendered/input review and updated task evidence. Run/recruitment/market/profile/disk persistence remain separate systems; scope clarification was requested asynchronously while match work proceeded.
