extends ColorRect
## Full-window presentation. Navigation is delegated to the match controller.
signal command(action: String)
const MatchTheme = preload("res://ui/game_theme.tres")
var content: Control
var presenter: Control
var model: RefCounted
var mode := ""
var closing := false
var transition: Tween
var scale_factor := 1.0
var ivory: Color = MatchTheme.get_color("ivory", "Palette")
var coral: Color = MatchTheme.get_color("coral", "Palette")
var muted: Color = MatchTheme.get_color("muted", "Palette")

class Icon:
	extends Control
	var kind := ""
	var ink := Color("efe9d9")
	func _draw() -> void:
		match kind:
			"info":
				draw_arc(Vector2(12,12),9,0,TAU,24,ink,1.4,true)
				draw_circle(Vector2(12,7),1.2,ink)
				draw_line(Vector2(12,11),Vector2(12,18),ink,1.6,true)
			"pause":
				for x in [8,16]: draw_line(Vector2(x,4),Vector2(x,20),ink,3,true)
			"menu":
				for y in [5,12,19]: draw_line(Vector2(2,y),Vector2(23,y),ink,1.7,true)
			"kit":
				draw_set_transform(size / 2, 0, Vector2.ONE * size.y / 34)
				draw_colored_polygon(PackedVector2Array([Vector2(-7,-12),Vector2(-17,-5),Vector2(-13,3),Vector2(-8,0),Vector2(-8,15),Vector2(8,15),Vector2(8,0),Vector2(13,3),Vector2(17,-5),Vector2(7,-12),Vector2(3,-8),Vector2(-3,-8)]),ink)
			"resume", "continue_half", "continue_result":
				draw_colored_polygon(PackedVector2Array([Vector2(5,3),Vector2(21,12),Vector2(5,21)]), ink)
			"details":
				for i in 3: draw_line(Vector2(5+i*7,21),Vector2(5+i*7,9-i*3),ink,2,true)
			"settings":
				draw_arc(Vector2(12,12),8,0,TAU,12,ink,1.5,true)
				draw_arc(Vector2(12,12),3,0,TAU,16,ink,1.5,true)
				for i in 8: draw_line(Vector2(12,12)+Vector2.from_angle(i*TAU/8)*8,Vector2(12,12)+Vector2.from_angle(i*TAU/8)*11,ink,2,true)
			"restart", "new":
				draw_arc(Vector2(12,12),9,0.3,TAU-0.4,28,ink,1.5,true)
				draw_polyline(PackedVector2Array([Vector2(15,2),Vector2(21,3),Vector2(20,9)]),ink,1.5,true)
			"quit":
				draw_polyline(PackedVector2Array([Vector2(10,3),Vector2(21,3),Vector2(21,21),Vector2(10,21)]),ink,1.5,true)
				draw_line(Vector2(2,12),Vector2(15,12),ink,1.5,true)
				draw_polyline(PackedVector2Array([Vector2(10,7),Vector2(15,12),Vector2(10,17)]),ink,1.5,true)
			_:
				draw_arc(Vector2(12,12),9,0,TAU,24,ink,1.5,true)
				draw_circle(Vector2(12,12),3,ink)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.075, 0.045, 0.92)
	hide()

func present(next_mode: String, sim: RefCounted, hud: Control) -> void:
	_cancel_transition()
	var entering := not visible or closing
	closing = false
	mode = next_mode
	model = sim
	presenter = hud
	scale_factor = hud.ui_scale
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	show()
	mouse_filter = MOUSE_FILTER_STOP
	if mode == "menu": _pause_menu()
	elif mode == "settings": _settings()
	elif mode in ["halftime", "result", "details"]: _summary()
	elif mode == "log": _log()
	else: _confirmation()
	_focus_loop()
	modulate.a = 0.0 if entering and not hud.reduced_motion else 1.0
	content.position.y = 8 if entering and not hud.reduced_motion else 0
	if not hud.reduced_motion:
		transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		transition.tween_property(self, "modulate:a", 1.0, 0.18)
		transition.tween_property(content, "position:y", 0.0, 0.2)

