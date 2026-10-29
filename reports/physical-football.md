# Physical ball continuity — 29 October 2026

One causal football slice based on `27c892a`; Godot 4.7.2 / GL Compatibility. Preserves cards/portraits, ratings, campaign economy, renderer/HUD, save fields and 180 active regulation seconds. Unrelated working files remain intact.

## Delivered

Untouched deliveries retain incoming momentum after their intended arrival; curved deliveries retain the tangent. Curved shots continue beyond their aiming point. Loose balls use provisional constant 5 m/s² deceleration instead of 4% loss per tick; poor touches retain 40% incoming speed before the existing trait modifier. These are tuning choices, not measured realism.

Swept flight/loose contacts and whole-ball boundaries resolve in chronological order. An endpoint pickup cannot rescue an already-out ball; roster iteration cannot decide the first touch. Shot saves compare the actual keeper-plane contact against blocks and the boundary. Blocks reflect around their contact normal. Existing cooldowns prevent immediate rebound recapture by the deflector.

Opposing non-shot keeper contacts use HAN, speed, height and nearby pressure for catch/parry. Teammate deliveries retain foot reception. Shot saves reject out-of-area or vertically unreachable contacts. Central glove contacts turn momentum back into play; glancing saves can retain forward travel and exit. A save awards no corner by itself. Actual last touch and offside eligibility survive a parry. Shootouts share loose integration without ordinary recovery.

No new authoritative fields/schema. Existing snapshots remain loadable; future equality means exact continuation under the new implementation, not unchanged historical outcomes after physics changes.

## Native evidence

Actual seed-11027 before/after captures preserve the rich textured field and unchanged bodies/names. Links show 10 fps excerpts resized for convenient playback; full native frames remain in `.godot/football-motion/`.

| Output | Before | After |
|---|---|---|
| 720p / 1× | [clip](physical-football/baseline-1x.webp), [sequence](physical-football/baseline-1x-sequence.jpg), [native still](physical-football/baseline-720.png) | [clip](physical-football/after-1x.webp), [sequence](physical-football/after-1x-sequence.jpg), [native still](physical-football/after-720.png) |
| 1080p / 2× | [clip](physical-football/baseline-2x.webp), [sequence](physical-football/baseline-2x-sequence.jpg), [native still](physical-football/baseline-1080.png) | [clip](physical-football/after-2x.webp), [sequence](physical-football/after-2x-sequence.jpg), [native still](physical-football/after-1080.png) |

Reviewed sequences show real ball separation/receptions and local trait cues; existing crowded support/role patterns remain. This is sequence review, not human approval or profiling. Initial sandboxed renderer attempts failed cache/allocation access; successful captures used normal local cache access. The original 1080p baseline retained 190 frames without a completion marker; only its first 100 are presented. Completed after runs explicitly pass per-frame headless equality (600 frames each speed).

Authored native scenarios, each with per-frame headless equality:

- [Glancing save → parry → corner](physical-football/corner.webp), [sequence](physical-football/corner-sequence.jpg). Actual seed-3 contact (104,37), mirrored model case (1,31).
- [Central save → live rebound → recovery](physical-football/live_save.webp), [sequence](physical-football/live_save-sequence.jpg). No corner; subsequent football can continue to a real shot/goal.
- [Overhit pass → throw](physical-football/overhit.webp), [sequence](physical-football/overhit-sequence.jpg).
- [Off-centre block](physical-football/block.webp), [sequence](physical-football/block-sequence.jpg).

## Same twenty-fixture diagnostic

| Metric | Before | After |
|---|---:|---:|
| Mean goals / shots / completed passes | 3.55 / 16.85 / 77.25 | 2.80 / 14.85 / 69.40 |
| Scoreless / unfinished fixtures | 0 / 0 | 1 / 0 |
| Throws / corners awarded | 0 / 0 | 67 / 20 |
| Saves / parries / poor touches | 48 / 13 / 26 | 52 / 19 / 29 |
| Fouls / yellows | 4 / 2 | 2 / 1 |
| Offsides / penalties / reds | 0 / 0 / 0 | 0 / 0 / 0 |

155 untouched intended pass arrivals in the new sample. Counts establish opportunity, not desirable frequency/balance. No event injection or score correction. The diagnostic now accepts genuine 0–0s instead of requiring minimum goals/chances. [Before log](physical-football/physical-baseline-watchability.log), [final log](physical-football/physical-final-watchability.log).

## Verification

- Final batch: **521 checks, zero failures**, including 110 physical assertions: mirrored boundaries, first swept contact, curve momentum, actual parry corners/no-corner recovery, blocks, legal/vertical keeper reach, HAN pairs, offside preservation and exact midflight/actual-parry snapshot futures. [Log](physical-football/physical-final-batch.log).
- Full runner before the final two extra assertions: **110,202 checks, one pre-existing score-font failure**. Other football/clock/1×/2×/headless, pause/report, shootout and presentation checks pass. The unchanged Matchday Score font measures `1111=59px`, `8888=90px` at 46px, violating the older equal-width assertion. Theme/HUD/view files match HEAD; no assertion was weakened. Track during the user's UI overhaul. [Full log](physical-football/physical-full-tests.log), [font probe](physical-football/physical-font-baseline.log).
- Save/backup/corruption recovery and journal interruption/idempotency/session checks pass. Two separate executable launches reproduce the next **600 ticks** exactly from a disposable disk save. Real campaign slot untouched. [Save](physical-football/physical-saves.log), [session](physical-football/physical-session.log), [writer](physical-football/physical-disk-write.log), [resumer](physical-football/physical-disk-resume.log).
- Headless editor import/parse and diff whitespace checks pass. [Import](physical-football/physical-import.log). Final native scenario logs reside beside these logs.

Model limits: powered intended flight then rolling resistance, linear loose height settling, simplified keeper-plane reach, basic aerial/clearance decisions, no post/crossbar restitution. Team perception/support, sophisticated clearances and contextual fouls/offside remain unfinished. No human enjoyment, performance or exported-build claim.

Interpretation checked against current official [IFAB Law 9](https://www.theifab.com/laws/latest/the-ball-in-and-out-of-play/), [Law 17](https://www.theifab.com/laws/latest/the-corner-kick/) and [Law 11](https://www.theifab.com/laws/latest/offside/); tuning constants are authored, not IFAB values.

## Boundary and next work

Physical continuity ends here. Next football task: coordinated whole-team intent/perception and reachable passing options on paired seeds. During verification the user reprioritized a connected UI/UX, pyramid progression and economy redesign: research/design that system before coherent implementation. Preserve this physics slice, saves and settled portraits; `tasks/todo.md` stays authoritative.
