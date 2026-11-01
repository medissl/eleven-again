extends RefCounted
## Frozen authored content. Opposition/starters never enter the acquisition pool.
const Card = preload("res://content/player_card.gd")
const Lineup = preload("res://squad/lineup.gd")
const Catalogue = preload("res://content/catalogue.gd")
const VERSION := "campaign_road_v2"
const LEGACY_VERSION := "campaign_v1"
const ROOT := "res://content/campaign/"
var errors: Array[String] = []
var cards: Dictionary = {}
var countries: Dictionary = {}
var clubs: Dictionary = {}
var variants: Dictionary = {}
var recruits: Array[Resource] = []
var metadata_by_id: Dictionary = {}
var rules: Dictionary = {}
var weights: Dictionary = {}
var road_aliases := {}

func _init() -> void:
	rules = read_data("run_rules")
	weights = read_data("acquisition_weights")
	var library := Catalogue.new()
	errors.append_array(library.errors)
	for card in library.cards:
		cards[card.card_id] = card
		recruits.append(card)
		metadata_by_id[card.card_id] = library.metadata(card.card_id)
	for file in ["country_starters","enemy_rosters","fictional_recruits"]:
		var data := read_data(file)
		for record in data.get("cards",[]):
			var card: Resource = Card.from_data(record) if record is Dictionary else null
			if card == null:
				errors.append("Invalid campaign card in "+file)
				continue
			if cards.has(card.card_id): errors.append("Duplicate card: "+card.card_id)
			if not card.trait_id.is_empty() and card.primary_role not in Card.Traits.catalogue[card.trait_id].positions: errors.append("Incompatible trait: "+card.card_id)
			cards[card.card_id] = card
			if file == "fictional_recruits":
				recruits.append(card)
				var info: Dictionary = data.get("metadata_by_card_id",{}).get(card.card_id,{})
				if info.get("ovr") != card.rating() or info.get("tier") != card.tier() or info.get("market_price") != price(card.rating()): errors.append("Stale recruit metadata: "+card.card_id)
				info = info.duplicate(true)
				info.version_label = info.get("edition","Run edition")
				info.country_name = country_name(info.get("country_code",""))
				info.target_asset_path = "res://assets/portraits/run_recruits/"+card.portrait_id+".png"
				metadata_by_id[card.card_id] = info
		for country in data.get("countries",[]):
			if countries.has(country.id): errors.append("Duplicate country")
			countries[country.id] = country
		for variant in data.get("variants",[]):
			if variants.has(variant.id): errors.append("Duplicate opponent variant")
			variants[variant.id] = variant
	for club in read_data("enemy_clubs").get("teams",[]):
		if clubs.has(club.id): errors.append("Duplicate club")
		clubs[club.id] = club
	validate()
	if errors.is_empty(): install_road_rivals()
	if not errors.is_empty():
		cards.clear()
		recruits.clear()
		countries.clear()
		clubs.clear()
		variants.clear()
		metadata_by_id.clear()

static func supports_version(value: Variant) -> bool:
	return value in [VERSION,LEGACY_VERSION]

func install_road_rivals() -> void:
	var records: Array = read_data("road_rivals").get("rivals",[])
	if records.size() != 16: errors.append("Incomplete road opposition"); return
	for record in records:
		if not clubs.has(record.source) or clubs.has(record.id) or road_aliases.has(record.source) or not str(record.id).is_valid_identifier():
			errors.append("Invalid road rival identity"); continue
		var club: Dictionary = clubs[record.source].duplicate(true)
		club.id = record.id
		club.name = record.name
		club.legacy_source = record.source
		club.opposition_kind = record.kind
		club.country_code = record.get("country","")
		club.home_kit = "#"+record.primary
		club.away_kit = "#"+record.accent
		clubs[club.id] = club
		road_aliases[record.source] = club.id
		if not ResourceLoader.exists(badge_path(club.id)): errors.append("Missing original road crest")
		for variant in variants.values():
			if variant.team_id != record.source: continue
			var copy: Dictionary = variant.duplicate(true)
			copy.id = str(variant.id).replace(record.source,club.id)
			copy.team_id = club.id
			variants[copy.id] = copy
			if opponent_plan(copy.id) == null: errors.append("Invalid road opponent plan")

func read_data(file: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(ROOT+file+".json"))
	if data is Dictionary and data.get("schema_version") == 1: return data
	errors.append("Unreadable campaign data: "+file)
	return {}

