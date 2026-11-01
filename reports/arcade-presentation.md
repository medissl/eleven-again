# Pixel football presentation — 1 November 2026

**Latest continuation:** User feedback reopened this slice: final button/label/icon alignment, selected-state bounds, panel spacing, larger simple goals and restored real whistle are written but have not completed native verification. Automatic approval review could not execute the latest test due usage limit. Earlier passes below are historical evidence. The new master implementation commission continues in "docs/ELEVEN_AGAIN_DESIGN.md"; do not treat this report as final acceptance.

The latest user direction supersedes the earlier neon/glass and chalk experiments: retro-modern pixel football across menus, cards, icons and gameplay presentation, with no further system changes. Targeted follow-up asked for clearer small text/numerals, remade badges and blur behind the persistent opening menu. This is a local Godot source checkpoint, not a pushed build or export.

## Delivered presentation

- One Pixel Operator family with regular/bold text and stable mono-bold numerals. The first Pixelify attempt was replaced after user feedback. Larger card stat labels, one shared frame and purple Legend treatment preserve all card/portrait data.
- Shared navy, grass, cream, gold, coral and purple palette; square pixel frames; palette-based hover/press animation; accessible keyboard focus and reduced motion. No settled-button zoom resampling, bloom, glass backbuffer or foil gradients.
- Generated pixel logo, stadium, road board, pawn, lock, tunnel, reveal field, trophy and40 distinct original crests. All54 images pass palette/import admission. Full prompts, atlas mapping, font licence and source notes are in `assets/ui/arcade/`.
- The opening stadium persists behind management screens with background-only blur. Opaque Settings/drawers prevent old text/scene overlap. Main actions form a game menu rather than dashboard tiles.
- Live pitch geometry, grass, actors, ball, nets and motion render through an isolated pixel viewport. HUD, surnames, numbers and trait labels stay native and readable. All pitch markings, both kit indicators,22 equal bodies and true ball trajectories remain. The shared renderer also supplies replay; formation previews explicitly disable its hidden live pitch layer.
- Original eight-bar arcade menu loop and short interface/gameplay cues; the previous real referee whistle and unchanged crowd recordings remain. No music during live play. Native PCM checks cover audible/non-clipping mix; the new WAV loop boundary was repaired after a failing check.
- Slower position/nation/playstyle/crowd walkout, field rush, card reveal/confetti and **one Confirm** retained. The road shows only current/next opponent, remaining stops locked, and moves the pawn after progress.

## Earlier repairs preserved

`bcf4a4e` checkpointed the earlier authorized behavior work before the final visual-only direction: hidden/inactive outgoing screens, working Settings Back, persistent Collection chrome/focus, separate Squad access, kickoff3–2–1 before whistle/kick, legal loose keeper catches, closer pressing/tracking and differentiated attacking support, actual-time ball trail, own-goal event-team correction and whistle sequence cancellation. Full model runner passed130,614 checks/0 failures before the visual-only slice; it is not represented as a new full-model rerun here.

New runs use `campaign_road_v2` original big-club/national identities. Legacy `campaign_v1` itineraries and opponent strengths remain intact. The old implementation was compared over100 seeds and actual legacy/new disk continuation passed. This changes rival identity/progression presentation, not the economy. Existing saved runs keep their legacy fixtures.

## Native verification actually run

Engine: Godot4.7.2, GL Compatibility, Intel Iris Xe. Tests use disposable `user://` slots; no personal save was reset.

| Check | Result |
|---|---|
| Import and campaign dependency parse | Passed |
| Full connected campaign at720p and1080p | Both passed: all12 wins/rewards,3 defeats, recruitment/market/coaching, preparation, match/pause/results, settings, records, recovery and Continue |
| Font-family/capture audit | Both sizes passed; native captures in `reports/arcade-ui/` |
| Navigation regression |14 checks/0 each size; mouse/keyboard, Settings Back/category disposal, paging focus, road secrecy/current-next bounds, anonymous identity |
| Recruitment |38 checks/0 each size; real input skip/Confirm, transaction idempotency/disk reload, reveal beats and recorded audio |
| Audio |49 checks/0 each size; whistle sequencing, menu/stadium separation, PCM audibility/peak limits |
| Motion |12 checks/0 each size; stable pixel scale, palette feedback, reduced motion, outgoing disposal |
| Native football presentation |26 checks/0 each size; countdown, legal trajectory fixture, no render mutation/RNG changes, bounded trail/reduced motion |
| Squad |219 checks/0 at1080p; all3 shapes, card bounds, reserve/context/drag, legal Auto Build, saved Apply and stale-action rejection; prior720p check also passed |
| Actual buffered replay |18 checks/0 each size; seed42 goal tick9678,240 recorded frames, slow motion and mouse/Escape skip, frozen authoritative state |
| Card/Collection privacy |All200 bindings plus hidden/missing art, search/pages, native inspect/pin/Back/comparison; empty/partial/full Collection and last-page checks passed |
| Artwork |54 imports match opaque PNG pixels,32-colour/binary-alpha admission,40 unique crests, stable score numerals,36 ability icons |
| Separate executable Continue |`nov01_pixel_final`: native Save/exit followed by fresh-process settings restore and exact600-tick future passed |

Actual captures were inspected for menu/background, five recruitment cards, board/crests, Settings, player overview, opponent/Squad, match/kit icons, results and walkout at the two target sizes. Evidence is under `reports/arcade-ui/`, `reports/flow-repair/`, `reports/recruitment/`, `reports/squad/`, `reports/replay/` and `reports/match-audio/`. Layout evidence does not establish human enjoyment.

Controlled180-frame probe: current720p median22.92ms/p9527.07ms;1080p median21.60ms/p9527.21ms. The prior direct pitch renderer with the same current UI measured720p median21.85ms/p9527.52ms on the same session. These short samples show similar cost, **not steady60fps** or a whole-match performance guarantee; measured sustained performance remains open.

## Boundary and next step

The complete connected visual pass is ready for the user's playtest. Preserve this direction and make targeted visual/readability fixes from actual feedback. No more theme pivot, new gameplay rules or economy work is implied. Pending larger tasks: real route choices/deeper roguelike rewards, rerolls/restocks/versioned economy,32 origins, balance, sustained performance/human football evaluation and Windows export. The current road is a fixed itinerary with current/next disclosure, not a fabricated branching system.

Targeted feedback follow-up: original metadata is now wired into origin previews; compact origin cards and full substitute cards clear each other/footer. Larger bold backed surnames, quieter pitch saturation, simple generated net (later enlarged in depth), generated beveled button/panel/node sprites and clearer route links are integrated. Before the last button-margin changes,2,984 native polish checks passed across720p,1080p and two nonstandard aspect ratios; full campaign flow was recaptured at both sizes. The newly added real-pixel glyph-shift check is pending. Keep the crowd as-is and the restored whistle_referee.mp3. No new campaign system was enabled.
