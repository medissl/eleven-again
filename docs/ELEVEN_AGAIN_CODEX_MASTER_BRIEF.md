# ELEVEN AGAIN — CODEX MASTER IMPLEMENTATION BRIEF
Version: 1.0 | Goal: transform the existing pixel-art, automated football roguelite into a replayable, balanced, satisfying game without replacing the working foundation.

## YOUR ROLE AND AUTONOMY
You are acting as the lead gameplay designer, technical designer, pixel-art UI designer, balancing engineer, QA engineer, and implementing developer. This is an **implementation commission**, not just a brainstorming prompt. Audit the actual local project first. Then implement safely, in well-tested phases. Do not ask the owner to specify every small detail. Make reasonable reversible choices, log assumptions in `docs/ELEVEN_AGAIN_DESIGN.md`, and proceed. If the codebase differs from this brief, adapt the *implementation*, preserve the *player experience*, and explicitly document any necessary deviation. Do not fabricate completed functionality. Never overwrite major working systems just because doing so is easier.

Priorities: (1) interesting decisions and run variety, (2) simulation/trait integrity, (3) sensible pacing, (4) fair recruitment and progression, (5) pixel-art polish, (6) unlocks and replayability. A playable, coherent first slice beats many partially connected features. Implement real interactions rather than decorative but inert screens.

## 0. KNOWN CURRENT GAME AND NON-NEGOTIABLE CONSTRAINTS
- Title: **Eleven Again**. Pixel-art football manager / automatic match simulation / roguelite. Built in Codex; pixel assets are currently generated programmatically/in the local development workflow.
- 200–300+ existing player cards, 4 tiers: Bronze, Silver, Gold, Legend (purple). Each card has six stats: Pace, Shooting, Dribbling, Physical, Defending, Passing. Stat maximum = 120. Overall rating maximum = 120. Each player has **one active trait/skill** (examples: Bullet Pass, Finesse Shot).
- Existing starter XI, squad editing, formation, tactics, positions, transfers/signings, currency, match simulation, field, goals, passing, dribbling, shots, defending, throw-ins/free kicks/corners and an existing pack-reveal tunnel (country → position → trait → player).
- The match view is top-down, with circular player markers and name labels, and NO direct human control. A match currently takes approximately 3 real minutes at 2× playback speed. Preserve the working simulation and automated manager identity.
- The existing campaign is 12 progressively harder fixtures: small clubs → big clubs → country/world championship, with elimination upon a third loss. Honor this story and loss-budget contract unless a migration-compatible interpretation is necessary.
- Do **not** destroy cards, rewrite 300 assets, rename existing stable card IDs, replace the simulator, rewrite the project's framework, break saves, or copy unlicensed sprite packs/footballer portraits. Do not prioritize animated humans over gameplay.
- Retain all working player statistics, current rarity assignments, player art, abilities, ball physics, and events unless an audit proves a bug. Do not blindly normalize the roster to an imagined rating distribution.

## 1. PLAYER FANTASY AND DESIGN PRINCIPLES
The player's role is a manager building an unlikely Eleven into world champions, making choices BEFORE matches. A run should tell a different story, not just be a sequence of replacing cards with higher OVR. The strategic question should become: “Is this higher-rated recruit better, or does my weaker existing card complete my build?”

Five pillars:
1. **Recruitment as discovery:** earned packs, visible odds, meaningful position targeting and exciting Legend reveals.
2. **Team identity:** build around skills, formation, style and 2–3 run-specific Manager Cards, with measurable effects in simulation.
3. **Readable tactics:** opponent scouting, transparent tactical strengths and clear post-match causal feedback.
4. **Short, complete journeys:** 12 primary fixtures; choose routes and viewing modes rather than padding match count.
5. **Earned legacy:** permanent hexagonal manager development expands possible builds rather than making the starting XI overwhelmingly stronger.

Avoid: pure percentage inflation, pay-to-win gacha, forced grinding, unwinnable random recruits, opaque outcomes, repetitive unskippable animations, misleading odds, artificial script-based wins, and systems that only exist in menus.

## 2. CAMPAIGN, LIVES, AND STRUCTURE
Three acts, four scheduled fixture nodes each:
- Act I, “The Underdogs”, nodes 1–4: local/small clubs, training-ground aesthetics, early Bronze/Silver recruits; match 4 is a chapter boss.
- Act II, “The Big Leagues”, nodes 5–8: richer clubs, diverse opponent playstyles, Gold-heavy opportunities; match 8 is a chapter boss.
- Act III, “The World Stage”, nodes 9–12: international representative/elite XI tournament, semi-final at 11 and World Cup final at 12.

