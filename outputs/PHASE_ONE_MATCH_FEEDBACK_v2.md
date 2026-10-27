# Eleven Again — Phase 1 player feedback and match-experience revision

27 October 2026. User feedback after Phase 1. This is an inspected-source assessment and implementation handoff, not a gameplay patch or evidence of a runtime fix.

## 1. Confirmed feedback and current scope

The user wants convincing visible football, meaningful player attributes, genuine set pieces, an on-field goal celebration with confetti, and a halftime pause showing what happened. This is stronger presentation than changing clock text. The earlier suggestion to avoid confetti and auto-resume halftime does not satisfy this clarified requirement.

Keep the full-field circle-player presentation and the decision to omit spectators/stadium extras. Regulation is already 180 active seconds in the inspected implementation, with two 90-second halves. Do not restart the duration discussion as though the three-minute change were still absent.

Phase 1's report explicitly leaves human watchability approval open. Passing its technical checks does not establish that the football is complete, every attribute exists, or the user enjoys watching it.

## 2. Findings from the current source

Reviewed `match/match_sim.gd`, `match/match_view.gd`, `ui/match_hud.gd`, relevant existing tests, the Phase 1 report and task tracker. Verified the available console executable reports Godot 4.7.2.stable.official.ed1daf0bf. No match run or new behavioural test was performed for this feedback assessment.

| Concern | Current implementation | Consequence |
|---|---|---|
| No free kicks | `challenge_carrier()` resolves clean wins or unsuccessful challenges; no foul award exists | Free kicks cannot emerge from the present challenge rules |
| No corners | Ordinary boundary exits become a generic `restart`; no corner classification exists | More playtesting cannot reveal a corner feature that is not implemented |
| No visible keeper deflections | `keeper_save()` includes a parry branch following a successful save; 28% is the code's branch probability, not a measured fixture frequency | The capability exists, but the complete presentation and boundary consequences are limited |
| Parry never goes behind for a corner | Current parry velocity points back toward the field and produces a damped central loose ball | It is not a model of varied fingertip deflections, touches around posts, or tips over the bar |
| Feed does not explain a parry | An explicit `parry` description exists but `refresh_events()` omits it from the default allowlist | A save may be listed without making the live rebound clear |
| Goal/halftime effects feel too small | Goal text changes in the clock, a scorer ring and net recoil; halftime is a short automatic dead phase | There is no requested central GOAL/confetti presentation or user-dismissed halftime report |
| All six attributes/OVR matter | Five outfield attributes plus one generic keeping value are present; PHY and the full role/OVR system are not | Some attributes matter already, but the complete advertised system is not implemented |

These are findings from the inspected code. They do not establish how often a player sees each event, or prove a perceived animation issue's full runtime cause. Do not claim the reported observation has been reproduced solely from this review.

## 3. Set pieces must emerge from actual play

Free kicks are associated with offences; ordinary touches or a clean tackle are not sufficient. Corners can arise when a defender/keeper is last to touch a ball that crosses the defending goal line outside a scored goal. A parry may also stay in play or go over a touchline. Use the actual crossing and last-touch context, not a periodic corner/free-kick lottery.

