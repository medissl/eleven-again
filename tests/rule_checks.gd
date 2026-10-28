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
