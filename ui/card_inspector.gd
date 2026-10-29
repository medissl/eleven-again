extends ColorRect
signal closed
signal pin_requested(card_id: String)
const CardView = preload("res://ui/player_card.gd")
static var ThemeData: Theme = preload("res://ui/matchday_theme.gd").build()
var definition: Resource
var info: Dictionary = {}
var comparison: Resource
var comparison_info: Dictionary = {}
var comparison_role := ""
var ui_scale := 1.0
var reduced_motion := false
var closing := false
var owned := false
var entrance: Tween

func label(parent: Node, value: String, pixels: int = 18, role: String = "Label") -> Label:
	var node := Label.new()
	node.text = value
	node.theme_type_variation = role
	node.add_theme_font_size_override("font_size",roundi(pixels*ui_scale))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(node)
	return node

func _ready() -> void:
	theme = ThemeData
	color = ThemeData.get_color("forest","Palette")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if comparison != null:
		build_comparison()
		return
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",16)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	label(header,"PLAYER FILE",32,"Heading").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.name = "CloseFile"
	back.text = "Back"
	back.pressed.connect(dismiss)
	header.add_child(back)
	outer.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	for entry in ([[definition,info],[comparison,comparison_info]] if comparison != null else [[definition,info]] if definition != null else []):
		var frame := CenterContainer.new()
		frame.custom_minimum_size.x = 300
		body.add_child(frame)
		var view := CardView.new()
		view.font_scale = ui_scale
		view.custom_minimum_size = Vector2(300,420)
		view.bind(entry[0],entry[1],entry[0] != null,owned and entry[0] == definition)
		view.focus_mode = Control.FOCUS_NONE
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(view)
	var scroll := ScrollContainer.new()
	scroll.name = "FileDetails"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",12)
	scroll.add_child(details)
	if definition == null:
		label(details,"UNDISCOVERED",32,"Heading")
		label(details,"This edition has not been discovered.")
	else:
		label(details,definition.display_name,32,"Heading")
		var pin := Button.new()
		pin.text = "Pin comparison"
		pin.name = "PinComparison"
		pin.pressed.connect(func(): pin_requested.emit(definition.card_id))
		details.add_child(pin)
		label(details,str(info.get("country_name","Fictional player"))+"  "+str(info.get("version_label","Fictional"))+"  "+str(info.get("career_pool","Exhibition")))
		label(details,"%d OVR  %s  %s" % [definition.rating(),definition.primary_role,definition.tier().capitalize()],22,"Score")
		label(details,"Base attributes  match role and fatigue adjustments apply separately.",13)
		label(details,"Natural: "+", ".join(definition.natural_roles)+"\nFamiliar: "+(", ".join(definition.familiar_roles) if not definition.familiar_roles.is_empty() else "None"),14)
		if comparison != null: label(details,"Changes versus "+comparison.display_name+"  "+str(comparison_info.get("version_label","Fictional")),14,"BodyStrong")
		stats(details,"OUTFIELD",definition.attributes,comparison.attributes if comparison != null else {})
		stats(details,"GOALKEEPING",definition.keeper_attributes,comparison.keeper_attributes if comparison != null else {})
		if definition.primary_role != "GK": label(details,"Emergency outfield keeping uses the 35 baseline.",13)
		details.add_child(HSeparator.new())
		if not definition.trait_id.is_empty():
			var ability: Dictionary = definition.Traits.catalogue[definition.trait_id]
			label(details,ability.name,26,"Score")
			label(details,"Automatic  implemented  "+", ".join(ability.positions),13,"BodyStrong")
			label(details,"Trigger: "+ability.trigger+"\nEffect: "+ability.effect+"\nCounterplay: "+ability.counterplay,18)
			label(details,"3 uses in regulation; +1 in extra time. 10′ cooldown. Activation: %d stamina. Shared attribute bonus cap: +6." % int(ability.parameters.get("activation_stamina_cost",2)),13)
			if definition.trait_id in ["penalty_composure","cat_reflexes"]: label(details,"Shootout: one opportunity per kick, using its separate shootout allowance.",13)
		else: label(details,"No signature trait. Ordinary football actions remain available.",15)
		label(details,"Original provisional game ratings. Portraits are modular likeness studies.",13)
		if info.has("identity_reference_id"):
			label(details,"Source: "+str(info.get("reference_title",info.identity_reference_id))+"\n"+str(info.get("reference_note",info.get("reference_scope","").replace("_"," "))),13)
			var address: String = info.get("reference_url","")
			if address.begins_with("https://"):
				var link := LinkButton.new()
				link.focus_mode = Control.FOCUS_ALL
				link.text = "Open identity reference"
				link.pressed.connect(func(): OS.shell_open(address))
				details.add_child(link)
	preload("res://ui/campaign_parts.gd").focus_loop(self)
	if not reduced_motion:
		modulate.a = 0
		entrance = create_tween()
		entrance.tween_property(self,"modulate:a",1,0.12)

