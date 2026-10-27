# Eleven Again — project design direction

Status: Phase 1 implementation, 27 October 2026. Read `~/.codex/DESIGN.md` for the standing research, critique, and rendered-output workflow.

## Product and player

A mouse-first offline PC football squad roguelike. The manager recruits, assigns roles and tactics, then watches a short automatic eleven-a-side match. Football fans should read the ball, team shape, and a consequential squad choice without specialist analytics. Match movement is the central experience; collecting legends supplies emotional identity.

The intended personality is a thoughtful football tactics board with the warmth of a personal legends album. A successful run's proposed 30–45 minute length and every balance number remain hypotheses.

## Direction and references

Use the GDD's tactics-board/album direction as the starting hypothesis. Its alternative, a spectacle-first card reveal experience, would place attention on rarity rather than football; retain only a brief skippable recruitment reveal. Revisit the direction if real playtests show a mismatch.

Before the first substantial match HUD or recruitment screen, inspect relevant real references through Game UI Database or Interface In Game and official game material. Record 3–5 useful references across the first HUD and album work, what each teaches, and what to avoid copying. The GDD mentions Super Auto Pets, The Last Flame, and Football, Tactics & Glory as gameplay references; those references have **not** been independently inspected for this plan. Do not treat this file as evidence of completed visual research.

Phase 1 references actually inspected:
- [Football, Tactics & Glory: tactical view](https://i0.wp.com/creoteam.com/wp-content/uploads/2020/09/FT_Turn-Based.jpg?resize=547%2C308&ssl=1): clear ball/action relationship. Borrow field readability, not its turn-based grid or floating action controls.
- [Football, Tactics & Glory: whole-pitch view](https://i0.wp.com/creoteam.com/wp-content/uploads/2020/09/FT_Campaign.jpg?resize=547%2C308&ssl=1): complete shape and compact scoreboard. Use a flat camera and keep the score outside the pitch; avoid stadium clutter.
- [Super Auto Pets, official developer page](https://teamwood.itch.io/super-auto-pets): consulted for preparation-led automatic battles and untimed decisions, not as an inspected visual reference. Album-specific visual research remains for Phase 6. Game UI Database was robots-blocked and the attempted Interface In Game page was inaccessible; official material supplied the match references.

Initial rendered palette: background #101e1a, pitch #184d3b/#1b523f, type/home markers #efecda, away #e88670, selection #e9b65e. Use Godot's bundled readable default font until album typography warrants an additional licensed asset. Team distinction combines numbered cream circles with patterned coral circles.

The user approved `MATCH_UI_HANDOFF.md` as the current match target: pitch first, compact team/score/clock, pause/1×/2×/Menu, concise newest-first events, and secondary information behind a modal. The current HUD uses native Godot Controls with generated turf, larger team-patterned discs, green keepers with team rings, and deeper goal frames/netting. Labels now retain a fixed below-player anchor with gentle de-emphasis for crowded secondary names. The football has panel shading, rolling and a small cosmetic touch/bounce, tied to authoritative state. Goal/halftime/full-time header cues and net reactions consume real events.

Current pacing: the user explicitly confirmed three active minutes at 1× and ninety active-play seconds at 2×, plus stoppages. Read `MATCH_PACING_AND_EVENTS_v1.md` for event direction and later timing dependencies. No spectators/stadium extras are part of this view. New HUD and modal layouts were rendered at 720p/1080p; final animation/native interaction review was interrupted when the user stopped Computer Use with Escape. See `reports/phase-one.md` for the precise verification boundary. Audio, larger UI scale and reduced-motion settings remain later work.

## Hierarchy and composition

1. Ball and immediate contest.
2. Team shape and passing options.
3. Score, clock, match phase, and viewing controls.
4. Significant events and concise statistics.

Keep the whole top-down 105×68 pitch visible. Put the scoreboard above it and the live feed beside its right edge. Start near the GDD's 74:26 pitch/details split, then adjust using actual screenshots. A selected player or event may expose details without covering a live chance. Use circular markers, surnames, a clear ball outline, and a quiet possession ring.

Resolve overlapping names by abbreviation and priority; keep the ball carrier and selected player readable. Distinguish teams with pattern/outline as well as kit colour. Goal, card, and substitution cues must agree with authoritative events.

Management screens prioritise the next decision: weak position, comparison, funds, consequence, confirmation. A recruitment row of five comparable candidates is justified by the choice; unrelated decorative cards are not. Show roster replacement before commitment and retain funds/squad when inspection is cancelled.

## Visual materials

### Saved card direction for later phases

The user supplied `CARD_DESIGN_HANDOFF.md` and the references under `outputs/card-design-reference-v1/` for future card/album work, not implementation in Phase 1. Read the actual handoff when starting card Resources, recruitment/market cards, squad cards, or the index. Use a flat reusable native 5:7 archive card: clipped corner, album spine, era stamp, separate photographic cutout, prominent OVR/role, surname, country text/flag, band text/pattern, optional trait, and PAC/SHO/PAS then DRI/DEF/PHY. Keep three-digit values readable. Ivory/brass Legends, forest ordinary cards, and anonymous undiscovered silhouettes share one shape and equal size. Concept ratings are illustrative, and portraits retain their source/permission records. Preserve hidden identity and missing-portrait fallbacks. Assets and the original handoff remain user-owned references; do not replace them with generated whole-card images.


Use deep grass greens for the field, charcoal for supporting panels, warm off-white for readable type, and restrained amber for decisions and milestones. Exact colour tokens and fonts will be selected against real rendered contrast checks during Phase 1, then reused through a Godot Theme. Keep semantic state colours distinct from team kits.

Use a readable sans serif for names, instructions, and data, with stable-width score/clock numerals where available. A display face may add album character after licensing and readability are checked. Avoid portraits as the only identity cue: initials, silhouettes, full names, era, role, and rarity text must work without images.

Keep the pitch flat and readable. Decoration, texture, crowd effects, and rarity effects earn their place through better recognition or feedback. Avoid licensed crests, kits, photographs, or commentary as dependencies of the first playable build.

## Interaction and accessibility

- Mouse-first, complete keyboard navigation for menus and choices; visible focus and clear selected/disabled states.
- Space pauses, Escape opens pause/settings; speed controls are remappable. Watching controls do not unlock live managerial changes.
- Pausing freezes simulation and allows inspection. Hover information also has a select/focus equivalent.
- Minimum functional layout: 1280×720. Inspect 1920×1080 too, including scaled UI and long player names.
- Combine colour with labels, outlines, patterns, or icons. Rarity uses band text and a border pattern.
- Support independent music/effects levels, reduced motion, windowed/fullscreen, UI scale, and feed equivalents of important audio.
- Brief goals and recruitment cues should explain state; reveal animations are skippable and decisions have no timer.
- Undiscovered index slots remain anonymous, including hover/focus text.

## Acceptance for visual tasks

Run the actual scene, capture both target sizes, inspect composition and name collisions, and interact with changed flows using mouse and keyboard. Check that pitch, ball, score, feed, and focus remain understandable under motion and UI scaling. Record concrete defects, refine the largest ones, and recheck. Measure frame time on the actual PC when meaningful.

Store a small set of useful screenshots and findings in the relevant task evidence; do not generate a gallery for every minor edit. Use the global design scorecard as a critique tool, never as a substitute for playtesting. A screenshot proves layout, not match enjoyment or tactical quality.
