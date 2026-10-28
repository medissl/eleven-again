# Native player cards — 28 October 2026

The user explicitly requested completing the card layer before continuing run work. The playable result is a native 200-edition catalogue, reusable card renderer, player files/comparison and preparation inspection. Recruitment, spending, campaign pools and permanent discovery remain separate systems.

## Delivered

- `content/catalogue.gd` loads validated native `PlayerCard` Resources from the promoted JSON. Country, edition, career pool, portrait binding, source scope and review notes remain keyed by card ID. All 200 definitions retain their original provisional numbers; no match attribute, OVR weight, trait strength or fixture roster was changed.
- 200 original transparent 96×96 portraits are shipped under `assets/portraits/catalogue_200/`, with Godot import metadata and provenance. Runtime needs no authoring package, Python, portrait compositor or network. Nearest filtering, square aspect and integer portrait scaling where practical preserve the pixel treatment.
- One native 5:7 card: clipped corner, archive spine, restrained pitch circle, Barlow OVR/surname and Inter labels, four printed tiers plus distinct line/tick/cross patterns. All information is native text, separate from the portrait. Outfield footer is PAC/SHO/PAS then DRI/DEF/PHY; keeper footer is REF/HAN/POS then DIV/KIC/PHY.
- Known, owned, selected, unavailable, missing-art and undiscovered states. Hidden presentation drops the definition, metadata, texture and identifying tooltip/accessibility text. Known missing portraits retain country/edition/name. Current fixture squad files show owned status; catalogue browsing grants no ownership or discovery.
- Public archive: accent-insensitive player/country/edition search, primary-role/tier/career filters, name/OVR sorting, six-card pages, empty/last-page handling, native keyboard/mouse controls and a pinned comparison.
- Player files show full names/edition/country, natural/familiar roles, primary OVR/tier, all eleven integer base fields, exact signed comparison differences, the current implemented trait's trigger/effect/counterplay/limits, and source titles/scope/HTTPS references where supplied. Ordinary and shootout trait budgets are distinguished. Card OVR/tier never multiplies match power.
- Preparation has **Player archive** and a **Card** button per lineup row. Opening/browsing/closing preserves the plans, match state and RNG. Escape closes focused search, modal Tab stays within the active screen, focus returns to the caller, reduced motion skips fades and rapid close input resolves once.

Cards share stable `person_id` across authored editions and distinct `card_id` values. The present source has exactly 200 unique people; the loader also accepts further valid editions, and eligibility exclusions apply across every edition of an excluded person. Future recruitment receives an explicit OVR range; this high-rated catalogue is not an automatic early-run pool.

## Verification

Godot **4.7.2.stable.official.ed1daf0bf**, GL Compatibility, Intel Iris Xe. Headless editor import/parse completed with no script errors. The existing football/presentation suite passed **109,763 assertions, zero failures**, with unchanged baseline fixture results. New catalogue and native UI runners also passed; their output was checked for script errors in addition to exit status.

`tests/catalogue_checks.gd` checks all 200 native definitions/portrait textures, 200 people/card IDs/metadata bindings, 20 per role and 10 Modern/10 Retired per role, metadata copy isolation, accent/plain spelling, empty early-stage pools, owned/released-person exclusions, additional editions and atomic duplicate-card rejection.

`tests/card_ui_checks.gd` binds all 200 definitions without mutating them, checks integer display/masked identity/missing art, last/empty pages, mouse pinning, native Enter/Escape/Tab, source access/scrolling, comparison, same-frame rapid Escape during a fade, and actual preparation entry/exit. It explicitly attempts match updates while browsing and confirms the match/RNG and submitted plans remain unchanged.

Native GL renders and viewport input were reviewed at **1280×720 and 1920×1080**, normal and **125% UI**. Initial cramped stat columns, decimal rendering, footer clipping, an encoded dash and search-Escape handling were corrected before final captures. The tier/long-name/120 boards are authored layout scenarios, not additions to the playable roster. No permanent index or recruitment transaction is claimed by these checks.

Representative final captures:

- [Archive, 720p](screenshots/cards-archive-1280x720.png) / [1080p enlarged](screenshots/cards-archive-large-1920x1080.png).
- [Full player file](screenshots/cards-file-large-1280x720.png) / [trait and source detail](screenshots/cards-trait-source-large-1280x720.png).
- [Pinned comparison](screenshots/cards-compare-large-1280x720.png).
- [All four tiers, 120 and long name](screenshots/cards-tiers-1920x1080.png).
- [Hidden, missing-art, owned and unavailable](screenshots/cards-identity-1920x1080.png).
- [Preparation entry](screenshots/cards-preparation-1280x720.png) / [fixture keeper file](screenshots/cards-fixture-file-1280x720.png).

Reproduce from the project directory:

```powershell
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/catalogue_checks.gd
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/card_ui_checks.gd
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/card_ui_checks.gd -- --capture
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/card_ui_checks.gd -- --capture --large
& 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
```

## Content and scope limits

The supplied 200-card set contains 179 Legend and 21 Gold editions (OVR 94–119). Four-tier renderer boundaries are verified, but this collection contains no Bronze/Silver world-player editions. Fictional opening squads remain intact. Prices, odds and campaign pool distribution were not invented; those belong to the run/recruitment tasks.

Portraits remain supplied modular likeness studies, including known accessory/era limitations. Ratings are original provisional game design, not official scouting or EA/FIFA data. Identity references have mixed verification scope, exposed in the player files. No claim of final likeness accuracy, balanced recruitment, ownership persistence, historical fact checking of all 200 or an exported build is made.

The source workbook is an authoring/review view; approved changes still require source transfer, re-export and native validation. Runtime snapshots and portraits are now vendored, rather than read from `.gdignore`d output packages.

Tasks 6.3a/6.4a complete this card boundary. Remaining 6.3/6.4 work concerns campaign eligibility/prices, acquisition flows and persistent discovered-version index/reveals. Next coherent implementation remains the short-run progression/recruitment/market milestone. Local branch: `codex/player-cards`; first content checkpoint `e6db97f`. No push, merge or release.
