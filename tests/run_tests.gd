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
		check(a.owner >= 0 and a.ball_state == Match.BallState.CONTROLLED, "exclusive controlled ball")
		check(a.ball == a.players[a.owner].position, "ball follows its sole owner")
		for p in a.players:
			check(p.position.is_finite() and Rect2(Vector2.ZERO, Match.FIELD).has_point(p.position), "finite in-bounds player")
	check(a.signature() == b.signature(), "supported-build repeatability")
	a.owner = -1
	a.ball_state = Match.BallState.LOOSE
	a.ball = a.players[5].position
	a.step()
	check(a.owner == 5, "reachable loose ball recovery")
	check(a.events.back().kind == "recovery", "recovery event derives from control")
	print("CHECKS ", checks, " FAILURES ", failures.size())
	quit(0 if failures.is_empty() else 1)
