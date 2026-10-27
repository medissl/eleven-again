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
		elif kind in ["save", "smother"]:
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
		for event in sim.events:
			if event.kind == "goal":
				goal_cue_tick = event.tick
				goal_cue_actor = event.actor
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
		if event.kind not in ["goal", "save", "smother", "tackle", "interception", "block", "miss", "kickoff", "halftime", "full_time"]: continue
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
	title.text = {"menu":"Paused", "details":"Match details", "log":"All events", "restart":"Restart exhibition?", "new":"New exhibition?"}[mode]
	title.add_theme_font_size_override("font_size", 28)
	panel_content.add_child(title)
	if mode == "menu":
		for entry in [["resume","Resume match"],["details","Match details"],["log","All events"],["restart","Restart this fixture"],["new","New exhibition"],["quit","Quit to desktop"]]:
			_panel_button(entry[0], entry[1])
		_panel_text("Space pauses · 1 / 2 speed · ← / → inspect\nExhibition only: simplified restarts, draws, no cards or offside. Progress is not saved.", 14)
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
	for child in panel_content.get_children():
		if child is Button: focusable.append(child)
	for i in focusable.size():
		focusable[i].focus_next = focusable[(i + 1) % focusable.size()].get_path()
		focusable[i].focus_previous = focusable[posmod(i - 1, focusable.size())].get_path()
	if not focusable.is_empty(): focusable[0].grab_focus()
	panel.size = Vector2(500 if mode == "log" else 430, 0)
	_center_panel.call_deferred()

func _panel_button(id: String, text: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(func(): command.emit(id))
	panel_content.add_child(button)

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
