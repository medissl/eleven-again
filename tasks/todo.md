# Eleven Again — development tasks

Task source of truth. Read `plan.md` for phase boundaries, GDD authority, architecture, checks, and prompts. Status on 28 October 2026: match-system batch implemented through preparation, attributes, coordinated AI/tactics, stamina/substitutions, set pieces/basic offside/discipline, ET/shootouts and all 36 researched traits. User confirmed **complete match systems first**; run/economy/disk saves/index remain pending. **Next: 3.2 — four-win run progression**, after playtesting this match batch. See [gameplay evidence](../reports/gameplay-batch.md). See [Phase 1 evidence](../reports/phase-one.md) and [kickoff evidence](../reports/kickoffs.md).

Each task below has a checkable outcome, verification, dependencies, and likely files. Paths are suggestions; inspect existing code before choosing them. S ≈ 1–2 files, M ≈ 3–5; split a task that grows beyond that. Update a completed task with concise evidence (actual command/result, seeds/screenshots where relevant, limits, and local commit). Checkpoints review the preceding work and do not automatically authorize a new phase.

## Phase 0 — project contract

- [x] **0.1 — Record the project workflow.** Preserve the GDD and add the roadmap, actionable tasks, project agent instructions, project design direction, and README.
  - Acceptance: confirmed requirements/proposals remain distinct; every phase has a boundary, acceptance gate, and verification; no gameplay is claimed.
  - Verification: document/reference/task dependency review; original GDD and Godot configuration compared against baseline.
  - Dependencies: none. Files: `AGENTS.md`, `DESIGN.md`, `README.md`, `tasks/plan.md`, `tasks/todo.md` (M documentation slice).
  - Evidence: 38 unique task IDs, all with acceptance/verification/dependency/file fields; local Markdown links resolve. Git comparison found no changes to the original GDD, Godot configuration, or icon assets. No gameplay/runtime/visual checks apply to this documentation delivery.
- [x] **0.2 — Establish local version control.** Initialize local Git, verify the GitHub repository through the plugin, configure `origin`, checkpoint original files, and ignore export/credential artifacts.
  - Acceptance: original project has a recoverable baseline; remote is the verified `medissl/eleven-again`; no push is needed to complete setup.
  - Verification: inspect local history, remote, status, ignored paths, and staged diff.
  - Dependencies: none. Files: local Git metadata and `.gitignore` (S).
  - Evidence: GitHub search returned the correct repository; Godot tools reported 4.7.2 and zero scripts/scenes. Original-file checkpoint: `a2ea881`. No remote write.

**Gate 0:** Instructions and roadmap agree; Git checkpoint exists; future tasks remain unchecked. Planning does not satisfy gameplay acceptance.

## Phase 1 — watchable football

- [x] **1.1 — First runnable match board.** Boot into a full-pitch scene with two labelled fictional XIs and a clear ball; establish the initial native theme from real references.
  - Acceptance: main scene runs, all 22 players and pitch bounds fit both target resolutions, and ball/team/name cues are legible with keyboard-accessible exit/pause controls.
  - Verification: Godot import/run; inspect reference notes and actual 720p/1080p captures; interact with controls. No match behavior claimed yet.
  - Dependencies: Gate 0. Likely files: `project.godot`, `match/match_view.tscn`, `match/match_view.gd`, `ui/game_theme.tres`, `DESIGN.md` (M).
- [x] **1.2 — Authoritative simulation step.** Drive formation movement and an exclusive ball state from a seeded fixed-step model; add the smallest native regression runner.
  - Acceptance: controlled/in-flight/loose/dead transitions have one owner at most; repeated inputs/seed yield equal supported-build state; the renderer only reads the simulation.
  - Verification: native runner checks ownership, fixed-step repeatability, and finite/in-bounds state; import/parse and visible movement smoke.
  - Dependencies: 1.1. Likely files: `match/match_sim.gd`, `match/match_state.gd`, `match/match_view.gd`, `tests/run_tests.gd`, `tests/test_match.gd` (M).
- [x] **1.3 — Pass, carry, recover.** Add ball travel, support/defensive roles, reachable tackles and interceptions with bounded action frequency.
  - Acceptance: players pass through actual lanes, possession changes through field events, and nearest-presser/support limits keep the rest of the team in readable shape.
  - Verification: seeded lane-block/recovery/cooldown scenarios; watch several seeds for swarm, teleport, aimless passing, and action-spam defects.
  - Dependencies: 1.2. Likely files: `match/match_sim.gd`, `match/decisions.gd`, `match/ball_rules.gd`, `tests/test_match.gd` (M).

**Checkpoint 1A — passed:** Real board captures reviewed at both sizes; ownership/bounds/repeatability and actual-lane interception scenarios pass. Only the nearest defender presses while other players retain anchors. Checkpoints: `27f0e1f`, `fe01ded`, `8609772`.

- [x] **1.4 — Chances and keeper outcomes.** Add shots, physical blocks, keeper saves/holds/parries, playable rebounds, and goal-line events.
  - Acceptance: every score comes from a goal event; blocks precede keeper resolution; parries create a loose ball; attributes and chance context both influence execution.
  - Verification: authored goal/block/hold/parry scenarios plus good/bad chance comparisons; observe seeded chances and inspect ball/score agreement.
  - Dependencies: 1.3. Likely files: `match/match_sim.gd`, `match/ball_rules.gd`, `match/keeper_rules.gd`, `tests/test_match.gd` (M).
