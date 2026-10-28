extends Control
## Native presentation only. All actions are requests to the match controller.
signal command(action: String)

const MatchTheme = preload("res://ui/game_theme.tres")
const MatchOverlay = preload("res://ui/match_overlay.gd")
const GoalCelebration = preload("res://ui/goal_celebration.gd")
var CREAM: Color = MatchTheme.get_color("ivory", "Palette")
var MUTED: Color = MatchTheme.get_color("muted", "Palette")
var CORAL: Color = MatchTheme.get_color("coral", "Palette")
var AMBER: Color = MatchTheme.get_color("amber", "Palette")
var buttons: Dictionary = {}
var labels: Dictionary = {}
var event_list: VBoxContainer
var inspection: Label
var overlay
var panel_content: Control:
	get: return overlay.content
var divider := 1008.0
var pitch := Rect2()
var event_count := -1
var kit_centers: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var inspected := ""
var model: RefCounted
var status_color := Color("58bd7a")
var goal_cue_tick := -1000
var goal_cue_actor := -1
var goal_event: Dictionary = {}
var effects_enabled := true
var reduced_motion := false
var ui_scale := 1.0
var celebration
var keyboard_focus := false
var no_focus := StyleBoxEmpty.new()
var campaign_mode := false
var team_names: Array = ["Meadow XI","Harbor XI"]
var team_kits: Array = [Color("efe9d9"),Color("ed7864")]

class EventRow:
	extends HBoxContainer
	func _draw() -> void:
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(0.4, 0.48, 0.41, 0.5), 1)

