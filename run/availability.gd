extends RefCounted
## Campaign bans are served by completed attempts; anonymous cover exists only in match plans.
const Card = preload("res://content/player_card.gd")
const Lineup = preload("res://squad/lineup.gd")
const SETTINGS := ["formation","attack","defence","route","width","substitution_plan","late_risk","captain","free_kick_taker","corner_taker","penalty_taker"]

static func banned(book: Dictionary) -> Array:
	var result: Array = book.keys().filter(func(id): return book[id].get("ban",0) > 0)
	result.sort()
	return result

static func advance(book: Dictionary, events: Array, served: Array, match_cards: Array) -> Dictionary:
	var result := book.duplicate(true)
	for person in served: result.erase(person)
	var people := {}
	for card in match_cards:
		if not card.card_id.begins_with("academy_"): people[card.card_id] = card.person_id
	var incidents := {}
	for event in events:
		if event.get("team") != 0 or event.get("kind") not in ["yellow_card","red_card"] or not people.has(event.get("actor_card")): continue
		var person: String = people[event.actor_card]
		if not incidents.has(person): incidents[person] = {"yellow":0,"red":false}
		if event.kind == "red_card": incidents[person].red = true
		else: incidents[person].yellow += 1
	for person in incidents:
		var entry: Dictionary = result.get(person,{"yellow":0,"ban":0}).duplicate()
		entry.yellow += incidents[person].yellow
		if incidents[person].red or entry.yellow >= 3:
			entry.yellow = 0
			entry.ban = 1
		result[person] = entry
	return result

static func academy(run_id: String, index: int, role: String) -> Resource:
	var card := Card.new()
	card.person_id = "academy_%s_%02d" % [run_id.sha256_text().left(12),index]
	card.card_id = card.person_id
	card.display_name = "Academy keeper" if role == "GK" else "Academy player"
	card.primary_role = role
	card.natural_roles.assign([role])
	for key in card.attributes: card.attributes[key] = 48
	for key in card.keeper_attributes: card.keeper_attributes[key] = 48
	return card

static func is_academy(record: Dictionary, run_id: String) -> bool:
	var id: String = record.get("card_id","")
	var suffix := id.right(2)
	if not suffix.is_valid_int() or int(suffix) < 0 or int(suffix) > 10 or record.get("primary_role") not in Card.WEIGHTS: return false
	return record == academy(run_id,int(suffix),record.primary_role).to_data()

static func plan(data: Dictionary) -> Resource:
	var owned: Resource = Lineup.from_data(data.plan)
	if owned == null: return null
	var result := Lineup.new()
	for key in SETTINGS: result.set(key,owned.get(key))
	var unavailable := banned(data.discipline)
	result.cards.assign(owned.cards.filter(func(card): return card.person_id not in unavailable))
	var count := 0
	if result.cards.filter(func(card): return "GK" in card.natural_roles).is_empty():
		result.cards.append(academy(data.run_id,count,"GK"))
		count += 1
	while result.cards.size() < 11:
		result.cards.append(academy(data.run_id,count,Lineup.ROLES[result.formation][result.cards.size()]))
		count += 1
	var ids: Array = result.cards.map(func(card): return card.card_id)
	var selected := []
	for index in owned.starters: selected.append(ids.find(owned.cards[index].card_id))
	fill_slots(result,selected)
	result.starters.assign(selected)
	result.bench_order.clear()
	for index in owned.bench_order:
		var available: int = ids.find(owned.cards[index].card_id)
		if available >= 0 and available not in selected: result.bench_order.append(available)
	result.penalty_order.assign(owned.penalty_order)
	for slot in owned.pinned_replacements:
		var index: int = owned.pinned_replacements[slot]
		result.pinned_replacements[slot] = ids.find(owned.cards[index].card_id) if index >= 0 else -1
	result.refresh_bench_order()
	return result if result.errors().is_empty() else null

static func fill_slots(plan_value: Resource, selected: Array) -> void:
	if selected[0] < 0 or "GK" not in plan_value.cards[selected[0]].natural_roles:
		var keeper := -1
		for index in plan_value.cards.size():
			if "GK" in plan_value.cards[index].natural_roles and (keeper < 0 or plan_value.cards[index].rating("GK") > plan_value.cards[keeper].rating("GK")): keeper = index
		if keeper >= 0:
			var old_slot: int = selected.find(keeper)
			if old_slot >= 0: selected[old_slot] = -1
			selected[0] = keeper
	for slot in 11:
		if selected[slot] >= 0: continue
		var best := -1
		for index in plan_value.cards.size():
			if index in selected: continue
			var role: String = Lineup.ROLES[plan_value.formation][slot]
			if best < 0 or plan_value.cards[index].rating(role,true) > plan_value.cards[best].rating(role,true): best = index
		selected[slot] = best

static func remember(owned: Resource, prepared: Resource) -> Resource:
	for key in SETTINGS: owned.set(key,prepared.get(key))
	var ids: Array = owned.cards.map(func(card): return card.card_id)
	var selected := []
	for index in prepared.starters: selected.append(ids.find(prepared.cards[index].card_id))
	# Banned owned players can remain in the saved future plan; they never enter this match.
	fill_slots(owned,selected)
	owned.starters.assign(selected)
	owned.penalty_order.assign(prepared.penalty_order)
	owned.bench_order.clear()
	for index in prepared.bench_order:
		var original: int = ids.find(prepared.cards[index].card_id)
		if original >= 0 and original not in selected: owned.bench_order.append(original)
	owned.pinned_replacements.clear()
	for slot in prepared.pinned_replacements:
		var index: int = prepared.pinned_replacements[slot]
		owned.pinned_replacements[slot] = ids.find(prepared.cards[index].card_id) if index >= 0 else -1
	owned.refresh_bench_order()
	return owned
