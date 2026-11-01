extends Button
## One native 5:7 archive template. Definitions and portraits never contain rendered text.
const Catalogue = preload("res://content/catalogue.gd")
const CardData = preload("res://content/player_card.gd")
static var MatchTheme: Theme = preload("res://ui/matchday_theme.gd").build()
const FrameStyle = preload("res://ui/card_style.gd")
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
var reveal_flash := 0.0
var legend_reveal := false

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
	ready.connect(layout_card)
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
	face = Color("101827")
	accent = Color(FrameStyle.PALETTES[tier][0])
	ink = Color("FFF4D2")
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
	put(names[0].to_upper() if definition != null else "",Rect2(24,257,251,17),12)
	put(names[1].to_upper(),Rect2(24,275,252,30),30,"Score")
	var ability: String = CardData.Traits.catalogue[definition.trait_id].name if definition != null and not definition.trait_id.is_empty() else ("No signature trait" if definition != null else "—")
	if definition != null and not definition.trait_id.is_empty():
		var badge := preload("res://ui/ability_badge.gd").new()
		badge.ability = CardData.Traits.catalogue[definition.trait_id]
		badge.position = Vector2(242,72)
		badge.size = Vector2(36,36)
		content.add_child(badge)
	if definition != null:
		var flag := TextureRect.new()
		flag.texture = preload("res://ui/flags.gd").texture(str(info.get("country_code","")))
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.position = Vector2(24,112)
		flag.size = Vector2(32,24)
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(flag)
	var keys: Array = ["REF","HAN","POS","DIV","KIC","PHY"] if definition != null and definition.primary_role == "GK" else CardData.STATS
	for index in 6:
		var x := 24+int(index/3)*136
		var y := 311+(index%3)*33
		put(keys[index],Rect2(x,y,40,34),20,"BodyStrong")
		var value: String = "—"
		if definition != null:
			value = str(int(definition.attributes[keys[index]] if keys[index] in CardData.STATS else definition.keeper_attributes[keys[index]]))
		put(value,Rect2(x+41,y-1,74,38),36,"Score",HORIZONTAL_ALIGNMENT_RIGHT)
	tooltip_text = "  ".join([definition.display_name,str(info.get("version_label","Fictional")),tier.capitalize(),ability]) if definition != null else "Undiscovered player"
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
	if value and not button_pressed:
		reveal_flash = 0.7
		legend_reveal = false
		set_process(true)
	set_pressed_no_signal(value)
	if is_instance_valid(status): status.text = "SELECTED" if value else ("UNAVAILABLE" if disabled else "")
	queue_redraw()

func _process(delta: float) -> void:
	reveal_flash = maxf(0,reveal_flash-delta*1.6)
	queue_redraw()
	if reveal_flash == 0: set_process(false)

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
	FrameStyle.paint(self)
