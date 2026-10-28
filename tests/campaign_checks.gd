extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Controller = preload("res://run/run_controller.gd")
const Lineup = preload("res://squad/lineup.gd")
const State = preload("res://run/run_state.gd")
var content: RefCounted

func _initialize() -> void:
	call_deferred("run")

func fixture(controller: RefCounted, home: int, away: int, penalties: bool = false) -> void:
	var plan: Resource = Lineup.from_data(controller.snapshot().plan)
	assert(controller.commit_match(plan,controller.revision()).ok)
	assert(not controller.finish_match(controller.revision()).ok,"Unfinished matches cannot grant results")
	# Authored result contracts. A separate test below runs the actual native football.
	controller.model.scores = [home,away]
	if penalties: controller.model.shootout = {"goals":[5,4],"attempts":[5,5]}
	controller.model.finish_match()
	var old_revision: int = controller.revision()
	assert(controller.finish_match(old_revision).ok)
	var result: Dictionary = controller.snapshot()
	assert(State.error(result,content).is_empty(),State.error(result,content))
	assert(not controller.finish_match(old_revision).ok and controller.snapshot() == result,"Repeated result cannot pay or advance twice")

func decisions(controller: RefCounted, counts: Dictionary, sign_free: bool = false) -> void:
	while controller.snapshot().step not in ["prepare","won","lost"]:
		var state: Dictionary = controller.snapshot()
		assert(State.error(state,content).is_empty(),State.error(state,content))
		match state.step:
			"result": assert(controller.continue_result(controller.revision()).ok)
			"opening_recruit", "recruit":
				counts.recruits += 1
				if sign_free:
					var outgoing: String = state.plan.cards.back().card_id if state.plan.cards.size() == 18 else ""
					assert(controller.acquire(state.offer.cards[0],outgoing,controller.revision()).ok)
				else: assert(controller.skip_recruit(controller.revision()).ok)
			"market":
				counts.markets += 1
				var stock: Dictionary = state.market.duplicate(true)
				assert(controller.close_market(controller.revision()).ok)
				assert(controller.reopen_market(controller.revision()).ok)
				assert(controller.snapshot().market == stock,"Leaving a market never refreshes stock")
				assert(controller.close_market(controller.revision()).ok)
			"coaching":
				counts.coaching += 1
				assert(state.coaching.size() == 3)
				for id in state.coaching: assert(id not in state.principles)
				assert(controller.choose_principle(state.coaching[0],controller.revision()).ok)
			_: assert(false,"Unexpected step: "+state.step)

func run() -> void:
	content = Campaign.new()
	assert(content.errors.is_empty())
	var campaign := Controller.new(content)
	assert(campaign.start("ENG",42,"contract-test").ok)
	assert(not campaign.start("BRA",42,"replacement").ok)
	var same := Controller.new(content)
	assert(same.start("ENG",42,"contract-test").ok and same.snapshot() == campaign.snapshot())
	var untouched: Dictionary = campaign.snapshot()
	assert(not campaign.acquire("unknown","",campaign.revision()).ok and campaign.snapshot() == untouched)
	assert(campaign.best_owned().size() == 2)
	var counts := {"recruits":0,"markets":0,"coaching":0}
	decisions(campaign,counts,true)
	var fixed: Array = campaign.snapshot().fixtures.duplicate(true)
	fixture(campaign,0,1)
	var state: Dictionary = campaign.snapshot()
	assert(state.defeats == 1 and state.wins == 0 and state.cash == 8000000 and state.queue.is_empty())
	var previous_seed: int = state.ledger[0].seed
	decisions(campaign,counts,true)
	for win_index in 12:
		fixture(campaign,0 if win_index == 3 else 2,0 if win_index == 3 else 1,win_index == 3)
		state = campaign.snapshot()
		assert(state.wins == win_index+1 and state.fixtures == fixed)
		if win_index == 0:
			assert(state.ledger[1].seed != previous_seed and state.ledger[0].fixture == state.ledger[1].fixture,"Loss retries the frozen opponent with a fresh committed seed")
		if win_index == 10: assert(state.cash == 82000000)
		decisions(campaign,counts,true)
	state = campaign.snapshot()
	assert(state.step == "won" and state.wins == 12 and state.defeats == 1 and state.ledger.size() == 13)
	assert(state.cash == 92000000 and state.earnings == 84000000)
	assert(counts == {"recruits":10,"markets":3,"coaching":2})
	assert(state.acquisitions.size() == 10 and state.plan.cards.size() == 18 and state.released.size() == 8)
	assert(not campaign.commit_match(Lineup.from_data(state.plan),campaign.revision()).ok)
	for entry in state.acquisitions: assert(not entry.person_id.begins_with("enemy_"))
	var failed := Controller.new(content)
	assert(failed.start("IDN",13,"three-losses").ok)
	decisions(failed,{"recruits":0,"markets":0,"coaching":0})
	for index in 3:
		fixture(failed,0,1)
		if index < 2: decisions(failed,{"recruits":0,"markets":0,"coaching":0})
	assert(failed.snapshot().step == "lost" and failed.snapshot().ledger.size() == 3 and failed.snapshot().cash == 8000000)
	market_checks()
	signing_failures()
	actual_match()
	print("CAMPAIGN: twelve wins, three defeats, ten recruits, three fixed markets, two choices, revisions, signing and native match boundary passed")
	quit()