Official reference points: [IFAB Law 17](https://www.theifab.com/laws/latest/the-corner-kick/) and [IFAB Law 12](https://www.theifab.com/laws/latest/fouls-and-misconduct/). Those laws contain additional cases; do not represent the brief examples here as an exhaustive implementation of all current laws.

### Boundary and contact improvements

- Classify the first boundary actually crossed by the ball's movement segment, including large per-step travel. A crossing near a corner must not create both a throw and corner.
- Preserve last touch for a tackle contact, defender block, keeper touch, and rebound, not just the player who originally shot.
- Support imperfect first touches and genuine defensive deflections where football context warrants them. Do not make every interception an instant perfect controlled reception.
- Allow goalkeeper hold, live parry, deflection behind, and other reasonable outcomes from shot direction, keeper reach/position and handling. A 2D top-down simulation does not need a complete 3D physics engine; if height is relevant, a small explicit height/flight-type model can distinguish a tip over the bar from a ground rebound. Do not draw a grounded corner-triggering ball going through the goal mouth and then deny the apparent goal without explaining height.
- A held save stays with the keeper; a parry creates one real ball with appropriate velocity; a ball exiting after the touch uses the same boundary classifier.
- Add foul outcomes based on meaningful challenge context, such as lateness and contact angle. Differentiate clean tackles, failed attempts, fouls and serious misconduct. Contacts should not all become fouls.
- After an award, arrange a legal, bounded restart with assigned takers, teammates, opponents and keeper. Delivery returns to the ordinary ball/contest model.

Test authored cases that must produce a corner, goal kick, throw, live rebound and free kick. Then observe ordinary seeded matches to check that the events arise at plausible rates. Forced scenario correctness and natural match frequency are separate acceptance criteria. Do not insert fake set pieces merely to guarantee one per game.

## 4. Goal presentation — explicit on-field event

The requested goal sequence is:

1. The ball crosses the line; the authoritative score and goal event commit once.
2. Stop active play for the goal/restart phase and preserve the scoring moment briefly.
3. A prominent **GOAL!** graphic appears over the field, with scorer, minute and updated score. Use large readable display typography and the scoring team's accent.
4. Add a short local confetti burst, a clear net reaction, and an optional scorer pulse. Keep the full pitch/camera orientation stable; no spectator art is required.
5. Fade the celebration, reveal the restart shape, and resume automatically. The persistent feed retains the event.

Initial presentation target: roughly 2–3 seconds of readable celebration, to be checked at both speeds. Provide reduced-motion and effects controls; replace confetti with a static/fade cue when requested. Keep the emitter count capped and stop/clear it reliably on restart, exit, and scene changes.

Cosmetic particles use a separate RNG and cannot touch the ball or consume gameplay randomness. Neither a tween callback nor a particle ending awards a goal or reward. Coordinate the overlay with the existing deterministic dead phase so there are not two back-to-back, unnecessarily long goal pauses. A headless fixture can bypass presentation waiting without altering the authoritative event sequence.

## 5. Halftime — pause and explain the half

At 45 displayed minutes, freeze the match and open an on-field halftime overlay. This explicitly replaces the earlier auto-dismissed three-second transition. The user presses **Continue second half** when ready. Remain a watch-only manager: this feedback does not introduce live tactical edits or extra substitutions outside the existing plan.

Required content:

- Current score and clear HALF-TIME heading.
- Team possession percentages, calculated from the actual recorded possession counters with a documented denominator. If current counters only cover controlled-ball ticks, label the metric accordingly until a fuller definition exists; flight/loose time must not be silently invented.
- Shots, shots on target, saves, completed/attempted passes and optional completion percentage.
- Scorers and significant first-half events, such as important saves, cards or substitutions when those systems exist.
- One or two factual observations where supported by data, not invented causal analysis.

Use a dimmed pitch backdrop and a compact, readable summary rather than a wall of narrative. Show a scrollable event list if necessary. Retain the overlay until a deliberate Continue action; Escape/menu/settings must not accidentally dismiss it into live play.

Snapshot first-half values once on entry. Do not accidentally display full-match aggregates or recompute from events that occur after the half resumes. Distinguish team-controlled possession percentages from exact full-match real-world analytics.

The fixed-step loop must stop immediately at the halftime boundary, even during a 2× update that would otherwise execute another step. While the overlay is open, consume no active time, RNG, stamina, or gameplay ticks. Continue changes the appropriate phase once; duplicate input does not start the half twice. Headless tests use an explicit acknowledgement/bypass for the presentation wait, preserving the same match state and results.

Full time should similarly lead to a persistent result/summary with a deliberate Continue action. Keep shootout goals separate once that phase exists.

## 6. Attribute influence — current state and intended improvement

| Attribute | Existing influence | Observable complete-system target |
|---|---|---|
| PAC | Movement speed | Bounded acceleration/recovery pace and runs into space; not teleportation |
| SHO | Shot aim probability, shot velocity, opponent save probability | Same chance finishes more reliably with better technique, while angle/pressure still matter |
| PAS | Pass aim probability and velocity | Better execution and a broader set of worthwhile through balls/crosses under risk-aware decisions |
| DRI | Resistance to tackle/smother probabilities | First touch, turning with the ball and carrying through pressure, in addition to challenge resistance |
| DEF | Standing-tackle clean-win probability | Marking/interception response and appropriate challenge execution, not just a single tackle roll |
| PHY | Not present in the inspected Footballer model | Strength/aerial contests and stamina endurance under capped, tested rules |
| Keeper attributes | One generic keeping value | Role-aware reflex, handling, position, diving and distribution influences as planned in task 2.1 |
| OVR | Full data-backed role rating not implemented | Weighted summary of actual relevant attributes and familiarity; no additional hidden score multiplier |

High OVR must not simply instruct a hidden score generator to award more goals. An excellent striker should finish better; an excellent passer should execute better options; strong defenders should actually prevent chances. A weak team can still create a good chance or win a match. One stat cannot provide every skill, and 120 is a cap rather than an invincibility flag.

## 7. Improve football intelligence before expanding content

The basic 2D approach can support much more convincing football through utility-based action choices, team shape and state machines. An online LLM or machine-learning training system is not required.

Priorities:

1. **Off-ball shape:** passing triangles, width, defensive cover, screening, runners beyond a defender, and avoiding ball swarms.
2. **Choices under context:** compare carry/pass/shoot/cross/clear using expected football value and actual player strengths. Do not make every forward pass preferable to a useful recycle.
3. **Defensive response:** pressure plus covering/screening, meaningful interceptions and imperfect contacts, rather than every defender chasing the ball or every interception becoming a perfect catch.
4. **Keeper variety:** observable positioning, hold/parry/deflection consequences, and live second balls.
5. **Role/tactic identity:** a physical forward, creative midfielder, fast winger and defensive midfielder should produce distinguishable play. A tactic changes behaviours, not an unexplained matchup multiplier.

A compressed three-minute match cannot reproduce every feature of a full-length professional match. It can preserve recognisable patterns and meaningful football decisions. Judge that from motion and player feedback, not from how many rules or lines of code exist.

### Evidence that attributes matter

For each attribute, create controlled scenarios changing only that attribute, such as 60 versus 100, over repeated seeds. Check the relevant outcome: movement/recovery time, same-chance finishing, pressured pass accuracy, ball retention, correct interceptions/tackles, physical contests or fatigue. Keep geometry, opponents and other inputs fixed where practical. Assert a directional distributional effect, not that every high-stat roll must win.

Then test integrated fixtures and several team compositions. A generic highest-OVR team should not automatically erase positional fit. Recheck 1×/2×/headless equivalence after AI changes, and watch actual output for robotic repetition, poor supporting runs and unreadable deflections.

No fixed pass count, assertion count, or score range proves the AI feels like football. The user's observed feedback remains part of acceptance.

## 8. Recommended work boundary and handoff

Do not proceed directly to a large historical roster or recruitment economy while these match-experience concerns remain unresolved. Keep existing technical progress, but treat the human-watchability gate as open.

Recommended next slices, to be agreed with the implementing workflow rather than silently rewriting tasks:

1. Goal overlay/confetti and the paused first-half summary, with state-isolation and interaction checks.
2. Data-backed complete attributes/role ratings from Phase 2.1 and measurable attribute scenarios.
3. Targeted off-ball/action/keeper improvements based on observed play.
4. Bring boundary-aware restarts and a small genuine foul/free-kick/corner slice forward if the user requires those to judge the football, rather than waiting until after the recruitment/save work. Full discipline/offside/rules can retain their later verification boundary.

Moving planned Phase 5 functionality earlier is a proposed roadmap adjustment. It is not evidence those features already work or permission to implement every later system in one session. Review dependencies explicitly; prototype in-memory restart state does not require building the entire future persistence system first.

### Sendable request

> Treat this as Phase 1 human feedback, not approval that watchability is complete. The user wants genuine football and meaningful stats: inspect the current generic restarts, inward-only parries, narrow stat influences and missing PHY/OVR system. Implement in small verified slices: an on-field GOAL graphic with brief confetti, a paused halftime stats/events summary with Continue, then complete attribute influence and targeted AI/keeper improvements. Propose pulling a minimal real foul/free-kick/corner slice forward so the football can be evaluated before building the full roguelike content. Preserve three-minute timing, fixed-step speed equivalence, existing work, no spectators, and truthful state-driven score/feed/effects. Add behavioural and visual checks appropriate to each slice; do not fake set pieces or claim balance from passing static tests.

## Verification limit of this delivery

This document reflects source inspection and the reported user experience. Only the Godot executable version was executed here. No code was changed, no native regression suite was rerun, no fixtures were sampled, and no new runtime UI or AI behaviour was verified. The existing report's test claims remain that report's evidence, not new testing by this assessment.
