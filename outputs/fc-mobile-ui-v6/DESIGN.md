# Eleven Again — FC Mobile graphic direction / The Climb

30 October 2026. The user rejected graphite/coral v5 and then the plain font/flat blue surfaces. They **approved the subsequent neon/glass football direction**, and requested consistent typography plus a shared card upgrade with larger stats and white ability icons. This v6 is the current reference. Runtime football is checkpointed at `ff3e604`. This package is an isolated native design preview and implementation contract, not a claim that production migration/new economy has shipped. `tasks/todo.md` is the sole tracker. Earlier coral captures are archived under `rejected-v5/`, not current design targets.

## The run

Choose a country → opening free signing → Pyramid hub → Squad → opponent card lineup/tactics → watch match → reward desk → climb. Twelve wins crown the run; three defeats end it. Defeat retries the same saved opponent with a fresh persisted attempt seed, no farming rewards. No permanent money/squad/power. Acquired-version Collection and records survive.

One currency: cash. No tokens, gems, salaries, contracts, interest, chemistry or permanent upgrades. The interesting choice is a better player now, a better-fitting reroll, or money for a future market.

## The pyramid

| Level, bottom → top | Wins needed | Opposition identity | Win cash |
|---|---|---|---|
| Local clubs | 1–3 | Amateur and small original clubs | $4m each |
| National leagues | 4–6 | Established original domestic clubs | $6m each |
| Club champions | 7–8 | Original elite clubs with strong city/football identities | $8m each |
| Nations cup | 9–10 | National sides, actual country flags | $10m each |
| World Cup semifinal | 11 | National finalist contender | $12m |
| World Cup final | 12 | Strong national opponent; original trophy presentation | Trophy, no pointless final shop |

Twelve fixture medallions form a true narrowing silhouette: 3 + 3 + 2 + 2 + 1 + 1. Completed wins climb from the base. Current step has one strong outline/route; locked steps show competition category rather than invented scouting. The next rival receives one focused side panel and one Prepare action. Squad remains a separate top-level destination. This is a fixed campaign, not a deceptive branching map.

Original elite examples: **Rive Athletic** (navy/cyan, bridge-and-river crest), **Isar Union** (red/platinum, mountain/river shield), **Crown Vale** (burgundy/platinum, crown), **Forge Sporting** (steel/copper, forge motif). Regional identity/color suggests football culture; names, crest geometry and symbols are original. The native atlas supplies these four original club marks. Nations use flags, not federation crests.

The existing OVR difficulty curve remains a starting hypothesis. More recruitment and different market timing will change difficulty: measure paired fixtures/full runs before calling it balanced. No dynamic score/OVR correction.

## Recruitment, rerolls and money

Start with **16 players and $10m**. Opening offer: five full cards, one free signing, ordinary 75–79 focus player; no cash alternative on this first decision. After every non-final victory, award the scheduled cash once and offer:

- **Sign one free player** from five saved candidates; or
- **Take $2m** instead. This replaces empty Skip with an actual opportunity-cost choice.

Free signing costs no money. Selected card exposes a compact outgoing-player/slot-fit strip only if needed. At 18 players, confirm incoming + outgoing atomically; choosing/inspecting does not release anyone. Keep the last trained keeper protected. Releasing is not selling and returns no money. No force-signing a worse player to escape the page.

**Reroll:** first $1m, second $2m, at most two per draft. Same power bands/role coverage; no hidden improvement or luck boost. The current offer is replaced only after successful generation and journal commit. Paid price, new candidate IDs and RNG advance persist together. No third roll, save-scumming refresh or showing paid changes before saving succeeds. Rerolled-away candidates are excluded from that reward's next roll when coverage permits; owned/released people remain excluded for the run. Explain any coverage fallback in development diagnostics, not decorative player-facing prose.

**Markets after wins 3, 6, 9:** eight saved players, four complete cards per page; up to two purchases. One optional Restock costs $3m/$5m/$7m by visit. Restock replaces unsold stock, never resets purchase count, never sells a player twice and cannot refresh on Back/Continue. Ordinary owned/released exclusions apply. Leave market is always available. Market closed at next kickoff.

Price bands in `economy.json`: 65–69: $3–4m; 70–79: $5–8m; 80–89: $10–16m; 90–99: $18–28m; 100–109: $32–46m; 110–120: $50–72m. Linear integer-million interpolation within bands. Printed card base OVR prices the card; slot penalty affects fit, not resale/arbitrary price. Exact current price is visible before signing.

Two existing coaching choices after wins 4 and 8 retain their real six effects/shared +6 cap. Present them on the reward desk after that signing choice, with one of three meaningful principles, rather than creating more currencies or a skill tree.

Arithmetic, not balance: cash available before the final with no purchases/rerolls is $88m; banking all eleven victory drafts raises it to $110m but sacrifices eleven players. Rolling twice on the opening + eleven victory drafts costs $36m. No loss reward, interest or repeatable sales can farm cash. These numbers are provisional and must live in data.

## Art direction

