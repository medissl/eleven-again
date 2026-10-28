extends SceneTree
const Catalogue = preload("res://content/catalogue.gd")
func _initialize() -> void:
	var library := Catalogue.new()
	assert(library.errors.is_empty(),str(library.errors))
	assert(library.cards.size() == 200)
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
	var corrupt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/player_catalogue.json"))
	corrupt.cards[1].person_id = corrupt.cards[0].person_id
	library.load_data(corrupt)
	assert(not library.errors.is_empty() and library.cards.is_empty())
	print("CATALOGUE: 200 native cards/portraits; coverage, metadata, exclusions and atomic rejection passed")
	quit()
