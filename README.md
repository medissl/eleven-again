# Eleven Again

An offline PC football squad-building roguelike, built in Godot. Prepare a fictional starting squad, recruit football greats, set tactics, and watch short top-down matches through a disposable run.

## Current state

UI refresh accepted by the user on **28 October 2026**. Shared packaged typography, fullscreen menus/reports, distinct icons and renderer-only transition polish are checkpointed locally. See [UI checkpoint evidence](reports/ui-refresh.md). Further UI work is deferred to polish. Proper kickoffs now set a stationary centre ball, legal spacing and an actual opening pass, including after goals and halftime; see [kickoff verification](reports/kickoffs.md). Boundary rules, full attributes, coordinated AI, tactics and traits remain planned gameplay work.

Phase 1 implemented, 27 October 2026: a playable fictional eleven-a-side exhibition with physical passes, interceptions, tackles, shots, saves, rebounds, goals, two halves, a live journal, statistics, and pause/speed controls. Godot **4.7.2.stable.official.ed1daf0bf**, GDScript, GL Compatibility; no external dependencies.

Regulation is **three active minutes at 1× / ninety active-play seconds at 2×**, plus stoppages and time spent in reports. Goals show an on-field scorer/score celebration; halftime freezes until **Continue second half**, with actual statistics and first-half moments. Full time retains its summary until Continue opens exhibition choices. Menu includes celebration-effects and reduced-motion switches for the current session.

The pitch-first HUD, fixed below-player names, rolling football and deeper nets remain. Native checks and rendered report/control verification pass at 720p/1080p; human watchability approval remains open. This prototype permits draws and generic restarts. Complete attributes, genuine set pieces, tactics, cards, recruitment, runs, saves and audio remain future work. It is not a balanced or exported release.

## Development documents

- [Development roadmap](tasks/plan.md): phases, boundaries, risks, checks, and reusable Codex instructions.
- [Task checklist](tasks/todo.md): ordered work and acceptance criteria; the current task source of truth.
- [Project agent instructions](AGENTS.md): engineering, skills, Git, and verification workflow.
- [Project design direction](DESIGN.md): football tactics board and legends album, with rendering gates.
- [Original GDD v0.1](Football_Roguelike_GDD_v0.1.md): preserved early design, including provisional rules and unmeasured targets.

## Godot

Import this folder's `project.godot` in Godot and press **F5**. The exhibition starts automatically with a fresh fixture seed. Open **Menu** for match details, the full log, a confirmed same-seed restart, a new exhibition, or quit. The current prototype generates attributes with the fixture seed. Use the installed engine version until a deliberate upgrade is verified.

- Space: pause/resume. Escape: menu/back, restoring the prior playback state when the menu closes.
- 1 / 2 or the segmented buttons: 1× / 2× playback.
- Hover/click a player or Left/Right: inspect names and prototype attributes.
- Tab/Shift+Tab and Enter: navigate/activate buttons. All events opens the complete log while paused.

The shell executable was found at `D:\Godot\Godot_v4.7.2-stable_win64_console.exe`. Run native checks from the project directory:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
```

See [Phase 1 verification](reports/phase-one.md) for exact checks, seeds, rendering evidence, measured limits, and screenshot commands.

## Version control

GitHub repository: [medissl/eleven-again](https://github.com/medissl/eleven-again). Local Git is initialized with this `origin`. Local checkpoints do not imply files have been pushed; publishing requires user authorization.

Next gameplay slice: **1.14 — genuine boundary restarts**, before meaningful preparation in Phase 2. Kickoff development is on `codex/proper-kickoffs`; nothing has been pushed.