func dismiss(animate: bool = true) -> void:
	_cancel_transition()
	closing = true
	mouse_filter = MOUSE_FILTER_IGNORE
	if is_instance_valid(content):
		for node in content.find_children("*", "BaseButton", true, false): node.disabled = true
	if not animate or presenter.reduced_motion:
		hide()
		return
	transition = create_tween()
	transition.tween_property(self, "modulate:a", 0.0, 0.12)
	transition.tween_callback(hide)

func _cancel_transition() -> void:
	if transition and transition.is_valid(): transition.kill()
	transition = null

func is_active() -> bool:
	return visible and not closing

func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

func _text(parent: Node, text: String, role: String = "Label", pixels: int = 17, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = role
	label.add_theme_font_size_override("font_size", roundi(pixels * scale_factor))
	label.horizontal_alignment = align
	label.tooltip_text = text
	label.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _column(rect: Rect2) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	content.add_child(box)
	_place(box, rect)
	return box

func _button(parent: Node, action: String, text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.name = action.to_pascal_case()
	button.set_meta("action", action)
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation = "Primary" if primary else "Button"
	button.add_theme_font_size_override("font_size", roundi((19 if primary else 18) * scale_factor))
	button.custom_minimum_size.y = 48 * scale_factor
	button.pressed.connect(func(): command.emit(action))
	parent.add_child(button)
	if action in ["resume", "menu", "details", "log", "settings", "restart", "new", "quit"]:
		for state in ["normal", "hover", "pressed"]:
			var style: StyleBox = MatchTheme.get_stylebox(state, button.theme_type_variation).duplicate()
			style.content_margin_left = 46
			button.add_theme_stylebox_override(state, style)
		var icon := Icon.new()
		icon.kind = action
		icon.ink = Color("102e20") if primary else ivory
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(icon)
		button.resized.connect(func(): icon.position = Vector2(12, (button.size.y - 24) / 2))
	if primary and action in ["continue_half","continue_result","confirm_restart","confirm_new"]:
		var arrow := _text(button, "→", "Label", 23, HORIZONTAL_ALIGNMENT_RIGHT)
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.add_theme_color_override("font_color", Color("102e20"))
		arrow.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		arrow.offset_left = -36
		arrow.offset_right = -12
	return button

func _focus_loop() -> void:
	var controls: Array[Control] = []
	var preferred: Control
	for node in content.find_children("*", "BaseButton", true, false):
		controls.append(node)
		if node.get_meta("action", "") in ["continue_half", "continue_result"]: preferred = node
	for i in controls.size():
		controls[i].focus_next = controls[(i + 1) % controls.size()].get_path()
		controls[i].focus_previous = controls[posmod(i - 1, controls.size())].get_path()
	if preferred: preferred.grab_focus()
	elif not controls.is_empty(): controls[0].grab_focus()

func _pause_menu() -> void:
	var left := _column(Rect2(size * Vector2(0.08,0.25), size * Vector2(0.5,0.58)))
	_text(left, "EXHIBITION COMPLETE" if model.finished else "MATCH PAUSED", "Section", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_text(left, "FULL TIME" if model.finished else "PAUSED", "Heading", 150, HORIZONTAL_ALIGNMENT_CENTER)
	var score := Control.new()
	score.custom_minimum_size.y = 90
	left.add_child(score)
	_team_score(score, model.snapshot_report(), 54, false)
	_text(left, "%d′  ·  %s" % [model.display_minute(), "Full time" if model.finished else ("Half time" if model.period == 1 else ("Second half" if model.period == 2 else "First half"))], "Label", 17, HORIZONTAL_ALIGNMENT_CENTER)
	var right := _column(Rect2(size * Vector2(0.67,0.20), size * Vector2(0.28,0.74)))
	right.add_theme_constant_override("separation",12)
	_button(right, "result" if model.finished else "resume", "Match summary" if model.finished else ("Return to halftime" if model.period == 1 else "Resume match"), true)
	for entry in [["details","Match details"],["log","Event log"],["settings","Settings"]]: _button(right, entry[0], entry[1])
	right.add_child(HSeparator.new())
	for entry in [["restart","Restart exhibition"],["prepare","Prepare exhibition"],["quit","Quit to desktop"]]: _button(right, entry[0], entry[1])
	for action in right.get_children():
		if action is Button:
			action.add_theme_font_size_override("font_size",roundi(20*scale_factor))
			action.custom_minimum_size.y = (56 if action.get_meta("action","") in ["resume","result","details","log","settings"] else 48) * scale_factor
	var divider := VSeparator.new()
	content.add_child(divider)
	_place(divider,Rect2(size.x*0.645,size.y*0.13,1,size.y*0.75))
	var rule := HSeparator.new()
	content.add_child(rule)
	_place(rule,Rect2(size.x*0.10,size.y*0.73+(scale_factor-1)*190,size.x*0.48,1))

func _settings() -> void:
	var box := _column(Rect2(size * Vector2(0.24,0.17), size * Vector2(0.52,0.7)))
	_text(box, "VIEWING PREFERENCES", "Section", 15)
	_text(box, "Settings", "Heading", 52)
	_button(box, "effects", "Celebration effects: " + ("On" if presenter.effects_enabled else "Off"))
	_button(box, "motion", "Reduced motion: " + ("On" if presenter.reduced_motion else "Off"))
	_text(box, "Interface size", "BodyStrong", 17)
	var sizes := HBoxContainer.new()
	box.add_child(sizes)
	for percent in [100,115,125]:
		var button := _button(sizes, "scale%d" % percent, "%d%%" % percent, is_equal_approx(presenter.ui_scale, percent / 100.0))
		button.size_flags_horizontal = SIZE_EXPAND_FILL
	_text(box, "Preferences apply to this session. Match timing and outcomes stay unchanged.", "Label", 15).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(box, "back", "Back", true)

func _section(parent: Node, caption: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	_text(row, caption, "Section", 15)
	var line := HSeparator.new()
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(line)

func _team_score(parent: Control, report: Dictionary, pixels: int, scorers: bool = true) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	parent.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for team in 2:
		if team == 1:
			var score := _text(row, "%d  –  %d" % report.scores, "Score", pixels, HORIZONTAL_ALIGNMENT_CENTER)
			score.custom_minimum_size.x = pixels * 2.6 * scale_factor
			score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var group := VBoxContainer.new()
		group.size_flags_horizontal = SIZE_EXPAND_FILL
		group.size_flags_vertical = SIZE_SHRINK_CENTER
		group.custom_minimum_size.x = maxf(0,(parent.size.x-pixels*2.6*scale_factor-40)/2)
		parent.resized.connect(func(): group.custom_minimum_size.x = maxf(0,(parent.size.x-pixels*2.6*scale_factor-40)/2))
		row.add_child(group)
		var identity := HBoxContainer.new()
		identity.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
		identity.add_theme_constant_override("separation", 18)
		group.add_child(identity)
		var kit := Icon.new()
		kit.kind = "kit"
		kit.ink = ivory if team == 0 else coral
		kit.custom_minimum_size = Vector2(42,42)
		identity.add_child(kit)
		_text(identity, "MEADOW XI" if team == 0 else "HARBOR XI", "Team", 40 if pixels > 60 else 32)
		if scorers:
			var names: Array[String] = []
			for event in report.events:
				if event.kind == "goal" and event.team == team: names.append("%s %d′" % [event.get("actor_name",model.players[event.actor].name), event.minute])
			_text(group, " · ".join(names), "Label", 15, HORIZONTAL_ALIGNMENT_CENTER).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _comparison_row(parent: Node, caption: String, values: Array, key: String, tip: Label = null) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 38 * scale_factor
	parent.add_child(row)
	var home := _text(row, str(values[0]), "Score", 29, HORIZONTAL_ALIGNMENT_CENTER)
	home.name = key + "Home"
	home.custom_minimum_size.x = 100 * scale_factor
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(center)
	_text(center, caption, "Label", 17, HORIZONTAL_ALIGNMENT_CENTER)
	if tip:
		var info := Button.new()
		info.name = "PossessionInfo"
		info.tooltip_text = tip.text
		info.custom_minimum_size = Vector2(28,28)
		info.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		center.add_child(info)
		var popup := PanelContainer.new()
		popup.name = "PossessionTooltip"
		popup.add_theme_stylebox_override("panel",MatchTheme.get_stylebox("panel","TooltipPanel"))
		popup.z_index = 5
		popup.custom_minimum_size.x = minf(440,size.x-48)
		content.add_child(popup)
		popup.add_child(tip)
		tip.show()
		popup.hide()
		info.pressed.connect(func():
			popup.visible = not popup.visible
			var local_point := content.get_global_transform().affine_inverse()*info.get_global_rect().position
			popup.position = Vector2(clampf(local_point.x-160,24,size.x-464),local_point.y+38)
			info.tooltip_text = "" if popup.visible else tip.text)
		var icon := Icon.new()
		icon.kind = "info"
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		info.add_child(icon)
		info.resized.connect(func(): icon.position = (info.size-Vector2(24,24))/2)
	var away := _text(row, str(values[1]), "Score", 29, HORIZONTAL_ALIGNMENT_CENTER)
	away.name = key + "Away"
	away.custom_minimum_size.x = 100 * scale_factor

func _statistics(parent: VBoxContainer, report: Dictionary) -> void:
	_section(parent, "MATCH STATS")
	var tip := Label.new()
	tip.text = "Possession counts controlled-ball time only. Flight and loose-ball time are excluded."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 14)
	tip.hide()
	var total: int = report.possession[0] + report.possession[1]
	var home_share := roundi(100.0 * report.possession[0] / total) if total > 0 else 0
	_comparison_row(parent, "Possession", ["%d%%" % home_share, "%d%%" % (100-home_share)] if total > 0 else ["—","—"], "Possession", tip)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 2)
	bar.custom_minimum_size.y = 6
	parent.add_child(bar)
	for team in 2:
		var fill := ColorRect.new()
		fill.color = (ivory if team == 0 else coral) if total > 0 else muted.darkened(0.45)
		fill.size_flags_horizontal = SIZE_EXPAND_FILL
		fill.size_flags_stretch_ratio = maxf(0.001, report.possession[team]) if total > 0 else 1.0
		fill.mouse_filter = MOUSE_FILTER_IGNORE
		bar.add_child(fill)
	for entry in [["Shots",report.shots,"Shots"],["On target",report.on_target,"OnTarget"],["Saves",report.saves,"Saves"],["Passes completed",["%d / %d" % [report.completed[0],report.attempted[0]],"%d / %d" % [report.completed[1],report.attempted[1]]],"Passes"]]:
		parent.add_child(HSeparator.new())
		_comparison_row(parent, entry[0], entry[1], entry[2])

func _events(parent: VBoxContainer, events: Array, all_events: bool = false) -> void:
	_section(parent, "EVENT LOG" if all_events else "KEY MOMENTS")
	var scroll := ScrollContainer.new()
	scroll.name = "EventLog" if all_events else "Moments"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	for event in events:
		if not all_events and event.kind not in ["goal","save","parry","smother","block"]: continue
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 62 * scale_factor
		row.add_theme_constant_override("separation", 10)
		rows.add_child(row)
		var icon = presenter.EventIcon.new()
		icon.kind = event.kind
		icon.team = event.team
		icon.custom_minimum_size = Vector2(30,35)
		row.add_child(icon)
		_text(row, "%d′" % event.minute, "Label", 17).custom_minimum_size.x = 36
		var copy: Array[String] = presenter.event_copy(event)
		var lines := VBoxContainer.new()
		lines.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(lines)
		_text(lines, copy[0], "BodyStrong", 18).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_text(lines, copy[1], "Label", 16).add_theme_color_override("font_color", muted)
		rows.add_child(HSeparator.new())
	if rows.get_child_count() == 0:
		_text(rows, "No goals or keeper/shot-blocking events this period.", "Label", 17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _summary() -> void:
	var report: Dictionary = model.halftime_report if mode == "halftime" else (model.result_report if mode == "result" else model.snapshot_report())
	var heading := _text(content, {"halftime":"HALF TIME","result":"FULL TIME","details":"MATCH DETAILS"}[mode], "Section", 17, HORIZONTAL_ALIGNMENT_CENTER)
	_place(heading, Rect2(0, size.y * 0.055, size.x, 30))
	var minute := _text(content, "%d′" % report.minute, "Label", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_place(minute, Rect2(0,size.y * 0.108,size.x,25))
	var score := Control.new()
	content.add_child(score)
	_place(score, Rect2(size.x*0.10,size.y*0.17,size.x*0.80,size.y*0.14))
	_team_score(score, report, 84)
	var left := _column(Rect2(size * Vector2(0.10,0.35),size * Vector2(0.50,0.46)))
	_statistics(left, report)
	var right := _column(Rect2(size * Vector2(0.66,0.35),size * Vector2(0.26,0.46)))
	_events(right, report.events)
	var divider := VSeparator.new()
	content.add_child(divider)
	_place(divider, Rect2(size.x*0.63,size.y*0.35,1,size.y*0.46))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	content.add_child(footer)
	_place(footer, Rect2(48,size.y-100,size.x-96,56))
	_button(footer, "menu" if mode != "details" else "back", "Match menu" if mode != "details" else "Back")
	var result := _text(footer, ("Exhibition draw" if report.scores[0] == report.scores[1] else ("Meadow XI win" if report.scores[0] > report.scores[1] else "Harbor XI win")) if mode == "result" else "", "Label", 17, HORIZONTAL_ALIGNMENT_CENTER)
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	if mode != "details":
		_button(footer, "continue_half" if mode == "halftime" else "continue_result", "Continue second half" if mode == "halftime" else "Continue", true).custom_minimum_size.x = 300 * scale_factor
	var rule := HSeparator.new()
	content.add_child(rule)
	_place(rule,Rect2(48,size.y-92,maxf(150,size.x-120-300*scale_factor),1))

func _log() -> void:
	var box := _column(Rect2(size * Vector2(0.12,0.10),size * Vector2(0.76,0.74)))
	_text(box, "THE MATCH AS IT HAPPENED", "Section", 15)
	_text(box, "Event log", "Heading", 50)
	var chronological: Array = model.events.duplicate()
	chronological.reverse()
	_events(box, chronological, true)
	var button := _button(content, "back", "Back", true)
	_place(button, Rect2(size.x*0.68,size.y-82,size.x*0.2,50))

func _confirmation() -> void:
	var box := _column(Rect2(size * Vector2(0.23,0.24),size * Vector2(0.54,0.55)))
	_text(box, "EXHIBITION ONLY", "Section", 15)
	_text(box, "Change the match plan?" if mode == "prepare" else ("Restart this fixture?" if mode == "restart" else "Start a new exhibition?"), "Heading", 48)
	_text(box, "Discard this exhibition and replay its seed." if mode == "restart" else "Discard this exhibition and start a different seed.", "Label", 18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text(box, "Exhibition progress is not saved.", "Label", 16)
	_button(box, "confirm_" + mode, "Replay fixture" if mode == "restart" else "Start new fixture", true)
	_button(box, "back", "Cancel")

func dismiss_help() -> bool:
	if not is_instance_valid(content): return false
	var popup := content.find_child("PossessionTooltip",true,false) as Control
	if not popup or not popup.visible: return false
	popup.hide()
	return true
