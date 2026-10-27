extends Control

const Match = preload("res://match/match_sim.gd")
const Hud = preload("res://ui/match_hud.gd")
const CREAM := Color("f1eedb")
const CORAL := Color("ed7864")
const AMBER := Color("ecc14f")
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
var label_alpha := PackedFloat32Array()
var label_dim_until := PackedInt64Array()
var ball_roll := 0.0
var result_dismissed := false

func _ready() -> void:
	var seed_value := fixture_seed if fixture_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
	sim = Match.new(seed_value)
	font = ThemeDB.fallback_font
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
	hud.buttons.pause.grab_focus()

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
	var available := Rect2(24, 86, divider - 48, size.y - 108)
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
	for i in 22: player_positions[i] = sim.players[i].position
	ball = sim.ball
	var inspected := hovered if hovered >= 0 else selected
	var description := ""
	if inspected >= 0:
		var p = sim.players[inspected]
		description = "%s · %s\nPAC %d  SHO %d  PAS %d\nDRI %d  DEF %d%s" % [p.name, "Meadow" if p.team == 0 else "Harbor", p.pace, p.shooting, p.passing, p.dribbling, p.defence, "  GK %d" % p.keeping if inspected % 11 == 0 else ""]
	if overlay_mode.is_empty() and not _required_report().is_empty():
		_open_overlay(_required_report())
	hud.refresh(sim, paused, speed, description)
	queue_redraw()

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
		"menu", "details", "log", "restart", "new", "result": _open_overlay(action)
		"effects", "motion":
			if action == "effects": hud.effects_enabled = not hud.effects_enabled
			else: hud.reduced_motion = not hud.reduced_motion
			hud.show_panel("menu", sim)
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
		"quit": get_tree().quit()
	_sync_state()

func _open_overlay(mode: String) -> void:
	if overlay_mode.is_empty():
		before_overlay_paused = paused
		restore_focus = get_viewport().gui_get_focus_owner()
		overlay_parent = ""
	elif overlay_mode == "menu" and mode != "menu":
		overlay_parent = "menu"
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
	elif not _required_report().is_empty():
		_open_overlay(_required_report())
	else:
		_close_overlay()
		paused = before_overlay_paused

func _close_overlay() -> void:
	overlay_mode = ""
	overlay_parent = ""
	hud.close_panel()
	if is_instance_valid(restore_focus) and restore_focus is BaseButton and not restore_focus.disabled:
		restore_focus.grab_focus()
	else:
		hud.buttons.menu.grab_focus()

func _restart(new_seed: bool = false) -> void:
	sim = Match.new(sim.match_seed + (1 if new_seed else 0))
	selected = -1
	hovered = -1
	label_alpha.fill(1.0)
	label_dim_until.fill(0)
	ball_roll = 0
	result_dismissed = false
	_close_overlay()
	paused = false
	hud.event_count = -1
	_sync_state()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode == KEY_ESCAPE:
		if overlay_mode.is_empty(): _open_overlay("menu")
		else: _dismiss_overlay()
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
	_draw_ball()

func _draw_ball() -> void:
	var ground := _field(ball)
	var bounce := 0.0
	var touch := Vector2.ZERO
	if not hud.reduced_motion and sim.owner >= 0 and sim.players[sim.owner].position.distance_to(sim.players[sim.owner].previous) > 0.005:
		var phase := sim.held_ticks * TAU / 24.0
		bounce = absf(sin(phase)) * 1.6
		touch = (sim.players[sim.owner].position - sim.players[sim.owner].previous).normalized() * sin(phase) * 1.8
	var center := ground + touch - Vector2(0, bounce)
	draw_set_transform(ground + Vector2(0, 4), 0, Vector2(1.35, 0.5))
	draw_circle(Vector2.ZERO, 4.7, Color(0.01,0.03,0.02,0.75))
	draw_set_transform(Vector2.ZERO)
	draw_circle(center, 6.2, Color("102118"))
	draw_circle(center, 5.1, Color("e5e8df"))
	var patch := PackedVector2Array()
	for i in 5: patch.append(center + Vector2.from_angle(ball_roll + i * TAU / 5) * 2.0)
	draw_colored_polygon(patch, Color("203c2a"))
	for i in 3:
		var angle := ball_roll + i * TAU / 3
		draw_colored_polygon(PackedVector2Array([center + Vector2.from_angle(angle) * 3.2, center + Vector2.from_angle(angle - 0.3) * 4.8, center + Vector2.from_angle(angle + 0.3) * 4.8]), Color("203c2a"))
	draw_circle(center + Vector2(-1.6, -2.0), 0.9, Color(1,1,1,0.8))

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
	var point := _field(player_positions[index])
	var color := CREAM if index < 11 else CORAL
	if selected == index or sim.owner == index:
		draw_arc(point, 17.0 if selected == index else 16.0, 0, TAU, 36, AMBER, 2.0 if selected == index else 1.3, true)
	if hud.effects_enabled and index == hud.goal_cue_actor and sim.ticks - hud.goal_cue_tick < 150:
		draw_arc(point, 18 + (0 if hud.reduced_motion else sin((sim.ticks - hud.goal_cue_tick) * 0.15)), 0, TAU, 36, AMBER, 1.5, true)
	draw_circle(point + Vector2(1, 2.5), 13.8, Color(0.02,0.05,0.025,0.85))
	draw_circle(point, 13.2, Color("102315"))
	draw_circle(point, 12.3, CREAM)
	draw_circle(point, 11.1, color)
	if index % 11 == 0:
		draw_circle(point, 10.3, Color("247f53"))
	if index >= 11:
		draw_arc(point, 9, PI * 0.10, PI * 0.90, 14, Color("9d4937"), 1.2, true)
	var number := str(index % 11 + 1)
	var number_pos := point + Vector2(-font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2, 5)
	if index >= 11 or index % 11 == 0:
		for offset in [Vector2(-0.7,0),Vector2(0.7,0),Vector2(0,-0.7),Vector2(0,0.7)]:
			draw_string(font, number_pos + offset, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("27432d"))
	draw_string(font, number_pos, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM if index % 11 == 0 or index >= 11 else Color("102315"))

func _draw_name(index: int) -> void:
	var point := _field(player_positions[index])
	var player_name: String = Match.NAMES[index]
	var width := font.get_string_size(player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
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
	for halo in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
		draw_string(font, pos + halo, player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.04,0.08,0.04,label_alpha[index]))
	draw_string(font, pos, player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CREAM, label_alpha[index]))
