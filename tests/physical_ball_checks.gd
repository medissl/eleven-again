extends RefCounted
const Match = preload("res://match/match_sim.gd")

static func fixture(seed_value: int = 42) -> RefCounted:
	var m := Match.new(seed_value)
	for p in m.players:
		p.position = Vector2(20+p.id*2,15)
		p.previous = p.position
		p.target = p.position
		p.card.trait_id = ""
		p.run_ready_tick = 999999
	m.take_control(9)
	return m

static func advance(m, count: int = 1) -> void:
	for tick in count:
		if m.ball_state == Match.BallState.FLIGHT: m.advance_flight()
		elif m.ball_state == Match.BallState.LOOSE: m.advance_loose()
		else: break

static func saved_shot(wide: bool, team: int = 0) -> RefCounted:
	for seed_value in 128:
		var m := fixture(seed_value)
		var keeper: int = m.keeper_id(1-team)
		m.take_control(9 if team == 0 else 20)
		m.players[m.owner].position = m.oriented(Vector2(88.3,37 if wide else 34),team)
		m.ball = m.oriented(Vector2(90,37 if wide else 34),team)
		m.players[10 if team == 0 else 21].position = m.oriented(Vector2(104.5,50),team)
		m.players[keeper].position = m.oriented(Vector2(104,34),team)
		m.players[keeper].handling = 40
		m.launch_ball(m.oriented(Vector2(105,37 if wide else 34),team),32,"shot")
		m.shot_quality = 0.2
		while m.ball_state == Match.BallState.FLIGHT: advance(m)
		if m.events.any(func(e): return e.kind == "parry"): return m
	assert(false,"Seeded reachable shots must exercise actual parries")
	return null

