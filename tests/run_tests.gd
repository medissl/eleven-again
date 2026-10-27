extends SceneTree

const Match = preload("res://match/match_sim.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	var a := Match.new(42)
	var b := Match.new(42)
	check(a.players.size() == 22, "two complete fictional elevens")
	for tick in 600:
		a.step()
		b.step()
		check((a.owner >= 0) == (a.ball_state == Match.BallState.CONTROLLED), "exclusive controlled ball")
		if a.owner >= 0:
			check(a.ball == a.players[a.owner].position, "ball follows its sole owner")
		for p in a.players:
			check(p.position.is_finite() and Rect2(Vector2.ZERO, Match.FIELD).has_point(p.position), "finite in-bounds player")
	check(a.signature() == b.signature(), "supported-build repeatability")
	check(a.pass_attempts[0] + a.pass_attempts[1] > 0, "football includes actual passes")
	a.owner = -1
	a.ball_state = Match.BallState.LOOSE
	a.ball = a.players[5].position
	a.step()
	check(a.owner == 5, "reachable loose ball recovery")
	check(a.events.back().kind == "recovery", "recovery event derives from control")
	var lane := Match.new(7)
	for p in lane.players:
		p.position = Vector2(10, p.id * 2.0 + 5)
	lane.players[9].position = Vector2(40, 34)
	lane.players[8].position = Vector2(60, 34)
	lane.players[12].position = Vector2(49, 34)
	lane.take_control(9)
	lane.launch_ball(Vector2(60, 34), 24, "pass")
	var initial_ball: Vector2 = lane.ball
	lane.advance_flight()
	check(lane.owner == -1 and lane.ball.distance_to(initial_ball) < 0.5, "pass travels, never teleports")
	for tick in 30:
		if lane.ball_state == Match.BallState.FLIGHT:
			lane.advance_flight()
	check(lane.owner == 12 and lane.events.back().kind == "interception", "reachable opponent intercepts actual lane")
	lane.take_control(9)
	lane.held_ticks = 30
	lane.players[12].position = lane.ball + Vector2(1, 0)
	lane.challenge_carrier()
	var event_count: int = lane.events.size()
	lane.challenge_carrier()
	check(lane.events.size() == event_count, "challenge cooldown prevents per-frame retries")
	print("CHECKS ", checks, " FAILURES ", failures.size())
	quit(0 if failures.is_empty() else 1)
