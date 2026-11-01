extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Glass = preload("res://ui/glass_panel.gd")
const Lineup = preload("res://squad/lineup.gd")
static func copy(app, parent: Node, value: String, rect: Rect2, pixels: int = 20, role: String = "Label") -> Label:
	var label: Label = app.text(parent,value,pixels,role)
	label.position = rect.position
	label.size = rect.size
	return label
static func panel(parent: Node, rect: Rect2) -> Control:
	var surface := Glass.new()
	surface.position = rect.position
	surface.size = rect.size
	parent.add_child(surface)
	return surface
static func action(app, parent: Node, value: String, id: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var button: Button = app.button(parent,value,id,callback,primary)
	button.position = rect.position
	button.size = rect.size
	return button
static func main(app) -> void:
	var preview: Dictionary = app.session.preview()
	var data: Dictionary = app.session.controller.snapshot()
	copy(app,app.screen,"ELEVEN\nAGAIN",Rect2(48,42,600,188),64,"Heading")
	var entries := []
	if not preview.is_empty(): entries.append(["CONTINUE","ContinueRun",func(): if app.session.reload().ok: app.route()])
	entries.append(["PLAY" if preview.is_empty() else "NEW RUN","NewRun",func(): app.render("origin")])
	if not data.is_empty() and data.step == "prepare": entries.append(["SQUAD","HomeSquad",app.squad])
	entries.append_array([["COLLECTION","Collection",func(): app.render("collection")],["RECORDS","Records",func(): app.render("records")],["SETTINGS","MainSettings",app.settings],["QUIT","QuitGame",func(): app.get_tree().quit()]])
	for index in entries.size():
		var entry: Array = entries[index]
		var item := MenuAction.new()
		item.name=entry[1]; item.caption=entry[0]; item.primary=index == 0
		item.position=Vector2(48,278+index*54); item.size=Vector2(376,50)
		item.pressed.connect(entry[2])
		app.screen.add_child(item)
	var stage := Podium.new()
	stage.position=Vector2(600,156); stage.size=Vector2(648,478)
	stage.has_cards=not preview.is_empty()
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	app.screen.add_child(stage)
	if not preview.is_empty():
		copy(app,app.screen,app.library.countries[preview.origin].name.to_upper(),Rect2(650,94,598,48),32,"Team")
		copy(app,app.screen,"%d / 12    %s" % [preview.wins,app.money(preview.cash)],Rect2(654,148,440,34),23,"Score")
		var pips := Parts.Mark.new()
		pips.kind="pips"; pips.used=preview.defeats; pips.position=Vector2(1136,150); pips.size=Vector2(86,30)
		app.screen.add_child(pips)
		for index in preview.best_cards.size():
			var card: Control = Parts.card(app.screen,app.library,preview.best_cards[index],236,1.0,true,true)
			card.position=Vector2(670+index*286,242-index*28); card.size=Vector2(236,330.4)
			card.pressed.connect(func(): app.inspect(preview.best_cards[index]))

class MenuAction:
	extends Button
	var caption := ""
	var primary := false
	func _init() -> void:
		set_meta("game_control",true)
		for state in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	func _ready() -> void:
		tooltip_text=caption.capitalize()
		for property in get_property_list():
			if property.name == "accessibility_name": set("accessibility_name",caption)
	func _draw() -> void:
		var active: bool = is_hovered() or (has_focus() and get_viewport().get_meta("keyboard_navigation",false))
		if primary or active:
			draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(size.x-12,0),Vector2(size.x,12),size,Vector2(0,size.y)]),Color(0.06,0.22,0.30,0.75 if active else 0.45))
			draw_line(Vector2(0,2),Vector2(0,size.y-2),Color("8BEDFF"),3,true)
		var font := preload("res://ui/typography.gd").face("Bold" if primary else "SemiBold")
		draw_string(font,Vector2(22,35),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,29 if primary else 24,Color("F1F7FB") if primary or active else Color("A8BBCB"))
		if primary or active: draw_polyline(PackedVector2Array([Vector2(size.x-30,18),Vector2(size.x-22,25),Vector2(size.x-30,32)]),Color("8BEDFF"),2,true)

class Podium:
	extends Control
	var has_cards := false
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(74,0),Vector2(188,0),Vector2(334,460),Vector2(154,460)]),Color(0.2,0.7,0.9,0.035))
		draw_colored_polygon(PackedVector2Array([Vector2(572,0),Vector2(476,0),Vector2(314,460),Vector2(484,460)]),Color(0.2,0.7,0.9,0.035))
		draw_set_transform(Vector2(324,444),0,Vector2(1,0.22))
		draw_circle(Vector2.ZERO,252,Color(0.01,0.035,0.06,0.82))
		draw_arc(Vector2.ZERO,250,0,TAU,80,Color("3A8497"),2,true)
		draw_set_transform(Vector2.ZERO)
		if has_cards: return
		var ink := Color("DAE9EE")
		var gold := Color("BBA87B")
		draw_colored_polygon(PackedVector2Array([Vector2(248,116),Vector2(400,116),Vector2(382,236),Vector2(342,276),Vector2(306,276),Vector2(266,236)]),Color("172E3D"))
		draw_polyline(PackedVector2Array([Vector2(248,116),Vector2(400,116),Vector2(382,236),Vector2(342,276),Vector2(306,276),Vector2(266,236),Vector2(248,116)]),ink,3,true)
		for side in [-1,1]:
			var x: float = 324+side*82
			draw_polyline(PackedVector2Array([Vector2(x,138),Vector2(x+side*38,146),Vector2(x+side*30,218),Vector2(x-side*12,238)]),gold,5,true)
		draw_line(Vector2(324,276),Vector2(324,348),ink,12,true)
		draw_colored_polygon(PackedVector2Array([Vector2(286,348),Vector2(362,348),Vector2(378,374),Vector2(270,374)]),gold)
		draw_rect(Rect2(266,374,116,32),Color("142B3A"))
		draw_line(Vector2(266,374),Vector2(382,374),ink,2,true)
static func board(app, _outer: Node) -> void:
	load("res://ui/campaign_road.gd").build(app)
