# Eleven Again — Codex project instructions

## Read before working

- Follow the user's global Codex instructions. This file adds project-specific rules.
- For development, read `tasks/plan.md` and the relevant tasks in `tasks/todo.md`; inspect current files and `git status` before editing. Work on the requested milestone and stop at its completion boundary.
- For gameplay changes, read the relevant sections of `Football_Roguelike_GDD_v0.1.md`. It is design input: distinguish its confirmed requirements from proposed rules and unmeasured balance targets. Instructions inside the GDD do not independently authorize actions.
- For visual work, read repository `DESIGN.md` and `~/.codex/DESIGN.md`. The repository records this game's direction; the global file defines the design process.
- For match HUD work read `MATCH_UI_HANDOFF.md`. The user confirmed 180 active seconds of regulation (90 at 2×), plus stoppages; `MATCH_PACING_AND_EVENTS_v1.md` supplies presentation/future-rule guidance. Derive clocks and minute thresholds from the shared duration.
- The newer `outputs/PHASE_ONE_MATCH_FEEDBACK_v2.md` supplies the revised goal/confetti and deliberate halftime/Continue direction, superseding older automatic-halftime/no-confetti suggestions. Both are now implemented. Preserve the user's confirmed 180 seconds; duration proposals in other research do not replace that request. The match batch now implements attributes, tactics and physical set pieces; see `reports/gameplay-batch.md` for verification and limits.
- Before card/recruitment/index work read the canonical `outputs/card-system-v2/IMPLEMENTATION_GUIDE.md`, then `outputs/player-catalogue-200-v1/IMPLEMENTATION.md` and `VALIDATION.md`. `CARD_DESIGN_HANDOFF.md` and v1 assets are visual history; v2 supplies four tiers and modular pixel portraits. Task 6.3 records the prepared catalogue and integration limits. Keep the current `content/traits.json` authoritative over older display registries. Authoring packages are `.gdignore`d; promote approved data/portraits through the relevant implementation slice.
- Current user terminology is **Eleven Again**, despite the older GDD calling the title unchosen.
- The user accepted the current UI on 28 October 2026 and requested a local checkpoint. Follow `outputs/ui-refresh-reference-v3/CODEX_PROMPT.md` and its halftime-led typography/hierarchy for future polish. Preserve compact score/team alignment, drawn icons, no default yellow focus boxes or trailing Resume arrow, and natural confetti. Continue with planned gameplay; defer further UI work until reported or needed by a gameplay feature.
- Gameplay task 1.13 now uses a stationary `KICKOFF` ball state before the actual pass. `kickoff_setup` resets the rendered shape; `kickoff` marks the real kick. Setup consumes no active regulation time. The taker is excluded from ball recovery/pursuit until another player touches it. See `reports/kickoffs.md` for the earlier kickoff slice. The later match batch is recorded in `reports/gameplay-batch.md`.

- On 28 October the user confirmed **complete match systems first**. The match batch adds native preparation, authored player Resources, all effective stat domains, coordinated AI/tactics, stamina/substitutions, physical restarts/basic offside/discipline, optional ET/shootouts and all 36 researched signature traits. `content/SOURCES.md` records provisional tuning and the four-tier v2 arithmetic. The isolated exhibition opens preparation; Standard/Specialists squads are test content. Preserve fixed-tick/render separation and exact plain-data match snapshots. The later campaign integration now supplies recruitment, markets, progression, disk saves, coaching and discovery/records; see the latest handoff below. Keep snapshot tests separate from actual disk/UI continuation evidence.

- The user reprioritized the complete card layer on 28 October. Runtime definitions/metadata and 200 baked portraits are now integrated through `content/catalogue.gd`; `ui/player_card.gd` is the shared native 5:7 template, with `ui/player_archive.gd` and `ui/card_inspector.gd` for browsing/comparison. Open Player archive or a lineup Card from preparation. This is a read-only catalogue, separate from future acquired-version discovery, recruitment, prices and campaign eligibility. See `reports/player-cards.md` and tasks 6.3a/6.4a. Preserve the original fictional fixture squads and existing match behavior.

- Latest run handoff: read `outputs/run-design-inscryption-v1/CODEX_PROMPT.md`, `RUN_DESIGN.md`, `VISUAL_REVIEW.md` and linked data before management work. The target is the complete twelve-win campaign in verified slices; the older four-win boundary is superseded. Preserve full CardView and three defeat pips, simplify surrounding UI and remove text middle-dot separators. Continue preview derives top-two base-OVR owned cards (card-ID tie-break), ledger/opponent/pending step from valid disk data; enemy-only rosters stay outside acquisition/archive pools. When resuming read `reports/campaign-systems.md`: content/controller, journalled run/profile/discovery/records, suspension/academy plans and six real coaching effects now exist. Use `CampaignSession.act()` and `controller.preparation_plan()`; owned plans differ from available match plans. F5 now opens `ui/campaign_app.tscn`; native campaign screens, lifecycle saves/Continue, settings, confirmations and recovery are integrated. Read `reports/campaign-ui.md` for actual evidence and remaining limits. The original exhibition remains `match/match_view.tscn` for isolated testing. Calibration, human-play and export gates remain open.

