extends SceneTree
const Catalogue = preload("res://content/catalogue.gd")
func _initialize() -> void:
	var library := Catalogue.new()
	assert(library.errors.is_empty(),str(library.errors))
	assert(library.cards.size() == 200)
	var people := {}
	for card in library.cards: people[card.person_id] = true
	assert(people.size() == 200 and library.by_id.size() == 200 and library.metadata_by_id.size() == 200)
	for role in ["GK","CB","LB","RB","DM","CM","AM","LW","RW","ST"]:
		assert(library.query("",role).size() == 20)
		for pool in ["Modern","Retired"]: assert(library.query("",role,"",pool).size() == 10)
	for card in library.cards:
		var info := library.metadata(card.card_id)
		var texture := Catalogue.portrait(card,info)
		assert(texture != null and texture.get_size() == Vector2(96,96))
		info.country_name = "Changed copy"
		assert(library.metadata(card.card_id).country_name != info.country_name)
	assert(library.eligible(75,79).is_empty())
	assert(library.eligible(1,120,library.cards.map(func(c): return c.person_id)).is_empty())
	assert(library.query("Mbappé").size() == 1)
	assert(library.query("mbappe").size() == 1)
	var corrupt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/player_catalogue.json"))
	var version: Dictionary = corrupt.cards[0].duplicate(true)
	version.card_id += "_validation_edition"
	corrupt.cards.append(version)
	corrupt.metadata_by_card_id[version.card_id] = corrupt.metadata_by_card_id[corrupt.cards[0].card_id].duplicate(true)
	library.load_data(corrupt)
	assert(library.errors.is_empty() and library.cards.size() == 201)
	assert(library.eligible(1,120,[version.person_id]).size() == 199,"Exclusions apply to every edition of a person")
	corrupt.cards[1].card_id = corrupt.cards[0].card_id
	library.load_data(corrupt)
	assert(not library.errors.is_empty() and library.cards.is_empty())
	print("CATALOGUE: 200 native cards/portraits; coverage, metadata, exclusions and atomic rejection passed")
	quit()
