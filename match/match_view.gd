extends Control
signal campaign_action(action: String)

const Match = preload("res://match/match_sim.gd")
const Hud = preload("res://ui/match_hud.gd")
static var MatchTheme: Theme = preload("res://ui/matchday_theme.gd").build()
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
var type_layer: Node2D
var world: Node2D
var world_viewport: SubViewport
var world_image: TextureRect
var turf: Texture2D
static var shared_turf: Texture2D
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
var trail_times: Array[float] = []
var trail_clock := 0.0
var name_metrics := {}
var preparation: Control
var external_model: RefCounted
var campaign_mode := false
var team_names: Array = ["Meadow XI","Harbor XI"]
var team_kits: Array = [Color("efe9d9"),Color("ed7864")]
var key_bindings := {"pause":KEY_SPACE,"speed1":KEY_1,"speed2":KEY_2,"menu":KEY_ESCAPE}
var audio_enabled := true
var audio: Node
const Motion = preload("res://ui/motion.gd")
var replay_history := preload("res://match/replay_buffer.gd").new()
var goal_replay: Control
var replays_enabled := true
var card_library: RefCounted

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_make_pixel_layer()
	get_tree().node_added.connect(_motion_added)
	if audio_enabled: audio=preload("res://ui/audio.gd").obtain(self)
	theme = MatchTheme
	var seed_value := fixture_seed if fixture_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
	sim = external_model if external_model != null else Match.new(seed_value)
	font = MatchTheme.default_font
	for p in sim.players: player_positions.append(p.position)
	label_alpha.resize(22)
	label_alpha.fill(1.0)
	label_dim_until.resize(22)
	_make_turf()
	hud = Hud.new()
	hud.campaign_mode = campaign_mode
	hud.team_names = team_names.duplicate()
	hud.team_kits = team_kits.duplicate()
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
	if is_instance_valid(audio): audio.set_match(true)
	if fixture_seed == 0 and external_model == null: open_preparation()

func _motion_added(node: Node) -> void:
	if node is Control and is_ancestor_of(node): _bind_motion.call_deferred(node.get_instance_id())

func _bind_motion(id: int) -> void:
	var node := instance_from_id(id) as Control
	if is_instance_valid(node) and node.is_inside_tree(): Motion.bind_control(node,func(): return is_instance_valid(hud) and hud.reduced_motion)

func open_preparation() -> void:
	if is_instance_valid(audio): audio.set_match(false)
	var next_seed := sim.match_seed+(1 if sim.ticks > 0 else 0)
	paused = true
	_close_overlay(false)
	if is_instance_valid(preparation): preparation.queue_free()
	preparation = load("res://ui/preparation.gd").new()
	preparation.plans[0] = sim.plans[0].duplicate(true)
	preparation.plans[1] = sim.plans[1].duplicate(true)
	preparation.ui_scale = hud.ui_scale
	preparation.knockout = sim.knockout
	preparation.reduced_motion = hud.reduced_motion
	add_child(preparation)
	preparation.submitted.connect(func(home,away,resolve_ties):
		sim = Match.new(next_seed,Match.REGULATION_SECONDS,home,away,resolve_ties)
		preparation.queue_free()
		preparation = null
		selected = -1
		hovered = -1
		result_dismissed = false
		hud.event_count = -1
		paused = false
		if is_instance_valid(audio): audio.set_match(true)
		_sync_state())
	preparation.cancelled.connect(func():
		preparation.queue_free()
		preparation = null
		_open_overlay("menu"))

