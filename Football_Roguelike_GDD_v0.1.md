# Football Squad Roguelike — Game Design Document

Version 0.1 • 27 October 2026 • Design proposal for review

**Working title:** Eleven Again. This is a placeholder; the user has not chosen a name.

**Pitch:** Assemble an ordinary country-origin squad into a team of all-time greats, set its tactics, and watch one-minute football matches as you chase a world championship in a single, disposable run.

**Balance status:** The rules and starting numbers below form a coherent baseline. No match engine exists yet, and no simulated or human playtest has established that these numbers are balanced. Economy arithmetic and probability checks are documented separately. Numerical targets are acceptance criteria, not measured results.

## 1. What is fixed, and what this document proposes

### Confirmed user requirements

- An installed PC game built in Godot, initially for personal use.
- A football squad-building roguelike.
- Choose a starting country and receive an average fictional squad.
- Recruit real football names and legends from roughly 1900–2026 alongside fictional players.
- Set the lineup and tactics before a match; watch players execute them automatically.
- A top-down full pitch with circular player markers and names.
- Approximately one minute of live play representing 90 match minutes, with extra time to 120 when tied.
- Scoreboard and live commentary covering possession changes, tackles, saves, goals, cards, and substitutions.
- Pace, shooting, passing, dribbling, defence, physical, and OVR, with 120 as the attribute ceiling.
- Periodic recruitment offers: choose one player from five.
- Match wins earn money, spent on players at later market checkpoints.
- A run ends with its squad and money erased. Persistent records and a silhouette-based player index are desirable.

### Proposed decisions made to complete the design

- Twelve victories win a run; the third defeat ends it.
- Three chapters of four victories, rather than a full multi-season league simulation.
- A country-origin invitational squad can recruit any nationality.
- Every match resolves to a win or loss, using extra time and penalties when necessary.
- Eighteen-player squad limit, automated substitutions, match-only stamina, and simple suspensions.
- No salaries, injuries, player ageing, duplicate fusion, or permanent gameplay upgrades in version one.
- Nine recruitment checkpoints, three markets, and two small team-wide coaching choices per successful run.
- All figures in this document are tunable without changing the central concept.

These proposals are not being represented as decisions already approved by the user. This document defines a complete candidate design so changes can be evaluated concretely.

## 2. Player fantasy and design pillars

The player is the manager who recognises a useful footballer, assembles complementary roles, anticipates an opponent, and sees a plan work on the pitch. Famous players provide emotional excitement; ordinary specialists must still have tactical value.

1. **Football you can read.** Shape, space, possession, and the ball explain the result. The circles represent the authoritative match state.
2. **Recruitment with consequences.** One great striker competes with a needed defender or goalkeeper for the same signing opportunity.
3. **A different eleven each run.** Offers, opponents, and coaching choices create variation. Memorising one perfect roster is insufficient.
4. **Management before kickoff.** Success rewards squad decisions and preparation rather than reflexes or live micromanagement.
5. **Temporary power, permanent memories.** Every squad disappears. The index and records preserve the story without increasing starting power.

**Audience:** The user and other football fans who enjoy team-building, short automatic battles, and recognisable player identities. No knowledge of advanced football analytics is required.

**Session target:** A successful run takes approximately 30–45 minutes once familiar with the game; first-time reading can take longer. Matches supply 12–14 minutes of regulation active play, plus extra time, stoppages, and management. This is a pacing hypothesis to measure.

## 3. The complete core loop

1. Start a run and select a country.
2. Receive sixteen fictional players and $8 million.
3. Choose one opening recruit from five candidates, each 75–79 OVR.
4. Inspect the next opponent, assign the XI, select tactics, and configure automatic substitutions.
5. Watch the match. Pause and speed controls affect viewing only.
6. Win: receive the stage prize, advance one victory, and resolve any checkpoint reward.
7. Lose: mark one defeat and return to preparation for the same stage, unless it was the third defeat.
8. Repeat until twelve wins or three defeats.
9. Show the run summary, update the index and records, and offer a new run.

**Why losses do not advance:** A player must actually overcome each competition level. Losses are learning opportunities, not a way to farm recruitment or skip difficult opponents.

**After a loss:** Keep money and players. Restore match stamina. Apply and serve suspensions according to the completed fixture. No prize, recruitment, market refresh, or coaching reward is granted. The opponent's roster and starting tactics remain the same; a new attempt seed gives a new match rather than an identical replay.

**Boss rule:** Chapter finals use the same defeat allowance as other matches. There is no surprise instant elimination and no defeat-counter reset between chapters.

**Length bound:** A successful run contains 12–14 fixtures. A failed run can contain at most 14 fixtures: eleven wins and three losses. There is no endless mode in the initial design.

## 4. Country identity and competition structure

### Country selection

Country determines starter names, origin, kit colours, and presentation. All initial countries have comparable squad strength and identical starting cash, squad size, and signing access. Nationality itself gives no statistical bonus.

The squad is a fantasy invitational team originating in that country. It is not a real national team governed by international eligibility. An Indonesian-origin squad may recruit a Brazilian forward, a French midfielder, and an Italian defender.

This preserves country identity while allowing the all-era dream squad the game is about. It also avoids making the most famous football countries mechanically superior choices.

### Three chapters

| Chapter | Victories required | Competition fantasy | Main lesson |
|---|---:|---|---|
| Grassroots | 1–4 | Local challengers to regional champions | Replace weak links and establish a workable shape |
| Elite League | 5–8 | Professional opposition to elite league champions | Build a coherent tactical identity and useful bench |
| World Invitational | 9–12 | International all-star opposition to world champions | Adapt to strong specialists and finish the squad |

The Elite League evokes a top domestic league. The World Invitational evokes a world championship. These are fictional competitions in one compressed run, not a literal Premier League season followed by a national-team World Cup.

### Stage and reward schedule

OVR ranges below describe the opponent's legal starting XI before match effects. They are initial difficulty inputs, not a guarantee that every team at that OVR is equally difficult.

