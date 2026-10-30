extends RefCounted
const ROOT := "res://outputs/fc-mobile-ui-v6/"
const BG := Color("080E19")
const SURFACE := Color("101D2E")
const RAISED := Color("1A2D45")
const INK := Color("F2F7FD")
const MUTED := Color("A0B2C9")
const LINE := Color("29405A")
const ACCENT := Color("49D6F5")
static var flags := {}
static var typefaces := {}

static func athletic_font(weight: String, italic: bool = false) -> FontVariation:
	var key := weight+("Italic" if italic else "")
	if not typefaces.has(key):
		var face := FontFile.new()
		face.data = FileAccess.get_file_as_bytes(ROOT+"fonts/Saira-"+("Italic-" if italic else "")+"Variable.ttf")
		face.fallbacks = [load("res://assets/ui/matchday/fonts/SourceSans3-Regular.ttf")]
		var variant := FontVariation.new()
		variant.base_font = face
		var text_server := TextServerManager.get_primary_interface()
		variant.variation_opentype = {text_server.name_to_tag("wght"):float({"Medium":500,"SemiBold":600,"Bold":800}[weight]),text_server.name_to_tag("wdth"):90.0}
		variant.opentype_features = {text_server.name_to_tag("tnum"):1,text_server.name_to_tag("pnum"):0}
		typefaces[key] = variant
	return typefaces[key]

static func make_theme() -> Theme:
	var result: Theme = load("res://ui/game_theme.tres").duplicate(true)
	result.default_font = athletic_font("Medium")
	result.default_font_size = 18
	var strong: Font = athletic_font("Bold")
	result.set_font("font","Heading",athletic_font("Bold",true))
	result.set_font("font","Team",strong)
	result.set_font("font","BodyStrong",athletic_font("SemiBold"))
	result.set_font("font","Section",athletic_font("SemiBold"))
	for role in ["Label","RichTextLabel","TooltipLabel","LineEdit"]: result.set_font("font",role,athletic_font("Medium"))
	for role in ["Button","Primary","Quiet","Tab","OptionButton","CheckButton"]:
		result.set_font("font",role,athletic_font("SemiBold"))
		result.set_font_size("font_size",role,20)
	result.set_font("font","Goal",athletic_font("Bold",true))
	result.set_font("font","Score",strong)
	for kind in ["Label","Button","OptionButton","LineEdit","CheckButton"]:
		result.set_color("font_color",kind,INK)
		result.set_color("font_hover_color",kind,INK)
		result.set_color("font_focus_color",kind,INK)
		result.set_color("font_pressed_color",kind,INK)
		result.set_color("font_disabled_color",kind,MUTED.darkened(0.3))
	for role in ["Button","Primary","Quiet","Tab"]:
		if role != "Button": result.set_type_variation(role,"Button")
		for state in ["normal","hover","pressed","focus","disabled"]:
			var box := StyleBoxFlat.new()
			# The separate glass child draws the surface; native text/icons stay crisp.
			box.bg_color = Color(0,0,0,0)
			box.content_margin_left = 16
			box.content_margin_right = 16
			result.set_stylebox(state,role,box)
		if role == "Primary":
			for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]: result.set_color(state,role,INK)
	return result

static func label(parent: Node, value: String, rect: Rect2, pixels: int = 18, role: String = "Label", ink: Color = INK) -> Label:
	var node := Label.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.theme_type_variation = role
	node.add_theme_font_size_override("font_size",pixels)
	node.add_theme_color_override("font_color",ink)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, value: String, rect: Rect2, action: Callable, role: String = "Button", id: String = "") -> Button:
	var node := Button.new()
	node.text = value
	node.name = id if not id.is_empty() else value.to_pascal_case().replace("$","") if not value.is_empty() else "Action"
	node.position = rect.position
	node.size = rect.size
	node.theme_type_variation = role
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(action)
	parent.add_child(node)
	skin_button(node)
	return node

