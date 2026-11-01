param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$weights = @{ST=@(15,40,5,20,0,20);LW=@(25,20,20,25,0,10);RW=@(25,20,20,25,0,10);AM=@(10,25,30,25,0,10);CM=@(10,10,35,20,15,10);DM=@(10,5,25,10,30,20);CB=@(15,0,10,5,40,30);LB=@(25,5,20,10,25,15);RB=@(25,5,20,10,25,15);GK=@(30,20,25,15,10)}
$sources = @('content/player_catalogue.json','content/campaign/country_starters.json','content/campaign/enemy_rosters.json','content/campaign/fictional_recruits.json')
$datasets = @()
$allCards = @()
foreach ($relative in $sources) {
    $path = Join-Path $ProjectRoot $relative
    $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $tiers = [ordered]@{bronze=0;silver=0;gold=0;legend=0}
    $roles = @{}
    $ratings = @()
    $invalid = @()
    $missingArt = @()
    foreach ($card in $data.cards) {
        $allCards += $card
        $keys = if ($card.primary_role -eq 'GK') { @('REF','HAN','POS','DIV','KIC') } else { @('PAC','SHO','PAS','DRI','DEF','PHY') }
        $stats = if ($card.primary_role -eq 'GK') { $card.keeper_attributes } else { $card.attributes }
        $total = 0.0
        for ($index=0; $index -lt $keys.Count; $index++) { $total += $stats.($keys[$index]) * $weights[$card.primary_role][$index] }
        $ovr = [int][Math]::Floor($total/100.0+0.5)
        $ratings += $ovr
        $tier = if ($ovr -lt 70) {'bronze'} elseif ($ovr -lt 85) {'silver'} elseif ($ovr -lt 100) {'gold'} else {'legend'}
        $tiers[$tier]++
        if (-not $roles.ContainsKey($card.primary_role)) { $roles[$card.primary_role]=0 }
        $roles[$card.primary_role]++
        foreach ($field in @($card.attributes.PSObject.Properties)+@($card.keeper_attributes.PSObject.Properties)) {
            if ($field.Value -lt 1 -or $field.Value -gt 120 -or $field.Value -ne [Math]::Floor($field.Value)) { $invalid += $card.card_id+'/'+$field.Name }
        }
        $portraitFound = $false
        foreach ($folder in @('assets/portraits/catalogue_200','assets/portraits/run_recruits')) {
            if (Test-Path -LiteralPath (Join-Path $ProjectRoot ($folder+'/'+$card.portrait_id+'.png'))) { $portraitFound=$true }
        }
        if (-not $portraitFound) { $missingArt += $card.card_id }
    }
    $range = $ratings | Measure-Object -Minimum -Maximum
    $datasets += [ordered]@{path=$relative;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;cards=@($data.cards).Count;unique_people=@($data.cards.person_id | Sort-Object -Unique).Count;tiers=$tiers;roles=$roles;minimum_ovr=$range.Minimum;maximum_ovr=$range.Maximum;invalid_stats=$invalid;missing_portrait_files=$missingArt}
}
$rules = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/run_rules.json') -Raw | ConvertFrom-Json
$acquisition = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/acquisition_weights.json') -Raw | ConvertFrom-Json
$starters = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/country_starters.json') -Raw | ConvertFrom-Json
$enemies = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/enemy_clubs.json') -Raw | ConvertFrom-Json
$rivals = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/road_rivals.json') -Raw | ConvertFrom-Json
$traits = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/traits.json') -Raw | ConvertFrom-Json
$targets = Get-Content -LiteralPath (Join-Path $ProjectRoot 'content/campaign/master_balance_v1.json') -Raw | ConvertFrom-Json
function Get-ClearProbability([double[]]$Rates) {
    $dp = @(1.0,0.0,0.0)
    for ($node=0; $node -lt 11; $node++) {
        $p = $Rates[$node]
        $dp = @(($dp[0]*$p),($dp[1]*$p+$dp[0]*(1-$p)),($dp[2]*$p+$dp[1]*(1-$p)))
    }
    $total = 0.0
    for ($losses=0; $losses -lt 3; $losses++) { $total += $dp[$losses]*(1-[Math]::Pow(1-$Rates[11],3-$losses)) }
    return $total
}
$packChecks = @()
foreach ($kind in @('standard','elite')) {
    $rows = $targets.($kind+'_weights')
    for ($act=0; $act -lt 3; $act++) {
        $sum = ($rows[$act] | Measure-Object -Sum).Sum
        if ($sum -ne $targets.rarity_weight_total) { throw 'Pack weights do not sum to100%' }
        $p = $rows[$act][3]/[double]$targets.rarity_weight_total
        $packChecks += [ordered]@{kind=$kind;act=($act+1);weight_sum=$sum;legend_per_card=$p;at_least_one_legend_in_four=(1-[Math]::Pow(1-$p,4))}
    }
}
$noLegend = [Math]::Pow(0.998,8)*[Math]::Pow(0.985,8)*[Math]::Pow(0.96,8)
$report = [ordered]@{
    schema=1;date='2026-11-01';kind='static_source_audit_not_engine_simulation';brief_sha256=(Get-FileHash -LiteralPath (Join-Path $ProjectRoot 'docs/ELEVEN_AGAIN_CODEX_MASTER_BRIEF.md')).Hash
    datasets=$datasets;total_authored_cards=$allCards.Count;unique_card_ids=@($allCards.card_id | Sort-Object -Unique).Count
    duplicate_card_ids=@($allCards | Group-Object card_id | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
    acquisition_pool_cards=($datasets[0].cards+$datasets[3].cards);origins=@($starters.countries).Count;legacy_clubs=@($enemies.teams).Count;new_rival_aliases=@($rivals.rivals).Count;trait_definitions=@($traits.traits).Count
    current_rules=[ordered]@{starting_cash=$rules.starting_cash;total_win_prizes=($rules.stages.win_prize | Measure-Object -Sum).Sum;starting_squad=$rules.starting_squad;squad_cap=$rules.squad_cap;regulation_seconds=$rules.regulation_active_seconds;target_wins=$rules.target_wins;defeat_limit=$rules.defeat_limit;free_offer_slots=@($acquisition.free_slots).Count;market_slots=@($acquisition.market_slots).Count;recruit_after=@($rules.stages | Where-Object recruit | Select-Object -ExpandProperty stage);market_after=@($rules.stages | Where-Object {$null -ne $_.market} | Select-Object -ExpandProperty stage);coaching_after=@($rules.stages | Where-Object coaching | Select-Object -ExpandProperty stage)}
    initial_target_arithmetic=[ordered]@{packs=$packChecks;six_earned_legend_offered=(1-$noLegend);plus_act_three_elite=(1-$noLegend*[Math]::Pow(0.92,4));perfect_coins=1840;prefinal_coins=1630;legacy_total=2820;perfect_clear_marks=565;independent_run_clear=(Get-ClearProbability $targets.benchmark_node_win_rates);informed_plus_05=(Get-ClearProbability @($targets.benchmark_node_win_rates | ForEach-Object {[Math]::Min(0.95,$_+0.05)}));informed_plus_10=(Get-ClearProbability @($targets.benchmark_node_win_rates | ForEach-Object {[Math]::Min(0.95,$_+0.10)}));calibrated_in_engine=$false}
    native_baseline_status='latest_button_margin_patch_unverified_due_automatic_approval_review_usage_limit';mutates_runtime=$false
}
$destination = Join-Path $ProjectRoot 'reports/master-brief-audit.json'
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $destination -Encoding utf8
[PSCustomObject]$report | Select-Object total_authored_cards,unique_card_ids,acquisition_pool_cards,origins,legacy_clubs,new_rival_aliases,trait_definitions | Format-List
$datasets | ForEach-Object { [PSCustomObject]@{path=$_.path;cards=$_.cards;bronze=$_.tiers.bronze;silver=$_.tiers.silver;gold=$_.tiers.gold;legend=$_.tiers.legend;minimum=$_.minimum_ovr;maximum=$_.maximum_ovr;invalid=$_.invalid_stats.Count;missing_portraits=$_.missing_portrait_files.Count} } | Format-Table -AutoSize