func _make_turf() -> void:
	# One reusable texture; fixed surface noise never consumes match randomness.
	if shared_turf != null:
		turf = shared_turf
		return
	var image := Image.create(64,64,false,Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var fleck := posmod(x*73+y*151+x*y*3,97)
			image.set_pixel(x,y,Color("3F8050") if fleck == 0 else Color("335A41"))
	turf = ImageTexture.create_from_image(image)
	shared_turf = turf

func _layout() -> void:
	_layout_pixel_layer()
	if not is_instance_valid(hud): return
	var divider := size.x - 270
	var top: float = 86 + (hud.ui_scale - 1) * 50
	var available := Rect2(40, top, divider - 80, size.y - top - 22)
	var factor := minf(available.size.x / 105, available.size.y / 68)
	pitch = Rect2(available.get_center() - Vector2(105, 68) * factor / 2, Vector2(105, 68) * factor)
	hud.arrange(pitch, divider)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(goal_replay): return
	if not paused and not sim.finished:
		for step_index in speed:
			var before_events := sim.events.size()
			sim.step()
			replay_history.capture(sim)
			if sim.ball_state != Match.BallState.DEAD:
				ball_roll += sim.previous_ball.distance_to(sim.ball) * 0.8
			if sim.period == Match.Period.HALF_TIME or sim.finished or sim.events.slice(before_events).any(func(event): return event.kind == "goal"): break
		_sync_state()

func _sync_state() -> void:
	if not is_instance_valid(hud): return
	if presentation_fixture != sim.get_instance_id(): snap_presentation()
	_consume_presentation_events()
	if is_instance_valid(audio): audio.watch_match(sim,paused)
	var inspected := hovered if hovered >= 0 else selected
	var description := ""
	if inspected >= 0:
		var p = sim.players[inspected]
		var keys := ["REF","HAN","POS","DIV","KIC","PAC"] if p.role == "GK" else ["PAC","SHO","PAS","DRI","DEF","PHY"]
		description = "%s · %s%s\n%s %d  %s %d  %s %d\n%s %d  %s %d  %s %d\nStamina %d · %s" % [p.name,p.role," · Sent off" if not p.active else "",keys[0],sim.attribute(inspected,keys[0]),keys[1],sim.attribute(inspected,keys[1]),keys[2],sim.attribute(inspected,keys[2]),keys[3],sim.attribute(inspected,keys[3]),keys[4],sim.attribute(inspected,keys[4]),keys[5],sim.attribute(inspected,keys[5]),p.stamina,p.job]
		if not p.card.trait_id.is_empty():
			var definition: Dictionary = sim.Traits.catalogue[p.card.trait_id]
			var ready := "Ready" if sim.active_ticks >= p.trait_ready else "%d′ cooldown" % ceili((p.trait_ready-sim.active_ticks)*90.0/sim.regulation_ticks)
			description += "\n%s · %d/%d · %s" % [definition.name,p.trait_uses,sim.trait_allowance,ready if p.role in definition.positions else "Role unavailable"]
			hud.inspection.tooltip_text = definition.trigger+"\n"+definition.effect+"\nCounterplay: "+definition.counterplay
	if not is_instance_valid(goal_replay) and overlay_mode.is_empty() and not _required_report().is_empty():
		_open_overlay(_required_report())
	hud.refresh(sim, paused, speed, description)
	queue_redraw()

func snap_presentation() -> void:
	# Discontinuous fixture loading is not a pass or a long-distance ball flight.
	presentation_fixture = sim.get_instance_id()
	presentation_events = sim.events.size()
	replay_history.clear()
	replay_history.capture(sim)
	hud.added_period = -1
	hud.cue.duration = 0
	hud.cue.hide()
	if sim.ticks == 0 and sim.ball_state == Match.BallState.KICKOFF:
		hud.cue.consume(sim.events.back(),team_names)
	for i in 22: player_positions[i] = sim.players[i].position
	ball = sim.ball
	ball_trail.clear()
	trail_times.clear()
	formation_tick = -1000
	impact_tick = -1000
	owner_tick = -1000
	presented_owner = sim.owner

func _consume_presentation_events() -> void:
	for index in range(presentation_events,sim.events.size()):
		var event: Dictionary = sim.events[index]
		if is_instance_valid(audio) and event.tick >= sim.ticks-2: audio.consume(event)
		if event.tick >= sim.ticks-2: hud.cue.consume(event,team_names)
		if event.kind == "goal" and event.tick >= sim.ticks-2:
			if replays_enabled: _show_goal_replay(event)
			else: hud.cue.present("GOAL",str(event.get("actor_name","")).to_upper(),1.65,4)
		if event.kind in ["kickoff_setup","shootout_setup","restart_setup"] and event.tick > 0:
			# Briefly reveal the real reset shape; never draw a fictional flight to centre.
			for i in 22: player_positions[i] = sim.players[i].position
			ball = sim.ball
			formation_tick = sim.ticks
			ball_trail.clear()
			trail_times.clear()
		elif event.kind == "goal":
			ball = sim.ball # The crossing and score stay visually aligned.
			ball_trail.clear()
			trail_times.clear()
		elif event.kind in ["received","recovery","tackle","interception","save","block"]:
			impact_tick = event.tick
			impact_position = event.position
	presentation_events = sim.events.size()
	if sim.owner != presented_owner:
		presented_owner = sim.owner
		if presented_owner >= 0: owner_tick = sim.ticks

func _show_goal_replay(event: Dictionary) -> void:
	if is_instance_valid(goal_replay): return
	goal_replay = load("res://ui/goal_replay.gd").new()
	goal_replay.match_view = self
	goal_replay.clip = replay_history.goal_clip(sim,event)
	add_child(goal_replay)
	goal_replay.finished.connect(func():
		goal_replay = null
		_sync_state())

func _process(delta: float) -> void:
	if not is_instance_valid(hud) or paused: return
	# A few milliseconds of render-only settling, with no anticipation or overshoot.
	for i in 22: player_positions[i] = player_positions[i].lerp(sim.players[i].position,1-exp(-delta*65))
	ball = ball.lerp(sim.ball,1-exp(-delta*100))
	trail_clock += delta
	if _has_ball_trail() and not hud.reduced_motion:
		if ball_trail.is_empty() or ball_trail.back().distance_to(ball) > 0.02:
			ball_trail.append(ball)
			trail_times.append(trail_clock)
		var carrying: bool = sim.ball_state == Match.BallState.CONTROLLED
		while not ball_trail.is_empty() and (trail_clock-trail_times[0] > (0.1 if carrying else 0.22) or ball.distance_to(ball_trail[0]) > (1.8 if carrying else 8.0) or ball_trail.size() > 24):
			ball_trail.pop_front()
			trail_times.pop_front()
	else:
		ball_trail.clear()
		trail_times.clear()
	queue_redraw()

func _formation_opacity() -> float:
	if hud.reduced_motion: return 1.0
	if not sim.finished and sim.ball_state == Match.BallState.DEAD and sim.restart_kind == "kickoff":
		return clampf(sim.dead_ticks/12.0,0,1)
	var progress := clampf((sim.ticks-formation_tick)/10.0,0,1)
	return progress*progress*(3-2*progress)

func _actor_opacity() -> float:
	var opacity := _formation_opacity()
	return opacity

func _required_report() -> String:
	if sim.period == Match.Period.HALF_TIME: return "halftime"
	if sim.finished and not result_dismissed: return "result"
	return ""

func _on_command(action: String) -> void:
	if campaign_mode and action in ["save_exit","campaign_settings","continue_result"]:
		paused = true
		campaign_action.emit(action)
		return
	if campaign_mode and action in ["restart","new","prepare","confirm_restart","confirm_new","confirm_prepare","quit"]: return
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
	if is_instance_valid(goal_replay): goal_replay.queue_free()
	goal_replay = null
	sim = Match.new(sim.match_seed + (1 if new_seed else 0),Match.REGULATION_SECONDS,sim.plans[0],sim.plans[1],sim.knockout)
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
	if is_instance_valid(goal_replay):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_SPACE,KEY_ENTER]):
			goal_replay.skip_replay()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(preparation): return
	if event is InputEventMouseButton and event.pressed:
		hud.keyboard_focus = false
		hud.apply_focus_style()
		return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode in [KEY_TAB,KEY_ESCAPE,KEY_ENTER]:
		hud.keyboard_focus = true
		hud.apply_focus_style()
	if event.keycode == KEY_ESCAPE or event.keycode == key_bindings.menu:
		if overlay_mode.is_empty(): _open_overlay("menu")
		elif not hud.overlay.dismiss_help(): _dismiss_overlay()
	elif not overlay_mode.is_empty(): return
	elif event.keycode == key_bindings.pause:
		if not sim.finished: paused = not paused
	elif event.keycode in [key_bindings.speed1,key_bindings.speed2]:
		speed = 1 if event.keycode == key_bindings.speed1 else 2
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
			if not sim.players[i].active: continue
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
	if is_instance_valid(world): world.queue_redraw()
	if is_instance_valid(type_layer): type_layer.queue_redraw()

