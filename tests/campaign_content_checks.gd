extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Catalogue = preload("res://content/catalogue.gd")

func _initialize() -> void:
	var content := Campaign.new()
	assert(content.errors.is_empty(),str(content.errors))
	assert(content.cards.size() == 1356 and content.recruits.size() == 300)
	assert(Catalogue.new().cards.size() == 200,"Public archive keeps its curated catalogue")
	var people := {}
	for card in content.recruits:
		assert(not people.has(card.person_id))
		people[card.person_id] = true
		assert(not card.person_id.begins_with("enemy_") and not card.person_id.begins_with("starter_"))
	for country in content.countries.values():
		var plan := content.country_plan(country.id)
		assert(plan != null and plan.cards.size() == 16)
		assert(plan.cards.filter(func(c): return "GK" in c.natural_roles).size() == 2)
		assert(Campaign.xi_rating(plan) >= 62 and Campaign.xi_rating(plan) <= 64)
		var old_rating: int = content.cards[plan.cards[0].card_id].rating()
		plan.cards[0].keeper_attributes.REF = 1
		assert(content.cards[plan.cards[0].card_id].rating() == old_rating,"Plans own private card definitions")
	for variant in content.variants.values():
		var plan := content.opponent_plan(variant.id)
		assert(plan != null and plan.errors().is_empty())
	for club_id in content.clubs:
		var texture: Texture2D = load(content.badge_path(club_id))
		assert(texture != null and texture.get_image().get_pixel(0,0).a == 0)
	for seed_value in 100:
		var assignments := content.itinerary(seed_value)
		assert(assignments.size() == 12 and assignments == content.itinerary(seed_value))
		for chapter in 3:
			var selected := []
			for offset in 4:
				var fixture: Dictionary = assignments[chapter*4+offset]
				assert(content.variants.has(fixture.variant_id))
				assert(fixture.club_id not in selected)
				selected.append(fixture.club_id)
				assert(content.clubs[fixture.club_id].is_boss == (offset == 3))
	assert(content.itinerary(1) != content.itinerary(2))
	for anchor in content.rules.price_anchors_millions: assert(content.price(int(anchor[0])) == int(anchor[1])*1000000)
	assert(content.price(64) == -1 and content.price(121) == -1)
	assert(content.price(76) == 6000000 and content.price(77) == 7000000)
	print("CAMPAIGN CONTENT: 1356 definitions, 300 acquisition cards, ",content.clubs.size()," badges and 100 seeded twelve-fixture itineraries passed")
	quit()
