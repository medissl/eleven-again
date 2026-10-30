# Eleven Again — FC Mobile graphic direction, native v6 reference

30 October 2026. The user approved the **neon/glass football direction**, then requested a shared card upgrade, larger stats, white ability icons and consistent typography. This revision uses an original floodlit arena, genuinely blurred glass, clipped illuminated borders, one Saira family, textured perspective Squad pitches and original club crests. The earlier coral images under `rejected-v5/` are historical.

This is an **isolated native Godot design prototype**, including pyramid progression and a provisional money/recruitment/reroll system. F5/main scene, real saves/profile and current campaign economics are unchanged. No migration has been run.

Start with [the visual board](captures/design-board.jpg), [design/system contract](DESIGN.md) and [current-game audit](AUDIT.md).

## Try it

From the project directory:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . res://outputs/fc-mobile-ui-v6/preview.tscn
```

Continue opens the sample pyramid; New run opens the 32-country selector. Squad has native card selection/reserve swaps, nine formation diagrams and tactics/assignment drawers. Preparation shows opponent cards. Rewards demonstrate free signing/cash/rerolls; Market has eight candidates across two pages, two purchases and one restock. Player sheets have a full native card, position/flag rail, stats/trait and comparison. Settings changes only the content pane. Escape closes a drawer before leaving its page.

Numbers, sample roster/records/results and Collection discoveries are isolated design examples, never the actual profile. The extra 26 origins illustrate selection; their final authored rosters are not implemented. Nine formation diagrams illustrate the target; production AI currently implements three. The live reference preserves the complete existing native HUD, shirts and field while demonstrating a blue surrounding skin. Final production match/report integration remains open. Audio sliders illustrate future independent controls; this package supplies no music/SFX or OS key-rebinding implementation.

This deliberately separates a reviewable connected design from changes that could invalidate an ongoing run. The next implementation milestone must use the schema/content compatibility contract in DESIGN.md, not overwrite v1 content or fake cash changes inside UI callbacks.

## Evidence

Native references are in `captures/`, at 1280×720 and 1920×1080. The shared card finish has larger two-column stats, OVR/position/flag rail and 36 white ability symbols with keyboard/hover details. Every visible text role uses Saira, including Sign Hart and all 200 card bindings. Verification covers data/portrait bindings, visible uniform/field pixels, glass opacity pixels, mouse/Tab/Escape, bounds, paging, arithmetic, tabular figures and reduced motion. Final counts/logs are recorded in `verification/` and the linked report.

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://outputs/fc-mobile-ui-v6/verify.gd
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://outputs/fc-mobile-ui-v6/verify.gd -- --1080
```

Native motion previews: [720p settings](captures/settings-motion-720.webp), [1080p settings](captures/settings-motion-1080.webp). The full-opacity outgoing page remains mounted during transitions; categories preserve their surrounding shell. These are prototype checks, not evidence that production navigation was already repaired.

Card references: [all tier finishes](captures/card-finishes-720.png), [36 ability symbols](captures/ability-icons-720.png), [keyboard ability details](captures/ability-details-720.png), [five complete signing cards](captures/reward-720.png).

No balance, human enjoyment, full new-campaign playthrough, export or final visual approval is claimed. Production football's completed physical slice/evidence is [here](../../reports/physical-football.md). `tasks/todo.md` remains the single task list.
