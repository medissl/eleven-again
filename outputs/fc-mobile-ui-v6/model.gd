extends RefCounted
## Isolated design arithmetic. No actual CampaignSession, saves, profile or gameplay RNG.
const ROOT := "res://outputs/fc-mobile-ui-v6/"
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"economy.json"))
var cash := 32000000
var wins := 6
var defeats := 1
var origin := "ENG"
var rolls := 0
var market_bought := 0
var market_restocked := false
var choice := 0
var revision := 0
var receipts: Array = []
var purchased: Array[String] = []

func money(value: int) -> String: return "$%dm" % roundi(value/1000000.0)
func reroll_cost() -> int: return int(rules.draft_reroll_prices_m[rolls])*1000000 if rolls < 2 else -1
func reroll() -> bool:
	var cost := reroll_cost()
	if cost < 0 or cash < cost: return false
	cash -= cost
	rolls += 1
	choice = 0
	revision += 1
	receipts.append({"kind":"reroll","cost":cost,"revision":revision})
	return true

func new_run(country: String) -> void:
	origin = country
	cash = int(rules.start_cash)
	wins = 0
	defeats = 0
	rolls = 0
	market_bought = 0
	market_restocked = false
	purchased.clear()
	receipts.clear()
	revision += 1

func bank() -> void:
	cash += int(rules.bank_instead_m)*1000000
	receipts.append({"kind":"bank","amount":int(rules.bank_instead_m)*1000000})
	rolls = 0
	revision += 1

func price(ovr: int) -> int:
	for band in rules.price_bands:
		if ovr >= band[0] and ovr <= band[1]: return roundi(lerpf(band[2],band[3],float(ovr-band[0])/maxf(1,band[1]-band[0])))*1000000
	return 3000000

func buy(ovr: int, card_id: String = "") -> bool:
	var cost := price(ovr)
	if market_bought >= 2 or cash < cost or (not card_id.is_empty() and card_id in purchased): return false
	cash -= cost
	market_bought += 1
	if not card_id.is_empty(): purchased.append(card_id)
	revision += 1
	receipts.append({"kind":"buy","cost":cost})
	return true

func restock() -> bool:
	var visit := clampi(int(wins/3),1,3)-1
	var cost := int(rules.market_restock_prices_m[visit])*1000000
	if market_restocked or market_bought >= 2 or cash < cost: return false
	cash -= cost
	market_restocked = true
	revision += 1
	receipts.append({"kind":"restock","cost":cost})
	return true
