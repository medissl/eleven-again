# Eleven Again — Codex development roadmap

Date: 27 October 2026. Source: GDD v0.1. Task tracker: `tasks/todo.md`.

## Outcome and authority

Build the user's offline personal PC game in this Godot project, using GitHub for version control, EngineeringSuite for the relevant development workflow, Ponytail for simplicity, and the global/project agent and design instructions.

This delivery establishes the plan and repository workflow. It does not implement gameplay or approve every GDD proposal. The GDD remains unchanged. Its confirmed requirements define the product; its proposed run length, economy, squad limits, formulas, content counts, and balance targets are a **working baseline** for future implementation and playtests. Eleven Again is the current project name supplied by the user.

The next development request can accept the relevant phase as a working specification. Reversible technical choices need no repeated permission. Seek user direction for consequential changes to the core football experience or disputed proposals; do useful independent work meanwhile. Planning must not be confused with measured results.

## Baseline inspection

- Root contains `project.godot`, the GDD, icon/import metadata, and editor/Git settings. Connected Godot inspection found zero scenes and zero scripts.
- Engine tool returned `4.7.2.stable.official.ed1daf0bf`; retain GDScript, 2D, and GL Compatibility.
- No local Git repository existed. Local Git was initialized, the original files checkpointed, and `origin` set to `https://github.com/medissl/eleven-again.git`.
- The GitHub plugin found the correct accessible repository, reporting size zero and default branch `main`. Its visibility was public at inspection. No remote content was changed. Inspect remote state again before first authorized push; account credentials for Git transport have not been tested.
- Graphify is available but unnecessary for an empty codebase; no index was queried.
- There is no runnable main scene, test runner, export preset, or game screenshot. Godot inspection is evidence of setup only.

## Delivery phases

Each phase is a milestone containing several focused Codex sessions, not a promise to finish in one prompt. Dependencies run in order. If a task grows beyond about five files or one focused session, split it before implementation. File paths in the task list are prospective, not required scaffolding.

| Phase | Playable/result milestone | Includes | Exit gate |
|---|---|---|---|
| 0. Project contract | Repeatable development context | Agent/design instructions, roadmap, task list, local Git baseline and GitHub remote | Documents agree, original project preserved, local checkpoint exists |
| 1. Watchable football | Run one fictional exhibition | Full pitch, 22 players, ball, passing, carrying, reachable tackles, shots, saves, goals, 60-second clock, truthful feed, pause/speed, native checks | Visible match is understandable; invariants and supported-build speed equivalence pass; no persistent swarming or phantom goals |
| 2. Meaningful preparation | Make a plan and observe its effect | Player resources/OVR, three formations, role penalties, nine tactics, fatigue, preplanned automatic substitutions | Legal XI enforced; controlled scenarios show behavior changes; no live management required |
| 3. Four-win run | Play a small complete roguelike | One country, opening recruit, three later offers, one market, three defeats, scouting, final, ET/shootout | Country → recruitment → prep → matches/rewards → ending works; no reward duplication, soft lock, or roster/economy exploit |
| 4. Reliable continuation | Close the game and return safely | Atomic versioned saves/backups, exact match resume, separate profile, basic silhouettes/index/records, settings persistence | Interruption/recovery checks pass at each transaction; completed run clears only run progress |
| 5. Complete football and run | Twelve-win candidate version | Restarts/set pieces, offside, discipline/suspensions/emergency roles, full opponents/reward schedule, three markets, two principles, evidence-based results | All complete-version rule scenarios work; full run can resume at every checkpoint |
| 6. Identity and content | Personal game with its intended collection | Six origin rosters, historical versions by coverage, eight traits, complete album, authored rivals, HUD/menu/audio refinement | Content validator passes under exclusions; all screens/flows reviewed at both resolutions with accessible input |
| 7. Calibration and personal build | Tested Windows build | Statistical match/run reports, observed playtests, measured performance, targeted tuning, export smoke test | Major pacing/exploit/readability issues addressed; packaged game runs and saves on user's PC; limits documented |

**Critical path:** 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7. Do not invest in a large historical roster while Phase 1 is failing. The four-win slice is intentionally useful before the full design is built.

## Scope contracts

### Phase 1 is a football experiment

