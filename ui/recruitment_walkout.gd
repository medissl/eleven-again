extends Control
signal completed
var definition: Resource
var info: Dictionary
var audio: Node
var reduced := false
var effects_enabled := true
var newly_discovered := false
var age := 0.0
var reveal_index := -1
var finished := false
var canvas: Control
var tunnel: Control
var headline: Label
var flag: TextureRect
var card: Control
var confirm: Button
var skip: Button
var pitch: TextureRect
var caption: Label
var shade: ColorRect
var atmosphere: Control
var ability_icon: TextureRect
const REVEAL_TIME := 12.0
const CONFIRM_TIME := 13.7

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	theme = preload("res://ui/matchday_theme.gd").build()
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	resized.connect(layout)
	layout()
	pitch = TextureRect.new()
	pitch.texture = preload("res://assets/ui/arcade/field.png")
	pitch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pitch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pitch.size = Vector2(1280,720)
	pitch.modulate = Color.WHITE
	pitch.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(pitch)
	tunnel = TextureRect.new()
	tunnel.texture = preload("res://assets/ui/arcade/tunnel.png")
	var motion_material := ShaderMaterial.new()
	motion_material.shader = preload("res://assets/ui/premium/tunnel_motion.gdshader")
	tunnel.material = motion_material
	tunnel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tunnel.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tunnel.pivot_offset=Vector2(640,310)
	tunnel.mouse_filter=MOUSE_FILTER_IGNORE
	tunnel.size = Vector2(1280,720)
	canvas.add_child(tunnel)
	shade = ColorRect.new()
	shade.size = Vector2(1280,720)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(shade)
	atmosphere = Atmosphere.new()
	atmosphere.size = Vector2(1280,720)
	atmosphere.ink = Color("9B58AC") if definition.tier() == "legend" else Color("FFF4D2")
	canvas.add_child(atmosphere)
	caption = Label.new()
	caption.position = Vector2(160,104)
	caption.size = Vector2(960,32)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",18)
	caption.modulate = Color("A8C8BF")
	canvas.add_child(caption)
	headline = Label.new()
	headline.position = Vector2(180,250)
	headline.size = Vector2(920,126)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	headline.theme_type_variation = "Heading"
	headline.add_theme_font_override("font",preload("res://ui/typography.gd").face("Bold"))
	headline.add_theme_font_size_override("font_size",112)
	headline.add_theme_color_override("font_outline_color",Color("101827"))
	headline.add_theme_constant_override("outline_size",2)
	headline.add_theme_color_override("font_shadow_color",Color("10182700"))
	headline.add_theme_constant_override("shadow_offset_y",3)
	headline.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(headline)
	flag = TextureRect.new()
	flag.texture = preload("res://ui/flags.gd").texture(str(info.get("country_code","")))
	flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.position=Vector2(574,172); flag.size=Vector2(132,88)
	flag.mouse_filter=MOUSE_FILTER_IGNORE
	canvas.add_child(flag)
	ability_icon = TextureRect.new()
	if not definition.trait_id.is_empty(): ability_icon.texture = preload("res://ui/ability_icons.gd").texture(definition.trait_id)
	ability_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ability_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ability_icon.position = Vector2(600,174)
	ability_icon.size = Vector2(80,80)
	ability_icon.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(ability_icon)
	card = preload("res://ui/player_card.gd").new()
	card.bind(definition,info,true,true)
	card.position=Vector2(487,174); card.size=Vector2(306,428.4); card.custom_minimum_size=card.size
	card.pivot_offset=card.size/2
	card.focus_mode=FOCUS_NONE
	card.mouse_filter=MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	for child in card.content.get_children():
		if child is BaseButton: child.focus_mode=FOCUS_NONE; child.mouse_filter=MOUSE_FILTER_IGNORE
	confirm = button("Confirm","WalkoutConfirm",Rect2(1056,28,192,48),confirm_player)
	skip = button("Skip intro","SkipWalkout",Rect2(1080,28,168,44),skip_intro)
	skip.theme_type_variation = "Quiet"
	confirm.hide()
	confirm.focus_next=confirm.get_path_to(confirm)
	confirm.focus_previous=confirm.get_path_to(confirm)
	skip.focus_next=skip.get_path_to(skip)
	skip.focus_previous=skip.get_path_to(skip)
	skip.grab_focus()
	card.hide()
	flag.hide()
	ability_icon.hide()
	if is_instance_valid(audio): audio.set_walkout(true)
	if reduced: skip_intro()

func layout() -> void:
	canvas.scale=Vector2.ONE*minf(size.x/1280,size.y/720)
	canvas.position=(size-canvas.size*canvas.scale)/2
func button(value: String, id: String, rect: Rect2, callback: Callable) -> Button:
	var node := Button.new()
	node.name=id; node.text=value; node.position=rect.position; node.size=rect.size
	node.theme_type_variation="Primary"
	node.pressed.connect(callback)
	canvas.add_child(node)
	preload("res://ui/motion.gd").bind_control(node,func(): return reduced)
	return node
func skip_intro() -> void:
	age=maxf(age,CONFIRM_TIME)
	_process(0)
func confirm_player() -> void:
	if finished or age < CONFIRM_TIME: return
	finished=true
	if is_instance_valid(audio): audio.play("confirm",-11); audio.set_walkout(false)
	completed.emit()
