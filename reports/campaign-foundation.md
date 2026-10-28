# Twelve-win campaign foundation

28 October 2026. Godot 4.7.2.stable.official.ed1daf0bf. Branch `codex/campaign-foundation`. This is the first implementation batch for the full run handoff, not the complete management feature. F5 still opens the accepted preparation/match sandbox. No campaign menu, automatic campaign autosave or profile is exposed yet.

## Implemented

- `content/campaign.gd` admits 1,156 additional immutable native card definitions: six origins/96 starters, 100 fictional recruits and 960 enemy-only definitions in 60 stage rosters. Together with the existing 200 historical cards, acquisition has 300 candidates. All 24 original SVG badges, 100 pixel PNGs and six source data files match their approved source bytes. The public archive remains its curated 200 editions; enemy variants/starters stay out of acquisition and archive pools.
- All 66 plans validate, origin XIs average 62.82, opposition XIs fit the twelve stage budgets, and regular/final starting XIs have two/four signature traits. Plans own private card definitions. Twelve opponent assignments are seeded and frozen, with three distinct regular clubs plus one final per chapter. Prices derive from primary base OVR with the approved $70–80m peak interval.
- `run/run_controller.gd` owns explicit opening/preparation/match/result/recruit/market/coaching/terminal steps. Revision guards reject duplicate/stale actions. A committed attempt uses the existing native football model with 180-second regulation, ET and penalties. Results come from its actual winner/report; losses retain cash/roster and retry the same opponent with a fresh committed seed. Twelve wins pay $84m total; starting cash makes $92m, of which at most $82m exists at Market III. Terminal results offer no subsequent rewards.
- Recruitment rolls one band per slot, then a uniform eligible person and edition. Owned/released identities and duplicate people are excluded across editions. Depletion falls downward within the checkpoint bands, then to a bounded wildcard with a recorded exception; it cannot reroll upward. Insufficient coverage fails without changing state/RNG. All ten free decisions and three fixed eight-player/two-buy markets are represented. Market stock/purchases persist when closed/reopened and expire at the next committed fixture.
- Signing validates money, explicit replacement at 18, last-trained-GK protection and identity before changing a private copy. Release returns $0. Lineup/bench/pins are repaired and preserved as appropriate. Acquisition IDs are retained for future profile transactions. Two seeded coaching offers exclude owned principles, but **their football effects are not installed yet**. `best_owned()` supplies the required stable base-OVR/card-ID ordering; no live menu preview is claimed.
- `run/run_state.gd` checks plain finite data, content/identity/ownership/financial/result ledgers, seeded fixtures/attempts and match snapshots before restoration. `persistence/save_store.gd` uses checksummed native Variant bytes with executable object decoding disabled, preserving int64 RNG/Vector2 types. Writes verify a flushed temporary file, retain one previous valid backup and atomically rename. Repairing a damaged primary preserves its original bytes separately.

## Verification actually run

| Check | Result / limits |
|---|---|
| `tests/campaign_content_checks.gd` | All 1,356 total definitions, 66 plans, 300 acquisition cards, 24 badge textures and 100 repeatable twelve-fixture itineraries pass |
| `tests/acquisition_checks.gd` | 200 seeds across opening/all chapters/all markets, low-band stock, role exhaustion, downward-only fallback, complete exhaustion and multi-edition exclusions pass |
| `tests/campaign_checks.gd` | Authored full twelve-win and three-loss sequences, all ten/three/two decisions, exact income, rematch identity/seed, duplicate result/action, fixed stock, two-buy cap, last keeper, failed funds/replacement/content and immutable preparation checks pass. One actual full native knockout fixture supplies its true report to the ledger. The twelve-win sequence uses authored outcomes; it is not a measured bot campaign |
| `tests/save_checks.gd` | Actual disposable disk writes/overwrite, backup selection, corrupt-primary preservation, invalid cash/content/data rejection, restored match state and 600 future-tick equality pass |
| Two separate Godot executables | `--write-probe`, then `--resume-probe` in a fresh process reproduce exactly the expected future football/RNG signature from disk. Test files are isolated under a unique `user://campaign_relaunch_test_*` folder and removed afterwards |
| Existing catalogue regression | All 200 original native cards/portraits and original archive coverage/exclusions pass |
| Existing football/presentation regression | **109,763 checks, zero failures**, unchanged recorded seed scores and attribute-pair results |
| Godot headless import/parse | Clean; new `.gd.uid`/asset `.import` metadata retained |

No management screen changed, so no new visual acceptance or mouse/keyboard campaign flow is claimed. The existing complete native CardView remains the intended component. No export, whole-run balance, human enjoyment, forced process-kill recovery or cross-engine determinism claim.

Run focused checks with the existing executable pattern, substituting each `res://tests/...gd` above. For the fresh-process probe pass `-- --write-probe --store-root=user://campaign_relaunch_test_UNIQUE`, then `-- --resume-probe --store-root=user://campaign_relaunch_test_UNIQUE` to a second invocation. The unique suffix must be identifier-safe and the location must not already hold a probe.

## Next integration slice

Keep the full twelve-win target. Add the durable run/profile transaction coordinator and journal replay, discovery/records/exact best legal XI, campaign suspensions/academy coverage and actual contextual coaching effects. Then connect native management/preparation/match menus and autosave checkpoints, retaining full cards/defeat pips and deriving Continue exclusively from a valid disk run. Validate journal crash boundaries and terminal cleanup before exposing the campaign, then inspect real native 720p/1080p normal/enlarged UI and complete campaign flows. Tasks 3.2–3.6, 4.1–4.4, 5.4–5.5 and relevant content/UI gates remain open until those boundaries are complete.
