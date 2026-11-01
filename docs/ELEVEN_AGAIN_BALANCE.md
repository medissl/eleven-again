# Eleven Again — balance audit and initial targets

1November2026. **Not calibrated. No1,000-run engine study has been completed.** The master brief's values are initial targets. `tools/audit_master_brief.ps1` currently verifies database integrity and probability arithmetic; it does not simulate football.

## Current content and economy

Native role-weighted OVR remains authoritative. Historical catalogue:200 cards,21 Gold/179 Legend,OVR94–119. Fictional recruits:100 cards,20 Bronze/60 Silver/20 Gold,OVR65–92. Acquisition pool300; starter/enemy-only cards remain excluded. All1,356 authored IDs are unique; all inspected attributes are integral1–120; all portrait PNGs exist. See the hashed machine audit in `reports/master-brief-audit.json`.

Current campaign starts at$8m,16 owned cards,cap18,12 wins/3 defeats. It awards$84m in win prizes,9 victory recruit steps,3 markets after3/7/11 and2 coaching choices after4/8. Free offers have5 cards; markets4. Defeats retry and pay no consolation. These rules are **not** the master economy and will remain frozen for existing saves.

Current36 player traits are context/role/cooldown eligible, with deterministic activation and3 uses in regulation/4 with ET. Effective combined attribute bonuses are capped at6; effective attributes cap at120. There is no measured trait35%/45% trigger layer, eight-card Manager system, +.12 combined probability pipeline or actual xG telemetry yet. Shot `quality` is an internal geometry/context quantity and must not be advertised as calibrated xG.

## Verified arithmetic for proposed four-card packs

| Pack | Act | Bronze/Silver/Gold/Legend per card | At least1 Legend in4 |
|---|---|---|---:|
| Standard/Position |I|56/38/5.8/0.2%|0.797603%|
| Standard/Position |II|25/48/25.5/1.5%|5.866345%|
| Standard/Position |III|8/35/53/4%|15.065344%|
| Elite |I|10/62/27/1%|3.940399%|
| Elite |II|5/35/55/5%|18.549375%|
| Elite |III|0/16/76/8%|28.360704%|

All six weight rows sum to10,000 basis points. Formula: `1-(1-p)^4`. With2 Standard packs in each act, probability of a Legend **offered** is37.092266%; adding1 ActIII Elite pack gives54.933343%. These assume the packs are actually opened and their tier pools satisfy the odds. They do not guarantee a signed Legend. Exhaustion/fallback must be disclosed and reflected in real displayed odds; Monte Carlo and scarcity tests remain pending.

## Proposed coin/legacy budgets

| Act | Win coins | Unique-node loss coins |
|---|---:|---:|
|I|100|35|
|II|150|50|
|III|210|70|

Perfect win income1,840; before final1,630. Initial Standard/Position/Elite prices180/280/480; refresh45; training140. Two Position+two Standard+one Elite cost1,400, leaving230 pre-final in the reference perfect run. New-mode starting coins0 is an explicit assumption, not a conversion of legacy funds.

Direct Bronze/Silver/Gold/Legend listings100/210/420/900. Release caps25/35/55/80; no starter-coin loop. Training adds4 to one chosen stat,≤2 per player/run, max120, no zero-benefit spends. These features/receipts are prepared targets, not live systems.

Legacy:6×(70+100+130+170)=2,820 Marks. Perfect clear:12×35+3×15+100=565, about4.99 perfect clears for the whole tree. Repeated final failures, reloads and replays must not mint more rewards. Profile migration and all24 purchase/effect tests are still required.

## Difficulty reference, not predetermined results

Per-node reference rates: `.84,.79,.75,.68,.76,.73,.69,.64,.69,.66,.62,.55`. Under the brief's independent model—losses advance at1–11, third loss eliminates, final retries while hearts remain—the calculated clear rate is22.523980%. Adding.05 to each node gives35.639531%; adding.10, capped at.95, gives52.095436%. These agree with the brief's rounded examples. The current twelve-win/retry controller follows a different contract; do not label these its completion odds.

## Required real-engine measurements

For each policy and seed record: origin, legal XI/formation/tactics, per-node opponent and result, clear/loss, active ticks and wall duration, actual trait opportunities/activation/execution/result, Manager eligibility/impact, cards offered/signed by tier, unique person exclusions, final XI OVR, coin ledger, spend/surplus, route risk choices and final retries. Compare at least1,000 baseline and1,000 informed runs; capture confidence intervals and policy definitions. Verify identical seeds/pre-match choices produce the same score, scorers, skill events and rewards across Live/Highlights/Instant.

Do not fabricate xG or retrofit an independent score generator. Tune legal opponent squads, style counters, pool coverage, meaningful draft choices and service prices. Keep roster identity/rarity intact. Exact balance, trait reliability, meaningful build advantage and human replayability remain open until these measurements and user playtests exist.
