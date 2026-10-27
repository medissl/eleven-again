extends Control
## Native presentation only. All actions are requests to the match controller.
signal command(action: String)

const CREAM := Color("f1eedb")
const MUTED := Color("a0afa4")
const CORAL := Color("ec7968")
const AMBER := Color("ecc14f")
var buttons: Dictionary = {}
var labels: Dictionary = {}
var event_list: VBoxContainer
var inspection: Label
var overlay: ColorRect
var panel: PanelContainer
var panel_content: VBoxContainer
var divider := 1008.0
var pitch := Rect2()
var event_count := -1
var inspected := ""
var model: RefCounted
var status_color := Color("58bd7a")
var goal_cue_tick := -1000
var goal_cue_actor := -1
var goal_event: Dictionary = {}
var effects_enabled := true
var reduced_motion := false

class EventIcon:
	extends Control
	var kind := ""
	var team := -1
	func _draw() -> void:
		var color := Color("f1eedb") if team == 0 else Color("ec7968")
		if team < 0: color = Color("a0afa4")
		draw_circle(Vector2(6, 13), 4, color)
		if team == 1: draw_arc(Vector2(6, 13), 6, 0, TAU, 20, color, 1, true)
		var center := Vector2(32, 16)
		if kind == "goal":
			draw_arc(center, 10, 0, TAU, 24, Color("f1eedb"), 1.8, true)
			draw_circle(center, 3.5, Color("f1eedb"))
			for i in 5:
				var point := center + Vector2.from_angle(i * TAU / 5) * 6
				draw_line(point, center + Vector2.from_angle(i * TAU / 5) * 10, Color("f1eedb"), 1.5, true)
		elif kind in ["save", "smother", "parry"]:
			draw_polyline(PackedVector2Array([Vector2(23, 16), Vector2(24, 27), Vector2(38, 27), Vector2(42, 13)]), Color("f1eedb"), 1.8, true)
			for i in 4: draw_line(Vector2(26 + i * 4, 19), Vector2(25 + i * 4, 5 + i % 2 * 3), Color("f1eedb"), 1.8, true)
		else:
			draw_line(center - Vector2(9, -6), center + Vector2(8, -6), Color("f1eedb"), 1.8, true)
			draw_polyline(PackedVector2Array([center + Vector2(1, -8), center + Vector2(8, -6), center + Vector2(6, 1)]), Color("f1eedb"), 1.8, true)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_label("home", "MEADOW XI", 20, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	_label("away", "HARBOR XI", 20, CREAM)
	_label("score", "0 – 0", 40, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_label("clock", "0′", 17, AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_label("live", "LIVE", 16, CREAM)
	_label("goal_title", "GOAL!", 60, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_label("goal_detail", "", 20, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
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
	inspection.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(inspection)
	event_list = VBoxContainer.new()
	event_list.add_theme_constant_override("separation", 12)
	event_list.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(event_list)
	overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.035, 0.025, 0.64)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("11251a"), Color("52664e"), 22))
	overlay.add_child(panel)
	panel_content = VBoxContainer.new()
	panel_content.add_theme_constant_override("separation", 10)
	panel.add_child(panel_content)
	overlay.hide()

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
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(label)
	labels[id] = label

func _button(id: String, text: String, hint: String) -> Button:
	var button := Button.new()
	button.name = id.capitalize().replace(" ", "")
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(40, 42)
	button.pressed.connect(func(): command.emit(id))
	add_child(button)
	buttons[id] = button
	return button

func arrange(field_rect: Rect2, divider_x: float) -> void:
	pitch = field_rect
	divider = divider_x
	var center := pitch.get_center().x
	_put(labels.home, Rect2(center - 295, 21, 180, 34))
	_put(labels.away, Rect2(center + 112, 21, 180, 34))
	_put(labels.score, Rect2(center - 80, 5, 160, 50))
	_put(labels.clock, Rect2(center - 110, 53, 220, 28))
	_put(labels.live, Rect2(divider + 38, 94, 190, 28))
	_put(labels.goal_title, Rect2(pitch.get_center() + Vector2(-235, -64), Vector2(470, 80)))
	_put(labels.goal_detail, Rect2(pitch.get_center() + Vector2(-235, 22), Vector2(470, 32)))
	var x := divider + 12
	_put(buttons.pause, Rect2(x, 20, 42, 42))
	_put(buttons.speed1, Rect2(x + 50, 20, 44, 42))
	_put(buttons.speed2, Rect2(x + 94, 20, 44, 42))
	_put(buttons.menu, Rect2(x + 148, 20, 90, 42))
	_put(buttons.log, Rect2(divider + 14, size.y - 62, size.x - divider - 30, 42))
	inspection.position = Vector2(divider + 20, 134)
	inspection.size = Vector2(size.x - divider - 38, 70)
	event_list.position = Vector2(divider + 18, 140 + (80 if not inspected.is_empty() else 0))
	event_list.size = Vector2(size.x - divider - 32, 0)
	if overlay.visible: _center_panel()
	queue_redraw()

func _put(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _draw() -> void:
	var center := pitch.get_center().x
	_kit(Vector2(center - 318, 37), CREAM)
	_kit(Vector2(center + 316, 37), CORAL)
	draw_line(Vector2(divider, 84), Vector2(divider, size.y - 20), Color("40513d"), 1)
	draw_line(Vector2(divider + 18, 130), Vector2(size.x - 20, 130), Color("344a36"), 1)
	draw_line(Vector2(divider + 18, size.y - 73), Vector2(size.x - 20, size.y - 73), Color("344a36"), 1)
	draw_circle(Vector2(divider + 24, 108), 5, status_color)
	if labels.goal_title.visible: _draw_celebration()

func _draw_celebration() -> void:
	var age: int = model.ticks - goal_cue_tick
	var opacity := clampf((150 - age) / 20.0, 0, 1)
	var center := pitch.get_center()
	var color := CREAM if goal_event.team == 0 else CORAL
	draw_style_box(_box(Color(0.025, 0.07, 0.04, 0.94 * opacity), Color(color, opacity), 0), Rect2(center - Vector2(235, 68), Vector2(470, 135)))
	if not effects_enabled or reduced_motion: return
	# Capped analytical particles; no persistent emitter or gameplay RNG.
	var t := age / 60.0
	for i in 44:
		var angle := i * 2.39996 + goal_cue_tick % 11
		var velocity := Vector2(cos(angle) * (90 + i % 5 * 16), -90 - i % 7 * 16)
		var point := center + Vector2(0, -25) + velocity * t + Vector2(0, 70 * t * t)
		if not pitch.grow(-10).has_point(point): continue
		var piece_color: Color = [color, AMBER, CREAM][i % 3]
		var edge := Vector2.from_angle(angle + t * 4) * 3
		var side := edge.orthogonal() * 0.45
		draw_colored_polygon(PackedVector2Array([point - edge - side, point + edge - side, point + edge + side, point - edge + side]), Color(piece_color, opacity))

func _kit(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([Vector2(-7,-12),Vector2(-17,-5),Vector2(-13,3),Vector2(-8,0),Vector2(-8,15),Vector2(8,15),Vector2(8,0),Vector2(13,3),Vector2(17,-5),Vector2(7,-12),Vector2(3,-8),Vector2(-3,-8)])
	for i in points.size(): points[i] += center
	draw_colored_polygon(points, color)

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
	var goal_visible: bool = not goal_event.is_empty() and sim.ticks - goal_cue_tick < 150 and sim.period != 1 and not sim.finished
	labels.goal_title.visible = goal_visible
	labels.goal_detail.visible = goal_visible
	if goal_visible:
		labels.goal_title.add_theme_color_override("font_color", CREAM if goal_event.team == 0 else CORAL)
		labels.goal_detail.text = "%s · %d′    %d–%d" % [sim.NAMES[goal_event.actor], goal_event.minute, goal_event.score[0], goal_event.score[1]]
		var opacity := clampf((150 - (sim.ticks - goal_cue_tick)) / 20.0, 0, 1)
		labels.goal_title.modulate.a = opacity
		labels.goal_detail.modulate.a = opacity
	if sim.finished:
		labels.clock.text = "FULL TIME · %d′" % sim.display_minute()
	elif sim.period == 1:
		labels.clock.text = "HALF TIME · %d–%d" % sim.scores
	elif goal_cue_actor >= 0 and sim.ticks - goal_cue_tick < 150:
		labels.clock.text = "GOAL · %s · %d′" % [sim.NAMES[goal_cue_actor], sim.display_minute()]
	labels.live.text = "FULL TIME" if sim.finished else ("PAUSED" if paused else "LIVE")
	status_color = MUTED if sim.finished else (AMBER if paused else Color("58bd7a"))
	queue_redraw()
	buttons.pause.text = "▶" if paused else "Ⅱ"
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
	buttons.pause.disabled = sim.finished or overlay.visible

func event_copy(event: Dictionary) -> Array[String]:
	var actor: String = model.NAMES[event.actor] if event.actor >= 0 else ""
	match event.kind:
		"goal": return [actor, "Goal · %d–%d" % event.score]
		"save": return [actor, "Save"]
		"smother": return [actor, "Claims the ball"]
		"tackle": return [actor, "Tackle"]
		"interception": return [actor, "Interception"]
		"block": return [actor, "Shot blocked"]
		"miss": return [actor, "Shot wide"]
		"shot": return [actor, "Shot"]
		"kickoff": return ["Meadow XI" if event.team == 0 else "Harbor XI", "Kickoff"]
		"halftime": return ["Half time", "Teams change ends"]
		"full_time": return ["Full time", "%d–%d · Exhibition draw" % event.score if event.score[0] == event.score[1] else "%d–%d · Final score" % event.score]
		"pass": return [actor, "Pass to %s" % model.NAMES[event.receiver]]
		"received": return [actor, "Pass received"]
		"hold": return [actor, "Ball held"]
		"parry": return [actor, "Live rebound"]
		"challenge": return [actor, "Challenge"]
		"goal_kick": return [actor, "Goal kick"]
		"restart": return [actor, "Restart"]
		"recovery": return [actor, "Loose ball recovered"]
		_: return [actor, "Ball out"]

func _refresh_rows() -> void:
	for child in event_list.get_children():
		event_list.remove_child(child)
		child.queue_free()
	var count := 0
	var limit := int((size.y - 220 - (80 if not inspected.is_empty() else 0)) / 76)
	for i in range(model.events.size() - 1, -1, -1):
		var event: Dictionary = model.events[i]
		if event.kind not in ["goal", "save", "parry", "smother", "tackle", "interception", "block", "miss", "kickoff", "halftime", "full_time"]: continue
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 64
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
		icon.custom_minimum_size = Vector2(46, 40)
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(text)
		var copy := event_copy(event)
		for line in 2:
			var label := Label.new()
			label.text = copy[line]
			label.tooltip_text = label.text
			label.add_theme_font_size_override("font_size", 17 if line == 0 else 14)
			label.add_theme_color_override("font_color", CREAM if line == 0 else MUTED)
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.custom_minimum_size.x = 115
			text.add_child(label)
		count += 1
		if count >= limit: break

func show_panel(mode: String, sim: RefCounted) -> void:
	model = sim
	overlay.show()
	for button in buttons.values(): button.disabled = true
	for child in panel_content.get_children():
		panel_content.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = {"menu":"Match menu" if sim.finished else "Paused", "details":"Match details", "log":"All events", "restart":"Restart exhibition?", "new":"New exhibition?", "halftime":"HALF TIME", "result":"FULL TIME"}[mode]
	title.add_theme_font_size_override("font_size", 28)
	panel_content.add_child(title)
	if mode == "menu":
		for entry in [["result","Match summary"] if sim.finished else ["resume","Return to halftime" if sim.period == 1 else "Resume match"],["details","Match details"],["log","All events"],["restart","Restart this fixture"],["new","New exhibition"],["quit","Quit to desktop"]]:
			_panel_button(entry[0], entry[1])
		_panel_button("effects", "Celebration effects: " + ("On" if effects_enabled else "Off"))
		_panel_button("motion", "Reduced motion: " + ("On" if reduced_motion else "Off"))
		_panel_text("Space pauses · 1 / 2 speed · ← / → inspect\nExhibition only: simplified restarts, draws, no cards or offside. Progress is not saved.", 14)
	elif mode in ["halftime", "result"]:
		_show_report(sim.halftime_report if mode == "halftime" else sim.result_report, mode)
	elif mode == "details":
		_panel_text("MEADOW XI                         HARBOR XI\n\nGoals                 %d : %d\nShots                 %d : %d\nOn target             %d : %d\nCompleted passes      %d : %d\nPass attempts         %d : %d\nSaves                 %d : %d\n\nFixture seed: %d\n%d active seconds · %s" % [sim.scores[0],sim.scores[1],sim.shots[0],sim.shots[1],sim.shots_on_target[0],sim.shots_on_target[1],sim.completed_passes[0],sim.completed_passes[1],sim.pass_attempts[0],sim.pass_attempts[1],sim.saves[0],sim.saves[1],sim.match_seed,sim.regulation_ticks / 60,"exhibition draw" if sim.finished and sim.scores[0] == sim.scores[1] else "fictional squads"], 17)
		_panel_button("back", "Back")
	elif mode == "log":
		var log_view := RichTextLabel.new()
		log_view.custom_minimum_size = Vector2(430, 320)
		log_view.bbcode_enabled = true
		log_view.add_theme_font_size_override("normal_font_size", 16)
		for i in range(sim.events.size() - 1, -1, -1):
			var copy := event_copy(sim.events[i])
			log_view.append_text("[color=#ecc14f]%02d′[/color]  %s · %s\n\n" % [sim.events[i].minute, copy[0], copy[1]])
		panel_content.add_child(log_view)
		_panel_button("back", "Back")
	else:
		_panel_text("Discard the current exhibition and %s?\n\nExhibitions are not saved." % ("replay this exact seed" if mode == "restart" else "start a different fixture"), 17)
		_panel_button("confirm_" + mode, "Replay fixture" if mode == "restart" else "Start new fixture")
		_panel_button("back", "Cancel")
	var focusable: Array[Control] = []
	for child in panel_content.find_children("*", "Button", true, false):
		focusable.append(child)
	for i in focusable.size():
		focusable[i].focus_next = focusable[(i + 1) % focusable.size()].get_path()
		focusable[i].focus_previous = focusable[posmod(i - 1, focusable.size())].get_path()
	if not focusable.is_empty(): focusable[0].grab_focus()
	panel.size = Vector2(600 if mode in ["halftime", "result"] else (500 if mode == "log" else 430), 0)
	_center_panel.call_deferred()

func _show_report(report: Dictionary, mode: String) -> void:
	_panel_text("%d  –  %d" % report.scores, 34)
	var stats := GridContainer.new()
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 20)
	stats.add_theme_constant_override("v_separation", 5)
	panel_content.add_child(stats)
	var total_control: int = report.possession[0] + report.possession[1]
	var control := ["—", "—"]
	if total_control > 0:
		var home := roundi(100.0 * report.possession[0] / total_control)
		control = ["%d%%" % home, "%d%%" % (100 - home)]
	var rows := [["MEADOW XI", "", "HARBOR XI"], [control[0], "Controlled-ball possession", control[1]],
		[str(report.shots[0]), "Shots", str(report.shots[1])],
		[str(report.on_target[0]), "On target", str(report.on_target[1])],
		[str(report.saves[0]), "Saves", str(report.saves[1])],
		["%d / %d" % [report.completed[0], report.attempted[0]], "Passes completed / attempted", "%d / %d" % [report.completed[1], report.attempted[1]]]]
	for row in rows:
		for column in 3:
			var label := Label.new()
			label.text = row[column]
			label.add_theme_font_size_override("font_size", 15 if column == 1 else 16)
			label.add_theme_color_override("font_color", MUTED if column == 1 else CREAM)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			stats.add_child(label)
	_panel_text("Control time counts only a player holding the ball; flight and loose-ball time are excluded.", 13)
	_panel_text("FIRST-HALF MOMENTS" if mode == "halftime" else "MATCH MOMENTS", 14)
	var moments := RichTextLabel.new()
	moments.name = "Moments"
	moments.custom_minimum_size = Vector2(540, 115)
	moments.add_theme_font_size_override("normal_font_size", 16)
	for event in report.events:
		if event.kind in ["goal", "save", "parry", "smother", "block"]:
			var copy := event_copy(event)
			moments.add_text("%d′  %s · %s\n" % [event.minute, copy[0], copy[1]])
	if moments.get_parsed_text().is_empty(): moments.add_text("No goals or keeper/shot-blocking events this period.")
	panel_content.add_child(moments)
	if mode == "result":
		_panel_text("Exhibition draw" if report.scores[0] == report.scores[1] else ("Meadow XI win" if report.scores[0] > report.scores[1] else "Harbor XI win"), 18)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	panel_content.add_child(actions)
	var proceed := _panel_button("continue_half" if mode == "halftime" else "continue_result", "Continue second half" if mode == "halftime" else "Continue")
	proceed.reparent(actions)
	proceed.size_flags_horizontal = SIZE_EXPAND_FILL
	_panel_button("menu", "Match menu").reparent(actions)

func _panel_button(id: String, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(func(): command.emit(id))
	panel_content.add_child(button)
	return button

func _panel_text(text: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 370
	label.add_theme_font_size_override("font_size", font_size)
	panel_content.add_child(label)

func _center_panel() -> void:
	panel.position = (size - panel.size) / 2

func close_panel() -> void:
	overlay.hide()
	for button in buttons.values(): button.disabled = false
