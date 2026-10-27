# Eleven Again

An offline PC football squad-building roguelike, built in Godot. Prepare a fictional starting squad, recruit football greats, set tactics, and watch short top-down matches through a disposable run.

## Current state

Planning baseline, 27 October 2026. The original Godot project has no scenes, scripts, main scene, or playable match. Godot tooling reported **4.7.2.stable.official.ed1daf0bf**; the project uses GL Compatibility. No gameplay, balance, export, or visual verification is claimed.

## Development documents

- [Development roadmap](tasks/plan.md): phases, boundaries, risks, checks, and reusable Codex instructions.
- [Task checklist](tasks/todo.md): ordered work and acceptance criteria; the current task source of truth.
- [Project agent instructions](AGENTS.md): engineering, skills, Git, and verification workflow.
- [Project design direction](DESIGN.md): football tactics board and legends album, with rendering gates.
- [Original GDD v0.1](Football_Roguelike_GDD_v0.1.md): preserved early design, including provisional rules and unmeasured targets.

## Godot

Import this folder's `project.godot` in Godot. Phase 1 adds the first runnable scene and native headless checks. Use the installed engine version until a deliberate upgrade is verified. The Godot executable is not currently on the shell PATH; connected Godot tools can inspect the project.

## Version control

GitHub repository: [medissl/eleven-again](https://github.com/medissl/eleven-again). Local Git is initialized with this `origin`. Local checkpoints do not imply files have been pushed; publishing requires user authorization.

Next milestone: **Phase 1 — watchable football**. See the roadmap for a ready-to-use Codex prompt.
