extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Controller = preload("res://run/run_controller.gd")
const Availability = preload("res://run/availability.gd")
const State = preload("res://run/run_state.gd")
const Session = preload("res://persistence/campaign_session.gd")
const Records = preload("res://run/records.gd")
const Match = preload("res://match/match_sim.gd")
var content: RefCounted

func _initialize() -> void: call_deferred("run")

func ready_next(controller: RefCounted) -> void:
	while controller.snapshot().step != "prepare":
		var state: Dictionary = controller.snapshot()
		match state.step:
			"opening_recruit", "recruit": assert(controller.skip_recruit(controller.revision()).ok)
			"result": assert(controller.continue_result(controller.revision()).ok)
			"market": assert(controller.close_market(controller.revision()).ok)
			"coaching": assert(controller.choose_principle(state.coaching[0],controller.revision()).ok)
			_: assert(false,"Unexpected step")

func card_fixture(controller: RefCounted, actor: int, yellows: int, win: bool) -> void:
	assert(controller.commit_match(controller.preparation_plan(),controller.revision()).ok)
	for incident in yellows:
		controller.model.ball_state = Match.BallState.CONTROLLED
		controller.model.owner = 20
		controller.model.Discipline.foul(controller.model,actor,20,1)
	controller.model.scores = [1,0] if win else [0,1]
	controller.model.finish_match()
	assert(controller.finish_match(controller.revision()).ok)
	assert(State.error(controller.snapshot(),content).is_empty(),State.error(controller.snapshot(),content))

func run() -> void:
	content = Campaign.new()
	var controller := Controller.new(content)
	assert(controller.start("ENG",40,"disciplinary-contract").ok)
	ready_next(controller)
	var person: String = controller.snapshot().plan.cards[1].person_id
	for fixture in 3:
		card_fixture(controller,1,1,true)
		var entry: Dictionary = controller.snapshot().discipline[person]
		assert(entry == ({"yellow":fixture+1,"ban":0} if fixture < 2 else {"yellow":0,"ban":1}))
		ready_next(controller)
	var before: Dictionary = controller.snapshot()
	for visit in 3:
		var prepared: Resource = controller.preparation_plan()
		assert(prepared.errors().is_empty() and prepared.cards.size() == 15)
		assert(prepared.cards.filter(func(card): return card.person_id == person).is_empty())
	assert(controller.snapshot() == before,"Opening preparation cannot serve a ban")
	assert(not controller.commit_match(content.country_plan("ENG"),controller.revision()).ok)
	card_fixture(controller,2,0,true)
	assert(not controller.snapshot().discipline.has(person),"A completed win serves one ban and clears yellows")
	ready_next(controller)
	assert(controller.preparation_plan().cards.size() == 16)
	var next_person: String = controller.preparation_plan().cards[controller.preparation_plan().starters[2]].person_id
	card_fixture(controller,2,2,false)
	assert(controller.snapshot().discipline[next_person] == {"yellow":0,"ban":1},"Second-yellow red creates one ban")
	ready_next(controller)
	card_fixture(controller,2,0,false)
	assert(not controller.snapshot().discipline.has(next_person),"A completed loss also serves the ban")
	extreme_cover()
	disk_service()
	academy_disk()
	substitute_identity()
	print("AVAILABILITY: accumulated yellows/red, win/loss service, prep invariance, academy/GK cover, disk resume and substitute identity passed")
	quit()

func extreme_cover() -> void:
	var controller := Controller.new(content)
	assert(controller.start("BRA",2,"academy-contract").ok)
	var state: Dictionary = controller.snapshot()
	for record in state.plan.cards: state.discipline[record.person_id] = {"yellow":0,"ban":1}
	var prepared: Resource = Availability.plan(state)
	assert(prepared != null and prepared.errors().is_empty() and prepared.cards.size() == 11)
	assert(Records.capture(prepared).is_empty())
	for card in prepared.cards:
		assert(card.rating() == 48 and Availability.is_academy(card.to_data(),state.run_id))
		assert(not content.cards.has(card.card_id) and card not in content.recruits)
	assert("GK" in prepared.cards[prepared.starters[0]].natural_roles)
	var original_owned: int = state.plan.cards.size()
	var remembered: Resource = Availability.remember(content.country_plan("BRA"),prepared)
	assert(remembered.cards.size() == original_owned and remembered.errors().is_empty())
	for card in remembered.cards: assert(not card.card_id.begins_with("academy_"))
	var forged: Dictionary = prepared.cards[0].to_data()
	forged.attributes.PAC = 120
	assert(not Availability.is_academy(forged,state.run_id))
	# All ordinary players available except both keepers: anonymous keeper only.
	state.discipline = {}
	for card in state.plan.cards:
		if "GK" in card.natural_roles: state.discipline[card.person_id] = {"yellow":0,"ban":1}
	prepared = Availability.plan(state)
	assert(prepared.errors().is_empty() and prepared.cards.size() == 15)
	assert(prepared.cards.filter(func(card): return card.card_id.begins_with("academy_")).size() == 1)
	assert(prepared.cards[prepared.starters[0]].rating("GK") == 48)