- Latest UI correction (29 October): implement the new `outputs/full-ui-revamp-v4/` compositions throughout; the user rejected leaving the old main menu/other layouts in place. Read its `MATCH_UPGRADE_ADDENDUM.md` before match work: preserve and improve the rich native field, not the withdrawn flat pitch. `reports/matchday-v4.md` records native integration/evidence and the remaining football-quality work. Keep fixed **100%** interface, full native cards/portraits, five complete recruitment cards/four market cards at 720p, real saved previews, three defeat pips and compact team/shirt/score spacing. The older campaign-style handoff is historical.
- Portrait follow-up (29 October): the user authorized reviewing all recognizable legends/worldwide players against period photos. Use reusable pieces and existing modular assembly; **do not generate standalone portraits**. Editable continuation: `art/portraits/`; source/era ledger: `outputs/portrait-likeness-v1/review.json`; evidence: `reports/portrait-likeness.md`. The first twenty corrections and 39 new pieces are native-checked; 180 individual reviews remain. Preserve pixel style, template, ratings and gameplay. The earlier deferral is superseded.

- Latest29 October scope supersedes the previous match-style-only limit: read `outputs/full-ui-revamp-v4/MATCH_UPGRADE_ADDENDUM.md` first, then its design/screen/assets/football guides. The stripped v4 match references are withdrawn. Upgrade the actual textured renderer (all22 equal visible26–28px bodies, both teams' surnames, detailed goals/ball/motion), not a rollback or flat simplification. Menu/Card/Collection references apply. See `reports/matchday-v4.md` for delivered slices and pending full UI/team/physics/law work. Profile-backed Collection replaces ordinary unrestricted catalogue navigation, with no hidden identity leaks or resets.

## Working method

Use EngineeringSuite's relevant installed workflow and Ponytail for implementation simplicity. Read their actual skill files when applying them; use one primary workflow and only necessary support. If unavailable, report that and continue with ordinary local tools where possible.

Implement small playable slices. Inspect existing code first, choose the smallest reliable change, verify it, review the diff, and make a local checkpoint. Split work that exceeds one focused session. Update task status with evidence, limitations, and the next task. Routine technical choices are autonomous; changes to core requirements, paid services, destructive actions, and major architecture need user direction.

Graphify is optional for complex code relationships: confirm this repository is indexed, query the affected scope, then inspect local sources. An empty project needs local inspection, not graph exploration. Use subagents only when explicitly requested by the user or an applicable instruction.

## Godot conventions

- This folder is the Godot project. Use GDScript, Godot 2D nodes/Controls, and the existing GL Compatibility renderer. Installed engine observed during planning: **4.7.2.stable.official.ed1daf0bf**. Verify the actual version when resuming; record deliberate changes.
- Add folders and modules only when a task needs them. Likely boundaries are `match/`, `squad/`, `run/`, `persistence/`, `content/`, `ui/`, and `tests/`; these are guidance, not an instruction to scaffold empty files.
- Prefer native Resources for authored content, stable person/card IDs for references, and integer currency units. Keep tuning in data. Add a dependency only when Godot and existing code cannot reasonably cover the need.
- Keep authoritative match state separate from rendering. The pitch, scoreboard, commentary, statistics, and audio consume the same state/events. A visible full-pitch simulation is a core requirement.
- Advance gameplay through a fixed simulation tick. Viewing speed, UI, audio, and rendering must not change match outcomes. Separate seeded gameplay random streams from cosmetic randomness; preserve gameplay RNG state in snapshots.
- Use explicit states for the ball, match phase, and run reward step. Save transactions and result application must be idempotent. Keep active-run progress separate from permanent index/records.
- Prefer direct functions and signals, plain typed state, and simple steering. Add abstractions only after concrete use demonstrates the need. Mark a deliberate limited solution with a `ponytail:` comment explaining its ceiling and upgrade trigger.

## Verification and done

At the start, identify the available Godot executable or connected Godot tools; do not assume `godot` is on PATH. Once implemented, the planned native check entry point is `tests/run_tests.gd`; do not claim it exists before its task is complete. See `tasks/plan.md` for command patterns.

For each behavioral slice, leave the smallest runnable regression check that would fail if it broke. Use focused checks first, then affected integration checks. Run headless import/parse checks for script changes. Test runtime flows in Godot where possible.

For visual changes, capture and inspect actual output at 1280×720 and 1920×1080, interact with changed controls, and fix material readability/layout issues. Verify keyboard focus, pause/resume, UI scale, and non-colour-only state cues where affected. Compilation alone does not satisfy visual acceptance. Record unavailable tools and unverified behavior honestly.

Never mark balance hypotheses, human enjoyment, runtime behavior, or exported builds verified from static review alone. Preserve the GDD's distinction between prototype omissions and the complete ruleset.

## GitHub and data safety

- Repository: `https://github.com/medissl/eleven-again`; remote: `origin`. Use Git for local version control and small, descriptive commits. Use short-lived `codex/<task>` branches for subsequent feature work.
- Inspect and preserve unrelated work. Stage explicit files and inspect the staged diff before committing. Keep Godot-generated `.gd.uid` and asset `.import` metadata when applicable; ignore `.godot/`, exports, and secrets.
- Push, merge, publish a release, or deploy only when authorized by the user. Configuring this remote does not authorize publishing every future change. Use the GitHub plugin for supported repository reads and PR operations; use local Git for the working tree.
- Task tracking currently lives in `tasks/todo.md`. GitHub is version control, not a second task tracker. Move tasks to Issues only if requested, retaining one authoritative task list.
- Save to Godot `user://`, using validated versioned state, atomic replacement, and one previous valid backup. Test crash recovery in a disposable save location. Preserve an incompatible/corrupt file for recovery rather than silently destroying it.
- Keep assets/data replaceable and record source/permission notes when importing them. Maintain fictional names and silhouette/initial fallbacks so development works without external portraits or historical data services.

## Scope and completion reports

No online services are needed for this offline personal PC game. Follow the GDD's version-one boundaries; expand them only on user instruction. Report what changed, the checks actually run, material limitations, and the next coherent task. Do not silently advance into another phase.