**Continuity solution:** The manager's assembled squad MUST persist from Act I through III. Portray the final act as an intentionally fictional “World Stage Invitational” or alternate-universe fantasy national representative XI, so players from different countries can play together. Include a one-time clear sentence explaining this. Do not suddenly invalidate the user's hard-won XI with real-world nationality eligibility rules.

**Loss logic:** Losses at nodes 1–11 consume one of 3 hearts. At the third total loss, run ends. Losses advance through the scheduled route as presently implemented; still pay a small consolation award. The final node can only award the cup after a WIN. If a player loses at node 12 with hearts remaining, offer a “Final Rematch” at the same node, with no repeatable currency/draft/legacy farming; that loss still consumes a heart. Third loss ends the run. This creates 12 main fixtures and at most 14 played matches. If the existing simulator already implements a better, fully coherent 3-loss final rule, preserve it and document it, but never grant the trophy for losing the final.

**Routes:** Present a choice between TWO opponents/routes before selected nodes (e.g. nodes 3, 5, 7, 9) without raising main fixture count. Example: standard match with modest rewards versus stronger rival with a specific elevated reward. Reveal opponent playstyle, estimated strength band (not fake exact win%), reward, and risk. Route choices may modify the upcoming opponent and payout but must not make a run unsolvable. No procedural map maze in v1; a clean three-act route track is enough.

**Post-match cadence (once per scheduled node, whether win or loss unless eliminated):**
- Nodes 2, 4, 6, 8, 10 and 11: offer one earned 4-card Draft Pack; player reveals all 4 and signs 1 for free. If a legacy/perk node grants an extra pack, it is explicitly additional.
- Nodes 1, 3, 5, 7 and 9: offer a choice of 1 from 3 run-specific Manager Cards, or an alternate small coin option when the build is full. Max 3 Manager Cards active at once; when full, show swap/replace UI; no forced deletion.
- All completed fixtures: match result → coins → relevant pack / modifier / route event → squad → next fixture. The shop is OPTIONAL between fixtures, not a mandatory screen.
- Boss chapters at 4 and 8 produce a distinctive reward moment, but do not award dozens of stacked currencies.
- Run loss: end screen with the journey, goals, best player, completed nodes, earned legacy, and prominent “Eleven Again / New Run”. Clear: trophy screen, final XI and best combination, legacy rewards, New Run / harder challenge unlock.

## 3. PLAYER AND TACTICS: PRESERVE THE ROSTER
- Inspect the canonical player schema and roster before implementing. Keep stored OVR, the six stats, rarity, portrait, traits, nation, role/positions and IDs unchanged. All core values clamp at 120. When updating stats, use the existing authoritative OVR formula if one exists; otherwise derive *only a supplemental positional-fit indicator*, not a replacement OVR.
- Support 11 valid starters; ensure goalkeeper coverage, bench and squad constraints use existing semantics. Do not allow card selection to silently destroy/reassign players. “Sign” adds to bench, then offers “Compare & Start” as an optional action. The lineup remains editable before every match.
- For *advisory role-fit only*, use these normalized six-stat weights (sum to 1) as a starting table, then compare with current game's roles:
  - ST: SHO .38, PAC .20, DRI .17, PHY .12, PAS .09, DEF .04.
  - Winger: PAC .30, DRI .28, SHO .18, PAS .17, PHY .05, DEF .02.
  - Central mid: PAS .30, DRI .22, DEF .15, PHY .12, PAC .12, SHO .09.
  - Centre-back: DEF .40, PHY .27, PAC .14, PAS .12, DRI .04, SHO .03.
  - Full-back: DEF .30, PAC .23, PAS .18, PHY .14, DRI .11, SHO .04.
  - GK: use native goalkeeping mechanics/stats if available. If the only fields really are those six, derive a **UI advisory**, not the physics, e.g. DEF .40 + PHY .30 + PAS .20 + PAC .10, and retain native save/shot logic.
- Show active chemistry/synergy icons in squad and pre-match preview. The user must be able to understand why a specific setup is good. Do not add mandatory country/club link restrictions to make chemistry work; tactical and trait interactions are more reliable given the fantasy international act.

## 4. PACKS, SCOUTING, AND LEGEND ECONOMY
**Core interaction:** earned 4-card “draft pack”: the existing country → position → skill → player tunnel reveals four random cards; user chooses EXACTLY ONE signing. This preserves decision-making and makes the presentation genuinely exciting. The draft MUST be seed-backed and save-safe. Free checkpoint packs at 2,4,6,8,10,11 are the base recruitment rhythm, not daily-login gacha.

