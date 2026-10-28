extends RefCounted
const ThemeData = preload("res://ui/game_theme.tres")
const CardView = preload("res://ui/player_card.gd")
const INK := Color("112d21")
const IVORY := Color("efe9d9")
const BRASS := Color("b79a55")

class Paper:
	extends PanelContainer
	func _init() -> void:
		var box := StyleBoxEmpty.new()
		for side in ["left","right","top","bottom"]: box.set_content_margin(SIDE_LEFT if side == "left" else SIDE_RIGHT if side == "right" else SIDE_TOP if side == "top" else SIDE_BOTTOM,24)
		add_theme_stylebox_override("panel",box)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var polygon := PackedVector2Array([Vector2(1,1),Vector2(size.x-22,1),Vector2(size.x-1,22),size-Vector2.ONE,Vector2(1,size.y-1),Vector2(1,1)])
		draw_colored_polygon(polygon,IVORY)
		draw_polyline(polygon,BRASS,2,true)
		draw_rect(Rect2(10,10,size.x-20,size.y-20),Color(0.45,0.40,0.25,0.22),false,1)
		draw_arc(size/2, minf(size.x,size.y)*0.24,0,TAU,80,Color(0.45,0.40,0.25,0.12),1,true)
		# Native paper rules/grain remain quiet behind live text.
		for y in range(18,int(size.y)-12,19): draw_line(Vector2(12,y),Vector2(size.x-12,y),Color(0.45,0.40,0.25,0.025),1)

class Mark:
	extends Control
	var kind := "menu"
	var used := 0
	var country := "ENG"
	var ink := IVORY
	func _init() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if kind == "pips":
			for index in 3:
				var point := Vector2(10+index*26,size.y/2)
				if index < used: draw_circle(point,7,Color("ed7864"))
				draw_arc(point,7,0,TAU,24,ink,1.4,true)
		elif kind == "menu":
			for y in [6,14,22]: draw_line(Vector2(2,y),Vector2(29,y),ink,1.7,true)
		elif kind == "arrow":
			draw_line(Vector2(2,14),Vector2(28,14),ink,2,true)
			draw_polyline(PackedVector2Array([Vector2(19,5),Vector2(28,14),Vector2(19,23)]),ink,2,true)
		else:
			draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
			match country:
				"ENG":
					draw_rect(Rect2(size*Vector2(0.42,0),size*Vector2(0.16,1)),Color("c93c43"))
					draw_rect(Rect2(size*Vector2(0,0.4),size*Vector2(1,0.2)),Color("c93c43"))
				"FRA":
					draw_rect(Rect2(Vector2.ZERO,size*Vector2(0.333,1)),Color("285485"))
					draw_rect(Rect2(size*Vector2(0.667,0),size*Vector2(0.333,1)),Color("cb4345"))
				"BRA":
					draw_rect(Rect2(Vector2.ZERO,size),Color("31834e"))
					draw_colored_polygon(PackedVector2Array([size*Vector2(0.5,0.08),size*Vector2(0.93,0.5),size*Vector2(0.5,0.92),size*Vector2(0.07,0.5)]),Color("eed169"))
					draw_circle(size/2,size.y*0.24,Color("285485"))
				"JPN": draw_circle(size/2,size.y*0.3,Color("ca3d49"))
				"IDN": draw_rect(Rect2(Vector2.ZERO,size*Vector2(1,0.5)),Color("ca3d49"))
				"ARG":
					for y in [0.0,0.667]: draw_rect(Rect2(size*Vector2(0,y),size*Vector2(1,0.333)),Color("78b8d1"))
					draw_circle(size/2,size.y*0.1,BRASS)

static func label(parent: Node, value: String, pixels: int = 20, role: String = "Label", color: Color = IVORY) -> Label:
	var node := Label.new()
	node.text = value
	node.theme_type_variation = role
	node.add_theme_font_size_override("font_size",pixels)
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(node)
	return node

static func button(parent: Node, caption: String, id: String, action: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.name = id
	node.text = caption
	node.theme_type_variation = "Primary" if primary else "Button"
	node.custom_minimum_size.y = 46
	node.pressed.connect(action)
	parent.add_child(node)
	return node

static func column(parent: Node, separation: int = 16) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_constant_override("separation",separation)
	parent.add_child(node)
	return node

static func row(parent: Node, separation: int = 18) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation",separation)
	parent.add_child(node)
	return node

static func badge(parent: Node, library: RefCounted, club: String, pixels: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(library.badge_path(club))
	node.custom_minimum_size = Vector2.ONE*pixels
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(node)
	return node

static func card(parent: Node, library: RefCounted, id: String, width: float, font_scale: float, known: bool = true, owned: bool = false) -> Control:
	var node := CardView.new()
	node.font_scale = font_scale
	node.custom_minimum_size = Vector2(width,width*1.4)
	node.bind(library.cards[id],library.metadata(id),known,owned)
	parent.add_child(node)
	return node

static func focus_loop(parent: Node) -> void:
	var controls: Array[Control] = []
	collect(parent,controls)
	for index in controls.size():
		var current := controls[index]
		current.focus_next = current.get_path_to(controls[(index+1)%controls.size()])
		current.focus_previous = current.get_path_to(controls[posmod(index-1,controls.size())])
	if not controls.is_empty(): controls[0].grab_focus()

static func collect(node: Node, result: Array[Control]) -> void:
	if node is Control and node.visible and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled): result.append(node)
	for child in node.get_children(): collect(child,result)
