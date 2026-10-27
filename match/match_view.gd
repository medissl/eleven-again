extends Control

const Match = preload("res://match/match_sim.gd")

const CREAM := Color("efecda")
const MUTED := Color("9aa99e")
const AMBER := Color("e9b65e")
const CORAL := Color("e88670")
const GREEN := Color("184d3b")
const NAMES = Match.NAMES

var pitch := Rect2()
var player_positions: Array[Vector2] = []
var ball := Vector2(52.5, 34)
var paused := true
var speed := 1
var selected := -1
var labels: Dictionary = {}
var buttons: Dictionary = {}
var feed: RichTextLabel
var font: Font
var sim := Match.new()
var detailed := false
var last_event_count := -1
var hovered := -1
var pause_menu: AcceptDialog
var name_rects: Array[Rect2] = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	for p in sim.players:
		player_positions.append(p.position)
	_make_label("brand", "ELEVEN AGAIN", 23, CREAM)
	_make_label("edition", "EXHIBITION  /  MATCH LAB", 12, MUTED)
	_make_label("home", "MEADOW XI", 22, CREAM)
	_make_label("away", "HARBOR XI", 22, CORAL)
	_make_label("score", "0  –  0", 35, CREAM)
	_make_label("clock", "00′  /  READY", 14, AMBER)
	_make_label("pitch_title", "THE MATCH", 12, MUTED)
	_make_label("pitch_note", "4–3–3  ·  Fictional squads", 12, MUTED)
	_make_label("live", "MATCH JOURNAL", 15, CREAM)
	_make_label("live_note", "The story, as it happens.", 13, MUTED)
	_make_label("stats", "MEADOW                         HARBOR\n\nShots                 0  :  0\nOn target           0  :  0\nPasses                0  :  0", 14, CREAM)
	_make_label("inspection", "Select / ← → inspect  ·  Space pause  ·  Esc menu", 13, MUTED)
	_make_label("scope", "PHASE 1  /  Exhibition draws · Simplified restarts · No cards, offside or substitutions", 12, MUTED)
	_make_button("pause", "Kick off", _toggle_pause)
	_make_button("speed", "1× speed", _toggle_speed)
	_make_button("restart", "Restart", _restart)
	_make_button("new", "New match", func(): _restart(true))
	_make_button("exit", "Quit", func(): get_tree().quit())
	_make_button("detail", "Detailed feed: off", _toggle_detail)
	pause_menu = AcceptDialog.new()
	pause_menu.title = "Match paused"
	pause_menu.dialog_text = "Space: pause / resume\nLeft / Right: inspect players\n1 / 2: viewing speed\n\nViewing controls do not change the submitted team.\nThis exhibition uses simplified restarts and permits draws.\nCards, offside and substitutions arrive in later phases."
	pause_menu.ok_button_text = "Resume match"
	pause_menu.confirmed.connect(func():
		paused = false
		_sync_controls())
	add_child(pause_menu)
	feed = RichTextLabel.new()
	feed.bbcode_enabled = true
	feed.scroll_following = true
	feed.mouse_filter = Control.MOUSE_FILTER_STOP
	feed.add_theme_font_size_override("normal_font_size", 15)
	add_child(feed)
	feed.text = "[color=#e9b65e]PRE-MATCH[/color]\nTwo ordinary elevens. One open pitch.\n\nSelect Kick off to begin."
	resized.connect(_layout)
	mouse_exited.connect(func():
		hovered = -1
		_update_inspection())
	_layout()
	_sync_state()
	buttons.pause.grab_focus()

func _physics_process(_delta: float) -> void:
	if not paused and not sim.finished:
		for i in speed:
			sim.step()
		_sync_state()

