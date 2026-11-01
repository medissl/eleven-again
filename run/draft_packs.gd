extends RefCounted
static var BALANCE: Dictionary=preload("res://content/master_balance.gd").DATA
const GROUPS := {"GK":["GK"],"DEF":["LB","CB","RB"],"MID":["DM","CM","AM"],"FWD":["LW","RW","ST"]}

static func people_count(cards: Array) -> int:
	var people := {}
	for card in cards: people[card.person_id]=true
	return people.size()

static func focus_card(cards: Array) -> String:
	var eligible: Array=cards.filter(func(card): return card.tier() in ["gold","legend"])
	eligible.sort_custom(func(a,b): return a.rating() > b.rating() if a.rating() != b.rating() else a.card_id < b.card_id)
	return eligible[0].card_id if not eligible.is_empty() else ""

static func rarity(weights: Array, rng: RandomNumberGenerator) -> int:
	var roll := rng.randi_range(1,int(weights.reduce(func(a,b): return a+b,0)))
	for index in weights.size():
		roll-=int(weights[index])
		if roll <= 0: return index
	return weights.size()-1

static func generate(pool: Array, act: int, kind: String, target: String, excluded: Array, rng: RandomNumberGenerator) -> Dictionary:
	if act not in [1,2,3] or kind not in ["starter","standard","position","elite"]: return {"ok":false,"error":"Unknown scout pack."}
	var roles: Array=GROUPS.get(target,[target] if target in ["GK","LB","CB","RB","DM","CM","AM","LW","RW","ST"] else [])
	var available: Array=pool.filter(func(card): return card.person_id not in excluded)
	if kind == "starter": available=available.filter(func(card): return card.rating() in range(75,80))
	if people_count(available) < 4: return {"ok":false,"error":"Fewer than four unique eligible players remain. No coins charged."}
	if kind == "position" and (roles.is_empty() or people_count(available.filter(func(card): return card.primary_role in roles)) < 2): return {"ok":false,"error":"Two unique target-position players are unavailable. Cancel or choose another group; no coins charged."}
	var before := str(rng.state)
	var ids := []
	var odds := []
	var shortages := []
	var weights: Array=[0,10000,0,0] if kind == "starter" else BALANCE.elite_weights[act-1] if kind == "elite" else BALANCE.standard_weights[act-1]
	var used := excluded.duplicate()
	for slot in 4:
		var candidates: Array=available.filter(func(card): return card.person_id not in used and (kind != "position" or slot >= 2 or card.primary_role in roles))
		var tiers := [[],[],[],[]]
		for card in candidates: tiers[BALANCE.rarity_order.find(card.tier())].append(card)
		var effective := []
		for tier in 4: effective.append(weights[tier] if not tiers[tier].is_empty() else 0)
		if effective.reduce(func(a,b): return a+b,0) == 0:
			return {"ok":false,"error":"No players remain in this pack's advertised tiers. No coins charged."}
		if effective != weights: shortages.append(slot)
		odds.append(effective)
		var tier := rarity(effective,rng)
		var people := {}
		for card in tiers[tier]:
			if not people.has(card.person_id): people[card.person_id]=[]
			people[card.person_id].append(card)
		var persons: Array=people.keys()
		persons.sort()
		var editions: Array=people[persons[rng.randi_range(0,persons.size()-1)]]
		editions.sort_custom(func(a,b): return a.card_id < b.card_id)
		var selected: Resource=editions[rng.randi_range(0,editions.size()-1)]
		ids.append(selected.card_id)
		used.append(selected.person_id)
	return {"ok":true,"cards":ids,"kind":kind,"target":target,"act":act,"rng_before":before,"rng_after":str(rng.state),"excluded":excluded.duplicate(),"slot_weights":odds,"shortage_slots":shortages}