| Next win | Opponent XI OVR | Win prize | Checkpoint after victory |
|---:|---:|---:|---|
| 1 | 61–63 | $4m | Recruit one of five |
| 2 | 63–65 | $4m | Recruit one of five |
| 3 | 65–67 | $4m | Recruit one of five, then Market I |
| 4 | 68–70 | $4m | Regional final; choose first coaching principle |
| 5 | 71–73 | $7m | Recruit one of five |
| 6 | 74–76 | $7m | Recruit one of five |
| 7 | 77–79 | $7m | Recruit one of five, then Market II |
| 8 | 80–82 | $7m | Elite League final; choose second coaching principle |
| 9 | 83–85 | $10m | Recruit one of five |
| 10 | 85–87 | $10m | Recruit one of five |
| 11 | 88–90 | $10m | Recruit one of five, then Market III |
| 12 | 91–93 | $10m | World final; victory summary |

There are no functionally useless recruit or coaching screens after the final victory. The final prize is recorded as earnings even though the run ends immediately.

**Reward ordering:** Record result → prize → recruit if scheduled → market if scheduled → coaching if scheduled → next opponent preparation. An interrupted reward resumes at the unresolved step.

**Variation without a sprawling map:** Each stage draws from two or more authored opponent styles within its power band. The upcoming opponent is revealed before preparation and before entering the preceding market. A boss is selected and revealed at the start of its chapter. No optional route map is required for version one.

## 5. Starting roster, squad size, and lineup rules

### Starter roster

Sixteen fictional players: two goalkeepers, two centre-backs, two fullbacks, four midfielders, four wide/attacking players, and two strikers. Some have secondary positions so all supported formations are initially viable.

- Starting outfield attributes are generally 50–72, producing primary-position OVR around 58–64.
- Bench players generally rate 55–62.
- Every squad has at least one functional passer, one faster attacker, and one reliable defender.
- The opening 75–79 recruit creates an immediate focal player without replacing the entire team's importance.
- Aim for a starting selected XI around 62–65 after that recruit. Rebalance countries to this band rather than giving each an identical roster.

### Squad limit

Maximum eighteen players: eleven starters and seven reserves. Start with seventeen after the opening recruit. The first victory's recruit fills the eighteenth place; later signings require replacement unless a player has already been released.

Recruitment previews allow comparison and a proposed release before confirmation. Cancelling a purchase or inspection never releases anyone. A full-squad signing commits the acquisition and release together. Released players provide no money and do not return during that run.

There are no player sales in version one. This removes free-recruit resale loops and keeps money focused on match earnings. Trading can be reconsidered later if it adds worthwhile decisions.

### Position rules

Positions: GK, LB, CB, RB, DM, CM, AM, LW, RW, ST. Supported formations:

- 4-3-3: back four; DM and two CM; LW, ST, RW.
- 4-4-2: back four; two CM and two wide midfield roles; two ST. Familiar wide attackers can fill the wide midfield roles.
- 4-2-3-1: back four; two DM/CM; LW, AM, RW; ST.

Natural positions use full attributes. Authored familiar positions multiply execution attributes by 0.95. Unfamiliar outfield positions multiply them by 0.85. The UI shows this adjustment and affected slot OVR before kickoff. These are execution and positioning penalties, not permanent changes to the card.

A defender can play upfront in an emergency, but a high headline OVR should not make it a good general strategy. Goalkeeper familiarity is separate: an untrained outfield goalkeeper uses an emergency keeping rating of 35 before fatigue, rather than inheriting elite keeping from outfield OVR.

Kickoff requires eleven available players and one assigned goalkeeper. When suspensions make eleven impossible, provide anonymous one-fixture academy replacements at 48 OVR. They cannot be kept, sold, or used to discover collectible cards. This prevents an administrative soft lock while leaving the sporting disadvantage visible.

## 6. Player cards, historical versions, and ratings

### Identity

Each player has a person ID, a card-version ID, display name, country, era/year, natural/familiar positions, attributes, and at most one signature trait. Historical cards represent a particular football period, such as a specific season or tournament.

Two versions of the same person may exist in the overall database. A run may own only one. Recruitment and markets exclude all versions of an already owned or released person. A candidate cannot appear twice in the same offer. Opponents may field a different instance of a player the user owns; this is a fantasy competition, and roster uniqueness applies within a squad.

Years 1900–2026 describe the intended long-term roster coverage, not a commitment to include every famous player in the first build. Early-era ratings are authored interpretations with a source/confidence note, not claimed official FIFA ratings.

### Core attributes

Every attribute is an integer from 1 to 120. Starting and collectible content uses a narrower practical range, with 115–120 reserved for exceptional versions or specialties.

| Attribute | Main uses | Important limitation |
|---|---|---|
| PAC | Acceleration, top speed, recovery runs | Does not determine pass selection or tackling skill |
| SHO | Placement, shooting execution, penalties | Poor distance and angle still make a shot difficult |
| PAS | Pass placement, execution, distribution | Cannot make a blocked lane automatically safe |
| DRI | Control, turning with the ball, resisting a challenge | Does not confer defensive awareness |
| DEF | Marking response, tackle execution, interception reaction | Does not directly make a player physically faster |
| PHY | Strength, aerial contests, stamina endurance | Does not replace finishing technique |

Goalkeepers retain those six fields for distribution and movement, plus REF, HAN, POS, DIV, KIC: reflexes, handling, positioning, diving, and distribution. No hidden super-stat is inferred from a famous name.

### OVR

OVR is a weighted summary for a role, not a separate match-power multiplier. The match uses attributes and context. Round the role-weighted total to the nearest integer and clamp to 1–120.

| Role | PAC | SHO | PAS | DRI | DEF | PHY |
|---|---:|---:|---:|---:|---:|---:|
| ST | .15 | .40 | .05 | .20 | .00 | .20 |
| LW/RW | .25 | .20 | .20 | .25 | .00 | .10 |
| AM | .10 | .25 | .30 | .25 | .00 | .10 |
| CM | .10 | .10 | .35 | .20 | .15 | .10 |
| DM | .10 | .05 | .25 | .10 | .30 | .20 |
| CB | .15 | .00 | .10 | .05 | .40 | .30 |
| LB/RB | .25 | .05 | .20 | .10 | .25 | .15 |

GK OVR = .30 REF + .25 POS + .20 HAN + .15 DIV + .10 KIC.

Headline card OVR is for the authored primary role. The lineup shows role-adjusted OVR. Do not apply an OVR bonus on top of attributes; that would count strength twice.