- [x] **1.5 — Complete a timed exhibition.** Add the user-confirmed two 90-active-second halves, automated halftime, goals/kickoff resets, simple dead-ball recovery, and result/restart.
  - Acceptance: displayed 0–90 minutes maps correctly to 180 active seconds; stoppages freeze active time; a finished match can restart cleanly; exhibition ties and simplified rules are explained in the menu/details.
  - Verification: clock/halftime/goal/restart regression checks; complete ordinary and tied exhibition runs without stale players or duplicate scores.
  - Dependencies: 1.4. Likely files: `match/match_sim.gd`, `match/match_state.gd`, `match/match_view.gd`, `ui/exhibition_result.tscn`, `tests/test_match.gd` (M).
- [x] **1.6 — Trustworthy match HUD and viewing controls.** Show score, clock, event feed, basic statistics, pause and 1×/2× playback from the simulation.
  - Acceptance: feed/stats/score agree, events identify actors/time, pause consumes no ticks, and viewing/render/cosmetic differences leave the committed match result unchanged.
  - Verification: same-seed normal/2×/headless event-log comparison and pause scenario; visible control, feed-volume, name-overlap, and both-resolution review.
  - Dependencies: 1.5. Likely files: `match/match_view.tscn`, `match/match_view.gd`, `ui/match_hud.gd`, `tests/test_match.gd`, `DESIGN.md` (M).

- [x] **1.7 — On-field goal celebration.** Present the actual goal/scorer/minute/score over the dead-ball field, with a capped cosmetic confetti burst and session effects/reduced-motion controls.
  - Acceptance: no extra restart delay, duplicate goal, hidden live play or gameplay RNG consumption; pause freezes the cue, restart clears it, and static feedback remains with reduced motion.
  - Verification: native event/lifecycle/cosmetic checks; actual goal/reduced-motion captures at both sizes; native preference-control input.
  - Dependencies: 1.6. Files: `match/match_view.gd`, `ui/match_hud.gd`, `tests/run_tests.gd`, `tests/capture_match.gd` (M).
  - Evidence: combined native runner passed 111,209 assertions, zero failures; 1×/2×/headless equality and both-size rendered/input checks pass. Commands and captures in report continuation.
- [x] **1.8 — Deliberate half/full-time reports.** Replace the original automatic half in 1.5 with a frozen first-half snapshot and Continue; retain a final summary until Continue opens exhibition choices.
  - Acceptance: no ticks/RNG/cooldowns advance while waiting, including a 2× boundary; duplicate Continue is harmless; score, controlled-ball possession, shots/target/saves/passes and significant events use captured values. Menus/Escape cannot bypass the half.
  - Verification: native frozen-state/snapshot/duplicate-input/speed checks; report renders and dispatched Tab/Escape/mouse/Enter at both sizes. Update existing headless consumers to acknowledge halftime explicitly.
  - Dependencies: 1.7. Files: `match/match_sim.gd`, `match/match_view.gd`, `ui/match_hud.gd`, `tests/run_tests.gd`, `tests/capture_match.gd`; one-line acknowledgement in `tests/watchability.gd`.
  - Evidence: see report continuation. Real reports, zero-control denominator/empty moments and captured scoring events are distinguished; first-half arrays do not alias full-match totals.

**Gate 1 — technical/report visual/input checks passed; human watchability open:** Historical tasks 1.1–1.6 remain recorded above; 1.7–1.8 implement the revised presentation without claiming complete football rules. Reports/goals/menu were rendered at both sizes and native Godot viewport input verified. Longer name/ball-motion observation and final performance are still unmeasured. See [Phase 1 report](../reports/phase-one.md). Automated checks cannot establish enjoyment; obtain watchability feedback before Phase 2.

### Approved presentation refresh and subsequent motion pass

- [x] **1.9 — Shared broadcast theme and live HUD.** Package licensed Barlow Condensed/Inter locally; unify font, palette, score/clock, controls and real event rows against `outputs/ui-refresh-reference-v3/`.
  - Acceptance: true field aspect, ivory selected controls, clear focus, truthful events and readable long-name fallbacks; no football-model changes.
  - Verification: import/parse, both-size live renders, glyph/contrast and input checks.
  - Dependencies: 1.8. Likely files: theme/fonts, `ui/match_hud.gd`, `match/match_view.gd` (M plus vendored assets).
- [x] **1.10 — Coherent fullscreen menus and reports.** Use the approved halftime hierarchy for half/final reports, pause, details, log, settings and confirmations; expose only supported actions.
  - Acceptance: snapshot statistics/scorers, possession tooltip, clear primary action, correct nested Back/Escape/focus, supported accessibility settings and 720p/enlarged fit.
  - Verification: real renders and native input at both sizes; frozen-state and continuation regressions.
  - Dependencies: 1.9. Likely files: `ui/match_overlay.gd`, `ui/match_hud.gd`, `match/match_view.gd`, existing tests (M).
- [x] **1.11 — Broadcast goal and presentation transitions.** Replace the bordered goal dialog with condensed italic type, a team-colour diagonal sweep and capped confetti; short calm menu/summary entrances.
  - Acceptance: stable event identity; pause/speed/restart cannot duplicate or extend outcomes; reduced motion retains static information; no lingering effects.
  - Verification: actual entrance/hold/exit motion artifacts, still captures, native lifecycle/equivalence checks.
  - Dependencies: 1.10. Likely files: `ui/goal_celebration.gd`, overlay/HUD, capture checks (M).
- [x] **1.12 — Subsequent football transition polish.** Smooth visible possession/recovery, pass/save/rebound, restart/kickoff and period transitions, after the coherent UI refresh.
  - Acceptance: renderer-only easing, fixed camera, stable names and readable ball; genuine fast actions stay fast; authoritative ownership/timing/RNG unchanged under pause, speed, rapid input and restart.
  - Verification: watch real motion for the affected sequences, inspect transition artifacts, run native determinism/pause and presentation reset checks.
  - Dependencies: 1.11. Likely files: `match/match_view.gd`, presentation modules and focused checks (M).

