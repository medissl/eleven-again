extends Control

const Match = preload("res://match/match_sim.gd")
const Hud = preload("res://ui/match_hud.gd")
const MatchTheme = preload("res://ui/game_theme.tres")
var CREAM: Color = MatchTheme.get_color("ivory", "Palette")
var CORAL: Color = MatchTheme.get_color("coral", "Palette")
var AMBER: Color = MatchTheme.get_color("amber", "Palette")
@export var fixture_seed: int = 0
var sim := Match.new()
var paused := false
var speed := 1
var selected := -1
var hovered := -1
var pitch := Rect2()
var player_positions: Array[Vector2] = []
var ball := Vector2.ZERO
var hud
var font: Font
var turf: Texture2D
var name_rects: Array[Rect2] = []
var overlay_mode := ""
var overlay_parent := ""
var before_overlay_paused := false
var restore_focus: Control
var overlay_return_focus := ""
var label_alpha := PackedFloat32Array()
var label_dim_until := PackedInt64Array()
var ball_roll := 0.0
var result_dismissed := false
var presentation_fixture := 0
var presentation_events := 0
var formation_tick := -1000
var owner_tick := -1000
var presented_owner := -1
var impact_tick := -1000
var impact_position := Vector2.ZERO
var ball_trail: Array[Vector2] = []
var preparation: Control

func _ready() -> void:
	var seed_value := fixture_seed if fixture_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
	sim = Match.new(seed_value)
	font = MatchTheme.default_font
	for p in sim.players: player_positions.append(p.position)
	label_alpha.resize(22)
	label_alpha.fill(1.0)
	label_dim_until.resize(22)
	_make_turf()
	hud = Hud.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	hud.command.connect(_on_command)
	resized.connect(_layout)
	mouse_exited.connect(func():
		hovered = -1
		_sync_state())
	_layout()
	_sync_state()
	hud.apply_focus_style()
	if fixture_seed == 0: open_preparation()

func open_preparation() -> void:
	var next_seed := sim.match_seed+(1 if sim.ticks > 0 else 0)
	paused = true
	_close_overlay(false)
	if is_instance_valid(preparation): preparation.queue_free()
	preparation = load("res://ui/preparation.gd").new()
	preparation.plans[0] = sim.plans[0].duplicate(true)
	preparation.plans[1] = sim.plans[1].duplicate(true)
	preparation.ui_scale = hud.ui_scale
	add_child(preparation)
	preparation.submitted.connect(func(home,away):
		sim = Match.new(next_seed,Match.REGULATION_SECONDS,home,away)
		preparation.queue_free()
		preparation = null
		selected = -1
		hovered = -1
		result_dismissed = false
		hud.event_count = -1
		paused = false
		_sync_state())
	preparation.cancelled.connect(func():
		preparation.queue_free()
		preparation = null
		_open_overlay("menu"))