func _paint_pitch() -> void:
	world.draw_rect(Rect2(Vector2.ZERO, size), Color("101827"))
	if pitch.size.x <= 0: return
	world.draw_rect(pitch.grow(9), Color("263A2D"))
	world.draw_rect(pitch.grow(8), Color("B8C4AA45"), false, 1)
	world.draw_texture_rect(turf, pitch, true)
	for stripe in 10:
		if stripe % 2 == 0:
			world.draw_rect(Rect2(pitch.position + Vector2(pitch.size.x * stripe / 10, 0), Vector2(pitch.size.x / 10, pitch.size.y)), Color("3F8050",0.32))
	# Subtle floodlight falloff lives below every white field marking and every body.
	for edge in 12:
		var alpha := (1-edge/12.0)*0.018
		world.draw_rect(Rect2(pitch.position+Vector2(edge,edge),pitch.size-Vector2(edge*2,edge*2)),Color(0.01,0.035,0.075,alpha),false,1)
	var line := Color("DBE8DD")
	world.draw_rect(pitch, line, false, 1.4)
	world.draw_line(_field(Vector2(52.5, 0)), _field(Vector2(52.5, 68)), line, 1.4)
	world.draw_arc(_field(Vector2(52.5, 34)), 9.15 * _scale(), 0, TAU, 64, line, 1.4, true)
	world.draw_circle(_field(Vector2(52.5, 34)), 2.2, line)
	for end in 2:
		var x := 0.0 if end == 0 else 88.5
		world.draw_rect(Rect2(_field(Vector2(x, 13.84)), Vector2(16.5, 40.32) * _scale()), line, false, 1.4)
		x = 0.0 if end == 0 else 99.5
		world.draw_rect(Rect2(_field(Vector2(x, 24.84)), Vector2(5.5, 18.32) * _scale()), line, false, 1.4)
		var spot := Vector2(11 if end == 0 else 94, 34)
		world.draw_circle(_field(spot), 2, line)
		world.draw_arc(_field(spot), 9.15 * _scale(), -0.93 if end == 0 else PI - 0.93, 0.93 if end == 0 else PI + 0.93, 32, line, 1.4, true)
		_draw_goal(end)
	for point in [Vector2(0,0),Vector2(105,0),Vector2(105,68),Vector2(0,68)]:
		var start := 0.0 if point == Vector2.ZERO else (PI / 2 if point.y == 0 else (PI if point.x > 0 else PI * 1.5))
		world.draw_arc(_field(point), _scale(), start, start + PI / 2, 12, line, 1.1, true)
	if not hud.reduced_motion and sim.ticks-impact_tick >= 0 and sim.ticks-impact_tick < 10:
		var phase := (sim.ticks-impact_tick)/10.0
		world.draw_arc(_field(impact_position),7+phase*9,0,TAU,24,Color(CREAM,0.3*(1-phase)),1.2,true)
	if _has_ball_trail() and not hud.reduced_motion:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for index in ball_trail.size():
			var weight := float(index)/maxi(1,ball_trail.size()-1)
			points.append(_field(ball_trail[index]))
			colors.append(Color(_ball_ink(),weight*0.62))
		if points.size() > 1: world.draw_polyline_colors(points,colors,2.8,true)
	for i in 22:
		if i != sim.owner and i != selected: _draw_player(i)
	if sim.owner >= 0 and sim.owner != selected: _draw_player(sim.owner)
	if selected >= 0: _draw_player(selected)
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
		var age: int = sim.ticks-state.get("visual_resolved",state.get("visual_tick",sim.ticks))
		if state.state != "active" and age > 36: continue
		var position := _field(player_positions[p.id])
		var tint := Color("7bd2cf") if p.role == "GK" or state.trait in ["accelerator","recovery_sprint","touchline_burst"] else AMBER
		var alpha := 0.85 if state.state == "active" else clampf(1-age/36.0,0,1)*0.6
		if hud.effects_enabled and not hud.reduced_motion:
			var pulse := 1.0+sin((sim.active_ticks-state.started)*0.12)*0.08
			type_layer.draw_arc(position,20*pulse,0,TAU,32,Color(tint,alpha*0.5),2,true)
			if state.state == "success": type_layer.draw_arc(position,23,0,TAU,32,Color(tint,alpha),1,true)
		# Quiet icons retain identity off-ball; only three recent labels compete for attention.
		var icon := position+Vector2(0,-21)
		var glyph: Texture2D = preload("res://ui/matchday_icons.gd").signature_icon(state.trait)
		type_layer.draw_texture_rect(glyph,Rect2(icon-Vector2(8,8),Vector2(16,16)),false,Color(CREAM,alpha))
		if labels < 3 and sim.ticks-state.get("visual_tick",sim.ticks) < 72:
			var title: String = state.trait.replace("_"," ").to_upper()
			if state.state in ["failed","partial"]: title += "  "+str(state.state).to_upper()
			var width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
			var origin := Vector2(clampf(position.x-width/2,pitch.position.x+2,pitch.end.x-width-2),maxf(pitch.position.y+12,position.y-32))
			type_layer.draw_string_outline(font,origin,title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("0c2117"))
			type_layer.draw_string(font,origin,title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(CREAM,alpha))
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
	world.draw_set_transform(ground + Vector2(0, 4), 0, Vector2(1.35, 0.5))
	world.draw_circle(Vector2.ZERO, 4.7, Color(0.01,0.03,0.02,0.75*opacity))
	world.draw_set_transform(Vector2.ZERO)
	world.draw_circle(center, 6.6, Color(Color("102118"),opacity))
	world.draw_circle(center, 5.7, Color(Color("f9f7e9"),opacity))
	if hud.effects_enabled and _ball_ink() != CREAM:
		world.draw_arc(center,6.5,0,TAU,20,Color(_ball_ink(),0.85*opacity),1.3,true)
	var patch := PackedVector2Array()
	for i in 5: patch.append(center + Vector2.from_angle(ball_roll + i * TAU / 5) * 2.0)
	world.draw_colored_polygon(patch, Color(Color("203c2a"),opacity))
	for i in 3:
		var angle := ball_roll + i * TAU / 3
		world.draw_colored_polygon(PackedVector2Array([center + Vector2.from_angle(angle) * 3.2, center + Vector2.from_angle(angle - 0.3) * 4.8, center + Vector2.from_angle(angle + 0.3) * 4.8]), Color(Color("203c2a"),opacity))
	world.draw_circle(center + Vector2(-1.6, -2.0), 0.9, Color(1,1,1,0.8*opacity))

