extends Button
var ability := {}
var hint: Panel
func _ready() -> void:
	name = "AbilityIcon"
	icon = preload("res://ui/ability_icons.gd").texture(ability.id)
	expand_icon = true
	add_theme_constant_override("icon_max_width",32)
	for state in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(show_hint)
	focus_entered.connect(show_hint)
	mouse_exited.connect(dismiss_hint)
	focus_exited.connect(dismiss_hint)
	pressed.connect(show_hint)
	tooltip_text = ability.name
	for property in get_property_list():
		if property.name == "accessibility_name": set("accessibility_name",ability.name+". "+ability.effect)
func show_hint() -> void:
	if is_instance_valid(hint): return
	var viewport := get_viewport().get_visible_rect().size
	var factor := viewport.y/720.0
	var extent := Vector2(360,196)*factor
	var point := get_global_rect().end+Vector2(8,0)
	point.x = clampf(point.x,8,viewport.x-extent.x-8)
	point.y = clampf(point.y,8,viewport.y-extent.y-8)
	hint = preload("res://ui/glass_panel.gd").new()
	hint.position = point
	hint.size = extent
	hint.theme = theme if theme != null else get_parent().get_parent().theme
	hint.z_index = 1000
	get_viewport().add_child(hint)
	for index in 2:
		var copy := Label.new()
		copy.text = ability.name if index == 0 else ability.effect
		copy.position = Vector2(16,12 if index == 0 else 50)*factor
		copy.size = Vector2(328,30 if index == 0 else 132)*factor
		copy.add_theme_font_size_override("font_size",roundi((18 if index == 0 else 16)*factor))
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.clip_text = true
		copy.mouse_filter = MOUSE_FILTER_IGNORE
		hint.add_child(copy)
		copy.set_deferred("size",Vector2(328,30 if index == 0 else 132)*factor)
	queue_redraw()
func dismiss_hint() -> void:
	if is_instance_valid(hint): hint.queue_free()
	hint = null
	queue_redraw()
func _exit_tree() -> void: dismiss_hint()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_instance_valid(hint): dismiss_hint(); accept_event()
func _draw() -> void:
	if has_focus() or is_hovered(): draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),Color("FFF4D2"),false,1.5)
