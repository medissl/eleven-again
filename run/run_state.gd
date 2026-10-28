extends RefCounted
## Validate the persisted session boundary before constructing a match or showing Continue.
const Campaign = preload("res://content/campaign.gd")
const Lineup = preload("res://squad/lineup.gd")
const Snapshot = preload("res://match/match_snapshot.gd")
const STEPS := ["opening_recruit","prepare","match","result","recruit","market","coaching","won","lost"]

static func error(data: Variant, content: RefCounted) -> String:
	if data is not Dictionary: return "Run is not a dictionary."
	if not plain_finite(data): return "Run contains unsupported or non-finite values."
	for key in ["schema","revision","seed","wins","defeats","cash","earnings"]:
		if data.get(key) is not int: return "Invalid run integer: "+key
	for key in ["content_version","run_id","origin","step","offers_rng","markets_rng","attempts_rng","coaching_rng"]:
		if data.get(key) is not String: return "Invalid run text: "+key
	for key in ["fixtures","ledger","released","acquisitions","principles","coaching","queue"]:
		if data.get(key) is not Array: return "Invalid run list: "+key
	for key in ["plan","offer","market","current_attempt","match_snapshot"]:
		if data.get(key) is not Dictionary: return "Invalid run state: "+key
	if data.schema != 1 or data.content_version != Campaign.VERSION: return "Unsupported campaign version."
	if not content.errors.is_empty() or not content.countries.has(data.origin) or data.run_id.is_empty(): return "Missing origin/content."
	if data.step not in STEPS or data.revision < 1 or data.wins < 0 or data.wins > 12 or data.defeats < 0 or data.defeats > 3 or data.cash < 0: return "Invalid progress."
	if (data.step == "won") != (data.wins == 12) or (data.step == "lost") != (data.defeats == 3): return "Invalid terminal state."
	if data.wins == 12 and data.defeats == 3: return "Conflicting terminal state."
	if data.fixtures != content.itinerary(data.seed): return "Frozen fixtures changed."
	for name in ["offers","markets","attempts","coaching"]:
		if not data[name+"_rng"].is_valid_int(): return "Invalid RNG state."
	var plan: Resource = Lineup.from_data(data.plan)
	if plan == null: return "Invalid owned squad/plan."
	if plan.route not in ["mixed","combinations","wide"] or plan.late_risk not in ["none","trailing_attack","leading_caution"] or plan.width < 0.5 or plan.width > 1.5: return "Invalid tactical settings."
	var owned := {}
	for card in plan.cards:
		if not content.cards.has(card.card_id) or content.cards[card.card_id].to_data() != card.to_data() or card.person_id in data.released: return "Unknown, changed or released owned card."
		owned[card.card_id] = true
	var available: Array = content.countries[data.origin].cards.duplicate()
	var released := []
	var spent := 0
	var acquired_people := []
	for index in data.acquisitions.size():
		var acquisition = data.acquisitions[index]
		if acquisition is not Dictionary or acquisition.get("card_id") is not String or acquisition.get("outgoing_id") is not String or acquisition.get("cost") is not int: return "Invalid acquisition."
		var card: Resource = content.cards.get(acquisition.card_id)
		if card == null or card not in content.recruits or acquisition.get("person_id") != card.person_id or card.person_id in acquired_people or card.person_id in released: return "Invalid acquired person."
		if acquisition.get("id") != data.run_id+"/acquisition/"+str(index+1) or acquisition.cost not in [0,content.price(card.rating())]: return "Invalid acquisition cost/identity."
		if available.size() == 18:
			if acquisition.outgoing_id not in available: return "Missing outgoing player."
			available.erase(acquisition.outgoing_id)
			released.append(content.cards[acquisition.outgoing_id].person_id)
		elif not acquisition.outgoing_id.is_empty(): return "Unexpected outgoing player."
		available.append(card.card_id)
		acquired_people.append(card.person_id)
		spent += acquisition.cost
	if owned.size() != available.size(): return "Ownership ledger mismatch."
	for id in available:
		if not owned.has(id): return "Ownership ledger mismatch."
	if data.released != released: return "Release ledger mismatch."
	var wins := 0
	var defeats := 0
	var earnings := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed ^ 31027
	for index in data.ledger.size():
		var result = data.ledger[index]
		if result is not Dictionary or result.get("report") is not Dictionary or result.report.get("winner") not in [0,1]: return "Invalid result."
		if result.get("id") != data.run_id+"/attempt/"+str(index+1) or result.get("stage") != wins+1 or result.get("fixture") != data.fixtures[wins] or result.get("seed") != rng.randi_range(1,2147483646): return "Invalid attempt ledger."
		var prize := 0
		if result.report.winner == 0:
			prize = int(content.rules.stages[wins].win_prize)
			wins += 1
		else: defeats += 1
		if result.get("prize") != prize: return "Invalid prize."
		earnings += prize
		if (wins == 12 or defeats == 3) and index != data.ledger.size()-1: return "Result after run end."
	if wins != data.wins or defeats != data.defeats or earnings != data.earnings or data.cash != 8000000+earnings-spent: return "Progress/cash ledger mismatch."
	if data.principles.size() > 2 or data.coaching.size() not in [0,3]: return "Invalid coaching state."
	var seen := []
	for id in data.principles+data.coaching:
		if id not in ["short_combinations","wide_service","counter_runners","first_pressure","set_piece_preparation","bench_impact"] or id in seen: return "Duplicate/unknown principle."
		seen.append(id)
	if data.step == "coaching" and data.coaching.size() != 3: return "Missing coaching offer."
	for step in data.queue:
		if step not in ["recruit","market","coaching"]: return "Invalid queued step."
	if data.step in ["opening_recruit","recruit"]:
		if not valid_offer(data.offer,5,content): return "Invalid recruit offer."
	if not data.market.is_empty():
		if not valid_offer(data.market,8,content) or data.market.get("purchased") is not Array or data.market.purchased.size() > 2 or data.market.get("open") is not bool or data.market.get("number") not in [1,2,3]: return "Invalid market."
		var purchased := []
		for id in data.market.purchased:
			if id not in data.market.cards or id in purchased: return "Invalid purchase."
			purchased.append(id)
	if data.step == "market" and (data.market.is_empty() or not data.market.open): return "Missing/closed market."
	if data.step == "match":
		var attempt: Dictionary = data.current_attempt
		if attempt.get("id") != data.run_id+"/attempt/"+str(data.ledger.size()+1) or attempt.get("fixture") != data.fixtures[wins] or attempt.get("stage") != wins+1 or attempt.get("seed") != rng.randi_range(1,2147483646): return "Invalid committed attempt."
		var model: RefCounted = Snapshot.restore(data.match_snapshot)
		if model == null or model.match_seed != attempt.seed or not model.knockout or model.regulation_ticks != model.REGULATION_SECONDS*60 or model.plans[0].to_data() != data.plan or model.plans[1].to_data() != content.opponent_plan(attempt.fixture.variant_id).to_data(): return "Invalid match snapshot."
		if model.period not in model.Period.values() or model.ball_state not in model.BallState.values() or model.ticks < 0 or model.active_ticks < 0: return "Invalid football state."
		for player in model.players:
			if not content.cards.has(player.card.card_id) or content.cards[player.card.card_id].to_data() != player.card.to_data(): return "Changed match player definition."
			for key in model.ATTRIBUTE_FIELDS:
				var base = player.card.attributes.get(key,player.card.keeper_attributes.get(key))
				if player.get(model.ATTRIBUTE_FIELDS[key]) != base: return "Changed base match attribute."
	elif not data.match_snapshot.is_empty(): return "Unexpected match snapshot."
	if str(rng.state) != data.attempts_rng: return "Attempt RNG mismatch."
	return ""

static func plain_finite(value: Variant, depth: int = 0) -> bool:
	if depth > 64: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME: return true
		TYPE_FLOAT: return is_finite(value)
		TYPE_VECTOR2: return value.is_finite()
		TYPE_ARRAY:
			for item in value:
				if not plain_finite(item,depth+1): return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) not in [TYPE_INT,TYPE_STRING,TYPE_STRING_NAME]: return false
				if not plain_finite(value[key],depth+1): return false
			return true
	return false

static func valid_offer(offer: Dictionary, size_required: int, content: RefCounted) -> bool:
	if offer.get("cards") is not Array or offer.cards.size() != size_required or offer.get("id") is not String or offer.get("exceptions") is not Array: return false
	var people := []
	for id in offer.cards:
		var card: Resource = content.cards.get(id)
		if card == null or card not in content.recruits or card.person_id in people: return false
		people.append(card.person_id)
	return true
