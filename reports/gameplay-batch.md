# Match-system batch — 28 October 2026

The user requested gameplay, AI, tactics, real attributes and all researched signature traits with aura/action feedback, then explicitly confirmed **complete the match systems first**. This delivery stops at the playable match/preparation sandbox. Run progression, recruitment, markets, disk saves and index are separate pending milestones. Regulation remains the confirmed **180 active seconds**, or 90 at 2×, plus stoppages and deliberate halftime.

## Implemented

- Native authored player/card Resources with stable identities, validated integer 1–120 attributes, exact role OVR/familiarity, keeper fields and four v2 tiers. A single effective-attribute path applies the shared +6 cap, role penalty and maximum 12% fatigue penalty once. OVR/tier add no hidden power multiplier.
- Native preparation with legal XI/bench, three formations, nine attack/defence combinations, route/width/late risk, captain/takers, editable penalty order, substitution templates, reserve priority and pinned replacements. Submitted plans are private copies. F5 opens preparation; Standard and Specialists fixture squads collectively expose all 36 traits.
- Coordinated support triangles, elected pressure/cover, direct/possession/counter geometry, interruptible one-two/third-player intentions and comparable legal carry/pass/shot utility. Finite acceleration/turning and actual PAC/PAS/SHO/DRI/DEF/PHY and keeper execution replace seed-random attribute generation.
- Physical ground/curved/lofted passes, crosses/cutbacks, swept first-touch contacts, aerial contests, headers, blocks, saves/holds/parries and live rebounds. A deflection does not create controlled possession or a counterattack. Whole-ball earliest boundary crossing determines genuine goals/throws/corners/goal kicks from actual last touch.
- Actual set-piece receivers/markers/walls, preassigned/fallback takers, direct/indirect restart restrictions, pass-time basic offside and contextual fouls/cards/penalties. Dismissals remove players from pressure/contacts, reshuffle defensive cover and handle trained/emergency GK replacement; fewer than seven resolves one forfeit.
- PHY/work/pressing-dependent match fatigue, three automatic substitution plans, five changes/three windows, no re-entry, role/quality safeguards and fresh entrants. The first suitable reserve follows the submitted bench priority. Historical actor identities remain in events after substitutions.
- All 36 researched automatic trait contracts enhance actual legal action families. One card trait, bounded uses/cooldown/costs, no activation lottery or guaranteed success. Real pass speed/curve, movement/reaction windows, windup and handling/aerial/attribute modifiers drive outcomes. Local rings, short labels, family icons and enhanced ball trails read actual state/events; effects/reduced motion never consume gameplay RNG. Inapplicable roles and dismissed players cannot activate.
- Optional knockout profile: two 30-active-second extra-time halves, carried fatigue/cooldowns and one additional trait use, then physical shootouts only if still tied. Early clinch and paired sudden death, equal eligible taker counts, physical keeper holds/parries and still-moving penalty rebounds, separate tallies/statistics and honest result labels. Exhibition draws remain available.
- Engine-versioned plain-data match snapshots include private plans/cards, ball/curve, pending offside/windup, discipline/cover, substitutions, trait state, periods/penalties and RNG. Binary round trips preserve subsequent match state. This is an in-memory codec, **not disk persistence or a Continue menu**.

The research's 300-second duration was excluded. Overlap Engine's activation fee is provisionally zero because its brief stamina saving under the confirmed duration is smaller than the generic two-point fee; other bounds remain. See [fixture sources and tuning](../content/SOURCES.md). This exception and all trait constants still require calibration.

## Verification

Engine: **4.7.2.stable.official.ed1daf0bf**, GL Compatibility on Intel Iris Xe. Final headless import completed without script errors. Full native runner: **109,763 assertions, zero failures**; focused match-batch runner: **411 assertions, zero failures**. Output was inspected for script errors, not just process exit status.

Coverage includes ownership/bounds, same-seed replay, actual contacts/restarts, paired stat domains, all 36 positive/negative trait eligibility/use/cooldown/RNG contracts, red/GK/forfeit handling, late penalty extension, regulation/ET winners, shootout clinch/sudden death/live rebound, private plan submission, snapshots and subsequent-state equality. Presented 1×/2×/headless match results agree; presented shootout/effects/pause/restart checks also pass.

Paired 60/100 attribute scenarios over 96 seeds:

