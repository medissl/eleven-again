extends RefCounted
## Revision-guarded session model. Disk/journal integration is a separate boundary.
const Campaign = preload("res://content/campaign.gd")
const Acquisition = preload("res://run/acquisition.gd")
const Lineup = preload("res://squad/lineup.gd")
const Card = preload("res://content/player_card.gd")
const Match = preload("res://match/match_sim.gd")
const Snapshot = preload("res://match/match_snapshot.gd")
const State = preload("res://run/run_state.gd")
const Records = preload("res://run/records.gd")
const PRINCIPLES := ["short_combinations","wide_service","counter_runners","first_pressure","set_piece_preparation","bench_impact"]
var content: RefCounted
var model: RefCounted
var _state: Dictionary = {}

func _init(library: RefCounted = null) -> void:
	content = library if library != null else Campaign.new()

func snapshot() -> Dictionary:
	var data := _state.duplicate(true)
	if model != null and data.get("step") == "match": data.match_snapshot = Snapshot.capture(model)
	return data

func revision() -> int:
	return _state.get("revision",0)

func restore(data: Variant) -> Dictionary:
	var error := State.error(data,content)
	if not error.is_empty(): return failure(error)
	_state = data.duplicate(true)
	model = Snapshot.restore(data.match_snapshot) if data.step == "match" else null
	return {"ok":true,"revision":revision()}

