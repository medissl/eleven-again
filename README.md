# Eleven Again

An offline PC football squad-building roguelike in Godot. The native twelve-win campaign is now playable, alongside the original match/preparation sandbox.

## Current state

The complete native card layer is available: **200 authored world-player editions and portraits**, a shared four-tier archive card, searchable/filterable browsing, full player files and pinned stat comparisons. In preparation, open **Player archive**, or use a lineup row’s **Card** button. The archive is a read-only catalogue; browsing does not recruit players or unlock permanent discoveries. See [card verification](reports/player-cards.md). Ratings and modular likenesses remain provisional.

The user requested a large gameplay batch and confirmed **complete match systems first** on 28 October 2026. Native preparation now commits a legal XI, bench, formation, attack/defence tactics, width, route, captain/takers, penalty order and automatic substitution plan. Authored fictional card Resources supply six outfield and five keeper attributes, role familiarity/OVR, fatigue and one signature trait. OVR and tier add no hidden match multiplier.

The fixed-step full-pitch simulation includes coordinated support/pressure/cover, interruptible combinations, finite movement/turning, physical passes/curves/crosses/headers, first touches, tackles, shots, saves/rebounds and whole-ball boundary restarts. Basic offside, contextual fouls/cards, reduced-team cover, keeper dismissals and forfeits are implemented. All 36 researched traits enhance actual actions, with bounded use/cooldown and local aura/action feedback. Standard and Specialists fixture squads collectively expose them; these squads are unbalanced test content.

Regulation remains **three active minutes at 1× / ninety active-play seconds at 2×**, plus stoppages and deliberate halftime. Exhibition may end in a draw. The optional knockout profile adds two 30-active-second extra-time halves and physical penalties if still tied. Shootout tallies stay separate from match goals/statistics. Exact native disk snapshot/backup primitives are now tested, including fresh-process continuation; automatic checkpoints and main-menu Continue are integrated.

The [campaign foundation](reports/campaign-foundation.md) adds six origins, authored opposition, 300 acquisition candidates and twelve-stage progression/rewards. The [campaign systems batch](reports/campaign-systems.md) adds durable run/profile journaling, acquired-version discovery/records, carried suspensions/temporary academy cover and all six contextual coaching effects. These native models pass focused and existing football checks. The [native campaign UI](reports/campaign-ui.md) connects all rewards, preparation/matches, durable Continue, recovery/settings, Discovered/records and both endings. The interface now stays at 100%. Portrait likeness/era polish is deferred.

The accepted forest/ivory presentation, Barlow/Inter typography, stable camera, goal/confetti and calm reports remain. Read [gameplay evidence and limits](reports/gameplay-batch.md), [UI checkpoint](reports/ui-refresh.md) and [task status](tasks/todo.md). This is not a balanced or exported release.

## Play in Godot

Import this folder's `project.godot` and press **F5**. The campaign menu opens first. Choose New run, an origin and an opening recruit, then prepare your XI and play. Recruitment, markets and coaching follow saved progress. Continue resumes the actual disk checkpoint; Save and exit is in the match menu. The original sandbox can be launched separately from `match/match_view.tscn`; it retains Standard/Specialists and editable opposition. The Lineup, Set Pieces and Substitutions tabs expose roles, takers and reserve priority/pins. Inspect a player to see base/effective ratings and its trait. Start match locks private copies of both plans.

- Space pauses/resumes. Escape opens/closes menus while preserving the prior playback state.
- 1 / 2 or the segmented buttons select 1× / 2×.
- Hover/click a player or Left/Right to inspect actual stats, stamina/job and trait availability; hover the inspection for trigger/effect/counterplay.
- Tab/Shift+Tab and Enter navigate native controls. All events opens the paused complete log.
- Campaign Menu offers settings and Save and exit. The isolated exhibition retains preparation/restart. Halftime waits for Continue second half.

## Development

Godot **4.7.2.stable.official.ed1daf0bf**, GDScript, GL Compatibility; no runtime dependencies. The engine was found at `D:\Godot\Godot_v4.7.2-stable_win64_console.exe`.

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
```

Use `-- --batch-only` for focused match-batch checks. Inspect the output for script errors as well as assertion failures. Commands and reproducible native render scenarios are in the gameplay report.

- [Roadmap](tasks/plan.md) and [task checklist](tasks/todo.md).
- [Project instructions](AGENTS.md) and [design direction](DESIGN.md).
- [Original GDD](Football_Roguelike_GDD_v0.1.md), preserved with its proposals and unmeasured targets.
- [Fixture sources/tuning](content/SOURCES.md).

GitHub: [medissl/eleven-again](https://github.com/medissl/eleven-again). Current local work is on `codex/campaign-foundation`; nothing has been pushed. Next coherent task: remaining factual opposition/result evidence (3.5/5.6), then measured calibration and human playtests. See the campaign UI report. No export, push or release has been performed.