func _make_turf() -> void:
	# One reusable texture; fixed surface noise never consumes match randomness.
	var noise := FastNoiseLite.new()
	noise.seed = 71
	noise.frequency = 0.24
	var image := Image.create(384, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 384:
			var grain := noise.get_noise_2d(x, y)
			image.set_pixel(x, y, Color(0.10 + grain * 0.035, 0.245 + grain * 0.055, 0.075 + grain * 0.025))
	turf = ImageTexture.create_from_image(image)

func _layout() -> void:
	if not is_instance_valid(hud): return
	var divider := size.x - 270
	var top: float = 86 + (hud.ui_scale - 1) * 50
	var available := Rect2(24, top, divider - 48, size.y - top - 22)
	var factor := minf(available.size.x / 105, available.size.y / 68)
	pitch = Rect2(available.get_center() - Vector2(105, 68) * factor / 2, Vector2(105, 68) * factor)
	hud.arrange(pitch, divider)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not paused and not sim.finished:
		for step_index in speed:
			sim.step()
			if sim.ball_state != Match.BallState.DEAD:
				ball_roll += sim.previous_ball.distance_to(sim.ball) * 0.8
			if sim.period == Match.Period.HALF_TIME or sim.finished: break
		_sync_state()

func _sync_state() -> void:
	if not is_instance_valid(hud): return
	if presentation_fixture != sim.get_instance_id(): snap_presentation()
	_consume_presentation_events()
	var inspected := hovered if hovered >= 0 else selected
	var description := ""
	if inspected >= 0:
		var p = sim.players[inspected]
		description = "%s · %s · %s\nPAC %d SHO %d PAS %d DRI %d DEF %d PHY %d\nStamina %d · %s" % [p.name,p.role,p.card.tier().capitalize(),sim.attribute(inspected,"PAC"),sim.attribute(inspected,"SHO"),sim.attribute(inspected,"PAS"),sim.attribute(inspected,"DRI"),sim.attribute(inspected,"DEF"),sim.attribute(inspected,"PHY"),p.stamina,p.job]
	if overlay_mode.is_empty() and not _required_report().is_empty():
		_open_overlay(_required_report())
	hud.refresh(sim, paused, speed, description)
	queue_redraw()

func snap_presentation() -> void:
	# Discontinuous fixture loading is not a pass or a long-distance ball flight.
	presentation_fixture = sim.get_instance_id()
	presentation_events = sim.events.size()
	for i in 22: player_positions[i] = sim.players[i].position
	ball = sim.ball
	ball_trail.clear()
	formation_tick = -1000
	impact_tick = -1000
	owner_tick = -1000
	presented_owner = sim.owner

func _consume_presentation_events() -> void:
	for index in range(presentation_events,sim.events.size()):
		var event: Dictionary = sim.events[index]
		if event.kind == "kickoff_setup" and event.tick > 0:
			# Briefly reveal the real reset shape; never draw a fictional flight to centre.
			for i in 22: player_positions[i] = sim.players[i].position
			ball = sim.ball
			formation_tick = sim.ticks
			ball_trail.clear()
		elif event.kind == "goal":
			ball = sim.ball # The crossing and score stay visually aligned.
			ball_trail.clear()
		elif event.kind in ["received","recovery","tackle","interception","save","block"]:
			impact_tick = event.tick
			impact_position = event.position
	presentation_events = sim.events.size()
	if sim.owner != presented_owner:
		presented_owner = sim.owner
		if presented_owner >= 0: owner_tick = sim.ticks

func _process(delta: float) -> void:
	if not is_instance_valid(hud) or paused: return
	# A few milliseconds of render-only settling, with no anticipation or overshoot.
	for i in 22: player_positions[i] = player_positions[i].lerp(sim.players[i].position,1-exp(-delta*65))
	ball = ball.lerp(sim.ball,1-exp(-delta*100))
	if sim.ball_state == Match.BallState.FLIGHT and not hud.reduced_motion:
		if ball_trail.is_empty() or ball_trail.back().distance_to(ball) > 0.02: ball_trail.append(ball)
		while ball_trail.size() > 4: ball_trail.pop_front()
	else: ball_trail.clear()
	queue_redraw()

func _formation_opacity() -> float:
	if hud.reduced_motion: return 1.0
	if not sim.finished and sim.ball_state == Match.BallState.DEAD and sim.restart_kind == "kickoff":
		return clampf(sim.dead_ticks/12.0,0,1)
	var progress := clampf((sim.ticks-formation_tick)/10.0,0,1)
	return progress*progress*(3-2*progress)

func _required_report() -> String:
	if sim.period == Match.Period.HALF_TIME: return "halftime"
	if sim.finished and not result_dismissed: return "result"
	return ""

func _on_command(action: String) -> void:
	if not overlay_mode.is_empty() and action in ["pause", "speed1", "speed2"]: return
	match action:
		"pause":
			if not sim.finished: paused = not paused
		"speed1": speed = 1
		"speed2": speed = 2
		"menu", "details", "log", "settings", "restart", "new", "result": _open_overlay(action)
		"effects", "motion":
			if action == "effects": hud.effects_enabled = not hud.effects_enabled
			else: hud.reduced_motion = not hud.reduced_motion
			hud.show_panel(overlay_mode, sim)
		"scale100", "scale115", "scale125":
			hud.set_ui_scale(float(action.trim_prefix("scale")) / 100.0)
			_layout()
			hud.show_panel(overlay_mode, sim)
		"continue_half":
			if overlay_mode == "halftime" and sim.acknowledge_halftime():
				_close_overlay()
				paused = false
		"continue_result":
			if overlay_mode == "result" and sim.finished:
				result_dismissed = true
				_open_overlay("menu")
		"back": _dismiss_overlay()
		"resume":
			if not _required_report().is_empty(): _open_overlay(_required_report())
			else:
				_close_overlay()
				paused = false
		"confirm_restart": _restart(false)
		"confirm_new": _restart(true)
		"prepare": _open_overlay("prepare")
		"confirm_prepare": open_preparation()
		"quit": get_tree().quit()
	_sync_state()

func _open_overlay(mode: String) -> void:
	if overlay_mode.is_empty():
		before_overlay_paused = paused
		restore_focus = get_viewport().gui_get_focus_owner()
		overlay_parent = ""
	elif overlay_mode == "menu" and mode != "menu":
		overlay_parent = "menu"
		overlay_return_focus = mode
	else: overlay_parent = ""
	paused = true
	overlay_mode = mode
	hud.show_panel(mode, sim)

func _dismiss_overlay() -> void:
	if overlay_mode in ["halftime", "result"]: return
	if overlay_parent == "menu":
		overlay_parent = ""
		overlay_mode = "menu"
		hud.show_panel("menu", sim)
		hud.focus_action(overlay_return_focus)
	elif not _required_report().is_empty():
		_open_overlay(_required_report())
	else:
		_close_overlay()
		paused = before_overlay_paused

func _close_overlay(animate: bool = true) -> void:
	overlay_mode = ""
	overlay_parent = ""
	hud.close_panel(animate)
	if not hud.keyboard_focus:
		get_viewport().gui_release_focus()
	elif is_instance_valid(restore_focus) and restore_focus is BaseButton and not restore_focus.disabled:
		restore_focus.grab_focus()
	else:
		hud.buttons.menu.grab_focus()

func _restart(new_seed: bool = false) -> void:
	sim = Match.new(sim.match_seed + (1 if new_seed else 0),Match.REGULATION_SECONDS,sim.plans[0],sim.plans[1])
	selected = -1
	hovered = -1
	label_alpha.fill(1.0)
	label_dim_until.fill(0)
	ball_roll = 0
	result_dismissed = false
	_close_overlay(false)
	paused = false
	hud.event_count = -1
	_sync_state()

func _input(event: InputEvent) -> void:
	if is_instance_valid(preparation): return
	if event is InputEventMouseButton and event.pressed:
		hud.keyboard_focus = false
		hud.apply_focus_style()
		return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode in [KEY_TAB,KEY_ESCAPE,KEY_ENTER]:
		hud.keyboard_focus = true
		hud.apply_focus_style()
	if event.keycode == KEY_ESCAPE:
		if overlay_mode.is_empty(): _open_overlay("menu")
		elif not hud.overlay.dismiss_help(): _dismiss_overlay()
	elif not overlay_mode.is_empty(): return
	elif event.keycode == KEY_SPACE:
		if not sim.finished: paused = not paused
	elif event.keycode in [KEY_1, KEY_2]:
		speed = 1 if event.keycode == KEY_1 else 2
	elif event.keycode in [KEY_LEFT, KEY_RIGHT]:
		selected = posmod(selected + (-1 if event.keycode == KEY_LEFT else 1), 22)
		hovered = -1
	else: return
	get_viewport().set_input_as_handled()
	_sync_state()

func _gui_input(event: InputEvent) -> void:
	if not overlay_mode.is_empty(): return
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		hovered = -1
		for i in 22:
			if _field(player_positions[i]).distance_to(event.position) < 17:
				hovered = i
				if event is InputEventMouseButton: selected = i
				break
		_sync_state()

func _field(point: Vector2) -> Vector2:
	return pitch.position + point * _scale()

func _scale() -> float:
	return pitch.size.x / 105

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0c1711"))
	if pitch.size.x <= 0: return
	draw_rect(pitch.grow(9), Color("1c351b"))
	draw_texture_rect(turf, pitch, true)
	for stripe in 10:
		if stripe % 2 == 0:
			draw_rect(Rect2(pitch.position + Vector2(pitch.size.x * stripe / 10, 0), Vector2(pitch.size.x / 10, pitch.size.y)), Color(0.6, 0.7, 0.35, 0.065))
	var line := Color("c0c8a8")
	draw_rect(pitch, line, false, 1.4)
	draw_line(_field(Vector2(52.5, 0)), _field(Vector2(52.5, 68)), line, 1.4)
	draw_arc(_field(Vector2(52.5, 34)), 9.15 * _scale(), 0, TAU, 64, line, 1.4, true)
	draw_circle(_field(Vector2(52.5, 34)), 2.2, line)
	for end in 2:
		var x := 0.0 if end == 0 else 88.5
		draw_rect(Rect2(_field(Vector2(x, 13.84)), Vector2(16.5, 40.32) * _scale()), line, false, 1.4)
		x = 0.0 if end == 0 else 99.5
		draw_rect(Rect2(_field(Vector2(x, 24.84)), Vector2(5.5, 18.32) * _scale()), line, false, 1.4)
		var spot := Vector2(11 if end == 0 else 94, 34)
		draw_circle(_field(spot), 2, line)
		draw_arc(_field(spot), 9.15 * _scale(), -0.93 if end == 0 else PI - 0.93, 0.93 if end == 0 else PI + 0.93, 32, line, 1.4, true)
		_draw_goal(end)
	for point in [Vector2(0,0),Vector2(105,0),Vector2(105,68),Vector2(0,68)]:
		var start := 0.0 if point == Vector2.ZERO else (PI / 2 if point.y == 0 else (PI if point.x > 0 else PI * 1.5))
		draw_arc(_field(point), _scale(), start, start + PI / 2, 12, line, 1.1, true)
	if not hud.reduced_motion and sim.ticks-impact_tick >= 0 and sim.ticks-impact_tick < 10:
		var phase := (sim.ticks-impact_tick)/10.0
		draw_arc(_field(impact_position),7+phase*9,0,TAU,24,Color(CREAM,0.3*(1-phase)),1.2,true)
	if sim.ball_state == Match.BallState.FLIGHT and not hud.reduced_motion:
		for index in range(1,ball_trail.size()):
			draw_line(_field(ball_trail[index-1]),_field(ball_trail[index]),Color(CREAM,0.08+index*0.035),1.4,true)
	for i in 22:
		if i != sim.owner and i != selected: _draw_player(i)
	if sim.owner >= 0 and sim.owner != selected: _draw_player(sim.owner)
	if selected >= 0: _draw_player(selected)
	name_rects.clear()
	var priorities: Array[int] = []
	for index in [sim.owner, selected]:
		if index >= 0 and not priorities.has(index): priorities.append(index)
	for i in 22:
		if not priorities.has(i): priorities.append(i)
	for index in priorities: _draw_name(index)
	_draw_traits()
	_draw_ball()

func _draw_traits() -> void:
	if sim.ball_state in [Match.BallState.DEAD,Match.BallState.KICKOFF] or sim.finished: return
	var labels := 0
	var actors: Array = sim.players.duplicate()
	actors.sort_custom(func(a,b):
		var a_priority: int = (1000000 if a.id == sim.owner or a.id == selected else 0)+a.trait_state.get("started",-1000)
		var b_priority: int = (1000000 if b.id == sim.owner or b.id == selected else 0)+b.trait_state.get("started",-1000)
		return a_priority > b_priority)
	for p in actors:
		if not p.active: continue
		var state: Dictionary = p.trait_state
		if state.is_empty(): continue
		var age: int = sim.active_ticks-state.get("resolved",state.started)
		if state.state != "active" and age > 36: continue
		var position := _field(player_positions[p.id])
		var tint := Color("7bd2cf") if p.role == "GK" or state.trait in ["accelerator","recovery_sprint","touchline_burst"] else AMBER
		var alpha := 0.85 if state.state == "active" else clampf(1-age/36.0,0,1)*0.6
		if hud.effects_enabled and not hud.reduced_motion:
			var pulse := 1.0+sin((sim.active_ticks-state.started)*0.12)*0.08
			draw_arc(position,20*pulse,0,TAU,32,Color(tint,alpha*0.5),2,true)
			if state.state == "success": draw_arc(position,23,0,TAU,32,Color(tint,alpha),1,true)
		# Quiet icons retain identity off-ball; only three recent labels compete for attention.
		var icon := position+Vector2(0,-21)
		if state.kind in ["run","entry"]:
			for shift in [-3,3]: draw_polyline(PackedVector2Array([icon+Vector2(shift-2,3),icon+Vector2(shift+2,0),icon+Vector2(shift-2,-3)]),Color(tint,alpha),1.3,true)
		elif state.kind == "pass":
			draw_line(icon+Vector2(-5,0),icon+Vector2(5,0),Color(tint,alpha),1.4,true)
			draw_polyline(PackedVector2Array([icon+Vector2(1,-4),icon+Vector2(5,0),icon+Vector2(1,4)]),Color(tint,alpha),1.3,true)
		elif state.kind in ["shot","save","parry"]:
			draw_arc(icon,5,0,TAU,16,Color(tint,alpha),1.3,true)
			draw_line(icon+Vector2(-3,-3),icon+Vector2(3,3),Color(tint,alpha),1.2,true)
		else: draw_polyline(PackedVector2Array([icon+Vector2(-4,0),icon+Vector2(0,-5),icon+Vector2(4,0),icon+Vector2(0,5),icon+Vector2(-4,0)]),Color(tint,alpha),1.2,true)
		if labels < 3 and sim.active_ticks-state.started < 72:
			var title: String = state.trait.replace("_"," ").to_upper()
			var width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
			var origin := Vector2(clampf(position.x-width/2,pitch.position.x+2,pitch.end.x-width-2),maxf(pitch.position.y+12,position.y-32))
			draw_string_outline(font,origin,title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("0c2117"))
			draw_string(font,origin,title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(tint,alpha))
			labels += 1

func _draw_ball() -> void:
	var opacity := _formation_opacity()
	var ground := _field(ball)
	var bounce := 0.0
	var touch := Vector2.ZERO
	if not hud.reduced_motion and sim.owner >= 0 and sim.players[sim.owner].position.distance_to(sim.players[sim.owner].previous) > 0.005:
		var phase := sim.held_ticks * TAU / 24.0
		bounce = absf(sin(phase)) * 1.6
		touch = (sim.players[sim.owner].position - sim.players[sim.owner].previous).normalized() * sin(phase) * 1.8
	var center := ground + touch - Vector2(0, bounce)
	center.y -= sim.ball_height*5
	draw_set_transform(ground + Vector2(0, 4), 0, Vector2(1.35, 0.5))
	draw_circle(Vector2.ZERO, 4.7, Color(0.01,0.03,0.02,0.75*opacity))
	draw_set_transform(Vector2.ZERO)
	draw_circle(center, 6.2, Color(Color("102118"),opacity))
	draw_circle(center, 5.1, Color(Color("e5e8df"),opacity))
	if hud.effects_enabled and sim.flight_trait_actor >= 0 and sim.ball_state == Match.BallState.FLIGHT:
		draw_arc(center,6.5,0,TAU,20,Color(AMBER,0.85*opacity),1.3,true)
	var patch := PackedVector2Array()
	for i in 5: patch.append(center + Vector2.from_angle(ball_roll + i * TAU / 5) * 2.0)
	draw_colored_polygon(patch, Color(Color("203c2a"),opacity))
	for i in 3:
		var angle := ball_roll + i * TAU / 3
		draw_colored_polygon(PackedVector2Array([center + Vector2.from_angle(angle) * 3.2, center + Vector2.from_angle(angle - 0.3) * 4.8, center + Vector2.from_angle(angle + 0.3) * 4.8]), Color(Color("203c2a"),opacity))
	draw_circle(center + Vector2(-1.6, -2.0), 0.9, Color(1,1,1,0.8*opacity))

func _draw_goal(end: int) -> void:
	var depth := 2.5 * _scale()
	var mouth_x := pitch.position.x if end == 0 else pitch.end.x
	var net_x := mouth_x - depth if end == 0 else mouth_x
	var top := _field(Vector2(0, 30.34)).y
	var bottom := _field(Vector2(0, 37.66)).y
	var net := Rect2(net_x, top, depth, bottom - top)
	var recoil := 0.0
	var age: int = sim.ticks - hud.goal_cue_tick
	if hud.effects_enabled and not hud.reduced_motion and hud.goal_cue_actor >= 0 and age >= 0 and age < 90:
		var scoring_team: int = sim.players[hud.goal_cue_actor].team
		if (end == 1) == (sim.direction(scoring_team) > 0):
			recoil = sin(age * 0.3) * exp(-age / 25.0) * 2.0
	draw_rect(Rect2(net.position + Vector2(1, 3), net.size), Color(0.01,0.035,0.02,0.8))
	draw_rect(net, Color("203328"))
	var mesh := Color(0.77,0.83,0.75,0.52)
	for y in range(0, int(net.size.y) + 1, 5):
		draw_line(net.position + Vector2(recoil if end == 0 else 0.0, y), Vector2(net.end.x + (recoil if end == 1 else 0.0), net.position.y + y), mesh, 0.8, true)
	for x in range(0, int(depth) + 1, 5):
		draw_line(net.position + Vector2(x, 0), Vector2(net.position.x + x, net.end.y), mesh, 0.8, true)
	draw_rect(net, Color("a8b4a4"), false, 1.3)
	# The bright mouth posts sit on the actual goal line; net depth is purely presentation.
	for y in [top, bottom]:
		draw_line(Vector2(net.position.x, y), Vector2(net.end.x, y), CREAM, 2.5, true)
		draw_circle(Vector2(mouth_x, y), 2.3, Color.WHITE)
	draw_line(Vector2(mouth_x, top), Vector2(mouth_x, bottom), Color(0.96,0.97,0.9,0.7), 2, true)

func _draw_player(index: int) -> void:
	if not sim.players[index].active: return
	var point := _field(player_positions[index])
	var opacity := _formation_opacity()
	var color := Color(CREAM if index < 11 else CORAL,opacity)
	if selected == index or sim.owner == index:
		var transfer := 0.0 if hud.reduced_motion else 3*clampf(1-(sim.ticks-owner_tick)/10.0,0,1)
		draw_arc(point, 17.0 if selected == index else 16.0+transfer, 0, TAU, 36, Color(AMBER,opacity), 2.0 if selected == index else 1.3, true)
	if hud.effects_enabled and index == hud.goal_cue_actor and sim.ticks - hud.goal_cue_tick < 150:
		draw_arc(point, 18 + (0 if hud.reduced_motion else sin((sim.ticks - hud.goal_cue_tick) * 0.15)), 0, TAU, 36, Color(AMBER,opacity), 1.5, true)
	draw_circle(point + Vector2(1, 2.5), 13.8, Color(0.02,0.05,0.025,0.85*opacity))
	draw_circle(point, 13.2, Color(Color("102315"),opacity))
	draw_circle(point, 12.3, Color(CREAM,opacity))
	draw_circle(point, 11.1, color)
	if index % 11 == 0:
		draw_circle(point, 10.3, Color(Color("247f53"),opacity))
	if index >= 11:
		draw_arc(point, 9, PI * 0.10, PI * 0.90, 14, Color(Color("9d4937"),opacity), 1.2, true)
	var number := str(index % 11 + 1)
	var number_pos := point + Vector2(-font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2, 5)
	if index >= 11 or index % 11 == 0:
		for offset in [Vector2(-0.7,0),Vector2(0.7,0),Vector2(0,-0.7),Vector2(0,0.7)]:
			draw_string(font, number_pos + offset, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(Color("27432d"),opacity))
	draw_string(font, number_pos, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CREAM if index % 11 == 0 or index >= 11 else Color("102315"),opacity))