func build_comparison() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(1280,720)
	canvas.scale = Vector2.ONE*minf(size.x/1280,size.y/720)
	canvas.position = (size-canvas.size*canvas.scale)/2
	add_child(canvas)
	var heading := label(canvas,"Compare players",34,"Heading")
	heading.name = "ComparisonHeading"
	heading.position = Vector2(32,100)
	heading.size = Vector2(1216,44)
	var subtitle := label(canvas,"Compare base ratings. Match effects remain separate.",18)
	subtitle.position = Vector2(32,152)
	subtitle.size = Vector2(1216,32)
	for index in 2:
		var view := CardView.new()
		view.custom_minimum_size = Vector2(280,392)
		view.size = view.custom_minimum_size
		view.position = Vector2(220+index*560,206)
		view.bind(definition if index == 0 else comparison,info if index == 0 else comparison_info,true)
		view.focus_mode = Control.FOCUS_NONE
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(view)
	var symbol := TextureRect.new()
	symbol.texture = load("res://assets/ui/matchday/icons/compare.svg")
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.position = Vector2(606,266)
	symbol.size = Vector2(48,48)
	canvas.add_child(symbol)
	var context := label(canvas,comparison_role+" slot" if not comparison_role.is_empty() else definition.primary_role+"     "+comparison.primary_role,23,"Team")
	context.position = Vector2(538,352)
	context.size = Vector2(210,40)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var difference := label(canvas,"Different primary roles" if definition.primary_role != comparison.primary_role else "Same primary role\nBase ratings only",18)
	if not comparison_role.is_empty():
		var before: int = comparison.rating(comparison_role,true)
		var after: int = definition.rating(comparison_role,true)
		difference.text = "%d → %d\n%+d effective OVR" % [before,after,after-before]
	difference.position = Vector2(526,410)
	difference.size = Vector2(236,80)
	difference.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note := label(canvas,"Compared player → selected player in the chosen lineup slot." if not comparison_role.is_empty() else "A slot upgrade requires a selected, legal lineup role.",16)
	note.position = Vector2(32,652)
	note.size = Vector2(880,32)
	var close := Button.new()
	close.name = "CloseFile"
	close.text = "Close comparison"
	close.theme_type_variation = "Primary"
	close.position = Vector2(1008,652)
	close.size = Vector2(240,44)
	close.pressed.connect(dismiss)
	canvas.add_child(close)
	preload("res://ui/campaign_parts.gd").focus_loop(self)

func stats(parent: Node, title: String, values: Dictionary, versus: Dictionary) -> void:
	label(parent,title,13,"BodyStrong")
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	parent.add_child(grid)
	for key in values:
		var key_label := label(grid,key,13)
		key_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		key_label.custom_minimum_size = Vector2(34,26)
		var value := str(int(values[key]))
		if not versus.is_empty():
			var delta: int = values[key]-versus[key]
			value += " (%+d)" % delta
		var number := label(grid,value,20,"Score")
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.custom_minimum_size = Vector2(90 if not versus.is_empty() else 40,26)

func dismiss() -> void:
	if closing: return
	closing = true
	if is_instance_valid(entrance): entrance.kill()
	if not reduced_motion:
		var leave := create_tween()
		leave.tween_property(self,"modulate:a",0,0.09)
		await leave.finished
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