Pack rarity weights PER REVEALED CARD (not per pack), independently sampled; sum to 100%:

| Pack and act | Bronze | Silver | Gold | Legend |
|---|---:|---:|---:|---:|
| Standard / earned, I | 56.0% | 38.0% | 5.8% | 0.2% |
| Standard / earned, II | 25.0% | 48.0% | 25.5% | 1.5% |
| Standard / earned, III | 8.0% | 35.0% | 53.0% | 4.0% |
| Elite, I | 10.0% | 62.0% | 27.0% | 1.0% |
| Elite, II | 5.0% | 35.0% | 55.0% | 5.0% |
| Elite, III | 0.0% | 16.0% | 76.0% | 8.0% |

**Probability math (verify in automated tests):** If a per-card Legend rate is p, a 4-card reveal offers at least one Legend with probability `1-(1-p)^4`. Standard packs: Act I 0.80%, Act II 5.87%, Act III 15.07%; Elite III 28.36%. Assuming 2 earned Standard packs in each act (6 total), the probability of at least one Legend *offered* is `1-(.998^8)(.985^8)(.96^8) = 37.09%`. Add ONE purchased Act III Elite pack and the probability becomes `1-(.998^8)(.985^8)(.96^8)(.92^4) = 54.93%`. These numbers assume all those packs are actually opened, and “offered” is not guaranteed “signed.” No hidden pity initially; show odds openly. No player should need a Legend to win.

**Shop prices (in-run coins, initial tuning values):** Standard Scout 180; Position Scout 280; Elite Scout 480; refresh offers 45; single-player focused training 140. Shop stocks three direct signings optionally, with indicative direct listing prices: Bronze 100, Silver 210, Gold 420, Legend 900. Direct cards can be expensive because users know the exact card; packs trade certainty for variety. Ensure at least one affordable, useful option at most shop visits. Avoid pricing everything beyond expected run earnings. Shop offers may refresh between nodes, never during an uncompleted reveal.

Position Scout uses the **same rarity odds as Standard** for the current act, but guarantees at least 2 of the 4 offers are from the chosen *position group* (GK / DEF / MID / FWD), if enough valid players exist. Fallback gracefully with a visible explanation and refund/cancel option if roster scarcity makes the promise impossible. “Target a group” should be available early; targeting an exact position is a possible later legacy node. Elite is rarity-biased, but has no positional guarantee.

**Duplicate / roster safety:** Prevent duplicate copies of the same unique player appearing together in one pack when the pool is sufficient. Prefer cards not already owned; don't silently remove cards from the canonical pool. Allow a recruit to be declined in favor of a modest cash voucher when all four options are unwanted. Starting players cannot be turned into infinite free coins. Released/replaced pack recruits should give a small, capped return (e.g. Bronze 25, Silver 35, Gold 55, Legend 80), always less than the cheapest repeatable paid pack. Hard-cap any discard payout to avoid coin generation loops. Persist opening seed and offer set before reveal so reload cannot reroll outcomes.

**Presentation:** Use a skippable sequence: pack arrival, country, position, unique skill, final card reveal. Normal full reveal of all 4 should take roughly 4–7 seconds total, not 4 entire long tunnels; make one-card focus optional and big Legend flourish about 2–3 seconds. Offer “Reveal All”, “Skip”, reduced motion, sound mute and optional celebration replay. Clear rarity colors; purple Legend deserves a stronger light/tunnel/pixel particle treatment, a distinctive audio sting if audio exists, and a post-sign trait preview. DO NOT make non-Legend reveals irritating or impossible to skip. Do not add paid gacha, premium currency, energy or login pressure.

## 5. RUN ECONOMY — EXACT STARTING VALUES
Coins are temporary, reset each run. Legacy Marks (Section 8) persist. Keep currency naming consistent with actual project and migrate old data safely.

| Act | Win payout | Loss consolation |
|---|---:|---:|
| I (nodes 1–4) | 100 | 35 |
| II (nodes 5–8) | 150 | 50 |
| III (nodes 9–12) | 210 | 70 |

A perfect 12-win run generates `4×100 + 4×150 + 4×210 = 1,840` coins, of which `1,630` are earnable **before** the final fixture. Example feasible pre-final spending: 1 Elite pack (480) + 2 Position packs (560) + 2 Standard packs (360) = 1,400; leaves 230 for a refresh/training or saving. This is a *budget reference*, not a mandatory shopping path. Different builds can invest in fewer, better signings. If a fixture loss advances the run, it pays only its consolation reward, not the winning reward; no repeat farming from final rematches. If existing shop/training economy is meaningfully different, start behind a tuning config, compare full-run buying power and adjust coherently rather than blindly double-rewarding.

