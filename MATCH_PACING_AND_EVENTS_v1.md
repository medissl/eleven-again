# Eleven Again — match pacing and event presentation

27 October 2026. Proposed design addendum responding to the user's concern that one minute is too short. This is a handoff for discussion and implementation planning; it does not change the GDD, current task status, or active code. Three minutes is a recommendation, not a choice already confirmed by the user.

**Latest confirmed scope:** Keep the field-focused match presentation. The user explicitly declined spectators and surrounding stadium decoration. Do not add pixel fans, stands, benches, coaches, stadium construction, or a larger decorative map for this request. This document describes the intended end result; add features within their existing implementation phases rather than expanding the current task indiscriminately. The exact three-minute tuning remains a recommendation for the longer match.

## 1. Recommended timing

Give the player enough time to recognise a shape, follow several possessions, notice a good player, and anticipate the result. Keep 2× as a useful pacing choice.

| Phase | At 1× | At 2× | Displayed clock |
|---|---:|---:|---|
| First half | 90 active seconds | 45 wall-clock seconds | 0–45 minutes |
| Second half | 90 active seconds | 45 wall-clock seconds | 45–90 minutes |
| Regulation total | 180 active seconds | 90 wall-clock seconds | 0–90 minutes |
| Extra-time first half | 30 active seconds | 15 wall-clock seconds | 90–105 minutes |
| Extra-time second half | 30 active seconds | 15 wall-clock seconds | 105–120 minutes |
| Regulation plus extra time | 240 active seconds | 120 wall-clock seconds | 0–120 minutes |

Stoppages, the brief halftime transition, presentation, and a possible shootout add wall-clock time. These are active-play figures, not a promise that the complete viewing experience lasts exactly three minutes. Pause stops the match as usual.

Keep a stable fixed simulation timestep. At 2×, execute twice as much fixed-step simulation per wall second; do not double movement values, change probabilities, or use a larger timestep. Save viewing speed as a preference, not as a random input or difficulty level.

The original 60-second version and a possible 120-second version are useful calibration alternatives. Use one shared tuning value so testing them does not create separate code paths or competition modes. Avoid exposing several duration choices as a permanent game setting before balance supports them.

### Session consequence

A successful twelve-win run has 12–14 fixtures. Three-minute regulation supplies 36–42 minutes of active viewing at 1× or 18–21 minutes at 2×. Management, stoppages, extra time and shootouts add time. The old 30–45-minute overall target therefore cannot remain an unconditional 1× target. A rough planning allowance is 55–80 minutes at mostly 1×, or 35–55 minutes at mostly 2×; measure actual sessions before promising those ranges.

## 2. Balance changes required with duration

Do not just change the match-end constant and declare the longer game balanced.

- **Stamina:** Express the base drain relative to elapsed match minutes/normalised match progress, with movement and pressing modifiers. Preserve the intended end-of-regulation stamina bands. A three-times-longer fixture must not automatically drain three times as much condition.
- **Movement and ball travel:** Keep physically readable field speeds, acceleration, separation, and AI decision frequency. Do not slow all actors to one-third speed to stretch the same minute of action.
- **Shot selection:** Use the additional time for buildup, recycling, defensive shape, and better chance selection. Do not preserve a forced shot-every-few-seconds pattern that triples goals. Fix positional/chance quality problems before adjusting finishing arbitrarily.
- **Chance execution:** Continue resolving the same contextual football actions for both teams. Any finishing/keeping adjustments apply symmetrically; do not cap goals, manipulate late odds, or secretly protect a scoreline.
- **Discipline:** Reassess foul/card frequency against the increased number of challenges. Retain the proposed per-fixture aim of occasional rather than constant cards; tie calls to real challenges.
- **Substitutions:** Trigger plans from displayed minutes, not hardcoded real seconds. A 60-minute substitution now falls at 120 active seconds; 75 minutes falls at 150 active seconds.
- **Trait timers:** State each timer's domain explicitly. Proposed conversion for the old Super substitute window: fifteen displayed match minutes, which is 30 active seconds under this timing, or 15 wall seconds at 2×. The old two-active-second Counter runners window corresponds to three displayed match minutes, now six active seconds. This relative-duration conversion requires retesting: it increases the actual space covered while a burst is active. Neither visual tweens nor wall-clock timers may end gameplay buffs.
- **Run difficulty:** Longer matches can reduce upset variance and amplify stronger squads. Recheck the stage curve and whole-run completion rate instead of assuming the existing proposed OVR ranges are still appropriate.

