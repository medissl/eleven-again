extends SceneTree
const Match = preload("res://match/match_sim.gd")
const Snapshot = preload("res://match/match_snapshot.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func isolate(model: RefCounted) -> void:
	for player in model.players: player.position = Vector2(50,4+player.id*2.5)
func run() -> void:
	var model := Match.new(42)
	var initial_rng: int = model.rng.state
	for tick in Match.KICKOFF_SETUP_TICKS-1: model.step()
	check(model.active_ticks == 0 and model.rng.state == initial_rng and not model.events.any(func(event): return event.kind == "kickoff_whistle"),"Entire countdown precedes whistle, active time and gameplay RNG")
	var restored: RefCounted = Snapshot.restore(model.snapshot())
	model.step()
	restored.step()
	check(model.events[-3].kind == "kickoff_whistle" and model.events[-2].kind == "kickoff" and model.active_ticks == 1,"Whistle and physical opening kick follow countdown on the same tick")
	check(model.snapshot() == restored.snapshot(),"Countdown resume stays exact")
	var holds := 0
	for seed_value in 50:
		model = Match.new(seed_value)
		isolate(model)
		model.players[0].position = Vector2(6,34)
		model.owner = -1
		model.ball_state = Match.BallState.LOOSE
		model.ball = Vector2(6.5,34)
		model.ball_velocity = Vector2(-1,0)
		model.last_touch = 20
		model.flight_source = 20
		model.advance_loose()
		if model.owner == 0:
			holds += 1
			check(model.keeper_hand_owner == 0 and model.events.back().kind == "hold","Legal loose-ball keeper collections are held in hands")
	check(holds >= 25,"Unpressured keepers actively collect a majority of slow loose deliveries")
	model = Match.new(42)
	isolate(model)
	model.players[0].position = Vector2(6,34)
	model.owner = -1
	model.ball_state = Match.BallState.LOOSE
	model.ball = Vector2(6.5,34)
	model.ball_velocity = Vector2(-1,0)
	model.last_touch = 1
	model.flight_source = 1
	model.flight_kind = "pass"
	model.advance_loose()
	check(model.owner == 0 and model.keeper_hand_owner == -1,"Intentional teammate back-pass stays foot-controlled")
	model.take_control(0,"hold")
	model.choose_targets()
	check(model.players[0].target == model.players[0].position and model.players[0].job == "distribute","Holding keeper distributes rather than dribbling towards the far goal")
	model = Match.new(42)
	model.players[8].position = Vector2(79,10)
	model.take_control(8)
	model.players[8].velocity = Vector2(3,2)
	model.choose_targets()
	var press: Array = model.players.filter(func(player): return player.team == 1 and player.job == "press")
	var cover: Array = model.players.filter(func(player): return player.team == 1 and player.job == "cover presser")
	check(press.size() == 1 and cover.size() == 1,"One defender presses while another covers")
	check(press[0].target.distance_to(model.ball) > 0 and press[0].target.distance_to(model.ball) < 2,"Presser leads the moving carrier instead of chasing a stale position")
	check(cover[0].target.distance_to(model.ball) < 12,"Cover supports the presser instead of retreating halfway to the keeper")
	model.plans[0].route = "wide"
	model.choose_targets()
	var wide: Vector2 = model.players[10].target
	model.plans[0].route = "combinations"
	model.choose_targets()
	check(absf(wide.y-34) > absf(model.players[10].target.y-34),"Wide and combination plans create different support lanes")
	check(model.oriented(model.players[9].target,0).x <= model.FootballAI.onside_limit(model,0)+0.001,"Forward offers an onside passing option before release: "+str([model.players[9].target,model.FootballAI.onside_limit(model,0),model.owner]))
	model = Match.new(42)
	isolate(model)
	model.players[9].position = Vector2(60,34)
	model.kickoff_kicker = -1
	model.take_control(9)
	model.held_ticks = 30
	model.players[12].position = model.ball+Vector2(0.5,0)
	model.players[12].cooldown = 40
	model.players[13].position = model.ball+Vector2(1.2,0)
	model.players[13].cooldown = 0
	model.challenge_carrier()
	check(model.players[13].cooldown > 0,"A nearby covering defender can tackle when the closest defender is recovering")
	model.goal_scored(12,0)
	var goal: Dictionary = model.events.filter(func(event): return event.kind == "goal").back()
	check(goal.team == 0 and goal.own_goal and goal.actor == 12,"Own goal credits the scoring side while retaining the actual last-touch actor")
	print("WATCHABILITY CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)