func disk_service() -> void:
	var location := "user://campaign_availability_test_"+str(Time.get_ticks_usec())
	var session := Session.new(location,content)
	assert(session.new_run("FRA",7,"disk-discipline").ok)
	assert(session.act("skip_recruit",[],session.controller.revision()).ok)
	assert(session.act("commit_match",[session.controller.preparation_plan()],session.controller.revision()).ok)
	var person: String = session.controller.model.players[1].card.person_id
	session.controller.model.ball_state = Match.BallState.CONTROLLED
	session.controller.model.Discipline.foul(session.controller.model,1,20,2)
	session.controller.model.scores = [1,0]
	session.controller.model.finish_match()
	assert(session.act("finish_match",[],session.controller.revision()).ok)
	assert(session.act("continue_result",[],session.controller.revision()).ok)
	assert(session.act("skip_recruit",[],session.controller.revision()).ok)
	assert(session.act("commit_match",[session.controller.preparation_plan()],session.controller.revision()).ok)
	for tick in 80: session.controller.model.step()
	assert(session.checkpoint().ok)
	var before: Array = session.controller.model.signature()
	assert(session.reload().ok and session.controller.model.signature() == before)
	assert(session.controller.snapshot().discipline[person].ban == 1,"A partial saved match has not served the ban")
	session.controller.model.scores = [0,1]
	session.controller.model.finish_match()
	assert(session.act("finish_match",[],session.controller.revision()).ok)
	assert(not session.controller.snapshot().discipline.has(person))
	assert(session.reload().ok and not session.controller.snapshot().discipline.has(person))
	for file in DirAccess.get_files_at(session.store.directory): assert(DirAccess.remove_absolute(session.store.directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(session.store.directory) == OK)

func substitute_identity() -> void:
	var model := Match.new(42)
	model.players[6].yellows = 1
	var leaving_id: String = model.players[6].card.card_id
	var leaving_person: String = model.players[6].card.person_id
	model.emit_event("yellow_card",6)
	model.load_card(model.players[6],model.plans[0].cards[12])
	assert(model.players[6].yellows == 0,"An incoming player cannot inherit the outgoing player's yellow")
	model.emit_event("yellow_card",6)
	var book := Availability.advance({},model.events,[],model.plans[0].to_data().cards)
	assert(book[leaving_person].yellow == 1)
	assert(book[model.players[6].card.person_id].yellow == 1 and model.events[-2].actor_card == leaving_id)

func academy_disk() -> void:
	var location := "user://campaign_availability_test_"+str(Time.get_ticks_usec())
	var session := Session.new(location,content)
	assert(session.new_run("IDN",8,"academy-disk").ok)
	assert(session.act("skip_recruit",[],session.controller.revision()).ok)
	for fixture in 3:
		assert(session.act("commit_match",[session.controller.preparation_plan()],session.controller.revision()).ok)
		for actor in 11:
			session.controller.model.ball_state = Match.BallState.CONTROLLED
			session.controller.model.owner = 20
			session.controller.model.Discipline.foul(session.controller.model,actor,20,1)
		session.controller.model.scores = [1,0]
		session.controller.model.finish_match()
		assert(session.act("finish_match",[],session.controller.revision()).ok)
		assert(session.act("continue_result",[],session.controller.revision()).ok)
		assert(session.act("skip_recruit",[],session.controller.revision()).ok)
		if fixture == 2: assert(session.act("close_market",[],session.controller.revision()).ok)
	var original_peak: Dictionary = session.controller.snapshot().peak_xi.duplicate(true)
	var prepared: Resource = session.controller.preparation_plan()
	assert(prepared.cards.size() == 11 and prepared.cards.filter(func(card): return card.card_id.begins_with("academy_")).size() == 6)
	assert(session.act("commit_match",[prepared],session.controller.revision()).ok)
	for tick in 80: session.controller.model.step()
	assert(session.checkpoint().ok,session.last_error)
	var signature: Array = session.controller.model.signature()
	assert(session.reload().ok and session.controller.model.signature() == signature,session.last_error)
	session.controller.model.scores = [1,0]
	session.controller.model.finish_match()
	assert(session.act("finish_match",[],session.controller.revision()).ok)
	assert(session.controller.snapshot().discipline.is_empty())
	assert(session.controller.snapshot().plan.cards.size() == 16)
	assert(session.controller.snapshot().peak_xi == original_peak and session.profile.discoveries.is_empty(),"Academy cover cannot persist, discover or set a record")
	for file in DirAccess.get_files_at(session.store.directory): assert(DirAccess.remove_absolute(session.store.directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(session.store.directory) == OK)