func market_checks() -> void:
	var controller := Controller.new(content)
	assert(controller.start("FRA",70,"market-contract").ok)
	var counts := {"recruits":0,"markets":0,"coaching":0}
	decisions(controller,counts,true)
	for index in 3:
		fixture(controller,1,0)
		assert(controller.continue_result(controller.revision()).ok)
		var state: Dictionary = controller.snapshot()
		var outgoing: String = state.plan.cards.back().card_id if state.plan.cards.size() == 18 else ""
		assert(controller.acquire(state.offer.cards[0],outgoing,controller.revision()).ok)
	var state: Dictionary = controller.snapshot()
	assert(state.step == "market")
	var candidates: Array = state.market.cards.duplicate()
	candidates.sort_custom(func(a,b): return content.price(content.cards[a].rating()) < content.price(content.cards[b].rating()))
	for id in candidates.slice(0,2):
		state = controller.snapshot()
		var cost: int = content.price(content.cards[id].rating())
		assert(not controller.acquire(id,"",controller.revision()).ok,"Full squad requires explicit replacement")
		var old_revision: int = controller.revision()
		assert(controller.acquire(id,state.plan.cards.back().card_id,old_revision).ok)
		assert(controller.snapshot().cash == state.cash-cost)
		assert(not controller.acquire(id,state.plan.cards.back().card_id,old_revision).ok)
	state = controller.snapshot()
	assert(not controller.acquire(candidates[2],state.plan.cards.back().card_id,controller.revision()).ok)
	assert(controller.snapshot() == state,"Two-buy cap cannot mutate cash or roster")
	assert(controller.close_market(controller.revision()).ok)
	var plan: Resource = Lineup.from_data(controller.snapshot().plan)
	assert(controller.commit_match(plan,controller.revision()).ok)
	assert(not controller.reopen_market(controller.revision()).ok)
	plan.cards[0].keeper_attributes.REF = 1
	assert(controller.model.plans[0].cards[0].keeper_attributes.REF != 1,"Committed football owns its inputs")

func actual_match() -> void:
	var controller := Controller.new(content)
	assert(controller.start("JPN",6,"native-football").ok)
	assert(controller.skip_recruit(controller.revision()).ok)
	assert(controller.commit_match(Lineup.from_data(controller.snapshot().plan),controller.revision()).ok)
	var ticks := 0
	while not controller.model.finished and ticks < 60000:
		if controller.model.period == controller.model.Period.HALF_TIME: controller.model.acknowledge_halftime()
		controller.model.step()
		ticks += 1
	assert(controller.model.finished and controller.model.winner() >= 0)
	var report: Dictionary = controller.model.snapshot_report()
	assert(controller.finish_match(controller.revision()).ok)
	assert(controller.snapshot().ledger[0].report == report,"Run ledger consumes the real football outcome")

func signing_failures() -> void:
	var controller := Controller.new(content)
	assert(controller.start("ARG",91,"signing-contract").ok)
	var state: Dictionary = controller.snapshot()
	assert(controller.acquire(state.offer.cards[1],"",controller.revision()).ok)
	fixture(controller,1,0)
	var before: Dictionary = controller.snapshot()
	var pool: Array = content.recruits.duplicate()
	content.recruits.clear()
	assert(not controller.continue_result(controller.revision()).ok)
	assert(controller.snapshot() == before,"Content exhaustion retains the paid result and RNG without advancing")
	content.recruits.assign(pool)
	assert(controller.continue_result(controller.revision()).ok)
	state = controller.snapshot()
	assert(controller.acquire(state.offer.cards[1],"",controller.revision()).ok)
	fixture(controller,1,0)
	assert(controller.continue_result(controller.revision()).ok)
	state = controller.snapshot()
	var reserve_keeper: String = state.plan.cards[11].card_id
	assert(controller.acquire(state.offer.cards[1],reserve_keeper,controller.revision()).ok)
	fixture(controller,1,0)
	assert(controller.continue_result(controller.revision()).ok)
	state = controller.snapshot()
	assert(not controller.acquire(state.offer.cards[1],state.plan.cards[0].card_id,controller.revision()).ok)
	assert(controller.snapshot() == state,"Last trained keeper is protected atomically")
	assert(controller.skip_recruit(controller.revision()).ok)
	state = controller.snapshot()
	var stock: Array = state.market.cards.duplicate()
	stock.sort_custom(func(a,b): return content.price(content.cards[a].rating()) > content.price(content.cards[b].rating()))
	assert(controller.acquire(stock[0],state.plan.cards.back().card_id,controller.revision()).ok)
	# Authored zero-funds boundary, independent of the sampled stock's prices.
	controller._state.cash = 0
	state = controller.snapshot()
	var expensive: String = stock[1]
	assert(not controller.acquire(expensive,state.plan.cards.back().card_id,controller.revision()).ok)
	assert(controller.snapshot() == state,"Insufficient funds retains cash, stock and outgoing player")
	assert(controller.close_market(controller.revision()).ok)
	var bad_plan: Resource = Lineup.from_data(controller.snapshot().plan)
	bad_plan.cards[0].keeper_attributes.REF = 120
	state = controller.snapshot()
	assert(not controller.commit_match(bad_plan,controller.revision()).ok and controller.snapshot() == state,"Preparation cannot rewrite base attributes")
