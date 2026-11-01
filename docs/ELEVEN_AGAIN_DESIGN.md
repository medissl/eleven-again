# Eleven Again — implementation design and audit

Status:1November2026. **Phases0–5 systems are implemented and native-tested; Phase6 calibration/performance/playtest/export acceptance remains open.** New Run uses `campaign_roguelite_v3`; old saves retain their original controllers. Read `HANDOFF_2026-11-01.md` and `reports/master-brief-implementation.md` for the actual current state. Architecture tables below preserve the initial audit baseline; they are not a claim that the new systems remain absent.

## Authority and preservation

`ELEVEN_AGAIN_CODEX_MASTER_BRIEF.md` is the complete, byte-identical copy of the user-supplied specification, SHA256 `024C92290B0E5CEF4FCFBF83BC4850F2FFD0EC93256C764E7167BF208D2DCF6C`. Its implementation commission supersedes the preceding visual-only scope. Specific live feedback still applies: simple visible goals, previous real referee whistle, unchanged crowd audio, legible names, stable selected/unselected buttons and coherent panel margins.

Keep all200 historical cards/portraits and stable identities, the native rating formula, physical football, automated manager controls, existing collection/records and disk recovery. No roster normalization, simulator replacement, independent Instant Result dice roll or outcome rubber-banding. Preserve **180 active regulation seconds**: the brief's approximately3minutes at2× is an inaccurate description of the established implementation. At2×, active regulation takes90 seconds; stoppages, reports and replay presentation add time.

## Verified architecture

| Boundary | Actual implementation | Preserve / extend |
|---|---|---|
| Game entry | `ui/campaign_app.tscn`, native GDScript Controls; GL Compatibility Godot4.7.2 | Extend the current application, not another app/framework |
| Football | `match/match_sim.gd`,1/60 fixed tick, physical105×68 field,22 actors, explicit ball/period states, seeded `RandomNumberGenerator` | All modes must execute this same state machine |
| Ball/laws | Physical flights, interceptions, rebounds, keeper handling, restarts, offside, discipline, ET and shootout modules | Keep actual field events authoritative |
| Attributes | `content/player_card.gd`: six outfield stats plus five native keeping stats, valid integer1–120; role-weighted rounded OVR | Master role-fit table is advisory only |
| Traits |36 definitions; eligibility/role checks; activation/execution/result events with action/flight/card attribution | Add analytics first; measure before changing trigger reliability |
| Current modifiers | `match/coaching.gd`: six contextual +3 attribute effects, maximum2 principles; combined effective attribute bonus capped at6 and effective stats120 | Not the requested eight Manager Cards or +.12 probability pipeline |
| Preparation |11 legal starters,16 starting owned cards,18-card cap,3 actual formations, native tactics, automatic substitutions, private saved Squad Apply | Preserve legality, keeper coverage and before-match decisions |
| Acquisition | `run/acquisition.gd`: seeded role/band sampling, person-first uniqueness, explicit pool-shortfall exceptions, exclusions for owned/released people | Reuse identity/RNG safety; introduce versioned four-card pack rules |
| Campaign | `run/run_controller.gd`: twelve **wins**, third defeat ends run, defeat retries current fixture, no loss consolation | New scheduled-node advancement requires new-version state/validators |
| Content versions | `campaign_v1` and `campaign_road_v2`; new identities are aliases over existing opponent strength | Freeze both versions for legacy saves |
| Match save | `match/match_snapshot.gd` schema2, accepts1/2, exact engine string, full RNG/player/event state | Add explicit version migration when adding authoritative modifier state |
| Run save | Run schema3; fixed itinerary recomputed and validated; four independent persisted campaign RNG streams | Do not weaken fixed-fixture validation to admit arbitrary route edits |
| Profile | Schema1, exactly5 fields: schema/generation/transaction_id/discoveries/runs | Legacy Marks/tree need a schema migration, not unvalidated extra keys |
| Disk | `persistence/save_store.gd`, native Variant bytes without executable objects, SHA256 envelope schema1,32MiB limit, validated temporary write, atomic replace, one valid backup, corrupt preservation | Keep `CampaignSession.act()` journaled transaction boundary |
| Presentation | Pixel cards, original generated sprites, retained circle markers, buffered skippable replay, current slow walkout, independent music/effects/crowd | Short multi-card packs must reuse/shorten the existing walkout, not repeat four14-second tunnels |

## Database audit

Reproduce: `./tools/audit_master_brief.ps1`. Evidence: `reports/master-brief-audit.json`, including hashes of the four source databases.

| Database | Cards | Bronze | Silver | Gold | Legend | OVR |
|---|---:|---:|---:|---:|---:|---|
| Historical catalogue |200|0|0|21|179|94–119|
| Country starters |96|96|0|0|0|59–64|
| Enemy-only authored cards |960|346|426|188|0|57–94|
| Fictional recruits |100|20|60|20|0|65–92|

There are1,356 unique authored card IDs,300 acquisition cards,6 origins,24 legacy clubs,16 new rival aliases and36 traits. The audit found no out-of-range/nonintegral attributes and no missing portrait PNGs across these datasets. The blank origin-preview portraits were a missing `card_library` binding, repaired in `ui/campaign_screens.gd`; the image files were present. Historical rarity assignments are preserved even though most are Legend. Pack odds must be chosen by explicit tier weights rather than proportional to catalogue population. A second edition must not silently increase a person's selection weight.

