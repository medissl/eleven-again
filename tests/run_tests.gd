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
	call_deferred("run")

func run() -> void:
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
	var wing := Match.new(11027)
	wing.players[8].position = Vector2(74, 10)
	wing.take_control(8)
	wing.choose_targets()
	check(wing.players[8].target.y > 15, "wide carrier cuts inside rather than repeating the touchline duel")
	check(wing.players[9].target.x > 80 and wing.players[9].target.y > 20, "striker offers a central forward run")
	wing.players[9].position = Vector2(84, 30)
	wing.players[9].target = Vector2(92, 30)
	wing.players[8].passing = 120
	wing.pass_to(9)
	check(wing.flight_target.x > 84, "forward passes lead a moving receiver")
	test_shots()
	test_clock()
	await test_view()
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
	chance.players[9].position = Vector2(94, 34)
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
	var close_weak := 0
	var close_strong := 0
	var poor_strong := 0
	for seed_value in 64:
		for scenario in 3:
			var attempt := Match.new(seed_value)
			attempt.players[9].position = Vector2(96, 34) if scenario < 2 else Vector2(70, 64)
			attempt.players[9].shooting = 60 if scenario == 0 else 100
			attempt.take_control(9)
			attempt.shoot()
			if attempt.events.back().on_target:
				if scenario == 0: close_weak += 1
				elif scenario == 1: close_strong += 1
				else: poor_strong += 1
	check(close_strong > close_weak, "better shooting improves the same chance over paired seeds")
	check(close_weak > poor_strong, "good close chances can outperform stronger bad-angle shots")

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
			check((fixture.owner >= 0) == (fixture.ball_state == Match.BallState.CONTROLLED), "full-fixture exclusive ball ownership")
			check(fixture.ball.is_finite() and fixture.ball.x >= 0 and fixture.ball.x <= 105 and fixture.ball.y >= 0 and fixture.ball.y <= 68, "full-fixture finite ball stays in field or on goal line")
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

func key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func test_view() -> void:
	var view = load("res://match/match_view.tscn").instantiate()
	root.add_child(view)
	view.set_physics_process(false)
	view._physics_process(Match.DT)
	check(view.sim.ticks == 0, "ready screen does not run the match")
	view._input(key(KEY_SPACE))
	view._physics_process(Match.DT)
	check(not view.paused and view.sim.ticks == 1, "Space begins play even when a button has focus")
	view._input(key(KEY_SPACE))
	var frozen: Array = view.sim.signature()
	for frame in 30:
		view._physics_process(Match.DT)
	check(view.sim.signature() == frozen, "paused viewing consumes no ticks or RNG")
	view._input(key(KEY_RIGHT))
	check(view.selected == 0 and "Ward" in view.labels.inspection.text, "keyboard player inspection")
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = view._field(view.player_positions[3])
	view._gui_input(click)
	check(view.selected == 3 and "Silva" in view.labels.inspection.text, "mouse player inspection")
	view._input(key(KEY_ESCAPE))
	check(view.pause_menu.visible and view.paused, "Escape opens a paused help menu")
	view._input(key(KEY_ESCAPE))
	check(not view.pause_menu.visible and view.paused, "closing help preserves pause")
	view.buttons.new.pressed.emit()
	check(view.sim.match_seed == 11028 and view.sim.ticks == 0 and view.paused, "new fixture creates a fresh seeded match")
	view.sim = Match.new(42)
	view.last_event_count = -1
	view.buttons.pause.pressed.emit()
	var normal_frames := 0
	while not view.sim.finished and normal_frames < 9000:
		view._physics_process(Match.DT)
		normal_frames += 1
	var final_state: Array = view.sim.signature()
	check(view.labels.score.text == "%d  –  %d" % view.sim.scores and "FULL TIME" in view.labels.clock.text, "HUD agrees with seeded final result")
	check("Full time · %d – %d" % view.sim.scores in view.feed.text, "journal result agrees with scoreboard")
	view.buttons.detail.pressed.emit()
	check("passes toward" in view.feed.text or "receives the pass" in view.feed.text, "detailed feed exposes lower-value actions")
	view.buttons.restart.pressed.emit()
	view.buttons.speed.pressed.emit()
	view.buttons.pause.pressed.emit()
	var fast_frames := 0
	while not view.sim.finished and fast_frames < 9000:
		randf() # Cosmetic/global RNG cannot affect the independent match stream.
		view._physics_process(Match.DT)
		fast_frames += 1
	check(view.sim.signature() == final_state, "1x and 2x viewing yield identical full state and event log")
	check(fast_frames == ceili(normal_frames / 2.0), "2x advances two fixed steps per viewing frame")
	var headless := Match.new(42)
	while not headless.finished:
		headless.step()
	check(headless.signature() == final_state, "headless and presented matches are identical")
	view.buttons.restart.pressed.emit()
	check(view.sim.scores == [0, 0] and view.sim.active_ticks == 0 and view.sim.events.size() == 1, "restart clears scores events and clock")
	view.queue_free()
	await process_frame