UI acceptance: user tested and accepted the current UI on 28 October 2026; stop UI work and save locally. Combined native checks: 111,224 assertions, zero failures. See `../reports/ui-refresh.md` for capture/input evidence and limits. Further UI defects are deferred to polish.

### Football follow-ups requested during the presentation pass

- [x] **1.13 — Proper kickoff and opening touch.** Replace starting with an already-controlled striker dribble with a stationary centre-mark ball, legal setup and an actual opening kick/pass, including after goals and halftime.
  - Acceptance: correct restarting team, other players in their own halves, opponents outside 9.15 m until the kick; ball physically moves and the kicker cannot touch twice before another player. A backward opening pass is an ordinary available pattern, not a mandatory law. Source: [IFAB Law 8](https://www.theifab.com/laws/latest/the-start-and-restart-of-play/).
  - Verification: initial/goal/second-half kickoff scenarios, legal placements and physical first reception at both speeds; seeded outcome equivalence after rule changes.
  - Dependencies: 1.12. Likely files: match model/restarts, existing native rule checks (M).
  - Evidence (28 October): dedicated stationary kickoff state, legal shape, 12-tick opening countdown, real short backward pass using ordinary passing/reception, second-touch eligibility and eligible ball pursuit. First/goal/second-half scenarios and full-view 1×/2× equivalence pass; native runner: 111,192 assertions, zero failures. Import clean. Native 720p/1080p frame sequences reviewed; see `../reports/kickoffs.md`. One authored opening pattern; illegal second touches are prevented, rather than awarding indirect free kicks. Next: 1.14.
- [x] **1.14 — Genuine boundary restarts.** Classify the earliest whole-ball boundary crossing using actual last touch; distinguish throw, corner, goal kick and goal, including defensive blocks/keeper deflections.
  - Acceptance: no periodic awards or double award near a corner; keeper holds remain controlled, parries create one live ball, and awarded restarts have a bounded legal setup and real delivery. Declare any missing height rules.
  - Verification: authored last-touch/crossing/near-corner/deflection cases, ordinary fixture event rates and visible ball/feed agreement.
  - Dependencies: 1.13. Likely files: match model, ball rules/restarts, focused rule checks (M).
  - Evidence (28 October match batch): Whole-ball earliest crossing and actual last touch; physical throws/corners/goal kicks, curved/lofted travel and contact-conditioned rebounds. Native crossing/delivery tests and authored corner renders at both sizes pass. See gameplay report for height/post-physics limits.
- [x] **1.15 — Genuine fouls and basic free kicks.** Add fouls from real late/illegal challenge context and bounded free-kick setup/delivery; keep clean and failed challenges distinct.
  - Acceptance: no random stoppage lottery, no animation-awarded offences, correct location/team/taker and one restart per incident. Full discipline/penalty edge cases remain 5.1–5.3.
  - Verification: clean/failed/foul challenge scenarios and natural fixture observation; no repeated award or restart soft lock.
  - Dependencies: 1.14. Likely files: challenge/restart rules and focused native checks (M).
  - Evidence (28 October match batch): Reachable challenge context awards one actual foul/restart; physical direct/indirect free kicks and penalties share the match model. No periodic offence lottery. Native foul/card/expiry and full-match checks pass.

Follow-up priorities after restart/foul slices: complete attribute execution in **2.1**, coordinated/contextual football AI in **2.6**, selectable tactics in **2.3**, and real automatic card traits in **6.1**. These match-side systems are now implemented and checked in the requested larger batch; see the evidence below. Later run/economy/persistence/content work remains unchecked. The user explicitly selected match systems first.

## Phase 2 — meaningful preparation

- [x] **2.1 — Data-backed cards and role ratings.** Replace prototype constants with validated card Resources and the GDD's role weights, familiarity penalties, and goalkeeper fields.
  - Acceptance: full PAC/SHO/PAS/DRI/DEF/PHY and REF/HAN/POS/DIV/KIC values, 1–120 bounds, stable IDs, role weights/OVR and emergency keeping are correct. Relevant attributes visibly affect their actual execution domain through one effective-value path; OVR adds no hidden multiplier. Split data and execution domains into focused increments before coding.
  - Verification: rating/identity/role cases plus paired 60-versus-100 scenarios for movement, finishing, passing/first touch, defending/strength/endurance and keeper domains; fictional exhibition and playback equality remain intact.
  - Dependencies: Gate 1. Likely files: `content/player_card.gd`, `content/prototype_roster.tres`, `squad/squad_rules.gd`, `match/match_sim.gd`, `tests/test_squad.gd` (M).
  - Evidence (28 October match batch): Immutable fictional Resources, validated integral 1–120 fields, exact role OVR/familiarity and one capped effective-stat path. Paired native domain checks over 96 seeds plus baseline finishing checks pass; no established balance claim.
- [x] **2.2 — Build and commit a legal XI.** Add preparation with comparison, bench, and 4-3-3/4-4-2/4-2-3-1 assignments.
  - Acceptance: eleven distinct owned available players and one assigned GK are required; penalties, captain, takers, and penalty order are editable/previewed; kickoff locks submitted decisions against live edits.
  - Verification: duplicate/missing/GK/familiarity cases; arrange each formation by mouse and keyboard and play its committed XI.
  - Dependencies: 2.1. Likely files: `content/formations.tres`, `squad/squad_rules.gd`, `ui/preparation.tscn`, `ui/preparation.gd`, `tests/test_squad.gd` (M).
  - Evidence (28 October match batch): Native legal XI/bench preparation, all three formations, captain/takers and penalty order; private submitted plans. Both-size enlarged preparation renders and native Enter submission pass; formation/identity/role validation is covered by native checks.
- [x] **2.3 — Tactical identity on the pitch.** Connect three attacking and three defensive approaches to positioning and action preferences.
  - Acceptance: all nine combinations are selectable and previewed; controlled possession/direct/counter and press/block examples visibly differ without a hidden matchup bonus.
  - Verification: seeded context scenarios and event/position comparisons; inspect representative matches and unchanged playback equivalence.
  - Dependencies: 2.2 and 2.6. Likely files: `content/tactics.tres`, `match/decisions.gd`, `ui/preparation.gd`, `tests/test_tactics.gd` (M).
  - Evidence (28 October match batch): Nine selectable attack/defence combinations plus route, width and late-risk choices affect actual geometry/action utility/work, without a matchup multiplier. Geometry/action and presented/headless equivalence checks pass; tactical balance needs human playtests.

**Checkpoint 2A:** Role-adjusted selection is legal and tactics affect observed play; baseline match invariants still pass.

- [x] **2.4 — Match-only stamina.** Deplete/recover effective movement/execution from PHY, activity, and pressing, with capped fatigue penalties.
  - Timing: normalize base drain to regulation progress under the confirmed three-minute duration; do not triple the old per-fixture fatigue budget. Derive automatic substitution thresholds from displayed minutes in task 2.5.
  - Acceptance: all fixtures start at 100, zero stamina reduces affected attributes by at most 12%, bonuses/fatigue are applied once, and UI explains tired players.
  - Verification: boundary and tactic-depletion scenarios plus fresh-fixture reset; record observed calibration separately from GDD targets.
  - Dependencies: 2.3. Likely files: `match/match_state.gd`, `match/match_sim.gd`, `ui/match_hud.gd`, `tests/test_tactics.gd` (M).
  - Evidence (28 October match batch): PHY/activity/pressing-dependent work normalized to 180-second regulation, fresh fixture/substitute stamina and a 12% maximum penalty. Native boundaries/depletion comparisons and live inspection pass.
- [x] **2.5 — Preplanned automatic substitutions.** Implement three templates, pinned replacements, bench order, and optional 70-minute risk instructions.
  - Acceptance: max five substitutions/three windows excluding halftime; eligible players enter at full stamina, no re-entry, and harmful or impossible swaps are skipped with an explanation.
  - Verification: template thresholds, used/unavailable bench, window cap, and trailing/leading cases; inspect pre-match preview and actual substitution events.
  - Dependencies: 2.4. Likely files: `match/substitutions.gd`, `match/match_sim.gd`, `ui/preparation.gd`, `ui/match_hud.gd`, `tests/test_substitutions.gd` (M).
  - Evidence (28 October match batch): Three automatic templates, real bench priority, pins and late-risk instructions; five changes/three windows, no re-entry, fit/harm safeguards and fresh entrants. Native window, priority, eligibility and snapshot checks pass; prep explains skipped unsuitable/unavailable reserves.

- [x] **2.6 — Coordinated, context-aware football AI.** Build on the prototype with support triangles, elected pressure with cover, useful runs/recycling and comparable legal pass/carry/shoot choices informed by real player strengths. These foundations run before 2.3's tactic presets.
  - Acceptance: ordinary untraited football produces observable coordinated patterns; no swarm, scripted score, guaranteed combination or tactic matchup multiplier. Commit intentions long enough to avoid oscillation. Split patterns/action choices into focused increments before coding.
  - Verification: authored support/cover/chance-choice cases and paired seeded geometry/action comparisons, then observed match motion at both speeds; keep authoritative equality.
  - Dependencies: 2.1 and 2.2. Likely files: match decisions/team intents, player execution, native AI checks (M per increment).
  - Evidence (28 October match batch): Finite steering/turning, support triangles, pressure/cover, interrupted one-two/third-player runs, comparable legal action utilities and physical first touches. Authored coordination tests, fixture regressions and 1×/2× native frame-sequence review pass; human watchability remains open.

**Gate 2 — technical checks and rendered preparation passed; human tactical/watchability review open:** legal plans, effective stats, coordinated behavior and substitution limits have native regression coverage. Both-size enlarged preparation and 1×/2× frame sequences were reviewed; the Phase 1 suite still passes. These do not establish enjoyment or tactical balance.

## Phase 3 — four-win run

- [x] **3.1 — Resolve tied matches.** Derive ET from the shared regulation duration: one-third total, split into two halves (30 active seconds each under 180-second regulation); add shootouts with early termination and paired sudden death.
  - Acceptance: ET starts only on a regulation tie; shootout follows only an ET tie; on-field eligible takers/fatigue apply and shootout goals remain separate from match goals/statistics.
  - Verification: regulation winner, ET winner, early clinch, and sudden-death fixtures; visible phase/score labels and timing checks.
  - Dependencies: Gate 2. Likely files: `match/match_sim.gd`, `match/shootout.gd`, `ui/match_hud.gd`, `tests/test_match_rules.gd` (M).
  - Evidence (28 October match batch): Optional knockout preparation profile: two 30-active-second ET halves, physical penalties, early clinch and paired sudden death. Separate score/stat tallies, exact in-flight resume, winner/phase tests and native result/Continue checks at both sizes pass.
- [ ] **3.2 — Country setup and stage progression.** Start one country with 16 fictional starters/$8m and progress through four victories or three defeats using explicit result/reward states.
  - Acceptance: losses retain roster/cash and retry the saved opponent with a new attempt seed; result/prize application is idempotent; final win/loss ends exactly once.
  - Verification: forced win/loss sequences, repeated result delivery, max-fixture bound, and restart from summary; inspect setup/run overview.
  - Dependencies: 3.1. Likely files: `run/run_state.gd`, `run/run_controller.gd`, `content/short_run.tres`, `ui/run_overview.tscn`, `tests/test_run.gd` (M).
- [ ] **3.3 — Recruit one of five.** Add opening and wins-1/2/3 offers, identity exclusions, role coverage, and atomic squad replacement.
  - Acceptance: five distinct eligible people, opening 75–79, one choice/decline, 18-player cap, owned/released exclusions, and cancelled replacement leaves the squad untouched.
  - Verification: seeded offers, exhausted category/band fallback, duplicate versions, full-squad cancel/confirm; keyboard comparison/selection flow.
  - Dependencies: 3.2. Likely files: `run/recruitment.gd`, `squad/squad_rules.gd`, `ui/recruitment.tscn`, `ui/recruitment.gd`, `tests/test_recruitment.gd` (M).

**Checkpoint 3A:** A short run advances with actual resolved matches and non-repeatable rewards; recruitment never violates identity/squad rules.

- [ ] **3.4 — Market I with real spending consequences.** Add eight curated offers after win 3, price interpolation, affordability safeguards, and a two-purchase limit.
  - Acceptance: recruit precedes market, insufficient funds/third purchase are rejected, release/payment/acquisition commit together, and previews/cancels cannot spend or release anything.
  - Verification: exact funds, negative balance prevention, monotonic prices, full-squad purchase rollback, and no refresh after reopening; inspect next-opponent/funds preview.
  - Dependencies: 3.3. Likely files: `run/market.gd`, `run/run_controller.gd`, `ui/market.tscn`, `ui/market.gd`, `tests/test_market.gd` (M).
- [ ] **3.5 — Scout and understand the short-run final.** Author stage opponents with visible style, frozen rosters, and factual result feedback.
  - Acceptance: opponent previews show formation/strength/threat before preparation and market; defeat preserves that opponent; result observations agree with logged shots, passes, and turnovers.
  - Verification: fixed-roster retry plus known-event statistic totals; play different tactical responses and inspect result/scouting layout.
  - Dependencies: 3.4. Likely files: `content/short_opponents.tres`, `run/opponents.gd`, `ui/scouting.tscn`, `ui/result.gd`, `tests/test_run.gd` (M).
- [ ] **3.6 — Short-run completion flow.** Connect new run, reward ordering, win/loss summary, and fresh-start cleanup.
  - Acceptance: country → opening offer → prep → match → scheduled rewards → summary works for four wins or three defeats; no useless final rewards, leftover roster, or administrative dead end.
  - Verification: complete a normal run plus forced terminal/reward-cancel cases; review mouse/keyboard flows. Label saves/index and remaining rules as pending until later phases.
  - Dependencies: 3.5. Likely files: `ui/main_menu.tscn`, `ui/run_summary.tscn`, `run/run_controller.gd`, `tests/test_run.gd` (M).

**Gate 3:** Session-playable short run works end to end. Review economy and choices; do not claim persistence or complete football rules yet. Coaching is explicitly omitted from this terminal four-win slice.

## Phase 4 — reliable continuation

- [ ] **4.1 — Versioned saves at decision boundaries.** Add separate active-run/profile envelopes, validated serialization, atomic writes, one backup, and menu continuation.
  - Acceptance: generated offers/markets/opponents and unresolved reward steps restore exactly; purchase/result replay cannot double-commit; corrupt/incompatible state is preserved and recovery is explained.
  - Verification: disposable-directory interrupted-write/backup/schema tests and reopen at each run decision; test alongside existing user saves without touching them.
  - Dependencies: Gate 3. Likely files: `persistence/save_store.gd`, `persistence/state_codec.gd`, `run/run_controller.gd`, `ui/main_menu.gd`, `tests/test_save.gd` (M).
- [ ] **4.2 — Exact mid-match continuation.** Persist committed inputs and complete match/RNG state, including pending events and cooldowns.
  - Acceptance: quitting/resuming the committed attempt preserves future events/result on the supported build; it cannot reroll opponent/seed or repeat a reward; incompatible build handling is explicit.
  - Verification: uninterrupted versus resumed state/event comparison during possession, ball flight, dead ball, subs, ET, and shootout; test safe recovery after forced interruption.
  - Dependencies: 4.1. Likely files: `match/match_state.gd`, `match/match_sim.gd`, `persistence/state_codec.gd`, `run/run_controller.gd`, `tests/test_save.gd` (M).
- [ ] **4.3 — Persistent index and valid records.** Record acquired card versions, anonymous silhouettes, run history, and exact peak legal XI.
  - Acceptance: opponents/unchosen candidates never discover cards; index has no power effect; records exclude bench/buffs/emergency players and use GDD ordering with content/balance version labels.
  - Verification: discovered/hidden tooltip cases, duplicate discovery/reward calls, valid-XI rating/ranking checks, and run cleanup preserving profile; inspect index/records navigation.
  - Dependencies: 4.2. Likely files: `persistence/profile.gd`, `ui/player_index.tscn`, `ui/records.tscn`, `run/run_controller.gd`, `tests/test_profile.gd` (M).

**Checkpoint 4A:** Short run now resumes safely and keeps profile discoveries/records separate. Regress reward and purchase interruption paths before expanding UI settings.

- [ ] **4.4 — Persistent settings and safe abandonment.** Add UI scale, remapping, reduced motion, sound levels, display settings, and deliberate abandon/new-run confirmation.
  - Acceptance: settings survive restart independently of a run; abandoning clears only active progress; cancelling new-run confirmation preserves it; important feed/input remain accessible.
  - Verification: change/reopen settings, remap controls, cancel/confirm abandonment, and inspect both resolutions with enlarged UI/reduced motion; verify hidden match state does not advance while paused.
  - Dependencies: 4.3. Likely files: `persistence/settings.gd`, `ui/settings.tscn`, `ui/settings.gd`, `ui/main_menu.gd`, `tests/test_save.gd` (M).

**Gate 4:** First complete resumable short-run slice, including basic index/records. Exercise every save boundary and record actual recovery evidence; manual file inspection alone is insufficient.

## Phase 5 — complete football and twelve-win run

- [x] **5.1 — Football restarts and set pieces.** Replace prototype dead-ball handling with throw-ins, corners, goal kicks, free kicks, penalties, aerial outcomes, and preassigned takers.
  - Acceptance: correct team/location/ball state resumes after each restart; keeper handling bounds apply; set pieces use physical ball travel and ordinary attributes rather than an unrelated scoring roll.
  - Verification: authored each-boundary/restart/header/keeper-outside-box scenarios; save/resume while arranging a restart; inspect positioning and taker defaults.
  - Dependencies: Gate 4. Likely files: `match/restarts.gd`, `match/ball_rules.gd`, `ui/preparation.gd`, `persistence/state_codec.gd`, `tests/test_match_rules.gd` (M).
  - Evidence (28 October match batch): Match side pulled forward by the requested batch: real routines/takers/headers/keepers and restart restrictions. Native corner/penalty/action snapshots round-trip and preserve future state; authored corner renders reviewed. Disk persistence remains 4.1–4.2.
- [x] **5.2 — Basic offside.** Evaluate pass-time positions and active involvement, resetting through the shared restart rules.
  - Acceptance: qualifying active attackers are penalized consistently; legal, passive, own-half, and exempt-restart cases are distinguished; pending offside context survives resume.
  - Verification: authored positional/second-last-defender/pass-time cases, restart exemptions, and interception/involvement/resume cases; inspect event/location agreement.
  - Dependencies: 5.1. Likely files: `match/offside.gd`, `match/ball_rules.gd`, `match/restarts.gd`, `persistence/state_codec.gd`, `tests/test_match_rules.gd` (M).
  - Evidence (28 October match batch): Pass-time circle-centre offside, active ball involvement, level/own-half/direct-restart exemptions and deliberate-control reset. Pending offside snapshot/future equality passes. Full interference-with-opponent/body-edge detail is explicitly outside this basic implementation.
- [x] **5.3 — Fouls, cards, and reduced teams.** Tie foul risk to reachable challenges; handle yellows, second yellows, direct reds, GK dismissals and forfeits.
  - Acceptance: correct player leaves, keeper/shape is preserved through legal substitutions/emergency assignment, no replacement re-entry, and below seven triggers one resolved forfeit.
  - Verification: seeded challenge/contact cases, GK red with/without subs, second-yellow nonstacking, and forfeit idempotency; resume during disciplinary stoppage.
  - Dependencies: 5.2. Likely files: `match/discipline.gd`, `match/substitutions.gd`, `match/match_sim.gd`, `persistence/state_codec.gd`, `tests/test_discipline.gd` (M).
  - Evidence (28 October match batch): Contextual fouls/yellow/second-yellow/direct red, legal trained/emergency GK cover, defensive reshaping and idempotent fewer-than-seven forfeit. Dismissed players are excluded from pressure/contacts/restart selection. Disciplinary/keeper snapshot and subsequent-state checks pass; run suspensions remain 5.4.

**Checkpoint 5A — match side implemented early:** basic rule scenarios and in-memory match snapshot equivalence pass. Atomic disk/run saves are still pending; this does not complete Gate 4 or the full Phase 5 run. Watch for stoppage inflation, repeated fouls and shape collapse in human playtests.

- [ ] **5.4 — Suspension and emergency coverage.** Apply three-yellow/red one-fixture suspensions and anonymous one-fixture academy cover.
  - Acceptance: only the next completed attempt serves a suspension/clears tally, second-yellow red does not stack, emergency players cannot persist/discover/set peak-XI records, and kickoff cannot soft-lock.
  - Verification: repeated prep, loss/win service, multiple missing roles, emergency GK, and interrupted fixture completion; preview unavailable players clearly.
  - Dependencies: 5.3. Likely files: `squad/squad_rules.gd`, `run/run_controller.gd`, `persistence/profile.gd`, `ui/preparation.gd`, `tests/test_discipline.gd` (M).
- [ ] **5.5 — Full reward schedule and coaching.** Add the twelve-stage configuration, three markets, nine victory offers, and two principles chosen from three options out of six.
  - Acceptance: $92m total potential income including start/final prize; correct reward order and chapter odds; no duplicate principles, shared +6 bonus cap, no post-final recruit/market/coaching screen.
  - Verification: static schedule/weight checks and forced complete win/loss paths; resume at every reward step; compare full configuration against short-slice boundaries.
  - Dependencies: 5.4. Likely files: `content/full_run.tres`, `content/coaching.tres`, `run/run_controller.gd`, `ui/coaching.tscn`, `tests/test_run.gd` (M).
- [ ] **5.6 — Full opposition and result evidence.** Author at least two stage styles and two chapter-final identities per GDD coverage, with chapter-start boss reveal.
  - Acceptance: difficulty follows stage budgets, never current player power; saved opponent identities persist on retries; shot locations/turnover zones support factual result observations.
  - Verification: content coverage/budget checks, lucky-recruit nonadaptation scenario, full-run normal and edge paths, and seeded result-stat consistency.
  - Dependencies: 5.5. Likely files: `content/opponents.tres`, `run/opponents.gd`, `ui/scouting.gd`, `ui/result.gd`, `tests/test_run.gd` (M).

**Gate 5:** Full candidate rules/schedule and interruption scenarios pass. All core matches remain visible and readable; balance claims remain provisional.

## Phase 6 — identity and content

28 October card batch: user explicitly requested completing cards before run work. Tasks **6.3a/6.4a** below complete native content, rendering, archive/comparison and preparation inspection. Campaign prices/pools, recruitment transactions and persistent discovery remain in their original tasks. See [card evidence](../reports/player-cards.md).

Card/album reference saved by the user: read `../CARD_DESIGN_HANDOFF.md` and the linked project references before tasks 6.3–6.4. Apply its archive-card direction to earlier recruitment/squad UI tasks when they begin, with gameplay rules still governed by the GDD.

- [x] **6.1 — Real automatic signature traits.** Implement the single trait printed on a card as a bounded enhancement of an actual legal action, with above-player identity and honest activation/success/partial/failure feedback. Ordinary football works without traits. Catalogue counts and balance remain provisional.
  - Acceptance: maximum one trait per card; conditional +3/+4 effects and +6 cap precede role/fatigue penalties; timers and applicability survive save/resume without double counting.
  - Verification: boundary/stack/timer cases for every trait and principle, substitute timing, and equivalent visible/headless runs.
  - Dependencies: Gate 5. Likely files: `content/traits.tres`, `match/effective_attributes.gd`, `match/match_sim.gd`, `persistence/state_codec.gd`, `tests/test_traits.gd` (M).
  - Evidence (28 October match batch): All 36 researched automatic trait contracts are implemented on actual actions, with bounded uses/cooldowns/costs, shared +6 cap, role applicability, real curves/speeds/windup and aura/action feedback. All positive/negative eligibility/use contracts pass; two fictional squad options expose all traits. Coaching choices remain 5.5; standalone match snapshots work, disk save integration remains 4.2.
- [ ] **6.2 — Six country-origin squads.** Author sixteen fictional starters per country with comparable strength, viable formations, origin/kit identity, and equal starting access.
  - Acceptance: all six pass legal-role/attribute/starting-XI checks and remain selectable from the first run; nationality adds no hidden bonus or signing restriction.
  - Verification: validate and launch every origin in all formations; compare actual initial strength bands and distinguish team patterns. Split authored data batches as needed.
  - Dependencies: 6.1. Likely files: `content/countries.tres`, `content/starters.tres`, `ui/country_select.tscn`, `tests/test_content.gd` (M).
- [x] **6.3a — Native 200-card catalogue and portraits.** Promote the prepared JSON/metadata/reference notes and 200 baked PNGs into runtime folders; validate native Resources and exact source coverage.
  - Acceptance: 200 unique people/cards, 20 per role and 10 Modern/10 Retired per role; native derived OVR/tier and all eleven stats, one compatible trait, stable portrait bindings and edition metadata. Additional authored versions share person identity while keeping distinct card IDs.
  - Verification: `tests/catalogue_checks.gd` passes all 200 native card/texture checks, accent-insensitive queries, role/pool coverage, metadata isolation, multi-version exclusions and atomic duplicate-card rejection. No runtime Python/network/compositor or extra power multiplier. Dependencies: existing 2.1/6.1 and explicit user card request.

- [ ] **6.3 — Authored player catalogue integration.** Integrate the prepared 200-person Modern/Retired catalogue with explicit edition metadata and stage eligibility, retaining sufficient role/band coverage from fictional content.
  - Acceptance: person/version uniqueness, bounds, prices, source/confidence notes, and extreme owned/released exclusions validate; last-resort fallback is exposed as a content defect, not routine generation.
  - Verification: constrained pool/offer/market generation across every chapter and exclusion scenario; manually audit a representative identity/rating sample. Split catalogue entry into small batches.
  - Dependencies: 6.2. Likely files: `content/historical_cards.tres`, `content/sources.md`, `content/validate_content.gd`, `tests/test_content.gd` (M).
  - Prepared handoff (28 October): read `../outputs/player-catalogue-200-v1/IMPLEMENTATION.md` and `VALIDATION.md`. The package contains 200 unique people/cards and transparent 96×96 portraits: 20 per primary role, split 10 Modern/10 Retired. Its `cards` fit native `PlayerCard.from_data()`; preserve country/edition/pool/portrait/reference metadata separately by `card_id`. Package-native/workbook checks are documented there; runtime catalogue integration is complete in 6.3a; campaign/recruitment integration remains pending.
  - Content limits: provisional original ratings, 179 Legend/21 Gold (94–119), 34 of the current 36 traits used, no authored prices/odds. Preserve early fictional Bronze/Silver content and explicit stage pools. Modern denotes career pool, not live 2026 form; portrait likeness and mixed identity-reference coverage require review. Workbook edits require source transfer/re-export/revalidation. Recovery branch `codex/player-catalogue-200` at `3a331575` has older game ancestry; use current package files without switching/resetting the shared gameplay checkout.

**Checkpoint 6A:** All content effects and pools validate; data quantities never substitute for coverage or credible authoring. Core loop remains functional without external portraits.

- [x] **6.4a — Reusable native archive cards and inspection.** Implement one 5:7 four-tier template, pixel portraits, keeper/outfield layouts, hidden/missing/owned/selected/disabled states, catalogue filters/pages, complete player files and pinned comparisons; connect preparation Card/archive entry.
  - Acceptance: native text, three-digit values, accents/long names, honest base stats/traits and source notes; hidden identities masked, keyboard/mouse/focus/Back work, reduced-motion/rapid-close supported, match/plans/RNG untouched.
  - Verification: `tests/card_ui_checks.gd` passes 200 bindings, native input, empty/last pages, comparisons, same-frame rapid Escape, preparation entry and paused update attempts. Native GL captures reviewed at 720p/1080p, normal/125% UI, including all four tiers, 120, long names, keeper and identity states. Full existing runner: 109,763 assertions, zero failures. Dependencies: 6.3a; evidence/limits in `reports/player-cards.md`.

- [ ] **6.4 — Album and recruitment presentation.** Refine card comparison, discovered-version grouping, neutral hidden slots, portraits/fallbacks, and skippable reveals.
  - Prepared assets: `../outputs/card-system-v2/IMPLEMENTATION_GUIDE.md` governs the native 5:7 archive card and four tiers; use native Barlow/Inter text plus approved baked portraits with nearest filtering and square aspect. Catalogue metadata supplies intended `res://assets/portraits/catalogue_200/` targets. Preserve hidden/missing-art states. Runtime needs no Python compositor or network service. The old six-trait display registry is superseded by the live match registry.
  - Acceptance: selection consequences remain clear at 720p and enlarged UI; hidden names never leak; image-free operation is complete and imported assets have source notes.
  - Verification: actual first-visit/empty/partial/full index, missing portrait, full-squad signing, reduced motion, and keyboard flows; capture both sizes and update design decisions.
  - Dependencies: 6.3. Likely files: `ui/player_index.tscn`, `ui/recruitment.tscn`, `ui/player_card.gd`, `ui/game_theme.tres`, `DESIGN.md` (M).
- [ ] **6.5 — Consistent game presentation and sound.** Finish match/menu/results hierarchy, important event cues, restrained ambience, and accessible settings across screens.
  - Acceptance: ball/score/feed never disagree or become obscured, controls/focus work across the complete flow, and every important audio cue has visible information with independent sound controls.
  - Verification: complete run using mouse and keyboard, long names, 720p/1080p, UI scale and reduced motion; inspect representative captures and frame-time baseline. Split screen refinements into focused tasks.
  - Dependencies: 6.4. Likely files: affected `ui/` scene pair, `ui/audio.gd`, `ui/game_theme.tres`, `DESIGN.md` (M per refinement).

**Gate 6:** All implemented screens/content and core flows reviewed. Resolve material visual/input defects; record unavailable checks instead of claiming a polish score.

## Phase 7 — calibration and personal Windows build

- [ ] **7.1 — Reproducible match calibration.** Run headless same-team/side-swap, attribute-gap, tactic-grid, and rare-rule experiments using the actual engine.
  - Acceptance: reports include sample counts from GDD §18, seeds, versions, definitions, uncertainty intervals, timing/texture and side bias; outliers are inspectable in the visible game.
  - Verification: native suite plus repeat a report from its saved inputs; compare selected headless/visible fixtures before trusting aggregate measurements.
  - Dependencies: Gate 6. Likely files: `tests/calibrate_matches.gd`, `tests/report_metrics.gd`, `reports/match-calibration.md` (M).
- [ ] **7.2 — Whole-run economy and strategy calibration.** Compare highest-OVR, weakest-position, tactical-fit, spending and saving bots without changing gameplay rules for bots.
  - Acceptance: at least 1,000 runs per strategy report failure points, purchases, coverage/fallbacks, and reward integrity; anomalous strategies are investigated rather than hidden by adaptive opponents.
  - Verification: repeatable run-seed sample and report totals; tune only evidenced issues and rerun affected comparisons. Separate bot success from human targets.
  - Dependencies: 7.1. Likely files: `tests/calibrate_runs.gd`, `tests/strategy_bots.gd`, `reports/run-calibration.md`, affected tuning resource (M).
- [ ] **7.3 — Observed personal playtests and measured fixes.** Review 5–10 user runs where practical, focusing on readable football, meaningful recruitment, understandable defeats and willingness to restart.
  - Acceptance: observations and remaining uncertainties are recorded; major pacing/dominance/frustration/readability issues receive targeted fixes; 1080p performance is measured on the user's PC.
  - Verification: watched runs plus focused regressions after each fix; log actual run durations/feedback and frame-time measurements. If observations are unavailable, leave the human gate open.
  - Dependencies: 7.2. Likely files: `reports/playtests.md` and the smallest affected code/data files (M per fix).

**Checkpoint 7A:** Measured engine/bot results and human observations are separated. No unsupported claim of balanced or enjoyable play; accepted limitations are explicit.

- [ ] **7.4 — Export and verify the personal PC build.** Add Windows export configuration, use matching export templates, and smoke-test the packaged game outside the editor.
  - Acceptance: launch/new-run/continue/match/quit/relaunch work in the exported build, save/profile isolation survives, no missing assets, and supported engine/content version plus known issues are recorded.
  - Verification: clean import/native regression run, export success, packaged 720p/1080p interaction and save-resume smoke; inspect export contents for credentials/development-only artifacts.
  - Dependencies: 7.3 and documented human gate outcome. Likely files: `export_presets.cfg`, `README.md`, `reports/personal-build.md` (M); binaries stay under ignored `builds/` or `exports/`.

**Gate 7:** Verified personal Windows build, reproducible evidence, and known limits. GitHub push/release/public distribution require the user's separate authorization. No extra systems are implied by completion.