static func skin_button(node: Button) -> void:
	var surface := Glass.new()
	surface.name = "GlassSurface"
	surface.show_behind_parent = true
	node.add_child(surface)
	node.set_meta("motion_surface",surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var refresh := func():
		surface.surface_kind = 2 if node.theme_type_variation == "Primary" else 3 if node.theme_type_variation in ["Quiet","Tab"] else 1
		if not node.has_meta("motion_feedback"): surface.activity = 1.0 if node.has_focus() else 0.0
		surface.disabled_surface = node.disabled
		surface.queue_redraw()
	node.draw.connect(refresh)
	refresh.call()

static func panel(parent: Node, rect: Rect2, color: Color = SURFACE) -> Panel:
	var node: Panel = Glass.new() if minf(rect.size.x,rect.size.y) > 28 else Panel.new()
	node.position = rect.position
	node.size = rect.size
	if node is Glass:
		node.tint = color
		parent.add_child(node)
		return node
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color,0.93)
	box.set_corner_radius_all(12)
	box.border_color = LINE
	box.set_border_width_all(1)
	node.add_theme_stylebox_override("panel",box)
	parent.add_child(node)
	return node

class Glass:
	extends Panel
	var tint := Color("101D2E")
	var surface_kind := 0
	var activity := 0.0
	var disabled_surface := false
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		var glass := ShaderMaterial.new()
		glass.shader = load("res://outputs/fc-mobile-ui-v6/glass.gdshader")
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

static func flag(code: String) -> Texture2D:
	if flags.has(code): return flags[code]
	var path := ROOT+"flags/"+code+".svg"
	if not FileAccess.file_exists(path): return null
	var pixels := Image.new()
	assert(pixels.load_svg_from_string(FileAccess.get_file_as_string(path),0.3) == OK)
	flags[code] = ImageTexture.create_from_image(pixels)
	return flags[code]