func _has_ball_trail() -> bool:
	return sim.ball_state == Match.BallState.FLIGHT or (sim.ball_state == Match.BallState.LOOSE and sim.ball_velocity.length() > 2) or (sim.ball_state == Match.BallState.CONTROLLED and sim.owner >= 0 and sim.players[sim.owner].velocity.length() > 1.5)

func _ball_ink() -> Color:
	if not hud.effects_enabled: return CREAM
	if sim.ball_state == Match.BallState.FLIGHT and sim.flight_trait_actor >= 0 and sim.players[sim.flight_trait_actor].trait_state.get("state","") == "active": return AMBER
	if sim.ball_state == Match.BallState.LOOSE and sim.last_touch >= 0 and sim.players[sim.last_touch].trait_state.get("trait","") == "deflector" and sim.players[sim.last_touch].trait_state.get("state","") == "active": return Color("7bd2cf")
	return CREAM

func _draw_goal(end: int) -> void:
	var depth := minf(3.2 * _scale(),pitch.position.x-4.0)
	var mouth_x := pitch.position.x if end == 0 else pitch.end.x
	var net_x := mouth_x - depth if end == 0 else mouth_x
	var top := _field(Vector2(0, 30.34)).y
	var bottom := _field(Vector2(0, 37.66)).y
	var net := Rect2(net_x, top, depth, bottom - top)
	var recoil := 0.0
	var age: int = sim.ticks - hud.goal_cue_tick
	if hud.effects_enabled and not hud.reduced_motion and hud.goal_cue_actor >= 0 and age >= 0 and age < 90:
		var scoring_team: int = hud.goal_event.get("team",sim.players[hud.goal_cue_actor].team)
		if (end == 1) == (sim.direction(scoring_team) > 0):
			recoil = sin(age * 0.3) * exp(-age / 25.0) * 2.0
	var sprite: Texture2D=preload("res://assets/ui/arcade/goal.png") if end == 0 else preload("res://assets/ui/arcade/goal_flipped.png")
	# The sprite's bright mouth remains aligned to the real goal line.
	world.draw_texture_rect(sprite,Rect2(net.position,net.size+Vector2(recoil,0)),false)