### Card strength bands and market prices

These bands are gameplay power bands, not a historical judgement that an unfamiliar player was worse than a modern celebrity.

| Band | Primary OVR | Price range |
|---|---:|---:|
| Foundation | 1–64 | Not offered in the market |
| Prospect | 65–74 | $3–5m |
| Professional | 75–84 | $6–10m |
| Star | 85–94 | $12–20m |
| Icon | 95–104 | $24–38m |
| Legend | 105–114 | $45–65m |
| Apex | 115–120 | $80–95m |

Within a band, interpolate price linearly by primary OVR and round to the nearest $1m. No hidden popularity premium or random price multiplier. Legendary names can have multiple era versions in different bands. Card colour has a text label and border pattern so it is not the only signal.

### Signature traits

Traits add a small, conditional identity; they do not replace football. One trait per card, with no duplicates stacked on the same action. Examples:

| Trait | Effect |
|---|---|
| Poacher | +3 SHO for an open-play shot inside the penalty area |
| Long-range specialist | +3 SHO outside the penalty area; distance penalties still apply |
| Threader | +3 PAS for ground passes originating in the attacking half |
| Ball winner | +3 DEF for standing tackles |
| Press resistant | +3 DRI when at least two opponents are within 5 field metres |
| Aerial presence | +3 PHY in aerial duels |
| Distributor | +3 KIC for a goalkeeper's long distribution |
| Super substitute | +4 PAC and PHY for ten active-play seconds after entering as a substitute |

Cap effective attributes at 120. Across traits and coaching, the net situational bonus to one attribute is capped at +6. Position and fatigue penalties apply after capped bonuses. No cards gain permanent XP or levels during version-one runs; recruitment and tactical composition provide progression.

## 7. Recruitment: one from five

There is one opening offer plus nine victory offers: after wins 1, 2, 3, 5, 6, 7, 9, 10, and 11. Choose exactly one or decline all for no compensation. Unchosen candidates leave; there is no banking an offer for later.

### Offer construction

Five role slots: goalkeeper, defender, midfielder, attacker, and wildcard. A versatile card may qualify for several categories, but each candidate appears only once. This guarantees broad coverage without guaranteeing the exact fullback or midfielder required.

Every card in a regular offer independently draws a power band from the current chapter table, then an eligible person/version within it. Eligibility and duplicate rules apply before sampling. The actual individual-card chance also depends on role pool size; show the band odds, not invented equal chances for every footballer.

| Power band | Grassroots offers | Elite League offers | World offers |
|---|---:|---:|---:|
| Prospect | 25% | 0% | 0% |
| Professional | 70% | 30% | 0% |
| Star | 5% | 60% | 25% |
| Icon | 0% | 10% | 60% |
| Legend | 0% | 0% | 14% |
| Apex | 0% | 0% | 1% |

Opening candidates are an explicit exception: five 75–79 OVR players, one per role slot. There is no opening 120-OVR jackpot.

An Apex chance of 1% per candidate is not 1% per offer. With five independent eligible draws it is approximately 4.9% per World offer, or 14.0% across the fifteen candidate slots in three World offers. Eligibility/fallbacks can change the realised figure. Winning a run must never require an Apex.

No paid/free rerolls, real-money rolls, duplicate fusion, player packs, or pity counters in version one. Offers are created once and saved. Reloading the same checkpoint does not reroll them.

### Fairness rules

- At content-validation time, ensure sufficient eligible players per role and band for all checkpoints.
- If a category-band pool is exhausted, use the next lower nonempty band in that category. If that is exhausted, use any unowned valid player from the chapter's bands and flag the content shortage in development logs.
- A last-resort authored fictional substitute must keep the offer usable; a fallback should be treated as a content defect to fix before the full version.
- Reject procedural offers that contain fewer than five distinct people.
- Do not increase later opponents in response to a lucky signing.
- Recruitment odds never depend on codex completion or previous run success.

## 8. Money and market checkpoints

### Income

Start with $8m. Four Grassroots wins earn $16m; four Elite League wins earn $28m; four World wins earn $40m. A successful run therefore supplies **$92m total**, including starting cash and the final prize. There are no loss payouts, salaries, interest, sell values, or score-based income bonuses.

Money remains a fictional in-game resource. There is no economy outside a run.

### Markets

Markets open after wins 3, 7, and 11, after resolving that victory's free recruit. They close when the next fixture is committed. Each contains eight candidates: one GK, two defenders, two midfielders, two attackers, and one wildcard. Maximum two signings per visit.

| Market | Candidate bands | Power-band weights before role filtering |
|---|---|---|
| I | Prospect / Professional / Star | 25% / 65% / 10% |
| II | Professional / Star / Icon | 25% / 60% / 15% |
| III | Star / Icon / Legend / Apex | 20% / 55% / 24% / 1% |

Keep at least two candidates in the visit's lowest band by replacing higher-band wildcard/attacker slots if necessary. This affordability safeguard means final market-slot odds are not identical to the raw band table. The UI describes the market as a curated selection, rather than advertising independent draw odds.

There are no market refreshes or loans. An unaffordable candidate can be inspected but cannot be purchased. The market preview shows current funds, resulting funds, roster replacement, role coverage, and the next opponent.

### Example budget, not an optimal strategy

| Moment | Cash before spending | Example decision | Remaining cash |
|---|---:|---|---:|
| Start | $8m | No shop yet | $8m |
| After win 3 | $20m | Two Professionals at $8m each | $4m |
| After win 7 | $29m | One Star at $16m | $13m |
| After win 11 | $50m | One Icon at $30m and one Star at $16m | $4m |
| After win 12 | $14m | Run ends | $14m |

This path spends $78m across five players. A saver could instead arrive at Market III with up to $82m and buy an exceptional single player, but would accept weaker earlier squads and miss the most expensive Apex prices. The choice is deliberate.

**Economic guardrails:** All stages must be beatable without purchases; free recruitment supplies the foundation of a run. Shops improve consistency and repair positions. A purchased player should not be compulsory for a particular boss. No reward scales with goal margin, possession, or unnecessary extra time, avoiding incentives to farm statistics.

## 9. Tactics and automatic management

### Pre-match decisions

Choose formation, starters, bench order, captain, set-piece takers, penalty order, attacking approach, defensive approach, and substitution plan. The starting release has three attacking and three defensive approaches, creating nine understandable combinations.