func _sync_state() -> void:
	for i in 22:
		player_positions[i] = sim.players[i].position
	ball = sim.ball
	labels.score.text = "%d  –  %d" % sim.scores
	var phase_label: String = ["FIRST HALF", "HALF TIME", "SECOND HALF", "FULL TIME"][sim.period]
	if paused and not sim.finished:
		phase_label = "READY" if sim.ticks == 0 else "PAUSED"
	labels.clock.text = "%02d′  /  %s" % [sim.active_ticks / 40, phase_label]
	labels.pitch_note.text = "4–3–3  ·  Seed %d  ·  Meadow %s" % [sim.match_seed, "→" if sim.direction(0) > 0 else "←"]
	var controlled: int = sim.possession_ticks[0] + sim.possession_ticks[1]
	var share := roundi(100.0 * sim.possession_ticks[0] / controlled) if controlled > 0 else 50
	labels.stats.text = "MEADOW                     HARBOR\n\nShots               %d  :  %d\nOn target         %d  :  %d\nPasses          %d/%d : %d/%d\nControl            %d%% : %d%%" % [sim.shots[0], sim.shots[1], sim.shots_on_target[0], sim.shots_on_target[1], sim.completed_passes[0], sim.pass_attempts[0], sim.completed_passes[1], sim.pass_attempts[1], share, 100 - share]
	_refresh_feed()
	if sim.finished:
		buttons.pause.text = "Full time"
		buttons.pause.disabled = true
		labels.inspection.text = "%s  ·  %d – %d  ·  Restart to watch the same seed again" % ["EXHIBITION DRAW" if sim.scores[0] == sim.scores[1] else ("MEADOW WIN" if sim.scores[0] > sim.scores[1] else "HARBOR WIN"), sim.scores[0], sim.scores[1]]
	queue_redraw()

func _refresh_feed() -> void:
	if sim.events.size() == last_event_count and sim.ticks != 1:
		return
	last_event_count = sim.events.size()
	if sim.ticks == 0:
		feed.text = "[color=#e9b65e]PRE-MATCH[/color]\nTwo ordinary elevens. One open pitch.\n\nKick off to watch a 60-second match.\n\nRestart replays seed %d. New match tries the next seed." % sim.match_seed
		return
	var entries: Array[String] = []
	for event in sim.events:
		if not detailed and event.kind in ["pass", "received", "challenge", "hold", "recovery"]:
			continue
		var actor: String = NAMES[event.actor] if event.actor >= 0 else ""
		var message := ""
		match event.kind:
			"kickoff": message = "%s kick off." % ("Meadow" if event.team == 0 else "Harbor")
			"pass": message = "%s passes toward %s." % [actor, NAMES[event.receiver]]
			"received": message = "%s receives the pass." % actor
			"recovery": message = "%s gathers the loose ball." % actor
			"interception": message = "%s cuts out the pass." % actor
			"tackle": message = "%s wins the challenge." % actor
			"challenge": message = "%s challenges; the carrier keeps it." % actor
			"shot": message = "%s takes a shot." % actor
			"block": message = "%s blocks the shot." % actor
			"save": message = "%s makes the save." % actor
			"hold": message = "%s holds the ball." % actor
			"parry": message = "%s parries. The rebound is live." % actor
			"goal": message = "[b]GOAL · %s[/b]\nMeadow %d – %d Harbor" % [actor, event.score[0], event.score[1]]
			"miss": message = "%s sends it wide." % actor
			"out": message = "Ball out. A brief restart."
			"restart": message = "%s restarts play." % actor
			"goal_kick": message = "%s takes the goal kick." % actor
			"halftime": message = "[b]Half time.[/b] The teams change ends."
			"full_time": message = "[b]Full time · %d – %d[/b]\n%s" % [event.score[0], event.score[1], "Exhibition drawn." if event.score[0] == event.score[1] else "A result to build on."]
		if not message.is_empty():
			entries.append("[color=#e9b65e]%02d′[/color]  %s" % [event.minute, message])
	feed.text = "\n\n".join(entries.slice(maxi(0, entries.size() - 24)))

func _toggle_detail() -> void:
	detailed = not detailed
	buttons.detail.text = "Detailed feed: on" if detailed else "Detailed feed: off"
	last_event_count = -1
	_refresh_feed()

