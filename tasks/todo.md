# Eleven Again — development tasks

Task source of truth. Read `plan.md` for phase boundaries, GDD authority, architecture, checks, and prompts. Status on 27 October 2026: Phase 1 implemented and technically verified; **human watchability feedback pending, then 2.1**. See [Phase 1 evidence](../reports/phase-one.md).

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

## Phase 2 — meaningful preparation

- [ ] **2.1 — Data-backed cards and role ratings.** Replace prototype constants with validated card Resources and the GDD's role weights, familiarity penalties, and goalkeeper fields.
  - Acceptance: 1–120 bounds, weights, stable IDs, primary/slot OVR, and emergency keeping are correct; match execution uses attributes without a second OVR multiplier.
  - Verification: table-driven rating/bound/identity validation and same-card different-role scenarios; fictional exhibition still runs.
  - Dependencies: Gate 1. Likely files: `content/player_card.gd`, `content/prototype_roster.tres`, `squad/squad_rules.gd`, `match/match_sim.gd`, `tests/test_squad.gd` (M).
- [ ] **2.2 — Build and commit a legal XI.** Add preparation with comparison, bench, and 4-3-3/4-4-2/4-2-3-1 assignments.
  - Acceptance: eleven distinct owned available players and one assigned GK are required; penalties, captain, takers, and penalty order are editable/previewed; kickoff locks submitted decisions against live edits.
  - Verification: duplicate/missing/GK/familiarity cases; arrange each formation by mouse and keyboard and play its committed XI.
  - Dependencies: 2.1. Likely files: `content/formations.tres`, `squad/squad_rules.gd`, `ui/preparation.tscn`, `ui/preparation.gd`, `tests/test_squad.gd` (M).
- [ ] **2.3 — Tactical identity on the pitch.** Connect three attacking and three defensive approaches to positioning and action preferences.
  - Acceptance: all nine combinations are selectable and previewed; controlled possession/direct/counter and press/block examples visibly differ without a hidden matchup bonus.
  - Verification: seeded context scenarios and event/position comparisons; inspect representative matches and unchanged playback equivalence.
  - Dependencies: 2.2. Likely files: `content/tactics.tres`, `match/decisions.gd`, `ui/preparation.gd`, `tests/test_tactics.gd` (M).

**Checkpoint 2A:** Role-adjusted selection is legal and tactics affect observed play; baseline match invariants still pass.

- [ ] **2.4 — Match-only stamina.** Deplete/recover effective movement/execution from PHY, activity, and pressing, with capped fatigue penalties.
  - Timing: normalize base drain to regulation progress under the confirmed three-minute duration; do not triple the old per-fixture fatigue budget. Derive automatic substitution thresholds from displayed minutes in task 2.5.
  - Acceptance: all fixtures start at 100, zero stamina reduces affected attributes by at most 12%, bonuses/fatigue are applied once, and UI explains tired players.
  - Verification: boundary and tactic-depletion scenarios plus fresh-fixture reset; record observed calibration separately from GDD targets.
  - Dependencies: 2.3. Likely files: `match/match_state.gd`, `match/match_sim.gd`, `ui/match_hud.gd`, `tests/test_tactics.gd` (M).
- [ ] **2.5 — Preplanned automatic substitutions.** Implement three templates, pinned replacements, bench order, and optional 70-minute risk instructions.
  - Acceptance: max five substitutions/three windows excluding halftime; eligible players enter at full stamina, no re-entry, and harmful or impossible swaps are skipped with an explanation.
  - Verification: template thresholds, used/unavailable bench, window cap, and trailing/leading cases; inspect pre-match preview and actual substitution events.
  - Dependencies: 2.4. Likely files: `match/substitutions.gd`, `match/match_sim.gd`, `ui/preparation.gd`, `ui/match_hud.gd`, `tests/test_substitutions.gd` (M).

**Gate 2:** Lineup/tactical/substitution decisions are understandable and reproducible. Review gameplay and preparation at both sizes; retain the Phase 1 regression suite.

## Phase 3 — four-win run

- [ ] **3.1 — Resolve tied matches.** Derive ET from the shared regulation duration: one-third total, split into two halves (30 active seconds each under 180-second regulation); add shootouts with early termination and paired sudden death.
  - Acceptance: ET starts only on a regulation tie; shootout follows only an ET tie; on-field eligible takers/fatigue apply and shootout goals remain separate from match goals/statistics.
  - Verification: regulation winner, ET winner, early clinch, and sudden-death fixtures; visible phase/score labels and timing checks.
  - Dependencies: Gate 2. Likely files: `match/match_sim.gd`, `match/shootout.gd`, `ui/match_hud.gd`, `tests/test_match_rules.gd` (M).
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