Use two fictional squads and a single default formation. Show actual ball travel, reachable challenges, keeper actions, and rebounds. A prototype may simplify dead-ball positioning and end a tied exhibition as a draw; label those omissions. Phase 3 replaces exhibition draws with ET and penalties. Cards, offside, full set-piece choices, markets, historical content, and saves are not prerequisites of a watchable prototype.

Never replace visible play with a separately rolled hidden score. Keep passes and shots in authoritative field state. A match with attractive moving circles but unrelated outcomes fails the phase.

### Four-win slice is a separate content configuration

Provisional slice: 16 fictional starters, $8m, one opening 75–79 recruit, 18-player cap, wins 1–4, three-defeat limit. Free offers follow wins 1, 2, and 3; Market I follows win 3. The slice ends after victory 4 and omits coaching because no further match can use it. Phase 5 introduces coaching after wins 4 and 8 in the full twelve-win schedule. This is an explicit prototype omission, not a change to the GDD's full-run rules.

Target about 48 fictional collectible versions only if coverage validation proves them sufficient. Include the short run's final opponent, scouting, lineup, subs, and a summary. Phase 3 is session-playable; Phase 4 completes the GDD's resumable short-run slice with basic index/profile. Always label incomplete football rules in development builds.

### Full candidate version

Use the GDD's twelve-win/three-defeat schedule, nine victory offers, three markets after wins 3/7/11, and two coaching choices after wins 4/8 as provisional data. Start at $8m; victory income totals $84m, giving $92m including starting cash. Final rewards record the prize and go straight to the summary. Losses retry the fixed opponent without new prizes or offers.

Six country rosters and roughly 96 historical recruitable versions are content targets, not arbitrary quotas. Validate role/band coverage under owned/released-person exclusions. Keep every implemented country and recruitment pool available from the first run. Keep all persistent collection progression cosmetic/informational.

### Outside the initial personal game

Online multiplayer, mobile, public launch, live football APIs, accounts/backends, paid rolls, contracts/salaries, injuries/ageing, career seasons, stadium systems, manual on-pitch controls, full replay rewind, and permanent power upgrades remain outside scope. Public distribution and historical asset usage need a separate content review if requested later.

## Minimal implementation direction

- Use native Godot scenes/Controls and GDScript. Add Resources for cards, formations, opponents, and tunable rules when used; keep stable person/card-version IDs.
- Start with a plain authoritative match model stepped at fixed 60 Hz and stagger high-level decisions around 4 Hz. Simple formation anchors, bounded steering, and lane queries come before navigation frameworks or learned AI. Measure before optimizing.
- Render player/ball positions and feed the HUD from typed state/events. UI requests commands; it never invents match outcomes or currency changes.
- Use independent seeded streams for match actions, offers, and markets; cosmetic randomness stays separate. Commit inputs/seed before kickoff; save exact state and RNG position for mid-match continuation on the supported build.
- Store money as integer units. Confirm signing, payment, and required release as one transaction. A cancelled preview changes nothing. Reward steps have stable IDs/state so resume cannot replay a prize or discovery.
- Keep content, squad validation, match, run progression, persistence, and UI responsibilities clear; create a module when its first real task requires one. No generic service container, entity framework, plugin architecture, or speculative folder tree.
- Use one small native headless runner before adding a testing dependency. Add reusable helpers only after actual duplication. Snapshot every part of state affecting future outcomes, including pending actions, cooldowns, timers, substitutions, and RNG.

## Checks and evidence

The following are planned command patterns after the referenced scripts exist. `$GodotExe` means the verified installed console-capable executable path, not a currently configured environment variable. Connected Godot tools are an alternative for project runs/debug output. Record the concrete command and result used each time.

```powershell
& $GodotExe --version
& $GodotExe --headless --path . --editor --import --quit
& $GodotExe --headless --path . --script res://tests/run_tests.gd
& $GodotExe --path .
```

Native runner design: assertions, a nonzero exit code on failure, explicit scenario seeds, and a disposable save directory for persistence cases. Headless gameplay must use the same simulation as the visible match. CI comes after local checks work, using the same recorded engine build; no speculative workflow referencing a guessed downloadable engine version.

For every phase: run focused behavior checks, affected integration checks, import/parse, runtime smoke, and diff review. Include evidence in `tasks/todo.md` (command/result, scenario/seed, screenshot path when relevant, and remaining limitations). Review checkpoint evidence before proceeding within an authorized milestone. Human acceptance of watchability and fun is separate from automated verification.

