extends Control
signal completed
var definition: Resource
var info: Dictionary
var audio: Node
var reduced := false
var newly_discovered := false
var age := 0.0
var stage := 0
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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	theme = preload("res://ui/matchday_theme.gd").build()
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	resized.connect(layout)
	layout()
	pitch = TextureRect.new()
	pitch.texture = preload("res://assets/ui/premium/walkout-field.png")
	pitch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pitch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pitch.size = Vector2(1280,720)
	pitch.modulate = Color(0.75,0.85,1.0)
	pitch.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(pitch)
	tunnel = TextureRect.new()
	tunnel.texture = preload("res://assets/ui/premium/walkout-tunnel.png")
	tunnel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	tunnel.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tunnel.pivot_offset=Vector2(640,310)
	tunnel.mouse_filter=MOUSE_FILTER_IGNORE
	tunnel.size = Vector2(1280,720)
	canvas.add_child(tunnel)
	headline = Label.new()
	headline.position = Vector2(180,250)
	headline.size = Vector2(920,126)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	headline.theme_type_variation = "Heading"
	headline.add_theme_font_size_override("font_size",64)
	headline.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(headline)
	flag = TextureRect.new()
	flag.texture = preload("res://ui/flags.gd").texture(str(info.get("country_code","")))
	flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.position=Vector2(590,176); flag.size=Vector2(100,74)
	flag.mouse_filter=MOUSE_FILTER_IGNORE
	canvas.add_child(flag)
	card = preload("res://ui/player_card.gd").new()
	card.bind(definition,info,true,true)
	card.position=Vector2(505,200); card.size=Vector2(270,378); card.custom_minimum_size=card.size
	card.pivot_offset=card.size/2
	card.focus_mode=FOCUS_NONE
	card.mouse_filter=MOUSE_FILTER_IGNORE
	canvas.add_child(card)
	confirm = button("Confirm","WalkoutConfirm",Rect2(520,646,240,48),confirm_player)
	skip = button("Skip intro","SkipWalkout",Rect2(1080,28,168,44),skip_intro)
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
func skip_intro() -> void: age=5.8
func confirm_player() -> void:
	if stage == 0:
		stage=1
		headline.text="PLAYER RECRUITED"
		headline.position=Vector2(100,70); headline.size=Vector2(1080,80)
		headline.add_theme_font_size_override("font_size",46)
		confirm.text="Continue"
		confirm.name="WalkoutContinue"
		skip.hide()
		if is_instance_valid(audio): audio.play("confirm",-11)
	elif not finished:
		finished=true
		if is_instance_valid(audio): audio.set_walkout(false)
		completed.emit()
func _process(delta: float) -> void:
	age += delta
	var travel := 1.0 if reduced else smoothstep(0.0,4.6,age)
	tunnel.scale=Vector2.ONE*lerpf(1,2.8,travel)
	tunnel.modulate.a=1-smoothstep(3.5,4.8,age)
	pitch.pivot_offset=Vector2(640,400)
	pitch.scale=Vector2.ONE*lerpf(1,1.04,smoothstep(3.5,5.4,age))
	var reveal := 0 if age < 1.6 else 1 if age < 2.7 else 2 if age < 3.8 else 3
	if reveal != reveal_index:
		reveal_index=reveal
		if is_instance_valid(audio) and stage == 0: audio.reveal_sting(3.0 if reveal == 3 else 0.85)
	if stage == 1: return
	headline.text = definition.primary_role if reveal == 0 else str(info.get("country_name",info.get("country_code",""))) if reveal == 1 else str(definition.Traits.catalogue[definition.trait_id].name) if reveal == 2 and not definition.trait_id.is_empty() else "ALL-ROUND" if reveal == 2 else ("LEGEND DISCOVERED" if newly_discovered else "LEGEND SIGNED") if definition.tier() == "legend" else "SIGNED"
	flag.visible = reveal == 1
	card.visible = reveal == 3
	confirm.visible = age >= 5.2
	if reveal == 3:
		headline.position=Vector2(80,62); headline.size=Vector2(1120,80)
		headline.add_theme_font_size_override("font_size",42)
		var amount := 1.0 if reduced else smoothstep(3.8,4.5,age)
		card.scale=Vector2.ONE*lerpf(0.42,1,amount)
		card.modulate.a=amount
		if definition.tier() == "legend" and age < 4.5:
			card.reveal_flash=1
			card.legend_reveal=true
			card.set_process(true)
	else:
		var part := age if reveal == 0 else age-1.6 if reveal == 1 else age-2.7
		var length := 1.6 if reveal == 0 else 1.1
		headline.modulate.a=1 if reduced else minf(clampf(part/0.18,0,1),clampf((length-part)/0.18,0,1))
	if reveal == 3: headline.modulate.a=1
func _exit_tree() -> void:
	if is_instance_valid(audio): audio.set_walkout(false)
