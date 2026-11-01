extends ColorRect
signal closed
const Parts = preload("res://ui/campaign_parts.gd")
var title := "Details"
var body := VBoxContainer.new()
var actions := HBoxContainer.new()
var closing := false
var reduced_motion := false
var entrance: Tween
var panel_left := 848.0
var panel_width := 432.0

func _ready() -> void:
	theme = Parts.ThemeData
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0,0,0,0.48)
	var glass := preload("res://ui/glass_panel.gd").new()
	glass.position=Vector2(panel_left,0)
	glass.size=Vector2(panel_width,720)
	add_child(glass)
	var panel := PanelContainer.new()
	panel.position = Vector2(panel_left,0)
	panel.size = Vector2(panel_width,720)
	var margins := StyleBoxEmpty.new()
	for side in 4: margins.set_content_margin(side,24)
	panel.add_theme_stylebox_override("panel",margins)
	add_child(panel)
	var column := Parts.column(panel,16)
	Parts.label(column,title,28,"Heading")
	column.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	column.add_child(HSeparator.new())
	column.add_child(actions)
	actions.add_theme_constant_override("separation",12)
	Parts.button(actions,"Cancel","CloseDrawer",dismiss)
	if not reduced_motion:
		modulate.a = 0
		panel.position.x += 12
		entrance = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		entrance.tween_property(self,"modulate:a",1,0.18)
		entrance.tween_property(panel,"position:x",panel_left,0.18)
	call_deferred("focus_contents")

func focus_contents() -> void:
	Parts.focus_loop(self)

func dismiss() -> void:
	if closing: return
	closing = true
	if is_instance_valid(entrance): entrance.kill()
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