| Attack | Behaviour | Typical strength | Typical cost |
|---|---|---|---|
| Possession | More short support options and patient recycling | Retains the ball and draws defenders out | Can struggle to create quickly against a compact block |
| Direct | Earlier forward balls and aerial deliveries | Reaches strong forwards quickly | More contested balls and lost possession |
| Counter | Conservative support shape until recovery, then forward runs | Attacks space behind advanced opponents | Can leave the striker isolated and concede possession |

| Defence | Behaviour | Typical strength | Typical cost |
|---|---|---|---|
| High press | Closest eligible players close down high; back line advances | Forces hurried distribution | Uses stamina and exposes space behind |
| Balanced | Holds shape with selective challenges | Consistent, moderate risk | No specialised advantage |
| Deep block | Defenders retreat and protect central shooting lanes | Limits close central chances | Concedes territory and allows wide deliveries |

These alter positioning and action preferences. They are not universal percentage damage bonuses. For example, direct play does not simply beat possession because of a matchup table. It benefits when the opponent leaves space or cannot contest the receiving forward.

### Captain and set pieces

Captain is a presentation assignment with no hidden leadership buff in version one. Set-piece takers are selected explicitly, with sensible automatic defaults based on PAS/SHO. Penalty order is editable before kickoff.

### Automatic substitutions

No live managerial decisions are required. Before kickoff choose a template:

- **Balanced:** Up to three suitable outfield changes at displayed 60 minutes; up to two further changes at 75 minutes when tired or trailing.
- **Fresh legs:** Substitute up to three players below 55 stamina at the first dead ball after 55 minutes; use remaining changes after 70 minutes for players below 45.
- **Protect shape:** Changes after 65 minutes favour like-for-like positions, prioritising fatigue over attacking strength.

The manager may optionally pin named replacements and set one pre-match instruction: when trailing at 70 minutes, increase attacking risk within the selected approach. An optional leading instruction reduces attacking risk. No automatic formation change is required in version one.

Five substitutions maximum, across at most three substitution windows, excluding the halftime window. Extra time grants no additional substitution allowance in this simplified ruleset. Replaced players cannot re-enter. Suspended/unavailable reserves and already used players are excluded. The system skips harmful or positionally impossible changes and explains this in the plan preview.

After a red card, an automatic reshuffle preserves a goalkeeper and defensive shape, usually sacrificing an attacking position. If the goalkeeper is dismissed, replace an eligible outfielder with the reserve GK when substitutions remain; otherwise assign the best emergency goalkeeper. All automatic instructions are visible before kickoff.

### Two coaching principles

After wins 4 and 8, choose one of three offered principles from a six-item pool. Both active principles last for this run. No duplicates. They reward a chosen style without making one compulsory:

- Short combinations: +3 PAS on ground passes in the defensive/middle thirds.
- Wide service: +3 PAS on crosses.
- Counter runners: +3 PAC for two active seconds after a controlled recovery.
- First pressure: +3 DEF on standing tackles in the attacking third while High press is selected.
- Set-piece preparation: +3 SHO for direct free kicks and headers immediately following corners.
- Bench impact: +3 PHY for substitutes for the rest of their current match.

All use the shared +6 situational bonus cap. Principles have no cash value, persist through defeats, and never carry between runs. If they do not create understandable decisions in testing, remove this layer before adding more systems.

## 10. Match timing and football rules

### Time model

- Regulation consists of 60 active-play seconds: two 30-second halves.
- The displayed clock maps those seconds to 0–90 minutes.
- If tied, play two ten-active-second extra-time halves, mapping 90–120 minutes.
- If still tied, use a five-kick-per-team shootout, ending early when the result is mathematically settled; then paired sudden death if needed.
- Stoppages and short celebrations pause the active-play clock. There is no added-time calculation in version one.
- Normal-speed regulation should take roughly 70–100 wall-clock seconds including brief stoppages. This is a target, not a guarantee; review matches that routinely exceed it.
- At 2× viewing speed all simulation time advances consistently. Results cannot depend on viewing speed, rendering speed, commentary length, or whether the window is visible.

Halftime is a short automated transition, not a second management screen. Pause, settings, and hover inspection are available without changing tactics or the submitted XI.

### Included football rules

Eleven-a-side, kickoffs, throw-ins, goal kicks, corners, fouls, direct free kicks, penalties, yellow cards, second-yellow dismissals, direct red cards, basic offside, and substitutions. Offside uses the positions at the pass and involvement in play; there is no VAR presentation. Set pieces use short authored positioning routines rather than a separate control minigame.

Header outcomes derive from PHY, position, ball arrival, and pressure; there is no additional heading attribute in version one. Aerial shots also consider SHO. No goalkeeper handling outside the box; the keeper uses outfield execution there.

No injuries, weather, handball modelling, advantage rule, indirect free-kick edge cases, or multi-season disciplinary regulations in the initial complete version. This is an explicitly simplified football ruleset. If a team falls below seven players, it forfeits and records one defeat, subject to the normal run rules.

### Stamina and discipline

Players start every fixture at 100 stamina. Stamina falls during movement and pressing; PHY reduces depletion. High press should typically finish regulation around 40–55 stamina, Balanced around 55–70, and Deep block around 65–80 for active outfielders. These are calibration bands and vary by behaviour and PHY.

Full stamina causes no penalty. At zero stamina, affected movement and execution attributes receive at most a 12% reduction. Interpolate smoothly; there is no sudden cliff. Substitutes enter at 100 stamina. All stamina resets between attempts, including after defeats. There is no between-match recovery purchase.

Three accumulated yellows cause one-fixture suspension; a red card also causes one-fixture suspension. Two yellows in one fixture produce one red suspension, not stacked suspensions. Serving any suspension clears that player's yellow tally. A suspension is served by the next completed attempt, win or loss; repeatedly opening preparation does not serve it. The UI always lists unavailable players before kickoff.

Discipline introduces occasional adaptation, not constant squad destruction. Initial targets: 1–3 yellows per fixture on average, and red cards in fewer than 8% of fixtures. Fouls must be tied to identifiable challenges, not independent surprise rolls.

## 11. Match simulation and trustworthy presentation

