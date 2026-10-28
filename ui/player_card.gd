extends Button
## One native 5:7 archive template. Definitions and portraits never contain rendered text.
const Catalogue = preload("res://content/catalogue.gd")
const CardData = preload("res://content/player_card.gd")
const MatchTheme = preload("res://ui/game_theme.tres")
const STYLES := {"bronze":["18352a","b8875e"],"silver":["18352a","b6c4bd"],"gold":["18352a","d9b95b"],"legend":["f0ead8","b69a54"],"unknown":["18221e","77796e"]}
var definition: Resource
var info: Dictionary = {}
var discovered := true
var owned := false
var font_scale := 1.0
var portrait: TextureRect
var content: Control
var status: Label
var ink := Color("f0ead8")
var accent := Color("b69a54")
var face := Color("18352a")

func _init() -> void:
	theme = MatchTheme
	custom_minimum_size = Vector2(240,336)
	focus_mode = Control.FOCUS_ALL
	toggle_mode = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	resized.connect(layout_card)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func bind(card: Resource, metadata: Dictionary = {}, known: bool = true, is_owned: bool = false) -> void:
	definition = card if known else null
	info = metadata.duplicate(true) if known else {}
	discovered = known
	owned = is_owned and known
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size = Vector2(300,420)
	add_child(content)
	var tier: String = definition.tier() if definition != null else "unknown"
	face = Color(STYLES[tier][0])
	accent = Color(STYLES[tier][1])
	ink = Color("18291f") if tier == "legend" else Color("f0ead8")
	put("%d" % definition.rating() if definition != null else "?",Rect2(23,12,86,69),58,"Score")
	put(definition.primary_role if definition != null else "—",Rect2(25,76,65,28),24,"Score")
	put(str(info.get("version_label","FICTIONAL")) if definition != null else "",Rect2(112,19,160,26),12,"Label",HORIZONTAL_ALIGNMENT_RIGHT)
	status = put("",Rect2(118,48,154,20),10,"BodyStrong",HORIZONTAL_ALIGNMENT_RIGHT)
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(60,39)
	portrait.size = Vector2(192,192)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = Catalogue.portrait(definition,info)
	content.add_child(portrait)
	put(tier.to_upper() if definition != null else "UNDISCOVERED",Rect2(27,230,213,23),16,"Score",HORIZONTAL_ALIGNMENT_LEFT,Color("18291f"))
	var names: Array = split_name(definition.display_name) if definition != null else ["PLAYER ARCHIVE","UNDISCOVERED"]
	put(names[0].to_upper(),Rect2(24,260,251,19),12)
	put(names[1].to_upper(),Rect2(24,278,252,34),32,"Score")
	put(str(info.get("country_code","Fictional"))+"  /  "+definition.primary_role if definition != null else "Identity not discovered",Rect2(24,313,251,21),12)
	var ability: String = CardData.Traits.catalogue[definition.trait_id].name if definition != null and not definition.trait_id.is_empty() else ("No signature trait" if definition != null else "—")
	put(ability,Rect2(24,343,252,25),14)
	var keys: Array = ["REF","HAN","POS","DIV","KIC","PHY"] if definition != null and definition.primary_role == "GK" else CardData.STATS
	for index in 6:
		var x := 24+(index%3)*87
		var y := 369+(index/3)*23
		put(keys[index],Rect2(x,y,34,21),11)
		var value: String = "—"
		if definition != null:
			value = str(int(definition.attributes[keys[index]] if keys[index] in CardData.STATS else definition.keeper_attributes[keys[index]]))
		put(value,Rect2(x+34,y-3,43,25),24,"Score",HORIZONTAL_ALIGNMENT_RIGHT)
	tooltip_text = definition.display_name+" Â· "+str(info.get("version_label","Fictional"))+" Â· "+tier.capitalize()+" Â· "+ability if definition != null else "Undiscovered player"
	for property in get_property_list():
		if property.name == "accessibility_name": set("accessibility_name",tooltip_text)
	set_selected(button_pressed)
	layout_card()

func put(value: String, rect: Rect2, pixels: int, role: String = "Label", alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, tint: Color = Color(-1,-1,-1)) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = role
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	var font := MatchTheme.get_font("font",role)
	var fitted := roundi(pixels*font_scale)
	while fitted > 8 and font.get_height(fitted) > rect.size.y: fitted -= 1
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > rect.size.x:
		fitted = maxi(roundi(pixels*0.65),floori(fitted*rect.size.x/font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x))
	label.add_theme_font_size_override("font_size",fitted)
	label.add_theme_color_override("font_color",ink if tint.r < 0 else tint)
	content.add_child(label)
	return label

static func split_name(full_name: String) -> Array[String]:
	var words := full_name.split(" ",false)
	var cut := words.size()-1
	while cut > 0 and words[cut-1].to_lower() in ["van","von","der","de","da","del","di","dos","do"]: cut -= 1
	return [" ".join(words.slice(0,cut))," ".join(words.slice(cut))]

func set_selected(value: bool) -> void:
	set_pressed_no_signal(value)
	if is_instance_valid(status): status.text = "SELECTED" if value else ("UNAVAILABLE" if disabled else ("OWNED" if owned else ("KNOWN" if definition != null else "")))
	queue_redraw()

func layout_card() -> void:
	if not is_instance_valid(content): return
	var factor := minf(size.x/300,size.y/420)
	content.scale = Vector2.ONE*factor
	content.position = (size-Vector2(300,420)*factor)/2
	var global_scale := content.get_global_transform().get_scale().x
	var physical_pixels := 96*maxi(1,roundi(192*global_scale/96))
	var portrait_size := physical_pixels/maxf(0.01,global_scale)
	if portrait_size > 216: portrait_size = 192
	portrait.size = Vector2.ONE*portrait_size
	portrait.position = Vector2(156-portrait_size/2,231-portrait_size)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(content): return
	draw_set_transform(content.position,0,content.scale)
	var polygon := PackedVector2Array([Vector2(0,0),Vector2(278,0),Vector2(300,22),Vector2(300,420),Vector2(0,420)])
	draw_colored_polygon(polygon,face.lightened(0.04) if is_hovered() and not disabled else face)
	polygon.append(polygon[0])
	draw_polyline(polygon,accent,1.5,true)
	draw_line(Vector2(10,8),Vector2(10,412),accent,1,true)
	draw_arc(Vector2(156,137),87,0,TAU,64,Color(accent,0.17),1,true)
	if portrait.texture == null:
		draw_circle(Vector2(156,127),33,Color(ink,0.13))
		draw_arc(Vector2(156,215),61,PI,TAU,32,Color(ink,0.13),42,true)
	draw_rect(Rect2(18,231,264,21),accent)
	var tier: String = definition.tier() if definition != null else "unknown"
	for index in (2 if tier == "silver" else 1): draw_line(Vector2(242,240+index*4),Vector2(272,240+index*4),face,1,true)
	if tier == "gold":
		for x in range(244,275,7): draw_line(Vector2(x,246),Vector2(x+4,237),face,1,true)
	if tier == "legend": draw_line(Vector2(258,234),Vector2(258,250),face,1,true)
	draw_line(Vector2(24,338),Vector2(276,338),accent,1,true)
	if button_pressed or has_focus(): draw_polyline(PackedVector2Array([Vector2(3,3),Vector2(277,3),Vector2(297,23),Vector2(297,417),Vector2(3,417),Vector2(3,3)]),ink,2,true)
	draw_set_transform(Vector2.ZERO)
