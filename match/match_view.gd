extends Control

const CREAM := Color("efecda")
const MUTED := Color("9aa99e")
const AMBER := Color("e9b65e")
const CORAL := Color("e88670")
const GREEN := Color("184d3b")
const ANCHORS := [Vector2(6, 34), Vector2(25, 9), Vector2(21, 26),
	Vector2(21, 43), Vector2(25, 59), Vector2(42, 34), Vector2(53, 21),
	Vector2(53, 47), Vector2(72, 10), Vector2(77, 34), Vector2(72, 58)]
const NAMES := ["Ward", "Hart", "Okoro", "Silva", "Sato", "Reed", "Costa",
	"Idris", "Bima", "Arden", "Noor", "Novak", "Park", "Dube", "Bauer",
	"Chen", "Vega", "Musa", "Leone", "Ilyas", "Moreau", "Rossi"]

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

func _ready() -> void:
	font = ThemeDB.fallback_font
	for team in 2:
		for anchor in ANCHORS:
			var kickoff_anchor := Vector2(anchor.x * 0.6, anchor.y)
			player_positions.append(kickoff_anchor if team == 0 else Vector2(105 - kickoff_anchor.x, 68 - kickoff_anchor.y))
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
	_make_label("inspection", "Select a player to inspect  ·  Space pause  ·  Esc menu", 13, MUTED)
	_make_label("scope", "PHASE 1  /  Exhibition draws · Simplified restarts · No cards, offside or substitutions", 12, MUTED)
	_make_button("pause", "Kick off", _toggle_pause)
	_make_button("speed", "1× speed", _toggle_speed)
	_make_button("restart", "Restart", _restart)
	_make_button("exit", "Quit", func(): get_tree().quit())
	feed = RichTextLabel.new()
	feed.bbcode_enabled = true
	feed.scroll_following = true
	feed.mouse_filter = Control.MOUSE_FILTER_STOP
	feed.add_theme_font_size_override("normal_font_size", 15)
	add_child(feed)
	feed.text = "[color=#e9b65e]PRE-MATCH[/color]\nTwo ordinary elevens. One open pitch.\n\nSelect Kick off to begin."
	resized.connect(_layout)
	_layout()

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
	_place("pitch_note", right - 240, 142, 220)
	_place("live", right + 26, 89, 240)
	_place("live_note", right + 26, 115, 250)
	_place("stats", right + 26, size.y - 222, 255, 155)
	_place("inspection", 28, size.y - 60, right - 40)
	_place("scope", 28, size.y - 30, size.x - 56)
	feed.position = Vector2(right + 26, 165)
	feed.size = Vector2(side - 26, size.y - 410)
	for i in 4:
		var id: String = ["pause", "speed", "restart", "exit"][i]
		buttons[id].position = Vector2(size.x - 420 + i * 98, 24)
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
	draw_circle(point + Vector2(1, 2), radius + 1, Color("10291f"))
	draw_circle(point, radius, CREAM if home else CORAL)
	if not home:
		draw_arc(point, 7, PI * 0.15, PI * 0.85, 12, Color("642d29"), 2, true)
	var number := str(index % 11 + 1)
	draw_string(font, point + Vector2(-font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2, 4), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("17291f"))
	var name: String = NAMES[index]
	var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var name_pos := point + Vector2(-width / 2, 24)
	draw_rect(Rect2(name_pos + Vector2(-3, -13), Vector2(width + 6, 17)), Color("123126"))
	draw_string(font, name_pos, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CREAM)

func _toggle_pause() -> void:
	paused = not paused
	buttons.pause.text = "Resume" if paused else "Pause"
	labels.clock.text = "00′  /  PAUSED" if paused else "00′  /  FIRST HALF"

func _toggle_speed() -> void:
	speed = 3 - speed
	buttons.speed.text = "%d× speed" % speed

func _restart() -> void:
	paused = true
	selected = -1
	buttons.pause.text = "Kick off"
	labels.clock.text = "00′  /  READY"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			_toggle_pause()
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in player_positions.size():
			if _field(player_positions[i]).distance_to(event.position) < 17:
				selected = i
				labels.inspection.text = "%s  ·  %s  ·  No live managerial changes" % [NAMES[i], "Meadow XI" if i < 11 else "Harbor XI"]
				queue_redraw()
				break