**Floodlit stadium / midnight glass / ice.** Background `#080E19`, surface `#101D2E`, white `#F2F7FD`, muted `#A0B2C9`, selection `#49D6F5`. Glass has actual background blur, a lit upper rim, restrained cyan edge glow and opposing clipped corners. Primary actions have a deeper cyan-blue specular face; quiet navigation stays clear until hover/focus. The arena remains mounted behind the UI. The former flat panels, rounded pills and plain font were superseded by the user's neon/glass correction.

**One family: Saira.** Medium 500 for body, Semibold 600 for actions/labels and Heavy 800 for numbers/teams, with Heavy Italic for major headings. Width stays at 90 throughout. Explicitly set every theme role, including Primary/Quiet/Tab: inherited old button overrides caused Sign Hart to show a different font. Card labels use the same family. OpenType axes use unique integer tags; enable real tabular figures. Native checks inspect every visible label/button and all 200 card bindings. Source Sans remains a missing-symbol fallback, not an alternate text style. The font is OFL-licensed and locally vendored.

Use 32px outer spacing and 44px action targets. Body copy appears only when it changes a decision or explains an error. The original arena is menu art, never a replacement for the native match renderer. One explicit BackBufferCopy captures the arena before UI drawing; the glass shader samples it with a bounded nine-tap blur. Text/portraits do not enter the blur. Shader output respects inherited opacity: an actual pixel comparison verifies that zero-alpha incoming glass cannot erase outgoing text. Arena dimming animates with the page. Settings keeps its glass panel mounted while only its category content changes. Hardware performance is not yet profiled.

Home uses the arena, two full native cards and three football feature tiles. Squad uses a wide textured perspective pitch, larger native cards, a left team/OVR/formation region, reserve strip and optional selected-player sheet. The pyramid uses ascending platforms, a lit route and original club crests. Rewards, markets, origin selection, inspection, Collection, records, settings and endings share the same environment, typography, glass and illuminated actions.

## Shared card finish and readability

