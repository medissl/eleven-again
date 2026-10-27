# Copy this request into the Eleven Again implementation chat

Revamp the existing game's presentation into one coherent visual system based on these references. The user particularly approves the typography and hierarchy of the halftime image. Carry that identity across gameplay, score, controls, pause/menu, settings, statistics/log, goal, halftime and full-time/result presentation. This is a UI/animation task; preserve authoritative football and unrelated ongoing work.

## References to open and inspect first

All are in `C:/Users/media/OneDrive/Documents/eleven-again/outputs/ui-refresh-reference-v3/`:

- `gameplay-reference.png`: live scoreboard, controls, pitch and event-column composition.
- `pause-reference.png`: pause-menu composition, type hierarchy and button treatment.
- `goal-reference.png`: on-field broadcast-style celebration with confetti; no bordered modal.
- `halftime-reference.png`: approved typography, score/stats/event comparison and primary action.

These are generated design references, not verified engine screenshots or assets to display as one background. Some generated names, token placements, and proportions are illustrative. Real roster, score, events and statistics always come from game data. Preserve the actual 105:68 field aspect ratio rather than distorting it to match a bitmap.

## Work method

Read AGENTS.md, DESIGN.md, tasks/plan.md and tasks/todo.md; inspect latest source and Git status. Preserve current work. Integrate this request into the single task list and implement in coherent verifiable slices, beginning with the shared theme/live HUD, then menu/summary states and event animation. Keep the football research/timing work separate from this presentation change. No push or deployment is requested.

## Shared type and visual system

- Use the halftime image's condensed confident headings/scores and readable interface body typography everywhere.
- A practical font starting point is **Barlow Condensed Bold/Semibold** for headings, team names and numerals, **Barlow Condensed Bold Italic** for GOAL, and **Inter Regular/Medium/Semibold** for body, names and buttons. These are suggested approximations; an AI image does not identify a real font. Obtain files from their official distribution, keep licences, check required glyphs and package locally. Do not depend on a network font at runtime.
- Build one reusable Godot Theme, with named font/colour/spacing roles. Aim for forest `#101E1A`, ivory `#EFE9D9`, muted coral near `#ED7864`, restrained amber focus, and subtle separators. Verify actual contrast rather than trusting candidate colours.
- Use tabular/stable-width score and clock numerals. Avoid huge letterspacing on ordinary body text; reserve spaced uppercase for short section labels.
- A 720p starting scale: body 16–18px, team labels 22–26px, live score 38–46px, summary score 64–84px. Goal/pause hero type scales to available pitch/screen area. Adapt at 1080p and enlarged UI; no tiny text or clipped long names.
- Warm-ivory filled primary button with dark text, quiet text/icon secondary actions, thin separators and an obvious focus ring. Avoid a separate thick gold-outlined rectangle around every element.
- No spectators, stadium scenery, redundant in-match game title, prototype footer, permanent stats table or kickoff/restart/quit toolbar.

## Native implementation

Reuse existing `match/match_view.gd`, `ui/match_hud.gd` and scene/theme patterns after inspecting them. Use native Controls/containers, a small presentation overlay layer, draw primitives/Polygon2D for ribbons, Tweens for movement/opacity, and capped CPUParticles2D or a simple pooled effect for confetti. Add a new file only when it makes a concrete responsibility clearer; do not replace the architecture with a generic animation framework.

Every label, button, counter and state must function. Do not ship the mockups as flat screens, invent event rows to match them, or add unsupported future settings/main-menu/run features merely to populate an image.

## Live gameplay, score and controls

Keep the full field as the largest element and put one compact team/score/clock composition above the pitch, centred relative to the field. Ivory/coral kit identifiers accompany the team names. Place pause, selected 1×/2× and Menu above the right column. Selected speed uses the reference's ivory-fill state; keyboard focus remains distinguishable.

Use a narrow right live-feed column with concise real event rows, correct icons, short actor/type lines, breathing room and a quiet All events action. Keep team identity visible through colour plus shape/pattern. Names sit below players and future trait labels above them, without moving labels wildly every frame. The ball remains high-contrast.

Statistics and secondary tools open on demand. Actual score must update once from the goal event, never from a visual animation ending.

## Pause and related menus

Use the pause reference's full-screen dimmed-pitch takeover, left title/current score/period and a right action column. Resume is the primary ivory button. Match details, Event log and Settings are quiet navigation rows; restart/return/quit are separated secondary actions.