class EventIcon:
	extends Control
	var kind := ""
	var team := -1
	var kit := Color.TRANSPARENT
	func _draw() -> void:
		var color := Color("efe9d9") if team == 0 else Color("ed7864")
		if kit.a > 0: color = kit
		if team < 0: color = Color("a0afa4")
		var center := Vector2(17, 17)
		if kind in ["goal","shootout_goal"]:
			draw_arc(center, 10, 0, TAU, 24, color, 1.8, true)
			draw_circle(center, 3.5, color)
			for i in 5:
				var point := center + Vector2.from_angle(i * TAU / 5) * 6
				draw_line(point, center + Vector2.from_angle(i * TAU / 5) * 10, color, 1.5, true)
		elif kind in ["save", "smother", "parry","shootout_save"]:
			draw_set_transform(Vector2(-14, 0))
			draw_polyline(PackedVector2Array([Vector2(23, 16), Vector2(24, 27), Vector2(38, 27), Vector2(42, 13)]), Color("f1eedb"), 1.8, true)
			for i in 4: draw_line(Vector2(26 + i * 4, 19), Vector2(25 + i * 4, 5 + i % 2 * 3), Color("f1eedb"), 1.8, true)
		elif kind == "tackle":
			draw_polyline(PackedVector2Array([Vector2(3,24),Vector2(3,17),Vector2(11,18),Vector2(17,11),Vector2(22,15),Vector2(15,25),Vector2(3,24)]),color,1.8,true)
			draw_circle(Vector2(26,9),3,color)
		elif kind in ["shot","miss","shootout_shot","shootout_miss"]:
			draw_polyline(PackedVector2Array([Vector2(17,26),Vector2(17,5),Vector2(31,5),Vector2(31,26)]),color,1.5,true)
			var target := Vector2(29,1) if kind in ["miss","shootout_miss"] else Vector2(25,12)
			draw_line(Vector2(3,26),target,color,1.8,true)
			draw_polyline(PackedVector2Array([target-Vector2(7,0),target,target+Vector2(0,7)]),color,1.8,true)
			draw_circle(Vector2(3,26),2.5,color)
		elif kind == "pass":
			draw_circle(Vector2(4,23),3,color)
			draw_line(Vector2(10,21),Vector2(29,10),color,1.8,true)
			draw_polyline(PackedVector2Array([Vector2(21,9),Vector2(29,10),Vector2(26,18)]),color,1.8,true)
		elif kind == "interception":
			draw_line(Vector2(2,22),Vector2(18,22),color,1.8,true)
			draw_line(Vector2(18,22),Vector2(18,5),color,1.8,true)
			draw_polyline(PackedVector2Array([Vector2(12,11),Vector2(18,5),Vector2(24,11)]),color,1.8,true)
			draw_line(Vector2(27,18),Vector2(27,29),color,2,true)
		elif kind == "block":
			draw_polyline(PackedVector2Array([Vector2(6,7),Vector2(17,3),Vector2(28,7),Vector2(26,20),Vector2(17,29),Vector2(8,20),Vector2(6,7)]),color,1.8,true)
			draw_line(Vector2(11,11),Vector2(23,23),color,1.8,true)
		elif kind in ["kickoff", "kickoff_setup"]:
			draw_arc(center,10,0,TAU,24,color,1.5,true)
			draw_line(Vector2(17,3),Vector2(17,31),color,1.5,true)
			draw_circle(center,2.5,color)
		elif kind in ["yellow_card","red_card"]:
			draw_rect(Rect2(10,5,14,23),Color("f0cd50") if kind == "yellow_card" else Color("ed7864"))
		elif kind == "foul":
			draw_arc(Vector2(13,21),7,0,TAU,20,color,1.6,true)
			draw_polyline(PackedVector2Array([Vector2(16,15),Vector2(28,8),Vector2(31,14),Vector2(20,22)]),color,1.6,true)
		elif kind in ["offside","corner_awarded","throw_in_awarded"]:
			draw_line(Vector2(10,4),Vector2(10,30),color,1.7,true)
			draw_polyline(PackedVector2Array([Vector2(10,5),Vector2(27,11),Vector2(10,17)]),color,1.7,true)
		elif kind == "substitution":
			for offset in [0,12]:
				var x := 27 if offset == 0 else 7
				var sign_x := 1 if offset == 0 else -1
				var ink := Color("58bd7a") if offset == 0 else Color("ed7864")
				draw_line(Vector2(7,10+offset),Vector2(27,10+offset),ink,1.7,true)
				draw_polyline(PackedVector2Array([Vector2(x-sign_x*5,5+offset),Vector2(x,10+offset),Vector2(x-sign_x*5,15+offset)]),ink,1.7,true)
		elif kind in ["halftime","full_time","extra_time","extra_half","shootout_start"]:
			draw_arc(center,10,0,TAU,24,color,1.5,true)
			draw_polyline(PackedVector2Array([Vector2(17,8),Vector2(17,17),Vector2(24,17)]),color,1.8,true)
		else:
			draw_line(center - Vector2(9, -6), center + Vector2(8, -6), Color("f1eedb"), 1.8, true)
			draw_polyline(PackedVector2Array([center + Vector2(1, -8), center + Vector2(8, -6), center + Vector2(6, 1)]), Color("f1eedb"), 1.8, true)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_label("home", team_names[0].to_upper(), 26, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	_label("away", team_names[1].to_upper(), 26, CREAM)
	labels.home.theme_type_variation = "Team"
	labels.away.theme_type_variation = "Team"
	_label("score", "0 – 0", 46, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	labels.score.theme_type_variation = "Score"
	_label("clock", "0′", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_label("live", "LIVE", 16, CREAM)
	labels.live.theme_type_variation = "Section"
	labels.live.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_button("pause", "Ⅱ", "Pause / resume (Space)")
	_button("speed1", "1×", "Normal viewing speed (1)")
	_button("speed2", "2×", "Double viewing speed (2)")
	_button("menu", "☰  Menu", "Match menu (Escape)")
	_button("log", "All events   ›", "Full event log; pauses the match")
	var group := ButtonGroup.new()
	for id in ["speed1", "speed2"]:
		buttons[id].toggle_mode = true
		buttons[id].button_group = group
	inspection = Label.new()
	inspection.add_theme_font_size_override("font_size", 14)
	inspection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection.mouse_filter = MOUSE_FILTER_PASS
	add_child(inspection)
	event_list = VBoxContainer.new()
	event_list.add_theme_constant_override("separation", 12)
	event_list.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(event_list)
	celebration = GoalCelebration.new()
	celebration.team_names = team_names.duplicate()
	celebration.team_kits = team_kits.duplicate()
	add_child(celebration)
	labels.goal_title = celebration.title
	labels.goal_detail = celebration.detail
	overlay = MatchOverlay.new()
	add_child(overlay)
	overlay.command.connect(func(action): command.emit(action))

func _box(color: Color, border: Color, padding: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _label(id: String, text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := Label.new()
	label.text = text
	label.set_meta("base_font_size", font_size)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(label)
	labels[id] = label

func _button(id: String, text: String, hint: String) -> Button:
	var button := Button.new()
	button.name = id.capitalize().replace(" ", "")
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(40, 42)
	if id == "pause":
		button.text = ""
		var state_icon := MatchOverlay.Icon.new()
		state_icon.name = "StateIcon"
		state_icon.kind = "pause"
		state_icon.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(state_icon)
		button.resized.connect(func(): state_icon.position = (button.size-Vector2(24,24))/2)
	if id == "menu":
		button.text = "Menu"
		var menu_icon := MatchOverlay.Icon.new()
		menu_icon.kind = "menu"
		menu_icon.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(menu_icon)
		button.resized.connect(func(): menu_icon.position = Vector2(5,(button.size.y-24)/2))
		for state in ["normal","hover"]:
			var menu_style: StyleBox = MatchTheme.get_stylebox(state,"Button").duplicate()
			menu_style.content_margin_left = 34
			menu_style.content_margin_right = 4
			menu_style.border_width_bottom = 0
			button.add_theme_stylebox_override(state,menu_style)
	if id in ["pause","speed1","speed2"]:
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color(0,0,0,0)
		outline.border_color = Color(CREAM,0.65)
		outline.set_border_width_all(1)
		outline.set_corner_radius_all(4)
		outline.content_margin_left = 6
		outline.content_margin_right = 6
		button.add_theme_stylebox_override("normal",outline)
	if id in ["speed1", "speed2"]:
		var pressed: StyleBox = MatchTheme.get_stylebox("pressed", "Button").duplicate()
		pressed.content_margin_left = 6
		pressed.content_margin_right = 6
		button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(func(): command.emit(id))
	add_child(button)
	buttons[id] = button
	return button

func arrange(field_rect: Rect2, divider_x: float) -> void:
	pitch = field_rect
	divider = divider_x
	var center := pitch.get_center().x
	var face: Font = labels.home.get_theme_font("font")
	var score_face: Font = labels.score.get_theme_font("font")
	var score_width := maxf(128,score_face.get_string_size(labels.score.text,HORIZONTAL_ALIGNMENT_LEFT,-1,labels.score.get_theme_font_size("font_size")).x+12)
	var maximum_name := minf(220,(pitch.size.x-score_width-140)/2)
	var pixels := roundi(26*ui_scale)
	while pixels > 16 and maxf(face.get_string_size(labels.home.text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x,face.get_string_size(labels.away.text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x) > maximum_name: pixels -= 1
	for team in 2:
		var label: Label = labels.home if team == 0 else labels.away
		label.add_theme_font_size_override("font_size",pixels)
		var width := minf(maximum_name,ceilf(face.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x)+2)
		_put(label,Rect2(center-score_width/2-20-width if team == 0 else center+score_width/2+20,18,width,38))
	_put(labels.score, Rect2(center - score_width/2, 2, score_width, 57))
	kit_centers[0] = Vector2(labels.home.position.x-31,37)
	kit_centers[1] = Vector2(labels.away.position.x+labels.away.size.x+31,37)
	_put(labels.clock, Rect2(center - 110, 57 + (ui_scale - 1) * 28, 220, 27))
	_put(labels.live, Rect2(divider + 38, 94, 190, 28))
	_put(celebration, pitch)
	var x := divider + 12
	_put(buttons.pause, Rect2(x, 20, 42, 42))
	_put(buttons.speed1, Rect2(x + 54, 20, 44, 42))
	_put(buttons.speed2, Rect2(x + 98, 20, 44, 42))
	_put(buttons.menu, Rect2(x + 158, 20, 88, 42))
	_put(buttons.log, Rect2(divider + 14, size.y - 62, size.x - divider - 30, 42))
	inspection.position = Vector2(divider + 20, 134)
	inspection.size = Vector2(size.x - divider - 38, 130*ui_scale)
	event_list.position = Vector2(divider + 18, 140 + (140*ui_scale if not inspected.is_empty() else 0))
	event_list.size = Vector2(size.x - divider - 32, 0)
	queue_redraw()

func _put(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _draw() -> void:
	if overlay.is_active(): return
	var center := pitch.get_center().x
	_kit(kit_centers[0], team_kits[0])
	_kit(kit_centers[1], team_kits[1])
	draw_line(Vector2(center-22,56),Vector2(center+22,56),Color(AMBER,0.65),1)
	draw_line(Vector2(divider, 84), Vector2(divider, size.y - 20), Color("40513d"), 1)
	draw_line(Vector2(divider + 18, 130), Vector2(size.x - 20, 130), Color("344a36"), 1)
	draw_line(Vector2(divider + 18, size.y - 73), Vector2(size.x - 20, size.y - 73), Color("344a36"), 1)
	draw_circle(Vector2(divider + 24, 108), 5, status_color)

func _kit(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([Vector2(-7,-12),Vector2(-17,-5),Vector2(-13,3),Vector2(-8,0),Vector2(-8,15),Vector2(8,15),Vector2(8,0),Vector2(13,3),Vector2(17,-5),Vector2(7,-12),Vector2(3,-8),Vector2(-3,-8)])
	for i in points.size(): points[i] += center
	draw_colored_polygon(points, color)
	if color.get_luminance() < 0.45:
		points.append(points[0])
		draw_polyline(points,Color(CREAM,0.65),0.9,true)

func refresh(sim: RefCounted, paused: bool, speed: int, inspection_text: String) -> void:
	model = sim
	labels.score.text = "%d – %d" % sim.scores
	labels.clock.text = "%d′%s" % [sim.display_minute(), " · FT" if sim.finished else (" · HT" if sim.period == 1 else "")]
	if event_count != sim.events.size():
		goal_cue_tick = -1000
		goal_cue_actor = -1
		goal_event = {}
		for event in sim.events:
			if event.kind == "goal":
				goal_cue_tick = event.tick
				goal_cue_actor = event.actor
				goal_event = event
	celebration.sync(sim,goal_event,reduced_motion,effects_enabled,overlay.is_active())
	if sim.finished:
		labels.clock.text = "FULL TIME · %d′" % sim.display_minute()
	elif sim.period == 1:
		labels.clock.text = "HALF TIME · %d–%d" % sim.scores
	if not sim.shootout.is_empty(): labels.clock.text = "PEN %d–%d · %d′" % [sim.shootout.goals[0],sim.shootout.goals[1],sim.display_minute()]
	elif sim.period in [sim.Period.EXTRA_FIRST,sim.Period.EXTRA_SECOND]: labels.clock.text = "ET · %d′" % sim.display_minute()
	labels.live.text = "FULL TIME" if sim.finished else ("PAUSED" if paused else "LIVE")
	status_color = MUTED if sim.finished else (AMBER if paused else Color("58bd7a"))
	queue_redraw()
	buttons.pause.get_node("StateIcon").kind = "resume" if paused else "pause"
	buttons.pause.get_node("StateIcon").queue_redraw()
	buttons.pause.tooltip_text = "Resume match (Space)" if paused else "Pause match (Space)"
	buttons.speed1.set_pressed_no_signal(speed == 1)
	buttons.speed2.set_pressed_no_signal(speed == 2)
	if event_count != sim.events.size() or inspection_text != inspected:
		inspected = inspection_text
		inspection.text = inspection_text
		inspection.visible = not inspected.is_empty()
		arrange(pitch, divider)
		_refresh_rows()
		event_count = sim.events.size()
	buttons.pause.disabled = sim.finished or overlay.is_active()

func event_copy(event: Dictionary) -> Array[String]:
	var actor: String = event.get("actor_name",model.players[event.actor].name if event.actor >= 0 else "")
	match event.kind:
		"goal": return [actor, ("Own goal · " if event.get("own_goal",false) else "Goal · ")+"%d–%d" % event.score]
		"save": return [actor, "Save"]
		"smother": return [actor, "Claims the ball"]
		"tackle": return [actor, "Tackle"]
		"interception": return [actor, "Interception"]
		"block": return [actor, "Shot blocked"]
		"miss": return [actor, "Shot wide"]
		"shot": return [actor, "Shot"]
		"kickoff": return [team_names[event.team], "Kickoff"]
		"kickoff_setup": return [team_names[event.team], "Preparing kickoff"]
		"halftime": return ["Half time", "Teams change ends"]
		"full_time": return ["Full time", "%d–%d · Exhibition draw" % event.score if event.score[0] == event.score[1] else "%d–%d · Final score" % event.score]
		"pass": return [actor, "Pass to %s" % event.get("receiver_name",model.players[event.receiver].name)]
		"received": return [actor, "Pass received"]
		"hold": return [actor, "Ball held"]
		"parry": return [actor, "Live rebound"]
		"challenge": return [actor, "Challenge"]
		"goal_kick": return [actor, "Goal kick"]
		"restart": return [actor, "Restart"]
		"restart_setup": return [actor,event.restart.replace("_"," ").capitalize()+" setup"]
		"throw_in", "corner", "free_kick": return [actor, event.kind.replace("_"," ").capitalize()]
		"throw_in_awarded", "corner_awarded", "free_kick_awarded", "goal_kick_awarded": return [actor, event.kind.replace("_"," ").capitalize()]
		"foul": return [actor, "Foul on %s" % event.get("victim_name",model.players[event.victim].name)]
		"poor_touch": return [actor, "Loose first touch"]
		"substitution": return [actor, "On for %s" % event.out_name]
		"trait_activation": return [actor,event.trait.replace("_"," ").capitalize()+" · Activated"]
		"trait_execution": return [actor,event.trait.replace("_"," ").capitalize()+" · Executed"]
		"trait_result": return [actor,event.trait.replace("_"," ").capitalize()+" · "+event.state.capitalize()+": "+event.reason]
		"offside": return [actor,"Offside"]
		"yellow_card": return [actor,"Yellow card"]
		"red_card": return [actor,"Second yellow · sent off" if event.second_yellow else "Red card"]
		"penalty_awarded": return [actor,"Penalty awarded"]
		"penalty": return [actor,"Penalty"]
		"indirect_free_kick", "indirect_free_kick_awarded": return [actor,"Indirect free kick"]
		"emergency_keeper": return [actor,"Emergency goalkeeper"]
		"reshuffle": return [actor,"Covers "+event.assigned_role]
		"forfeit": return [actor,"Match forfeited · fewer than seven players"]
		"extra_time", "extra_half": return ["Extra time","First half" if event.kind == "extra_time" else "Second half"]
		"shootout_start": return ["Penalty shootout","Scores are separate from match goals"]
		"shootout_setup": return [actor,"Preparing penalty"]
		"shootout_shot": return [actor,"Penalty attempt"]
		"shootout_save": return [actor,"Penalty saved"]
		"shootout_goal", "shootout_miss": return [actor,("Penalty scored · " if event.kind == "shootout_goal" else "Penalty missed · ")+"%d–%d" % event.penalties]
		"header", "aerial_win": return [actor,"Aerial contact"]
		"recovery": return [actor, "Loose ball recovered"]
		_: return [actor, "Ball out"]

func _refresh_rows() -> void:
	for child in event_list.get_children():
		event_list.remove_child(child)
		child.queue_free()
	var count := 0
	var pass_shown := false
	var limit := maxi(1, int((size.y - 208 - (140 * ui_scale if not inspected.is_empty() else 0)) / (72 * ui_scale + 12)))
	for i in range(model.events.size() - 1, -1, -1):
		var event: Dictionary = model.events[i]
		if event.kind not in ["goal", "save", "parry", "smother", "tackle", "interception", "block", "miss", "shot", "pass", "kickoff", "halftime", "full_time","offside","foul","yellow_card","red_card","substitution","penalty_awarded","corner_awarded","throw_in_awarded","goal_kick_awarded","forfeit","extra_time","extra_half","shootout_start","shootout_shot","shootout_goal","shootout_miss","shootout_save"]: continue
		if event.kind == "pass":
			if pass_shown: continue
			pass_shown = true
		var row := EventRow.new()
		row.custom_minimum_size.y = 72 * ui_scale
		row.add_theme_constant_override("separation", 7)
		event_list.add_child(row)
		var minute := Label.new()
		minute.text = "%d′" % event.minute
		minute.custom_minimum_size.x = 32
		minute.add_theme_font_size_override("font_size", 16)
		minute.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		minute.size_flags_vertical = SIZE_SHRINK_BEGIN
		row.add_child(minute)
		var icon := EventIcon.new()
		icon.kind = event.kind
		icon.team = event.team
		if event.team >= 0: icon.kit = team_kits[event.team]
		icon.custom_minimum_size = Vector2(34, 40)
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(text)
		var copy := event_copy(event)
		for line in 2:
			var label := Label.new()
			label.text = copy[line]
			label.tooltip_text = label.text
			label.add_theme_font_size_override("font_size", roundi((18 if line == 0 else 16) * ui_scale))
			if line == 0: label.theme_type_variation = "BodyStrong"
			label.add_theme_color_override("font_color", CREAM if line == 0 else MUTED)
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.custom_minimum_size.x = 115
			text.add_child(label)
		count += 1
		if count >= limit: break

func show_panel(mode: String, sim: RefCounted) -> void:
	model = sim
	var previous_action := ""
	var focused := get_viewport().gui_get_focus_owner()
	if overlay.mode == mode and is_instance_valid(focused): previous_action = str(focused.get_meta("action", ""))
	for child in get_children():
		if child != overlay: child.hide()
	for button in buttons.values(): button.disabled = true
	overlay.present(mode, sim, self)
	apply_focus_style()
	if not previous_action.is_empty(): focus_action(previous_action)
	queue_redraw()

func focus_action(action: String) -> void:
	for button in overlay.content.find_children("*", "BaseButton", true, false):
		if button.get_meta("action", "") == action:
			button.grab_focus()
			return

func close_panel(animate: bool = true) -> void:
	overlay.dismiss(animate)
	for child in get_children():
		if child != overlay: child.show()
	for button in buttons.values(): button.disabled = false
	inspection.visible = not inspected.is_empty()
	queue_redraw()

func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 1.0, 1.25)
	for id in labels:
		if id.begins_with("goal_"): continue
		labels[id].add_theme_font_size_override("font_size", roundi(labels[id].get_meta("base_font_size") * ui_scale))
	for button in buttons.values(): button.add_theme_font_size_override("font_size", roundi(17 * ui_scale))
	inspection.add_theme_font_size_override("font_size", roundi(14 * ui_scale))
	event_count = -1

func apply_focus_style() -> void:
	for button in find_children("*","BaseButton",true,false):
		button.add_theme_stylebox_override("focus",MatchTheme.get_stylebox("focus","Button") if keyboard_focus else no_focus)
