extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Acquisition = preload("res://run/acquisition.gd")

func _initialize() -> void:
	var content := Campaign.new()
	assert(content.errors.is_empty())
	var rng := RandomNumberGenerator.new()
	var opening := [{"min":75,"max":79,"weight":100}]
	for seed_value in 200:
		rng.seed = seed_value
		var offer := Acquisition.generate(content.recruits,opening,content.weights.free_slots,[],rng)
		assert(offer.ok and offer.cards.size() == 5 and offer.exceptions.is_empty())
		for id in offer.cards: assert(content.cards[id].rating() >= 75 and content.cards[id].rating() <= 79)
		for chapter in content.weights.free:
			var bands: Array = content.weights.free[chapter]
			offer = Acquisition.generate(content.recruits,bands,content.weights.free_slots,[],rng)
			assert(offer.ok and offer.cards.size() == 5)
			var people := []
			for index in 5:
				var card: Resource = content.cards[offer.cards[index]]
				assert(card.person_id not in people)
				people.append(card.person_id)
				if index < 4: assert(card.primary_role in Acquisition.GROUPS[content.weights.free_slots[index]])
		for market in content.weights.market:
			var bands: Array = content.weights.market[market]
			offer = Acquisition.generate(content.recruits,bands,content.weights.market_slots,[],rng,2)
			assert(offer.ok and offer.cards.size() == 8)
			for index in 2: assert(content.cards[offer.cards[index]].rating() <= bands[0].max)
	var excluded := content.recruits.filter(func(c): return c.primary_role == "GK").map(func(c): return c.person_id)
	var depleted := Acquisition.generate(content.recruits,opening,content.weights.free_slots,excluded,rng)
	assert(depleted.ok and not depleted.exceptions.is_empty())
	for id in depleted.cards: assert(content.cards[id].person_id not in excluded and content.cards[id].rating() <= 79)
	var exhausted := Acquisition.generate(content.recruits,opening,content.weights.free_slots,content.recruits.map(func(c): return c.person_id),rng)
	assert(not exhausted.ok and not exhausted.has("cards"))
	# A missing low band may not reroll into a higher one, even when that is all that exists.
	var high_only: Array = content.recruits.filter(func(c): return c.rating() > 100)
	assert(not Acquisition.generate(high_only,[{"min":65,"max":69,"weight":100},{"min":100,"max":120,"weight":0}],content.weights.free_slots,[],rng).ok)
	var card: Resource = content.recruits[0].duplicate(true)
	var edition: Resource = card.duplicate(true)
	edition.card_id += "_another_edition"
	var versions: Array = [card,edition]
	assert(not Acquisition.generate(versions,[{"min":1,"max":120,"weight":100}],["WILD"],[card.person_id],rng).ok,"Person exclusion applies to all editions")
	assert(not Acquisition.generate(versions,[{"min":1,"max":120,"weight":100}],["WILD","WILD"],[],rng).ok,"One person cannot fill two offer slots")
	print("ACQUISITION: opening, all chapters/markets, 200 seeds, low-stock guarantees, exclusion and depletion checks passed")
	quit()