func _make_label(id: String, value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	labels[id] = label

func _make_button(id: String, value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(88, 38)
	button.pressed.connect(action)
	add_child(button)
	buttons[id] = button

func _place(id: String, x: float, y: float, width: float, height: float = 30) -> void:
	labels[id].position = Vector2(x, y)
	labels[id].size = Vector2(width, height)

func _layout() -> void:
	var side := 288.0
	var right := size.x - side - 28
	var available := Vector2(right - 56, size.y - 236)
	var scale_factor := minf(available.x / 105, available.y / 68)
	pitch = Rect2(Vector2(28 + (available.x - 105 * scale_factor) / 2, 174), Vector2(105, 68) * scale_factor)
	_place("brand", 28, 18, 280)
	_place("edition", 28, 50, 300)
	_place("home", 74, 91, 270)
	_place("score", right / 2 - 62, 77, 140, 52)
	_place("away", right - 286, 91, 250)
	labels.away.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place("clock", right / 2 - 68, 126, 200)
	_place("pitch_title", 28, 142, 200)
	_place("pitch_note", right - 300, 142, 290)
	_place("live", right + 26, 89, 240)
	_place("live_note", right + 26, 115, 250)
	_place("stats", right + 26, size.y - 222, 255, 155)
	_place("inspection", 28, size.y - 60, right - 40)
	_place("scope", 28, size.y - 30, size.x - 56)
	feed.position = Vector2(right + 26, 186)
	feed.size = Vector2(side - 26, size.y - 431)
	buttons.detail.position = Vector2(right + 26, 146)
	buttons.detail.size = Vector2(176, 30)
	for i in 5:
		var id: String = ["pause", "speed", "restart", "new", "exit"][i]
		buttons[id].position = Vector2(size.x - 520 + i * 98, 24)
		buttons[id].size = Vector2(90, 38)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101e1a"))
	var side_x := size.x - 316
	draw_line(Vector2(28, 74), Vector2(size.x - 28, 74), Color("34463b"), 1)
	draw_line(Vector2(side_x, 88), Vector2(side_x, size.y - 70), Color("34463b"), 1)
	if pitch.size.x == 0:
		return
	draw_rect(pitch.grow(10), Color("122f26"))
	for i in 10:
		var stripe := Rect2(pitch.position + Vector2(pitch.size.x * i / 10, 0), Vector2(pitch.size.x / 10, pitch.size.y))
		draw_rect(stripe, GREEN if i % 2 == 0 else Color("1b523f"))
	var line := Color("7ca58b")
	draw_rect(pitch, line, false, 1.4)
	draw_line(_field(Vector2(52.5, 0)), _field(Vector2(52.5, 68)), line, 1.4)
	draw_arc(_field(Vector2(52.5, 34)), 9.15 * _scale(), 0, TAU, 64, line, 1.4, true)
	draw_circle(_field(Vector2(52.5, 34)), 2, line)
	for end in 2:
		var x := 0.0 if end == 0 else 88.5
		draw_rect(Rect2(_field(Vector2(x, 13.84)), Vector2(16.5, 40.32) * _scale()), line, false, 1.4)
		x = 0.0 if end == 0 else 99.5
		draw_rect(Rect2(_field(Vector2(x, 24.84)), Vector2(5.5, 18.32) * _scale()), line, false, 1.4)
		var goal_x := pitch.position.x - 9 if end == 0 else pitch.end.x
		draw_rect(Rect2(Vector2(goal_x, _field(Vector2(0, 30.34)).y), Vector2(9, 7.32 * _scale())), CREAM, false, 2)
		draw_circle(_field(Vector2(11 if end == 0 else 94, 34)), 2, line)
	for i in player_positions.size():
		_draw_player(i)
	name_rects.clear()
	var priorities: Array[int] = []
	for index in [sim.owner, selected]:
		if index >= 0 and not priorities.has(index):
			priorities.append(index)
	for i in 22:
		if not priorities.has(i):
			priorities.append(i)
	for index in priorities:
		_draw_name(index)
	draw_circle(_field(ball) + Vector2(1, 2), 5.5, Color("081510"))
	draw_circle(_field(ball), 4.5, Color.WHITE)
	draw_circle(_field(ball), 1.5, Color("34463b"))

func _field(point: Vector2) -> Vector2:
	return pitch.position + point * _scale()

func _scale() -> float:
	return pitch.size.x / 105

func _draw_player(index: int) -> void:
	var point := _field(player_positions[index])
	var radius := 10.0
	var home := index < 11
	if selected == index:
		draw_arc(point, 15, 0, TAU, 28, AMBER, 2, true)
	elif sim.owner == index:
		draw_arc(point, 14, 0, TAU, 28, CREAM, 1, true)
	draw_circle(point + Vector2(1, 2), radius + 1, Color("10291f"))
	draw_circle(point, radius, CREAM if home else CORAL)
	if not home:
		draw_arc(point, 7, PI * 0.15, PI * 0.85, 12, Color("642d29"), 2, true)
	var number := str(index % 11 + 1)
	draw_string(font, point + Vector2(-font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2, 4), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("17291f"))

func _draw_name(index: int) -> void:
	var point := _field(player_positions[index])
	var name: String = NAMES[index]
	var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	for offset in [Vector2(-width / 2, 24), Vector2(-width / 2, -17), Vector2(15, 4), Vector2(-width - 15, 4)]:
		var name_pos: Vector2 = point + offset
		var rect := Rect2(name_pos + Vector2(-3, -13), Vector2(width + 6, 17))
		var blocked := not pitch.grow(7).encloses(rect)
		for existing in name_rects:
			blocked = blocked or existing.intersects(rect)
		for player_pos in player_positions:
			blocked = blocked or rect.intersects(Rect2(_field(player_pos) - Vector2(10, 10), Vector2(20, 20)))
		if not blocked:
			name_rects.append(rect)
			draw_rect(rect, Color("123126"))
			draw_string(font, name_pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CREAM)
			return

func _toggle_pause() -> void:
	if sim.finished:
		return
	paused = not paused
	_sync_controls()

func _sync_controls() -> void:
	buttons.pause.text = ("Kick off" if sim.ticks == 0 else "Resume") if paused else "Pause"
	_sync_state()

func _toggle_speed() -> void:
	speed = 3 - speed
	buttons.speed.text = "%d× speed" % speed

func _restart(new_seed: bool = false) -> void:
	sim = Match.new(sim.match_seed + (1 if new_seed else 0))
	paused = true
	selected = -1
	hovered = -1
	last_event_count = -1
	pause_menu.hide()
	buttons.pause.text = "Kick off"
	buttons.pause.disabled = false
	labels.clock.text = "00′  /  READY"
	_update_inspection()
	_sync_state()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			paused = true
			_sync_controls()
			if pause_menu.visible:
				pause_menu.hide()
			else:
				pause_menu.popup_centered()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and not pause_menu.visible:
			_toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_1, KEY_2] and not pause_menu.visible:
			speed = 1 if event.keycode == KEY_1 else 2
			buttons.speed.text = "%d× speed" % speed
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_LEFT, KEY_RIGHT] and not pause_menu.visible:
			selected = posmod(selected + (-1 if event.keycode == KEY_LEFT else 1), 22)
			hovered = -1
			_update_inspection()
			queue_redraw()
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		hovered = -1
		for i in player_positions.size():
			if _field(player_positions[i]).distance_to(event.position) < 17:
				hovered = i
				if event is InputEventMouseButton:
					selected = i
				break
		_update_inspection()
		queue_redraw()

func _update_inspection() -> void:
	var index := hovered if hovered >= 0 else selected
	if index < 0:
		labels.inspection.text = "Select / ← → inspect  ·  Space pause  ·  Esc menu"
		return
	var p = sim.players[index]
	labels.inspection.text = "%s · %s · PAC %d  PAS %d  SHO %d  DRI %d  DEF %d%s" % [p.name, "Meadow" if p.team == 0 else "Harbor", p.pace, p.passing, p.shooting, p.dribbling, p.defence, "  GK %d" % p.keeping if index % 11 == 0 else ""]