func run(check: Callable) -> void:
	for team in 2:
		var overhit := fixture()
		overhit.take_control(9 if team == 0 else 20)
		overhit.ball = Vector2(50,64 if team == 0 else 4)
		overhit.launch_ball(Vector2(50,66 if team == 0 else 2),24,"pass")
		advance(overhit,8)
		check.call(overhit.ball_state == Match.BallState.LOOSE and overhit.ball_velocity.length() > 20,"missed receiver leaves a moving ball on either touchline")
		advance(overhit,60)
		check.call(overhit.restart_kind == "throw_in" and overhit.restart_team == 1-team,"overhit pass physically exits and preserves last touch")
	var order := fixture()
	order.ball = Vector2(104.8,64)
	order.launch_ball(Vector2(108,80),122.4,"pass")
	order.ball_velocity = Vector2(24,120)
	order.players[12].position = Vector2(104,66.3)
	advance(order)
	check.call(order.restart_kind == "goal_kick" and order.last_touch == 9,"flight exit precedes a later reachable defensive contact")
	var loose := fixture()
	loose.ball_state = Match.BallState.LOOSE
	loose.owner = -1
	loose.ball = Vector2(104.8,64)
	loose.ball_velocity = Vector2(24,120)
	loose.players[12].position = Vector2(104,66.4)
	advance(loose)
	check.call(loose.restart_kind == "goal_kick" and loose.last_touch == 9,"loose-ball exit cannot be rescued after crossing")
	var swept := fixture()
	swept.ball_state = Match.BallState.LOOSE
	swept.owner = -1
	swept.ball = Vector2(50,34)
	swept.ball_velocity = Vector2(180,0)
	swept.players[12].position = Vector2(53,34)
	swept.players[13].position = Vector2(51.5,34)
	advance(swept)
	check.call(swept.owner == 13,"earliest swept loose contact wins regardless of roster iteration order")
	var curve := fixture()
	curve.ball = Vector2(80,50)
	curve.flight_curve = 3
	curve.flight_peak = 3
	curve.launch_ball(Vector2(85,62),26,"pass")
	while curve.ball_state == Match.BallState.FLIGHT: advance(curve)
	check.call(curve.ball_velocity.length() > 15 and curve.ball_velocity.y > 0,"missed curved delivery keeps its arriving tangent")
	advance(curve,120)
	check.call(curve.restart_kind == "throw_in","curved delivery can roll beyond its intended receiver")
	for team in 2:
		var corner := saved_shot(true,team)
		check.call((10 if team == 0 else 21) in corner.offside_context.candidates,"deliberate save preserves pass-time offside eligibility")
		check.call(corner.saves[1-team] == 1 and corner.restart_kind == "kickoff" and corner.ball_state == Match.BallState.LOOSE,"reachable save first creates a live rebound without awarding a corner")
		var contact: Vector2 = corner.ball
		advance(corner,90)
		check.call(corner.restart_kind == "corner" and corner.restart_team == team and corner.scores == [0,0],"glancing parry earns a corner only after crossing the goal line")
		check.call(corner.events.filter(func(e): return e.kind == "corner_awarded").size() == 1 and corner.last_touch == corner.keeper_id(1-team),"one corner preserves the keeper's real last touch")
		print("PHYSICAL PARRY CORNER team=",team," seed=",corner.match_seed," contact=",contact)
		var live := saved_shot(false,team)
		advance(live,90)
		check.call(live.ball_state in [Match.BallState.LOOSE,Match.BallState.CONTROLLED] and live.saves[1-team] == 1 and not live.events.any(func(e): return e.kind == "corner_awarded"),"central save stays playable infield without a corner, including a real recovery")
		var block := fixture()
		block.take_control(9 if team == 0 else 20)
		block.ball = block.oriented(Vector2(94,60),team)
		block.launch_ball(block.oriented(Vector2(105,60),team),30,"shot")
		block.players[block.keeper_id(1-team)].position = block.oriented(Vector2(103,34),team)
		block.players[12 if team == 0 else 1].position = block.oriented(Vector2(98,60.9),team)
		while block.ball_state == Match.BallState.FLIGHT: advance(block)
		check.call(block.events.back().kind == "block" and block.ball_velocity.y*block.direction(team) < 0,"off-centre block changes real momentum along its contact normal")
	var unreachable := fixture()
	unreachable.players[11].position = Vector2(99,34)
	unreachable.ball = Vector2(99,34)
	unreachable.flight_source = 9
	unreachable.flight_ticks = 60
	unreachable.ball_height = 4
	check.call(not unreachable.keeper_save(11),"keeper cannot save above actual vertical reach")
	unreachable.ball_height = 0
	unreachable.ball.x = 87
	check.call(not unreachable.keeper_save(11),"a keeper inside the box cannot handle a contact outside it")
	var low := [0,0]
	var high := [0,0]
	for seed_value in 64:
		for band in 2:
			var claim := fixture(seed_value)
			claim.ball = Vector2(99,34)
			claim.players[11].position = Vector2(99,34)
			claim.players[11].handling = 40 if band == 0 else 110
			claim.ball_velocity = Vector2(30,0)
			claim.flight_source = 9
			claim.owner = -1
			claim.ball_state = Match.BallState.FLIGHT
			claim.keeper_delivery_contact(11)
			if claim.owner == 11: high[band] += 1
			else:
				low[band] += 1
				check.call(claim.ball_state == Match.BallState.LOOSE and claim.last_touch == 11 and claim.ball_velocity.length() > 0,"failed delivery catch is a real live parry")
	check.call(high[1] > high[0] and low[0] > 0,"HAN changes non-shot handling without automatic holds")
	for kind in ["flight","rebound"]:
		var original := fixture(7)
		original.ball = Vector2(75,48)
		original.launch_ball(Vector2(84,61),28,"pass")
		if kind == "rebound":
			original = saved_shot(true)
		advance(original,7)
		var restored: RefCounted = load("res://match/match_snapshot.gd").restore(bytes_to_var(var_to_bytes(original.snapshot())))
		check.call(restored != null and restored.snapshot() == original.snapshot(),kind+" snapshot restores exactly")
		advance(original,120)
		advance(restored,120)
		check.call(original.snapshot() == restored.snapshot(),kind+" snapshot preserves the exact future including restarts/RNG")
