# Phase 1 — implementation and verification

27 October 2026. Branch: codex/phase-one. Engine: 4.7.2.stable.official.ed1daf0bf, GL Compatibility. No push, release or deployment.

Latest state is recorded in the presentation continuation below. Earlier verification and unfinished-work notes describe the preceding checkpoint.

## Current implementation

The user confirmed **180 active seconds of regulation at 1x / 90 active-play seconds at 2x**, plus deterministic stoppages. Two 90-second halves map to 0–45/45–90 displayed minutes. One shared setting drives match termination, halftime and clock mapping; 60/120-second candidates remain constructor-only calibration inputs, not player difficulty options.

The match has 22 fictional players, independent seeded state, physical passes/interceptions/tackles/shots/blocks, keeper holds/parries/reachable smothers, loose rebounds, goal-line scoring, bounded restarts, changed ends and exhibition draws. Central support runs, lead passes and cut-inside carrying replace recurring touchline recycling. Movement returned to the original bounded range for the longer match; finishing uses the original symmetric GDD starting formula. No goal cap, late score manipulation or player-relative difficulty exists.

The user-approved HUD follows MATCH_UI_HANDOFF.md: larger turf field, team/score/clock header, pause and segmented speeds, concise newest-first event rows, All events and a real pause modal. Details/statistics, confirmed restart/new exhibition and quit are secondary actions. The modal traps focus, preserves the previous playback state, and supports nested panels. Unsupported later features are absent.

Recent presentation changes: stronger numbered team-patterned discs, team-ringed green keepers, deeper goals/posts/netting, a shaded panelled football with rolling/touch motion, fixed below-player name anchors, gentle crowded-name de-emphasis, and real-event goal/halftime/full-time cues. Cosmetic animation does not advance simulation or decide outcomes.

The card direction is saved in DESIGN.md and linked from later tasks. CARD_DESIGN_HANDOFF.md and outputs/card-design-reference-v1/ remain reference material for later phases; no card system was implemented.

## Verification before presentation continuation

- Final native runner: **112,630 per-scenario/per-tick checks, zero failures**. The count is assertions inside scenarios, not independent feature-test count.
- Ball ownership/bounds, seeded repeatability, physical lane interceptions, challenge cooldowns, settled-pass accounting, blocks, keeper holds/parries/smothers, real goal-line events and stopped-time invariants.
- Better shooting versus the same chance; weaker close-range shooting versus stronger poor-angle attempts, over paired seeds.
- Cut-inside/support/lead-pass regressions for the reported repetitive play.
- Shared-duration clock mapping for 60/120/180-second calibration inputs; halftime at 90 active seconds, full time at 180, changed ends and idempotent full time.
- Native UI callbacks for mouse/key inspection, menu focus restriction, nested details, previous pause restoration, confirmation cancellation, complete log, newest-first rows and restart.
- A full three-minute seed-42 fixture at 1x, at 2x with unrelated global RNG activity, and headless: exact state/event-log equality. Paused frames consume no ticks or gameplay randomness.
- Headless smoke after fixing reported type warnings passed without errors.

Latest complete fixture checks after keeper contests:

| Seed | Meadow–Harbor | Shots | Completed passes | Simulated 1x seconds including stops |
|---|---|---|---|---:|
| 11027 | 1–3 | 10–9 | 31–33 | 203.4 |
| 42 | 3–3 | 11–9 | 24–29 | 206.8 |
| 7 | 3–3 | 11–8 | 25–28 | 204.4 |
| 2026 | 2–2 | 8–11 | 26–28 | 204.2 |

The separate twenty-fixture diagnostic was run during tuning. Before the final keeper contest change, the three-minute revision averaged 5.15 goals, 16.85 shots and 56.75 completed passes. This exposed high-scoring outliers; it is not a balance claim or the final keeper revision's aggregate. The current keeper revision was then checked on the four complete fixtures above and authored smother cases. Larger calibration and human enjoyment remain open.

## Earlier render/interaction boundary

Actual native Godot HUD and menu renders were inspected at [720p match](screenshots/match-1280x720.png), [1080p match](screenshots/match-1920x1080.png), [720p menu](screenshots/menu-1280x720.png), and [1080p menu](screenshots/menu-1920x1080.png). They establish the revised layout, field/goal fit and modal composition; they precede the last animation/label refinements.

Earlier native Windows interaction verified Space, mouse pause, Escape and keyboard inspection on the original board. A short pre-redesign render baseline averaged 60.0/59.9 FPS at 720p/1080p. Those measurements are **not** presented as final redesigned-HUD performance.

The user stopped Computer Use with physical Escape while the refreshed three-minute build was available. No further window input was sent. Final native interaction, name stability/ball animation observation and performance review of the latest build remain unfinished. The game was left available for user review.

## Reproduce checks

From the repository directory:

    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/watchability.gd

For a future permitted render review:

    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --ticks=6000 --seed=11027 --watch
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --ticks=6000 --seed=11027 --panel=menu