func _process(delta: float) -> void:
	if finished: return
	age += delta
	var travel := 1.0 if reduced else smoothstep(1.5,10.6,age)
	var rush := 1.0 if reduced else smoothstep(10.6,REVEAL_TIME,age)
	tunnel.scale=Vector2.ONE*lerpf(lerpf(1,1.85,travel),4.8,rush)
	tunnel.modulate.a=1-smoothstep(11.5,12.2,age)
	tunnel.self_modulate = Color.WHITE*lerpf(0.08,1.0,smoothstep(0.6,2.5,age))
	tunnel.self_modulate.a = 1
	tunnel.material.set_shader_parameter("rush",0.0 if reduced else sin(rush*PI))
	pitch.pivot_offset=Vector2(640,400)
	pitch.scale=Vector2.ONE*(1.0 if reduced else lerpf(1.13,1,smoothstep(REVEAL_TIME,8.0,age)))
	var reveal := -1 if age < 2.2 else 0 if age < 5.0 else 1 if age < 7.8 else 2 if age < 10.6 else -2 if age < REVEAL_TIME else 3
	if reveal != reveal_index:
		reveal_index=reveal
		if is_instance_valid(audio) and reveal >= 0: audio.reveal_sting(4.0 if reveal == 3 else 1.4)
		if reveal == 3 and definition.tier() == "legend" and not reduced:
			card.reveal_flash=1
			card.legend_reveal=true
			card.set_process(true)
	if is_instance_valid(audio): audio.walkout_energy = 1.0 if reveal == 3 else lerpf(0.1,0.95,rush) if reveal == -2 else clampf(age/14.0,0.08,0.75)
	shade.color = Color(0.04,0.08,0.06,0.10 if reduced else lerpf(1.0,0.24,smoothstep(0.3,2.5,age)))
	if reveal == -2: shade.color.a = lerpf(0.72,0.10,rush)
	atmosphere.age = age
	atmosphere.reduced = reduced
	atmosphere.effects_enabled = effects_enabled
	atmosphere.queue_redraw()
	caption.text = "POSITION" if reveal == 0 else "NATION" if reveal == 1 else "PLAYSTYLE" if reveal == 2 else definition.display_name.to_upper() if reveal == 3 else ""
	headline.visible = reveal >= 0
	headline.text = definition.primary_role if reveal == 0 else str(info.get("country_name",info.get("country_code",""))).to_upper() if reveal == 1 else str(definition.Traits.catalogue[definition.trait_id].name).to_upper() if reveal == 2 and not definition.trait_id.is_empty() else "ALL-ROUND" if reveal == 2 else ("LEGEND DISCOVERED" if newly_discovered else "LEGEND SIGNED") if definition.tier() == "legend" else "PLAYER SIGNED"
	flag.visible = reveal == 1
	ability_icon.visible = reveal == 2
	card.visible = reveal == 3
	var was_ready := confirm.visible
	confirm.visible = age >= CONFIRM_TIME
	if confirm.visible and not was_ready: confirm.grab_focus()
	skip.visible = not confirm.visible
	if reveal == 3:
		headline.position=Vector2(80,610); headline.size=Vector2(1120,52)
		headline.add_theme_font_size_override("font_size",30)
		caption.position.y = 100
		var amount := 1.0 if reduced else clampf((age-REVEAL_TIME)/0.9,0,1)
		var overshoot := 1+2.70158*pow(amount-1,3)+1.70158*pow(amount-1,2)
		card.scale=Vector2.ONE*lerpf(0.72,1,overshoot)
		card.rotation = 0 if reduced else lerpf(-0.06,0,smoothstep(0,0.7,amount))
		card.modulate.a = 1 if reduced else clampf(amount*4,0,1)
		headline.modulate.a = 1 if reduced else smoothstep(0.2,0.9,amount)
	elif reveal >= 0:
		headline.position=Vector2(100,280); headline.size=Vector2(1080,132)
		headline.add_theme_font_size_override("font_size",112 if reveal == 0 else 76 if reveal == 1 else 56)
		var part: float = age-[2.2,5.0,7.8][reveal]
		headline.modulate.a=1 if reduced else minf(clampf(part/0.6,0,1),clampf((2.8-part)/0.4,0,1))
		headline.scale = Vector2.ONE*(1.0 if reduced else lerpf(1.05,1,smoothstep(0,0.5,part)))
		flag.modulate.a = headline.modulate.a
		ability_icon.modulate.a = headline.modulate.a

class Atmosphere:
	extends Control
	var age := 0.0
	var reduced := false
	var effects_enabled := true
	var ink := Color("FFF4D2")
	func _init() -> void: mouse_filter = MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,20),Color("03070D"))
		draw_rect(Rect2(0,700,1280,20),Color("03070D"))
		if reduced or not effects_enabled: return
		if age < 10.6: return
		if age < REVEAL_TIME: return
		var time := age-REVEAL_TIME
		var fade := clampf(1-time/2.5,0,1)
		draw_set_transform(Vector2(640,604))
		pass # No glossy pool of light; pixel confetti marks the reveal.
		for index in 72:
			var phase := index*2.399963
			var point := Vector2(cos(phase)*(100+index*5)*minf(1,time*2),-250-time*(120+index%9*12)+time*time*115-index%11*15)
			var spin := phase+time*(2+index%5)
			var axis := Vector2.from_angle(spin)*Vector2(3.0,2.0+sin(time*4+phase))
			var side := axis.orthogonal()*0.55
			var color := Color.WHITE if index%3 == 0 else ink if index%3 == 1 else Color("F5CE65")
			draw_colored_polygon(PackedVector2Array([point-axis-side,point+axis-side,point+axis+side,point-axis+side]),Color(color,fade))
		draw_set_transform(Vector2.ZERO)
func _exit_tree() -> void:
	if is_instance_valid(audio): audio.set_walkout(false)