Initial three-minute texture hypotheses: roughly 80–140 completed passes and 10–18 shots across both sides, with mean total goals around 3–4.5. These are starting observation targets, not score caps or measured results. Football that is understandable and varied matters more than forcing every fixture into a numerical band.

## 3. Presentation direction

Use restrained sports-broadcast motion that fits the forest/ivory tactics-board direction. Emphasise important moments while leaving the live field readable. The scoreboard, feed, and event cues all consume authoritative match events. A visual animation never decides whether a goal, card, substitution, or result happened.

The existing GDD requests short visual/audio cues but does not provide this event-by-event choreography or typography specification. This addendum supplies that missing proposed detail.

### Typography

- Proposed display family: [Barlow Condensed](https://fonts.google.com/specimen/Barlow+Condensed), Semibold/Bold, for short event headings and strong numerals.
- Proposed interface family: [Inter](https://fonts.google.com/specimen/Inter), Regular/Medium/Semibold, for player names, supporting lines and controls.
- These are font-direction candidates, not installed assets. Verify and retain the selected font files' licences during import. The existing bundled readable face is a valid implementation fallback.
- Use tabular numerals for clock and score. Preserve readable diacritics and long-name fallbacks.
- At a 1280×720 baseline: major event titles approximately 36–44px; player/detail lines 18–20px; ordinary event/feed text at least about 16px. Scale for 1080p/UI preferences rather than baking text into images.
- Use one short title and one useful detail line. Examples: GOAL / Amir · 54′; SENT OFF / Bauer · 61′; HALF-TIME / 1–0. Do not add motivational slogans or duplicate journal headings.

## 4. Event choreography

Durations below are initial normal-speed presentation targets. They are not unskippable cinematics. Audio is original or appropriately licensed; every important sound has an equivalent visual cue.

| Event | Visual sequence | Typical normal-speed cue | Audio / retained information |
|---|---|---:|---|
| Goal | Ball crosses line → score updates once → brief net reaction and scorer ring → GOAL ribbon beside/below scoreboard with scorer/minute → fade before obscuring resumed play | 2–2.5 seconds during the restart phase | Crowd swell and short accent; goal remains in feed |
| Yellow card | Small amber card icon near the involved player, plus compact right-side toast with name/minute; mark disciplinary status in inspection | 1.2–1.6 seconds | Short whistle; card icon/type/name retained in feed |
| Red card | Clear red-card icon and SENT OFF label, then a brief departure/fade of that player's marker; a sent-off status remains visible in details | 1.8–2.2 seconds | Distinct whistle/crowd reaction; feed and team status retain dismissal |
| Substitution | Paired incoming/outgoing arrows and two names in the event column; a short field-entry/exit motion at the relevant touchline or simple marker transition | 1.5–2 seconds, one batch for a substitution window | Subtle sideline cue; names and direction remain in feed |
| Halftime | Whistle → action stops → compact central HALF-TIME and score overlay while play is dead → fade → teams take second-half positions | About 3 seconds | Halftime whistle; no required management interaction |
| Extra time | EXTRA TIME with score and 90′ transition; reuse halftime-style typography and motion | About 2 seconds | Short whistle; phase shown in clock/status |
| Full time | Final whistle → final score freezes → FULL-TIME and result line → quiet transition into summary with Continue | 2–3 seconds before the summary settles | Final whistle; result persists until the player continues |

### Important visual details

**Goal:** Preserve the complete pitch; no camera zoom, screen shake, confetti storm, or full-screen flash by default. A scorer/ball reaction and short score-area ribbon are enough. The actual ball crossing and score update precede the celebratory presentation. The net effect must not fabricate a ball path or delay the authoritative goal.

**Cards:** Use a card-shaped icon and explicit label, not colour alone. Away coral kit colours must not make a red card ambiguous. A yellow-card icon on a marker should be small enough to preserve name/number readability. Do not show actual referee cutscenes or a separate portrait screen.

**Dismissal:** Remove the player from authoritative participation immediately when the rules require it. A departing visual ghost cannot tackle, intercept, or keep the ball. Perform the automatic reshuffle from the match rules, not from an animation-completion callback.

**Substitution:** Green incoming and red outgoing arrows also have direction/labels so colour is not the only signal. For several changes, batch them in one compact panel. Commit roster changes exactly once; easing a token onto the field does not control who is legally active.

**Halftime:** It stays watch-only. No redundant kickoff button or forced tactical menu is introduced. The manager can still use ordinary pause/menu controls. The camera orientation and labels stay stable even when teams switch attacking directions.

**Full time:** This is the moment for statistics and summary rather than leaving permanent tables on the live HUD. Show the final score, win/loss/draw appropriate to the currently implemented mode, scorers, and concise statistics. In later run modes, rewards are applied by the run controller, not by a fading banner. A score of 1–1 with a 4–3 shootout has separate score/shootout lines; shootout kicks do not become ordinary goals.

## 5. Timing domains and simultaneous events

Define three timing domains explicitly:

1. Fixed-step simulation time, including deterministic stoppage phases.
2. Active match time, advancing the displayed football clock only during play.
3. UI presentation time, used for fades, focus and menu transitions.

Authoritative dead-ball/halftime durations belong to the simulation and are the same across visible/headless runs. Viewing speed changes how quickly those steps are processed in wall time. Do not let frame rate, animation callbacks, commentary length, or a toast queue add/remove simulation steps.

At 2×, major event sequences should be shorter, but preserve a readable short cue and persistent feed entry. Any visual hold that outlasts its simulation stoppage must remain nonblocking in the header/feed and never obscure live action or delay resumption. Short UI enter/exit easing can have a readability floor independent of the simulation.

Pause freezes match presentation tied to match events; menu focus/hover animations can still operate. Reduced motion replaces sliding/pulsing effects with quick fades or static status. Distinctive audio peaks respect volume settings and should not become startling loudness spikes.

For near-simultaneous events, maintain chronological authoritative entries and use one prominent cue at a time. Prioritise phase/result information, goals, and dismissals over routine events; retain all lower-priority information in the feed. A delayed visual cue must not be interpreted as a second gameplay event. Skip presentation backlog once it would become misleading; never drop the underlying event or its record.

## 6. Where this belongs in the roadmap

- **Current match work / Phase 1 timing and HUD:** Review the three-minute candidate now, before using the one-minute clock as a dependency everywhere. Keep regulation duration configurable in tuning and update clock, pause, restart and speed-equivalence checks when it changes. Basic goal/halftime/full-time cues fit this milestone.
- **Phase 2:** Validate stamina and minute-based automatic substitution thresholds with the new timing.
- **Phase 3 / Phase 5 rules:** Add event cues as extra time, shootouts, substitutions and discipline genuinely become available. Do not fake future events in the current prototype to fill the UI.
- **Phase 6.1:** Review trait timer semantics and save/resume boundaries under the new timing.
- **Phase 6.5:** Finish motion, type, sound, reduced-motion behaviour and presentation consistency across the complete game.
- **Phase 7:** Calibrate actual scoring, tactical advantage, run duration and human watchability.

Send this reference to the implementing Codex now. It should inform the current timing discussion and later presentation work; it should not cause abandonment of an in-progress coherent task or implementation of every later-phase system at once.

## 7. Required implementation verification

- Half ends at 90 active seconds and regulation at 180; display maps correctly to 45′/90′.
- Extra time adds 60 active seconds total and reaches 120′.
- Same committed inputs and seed produce equal supported-build outcomes/events at 1×, 2× and headless speed.
- Pausing, opening menus, reduced motion, muted audio, and skipped effects never change score, events or result application.
- No card/substitution/goal/result is committed twice or triggered from a visual completion callback.
- UI queues do not block a live chance or delay authoritative resumption.
- Stamina and trait timers use their stated domains; substitutions occur at intended displayed minutes.
- Actual 720p/1080p output remains readable for long names, consecutive events, extra time, shootouts, and UI scaling.
- Observe several complete three-minute matches at both viewing speeds. Verify that the extra time adds meaningful football rather than repeating the same failures for longer.

This addendum was checked for time-conversion consistency and compatibility with the current roadmap. It has not been implemented, rendered in Godot, or playtested. Enjoyment and balance remain unverified.

## 8. Existing football scope and set-piece behaviour

Free kicks, penalties, corners, throw-ins, goal kicks, offsides and discipline were already included in GDD section 10. Roadmap task 5.1 covers restarts/set pieces, 5.2 offside, and 5.3 discipline. The prototype's limited restarts are not the intended complete ruleset. This addendum supplies behaviour detail without adding a stadium environment or new manual-control minigames.

| Restart | Required visible setup | Resolution and safe fallback |
|---|---|---|
| Corner | Ball at the correct corner, assigned taker, receivers and markers arrange around the box, keeper covers goal | Automatic short delivery/cross selected by tactics; real ball travel, contests, headers, clearances and rebounds |
| Free kick | Correct foul location, assigned taker, wall when relevant, other players positioned legally | Automatic pass/cross/shot based on range and context; shared ball and shot/keeper resolution |
| Penalty | Ball on the spot, assigned available taker, keeper on goal, other players in prescribed waiting positions | Authoritative kick with actual ball flight; open-play penalties and shootouts have separate rebound/phase rules |
| Throw-in | Correct side and location, one taker and nearby passing options | Ball is delivered into play; no goal awarded directly from a throw and no repeated exit-event trigger |
| Goal kick | Correct defending team and taker; teammates offer outlets | Short or long distribution according to tactics; return to the shared live-ball state once kicked |
| Kickoff | Correct team at centre, valid restart shape, one ball | Automatic restart following goal/phase setup; no additional player-facing Kick off button |

The user remains the watching manager. Preassigned takers and tactics guide these actions; there are no power meters, aiming minigames, or mid-match input advantages.

Use explicit dead-ball → arrange → ready → execute → in-play transitions. Each restart has a unique event ID, a saved owner/team/location, a bounded setup duration, and a legal fallback if the preferred taker is unavailable. A setup cannot wait forever for a player to reach an impossible point. A timeout selects/repositions a valid taker and completes the same restart; it does not invent a goal or reroll an outcome repeatedly.

Offside must use pass-time context and the applicable restart exemptions, rather than treating all forward balls alike. When actual offside rules are implemented, verify them against the then-applicable official laws. The image/reference documents are not a football rules authority.

## 9. Anti-exploit and regression contract for longer matches

No design document can establish that a game has no bugs. These are concrete acceptance checks for the implementing Codex, rather than an unsupported guarantee.

### Clock and phase boundaries

- One authoritative regulation-duration setting determines both halftime and the 0–90 mapping. Extra time derives from the same model: one-third of regulation total, split equally. Do not leave a hidden 60-second timeout in another script.
- Detect displayed-minute thresholds by crossing them, with a one-time flag. Exact float equality is not required for halftime, substitutions, or an effect expiring.
- Phase transitions commit once. Repeated callbacks at a half/end boundary cannot create another kickoff, reward, card or result.
- Specify the whistle boundary before implementing it: ordinary flight/action after a terminal whistle cannot score. A penalty already awarded before time expires may require one final kick; that extension needs an explicit bounded phase and its own test, not an endlessly extended live clock. Shootouts remain distinct from open play.
- Opening a menu, inspecting a card, changing speed, reducing effects, or losing window focus must not advance different gameplay state or alter RNG.
- Holding a live ball, including goalkeeper possession, counts as active time. Only explicit authoritative stoppages pause that clock. A keeper cannot generate unlimited stopped time by remaining in a controlled state.

### Restarts and event ownership

- Process a boundary crossing/foul event once. A ball resting outside a line must not award another corner every tick.
- Maintain one ball and at most one owner. Reset stale possession, pending actions and relevant offside context when entering the appropriate restart.
- Record last touch and awarded team before resetting players. Preserve them through save/resume.
- Use the same chance model for set-piece ball travel and contests where applicable; do not run an additional independent score lottery after the ball has already resolved.
- A save/parry returns a real loose ball only in phases that allow a rebound. A shootout attempt cannot become ordinary live play.
- A red-card departure visual, outgoing substitute, or late tween callback cannot restore a player to participation.

### Attributes, stamina and traits

- Integrate stamina once per simulation step using the stated timing model; a second renderer/UI update must not drain it again.
- Preserve the intended end-of-match stamina profile at both viewing speeds and test normal/pressing/deep approaches separately.
- Apply fatigue/role/trait modifiers in one shared effective-attribute calculation, with the same caps. Never count a printed OVR as another performance multiplier.
- Expire buffs using saved gameplay-time deadlines, not real-time timers or animation completion. Pause and 2× cannot extend a buff's share of the match.
- Trigger recovery traits from a genuine controlled recovery from opposing possession, not a same-team pass, UI refresh, own loose touch, or repeated event delivery. Re-trigger policy must be explicit; refresh an allowed window rather than accidentally adding durations or stacking the bonus without a cap.
- Substitution limits and availability are authoritative. Repeated threshold evaluation cannot replenish fresh reserves or re-enter an outgoing player.

### Rewards, records and difficulty

- Longer play does not change prize values or grant money for extra goals, corners, stoppages, added transitions or shootout kicks.
- Award the run result and checkpoint once, irrespective of how many terminal UI animations or resume events occur.
- A duration change is a balance-version change for comparable records. Do not silently compare goal-scoring records under different match lengths as if they had equal conditions.
- Do not expose a mid-run duration selector that lets players choose a favourable clock for a weak or strong opponent. Keep the selected rules fixed for a committed run.
- Repeat same-seed 1×/2×/headless and interrupted-resume checks after timing changes. Compare the authoritative event/result sequence, not only the final score.
- Run whole-match samples and watch them. More time can amplify superior squads, foul accumulation and repetitive AI; no arithmetic audit alone can establish fair run difficulty.

### Focused scenario list

Test a goal near halftime, a shot in flight at full time, a penalty awarded just before expiry, a corner immediately after a save, a red-carded keeper, simultaneous substitution requests, an unavailable taker, a restart setup timeout, pause/speed toggles during every phase, and saving/resuming during each pending restart. Include no-goal/tied matches and a completed shootout. Each scenario must preserve one valid phase, correct participants, one ball, consistent score/feed, and at most one applied result.

## Sendable implementation note

> Treat this as the end-state pacing/presentation reference. Keep the field-focused view: no spectators or stadium extras. Review a 180-active-second regulation candidate, with 90-second halves and 60 seconds total extra time, preserving fixed-step 1×/2× equivalence. Rework stamina and gameplay-time timers with it, then measure scoring and run difficulty. Use the event choreography/type guidance for goals, cards, substitutions, halftime and full time. Restarts/set pieces are already planned in task 5.1; implement their real state transitions when that milestone is reached. Preserve current work, add focused boundary/resume regressions, and report measured evidence rather than promising no bugs or established balance.