Training is an optional run-only service, not a third currency: pay 140 coins to add **+4 to ONE chosen stat** on ONE roster player, capped at 120, no more than twice per player per run. Disallow zero-benefit spends. Use the game's current OVR recalculation rules and never exceed 120. Training should help salvage a good synergy card rather than replace recruiting.

## 6. TEAM SYNERGIES AND MANAGER CARDS (THE GAME'S STRATEGIC CORE)
Do not make “more OVR” the only reason to sign a player. Audit how the current single-skill traits actually trigger in the simulator; use existing event and probability systems. A skill must visibly alter the relevant EVENT when activated, not just display glowing UI. Preserve each player's one native skill; **Manager Cards** are separate run-only team modifiers and NEVER permanently change the source player card data.

First create 8–12 distinct Manager Cards, out of which the player can equip up to THREE during a run. Offer three choices on nodes 1,3,5,7,9; a full 3-slot loadout can replace an existing modifier. Effects should enable tactics and have counterplay, not simply +10 all stats.

Initial examples with conditional numeric modifiers (tune after simulation tests):
1. **Lightning Counter**: after an actual interception, the first immediate forward pass gets up to +0.06 *absolute* completion chance and its ensuing attacking opportunity gets up to +0.04 xG, if it happens inside the permitted possession window.
2. **One-Touch Football**: after 3 consecutive successful forward/central passes in one possession, the next shot receives +0.05 xG; resets on turnover; capped to 2 activations per half.
3. **Iron Wall**: CB/DM defensive-interception attempts gain up to +0.05 absolute success during organized defense; reduces forward attack tempo slightly (-0.03 effective opportunity creation) to create a tradeoff.
4. **Wide Overload**: successful wide progressions improve the quality of the next cross by +0.07 absolute; central buildup is slightly less frequent so this is an identity, not an always-on bonus.
5. **Dead-Ball Specialists**: corner/free-kick attacking opportunities improve xG by up to +0.06, but only for genuine set pieces.
6. **High Press Gamble**: pressing actions gain +0.06 interception success in the first 30 in-game minutes, but if the simulator models fatigue, stamina costs rise; otherwise a small opponent counterattack vulnerability is required.
7. **Deep-Lying Playmaker**: a successful long pass from CM/DM can improve the receiving player's subsequent action by +0.04, once per possession.
8. **Last Stand**: when trailing after minute 70, build-up/finishing opportunity quality gains +0.05; vulnerable to counters (-0.04 on defensive recovery) during the same state.
9–12: design only after first eight are functional, unique and tested; possible themes: Aerial Route, Possession Lock, Super Sub (only if bench substitutions exist), Patient Build-Up.

**Event modifiers are not arbitrary win-rate boosts:** Apply to actual pass, shot, interception, positioning and transition events through a shared modifier pipeline. Validate conditions, eligibility, cooldowns, and event attribution. For every event, total positive stacking on one probability/xG is capped at **+0.12 absolute** across player skills + all Manager Cards; clamp final probability to `[0.05, 0.95]` where applicable. Do not apply shot benefits more than once to one shot. Do not multiply several bonuses without a cap. Prefer meaningful tradeoffs and opportunities over universal power. Never secretly alter results based on whether a match is being watched.

**Player trait reliability:** For skills with naturally eligible opportunities, start from about a 35% trigger rate *per eligible opportunity*, max 2 activations per player per match and a context-appropriate cooldown; Legend traits may get around 45% if existing logic and balance allow, but don't force an impossible shot or interception just to trigger VFX. Test the actual chance a trait is seen in a full match, not just raw roll probability. If a player has three valid opportunities at 35%, chance of at least one trigger is `1-(.65^3)=72.54%`; with three at 45%, `1-(.55^3)=83.36%`. Ensure a marquee Legend who is actively participating usually has meaningful chances to exhibit their skill without guaranteed goals. If native proc logic already works well, tune minimally rather than overwriting it.

**Build discovery:** Annotate pre-match team composition with 1–3 small, understandable tags, e.g. “Counterattack: Bullet Pass + Fast Winger + Lightning Counter.” Show after-game impact: “Bullet Pass activated 2×,” “Lightning Counter created 1 quality chance,” “Finesse Shot led to goal.” Only display claims backed by logged match events. Higher OVR remains meaningful, but optimal squad selection should sometimes favor fit over OVR.