### Field and movement

Use a design field of 105 × 68 units. Units represent field metres for spacing, not a claim to simulate a full realistic 90-minute workload in sixty seconds. Use readable acceleration, turning, and ball travel. A higher PAC player moves faster within a bounded range; 120 PAC is not twice as fast as 60 PAC.

Initial movement range: approximately 5.2–8.2 units/second at full stamina, before possession/turning effects. Ground passes generally travel at 18–30 units/second. Tune for readability and player separation. The viewport scales independently of the simulation.

### Football intelligence

Every team has a formation anchor, possession shape, defensive shape, and transition behaviour. Players choose local jobs:

- Ball carrier: pass, carry, attempt a dribble, shoot, or clear.
- Support: provide a nearby option, run beyond, hold width, or protect against a counter.
- Defence: press, mark a threat, screen a passing lane, cover a teammate, or recover shape.
- Goalkeeper: cover the goal, claim/intercept reachable balls, save, hold/parry, and distribute.

Limit the active chase to the nearest suitable presser plus at most one support defender. Other players hold roles; twenty players must not swarm the ball. A teammate should not request a pass through a visibly blocked lane merely because their rating is high.

Action selection scores field context: progress, receiver space, interception risk, shot quality, available support, and team tactics. Use bounded random variation between reasonable actions. Do not make intelligence synonymous with name recognition or headline OVR.

### Event authority

There is one authoritative state for ball position, possession, player positions, actions, score, cards, and substitutions. Rendered movement, commentary, and statistics consume that state.

A pass travels through the field and may be intercepted. A shot can be blocked before reaching the keeper. A save may create a rebound that remains playable. A turnover is not an unrelated commentary line drawn while the ball remains with the original team.

Do not run independent outcome rolls in both animation and commentary. Avoid charging an attack twice for the same pressure modifier. The ball is either controlled, in flight, loose, or dead; two players cannot simultaneously own it.

### Starting execution formulas

These are implementation starting points, to be replaced if measured match behaviour is poor. Inputs use effective attributes after role, trait, and fatigue adjustments. Context variables are normalised as specified.

**Pass placement**

`P(accurate aim) = clamp(0.88 + 0.002 × (PAS − 80) − 0.10 × pressure − 0.18 × length − 0.12 × lane_risk, 0.25, 0.98)`

Pressure, normalised length, and lane risk each run 0–1. An inaccurate aim creates an imperfect ball trajectory; it does not teleport possession to a defender. An accurate ball can still be intercepted by an opponent who reaches its actual path. This is placement probability, not a second complete-pass probability.

**Standing tackle contact**

`P(clean win | reachable challenge) = clamp(0.48 + 0.004 × (DEF − DRI) + 0.12 × support_edge + 0.10 × angle_edge, 0.12, 0.85)`

Support and angle edges each run −1 to +1. Fatigue is already included in effective DEF/DRI and is not charged again. Contact is attempted only when the defender is in reach. Use a per-player challenge cooldown, initially 0.8 active seconds. Foul risk derives from angle, lateness, and challenge context. A tackle is not retried every frame until it succeeds.

**Unblocked open-play shot**

`P(on target) = clamp(0.30 + 0.004 × (SHO − 60) + 0.32 × quality − 0.16 × pressure, 0.15, 0.95)`

`P(save | on target) = clamp(0.90 − 0.65 × quality + 0.003 × (GK_OVR − 80) − 0.002 × (SHO − 80), 0.10, 0.95)`

Quality runs 0–1 and reflects distance, angle, keeper position, and shot type. Pressure runs 0–1 and is applied to placement, not charged a second time during save resolution. Fatigue already affects effective attributes. Resolve physical blocks before on-target/save resolution. Use HAN to decide hold versus parry after a successful save. A parry returns a real loose ball to the simulation. These probabilities may need substantial tuning once a genuine shot distribution exists.

**Shootout/penalty**

`P(score) = clamp(0.73 + 0.0025 × (SHO − 80) − 0.002 × (GK_OVR − 80), 0.50, 0.90)`

Use the on-field takers and fatigue-adjusted attributes. Apply early termination correctly. Outfield players cannot be replaced with a bench specialist during the shootout. Do not include shootout goals in the regulation score, ordinary goal difference, or open-play shot totals.

**Context must matter:** A strong striker should be more reliable than a weak one on the same chance. A weak striker with a clear close chance should still often be preferable to an elite striker shooting from a bad angle under pressure.

## 12. Opponents, difficulty, and counterplay

Opponent templates combine a fixed stage power budget with football identities. They do not use the player's current OVR to choose their own ratings. A lucky signing should feel powerful.

| Opponent style | Visible behaviour | Sensible response, not a guaranteed counter |
|---|---|---|
| High press | Challenges distribution and advances its line | Better passers or direct balls into space |
| Deep defence | Crowds central shooting lanes | Width, crosses, and patient movement |
| Fast counter | Breaks quickly after recovery | Covering midfielders and restraint in committing players |
| Aerial attack | Targets a physical forward | Strong centre-backs and protection against crosses |
| Possession | Creates passing triangles and recycles | Selective pressure and disciplined screening |
| Balanced all-stars | Few obvious weaknesses | A complete squad and appropriate bench |

Scouting reveals formation, XI OVR, standout attributes, style, and one plain-language threat. Example: “Their forwards are quick, and both fullbacks push high.” No match probability prediction is required; a misleading precision percentage would weaken trust.

Bosses have stronger composition and a clearly telegraphed style, not secret rules or arbitrary stat multipliers. They use the same player actions, stamina, cards, and substitution limits. Their roster is saved when generated. Future stage templates do not adapt secretly to punish the user's preferred formation.

After a defeat, show evidence-based observations: attempted versus completed passes, shots and locations, turnovers by zone, and the opponent's main pattern. Start with simple factual statements such as “Six of their eight shots came from the central penalty area.” Avoid claiming that one stat or tactical choice caused the loss without evidence.

### Initial balance hypotheses

- Equal-power, sensible lineups should split resolved wins approximately evenly over many seeds.
- A five-OVR stronger legal XI should have a measurable advantage, provisionally 60–70% resolved wins against comparable tactics.
- A ten-OVR gap should feel large, provisionally 75–85%, without eliminating upsets.
- No tactic combination should dominate all other combinations across varied rosters.
- A competent returning player should eventually win roughly 20–35% of standard runs. This target requires human validation and may change.