| Domain | 60 | 100 | Meaning |
|---|---:|---:|---|
| PAS displacement sum | 99.38 | 60.11 | Lower error |
| Difficult DRI receptions | 74 | 85 | More controlled touches |
| Clean DEF wins | 26 | 40 | More successful challenges |
| PHY shielding losses | 34 | 29 | Fewer lost duels |
| REF saves | 39 | 53 | More reachable shot saves |
| HAN holds | 29 | 35 | More secure handling |
| DIV reach saves | 0 | 44 | Different reachable-shot envelope |

PAC, keeper POS/KIC and PHY endurance comparisons plus the existing finishing comparisons pass. These isolated authored cases establish effects, not overall balance.

Full-fixture seeds 11027/42/7/2026 finished 2–2, 1–2, 2–0, 2–3. Simulated active-plus-stoppage durations were 196.5, 196.5, 192.9 and 199.2 seconds at 1×, excluding user report waits. A 20-seed diagnostic sample completed every fixture: mean **3.55 goals, 16.85 shots and 77.25 completed passes**, zero scoreless fixtures. It recorded 71 goals, 48 saves, 13 parries, 21 headers, 135 goal kicks, four fouls/free kicks, two yellows, 156 substitutions and 580 trait activations. There were no natural throw-ins, corners, penalties, offside awards or reds in this small sample; authored rule scenarios cover them. Their frequency and tactical realism are not calibrated. No event is injected to meet a quota.

Native GL frame sequences captured 70 frames at 20fps for 720p 1× and 1080p 2×. Sequence review shows stable camera/surnames, following ball travel and brief local trait identity rather than a fullscreen skill interruption. Still review is limited evidence of animation quality; human playtesting remains necessary. Both-size native captures/input checks cover enlarged preparation/Enter submission and shootout results/Escape/Continue. Authored corner/inspection captures show real routine positions and ball delivery, rather than a synthetic event overlay.

- [720p enlarged preparation](screenshots/preparation-125-1280x720.png), [1080p](screenshots/preparation-125-1920x1080.png).
- [720p substitution controls](screenshots/preparation-substitutions-125-1280x720.png), [1080p](screenshots/preparation-substitutions-125-1920x1080.png).
- [720p authored corner/inspection](screenshots/corner-inspect-1280x720.png), [1080p](screenshots/corner-inspect-1920x1080.png).
- [720p actual shootout result](screenshots/shootout_result-1280x720.png), [1080p](screenshots/shootout_result-1920x1080.png). This authored tied fixture goes directly to shootout, so ordinary match statistics are zero.
- [1× frame-sequence sheet](screenshots/traits-720-sequence.png), [2× sheet](screenshots/traits2x-1080-sequence.png). Full source frames are generated under ignored `.godot/presentation-frames/`.

Reproduce from the project directory:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd -- --batch-only
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/watchability.gd
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --panel=preparation --ui-scale=1.25 --verify-controls
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --panel=preparation --prep-page=substitutions --ui-scale=1.25 --verify-controls
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --scenario=corner --inspect=6
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/capture_match.gd -- --scenario=shootout_result --verify-controls
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/capture_match.gd -- --motion=traits
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/capture_match.gd -- --motion=traits2x --motion-1080p
```

## Boundaries and next work

Basic offside uses circle centres and ball involvement; not every interference-with-opponent or body-edge case is modelled. Height/descent and ground-plane collision are simplified; post/crossbar rebounds, referee delay/encroachment protocols and full 3D anatomy are omitted. Fouls/cards and authored squads/traits are provisional tuning. No human enjoyment, tactical dominance, final performance or exported build is claimed. Sources consulted included official [IFAB ball-in/out](https://www.theifab.com/laws/latest/the-ball-in-and-out-of-play/), [offside](https://www.theifab.com/laws/latest/offside/) and [goal-kick](https://www.theifab.com/laws/latest/the-goal-kick/) rules; this remains a bounded game interpretation.

Match-side tasks 5.1–5.3 and 6.1 were pulled forward for the user's requested batch. This does not complete disk/run gates, suspension service, coaching, historical catalogue or archive-card presentation. Next coherent milestone: **3.2–3.6, the four-win run**, starting with explicit progression/result/reward state. Disk transactions, index and permanent records follow their own tasks.

Local branch: `codex/gameplay-batch`. Earlier checkpoints: `b273f78` (boundaries) and `ec37b37` (preparation/stats/AI/traits). The final checkpoint is recorded by Git history. No push, merge, release or deployment. Unrelated card/research handoffs and packages were preserved. Graphify was queried but this repository was not indexed, so all implementation was grounded in local sources.