## 7. MATCH PLAYBACK, VISUAL FEEDBACK, AND FAIRNESS
KEEP the current top-down circle-and-name field for v1. The manager isn't directly controlling players; tactical clarity matters more than a costly 22-sprite animation rebuild. Upgrade presentation *around* the existing game: distinctive pass streaks, finesse curves, intercept flash, Legend skill flourish, tactical icons, goal celebrations, a scoreboard and replay highlights. All art uses existing pixel aesthetic, never blurry scaled vectors by accident.

Three viewing modes, ALL driven by the **same underlying simulation and seeded match state**:
- Live: existing 1× / 2× speed; 2× remains roughly 3 real minutes.
- Key Highlights: precompute/log or simulate the entire match and render only essential attacks, goals, saves, skill events and decisive moments, about 20–45 seconds target. Preserve final score/statistics exactly.
- Instant Result: run the same headless simulation without rendering per-tick animation, target a few seconds on supported hardware; then show score, xG if already credible, possession, shots, scorers and *actual* skill impact. Replay notable events using event log if supported.

Never implement “instant result” as a completely different formula that makes it easier/harder to win. Use deterministic local RNG streams for match resolution, scouting and presentation to avoid display speed affecting outcomes. Same initial seed + squad + opponent + tactics + manager modifiers = same outcome in all modes. Store seed and/or full result log so highlights can be reconstructed. UI playback changes cannot change game time-step or RNG call order. If genuine live tactical changes are implemented later, support equivalent pre-match contingent instructions for all modes; do not give Live an unfair gameplay advantage. For v1 prefer all strategic input pre-match and read-only match viewing.

Post-match panel: exact score and event-backed short recap; who scored; which trait triggered and its effect; optional simple tactical takeaway; gained coins; injuries/fatigue only if those mechanics genuinely exist. No fake “MVP” just because a player is a Legend. Name tags should be legible at game scale; do not require redrawing all player markers yet.

## 8. HEXAGONAL MANAGER LEGACY TREE (PERMANENT)
Follow the screenshot inspiration: central hexagon with six branching arcs, 4 hex nodes per branch, 24 purchasable nodes total. This is a **Manager Legacy** board, NOT a 300-player stat skill tree. Center = “THE MANAGER”, already active, and each node requires the preceding node on that branch. Accessible pan/zoom, controller/keyboard navigation if used by project, touch-friendly hit targets, names/costs/effects on selection, clear unlocked/locked/affordable states. Use exact deterministic hex grid coordinates rather than arbitrary offset hacks; draw connections under nodes.

Six branch identities: Scouting (cyan), Tactics (orange), Finance (gold), Academy (green), Chemistry (blue), Fortune (purple). Keep palette aligned with existing aesthetic and provide symbols besides color.

**Costs per branch, near-to-far:** 70 → 100 → 130 → 170 Legacy Marks. Total full tree cost: `6×(70+100+130+170)=2,820` Marks. Early acquisition should unlock a useful option, not +0.5% generic stats.

Examples for a fully implemented set of 24 real nodes, adapted to existing systems:
- **Scouting:** (1) position-group scout option unlocked; (2) see additional position intel on 3 shop offers; (3) one free pack *reroll* per run (not a guaranteed rarity upgrade); (4) Position Scout may guarantee 2 exact-position candidates where the pool permits.
- **Tactics:** (1) unlock additional 3 Manager Cards in the offering pool; (2) offer one extra choice at the next Manager Card event once per run; (3) unlock detailed opponent scout report; (4) unlock a tactical pivot at an Act II event (swap one run card for a newly offered one free).
- **Finance:** (1) unlock a 1-time small shop coupon (e.g. 40 coins); (2) reduce one market refresh from 45 to 0 per run; (3) +5% sell-value up to the caps; (4) one Standard pack discount of 90 once per run. Avoid stacked unlimited discounts/coin loops.
- **Academy:** (1) unlock extra training stat choice UI; (2) first training of a run is 30 coins cheaper; (3) one free team role-fit analysis before a boss; (4) once per run train one player +4 in an eligible stat without paying, still bound by 120 and per-player cap.
- **Chemistry:** (1) unlock synergy preview/filter in recruitment; (2) display 2-player trait pair preview in squad; (3) unlock 3 additional trait-combo Manager Cards (with proven real effects); (4) one extra manager-card selection option once per run. UX-only nodes must be strong enough to merit progression; combine with meaningful, bounded extra options where necessary.
- **Fortune:** (1) unlock a new risk/reward event type; (2) one optional “double-or-nothing” match reward offer per run with clear stakes and no forced risk; (3) obtain one additional **non-Legend-guaranteed** draft choice after the Act II boss; (4) one choice of two high-risk event outcomes before Act III. Do not make Fortune a permanent escalating Legend-rate bonus that erases rarity or hides probability.