func _draw_player(index: int) -> void:
	if not sim.players[index].active: return
	var is_keeper: bool = sim.players[index].role == "GK"
	var point := _field(player_positions[index])
	var opacity := _actor_opacity()
	var color := Color(team_kits[0] if index < 11 else team_kits[1],opacity)
	if selected == index or sim.owner == index:
		var transfer := 0.0 if hud.reduced_motion else 3*clampf(1-(sim.ticks-owner_tick)/10.0,0,1)
		world.draw_arc(point, 17.0 if selected == index else 16.0+transfer, 0, TAU, 36, Color(AMBER,opacity), 2.0 if selected == index else 1.3, true)
	if hud.effects_enabled and index == hud.goal_cue_actor and sim.ticks - hud.goal_cue_tick >= 0 and sim.ticks - hud.goal_cue_tick < 150:
		world.draw_arc(point, 18 + (0 if hud.reduced_motion else sin((sim.ticks - hud.goal_cue_tick) * 0.15)), 0, TAU, 36, Color(AMBER,opacity), 1.5, true)
	world.draw_circle(point + Vector2(1, 2.5), 13.8, Color(0.02,0.05,0.025,0.85*opacity))
	world.draw_circle(point, 13.2, Color(Color("102315"),opacity))
	world.draw_circle(point, 12.3, Color(CREAM,opacity))
	world.draw_circle(point, 11.1, color)
	if is_keeper:
		world.draw_circle(point, 10.3, Color(Color("247f53"),opacity))
	if index >= 11:
		world.draw_arc(point, 9, PI * 0.10, PI * 0.90, 14, Color(Color("9d4937"),opacity), 1.2, true)