func _draw_name(index: int) -> void:
	if not sim.players[index].active: return
	var point := _field(player_positions[index])
	var player_name: String = sim.players[index].name
	var pixels: int = roundi(14 * hud.ui_scale)
	while font.get_string_size(player_name,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x > 120 * hud.ui_scale and player_name.length() > 2:
		player_name = player_name.left(player_name.length()-2) + "…"
	var width := font.get_string_size(player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
	# A fixed below-token anchor prevents the old above/below flipping in duels.
	var pos := point + Vector2(-width / 2, 29)
	pos.x = clampf(pos.x, 4, size.x - 276 - width)
	pos.y = minf(pos.y, size.y - 4)
	var rect := Rect2(pos + Vector2(-2, -15), Vector2(width + 4, 19))
	var blocked := false
	for existing in name_rects: blocked = blocked or existing.intersects(rect)
	var important := index == sim.owner or index == selected
	if blocked and not important: label_dim_until[index] = sim.ticks + 30
	var target := 0.2 if sim.ticks < label_dim_until[index] and not important else 1.0
	label_alpha[index] = 1.0 if important else lerpf(label_alpha[index], target, minf(get_process_delta_time() * 8, 1))
	if not blocked or important: name_rects.append(rect)
	var opacity := label_alpha[index]*_formation_opacity()
	for halo in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
		draw_string(font, pos + halo, player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, Color(0.04,0.08,0.04,opacity))
	draw_string(font, pos, player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, Color(CREAM, opacity))