**Legacy Marks earnings:** +35 per won *unique scheduled node*, +15 per lost *unique node*, +15 on completing each act at nodes 4, 8, 12, +100 for a campaign championship win. A clean 12-win clear yields `12×35 + 3×15 + 100 = 565` Marks. `2,820/565 ≈ 4.99` perfect clears to buy every node; typical players taking partial runs should need more runs. No repeat payouts for Final Rematch failures, replays of the same completed fixture, save reloads, or UI speed changes. Persist Marks and purchased hexes across runs; reset tactical Manager Cards, coins, transient training, cards recruited during run and other run state when starting over.

Do not lock basic game comprehension or existing features behind legacy upgrades. If a suggested node duplicates a preexisting baseline feature, REPLACE that node with a new bounded choice without removing the existing baseline feature. The board should open doors, not withhold essential controls.

## 9. DIFFICULTY, COMPLETION CHANCES, AND BALANCING ENGINEERING
Do not simply add 10 OVR per opponent every match; actual team improvement is stochastic and positional. Audit existing opponent data and tuning first. For the initial balance benchmark, a *reasonably drafted but not optimized* team should have roughly these per-fixture win probabilities, conditioned on getting that far and making normal choices:

| Node | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Target P(win) | .84 | .79 | .75 | .68 | .76 | .73 | .69 | .64 | .69 | .66 | .62 | .55 |

This is an empirical **tuning target**, NOT permission to secretly predetermine winners. Use genuine match simulation, player skills, formation, opponent tactics and roster strength. Difficulty dips at starts of Acts II/III because a newly recruited team should feel its growth; bosses at 4, 8, 12 should be noticeable. Set opposition tiers and lineups from actual roster data; if specific player pool is sparse, adjust through legal squad compositions rather than fake 150 OVR cards.

Approximate independent-fixture model (for expectation only): with three total losses allowed, final MUST be won, and final can be retried while hearts remain, these 12 benchmark rates imply about **22.52%** run-clear probability. A player whose informed drafting/tactics improve their conditional win probability by +.05 per node has about **35.64%** clear chance; +.10 (with probabilities capped at .95) yields about **52.10%**. This gives a meaningful skill/progression curve without requiring guaranteed Legends. The exact in-engine values will differ due to correlated rosters, opponent counters, draws, draws-to-penalties, and resource decisions; measure them in simulations, don't claim they're exact game odds.

Implementation benchmark: build **deterministic headless batch simulations** with a basic drafting policy and a synergy-aware policy, at least 1,000 complete runs per policy (prefer 5,000 where fast). Record stage-by-stage win rate, run clear rate, average fixture time, cards obtained by rarity, Legends offered/signed, final lineup OVR distribution, Manager Card effectiveness, coin surplus/spend, trait activation and player use. Flag overpowered relics (unconditional dominance), dead choices, impossible difficulty spikes, rating caps, repeated shop exploits and packs with no usable candidates. Test several seeds and starter squads. Do NOT silently apply rubber-banding based on the player's current hearts.

## 10. PIXEL ART, UI AND COPY SPECIFICATION
Audit and preserve existing art direction before creating assets. Prefer reusable, procedurally generated pixel assets and small consistent atlases over large numbers of bespoke images. Nearest-neighbor scaling only; no fuzzy upscale, no generic gradients, no unnecessary 3D. Maintain compact layouts and legible type at actual game resolution. Use a limited coherent palette with rarity semantic colors (e.g. Bronze `#986A47`, Silver `#8799AA`, Gold `#D2A444`, Legend `#8752C7`) but adapt to existing UI tokens. Include icon/text equivalents for color-coded states.

Minimum real art deliverables, sized according to current engine rather than blindly hardcoding pixel dimensions:
- 4 pack shells plus reusable back-of-card, rarity frames, pixel shine, tunnel backdrops, country/position/trait reveal labels and distinct Legend burst.
- 6 hex branch icons, locked/unlocked hex states, connecting lines, active branch glow, central manager crest, branch selection markers.
- 8 Manager Card icons matching each effect (bolt, connected passes, shield, wing, dead ball, press, deep playmaker, last stand); one consistent icon grid.
- Simple in-match VFX: Bullet Pass trail, Finesse Shot curve, interception sparkle, rare-skill highlight, goal freeze/flash, responsive match summary.
- Three-act route map with boss node shapes, match-result icon, optional risk route, ticket/pack reward indicators.
- Championship trophy scene with final XI silhouettes/cards and satisfying short celebration; polished loss/new-run state.