These targets are not mutually proven. If the match engine's variance makes a twelve-win run too punitive, change the stage curve or defeat allowance based on whole-run results rather than secretly favouring the player during matches.

**Whole-run probability check:** If every attempt had an independent, constant 75% win chance, the chance of reaching twelve wins before three defeats would be approximately 28.1%. At a constant 70% it falls to 16.1%; at 80% it rises to 44.8%. A sequence of fair 50/50 stages would therefore be far too punishing for this intended experience. Most early fixtures should favour a competently managed player, while late opposition tests the completed build. Actual run probabilities depend on recruitment, adaptation, and correlated squad strength, so this calculation is only a baseline sanity check.

## 13. Interface, art direction, audio, and accessibility

### Chosen visual direction

**A football tactics board combined with a personal legends album.** The match screen prioritises ball and shape. Recruitment provides the emotional reveal. Use deep grass greens, warm off-white typography, charcoal panels, and a restrained amber accent for choices and milestones. Team kits stay distinct from UI status colours.

An alternative considered was a casino-like card spectacle with saturated rarity effects. The recommended direction gives recruitment a brief reveal while keeping the main identity about football management. No slot-machine sounds or lengthy unskippable reveals are needed.

### Match layout

```text
+---------------------------------------------------------------+
| COUNTRY XI       1 – 0       RIVAL XI       67′   Pause  1×  2× |
+------------------------------------------+--------------------+
|                                          | LIVE FEED          |
|               FULL PITCH                 | 67′ Interception   |
|                                          | 64′ Substitution   |
|  circular players, clear ball, surnames   | 58′ Save           |
|                                          | 51′ Goal           |
+------------------------------------------+--------------------+
| Formation / style / substitutions used    | Match statistics   |
+------------------------------------------+--------------------+
```

Scoreboard is above the pitch; commentary occupies the upper-right panel beside it, extending down the pitch edge. Default desktop allocation is roughly 74% pitch area and 26% commentary/details, adjusted to preserve the full field.

- The ball has a strong outline and contrast against pitch and markers.
- The controlled-ball player has a subtle possession ring, not a large flashing effect.
- Surnames sit below circles; short names can appear inside if legible. Hover/select reveals full name and attributes.
- Resolve name collisions using label priority and abbreviation. The ball carrier and selected player retain readable labels.
- Teams use different kit patterns/outlines in addition to colour.
- Goals, cards, and substitutions have short distinct visual/audio cues.
- Never cover a live scoring chance with a reward popup.

### Main screens

| Screen | Required decisions/information |
|---|---|
| Main menu | New run, continue, index, records, settings |
| Country selection | Squad identity, starter preview, equal-start explanation |
| Run overview | Wins, three defeat slots, chapter, money, next checkpoint |
| Squad preparation | Formation slots, bench, comparison, role penalties, automatic plan |
| Opponent scouting | Visible XI, style, threats, next-fixture commitment |
| Match | Field, score, clock, feed, substitutions, viewing controls |
| Result | Score, shootout if applicable, key statistics, prize, next step |
| Recruitment | Five candidates, role/attribute comparison, one-choice confirmation |
| Market | Eight offers, prices, funds, two-signing limit, replacement preview |
| Coaching | Three concise conditional bonuses with current principles visible |
| Index | Discovered cards, silhouettes, filters, biography/era, discovery record |
| Run summary | Outcome, wins/losses, peak XI, earnings, discoveries, notable players |

### Feed and statistics

Default feed highlights goals, saves, tackles/interceptions, fouls/cards, substitutions, and dangerous chances. A detailed toggle includes controlled recoveries and passes. Both consume the same event log. Coalesce repeated low-value actions so the main feed remains readable.

Events carry match timestamp, actors, event type, and location where relevant. Shootout events have their own phase label. Clicking an event may highlight its actors/location while paused; full video-style rewind is outside version one.

### Accessibility and controls

Mouse-first with keyboard navigation. Space pauses; Escape opens pause/settings; speed controls are remappable. Pausing is always possible, but match management stays locked. Support windowed/fullscreen and UI scale; target 1280×720 as the minimum functional layout and inspect at 1920×1080 as well.

Provide readable text sizes, scalable labels, independent music/effects volume, reduced motion, subtitles/feed for all important audio information, and alternatives to red/green-only signals. Recruitment is usable with keyboard focus and has no timed choice. Reveal animation is skippable.

Audio uses restrained stadium ambience, ball contact, whistle, crowd reactions, and subtle recruitment cues. There is no licensed commentary or music requirement. Player portraits are optional data-linked assets with initials/silhouettes as reliable fallbacks.

## 14. Index, records, and persistence

### Index discovery

An entry becomes discovered only when the card version is recruited or purchased. Seeing an opponent or inspecting an unchosen candidate does not unlock it. Owned fictional collectible starters can be discovered too; anonymous emergency players cannot.

Undiscovered entries show a neutral silhouette and an anonymous catalogue slot, not a hidden name revealed by a tooltip. A discovered version shows its portrait/fallback, full identity, era, role, attributes, trait, first discovery date, and runs recruited. Versions sit under a shared person entry; uncollected versions remain undiscovered.

The index never changes recruitment eligibility, odds, starting cash, or attributes. All implemented countries and the complete implemented recruitment pool are available from the first run.

### Records

Primary records: best progress, championship wins, highest achieved valid starting-XI OVR, most goals by a player in one run, and personal run history. The user specifically wanted peak team OVR, so it receives prominent placement.

Peak XI OVR is the arithmetic mean of eleven slot-adjusted card ratings in a saved valid lineup, before temporary coaching, traits, or stamina. Do not count bench ratings or transient buffs. Validate eleven distinct owned people, a legal formation, and one assigned goalkeeper. Exclude emergency academy replacements from eligible record lineups. Store the exact XI and formation with the record.

For comparing best runs, use lexicographic ordering: championship completion first, then wins, then fewer defeats, then peak valid XI OVR, then non-shootout goal difference. Do not hide this behind a complicated composite score.

Records include balance/content version. If later balance revisions materially change power, keep older records labelled rather than silently treating them as directly comparable.

### Saving and resuming

