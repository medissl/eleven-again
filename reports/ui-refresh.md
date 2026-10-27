# Accepted UI and motion checkpoint

28 October 2026. User tested the current UI, accepted it and requested a local checkpoint. No push or deployment.

The reference-led refresh unifies packaged Barlow Condensed/Inter fonts, theme roles, live header/feed, fullscreen pause/settings/log/details, half/final reports, distinct action/menu icons and goal sweep/confetti. User feedback corrected team alignment, default focus boxes, the Resume arrow, status-dot alignment and rigid confetti clipping. Reduced motion and 100/115/125% UI settings are functional for this session.

Renderer settling, actual-position trails, brief contact/possession cues and kickoff reveal fades are cosmetic. Existing fixed-step football, three-minute regulation, RNG and outcomes are unchanged. Gameplay follow-ups are explicitly pending in the single task list: proper kickoff, genuine restarts/fouls, complete attributes, coordinated AI, tactics and automatic traits.

Verification: Godot 4.7.2 native runner passed **111,224 assertions, zero failures**, including complete 1×/2×/headless state equality, stopped halftime, snapshot reports, glyph/stable-numeral checks, cosmetic independence, render-only easing, pause, repeated refresh and reset/rapid-menu cases. Original match model, project configuration and GDD have no changes. Import/parse and native GL captures passed during the slices.

Real captures under `reports/screenshots/` cover live, goal, half/final, pause, settings, log/details and enlarged/long-name variants at 1280×720 and 1920×1080. Native viewport input exercised Tab/Enter/mouse, nested Back/Escape, confirmation cancellation, report Continue, possession tooltip and settings. Some captures precede final footer/spacing refinements; user acceptance applies to the current running UI.

Native motion frame sequences were recorded in ignored `.godot/presentation-frames/`: goal, halftime/Continue and menu have 70 samples each at 20 fps from 60-step capture; the rebound sample stopped at 60 of 70 frames. These are actual renders, not generated art. Complete continuous visual/performance review was not finished before the user accepted UI and requested stopping. No new performance, balance, export, complete football-rule or gameplay-AI claim is made.

Reproduce focused checks with the existing `tests/run_tests.gd` and `tests/capture_match.gd`. Motion recording uses `--fixed-fps 60 --script res://tests/capture_match.gd -- --motion=goal` (or halftime/menu/rebound). Raw frames stay ignored. Font source/licence details are in `assets/fonts/SOURCES.md`.