func validate() -> void:
	if rules.get("target_wins") != 12 or rules.get("defeat_limit") != 3 or rules.get("starting_cash") != 8000000 or rules.get("regulation_active_seconds") != 180 or rules.get("stages",[]).size() != 12: errors.append("Invalid run schedule")
	if countries.size() != 6 or clubs.size() != 24 or variants.size() != 60 or cards.size() != 1356 or recruits.size() != 300: errors.append("Incomplete campaign content")
	if not errors.is_empty(): return
	for country in countries.values():
		var plan := country_plan(country.id)
		if plan == null or country.starting_cash != rules.starting_cash: errors.append("Invalid country: "+country.id)
		elif not is_equal_approx(xi_rating(plan),country.xi_ovr): errors.append("Stale origin XI rating")
	for club in clubs.values():
		if int(club.chapter) not in [1,2,3] or not ResourceLoader.exists(badge_path(club.id)): errors.append("Invalid club/badge: "+club.id)
	for variant in variants.values():
		var plan := opponent_plan(variant.id)
		if plan == null:
			errors.append("Invalid opponent: "+variant.id)
			continue
		var stage: Dictionary = rules.stages[int(variant.stage)-1]
		var club: Dictionary = clubs[variant.team_id]
		var rating := xi_rating(plan)
		if rating < stage.enemy_xi_ovr_min or rating > stage.enemy_xi_ovr_max or not is_equal_approx(rating,variant.xi_ovr): errors.append("Opponent outside stage budget: "+variant.id)
		if club.chapter != stage.chapter or club.is_boss != stage.boss: errors.append("Opponent stage mismatch")
		var signatures := 0
		for slot in 11:
			var card: Resource = plan.cards[plan.starters[slot]]
			if Lineup.ROLES[plan.formation][slot] not in card.natural_roles: errors.append("Unnatural opponent role")
			if not card.trait_id.is_empty(): signatures += 1
		if signatures != (4 if club.is_boss else 2): errors.append("Opponent trait budget")
	for card in recruits:
		if Catalogue.portrait(card,metadata(card.card_id)) == null: errors.append("Missing recruit portrait: "+card.card_id)

func country_plan(id: String) -> Resource:
	return make_plan(countries[id],{}) if countries.has(id) else null

func opponent_plan(id: String) -> Resource:
	if not variants.has(id): return null
	var variant: Dictionary = variants[id]
	return make_plan(variant,clubs.get(variant.team_id,{}))

func make_plan(record: Dictionary, tactics: Dictionary) -> Resource:
	var plan := Lineup.new()
	for id in record.get("cards",[]):
		if not cards.has(id): return null
		# Plans get private definitions; preparation cannot edit the content library.
		plan.cards.append(Card.from_data(cards[id].to_data()))
	for key in ["formation","attack","defence","route","width","late_risk","substitution_plan"]:
		if tactics.has(key): plan.set(key,tactics[key])
		elif record.has(key): plan.set(key,record[key])
	for key in ["starters","bench_order","penalty_order"]:
		if record.has(key):
			plan.get(key).clear()
			for value in record[key]: plan.get(key).append(int(value))
	for key in ["captain","free_kick_taker","corner_taker","penalty_taker"]:
		if record.has(key): plan.set(key,int(record[key]))
	return plan if plan.errors().is_empty() else null

static func xi_rating(plan: Resource) -> float:
	var total := 0
	for slot in 11: total += plan.cards[plan.starters[slot]].rating(Lineup.ROLES[plan.formation][slot],true)
	return total/11.0

func itinerary(seed_value: int, version: String = VERSION) -> Array:
	if not errors.is_empty(): return []
	if not supports_version(version): return []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array = []
	for chapter in range(1,4):
		var ordinary: Array = clubs.values().filter(func(club): return not club.has("legacy_source") and club.chapter == chapter and not club.is_boss)
		var finals: Array = clubs.values().filter(func(club): return not club.has("legacy_source") and club.chapter == chapter and club.is_boss)
		for offset in 4:
			var pool: Array = finals if offset == 3 else ordinary
			var club: Dictionary = pool.pop_at(rng.randi_range(0,pool.size()-1))
			if version == VERSION and road_aliases.has(club.id): club = clubs[road_aliases[club.id]]
			var stage := (chapter-1)*4+offset+1
			result.append({"stage":stage,"club_id":club.id,"variant_id":"%s_stage_%02d" % [club.id,stage]})
	return result

func metadata(card_id: String) -> Dictionary:
	var info: Dictionary = metadata_by_id.get(card_id,{}).duplicate(true)
	if info.is_empty() and cards.has(card_id):
		info = {"version_label":"Run edition","country_name":"Fictional player","career_pool":"Campaign","target_asset_path":"res://assets/portraits/run_recruits/"+cards[card_id].portrait_id+".png"}
		for country in countries.values():
			if card_id in country.cards:
				info.country_code = country.id
				info.country_name = country.name
				break
	return info

func badge_path(club_id: String) -> String:
	var pixel := "res://assets/ui/arcade/badges/"+club_id+".png"
	if club_id.is_valid_identifier() and ResourceLoader.exists(pixel): return pixel
	if clubs.has(club_id) and clubs[club_id].has("legacy_source"): return "res://assets/badges/road/"+club_id+".svg"
	return "res://assets/badges/campaign/"+club_id+".svg" if clubs.has(club_id) and club_id.is_valid_identifier() else ""

func price(ovr: int) -> int:
	var anchors: Array = rules.get("price_anchors_millions",[])
	for index in range(0,anchors.size(),2):
		var low: Array = anchors[index]
		var high: Array = anchors[index+1]
		if ovr >= low[0] and ovr <= high[0]:
			return floori(low[1]+float(ovr-low[0])*(high[1]-low[1])/(high[0]-low[0])+0.5)*1000000
	return -1

static func country_name(code: String) -> String:
	return {"ENG":"England","BRA":"Brazil","FRA":"France","JPN":"Japan","IDN":"Indonesia","ARG":"Argentina"}.get(code,code)
