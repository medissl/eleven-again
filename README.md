# Eleven Again

An offline PC football squad-building roguelike, built in Godot. Prepare a fictional starting squad, recruit football greats, set tactics, and watch short top-down matches through a disposable run.

## Current state

Phase 1 implemented, 27 October 2026: a playable fictional eleven-a-side exhibition with physical passes, interceptions, tackles, shots, saves, rebounds, goals, two halves, a live journal, statistics, and pause/speed controls. Godot **4.7.2.stable.official.ed1daf0bf**, GDScript, GL Compatibility; no external dependencies.

Regulation is now **three active minutes at 1× / ninety active-play seconds at 2×**, plus stoppages, as confirmed by the user. The match has the approved pitch-first HUD, stable below-player names, shaded rolling football, improved discs and deeper nets. This prototype permits draws and simplifies restarts. Cards, offside, substitutions, squad preparation, recruitment, runs, saves, audio and complete player Resources arrive later. It is not a balanced or exported release. Final animation/native interaction review remains open after Computer Use was stopped.

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

Next milestone after watchability feedback: **Phase 2 — meaningful preparation**. Development is on `codex/phase-one`; nothing has been pushed.