static func flag_view(parent: Node, code: String, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = flag(code)
	node.position = rect.position
	node.size = rect.size
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

class Card:
	extends "res://ui/player_card.gd"

class AbilityBadge:
	extends "res://ui/ability_badge.gd"

class Crest:
	extends Control
	static var atlas: Texture2D
	var motif := "bridge"
	var color := Color("29465E")
	var accent := Color("F06D50")
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if atlas == null and FileAccess.file_exists("res://outputs/fc-mobile-ui-v6/art/club-crests.png"):
			atlas = ImageTexture.create_from_image(Image.load_from_file("res://outputs/fc-mobile-ui-v6/art/club-crests.png"))
	func _draw() -> void:
		if motif != "trophy" and atlas != null:
			var index := 0 if motif == "bridge" else 1 if motif == "mountain" else 2 if motif == "crown" else 3
			var piece := AtlasTexture.new()
			piece.atlas = atlas
			piece.region = Rect2(Vector2(index%2,index/2)*atlas.get_size()/2,atlas.get_size()/2)
			draw_texture_rect(piece,Rect2(Vector2.ZERO,size),false)
			return
		draw_set_transform(Vector2.ZERO,0,size/Vector2(100,110))
		var shield := PackedVector2Array([Vector2(8,5),Vector2(92,5),Vector2(88,72),Vector2(50,105),Vector2(12,72),Vector2(8,5)])
		draw_colored_polygon(shield,color)
		draw_polyline(shield,accent,2.2,true)
		if motif == "bridge":
			for x in [27,73]: draw_line(Vector2(x,30),Vector2(x,74),accent,5,true)
			draw_arc(Vector2(50,60),23,PI,TAU,24,accent,4,true)
			draw_line(Vector2(22,60),Vector2(78,60),accent,3,true)
			for y in [78,84]: draw_line(Vector2(30,y),Vector2(70,y),accent,2,true)
		elif motif == "mountain":
			draw_polyline(PackedVector2Array([Vector2(20,66),Vector2(41,30),Vector2(53,50),Vector2(64,38),Vector2(82,66)]),accent,4,true)
			for y in [76,83]: draw_line(Vector2(30,y),Vector2(70,y),accent,3,true)
		elif motif == "trophy":
			draw_polyline(PackedVector2Array([Vector2(30,26),Vector2(34,55),Vector2(50,67),Vector2(66,55),Vector2(70,26)]),accent,4,true)
			draw_arc(Vector2(30,36),15,PI/2,PI*1.5,16,accent,3,true)
			draw_arc(Vector2(70,36),15,-PI/2,PI/2,16,accent,3,true)
			draw_line(Vector2(50,66),Vector2(50,83),accent,4,true)
			draw_line(Vector2(32,86),Vector2(68,86),accent,4,true)
		else:
			for x in [28,50,72]: draw_line(Vector2(x,30),Vector2(x,78),accent,4,true)
			for y in [40,56]: draw_line(Vector2(25,y),Vector2(75,y),accent,4,true)
		draw_set_transform(Vector2.ZERO)

class Pitch:
	extends Control
	var turf: Texture2D
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	func _ready() -> void:
		var renderer = load("res://match/match_view.gd").new()
		renderer._make_turf()
		turf = renderer.turf
		renderer.free()
	func project(point: Vector2) -> Vector2:
		var depth := point.y/105.0
		return Vector2(size.x/2+(point.x/68.0-0.5)*lerpf(size.x*0.79,size.x*0.99,depth),depth*size.y)
	func marking(points: Array) -> void:
		var path := PackedVector2Array()
		for point in points: path.append(project(point))
		draw_polyline(path,Color(0.77,0.86,0.87,0.7),1.2,true)
	func _draw() -> void:
		var edge := PackedVector2Array([project(Vector2(0,0)),project(Vector2(68,0)),project(Vector2(68,105)),project(Vector2(0,105))])
		draw_colored_polygon(edge,Color("769C93"),PackedVector2Array([Vector2.ZERO,Vector2(3,0),Vector2(3,3),Vector2(0,3)]),turf)
		marking([Vector2(0,0),Vector2(68,0),Vector2(68,105),Vector2(0,105),Vector2(0,0)])
		marking([Vector2(0,52.5),Vector2(68,52.5)])
		var circle: Array = []
		for index in 65:
			var angle := index*TAU/64
			circle.append(Vector2(34+cos(angle)*9.15,52.5+sin(angle)*9.15))
		marking(circle)
		for end in 2:
			var line := 0.0 if end == 0 else 105.0
			var direction := 1.0 if end == 0 else -1.0
			for area in [Vector2(40.32,16.5),Vector2(18.32,5.5)]:
				var left: float = 34-area.x/2
				var right: float = 34+area.x/2
				marking([Vector2(left,line),Vector2(left,line+direction*area.y),Vector2(right,line+direction*area.y),Vector2(right,line)])
			var spot := Vector2(34,line+direction*11)
			draw_circle(project(spot),1.5,Color(0.8,0.9,0.9,0.8))
			var arc: Array = []
			for index in 25:
				var angle := lerpf(0.65,PI-0.65,index/24.0)
				arc.append(spot+Vector2(cos(angle)*9.15,sin(angle)*9.15*direction))
			marking(arc)

class Toggle:
	extends Button
	var amount := 0.0:
		set(value): amount=value; queue_redraw()
	func _init() -> void:
		toggle_mode = true
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		text = "Off"
		toggled.connect(func(on):
			text="On" if on else "Off"
			var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(self,"amount",1.0 if on else 0.0,0.12))
	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = Color("49D6F5") if button_pressed else Color("29405A")
		track.set_corner_radius_all(14)
		draw_style_box(track,Rect2(size.x-70,9,54,28))
		draw_circle(Vector2(size.x-56+amount*26,23),10,Color("F4F0E9"))