Only show supported actions. Restart belongs to exhibition mode and requires confirmation; it must not become a free roguelike reroll. Return-to-menu appears only when that actual flow exists. Style any existing main menu with the same theme, while keeping the game title out of the live HUD.

Opening the menu pauses immediately, traps keyboard focus and remembers previous playback state. Escape restores that state; explicit Resume starts play. Nested panels return to the correct parent, never advance simulation, and restore focus. If opened from halftime, back/escape returns to halftime rather than silently starting the second half. Use a roughly 150–200ms fade/short entrance; avoid long menu motion.

Apply the same hierarchy to settings, event log and match details. Use supported controls, clear Back actions and no duplicated score headers. No dead buttons or giant unstructured text walls.

## Goal animation

Follow `goal-reference.png`: oversized ivory condensed/italic **GOAL!** directly over the pitch, coral/appropriate scoring-team diagonal sweep behind it, scorer and minute below, and a visible but capped ivory/team-colour/brass confetti burst. This is an emotional broadcast moment, not a normal centred bordered dialog. Keep the sidebar/header calmer and avoid duplicating a full GOAL sentence in the tiny clock.

Suggested normal-speed sequence within the existing authoritative goal stoppage:

1. 0–150ms: gentle local backdrop dim and diagonal sweep enters.
2. 100–300ms: GOAL slides a short distance and eases from about 0.94 scale to 1.00; scorer line fades in.
3. Around 100–900ms: emit confetti once, capped around 40–70 simple particles, lifetime roughly 0.8–1.4 seconds. Preserve actual net/scorer reaction where available.
4. Hold a readable beat, then fade/sweep out over roughly 200–300ms, aiming for about 2.0–2.5 seconds total at 1×. Adapt the presentation to the available goal phase at 2× rather than restarting or extending football ticks.

Use ease-out rather than repeated bounces/shakes. Confetti stays in the pitch area, avoids key text, and fully clears on new match/exit/restart. Keep the camera fixed. A reduced-motion alternative uses a static heading plus fade with no particle burst.

Consume the real goal event once by stable identity. Repeated HUD refresh, pause/resume, opening a menu or changing speed must not replay it. Cosmetic RNG must not consume gameplay RNG. Coordinate with existing dead-ball timing so there are not two separate consecutive celebration waits. Do not let an animation decide a score, restart team, reward or outcome.

## Halftime

Follow `halftime-reference.png`: a full-window dimmed-pitch summary, one prominent team/score composition, a left statistics comparison and right key-moments list. No generic bordered modal and no duplicate prominent live scoreboard behind it. Use a small possession info tooltip instead of printing the long denominator explanation in the main screen.

Use the actual first-half snapshot: possession, shots/on-target, saves, passes completed/attempted, scorers and meaningful events. Show an empty-state sentence only when that category is truly empty; never list two goals and then say there were no goals. The score and stats must agree.

On entry, stop at the true half boundary. Fade the backdrop around 180ms, reveal score/columns with a short 150–250ms entrance, and use only a subtle row stagger if desired. This is a persistent pause: **Continue second half** is the clear primary action and receives focus. No countdown or auto-resume. Continue commits once, cancels any remaining decorative tween safely and starts the correct half; the menu remains available without advancing play.

## Full time and remaining match states

Reuse the halftime composition for final score/result, statistics and key moments, with a primary Continue appropriate to the existing flow. Distinguish extra-time and penalty-shootout tallies when those rules are actually implemented. Use the same type/theme for compact card/substitution cues without inventing unsupported events. Keep results/rewards authoritative and idempotent.

## Verification and completion boundary

- Import/parse and focused native regressions; then actual screenshots at 1280×720 and 1920×1080 for live play, goal, halftime, pause/menu and full time.
- Interact with mouse/keyboard, focus, Escape, nested panels, confirmations and Continue. Test long names, UI scale and supported accessibility options.
- Show the actual GOAL entrance/hold/exit and halftime/menu transitions in motion, not only still screenshots. State if runtime capture/interaction is unavailable.
- Verify pause and 1×/2×/headless event/result equivalence, no duplicate goal/reward/half transition, no lingering particles or tweens after restart, and no simulation steps while halftime is awaiting input.
- Inspect and refine typography, spacing, field fit and collisions against the references. Do not stop at successful compilation or claim the generated images prove the implemented UI works.
- Report the UI changes, exact checks/limitations and the next bounded task. Do not silently proceed into new football systems, content or later gameplay phases just because this request says the whole presentation should be coherent.