func start(origin: String, seed_value: int, run_id: String) -> Dictionary:
	if not _state.is_empty(): return failure("This controller already holds a run.")
	if not content.errors.is_empty() or not content.countries.has(origin) or run_id.is_empty(): return failure("Invalid origin or campaign content.")
	var plan: Resource = content.country_plan(origin)
	var data := {"schema":2,"content_version":Campaign.VERSION,"run_id":run_id,"seed":seed_value,"origin":origin,"revision":0,"wins":0,"defeats":0,"cash":int(content.rules.starting_cash),"earnings":0,"step":"opening_recruit","fixtures":content.itinerary(seed_value),"ledger":[],"plan":plan.to_data(),"released":[],"acquisitions":[],"principles":[],"offer":{},"market":{},"coaching":[],"queue":[],"current_attempt":{},"match_snapshot":{},"peak_xi":Records.capture(plan),"discipline":{},"abandoned_attempt":{}}
	for stream in ["offers","markets","attempts","coaching"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value ^ {"offers":11027,"markets":21027,"attempts":31027,"coaching":41027}[stream]
		data[stream+"_rng"] = str(rng.state)
	var error := enter_step(data,"opening_recruit")
	return failure(error) if not error.is_empty() else commit(data)

func excluded_people(data: Dictionary) -> Array:
	var people: Array = data.released.duplicate()
	for card in data.plan.cards: people.append(card.person_id)
	return people

func stream(data: Dictionary, name: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.state = int(data[name+"_rng"])
	return rng

func enter_step(data: Dictionary, next: String) -> String:
	data.step = next
	if next in ["opening_recruit","recruit","market"]:
		var market := next == "market"
		var rng := stream(data,"markets" if market else "offers")
		var bands: Array
		var market_id := 0
		if market:
			market_id = int(content.rules.stages[data.wins-1].market)
			bands = content.weights.market[str(market_id)]
		elif next == "opening_recruit": bands = [{"min":75,"max":79,"weight":100}]
		else: bands = content.weights.free[["grassroots","elite","world"][int((data.wins-1)/4.0)]]
		var offer: Dictionary = Acquisition.generate(content.recruits,bands,content.weights.market_slots if market else content.weights.free_slots,excluded_people(data),rng,2 if market else 0)
		if not offer.ok: return offer.error
		offer.erase("ok")
		offer.id = data.run_id+"/"+next+"/"+str(data.wins)
		if market:
			offer.number = market_id
			offer.purchased = []
			offer.open = true
			data.market = offer
		else: data.offer = offer
		data[("markets" if market else "offers")+"_rng"] = str(rng.state)
	elif next == "coaching":
		var rng := stream(data,"coaching")
		var available: Array = PRINCIPLES.filter(func(value): return value not in data.principles)
		data.coaching = []
		for index in 3: data.coaching.append(available.pop_at(rng.randi_range(0,available.size()-1)))
		data.coaching_rng = str(rng.state)
	return ""

func advance(data: Dictionary) -> String:
	return enter_step(data,data.queue.pop_front() if not data.queue.is_empty() else "prepare")

func guard(expected: int, steps: Array) -> String:
	if _state.is_empty() or expected != revision(): return "This action is stale. Use the current run state."
	if _state.step not in steps: return "This action is unavailable at the current step."
	return ""

func commit(data: Dictionary) -> Dictionary:
	var unavailable: Array = data.discipline.keys().filter(func(id): return data.discipline[id].get("ban",0) > 0)
	var record := Records.capture(Lineup.from_data(data.plan),unavailable)
	if not record.is_empty() and record.total > data.peak_xi.total: data.peak_xi = record
	data.revision = revision()+1
	_state = data
	return {"ok":true,"revision":revision()}

func failure(message: String) -> Dictionary:
	return {"ok":false,"error":message,"revision":revision()}

func abandon(expected: int) -> Dictionary:
	var error := guard(expected,["opening_recruit","prepare","match","result","recruit","market","coaching"])
	if not error.is_empty(): return failure(error)
	var data := _state.duplicate(true)
	if data.step == "match": data.abandoned_attempt = data.current_attempt.duplicate(true)
	data.step = "abandoned"
	data.queue.clear()
	data.match_snapshot = {}
	model = null
	return commit(data)

func commit_match(plan: Resource, expected: int) -> Dictionary:
	var error := guard(expected,["prepare"])
	if not error.is_empty(): return failure(error)
	if plan == null or not plan.errors().is_empty(): return failure("Choose a legal starting eleven.")
	var owned: Dictionary = {}
	for record in _state.plan.cards: owned[record.card_id] = record
	if plan.cards.size() != owned.size(): return failure("Preparation must use the owned squad.")
	for card in plan.cards:
		if not owned.has(card.card_id) or card.to_data() != owned[card.card_id]: return failure("Preparation changed an owned player definition.")
	var data := _state.duplicate(true)
	var rng := stream(data,"attempts")
	var attempt_seed := rng.randi_range(1,2147483646)
	data.attempts_rng = str(rng.state)
	data.plan = plan.to_data()
	data.current_attempt = {"id":data.run_id+"/attempt/"+str(data.ledger.size()+1),"seed":attempt_seed,"stage":data.wins+1,"fixture":data.fixtures[data.wins].duplicate(true)}
	if not data.market.is_empty(): data.market.open = false
	var away: Resource = content.opponent_plan(data.current_attempt.fixture.variant_id)
	model = Match.new(attempt_seed,Match.REGULATION_SECONDS,plan,away,true)
	data.match_snapshot = Snapshot.capture(model)
	data.step = "match"
	return commit(data)

func finish_match(expected: int) -> Dictionary:
	var error := guard(expected,["match"])
	if not error.is_empty(): return failure(error)
	if model == null or not model.finished or model.winner() < 0 or not model.knockout or model.match_seed != _state.current_attempt.seed: return failure("The committed match has not resolved a winner.")
	var data := _state.duplicate(true)
	var result: Dictionary = data.current_attempt.duplicate(true)
	result.report = model.snapshot_report()
	result.prize = 0
	data.queue = []
	if model.winner() == 0:
		data.wins += 1
		var stage: Dictionary = content.rules.stages[data.wins-1]
		result.prize = int(stage.win_prize)
		data.cash += result.prize
		data.earnings += result.prize
		if stage.recruit: data.queue.append("recruit")
		if stage.market != null: data.queue.append("market")
		if stage.coaching: data.queue.append("coaching")
	else: data.defeats += 1
	data.ledger.append(result)
	data.match_snapshot = {}
	data.step = "won" if data.wins == 12 else ("lost" if data.defeats == 3 else "result")
	if data.step in ["won","lost"]: data.queue.clear()
	model = null
	return commit(data)

func continue_result(expected: int) -> Dictionary:
	var error := guard(expected,["result"])
	if not error.is_empty(): return failure(error)
	var data := _state.duplicate(true)
	error = advance(data)
	return failure(error) if not error.is_empty() else commit(data)

func skip_recruit(expected: int) -> Dictionary:
	var error := guard(expected,["opening_recruit","recruit"])
	if not error.is_empty(): return failure(error)
	var data := _state.duplicate(true)
	data.offer = {}
	error = advance(data)
	return failure(error) if not error.is_empty() else commit(data)

func close_market(expected: int) -> Dictionary:
	var error := guard(expected,["market"])
	if not error.is_empty(): return failure(error)
	var data := _state.duplicate(true)
	error = advance(data)
	return failure(error) if not error.is_empty() else commit(data)

func reopen_market(expected: int) -> Dictionary:
	var error := guard(expected,["prepare"])
	if not error.is_empty(): return failure(error)
	if _state.market.is_empty() or not _state.market.open: return failure("This market has expired.")
	var data := _state.duplicate(true)
	data.step = "market"
	return commit(data)

func choose_principle(id: String, expected: int) -> Dictionary:
	var error := guard(expected,["coaching"])
	if not error.is_empty(): return failure(error)
	if id not in _state.coaching or id in _state.principles: return failure("Choose one of the available principles.")
	var data := _state.duplicate(true)
	data.principles.append(id)
	data.coaching = []
	error = advance(data)
	return failure(error) if not error.is_empty() else commit(data)

func acquire(card_id: String, outgoing_id: String, expected: int) -> Dictionary:
	var error := guard(expected,["opening_recruit","recruit","market"])
	if not error.is_empty(): return failure(error)
	var market: bool = _state.step == "market"
	var offer: Dictionary = _state.market if market else _state.offer
	if card_id not in offer.cards: return failure("This player is not in the fixed offer.")
	if market and (not offer.open or card_id in offer.purchased or offer.purchased.size() >= 2): return failure("This signing is unavailable or the two-purchase limit was reached.")
	var card: Resource = content.cards[card_id]
	if card.person_id in excluded_people(_state): return failure("This person is already owned or released.")
	var cost: int = content.price(card.rating()) if market else 0
	if cost < 0 or cost > _state.cash: return failure("Insufficient funds for this signing.")
	var plan: Resource = Lineup.from_data(_state.plan)
	var outgoing := -1
	for index in plan.cards.size():
		if plan.cards[index].card_id == outgoing_id: outgoing = index
	if plan.cards.size() == 18 and outgoing < 0: return failure("Choose an outgoing player before confirming.")
	if plan.cards.size() < 18 and not outgoing_id.is_empty(): return failure("A replacement is only required at squad capacity.")
	if outgoing >= 0 and "GK" in plan.cards[outgoing].natural_roles and "GK" not in card.natural_roles and plan.cards.filter(func(c): return "GK" in c.natural_roles).size() == 1: return failure("Keep a trained goalkeeper in the owned squad.")
	var data := _state.duplicate(true)
	if outgoing >= 0:
		data.released.append(plan.cards[outgoing].person_id)
		plan.cards[outgoing] = Card.from_data(card.to_data())
		plan.bench_order.erase(outgoing)
		for slot in plan.pinned_replacements:
			if plan.pinned_replacements[slot] == outgoing: plan.pinned_replacements[slot] = -1
	else: plan.cards.append(Card.from_data(card.to_data()))
	# If the starting keeper was replaced, assign an owned trained keeper first.
	if "GK" not in plan.cards[plan.starters[0]].natural_roles:
		for index in plan.cards.size():
			if "GK" not in plan.cards[index].natural_roles: continue
			var old_slot: int = plan.starters.find(index)
			if old_slot >= 0: plan.starters[old_slot] = plan.starters[0]
			plan.starters[0] = index
			break
	plan.refresh_bench_order()
	if not plan.errors().is_empty(): return failure("The resulting squad is invalid.")
	data.plan = plan.to_data()
	data.cash -= cost
	data.acquisitions.append({"id":data.run_id+"/acquisition/"+str(data.acquisitions.size()+1),"card_id":card_id,"person_id":card.person_id,"cost":cost,"outgoing_id":outgoing_id})
	if market: data.market.purchased.append(card_id)
	else:
		data.offer = {}
		error = advance(data)
		if not error.is_empty(): return failure(error)
	return commit(data)

func best_owned() -> Array:
	if _state.is_empty(): return []
	var owned: Array = _state.plan.cards.map(func(record): return content.cards[record.card_id])
	owned.sort_custom(func(a,b): return a.rating() > b.rating() if a.rating() != b.rating() else a.card_id < b.card_id)
	return owned.slice(0,2).map(func(card): return card.card_id)
