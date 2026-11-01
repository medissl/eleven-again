extends ColorRect
signal closed
const CardView = preload("res://ui/player_card.gd")
static var ThemeData: Theme = preload("res://ui/matchday_theme.gd").build()
var definition: Resource
var info: Dictionary = {}
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
	preload("res://ui/glass_panel.gd").decorate_screen(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",16)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	label(header,"PLAYER OVERVIEW",32,"Heading").size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	for entry in ([[definition,info]] if definition != null else []):
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
		var identity := HBoxContainer.new()
		details.add_child(identity)
		label(identity,definition.display_name,32,"Heading").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label(details,str(info.get("country_name","Fictional player"))+"  /  "+str(info.get("version_label","Exhibition")),20)
		label(details,"%d OVR  %s  %s" % [definition.rating(),definition.primary_role,str(info.get("tier",definition.tier())).capitalize()],22,"Score")
		if not info.get("run_training",[]).is_empty():
			label(details,"RUN TRAINING  "+" / ".join(info.run_training.map(func(row): return "%s %d→%d" % [row.stat,row.before,row.after])),17)
		label(details,"Positions  "+" / ".join(definition.natural_roles)+( "    Secondary  "+" / ".join(definition.familiar_roles) if not definition.familiar_roles.is_empty() else ""),18)
		if definition.primary_role == "GK": stats(details,"GOALKEEPING",definition.keeper_attributes)
		stats(details,"OUTFIELD",definition.attributes)
		if definition.primary_role != "GK": stats(details,"GOALKEEPING",definition.keeper_attributes)
		details.add_child(HSeparator.new())
		if not definition.trait_id.is_empty():
			var ability: Dictionary = definition.Traits.catalogue[definition.trait_id]
			label(details,ability.name,26,"Score")
			label(details,ability.effect,20)
			label(details,"Activates: "+ability.trigger+"\nCounter: "+ability.counterplay,18)
			label(details,"3 uses  /  10′ cooldown  /  %d stamina\n+1 use in extra time. Shared attribute bonus cap +6." % int(ability.parameters.get("activation_stamina_cost",2)),17)
			if definition.trait_id in ["penalty_composure","cat_reflexes"]: label(details,"Shootout: one opportunity per kick, using its separate shootout allowance.",13)
		else: label(details,"No signature trait. Ordinary football actions remain available.",15)
		if info.has("identity_reference_id"):
			label(details,"Identity reference: "+str(info.get("reference_title",info.identity_reference_id))+"\n"+str(info.get("reference_note",info.get("reference_scope","").replace("_"," "))),16)
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

func stats(parent: Node, title: String, values: Dictionary) -> void:
	label(parent,title,18,"BodyStrong")
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	parent.add_child(grid)
	for key in values:
		var key_label := label(grid,key,18,"BodyStrong")
		key_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		key_label.custom_minimum_size = Vector2(48,34)
		var value := str(int(values[key]))
		var number := label(grid,value,28,"Score")
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.custom_minimum_size = Vector2(64,38)

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