- [ ] **5.1 — Football restarts and set pieces.** Replace prototype dead-ball handling with throw-ins, corners, goal kicks, free kicks, penalties, aerial outcomes, and preassigned takers.
  - Acceptance: correct team/location/ball state resumes after each restart; keeper handling bounds apply; set pieces use physical ball travel and ordinary attributes rather than an unrelated scoring roll.
  - Verification: authored each-boundary/restart/header/keeper-outside-box scenarios; save/resume while arranging a restart; inspect positioning and taker defaults.
  - Dependencies: Gate 4. Likely files: `match/restarts.gd`, `match/ball_rules.gd`, `ui/preparation.gd`, `persistence/state_codec.gd`, `tests/test_match_rules.gd` (M).
- [ ] **5.2 — Basic offside.** Evaluate pass-time positions and active involvement, resetting through the shared restart rules.
  - Acceptance: qualifying active attackers are penalized consistently; legal, passive, own-half, and exempt-restart cases are distinguished; pending offside context survives resume.
  - Verification: authored positional/second-last-defender/pass-time cases, restart exemptions, and interception/involvement/resume cases; inspect event/location agreement.
  - Dependencies: 5.1. Likely files: `match/offside.gd`, `match/ball_rules.gd`, `match/restarts.gd`, `persistence/state_codec.gd`, `tests/test_match_rules.gd` (M).
- [ ] **5.3 — Fouls, cards, and reduced teams.** Tie foul risk to reachable challenges; handle yellows, second yellows, direct reds, GK dismissals and forfeits.
  - Acceptance: correct player leaves, keeper/shape is preserved through legal substitutions/emergency assignment, no replacement re-entry, and below seven triggers one resolved forfeit.
  - Verification: seeded challenge/contact cases, GK red with/without subs, second-yellow nonstacking, and forfeit idempotency; resume during disciplinary stoppage.
  - Dependencies: 5.2. Likely files: `match/discipline.gd`, `match/substitutions.gd`, `match/match_sim.gd`, `persistence/state_codec.gd`, `tests/test_discipline.gd` (M).

**Checkpoint 5A:** Complete match-rule scenarios and prior save-equivalence cases pass; watch for stoppage inflation, repeated fouls, and shape collapse.

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

Card/album reference saved by the user: read `../CARD_DESIGN_HANDOFF.md` and the linked project references before tasks 6.3–6.4. Apply its archive-card direction to earlier recruitment/squad UI tasks when they begin, with gameplay rules still governed by the GDD.

- [ ] **6.1 — Signature identities.** Add eight conditional trait types to shared effective attributes, with six coaching principles composed under the same cap.
  - Acceptance: maximum one trait per card; conditional +3/+4 effects and +6 cap precede role/fatigue penalties; timers and applicability survive save/resume without double counting.
  - Verification: boundary/stack/timer cases for every trait and principle, substitute timing, and equivalent visible/headless runs.
  - Dependencies: Gate 5. Likely files: `content/traits.tres`, `match/effective_attributes.gd`, `match/match_sim.gd`, `persistence/state_codec.gd`, `tests/test_traits.gd` (M).
- [ ] **6.2 — Six country-origin squads.** Author sixteen fictional starters per country with comparable strength, viable formations, origin/kit identity, and equal starting access.
  - Acceptance: all six pass legal-role/attribute/starting-XI checks and remain selectable from the first run; nationality adds no hidden bonus or signing restriction.
  - Verification: validate and launch every origin in all formations; compare actual initial strength bands and distinguish team patterns. Split authored data batches as needed.
  - Dependencies: 6.1. Likely files: `content/countries.tres`, `content/starters.tres`, `ui/country_select.tscn`, `tests/test_content.gd` (M).
- [ ] **6.3 — Historical recruitment catalogue.** Add sourced era/version identities toward the proposed 96 historical cards, prioritising sufficient role/band coverage.
  - Acceptance: person/version uniqueness, bounds, prices, source/confidence notes, and extreme owned/released exclusions validate; last-resort fallback is exposed as a content defect, not routine generation.
  - Verification: constrained pool/offer/market generation across every chapter and exclusion scenario; manually audit a representative identity/rating sample. Split catalogue entry into small batches.
  - Dependencies: 6.2. Likely files: `content/historical_cards.tres`, `content/sources.md`, `content/validate_content.gd`, `tests/test_content.gd` (M).

**Checkpoint 6A:** All content effects and pools validate; data quantities never substitute for coverage or credible authoring. Core loop remains functional without external portraits.

- [ ] **6.4 — Album and recruitment presentation.** Refine card comparison, discovered-version grouping, neutral hidden slots, portraits/fallbacks, and skippable reveals.
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
