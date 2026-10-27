# Phase 1 — implementation and verification

27 October 2026. Branch: codex/phase-one. Engine: 4.7.2.stable.official.ed1daf0bf, GL Compatibility. No push, release or deployment.

## Current implementation

The user confirmed **180 active seconds of regulation at 1x / 90 active-play seconds at 2x**, plus deterministic stoppages. Two 90-second halves map to 0–45/45–90 displayed minutes. One shared setting drives match termination, halftime and clock mapping; 60/120-second candidates remain constructor-only calibration inputs, not player difficulty options.

The match has 22 fictional players, independent seeded state, physical passes/interceptions/tackles/shots/blocks, keeper holds/parries/reachable smothers, loose rebounds, goal-line scoring, bounded restarts, changed ends and exhibition draws. Central support runs, lead passes and cut-inside carrying replace recurring touchline recycling. Movement returned to the original bounded range for the longer match; finishing uses the original symmetric GDD starting formula. No goal cap, late score manipulation or player-relative difficulty exists.

The user-approved HUD follows MATCH_UI_HANDOFF.md: larger turf field, team/score/clock header, pause and segmented speeds, concise newest-first event rows, All events and a real pause modal. Details/statistics, confirmed restart/new exhibition and quit are secondary actions. The modal traps focus, preserves the previous playback state, and supports nested panels. Unsupported later features are absent.

Recent presentation changes: stronger numbered team-patterned discs, team-ringed green keepers, deeper goals/posts/netting, a shaded panelled football with rolling/touch motion, fixed below-player name anchors, gentle crowded-name de-emphasis, and real-event goal/halftime/full-time cues. Cosmetic animation does not advance simulation or decide outcomes.

The card direction is saved in DESIGN.md and linked from later tasks. CARD_DESIGN_HANDOFF.md and outputs/card-design-reference-v1/ remain reference material for later phases; no card system was implemented.

## Verification actually completed

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

## Render/interaction boundary

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