Offline local saving, no account or backend. Keep profile/index/records separate from active-run state. Autosave after country setup, generated offers, committed decisions, completed rewards, and matches. Write atomically and keep one previous valid backup.

At kickoff save the committed XI, tactics, substitution plan, attempt seed, and run state before advancing the simulation. Quitting mid-match resumes that committed attempt or reconstructs it deterministically on the same supported build; it does not reroll the opponent or offer a free new result. Maintain an in-memory/saved event history sufficient to restore the current match. Prefer exact saved match state for resume, with deterministic reconstruction as a tested fallback rather than assuming floating-point cross-version identity.

An intentional abandon ends the run. Starting another run while one exists requires a clear abandon confirmation. Settings and accessibility changes remain available during runs. There is no anti-cheat service; the aim is predictable local behaviour, not policing a personal game.

## 15. Worked example of a run

An Indonesian-origin squad starts with ordinary fictional players and $8m. The manager chooses a 78-OVR midfielder as the opening recruit and uses 4-3-3 Possession/Balanced.

The first offer contains a strong striker and a useful goalkeeper. Since the starter keeper is adequate and the team is failing to convert chances, the manager takes the striker. The next two offers improve a centre-back and a wide player.

After three wins, the team has $20m. Market I shows two affordable Professionals who cover a weak fullback position and the bench. Buying both for $16m leaves $4m. The regional final is won, and the manager selects Short combinations.

In the Elite League, a high-press opponent causes repeated central turnovers. The manager loses once. The result screen shows where the passes were intercepted. For the rematch, the manager selects Direct play and starts a more physical forward. That adjustment helps, though it does not guarantee a win.

By Market II, the manager has $29m and buys a $16m Star goalkeeper. A later recruitment offer contains a more famous goalkeeper and a less famous defensive midfielder. The manager takes the midfielder because the goalkeeper position is already strong.

World recruitment brings the possibility of Icons, Legends, and rare Apex cards. At Market III, the manager spends $46m on an Icon and a Star. The final match goes to extra time. The fresh substitute scores, and the run ends in a championship.

The entire squad and its remaining $14m disappear. Newly recruited card entries remain visible in the index. The record preserves the final XI and the highest legal XI rating achieved. The next run starts with ordinary players again.

This is an illustrative story consistent with the rules, not a simulated result or a claim that the example strategy is optimal.

## 16. Content plan and practical scope

### Match prototype

Two fictional teams, one pitch, core passing/carrying/defending/shooting/goalkeeping, goals, clock, and feed. No historical roster is required to establish whether the football is watchable. Temporarily omitted rules are labelled in development rather than presented as complete.

### First complete short-run slice

One country, four victory stages, three-defeat allowance, one market, recruitment, lineup/tactics, automated substitutions, basic index/save, and a final opponent. Approximately 48 authored card versions are sufficient as a target if role/tier coverage checks pass; the actual number follows those constraints. No promise that 48 arbitrary cards will fill every role pool.

### Initial full personal version

- Full twelve-win structure.
- Six country-origin starter rosters of sixteen fictional cards: 96 fictional starters.
- Approximately 96 historical recruitable card versions, distributed across roles and eras; real names/versions chosen after the design review.
- Target historical power distribution: 8 Prospects, 24 Professionals, 28 Stars, 22 Icons, 12 Legends, and 2 Apex cards. Coverage validation may require redistribution or additional cards.
- Enough goalkeepers, defenders, midfielders, and attackers in each offered band to support generation and duplicate exclusions. Content count never overrides this requirement.
- At least two opponent templates per regular stage and at least two final identities per chapter, using reusable pools and authored fictional fill where needed.
- Eight signature trait types, six coaching principles, three formations, and nine tactic combinations.
- Full match rules, records, index, saves, settings, and readable desktop UI described above.

The full historical span is a content expansion goal. It should not delay testing one complete run. Opponent roster instances do not require a unique portrait and biography for every slot.

### Deliberately outside version one

Online multiplayer, mobile export, a public launch, live football databases, real-money mechanics, transfer negotiations, salaries, contracts, stadium construction, youth academies, injuries, ageing, full career seasons, manual player controls, elaborate skill animations, weather, full match rewind, and endless progression.

These are scope boundaries, not requests to abandon the central football simulation or replace the game with a card-only battle.

## 17. Godot implementation direction

This is a design-level architecture, not an approved engineering task list or a claim that a project has been created. Use Godot with GDScript and a lightweight 2D presentation. Select and record the installed engine version when implementation begins.

| Module | Responsibility | Depends on |
|---|---|---|
| Content catalogue | Player cards, traits, formations, opponent templates, tuning tables | — |
| Squad rules | Ownership, positions, valid XI, OVR, replacements | Content catalogue |
| Match simulation | Movement, decisions, ball, rules, seeded events | Content catalogue, squad rules |
| Run controller | Stages, rewards, defeats, offers, market, coaching | Content catalogue, squad rules, match results |
| Profile/save | Atomic saves, active state, index, records, versioning | Defined state contracts |
| Presentation | Screens, field renderer, commentary, audio, controls | Public state/events of the above |

Keep rendering from deciding outcomes. A headless simulation should produce the same supported-build result from committed inputs and seeds as a visible match. Split random streams for match execution, offers, markets, and cosmetic effects so a portrait animation cannot change who scores.

Initial technical budget: 22 players and one ball; fixed 60 Hz simulation; staggered high-level decisions around four times per second per player; render interpolation where appropriate. Use simple steering, formation anchors, and lane queries before complex pathfinding or machine learning. Tune tick rates only after measuring behaviour and performance.

Content, economy, and tactical preferences should live in data resources rather than being scattered through UI scripts. Store player references by stable IDs. Validate roster/category coverage, price ranges, weights, and reward schedules at load/build time.

Performance target: stable 60 FPS at 1080p on the user's actual PC, to be measured once the first scene runs. Hardware requirements are not established yet. Large content pools must not create per-frame database scans.

## 18. Balance validation and acceptance criteria

### Static checks before a playable build

- Every OVR row sums to one; attributes and adjusted values stay within bounds.
- Recruitment and raw market weights sum to 100% for each chapter/visit.
- Exactly twelve victory stages, nine victory recruitment offers, three markets, and two coaching rewards.
- Correct income total and funds available before every market.
- Price interpolation is monotonic; market purchases and replacements are atomic.
- No duplicate people within a squad or five-player offer.
- Every required role/band has sufficient content or an explicit validated fallback.

