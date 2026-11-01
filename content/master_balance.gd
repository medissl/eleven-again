extends RefCounted
const VERSION := "campaign_roguelite_v3"
static var DATA: Dictionary=normalize(JSON.parse_string(FileAccess.get_file_as_string("res://content/campaign/master_balance_v1.json")))
static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		for key in value: value[key]=normalize(value[key])
	elif value is Array:
		for index in value.size(): value[index]=normalize(value[index])
	elif value is float and value == floorf(value): return int(value)
	return value
static func act(node: int) -> int: return clampi(node/4+1,1,3)
static func direct_price(card: Resource) -> int: return int(DATA.direct_prices[card.tier()])
static func cost(kind: String) -> int: return int(DATA.prices.get(kind,0))
