extends ColorRect
## Full-window presentation. Navigation is delegated to the match controller.
signal command(action: String)
static var MatchTheme: Theme = preload("res://ui/matchday_theme.gd").build()
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
		if kind == "kit":
			draw_set_transform(size/2,0,Vector2.ONE*size.y/34)
			var points := PackedVector2Array([Vector2(-7,-12),Vector2(-17,-5),Vector2(-13,3),Vector2(-8,0),Vector2(-8,15),Vector2(8,15),Vector2(8,0),Vector2(13,3),Vector2(17,-5),Vector2(7,-12),Vector2(3,-8),Vector2(-3,-8)])
			draw_colored_polygon(points,ink)
			if ink.get_luminance() < 0.45:
				points.append(points[0])
				draw_polyline(points,Color("F1ECDD99"),0.7,true)
		else:
			var id: String = {"resume":"play","continue_half":"play","continue_result":"forward","details":"records","log":"history","campaign_settings":"settings","restart":"restore","new":"new-run","save_exit":"save","quit":"exit"}.get(kind,kind)
			draw_texture_rect(preload("res://ui/matchday_icons.gd").texture("icons/"+id),Rect2(0,0,24,24),false,ink)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(MatchTheme.get_color("forest","Palette"),0.94)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	var glass := preload("res://ui/glass_panel.gd").new()
	add_child(glass)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glass.offset_left = 24
	glass.offset_top = 18
	glass.offset_right = -24
	glass.offset_bottom = -18
	color.a = 0.45
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
	if action in ["resume", "menu", "details", "log", "settings", "campaign_settings", "save_exit", "restart", "new", "quit"]:
		for state in ["normal", "hover", "pressed"]:
			var style: StyleBox = MatchTheme.get_stylebox(state, button.theme_type_variation).duplicate()
			style.content_margin_left = 46
			button.add_theme_stylebox_override(state, style)
		var icon := Icon.new()
		icon.kind = action
		icon.ink = ivory
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(icon)
		var align_icon := func(): icon.position = Vector2(12, (button.size.y - 24) / 2)
		button.resized.connect(align_icon)
		align_icon.call()
	if primary and action in ["continue_half","continue_result","confirm_restart","confirm_new"]:
		var arrow := _text(button, "→", "Label", 23, HORIZONTAL_ALIGNMENT_RIGHT)
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.add_theme_color_override("font_color", ivory)
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
	_text(left, ("MATCH COMPLETE" if presenter.campaign_mode else "EXHIBITION COMPLETE") if model.finished else "MATCH PAUSED", "Section", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_text(left, "FULL TIME" if model.finished else "PAUSED", "Heading", 120, HORIZONTAL_ALIGNMENT_CENTER)
	var score := Control.new()
	score.custom_minimum_size.y = 90
	left.add_child(score)
	_team_score(score, model.snapshot_report(), 54, false)
	_text(left, "%d′  ·  %s" % [model.display_minute(),model.phase_name()], "Label", 17, HORIZONTAL_ALIGNMENT_CENTER)
	var right := _column(Rect2(size * Vector2(0.67,0.20), size * Vector2(0.28,0.74)))
	right.add_theme_constant_override("separation",12)
	_button(right, "result" if model.finished else "resume", "Match summary" if model.finished else ("Return to halftime" if model.period == 1 else "Resume match"), true)
	for entry in [["details","Match details"],["log","Event log"],["campaign_settings" if presenter.campaign_mode else "settings","Settings"]]: _button(right, entry[0], entry[1])
	right.add_child(HSeparator.new())
	for entry in ([["save_exit","Save and exit to main menu"]] if presenter.campaign_mode else [["restart","Restart exhibition"],["prepare","Prepare exhibition"],["quit","Quit to desktop"]]): _button(right, entry[0], entry[1])
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
	_text(box, "Preferences apply to this session. Match timing and outcomes stay unchanged.", "Label", 15).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(box, "back", "Back")

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
	var gap := roundi(20*scale_factor)
	var identity_gap := roundi(14*scale_factor)
	row.add_theme_constant_override("separation",gap)
	parent.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var score := _text(row, "%d  –  %d" % report.scores, "Score", pixels, HORIZONTAL_ALIGNMENT_CENTER)
	score.name = "TeamScore"
	score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var groups: Array[Control] = []
	var labels: Array[Label] = []
	for team in 2:
		var group := VBoxContainer.new()
		group.size_flags_horizontal = SIZE_EXPAND_FILL
		group.size_flags_vertical = SIZE_SHRINK_CENTER
		groups.append(group)
		row.add_child(group)
		var identity := HBoxContainer.new()
		identity.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
		identity.add_theme_constant_override("separation",identity_gap)
		group.add_child(identity)
		var kit := Icon.new()
		kit.name = "TeamKitHome" if team == 0 else "TeamKitAway"
		kit.kind = "kit"
		kit.ink = presenter.team_kits[team]
		kit.custom_minimum_size = Vector2(42,42)*scale_factor
		kit.size_flags_vertical = SIZE_SHRINK_CENTER
		identity.add_child(kit)
		var team_name := _text(identity, presenter.team_names[team].to_upper(), "Team", 40 if pixels > 60 else 32)
		team_name.name = "TeamNameHome" if team == 0 else "TeamNameAway"
		team_name.tooltip_text = presenter.team_names[team]
		team_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		team_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		team_name.size_flags_horizontal = SIZE_SHRINK_BEGIN
		labels.append(team_name)
		if scorers:
			var names: Array[String] = []
			for event in report.events:
				if event.kind == "goal" and event.team == team: names.append("%s %s" % [event.get("actor_name",model.players[event.actor].name), event.get("clock","%d′" % event.minute)])
			_text(group, "  ".join(names), "Label", 15, HORIZONTAL_ALIGNMENT_CENTER).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.move_child(score,1)
	var align_teams := func():
		var score_face: Font = score.get_theme_font("font")
		var score_width := maxf(pixels*2.6*scale_factor,ceilf(score_face.get_string_size(score.text,HORIZONTAL_ALIGNMENT_LEFT,-1,score.get_theme_font_size("font_size")).x)+4)
		score.custom_minimum_size.x = score_width
		var side := maxf(0,floorf((parent.size.x-score_width-2*gap)/2))
		var available := maxf(1,side-42*scale_factor-identity_gap)
		var name_pixels := roundi((40 if pixels > 60 else 32)*scale_factor)
		var face: Font = labels[0].get_theme_font("font")
		while name_pixels > roundi(16*scale_factor) and maxf(face.get_string_size(labels[0].text,HORIZONTAL_ALIGNMENT_LEFT,-1,name_pixels).x,face.get_string_size(labels[1].text,HORIZONTAL_ALIGNMENT_LEFT,-1,name_pixels).x) > available: name_pixels -= 1
		for team in 2:
			groups[team].custom_minimum_size.x = side
			labels[team].add_theme_font_size_override("font_size",name_pixels)
			labels[team].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if face.get_string_size(labels[team].text,HORIZONTAL_ALIGNMENT_LEFT,-1,name_pixels).x > available else TextServer.AUTOWRAP_OFF
			labels[team].custom_minimum_size.x = minf(available,ceilf(face.get_string_size(labels[team].text,HORIZONTAL_ALIGNMENT_LEFT,-1,name_pixels).x)+1)
	parent.resized.connect(align_teams)
	align_teams.call_deferred()

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
		if not all_events and event.kind not in ["goal","save","parry","smother","block","shootout_goal","shootout_miss","forfeit","red_card","substitution"]: continue
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 62 * scale_factor
		row.add_theme_constant_override("separation", 10)
		rows.add_child(row)
		var icon = presenter.EventIcon.new()
		icon.kind = event.kind
		icon.entry = event
		icon.team = event.team
		icon.custom_minimum_size = Vector2(30,35)
		row.add_child(icon)
		_text(row, event.get("clock","%d′" % event.minute), "Label", 17).custom_minimum_size.x = 48
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
	var phase := mode in ["halftime","result"]
	var heading := _text(content, {"halftime":"HALF TIME","result":"FULL TIME","details":"MATCH DETAILS"}[mode], "Goal" if phase else "Section", 46 if phase else 17, HORIZONTAL_ALIGNMENT_CENTER)
	heading.name = "PhaseTitle"
	_place(heading, Rect2(0, size.y * 0.032, size.x, 64))
	if phase and not presenter.reduced_motion:
		heading.position.x = 30
		heading.modulate.a = 0
		var reveal := heading.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		reveal.tween_property(heading,"position:x",0.0,0.38)
		reveal.tween_property(heading,"modulate:a",1.0,0.24)
	var minute := _text(content, report.get("clock","%d′" % report.minute), "Label", 16, HORIZONTAL_ALIGNMENT_CENTER)
	if not report.get("penalties",[]).is_empty(): minute.text += "  ·  Penalties %d–%d" % report.penalties
	_place(minute, Rect2(0,size.y * 0.126,size.x,25))
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
	if mode == "result" and report.get("winner",-1) >= 0:
		result.text = presenter.team_names[report.winner]+" win"+(" on penalties" if not report.get("penalties",[]).is_empty() else (" by forfeit" if report.get("forfeit_team",-1) >= 0 else ""))
	result.size_flags_horizontal = SIZE_EXPAND_FILL
	if mode != "details":
		_button(footer, "continue_half" if mode == "halftime" else "continue_result", "Continue second half" if mode == "halftime" else "Continue", true).custom_minimum_size.x = 300 * scale_factor
	var rule := HSeparator.new()
	content.add_child(rule)
	rule.name = "FooterDivider"
	_place(rule,Rect2(48,size.y-116,size.x-96,1))

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