## Journey and versioned rules

For the new mode: origin/starter squad → optional starter scouting → prepare → match/viewing mode → truthful result/once-only coins → earned draft or Manager choice → optional market/Squad → next scheduled node. Three acts have4 nodes each; bosses4/8/final12. Losses at1–11 consume a heart and advance; the final must be won, with rematches only while lives remain. Preserve the mixed-nationality owned squad through the fictional World Stage Invitational. Show its one-sentence eligibility explanation once.

New-mode rewards: drafts at2/4/6/8/10/11; Manager choices at1/3/5/7/9; optional route alternatives before3/5/7/9. Maximum3 active Manager Cards. Existing five-card offers, $m funds, retry-on-loss progression and two principles continue unchanged for legacy runs.

Draft packs reveal4, sign exactly1 or take a bounded voucher. Standard/Position/Elite use the brief's act-specific tier weights. Position targets at least2 valid candidates from the requested group, with a truthful shortage/refund path. Commit the seed/offers and revision before presentation. Signing defaults to bench; replacing a starter is deliberate and keeper coverage stays valid. No new payout for starter discards or repeated confirmation/reload.

## Explicit reversible assumptions

1. New-mode tag is `campaign_roguelite_v3`; existing version tags stay frozen. `content/campaign/master_balance_v1.json` is now loaded by the admitted new-mode runtime, with initial targets explicitly uncalibrated.
2. New-mode starting coins=0, since the brief specifies no opening purse. This is a tuning assumption. Never convert an existing $m balance by guessing an exchange rate. Existing16-player starter squads remain intact.
3. Preserve the existing opening signing as a separately labelled starter-scout choice restricted to the current Silver band, adapted to4 candidates in the new mode. It is not one of the six earned Standard packs and cannot silently change their advertised Legend math.
4. A unique-node receipt caps repeatable reward. A first final loss can pay its consolation once; a later final win can top up that node to its win reward, rather than pay both rewards repeatedly. Marks likewise top up unique-node loss→win credit, then award championship/act completion once. This bounded interpretation needs explicit interruption/replay tests.
5. Position-group scouting and existing comprehension/inspection tools remain baseline options. Any suggested Legacy node that would remove a current basic feature will instead grant a bounded extra choice/discount; do not gate working controls behind purchases.
6. Existing traits activate deterministically once eligible, with3 regulation activations/4 in ET and a regulation-derived cooldown. Do not blindly add a35% roll or replace this with2 activations before eligible-opportunity/impact telemetry demonstrates the tradeoff.

## Phase gates and implementation order

**Phase0:** finish current UI baseline verification; preserve the working tree; run model/domain/native save checks; inspect current screenshots. Static architecture/database audit and target arithmetic are now reproducible. Current UI margin/press patch is not yet native-verified because approval review hit a usage limit.

**Phase1:** extend the existing `emit_event` / trait action IDs with before/after modifier attribution and eligible-opportunity counters, without adding RNG draws for analytics. Add a pure reducer for actual match impact. Test same seed/state with analytics enabled/disabled and at1×/2× before adding alternate viewing modes. Keep `shot_quality` labelled as quality; it is not calibrated xG. Introduce a centralized, bounded probability modifier path at real pass/shot/interception resolutions while preserving physical reach/flight/law constraints. Positive probability delta is capped at+.12 across applicable skill/Manager effects; final probability clamps apply only where defined, never to force physical impossibilities.

**Phase2:** admit new-mode schema and frozen content dispatch, four-card packs, visible real odds, Position/Elite services, coin budget, capped training/release/reroll receipts and shorter multi-reveal UX. Then implement Instant Result and Key Highlights by running the exact simulator, with committed snapshot/event parity and pause/report handling. No separate score formula.

**Phase3:** first8 Manager Cards,3 slots, offered3/swap when full, real conditional effects/counterplay and logged impact. Existing six coaching effects remain available to legacy runs. Each new card needs a real engine-event test, noneligible test, cooldown/reset test and combined-cap test before appearing in UI.

**Phase4:** new scheduled-node progression, two deterministic route candidates at selected nodes, honest scouting/risk/rewards, boss moments and final retries. Route choice must be persisted before match commitment and validated against a seed-derived allowed set; preserve old exact itinerary validation for legacy data.

**Phase5:** profile schema migration,24 functional prerequisite hexes, six branches,2,820 Marks total, once-only unique-node/act/champion receipts, pan/zoom/input. No decorative-only unlocks or unlimited compounding discounts.

**Phase6:** whole-flow polish and measured headless runs: baseline highest-OVR policy versus informed synergy policy,≥1,000 complete runs each, preferably5,000. Record actual performance, events, spending, pool shortfalls and completion intervals; tune teams/choices/economy without forcing winners. No claim of enjoyment or exact engine odds from the independent model.

## Current checkpoint limitation

The native command for the latest `tests/pixel_polish_checks.gd` update was **not executed**: automatic approval review could not complete because of account usage limit, explicitly not an unsafe-action determination. Do not evade that check by launching the same action through another tool or permission mode. Earlier native passes remain historical evidence, not validation of the final press/margin/whistle/goal edits. A Git mutation checkpoint also remains pending; use the filesystem recovery snapshot and machine-readable continuation in `tasks/master-brief-checkpoint.json`. Resume native verification first when review is available, then continue the phases autonomously.