For visual work: apply `DESIGN.md`, inspect real references for the first HUD/album, capture 1280×720 and 1920×1080, check keyboard/mouse behavior, contrast, overlapping labels, UI scale, and reduced motion. Record actual screenshots; do not mark visual QA from reading scene files.

Phase 7 calibrates using GDD §18: 2,000 equal-team fixtures with side swaps; at least 500 fixtures per attribute-gap scenario; 200 per tactic matchup across varied rosters; 1,000 runs per simple strategy. Publish seeds, configuration/version, counts, outcome definitions, uncertainty intervals, and outliers. Repeat affected scenarios after tuning rather than rerunning everything after every edit. These are simulation budgets, not already completed tests. Human enjoyment and 20–35% run-win targets need observed human play, initially 5–10 runs where practical.

## GDD coverage

| GDD sections | Delivery |
|---|---|
| 1–2: requirements, fantasy, pillars | Project contract and every phase gate |
| 3–5: loop, countries, roster | Phases 2–3; full stages in 5; countries in 6 |
| 6–8: cards, offers, economy | Phases 2–3; full weights/schedule in 5; historical coverage in 6 |
| 9: tactics, subs, coaching | Phase 2; coaching in 3/5 |
| 10–11: timing, football, simulation | Core in 1; tiebreakers in 3; complete rules in 5 |
| 12: opponents, difficulty, counterplay | Scouting in 3; full templates in 5/6; calibration in 7 |
| 13: presentation, audio, accessibility | Baseline in 1; each screen's phase; complete review in 6 |
| 14: index, records, persistence | Phase 4; historical polish in 6 |
| 15–16: example and content scope | Scenario input and phase boundaries, never claimed playtest evidence |
| 17–18: architecture, validation | Checks introduced with each behavior; broad calibration in 7 |
| 19–20: milestones, risks, proposals | Expanded here; proposals remain provisional |

## Risks and decision triggers

| Risk | Response / when to revisit |
|---|---|
| Match unreadable or dull | Keep Phase 1 open; inspect seeded outliers and player shape before new progression |
| PAC/OVR overwhelms context | Test same chance with different attributes, plus strong player/bad chance versus weak player/good chance |
| Save feature requires major rewrites | Keep simulation state explicit from Phase 1 and add snapshot equivalence in Phase 4 before expanding rules |
| Candidate pools exhaust | Validate constrained role/band pools and owned/released exclusions; extend content before treating fallback as normal |
| One tactic or OVR-only draft dominates | Compare varied squads and simple strategy bots, then human observations; adjust shared rules rather than hidden player-relative difficulty |
| Historical data/portraits consume project | Fictional first; sources/confidence and replaceable fallbacks; no automatic scraping dependency |
| Late rule complexity destabilizes matches | Add small authored rule scenarios in Phase 5 and replay existing regression seeds after each task |
| Existing proposals conflict with feedback | Record the changed rule and rationale before updating tuning/task acceptance; preserve versioned record comparability |

No blocking question prevents the prototype. Confirm proposed rules as relevant phases are requested; avoid treating tentative content quantities, exact colours/fonts, or balance formulas as immutable requirements.

## Codex session prompts

Start the first playable milestone:

> Implement Phase 1 of Eleven Again from tasks/plan.md and tasks/todo.md. Follow AGENTS.md and DESIGN.md, use the applicable EngineeringSuite workflow and Ponytail, and work in this Godot project. Start with task 1.1, implement coherent slices in order, verify with Godot and actual screenshots, update task evidence, and make local Git checkpoints. Stop at the Phase 1 gate. Keep the GDD's later systems out of this milestone. Do not push unless I authorize it.

For a shorter session:

> Implement task [ID] from tasks/todo.md. Read its source GDD sections and existing code, satisfy its acceptance criteria, run relevant checks, update evidence, and checkpoint locally. Stop after that task; report the next dependency-ready task.

For a later phase:

> Implement Phase [N] from tasks/plan.md using its task checklist. Inspect current code/Git state first and preserve unrelated work. Follow the project instructions, verify the prior gate, and split any oversized task. Complete and verify this phase, update evidence, and stop at its gate. Report any design proposal that needs my decision before dependent work.

## Current handoff

Completed scope: Phase 0 planning and local version-control setup. Gameplay remains unimplemented. Next task: **1.1, first runnable match board**. Task evidence, not this narrative, is the source of implementation status. No pushed branch, CI run, gameplay test, render review, export, or human playtest is implied by this plan.
