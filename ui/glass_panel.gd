extends Panel
## Historical API name retained for callers. This is now a pixel arcade surface, with no screen sampling.
var tint := Color("17253B")
var surface_kind := 0
var activity := 0.0
var disabled_surface := false
var pressed_surface := false
var keyboard_focus := false
func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
func _ready() -> void: resized.connect(queue_redraw)
func _draw() -> void:
	if surface_kind == 3 and activity < 0.01: return
	var asset := "button_primary" if surface_kind == 2 else "panel" if surface_kind == 0 else "button"
	self_modulate=Color(0.55,0.6,0.65,1) if disabled_surface else Color.WHITE.lightened(activity*0.06)
	if surface_kind == 0 and size.x > 600 and size.y > 300:
		draw_rect(Rect2(Vector2.ZERO,size),Color("101827"))
		draw_texture_rect(preload("res://assets/ui/arcade/background.png"),Rect2(Vector2.ZERO,size),false,Color(0.35,0.4,0.5,1))
		var border: StyleBoxTexture = preload("res://ui/pixel_skin.gd").surface(asset).duplicate()
		border.draw_center=false
		draw_style_box(border,Rect2(Vector2.ZERO,size))
	else:
		if surface_kind == 0: draw_rect(Rect2(Vector2.ZERO,size),Color("101827"))
		draw_style_box(preload("res://ui/pixel_skin.gd").surface(asset),Rect2(Vector2(0,2 if pressed_surface else 0),size-Vector2(0,2 if pressed_surface else 0)))
	if keyboard_focus: draw_rect(Rect2(Vector2(4,4),size-Vector2(8,8)),Color("F5CE65") if surface_kind != 2 else Color("101827"),false,2)
static func button(node: Button) -> void:
	if node.get_meta("game_control",false) or node.has_meta("motion_surface") or node.has_method("layout_card") or node.name in ["AbilityIcon","PossessionInfo"]: return
	var surface = load("res://ui/glass_panel.gd").new()
	surface.name="ArcadeSurface"
	surface.show_behind_parent=true
	node.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.set_meta("motion_surface",surface)
	var refresh := func():
		surface.surface_kind=2 if node.theme_type_variation == "Primary" else 3 if node.theme_type_variation in ["Quiet","Tab"] else 1
		surface.disabled_surface=node.disabled
		surface.queue_redraw()
	node.draw.connect(refresh)
	refresh.call()
static func decorate_screen(node: Control) -> void:
	var surface = load("res://ui/glass_panel.gd").new()
	node.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.offset_left=8; surface.offset_top=8; surface.offset_right=-8; surface.offset_bottom=-8