func _draw_name(index: int) -> void:
	if not sim.players[index].active: return
	var point := _field(player_positions[index])
	var pixels: int = roundi(18 * hud.ui_scale)
	var metrics: Dictionary = name_metrics.get(index,{})
	if metrics.get("source","") != sim.players[index].name or metrics.get("pixels",0) != pixels:
		var surname: String = preload("res://ui/player_card.gd").split_name(sim.players[index].name)[1]
		while preload("res://ui/typography.gd").face("Bold").get_string_size(surname,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x > 120*hud.ui_scale and surname.length() > 2:
			surname = surname.left(surname.length()-2)+"…"
		metrics = {"source":sim.players[index].name,"pixels":pixels,"text":surname,"width":preload("res://ui/typography.gd").face("Bold").get_string_size(surname,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x}
		name_metrics[index] = metrics
	var player_name: String = metrics.text
	var width: float = metrics.width
	# A fixed below-token anchor prevents the old above/below flipping in duels.
	var pos := point + Vector2(-width / 2, 29)
	pos.x = clampf(pos.x, pitch.position.x+2, maxf(pitch.position.x+2,pitch.end.x-width-2))
	pos.y = minf(pos.y, size.y - 4)
	var rect := Rect2(pos + Vector2(-2, -15), Vector2(width + 4, 19))
	var blocked := false
	for existing in name_rects: blocked = blocked or existing.intersects(rect)
	var important := index == sim.owner or index == selected
	if blocked and not important: label_dim_until[index] = sim.ticks + 30
	var target := 0.2 if sim.ticks < label_dim_until[index] and not important else 1.0
	label_alpha[index] = 1.0 if important else lerpf(label_alpha[index], target, minf(get_process_delta_time() * 8, 1))
	if not blocked or important: name_rects.append(rect)
	var opacity := label_alpha[index]*_actor_opacity()
	type_layer.draw_rect(Rect2(pos+Vector2(-3,-13),Vector2(width+6,18)),Color("101827",opacity*0.84))
	type_layer.draw_string(preload("res://ui/typography.gd").face("Bold"),pos,player_name,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,Color(CREAM,opacity))

func _paint_names() -> void:
	_draw_traits()
	for index in 22:
		if sim.players[index].active: _draw_number(index)
	name_rects.clear()
	var priorities: Array[int] = []
	for index in [sim.owner, selected]:
		if index >= 0 and not priorities.has(index): priorities.append(index)
	for i in 22:
		if not priorities.has(i): priorities.append(i)
	for index in priorities: _draw_name(index)

func _draw_number(index: int) -> void:
	var point := _field(player_positions[index])
	var opacity := _actor_opacity()
	var is_keeper: bool = sim.players[index].role == "GK"
	var number := str(index % 11 + 1)
	var number_pos := point + Vector2(-font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2, 5)
	var light_number: bool = is_keeper or team_kits[0 if index < 11 else 1].get_luminance() < 0.45
	if light_number:
		type_layer.draw_string_outline(font,number_pos,number,HORIZONTAL_ALIGNMENT_LEFT,-1,14,1,Color(Color("27432d"),opacity))
	type_layer.draw_string(font, number_pos, number, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CREAM if light_number else Color("102315"),opacity))

class PixelNames:
	extends Node2D
	var host: Control
	func _draw() -> void: host._paint_names()

class PixelWorld:
	extends Node2D
	var host: Control
	func _draw() -> void: host._paint_pitch()

func _make_pixel_layer() -> void:
	world_viewport = SubViewport.new()
	world_viewport.disable_3d = true
	world_viewport.transparent_bg = false
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(world_viewport)
	world = PixelWorld.new()
	world.host = self
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_viewport.add_child(world)
	world_image = TextureRect.new()
	world_image.texture = world_viewport.get_texture()
	world_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_image)
	type_layer = PixelNames.new()
	type_layer.host = self
	add_child(type_layer)
	_layout_pixel_layer()

func _layout_pixel_layer() -> void:
	if not is_instance_valid(world_viewport): return
	var step := maxi(1,roundi(size.y/360.0))
	world_viewport.size = Vector2i(size/step)
	world_viewport.canvas_transform = Transform2D(0,Vector2.ONE/step,0,Vector2.ZERO)
	world_image.size = size