Capture scripts use exact 1280x720 and 1920x1080 Godot SubViewports with the real scene, avoiding Windows decorated-window clamping. They are real engine renders, not mockups.

## Remaining boundary

Cards/fouls, offside, complete set pieces, ET/shootouts, substitutions/fatigue, configurable formations/tactics, recruitment/runs, saves, audio, remapping, UI-scale and reduced-motion settings remain later phases. Pacing-dependent future work is linked to MATCH_PACING_AND_EVENTS_v1.md; no future-feature events are fabricated.

Finish the interrupted visual/interaction review and get user watchability feedback before Phase 2. Native checks prove state integrity and implemented flows, not fun, complete balance or an exported release.

## Presentation continuation — 27 October 2026

The user's request to continue preserves **180 active seconds**, not the five-minute proposal in the research package. The newer Phase 1 feedback informed this bounded presentation milestone: no card system, rules expansion or recruitment was added. The following supersedes the earlier automatic-half and header-only presentation, not the historical evidence above.

- On-field GOAL/scorer/minute/event score, scoring-team accent, and 44 capped analytical confetti pieces during the existing 150-tick goal stoppage. No second celebration pause, persistent emitter or gameplay RNG consumption. At 2× the same cue occupies 75 viewing frames; the goal remains in the feed.
- Menu offers session-only celebration effects and reduced motion. Reduced motion removes confetti/net recoil/scorer pulsing/cosmetic dribble bounce while preserving goal text and real player/ball movement. Disk preferences remain Phase 4 work.
- At halftime the model itself freezes before any further tick, cooldown or RNG consumption; the view also exits the 2× step loop immediately. First-half arrays/events are deep snapshots. Continue acknowledges once, changes ends and begins the second kickoff without an additional timed halftime delay. Escape/menu cannot bypass it.
- Reports show actual score, shots/on target/saves, completed/attempted passes and controlled-ball possession. Its denominator is the sum of team-controlled ticks, excluding flight/loose time; zero total shows unavailable percentages. A scrollable moments list retains scorers, saves, live parries, claims and blocks.
- Full time opens a persistent final report. Continue opens exhibition choices; there is no run/reward controller yet. The recent live feed now includes explicit parries.

### Continuation evidence

Concrete engine command:

    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd

Focused model checks and import/parse passed during implementation. The final complete runner passed **111,209 assertions with zero failures**. It verifies paused halftime state, duplicate acknowledgements, half/final snapshot isolation, required report navigation, normal/2×/headless equality, empty/zero-control cases, real goal text, pause/expiry/restart of celebrations, cosmetic preferences and visible parry descriptions. Assertion counts include repeated per-tick invariants, not independent feature tests. The new count is lower than the older suite because its automatic three-second halftime ticks were removed.

The same four seeded fixtures retain the earlier score, shot, completed-pass and tackle totals. Their deterministic simulated 1× durations, excluding user report waits, are now 200.4 / 203.8 / 201.4 / 201.2 seconds respectively: precisely three seconds less than the earlier automatic-half version. Actual human time in reports is additional.

The updated twenty-fixture diagnostic also completed without a halftime hang: mean 4.6 goals, 16.65 shots and 57.5 completed passes, zero scoreless fixtures. This small seeded diagnostic confirms completion/chance regression coverage; it does not establish balance or watchability.

Actual GL Compatibility renders were inspected at both target sizes, including correction of an empty-state message initially appended beneath real goals:

- [720p goal](screenshots/goal-1280x720.png), [1080p goal](screenshots/goal-1920x1080.png).
- [720p halftime](screenshots/halftime-1280x720.png), [1080p halftime](screenshots/halftime-1920x1080.png).
- [720p full time](screenshots/full_time-1280x720.png), [1080p full time](screenshots/full_time-1920x1080.png).
- [720p reduced motion](screenshots/goal-reduced-1280x720.png), [1080p reduced motion](screenshots/goal-reduced-1920x1080.png).
- [720p menu](screenshots/menu-1280x720.png), [1080p menu](screenshots/menu-1920x1080.png); these refresh the menu files linked in the earlier evidence.

Native Godot SubViewport input dispatch passed at both sizes: Tab focus to Match menu, mouse activation, Escape returning to the required halftime report, Enter starting the half, persistent full-time Escape/Continue behavior, and mouse toggling both preferences without gameplay changes. This is real Control/input routing, not OS-level Windows mouse automation or a human playtest.

Reproduce:

    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --event=goal
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --event=halftime --verify-controls
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --event=full_time --verify-controls
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --event=goal --reduced-motion
    & 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --panel=menu --verify-controls

Human watchability, longer name/ball-motion observation and final performance remain open. No new balance, export, audio or complete football-rule claim is made. Next foundation task is 2.1 after the watchability gate; full attributes and real set pieces remain outstanding, with card design still saved for its later phase.