If using generated sprites, put the generation source/scripts in version control, make output reproducible, name assets predictably and keep small at native pixel size. Do not scrape copyrighted football badges, licensed player portraits or existing games' sprites. User has hundreds of finished card assets; **do not regenerate them**. Reuse and stylize existing art assets first. Design new assets by purpose, integrate them into actual screens, then inspect screenshot output for clipping/contrast.

Microcopy (adapt language to project's current localization):
- Run intro: “Eleven players. Three chances. One impossible trophy.”
- Pack: “Scout reports received. Sign one.”
- Pre-match: “Their strength: high press. Your edge: fast transitions.” (Only if backed by actual tactics.)
- Manager Card: “Choose a philosophy for this run.”
- Legendary reveal: “LEGEND DISCOVERED.”
- On second loss: “One chance remains.”
- Third loss: “The run ends here. The legacy remains.”
- Trophy: “WORLD CHAMPIONS. Eleven Again?”
- Legacy tree: “Grow your options, not just your numbers.”
- Final rematch: “The trophy is still out of reach. One more chance.”

Navigation: use a consistent main hub with “Continue Run”, “Squad”, “Scouting / Market”, “Tactics”, “Manager Legacy”, “Collection”, “Settings”; avoid adding redundant tabs if existing routes already serve the purpose. Persist current view/state across a save. Pack reveal actions are irreversible only after confirmation; no accidental card discard. Display odds, costs, affordability, effect text and current lives where important. Honor accessible focus states, keyboard/gamepad if already supported, and touch-friendly taps if game runs on mobile. Add a reduced-motion switch, animation skip, and music/SFX toggles as appropriate.

## 11. TECHNICAL ARCHITECTURE AND SAVE MIGRATION
Audit actual stack, game engine, test runner, local asset toolchain, data stores and save schema. Follow existing style and project agents/rules. Prefer data-driven, pure/testable modules over UI-specific magic numbers:
- `gameBalance` (rarity probabilities, coin costs, milestone progression, XP costs, trait clamps, timing target)
- `recruitment` (seeded candidate sampling, position filters, unique-ID collision handling, RNG state, signing transaction)
- `managerCards` (data definitions, eligibility, attach/detach, effect handler registry, capped modifier pipeline)
- `matchEvents` (deterministic simulation log, proc attribution, highlights, speed-independent playback)
- `campaign` (act/node/branch/lives/final retries, once-only rewards)
- `legacy` (node graph, prerequisites, persistent Marks, caps, migration)
- `ui/assets` integrated into the existing framework, not a new isolated app.

Preserve save/backward compatibility. Add an explicit versioned migration for missing new fields and old runs. Existing card IDs and rosters must not be replaced. New-session temporary config is separate from the legacy persistent profile. Save outcome and scouting RNG state atomically before reveal to prevent reroll exploits. Don't leak cross-run coins/relics/training. Never import an external hosted RNG that breaks offline or deterministic play.

Use feature flags if the app is live or changes could destabilize current saves. Prioritize mainline functionality over future-proof abstractions. Keep the game playable at each checkpoint; do not remove the old match renderer before the new event log works. Optimize batch simulations and make optional particle effects GPU/CPU lightweight. Logging can be compact and limited to match events needed for highlights, analytics and deterministic replay.

## 12. IMPLEMENTATION PHASES — ACT, DON'T STOP AT A PROPOSAL
**Phase 0: audit and baseline.** Inspect source structure, actual player database, card rarity distribution, ability implementation, save schema, campaign flow, formation/role handling, match simulator, renderer and assets. Run current tests/build and record defects. Write `docs/ELEVEN_AGAIN_DESIGN.md` with verified architecture, assumptions, mechanics and tuning table. DO NOT assert a feature is implemented until source/test confirms it.

**Phase 1: integrity and analytics.** Expose stable gameplay event hooks (pass, shot, interception, goal, set piece, skill). Instrument seeded simulation, before/after event modifiers and post-match attribution. Ensure speed does not change simulation results. Put constants in one configuration. Add first meaningful tests.

**Phase 2: recruitment and pacing.** Implement four-reveal choose-one packs, odds by act, target/Elite pack, coin pricing, fair replacement, save-safe RNG, reroll/release rules, and authentic existing tunnel animation. Integrate six checkpoint offers. Introduce Instant Result and Key Highlights when simulation parity and event logs are reliable. This phase should already make the game more enjoyable.

**Phase 3: build synergies.** Implement first EIGHT Manager Cards with real engine effects, max-3 loadout, synergy suggestions, visible skill procs and match-impact recap. Tune with headless batch sims. Do not spend time on dozens of decorative relics.

**Phase 4: campaign routes and difficulty.** Implement three acts, optional risk/reward branching opponent choice, authored opponent playstyle hints, boss moments, loss logic/final rematch, clear/loss screens and reward logic. Preserve the existing 12-node progression whenever possible.

**Phase 5: persistent legacy tree.** Implement 24 connected hex nodes in six branches, 2,820 total Marks cost, persistence and migration, no repeated reward exploits, responsive pan/zoom, meaningful actual effects. If a proposed unlock would lock an existing baseline feature, substitute a genuine choice-based node.

**Phase 6: pixel polish, progression tuning, complete QA.** Integrate all actual assets; performance check, keyboard/touch if relevant, audio/skip/reduced motion, final victory presentation, regression tests and 1,000–5,000 run balance analysis. Consider one post-clear “Hard Mode” with higher opposition competence and a run-only extra Manager Card risk/reward modifier. Reserve truly endless mode as post-MVP unless the foundation supports it cheaply. An endless mode must not replace the core short championship.

After EACH phase: run tests/build/lint/typechecks available; correct regressions; document actual changes, test evidence, next phase, and current risks; commit in sensible increments if repo workflow permits. Continue to the next phase autonomously while context/time permits. If resource-limited, finish and verify the current phase, leave clean state and an explicit machine-readable plan for the next Codex session. Do not ask the owner trivial choices. Only seek input if an irreversible, destructive or materially contradictory decision cannot be resolved safely.

## 13. QUALITY GATES AND NON-NEGOTIABLE TESTS
- Existing game starts, shows current cards/art, supports lineup/tactics, simulates a normal match, saves/loads, completes a run. No 300-card rework.
- All six player stats and OVR are always <=120. Existing IDs and rarity assignments survive migrations.
- Each pack has four candidate offers, visible real odds, unique candidates when possible, and exactly one signed player; targeted packs honor guarantees or compensate openly; no reload reroll exploit or duplicate currency loop.
- Pack probability unit tests verify sums to 1 and distribution Monte Carlo sanity. Legend reveal math aligns with Section 4; a Legend is rare but achievable, not a required win condition.
- Every Manager Card has at least one executable match-event test proving the described effect really happens when eligible, plus a stacking-cap test. Skill activation shown in UX corresponds to real logs. No displayed fictional “+xG” when the engine doesn't track it.
- Different viewing modes produce the SAME score, scorers, injuries (if any), skill event log and rewards for the same seed and pre-match decisions. No independent random simulator for Instant Result. No 12×3-minute mandatory waiting.
- Campaign always ends at 3 total losses; a final defeat never grants cup; no farming rematches; correct act transition and squad continuity. Clear unlocks next difficulty but lets player start normal mode again.
- Legacy tree has 24 real costed nodes, valid prerequisites, no duplicate purchases, saves persist across runs, refunds/migrations safe, Marks earned exactly once per eligible fixture/milestone, no permanent runaway power.
- Tests cover missing player roles, empty/short pools, mobile or low-resolution UI, extreme 120 stats, all 11 roster positions, overlapping abilities, high-speed match, save during pack reveal, old saves, instant restart, third loss at final, victory at final and replays.
- Balance telemetry includes at least baseline and informed draft policies and actual skill activation rates. If completion odds differ greatly from the targets, tune real opponent teams, economy or choice quality; never manipulate individual outcomes in secret.
- Visual screenshot review at intended target resolution: no cropped card names, mismatched pixel scaling, unreadable hex labels, blurred icons, overlapping controls, clipped skill popups or unskippable long reward animations.

## 14. WHAT TO DELIVER
Deliver working code, integrated art/scripts, tested mechanics and a clear brief report. Include:
1. `docs/ELEVEN_AGAIN_DESIGN.md`: final rules, player journey, UX, sample runs, probabilities, economy, exact data tables, tradeoffs and accepted deviations.
2. `docs/ELEVEN_AGAIN_BALANCE.md`: rarity audit, per-node difficulty, batch-simulation summary, match timing, skill proc metrics, pack-offer probabilities and recommended tuning.
3. Automated tests for mechanics and reproducibility; working asset generation sources.
4. A short changelog with “done / deferred / tested / known limitations”.

**Product success criterion:** a player can start with 11 ordinary footballers, discover an unusual combination, decide between OVR and fit, recruit exciting players through fair earned packs, understand what happened in their automatic matches, reach a coherent final, and want to play again with a DIFFERENT strategy. Do not solve lack of fun by simply making the run longer or adding more cards.

START by auditing the actual repository and preserving the current working game. Then implement in phases. Do not produce only a design plan and stop.
