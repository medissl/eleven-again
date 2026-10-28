extends Resource
const Roster = preload("res://content/exhibition_roster.tres")
const ROLES := {"4-3-3":["GK","LB","CB","CB","RB","DM","CM","CM","LW","ST","RW"],"4-4-2":["GK","LB","CB","CB","RB","LW","CM","CM","RW","ST","ST"],"4-2-3-1":["GK","LB","CB","CB","RB","DM","DM","AM","LW","ST","RW"]}
@export var formation := "4-3-3"
@export var attack := "possession"
@export var defence := "balanced"
@export var route := "mixed"
@export var width := 1.0
@export var substitution_plan := "balanced"
@export var late_risk := "none"
@export var cards: Array[Resource] = []
@export var starters: Array[int] = [0,1,2,3,4,5,6,7,8,9,10]
@export var captain := 5
@export var free_kick_taker := 6
@export var corner_taker := 8
@export var penalty_taker := 9
@export var penalty_order: Array[int] = [9,8,10,6,7,5,4,1,2,3,0]
@export var pinned_replacements: Dictionary = {}
@export var bench_order: Array[int] = [11,12,13,14,15]

static func exhibition(team: int) -> Resource:
	var result = load("res://squad/lineup.gd").new()
	for index in range(team*11,team*11+11): result.cards.append(Roster.cards[index])
	for index in range(22+team*5,27+team*5): result.cards.append(Roster.cards[index])
	if team == 1:
		result.attack = "direct"
		result.defence = "high_press"
	return result

static func specialists() -> Resource:
	var result = load("res://squad/lineup.gd").new()
	result.cards.assign(load("res://content/specialist_roster.tres").cards)
	return result

func errors() -> Array[String]:
	var found: Array[String] = []
	if not ROLES.has(formation): found.append("Unknown formation")
	if attack not in ["possession","direct","counter"] or defence not in ["high_press","balanced","deep_block"]: found.append("Unknown tactical approach")
	if substitution_plan not in ["balanced","fresh_legs","protect_shape"]: found.append("Unknown substitution plan")
	if starters.size() != 11: found.append("Select eleven starters")
	var people := {}
	for card in cards:
		found.append_array(card.errors())
		if people.has(card.person_id): found.append("One version per person")
		people[card.person_id] = true
	var selected := {}
	for index in starters:
		if index < 0 or index >= cards.size() or selected.has(index): found.append("Duplicate or missing starter")
		selected[index] = true
	if not starters.is_empty() and starters[0] >= 0 and starters[0] < cards.size() and "GK" not in cards[starters[0]].natural_roles: found.append("Assign a trained goalkeeper")
	for slot in [captain,free_kick_taker,corner_taker,penalty_taker]:
		if slot < 0 or slot >= 11: found.append("Invalid captain/taker")
	var ordered := {}
	for slot in penalty_order: ordered[slot] = true
	if penalty_order.size() != 11 or ordered.size() != 11: found.append("Penalty order must contain every starter once")
	for slot in penalty_order:
		if slot < 0 or slot >= 11: found.append("Invalid penalty order")
	return found

func to_data() -> Dictionary:
	var data := {"cards":cards.map(func(card): return card.to_data())}
	for key in ["formation","attack","defence","route","width","substitution_plan","late_risk","starters","captain","free_kick_taker","corner_taker","penalty_taker","penalty_order","pinned_replacements","bench_order"]:
		var value = get(key)
		data[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return data

static func from_data(data: Dictionary) -> Resource:
	var plan = load("res://squad/lineup.gd").new()
	if data.get("cards") is not Array or data.cards.size() > 18: return null
	for card_data in data.cards:
		if card_data is not Dictionary: return null
		var card = load("res://content/player_card.gd").from_data(card_data)
		if card == null: return null
		plan.cards.append(card)
	for key in ["formation","attack","defence","route","width","substitution_plan","late_risk","starters","captain","free_kick_taker","corner_taker","penalty_taker","penalty_order","pinned_replacements","bench_order"]:
		if not data.has(key): return null
		var original = plan.get(key)
		if original is Array:
			if data[key] is not Array: return null
			for value in data[key]:
				if value is not int: return null
			original.assign(data[key])
		else:
			if typeof(original) != typeof(data[key]): return null
			plan.set(key,data[key])
	return plan if plan.errors().is_empty() else null
