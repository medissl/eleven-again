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
	Parts.brand(app.screen,Vector2(440,190)).position=Vector2(36,44)
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
		draw_set_transform(Vector2(0,2 if is_pressed() else 0))
		var active: bool = is_hovered() or (has_focus() and get_viewport().get_meta("keyboard_navigation",false))
		if primary or active:
			draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(size.x-12,0),Vector2(size.x,12),size,Vector2(0,size.y)]),Color("31596A") if active else Color("233A50"))
			draw_line(Vector2(0,2),Vector2(0,size.y-2),Color("F5CE65"),4,false)
		var font := preload("res://ui/typography.gd").face("Bold" if primary else "SemiBold")
		draw_string(font,Vector2(22,35),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,29 if primary else 24,Color("FFF4D2") if primary or active else Color("A8C8BF"))
		if primary or active: draw_polyline(PackedVector2Array([Vector2(size.x-30,18),Vector2(size.x-22,25),Vector2(size.x-30,32)]),Color("FFF4D2"),2,true)

static func board(app, _outer: Node) -> void:
	load("res://ui/campaign_road.gd").build(app)
