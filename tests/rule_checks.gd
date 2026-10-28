extends RefCounted
const Match = preload("res://match/match_sim.gd")

func run(check: Callable) -> void:
	var m := Match.new(42)
	for p in m.players: p.position = Vector2(30 if p.team == 0 else 90,5+p.id*2)
	m.players[11].position = Vector2(101,34)
	m.players[6].position = Vector2(60,34)
	m.players[9].position = Vector2(95,34)
	m.take_control(6)
	m.launch_ball(Vector2(95,34),25,"pass")
	check.call(9 in m.offside_context.candidates and m.ball_state == Match.BallState.FLIGHT, "offside position is captured at the pass without stopping passive play")
	var flagged_snapshot: Dictionary = m.snapshot()
	m.players[9].position.x = 85
	m.take_control(9)
	check.call(m.restart_kind == "indirect_free_kick" and m.owner == -1 and m.restart_team == 1, "actual involvement uses pass-time position even after the runner returns")
	m.current_restart = "throw_in"
	check.call(m.Offside.capture(m,6).is_empty(), "direct throw-in receipt is exempt")
	m.current_restart = ""
	m.players[9].position.x = 90
	m.ball = Vector2(62,34)
	check.call(not m.Offside.positioned(m,9,0), "level with second-last defender is legal")
	m.players[9].position.x = 50
	check.call(not m.Offside.positioned(m,9,0), "own-half receiver is legal")
	var cards := Match.new(42)
	cards.take_control(9)
	cards.Discipline.foul(cards,12,9,1)
	check.call(cards.players[12].yellows == 1 and cards.players[12].active, "first yellow leaves the player active")
	cards.take_control(9)
	cards.Discipline.foul(cards,12,9,1)
	check.call(cards.players[12].yellows == 2 and not cards.players[12].active, "second yellow dismisses exactly that player")
	check.call(cards.players.any(func(p): return p.active and p.team == 1 and p.anchor_override.x >= 0 and p.role == "LB"), "reduced team assigns real defensive cover rather than replacing the red-carded player")
	var keeper := Match.new(42)
	keeper.players[9].position = Vector2(96,34)
	keeper.take_control(9)
	keeper.Discipline.foul(keeper,11,9,2)
	check.call(keeper.restart_kind == "penalty" and keeper.restart_team == 0, "defensive penalty-area foul awards a genuine penalty")
	check.call(keeper.players.filter(func(p): return p.active and p.team == 1).size() == 10 and keeper.substitution_counts[1] == 1, "keeper replacement sacrifices an outfielder and keeps the team reduced")
	check.call(keeper.players[keeper.keeper_id(1)].card.card_id != keeper.plans[1].cards[0].card_id, "reserve keeper actually enters")
	var emergency := Match.new(42)
	emergency.substitution_counts[1] = 5
	emergency.take_control(9)
	emergency.Discipline.foul(emergency,11,9,2)
	check.call(emergency.keeper_id(1) != 11 and emergency.attribute(emergency.keeper_id(1),"REF") == 35, "no-substitute keeper dismissal uses emergency outfield keeping")
	var forfeited := Match.new(42)
	for index in range(12,16): forfeited.players[index].active = false
	forfeited.take_control(9)
	forfeited.Discipline.foul(forfeited,16,9,2)
	check.call(forfeited.finished and forfeited.forfeit_team == 1, "fewer than seven finishes through one forfeit")
	var finished: Array = forfeited.signature()
	forfeited.step()
	check.call(forfeited.signature() == finished, "forfeit cannot apply twice")
	var indirect := Match.new(42)
	indirect.last_touch = 9
	indirect.restart_untouched = true
	indirect.restart_kick_team = 0
	indirect.restart_delivery = "indirect_free_kick"
	indirect.BallRules.resolve(indirect,Vector2(104,34),Vector2(106,34))
	check.call(indirect.scores == [0,0] and indirect.restart_kind == "goal_kick", "untouched indirect delivery cannot score directly")
	var knockout := Match.new(42,180,null,null,true)
	knockout.period = Match.Period.SECOND_HALF
	knockout.active_ticks = knockout.regulation_ticks-1
	knockout.take_control(9)
	knockout.players[1].trait_uses = 2
	knockout.step()
	check.call(knockout.period == Match.Period.EXTRA_FIRST and not knockout.finished and knockout.trait_allowance == 4, "regulation tie starts shared-duration extra time and grants one extra trait use")
	check.call(knockout.players[1].trait_uses >= 2 and knockout.display_minute() == 90, "extra time carries existing uses and the football clock")
	knockout.active_ticks = roundi(knockout.regulation_ticks*7.0/6)-1
	knockout.take_control(9)
	knockout.step()
	check.call(knockout.period == Match.Period.EXTRA_SECOND and knockout.direction(0) == -1 and knockout.display_minute() == 105, "extra-time halves are thirty active seconds and change ends")
	knockout.active_ticks = roundi(knockout.regulation_ticks*4.0/3)-1
	knockout.take_control(9)
	knockout.step()
	check.call(knockout.period == Match.Period.SHOOTOUT and knockout.display_minute() == 120, "only an extra-time tie starts penalties")
	var shots_before: Array = knockout.shots.duplicate()
	var saves_before: Array = knockout.saves.duplicate()
	for tick in 50:
		if knockout.finished: break
		knockout.step()
	var Snapshot = load("res://match/match_snapshot.gd")
	var resumed: RefCounted = Snapshot.restore(bytes_to_var(var_to_bytes(knockout.snapshot())))
	check.call(resumed != null and resumed.snapshot() == knockout.snapshot(), "shootout including an in-flight kick resumes exactly")
	for tick in 6000:
		if knockout.finished: break
		knockout.step()
		resumed.step()
	check.call(knockout.finished and knockout.winner() >= 0, "physical shootout resolves to a winner")
	check.call(knockout.scores == [0,0] and knockout.shots == shots_before and knockout.saves == saves_before, "shootout tallies do not contaminate match goals shots or saves")
	check.call(knockout.signature() == resumed.signature(), "resumed shootout has identical outcomes and RNG")
	check.call(knockout.Shootout.clinched({"attempts":[3,3],"goals":[3,0]}), "shootout ends at an early mathematical clinch")
	check.call(not knockout.Shootout.clinched({"attempts":[6,5],"goals":[5,4]}), "sudden death waits for the paired response")
	check.call(knockout.Shootout.clinched({"attempts":[6,6],"goals":[5,4]}), "sudden death ends after unequal paired scores")
	var late_penalty := Match.new(42)
	late_penalty.active_ticks = late_penalty.regulation_ticks/2
	late_penalty.period = Match.Period.FIRST_HALF
	late_penalty.award_restart(0,Vector2(94,34),"penalty",12)
	check.call(late_penalty.period_extension, "awarded penalty at expiry extends its period")
	for tick in 400:
		if late_penalty.period == Match.Period.HALF_TIME: break
		late_penalty.step()
	check.call(late_penalty.period == Match.Period.HALF_TIME and late_penalty.active_ticks == late_penalty.regulation_ticks/2, "late penalty completes without adding active minutes or allowing a new attack")
	for model in [cards,keeper,emergency]:
		for p in model.players:
			if not p.active: p.position = model.players[9].position
		var expected: int = model.players.filter(func(p): return p.active and p.team != 0 and p.position.distance_to(model.players[9].position) < 3).size()
		check.call(model.close_opponents(9,3) == expected,"dismissed players exert no phantom pressure")
	var corner := Match.new(42)
	corner.award_restart(0,Vector2(105,0),"corner",12)
	check.call(corner.players[9].position.x > 90 and corner.players[2].position.x > 90,"corner routine positions real attacking receivers")
	var power: RefCounted = load("res://tests/trait_checks.gd").new().shot_fixture("power_strike",Vector2(88,34))
	var pending_offside: RefCounted = Snapshot.restore(flagged_snapshot)
	for original in [corner,pending_offside,cards,keeper,emergency,late_penalty,power]:
		var restored: RefCounted = Snapshot.restore(bytes_to_var(var_to_bytes(original.snapshot())))
		check.call(restored != null and restored.snapshot() == original.snapshot(),"rule/action snapshot round trip includes pending state")
		if restored == null: continue
		for tick in 180:
			original.acknowledge_halftime()
			restored.acknowledge_halftime()
			original.step()
			restored.step()
		check.call(original.signature() == restored.signature(),"rule/action resume preserves subsequent execution and RNG")
	for edge in [Vector2(50,-1),Vector2(-1,34)]:
		var wide := Match.new(42)
		wide.Shootout.start(wide)
		wide.BallRules.resolve(wide,Vector2(1,1),edge)
		check.call(wide.shootout.goals == [0,0] and wide.restart_kind != "throw_in","shootout wide/own-end crossing cannot award a throw or goal")
	for final_period in [Match.Period.SECOND_HALF,Match.Period.EXTRA_SECOND]:
		var winner := Match.new(42,180,null,null,true)
		winner.period = final_period
		winner.active_ticks = winner.regulation_ticks-1 if final_period == Match.Period.SECOND_HALF else roundi(winner.regulation_ticks*4.0/3)-1
		winner.scores[0] = 1
		winner.take_control(9)
		winner.step()
		check.call(winner.finished and winner.winner() == 0 and winner.shootout.is_empty(),"regulation/extra-time winner ends without unnecessary penalties")
	var rebound := Match.new(42)
	rebound.Shootout.start(rebound)
	rebound.shootout.phase = "flight"
	rebound.flight_source = rebound.shootout.actor
	rebound.last_touch = rebound.shootout.keeper
	rebound.ball_state = Match.BallState.LOOSE
	rebound.ball = Vector2(104.9,34)
	rebound.ball_velocity = Vector2(8,0)
	rebound.step()
	check.call(rebound.shootout.phase == "flight","shootout rebound stays live while still moving")
	rebound.step()
	check.call(rebound.shootout.goals == [1,0] and rebound.scores == [0,0],"rebound crossing the goal counts once in shootout tally only")
