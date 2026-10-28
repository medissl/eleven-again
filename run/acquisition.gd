extends RefCounted
## No ownership, UI or disk mutation here. The caller commits RNG and choices together.
const GROUPS := {"GK":["GK"],"DEF":["CB","LB","RB"],"MID":["DM","CM","AM"],"ATT":["LW","RW","ST"]}

static func generate(pool: Array, bands: Array, slots: Array, excluded: Array, rng: RandomNumberGenerator, low_guarantee: int = 0) -> Dictionary:
	var candidates := []
	var used := excluded.duplicate()
	var exceptions := []
	for slot_index in slots.size():
		var band_index := 0
		if slot_index >= low_guarantee:
			var weight_total := 0
			for band in bands: weight_total += int(band.weight)
			if weight_total <= 0: return {"ok":false,"error":"Invalid acquisition weights"}
			var roll := rng.randi_range(1,weight_total)
			for index in bands.size():
				roll -= int(bands[index].weight)
				if roll <= 0:
					band_index = index
					break
		var group: String = slots[slot_index]
		var eligible := []
		var chosen_band := band_index
		for index in range(band_index,-1,-1):
			eligible = in_band(pool,bands[index],group,used)
			if not eligible.is_empty():
				chosen_band = index
				break
		if eligible.is_empty():
			for index in range(band_index,-1,-1):
				eligible = in_band(pool,bands[index],"WILD",used)
				if not eligible.is_empty():
					chosen_band = index
					break
			if not eligible.is_empty(): exceptions.append({"slot":slot_index,"role":group,"reason":"role_exhausted","rolled_band":band_index,"used_band":chosen_band})
		elif chosen_band != band_index:
			exceptions.append({"slot":slot_index,"role":group,"reason":"lower_band","rolled_band":band_index,"used_band":chosen_band})
		if eligible.is_empty(): return {"ok":false,"error":"Not enough eligible people to supply this fixed offer. Previous run state is retained."}
		# Choose a person first: extra editions never increase that person's weight.
		var people := {}
		for card in eligible:
			if not people.has(card.person_id): people[card.person_id] = []
			people[card.person_id].append(card)
		var identities: Array = people.keys()
		identities.sort()
		var person: String = identities[rng.randi_range(0,identities.size()-1)]
		var editions: Array = people[person]
		editions.sort_custom(func(a,b): return a.card_id < b.card_id)
		var picked: Resource = editions[rng.randi_range(0,editions.size()-1)]
		candidates.append(picked.card_id)
		used.append(person)
	return {"ok":true,"cards":candidates,"exceptions":exceptions}

static func in_band(pool: Array, band: Dictionary, group: String, excluded: Array) -> Array:
	return pool.filter(func(card): return card.person_id not in excluded and card.rating() >= band.min and card.rating() <= band.max and (group == "WILD" or card.primary_role in GROUPS.get(group,[])))
