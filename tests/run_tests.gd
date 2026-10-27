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
	a.pass_pending = false
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
	var settled := Match.new(8)
	settled.launch_ball(settled.players[8].position, 24, "pass")
	settled.ball_state = Match.BallState.LOOSE
	settled.take_control(8)
	settled.take_control(8)
	check(settled.completed_passes[0] == 1, "settled pass reception counts exactly once")
	test_shots()
	test_clock()
	print("CHECKS ", checks, " FAILURES ", failures.size())
	quit(0 if failures.is_empty() else 1)

func shot_fixture(seed_value: int):
	var match_model := Match.new(seed_value)
	for p in match_model.players:
		p.position = Vector2(20, 5)
	match_model.players[9].position = Vector2(85, 34)
	match_model.players[11].position = Vector2(99.5, 34)
	match_model.take_control(9)
	match_model.shots[0] = 1
	match_model.shot_quality = 0.3
	match_model.launch_ball(Vector2(105, 34), 32, "shot")
	return match_model

func finish_flight(match_model) -> void:
	for tick in 200:
		if match_model.ball_state != Match.BallState.FLIGHT:
			break
		match_model.advance_flight()

func test_shots() -> void:
	var chance = shot_fixture(3)
	chance.take_control(9)
	chance.held_ticks = 30
	chance.choose_action()
	check(chance.flight_kind == "shot" and chance.owner == -1, "a good close chance is not starved by early passing")
	var blocked = shot_fixture(10)
	blocked.players[12].position = Vector2(90, 34)
	finish_flight(blocked)
	check(blocked.events.back().kind == "block" and blocked.scores[0] == 0, "physical block precedes goalkeeper")
	check(blocked.ball_state == Match.BallState.LOOSE, "blocked shot remains a real loose ball")
	var goal = shot_fixture(11)
	goal.players[11].position.y = 15
	finish_flight(goal)
	check(goal.scores == [1, 0] and goal.events.back().kind == "goal", "goal from crossing the goal line")
	check(goal.ball.x == 105 and goal.ball_state == Match.BallState.DEAD, "goal celebration has no owner")
	var active_before: int = goal.active_ticks
	goal.step()
	check(goal.active_ticks == active_before, "celebration does not consume active play")
	var holds := 0
	var parries := 0
	for seed_value in 40:
		var saved = shot_fixture(seed_value)
		finish_flight(saved)
		if saved.events.back().kind == "hold":
			holds += 1
			check(saved.owner == 11 and saved.saves[1] == 1, "keeper holds after one save event")
		elif saved.events.back().kind == "parry":
			parries += 1
			check(saved.owner == -1 and saved.ball_state == Match.BallState.LOOSE and saved.ball_velocity.length() > 0, "parry creates moving rebound")
	check(holds > 0 and parries > 0, "seeded scenarios exercise holds and parries")
	var miss = shot_fixture(12)
	miss.flight_target = Vector2(105, 43)
	miss.ball_velocity = miss.ball.direction_to(miss.flight_target) * 32
	finish_flight(miss)
	check(miss.scores == [0, 0] and miss.shots_on_target == [0, 0], "off-target trajectory cannot add a goal or on-target stat")

func test_clock() -> void:
	var match_model := Match.new(11027)
	match_model.active_ticks = 1799
	match_model.step()
	check(match_model.period == Match.Period.HALF_TIME and match_model.active_ticks == 1800, "halftime after thirty active seconds")
	for tick in 120:
		match_model.step()
	check(match_model.active_ticks == 1800 and match_model.period == Match.Period.SECOND_HALF, "halftime freezes active clock")
	check(match_model.players[match_model.owner].team == 1 and match_model.direction(0) == -1, "second half changes ends and kickoff team")
	match_model.active_ticks = 3599
	match_model.step()
	check(match_model.finished and match_model.events.back().minute == 90, "full time at sixty active seconds")
	var final_state: Array = match_model.signature()
	match_model.step()
	check(match_model.signature() == final_state, "full time cannot advance or commit twice")
	for seed_value in [11027, 42, 7, 2026]:
		var fixture := Match.new(seed_value)
		while not fixture.finished and fixture.ticks < 9000:
			fixture.step()
		check(fixture.finished and fixture.active_ticks == 3600, "fixture finishes without endless stoppages")
		var goals := [0, 0]
		for event in fixture.events:
			if event.kind == "goal":
				goals[event.team] += 1
		check(goals == fixture.scores, "scoreboard agrees with authoritative goals")
		print("FIXTURE ", seed_value, " score=", fixture.scores, " shots=", fixture.shots, " passes=", fixture.completed_passes, " tackles=", fixture.tackles, " wall_seconds=", snappedf(fixture.ticks / 60.0, 0.1))
		if seed_value == 11027 and "--trace" in OS.get_cmdline_user_args():
			for event in fixture.events:
				print(event.minute, " ", event.kind, " ", event.actor, " ", event.position)