The user explicitly authorized this targeted visual follow-up; the 200 portraits remain settled. One definition-driven Card adapter and `card_style.gd` restyle all cards. Four derived tiers remain Bronze/Silver/Gold/Legend, with copper/titanium/champagne/**amethyst-purple** metallic frames and 1/2/3/4 notch marks. The user requested a stronger Legend distinction and suggested red or purple; purple with lilac highlights is the chosen finish. The 5:7 silhouette has clipped corners, a slight waist, a dark face and an OVR/position/flag rail. Every portrait, rating, attribute, edition and person/card ID remains original.

The lower card body uses a **two-column, three-row stat grid**, with 36px requested number type and 16px labels in the 300×420 logical template, fitted to real font metrics. Remove the old country/position footer and written ability-name row. Keep the player name directly above the stat rule. All six values remain visible, including PHY for keepers. Full free-signing/market cards stay complete at 720p.

**36 original white ability glyphs** share one stroke/style and authoritative trait-ID map. A36×36 badge sits at(242,72), opposite the position on the same horizontal level. No ability yields no badge. Hover/focus shows the real name/effect in a wrapped glass panel; Escape dismisses it before page navigation. Only the card's written ability name is removed; the mechanic and inspector details remain. Unknown cards expose neither an icon nor identity/portrait/ratings. Native evidence includes all four finishes, the unknown back, the 36-icon sheet and keyboard details. During production promotion, fold this adapter into the existing shared `ui/player_card.gd`; never create200 edited card images.

The live reference subclasses the existing MatchView only inside this authoring package. Its parent paints the blue top/sidebar background **before the native HUD child** draws. Both native shirt icons, compact score alignment, full textured field, all markings, goals, ball, player circles/names and feed remain. Explicit screenshot-pixel assertions guard the two kit centres and seven pitch landmarks at both resolutions. Preserve Menu's original icon/text margins when applying new button styles. No production match script is edited. Halftime/report/menu refinements must preserve the existing deliberate controls, animations, confetti and keyboard behaviour during integration.

All displayed OVR is **rounded upward to a whole number** (`ceili(total/11.0)` for team means); exact totals/11 remain saved and used for record ranking. Player OVR continues to use its established authored rating calculation.

## Connected screen contract

| Screen | Primary content/action | Remove or move |
|---|---|---|
| Home | Wordmark, Continue with real saved context, New run, Collection, Records, Settings | No generic marketing copy or fake saved preview |
| Country | 32 accurate flags, region filters/search, selected identity/kit; Start | Remove Your origin/A starting eleven explanatory paragraphs. Country changes identity, not hidden power. |
| Pyramid | Complete ascent silhouette, current rival, three defeat pips, cash, Squad, Prepare | Four horizontal fixture boxes and repeated headings |
| Squad | Card pitch, reserve strip, selected full card, Formation/Tactics/Assignments drawers; Apply/Cancel | Circle-only setup, long reserve button stack, many permanent dropdowns. Persist edits before match. |
| Opponent preparation | Enemy card pitch and compact formation/tactic facts; Start match, Squad shortcut | Editing own squad here; redundant collection link and generic body instructions |
| Live match | Existing rich field/22 equal circles, shared state and 180-second clock | Management cards never replace live circles; no renderer downgrade |
| Result/reward desk | Real score/prize receipt → five free cards or cash → scheduled market/coaching | Separate empty reward dialogs, meaningless Skip, instructional subtitle |
| Market | Four full cards, prices, funds-after/replace footer, Restock, Leave | Repeated name/stat panels, hidden costs, controls that refresh stock on navigation |
| Player sheet | Full card, useful stats/role fit/one trait; compare and back in place | Large developer/source prose in the primary view; sources live behind Details |
| Collection | Acquired versions and anonymous unknown backs; filters only known identities | Public unrestricted real-player catalogue in ordinary navigation |
| Records | Whole-number OVR, result/date/peak-XI; card pitch for saved XI | Fractional OVR and empty-state paragraphs |
| Settings | Keep current clear category/setting layout; animate only changing content | Rebuilding whole modal, useless fixed-size prose, unwired audio controls |
| Recovery/confirmations | Specific reason, preserved progress, one safe recovery action | Profile reset as a navigation fix; destructive vague Confirm |

32 proposed origins span all continents; exact list is `origins.json`. Existing six authored starts remain unchanged until content admission. New origins need equal-budget authored names/lineups and stable definitions, not country labels pasted onto England. The design preview illustrates selection only and never claims those 26 rosters are implemented.

Squad target formations: 4-3-3, 4-4-2, 4-2-3-1, 4-1-4-1, 4-2-2-2, 4-3-1-2, 3-4-3, 3-5-2, 5-3-2. Canonical role domains remain the existing ten until separately implemented role behavior warrants more. LM/RM/LWB/RWB/CF may be **display positions mapped explicitly to LW/RW/LB/RB/AM/ST**, with honest familiarity/slot-fit penalties; do not pretend new statistical domains exist. Every formation must have an actual shape, valid eleven and meaningful steering. Out-of-position is a visible badge/value change, never an unresponsive control.

## Motion and interaction

Persistent shell/background/header. Build an incoming page before removing the outgoing page. Crossfade content over 180–220ms with a small eased translation; outgoing remains opaque underneath until incoming is ready. No whole-screen black/empty frame. Preload fonts/cards/textures. Settings keeps categories/margins stable and transitions only right-hand content. Sliders update labels in place.

Hover 80–120ms; selected-card emphasis 120ms; drawer open 180ms/close 140ms. Avoid layout animation/reflow. Kill superseded tweens on rapid navigation; stale callbacks cannot free the new page. Disable outgoing controls and restore named focus to the incoming equivalent. Escape closes the topmost detail/drawer before leaving its caller. Reduced motion swaps immediately with the same selection/focus, no required animation wait. Presentation consumes no gameplay/offer RNG.

Card changes follow the shared finish/readability contract above. Preserve 5:7, all 200 portrait pixels, six stats, edition, four derived tiers and one trait. The prototype subclasses the real component; no portrait production is reopened.

## Implementation and save contract

Re-use current controller/session/content/snapshot boundaries. `CampaignSession.act()` remains the only campaign mutation path. Add revision-guarded `update_plan`, `reroll_offer`, `bank_offer`, `restock_market` commands; none may mutate a published model before successful disk commit. Store immutable spend/choice receipts and recompute cash from the ledger.

Use schema 4 / `campaign_v2` for new runs, with frozen `campaign_v1` content/rules for existing schema-3 runs. Dispatch content by saved version before validation; preserve run/profile/journal backups. No eager rewrite or reroll of an existing run. Existing in-flight matches resume their exact snapshots; old records retain original totals and identity. Legacy runs show their actual reward/market schedule and supported actions in the new presentation; do not offer v2 cash rewards/rerolls against a v1 ledger. Their old decline action can read Keep squad. A failed/incompatible migration remains recoverable and does not reset discovery. Implement and prove legacy fixture/result/acquisition validation before changing new-run defaults.

Build order: shared shell/motion/formatting → targeted card rail/player sheet → persistent Squad + opponent split → ruleset dispatch/receipts → new reward/economy → pyramid/rival/origin data → whole-flow verification. This sequence ships one connected presentation, not a mixture of old/new menus advertised as complete. Exact engineering tasks remain in `tasks/todo.md`.

Acceptance: 720p/1080p native captures, all controls/input/Back/focus, rapid tab/page changes and reduced motion, no blank frames, legal eleven/real tactics, five free/four market full cards, hidden-identity privacy, integer displayed OVR, atomic rerolls/restocks/no duplicate rewards, insufficient funds/exhaustion/cancel, old-run fresh-process continuation and new-run full-route tests. Human visual approval, economic calibration, enjoyment, audio and export stay open until evidenced.

Asset notes: all portraits/fonts come from the current project. Flags are a static MIT-licensed subset of [flag-icons v7.3.2](https://github.com/lipis/flag-icons/tree/v7.3.2); licence retained in `flags/LICENSE`. The original menu arena and four-crest atlas were generated for this proposal. Native vector symbols remain fallbacks. [Provenance](ASSETS.md) records sources and usage. No new runtime dependency.
