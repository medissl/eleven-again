extends RefCounted
## Authored content only. Browsing never grants ownership or changes fixture plans.
const Card = preload("res://content/player_card.gd")
var cards: Array[Resource] = []
var by_id: Dictionary = {}
var metadata_by_id: Dictionary = {}
var errors: Array[String] = []

func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/player_catalogue.json"))
	load_data(data)

func load_data(data: Variant) -> void:
	cards.clear()
	by_id.clear()
	metadata_by_id.clear()
	errors.clear()
	if data is not Dictionary or data.get("cards") is not Array or data.get("metadata_by_card_id") is not Dictionary:
		errors.append("The player catalogue could not be read.")
		return
	var people := {}
	for record in data.cards:
		var card: Resource = Card.from_data(record) if record is Dictionary else null
		if card == null:
			errors.append("Invalid player definition.")
			continue
		if by_id.has(card.card_id) or people.has(card.person_id): errors.append("Duplicate player identity: "+card.card_id)
		if card.trait_id.is_empty() or card.primary_role not in Card.Traits.catalogue[card.trait_id].positions: errors.append("Incompatible signature trait: "+card.card_id)
		var info = data.metadata_by_card_id.get(card.card_id)
		if info is not Dictionary:
			errors.append("Missing edition metadata: "+card.card_id)
			continue
		var path: String = "res://assets/portraits/catalogue_200/"+card.portrait_id+".png"
		if not card.portrait_id.is_valid_identifier() or info.get("target_asset_path") != path: errors.append("Invalid portrait binding: "+card.card_id)
		if info.get("ovr") != card.rating() or info.get("tier") != card.tier(): errors.append("Stale rating metadata: "+card.card_id)
		for key in ["country_code","country_name","version_label","identity_reference_id","reference_scope"]:
			if info.get(key) is not String or info[key].is_empty(): errors.append("Missing "+key+": "+card.card_id)
		if info.get("career_pool") not in ["Modern","Retired"]: errors.append("Invalid career pool: "+card.card_id)
		cards.append(card)
		by_id[card.card_id] = card
		people[card.person_id] = true
		metadata_by_id[card.card_id] = info.duplicate(true)
	if not errors.is_empty():
		cards.clear()
		by_id.clear()
		metadata_by_id.clear()

func metadata(card_id: String) -> Dictionary:
	return metadata_by_id.get(card_id,{}).duplicate(true)

func query(search: String = "", role: String = "", tier: String = "", pool: String = "", order: String = "name") -> Array[Resource]:
	var result: Array[Resource] = []
	var needle := search.strip_edges().to_lower()
	for card in cards:
		var info: Dictionary = metadata_by_id[card.card_id]
		var haystack: String = (card.display_name+" "+info.country_name+" "+info.country_code+" "+info.version_label).to_lower()
		if not needle.is_empty() and not haystack.contains(needle): continue
		if not role.is_empty() and card.primary_role != role: continue
		if not tier.is_empty() and card.tier() != tier: continue
		if not pool.is_empty() and info.career_pool != pool: continue
		result.append(card)
	result.sort_custom(func(a,b):
		if order == "rating" and a.rating() != b.rating(): return a.rating() > b.rating()
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	return result

func eligible(minimum: int, maximum: int, excluded_people: Array = []) -> Array[Resource]:
	return cards.filter(func(card): return card.rating() >= minimum and card.rating() <= maximum and card.person_id not in excluded_people)

static func portrait(card: Resource, info: Dictionary) -> Texture2D:
	if card == null or card.portrait_id.is_empty(): return null
	var path: String = info.get("target_asset_path","")
	if path != "res://assets/portraits/catalogue_200/"+card.portrait_id+".png": return null
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
