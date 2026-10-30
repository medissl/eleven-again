extends Panel
var tint := Color("101D2E")
var surface_kind := 0
var activity := 0.0
var disabled_surface := false
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var glass := ShaderMaterial.new()
	glass.shader = preload("res://assets/ui/premium/glass.gdshader")
	material = glass
	set_notify_transform(true)
func _ready() -> void:
	resized.connect(_sync)
	_sync()
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree(): _sync()
func _sync() -> void:
	var transform := get_global_transform_with_canvas()
	var extent := size*Vector2(transform.x.length(),transform.y.length())
	material.set_shader_parameter("panel_rect",Vector4(transform.origin.x,transform.origin.y,extent.x,extent.y))
	material.set_shader_parameter("cut_px",12.0*transform.x.length())
	queue_redraw()
func _draw() -> void:
	material.set_shader_parameter("tint",tint)
	material.set_shader_parameter("kind",surface_kind)
	material.set_shader_parameter("activity",activity)
	material.set_shader_parameter("disabled_surface",disabled_surface)
	draw_rect(Rect2(Vector2(-5,-5),size+Vector2(10,10)),Color.WHITE)

static func button(node: Button) -> void:
	if node.has_meta("motion_surface") or node.has_method("layout_card") or node.name in ["AbilityIcon","PossessionInfo"]: return
	var glass := preload("res://ui/glass_panel.gd").new()
	glass.name = "GlassSurface"
	glass.show_behind_parent = true
	node.add_child(glass)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.set_meta("motion_surface",glass)
	var refresh := func():
		glass.surface_kind = 2 if node.theme_type_variation == "Primary" else 3 if node.theme_type_variation in ["Quiet","Tab"] else 1
		glass.disabled_surface = node.disabled
		glass.queue_redraw()
	node.draw.connect(refresh)
	refresh.call()

static func decorate_screen(node: Control) -> void:
	var copy := BackBufferCopy.new()
	copy.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	node.add_child(copy)
	var glass := preload("res://ui/glass_panel.gd").new()
	node.add_child(glass)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glass.offset_left=24; glass.offset_top=18; glass.offset_right=-24; glass.offset_bottom=-18