### Match engine tests

- Ball ownership is exclusive; every goal has a valid ball/goal event.
- Rendered goals, commentary goals, and scoreboard goals agree.
- Goalkeeper possession, rebounds, throw-ins, corners, penalties, and offside reset correctly.
- Red cards remove the correct player; a red-carded goalkeeper and reduced-player formations remain valid.
- Extra time begins only when tied; shootouts use correct early termination and paired sudden death.
- Viewing speed and visual/audio RNG do not affect results.
- Pausing does not consume active time or trigger duplicated actions.
- Mid-match saving/resuming preserves score, players, pending events, and randomness on the supported build.
- Completed wins, losses, rewards, purchases, and discoveries cannot commit twice.

### Headless calibration plan

First make the football plausible; then tune whole-run success. Report confidence intervals and seeds, not only point estimates.

| Experiment | Initial sample | What it checks |
|---|---:|---|
| Equal teams, home/away swapped | 2,000 fixtures | Fairness, side bias, basic variance |
| Attribute/OVR gaps across styles | At least 500 per scenario | Strength matters without deterministic outcomes |
| Nine tactic combinations | At least 200 per matchup across several rosters | Dominant strategies and context-dependent counters |
| Whole-run strategy bots | 1,000 runs per simple strategy | Difficulty curve, economy, offer failure, purchase value |
| Rare/disciplined edge scenarios | Authored cases plus seeds | Cards, empty roles, substitutions, pool exhaustion |

Bots are diagnostics, not evidence that humans enjoy the game. Compare simple choices: highest-OVR drafting, weakest-position repair, tactical-fit drafting, early spending, and saving for Market III. If one trivial strategy dominates all rosters, revise the relevant system.

### Match texture targets

At normal speed, across ordinary balanced fixtures: approximately 24–50 completed passes total, 6–12 shots total, 8–16 controlled possession changes, and a mean total goal count around 2.5–3.5. Counts are compressed-match targets, not full-real-match statistics. Review mismatched definitions such as a loose-ball touch being counted as a new possession.

Watch outliers instead of forcing each match into these ranges. Long stretches of aimless passing, ball swarming, repeated identical goals, tackle spam, every shot scoring, and endless stoppages are failures even if the averages pass.

### Human playtesting

Use several complete runs by the user and, if desired, a few other football fans. Check whether they can explain a recruitment choice, recognise their tactical style, identify where the ball is, understand a defeat, and want another run.

Specific questions: Did a lower-OVR specialist ever make sense? Did the market create a real spending decision? Did a rare signing feel exciting without deciding the entire run? Did the final defeat feel understandable? Did the index provide motivation without a permanent power advantage?

Review after 5–10 observed runs, then again after targeted changes. Do not announce the design as balanced merely because a spreadsheet, scripted bot, or build succeeded.

## 19. Recommended production milestones

| Milestone | Deliverable | Exit criterion |
|---|---|---|
| 1. Watchable football | One exhibition match with fictional players | Readable passing, defending, shots, saves, goals, and truthful feed; no ball swarming |
| 2. Meaningful preparation | Positions, three formations, tactics, automatic subs | Controlled tests show attribute and tactical changes alter observable play |
| 3. Short complete run | Four victories, recruitment, one market, defeats, saves/index | Start-to-end loop works, resumes correctly, and creates understandable choices |
| 4. Full structure | Twelve victories, all rewards, complete rules and opponents | Run progression and economy work through win/loss/extra-time edge cases |
| 5. Historical content and presentation | Country rosters, historical cards, album, polished HUD/audio | Content coverage validates; full runs remain readable and enjoyable |
| 6. Balance pass | Simulation reports and observed personal playtests | Major dominant strategies, frustrating odds, and pacing problems are addressed |

Do not expand content while milestone one is failing. Do not replace the full-field match with an unrelated card resolution simply to reach milestone three faster. The match is the central product risk and the central attraction.

## 20. Risks, decisions to review, and reference notes

### Main risks and responses

| Risk | Response |
|---|---|
| A visually active match is still boring | Prototype realistic-looking shape and meaningful chances before building a large collection |
| Random results overwhelm management | Test attribute gaps and tactical context; keep three defeats; avoid mandatory lucky rolls |
| Highest OVR is always the only sensible recruit | Use role coverage, conditional traits, limited slots, and meaningful position penalties |
| One lucky Apex trivialises all stages | Restrict Apex availability to the final chapter and markets; no adaptive punishment |
| Replacing ordinary players erases country identity | Keep origin, kit, name, and run story; do not impose nationality bans |
| Too much management between one-minute matches | Use one-page preparation, defaults, quick comparison, skippable reveals, and nine clear checkpoints |
| A card database becomes the entire project | Start with fictional players and validate content by role before expanding eras |
| Personal asset collection becomes hard to replace | Keep portraits/data modular, record sources/permissions, and maintain a complete fallback presentation |

### Important proposals for the user to review

The working title, twelve-win/three-defeat structure, cross-national signings, eighteen-player cap, compressed fictional competitions, two coaching rewards, market economy, and initial absence of injuries/salaries are all proposed. They can change without discarding the core idea.

The most consequential design choice is how much randomness the user wants relative to football simulation. This draft chooses recognisable football with probabilistic execution and strong pre-match decisions. It does not choose a literal full-detail football manager simulation, nor a lottery where squad ratings simply decide a hidden score.

### References consulted

- User's original concept and follow-up preferences are the primary specification.
- [Super Auto Pets — developer's page](https://teamwood.itch.io/super-auto-pets): reference for preparation-driven team building and short automatic battles; no copied balance or assets.
- [The Last Flame — official store page](https://store.steampowered.com/app/1830970/The_Last_Flame/): reference for run-specific party composition and build identity; its items/relic scale is not proposed here.
- [Football, Tactics & Glory — developer's page](https://creoteam.com/football-tactics-glory/): reference for football decisions with visible tactical consequences; its turn-based control and long career are not adopted.

All specific systems, prices, schedules, formulas, and targets in this document are proposed for this game. No external source establishes that they are balanced.
