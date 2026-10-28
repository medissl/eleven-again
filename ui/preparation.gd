extends ColorRect
## Native pre-match controls. Emits private plans; submitted matches never read these widgets.
signal submitted(home: Resource, away: Resource, knockout: bool)
signal cancelled
const Lineup = preload("res://squad/lineup.gd")
const ThemeData = preload("res://ui/game_theme.tres")
var plans: Array[Resource] = [Lineup.exhibition(0),Lineup.exhibition(1)]
var team := 0
var page := "lineup"
var body: HBoxContainer
var validation: Label
var start_button: Button
var inspection: Label
var ui_scale := 1.0
var knockout := false

func _ready() -> void:
	theme = ThemeData
	color = Color("0c2117")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rebuild()

func text(parent: Node, value: String, pixels: int = 17, role: String = "Label") -> Label:
	var label := Label.new()
	label.text = value
	label.theme_type_variation = role
	label.add_theme_font_size_override("font_size",roundi(pixels*ui_scale))
	parent.add_child(label)
	return label

func choice(parent: Node, name_text: String, entries: Array, selected: int, changed: Callable) -> OptionButton:
	text(parent,name_text,15,"BodyStrong")
	var button := OptionButton.new()
	button.name = name_text.to_pascal_case()
	button.custom_minimum_size.y = 33
	for entry in entries: button.add_item(str(entry) if str(entry).begins_with("4-") else str(entry).replace("_"," ").capitalize())
	button.add_theme_font_size_override("font_size",roundi(16*ui_scale))
	button.select(selected)
	button.item_selected.connect(changed)
	parent.add_child(button)
	return button

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,30)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",12)
	margin.add_child(outer)
	text(outer,"EXHIBITION PREPARATION",36,"Heading")
	text(outer,"Choose your XI and plan. All changes lock at kickoff.  3 active minutes · 1× / 2×",16)
	outer.add_child(HSeparator.new())
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation",26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size.x = 270
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(left_scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",5)
	left_scroll.add_child(left)
	choice(left,"Team",["Meadow XI","Harbor XI"],team,func(index): team=index; rebuild())
	choice(left,"Fixture squad",["Standard","Specialists"],1 if plans[team].cards[0].person_id.begins_with("specialist_") else 0,func(index): plans[team]=Lineup.specialists() if index == 1 else Lineup.exhibition(team); rebuild())
	var plan = plans[team]
	choice(left,"Match rules",["Exhibition draw","Knockout: ET and penalties"],1 if knockout else 0,func(index): knockout=index == 1)
	var formations := ["4-3-3","4-4-2","4-2-3-1"]
	choice(left,"Formation",formations,formations.find(plan.formation),func(index): plan.formation=formations[index]; rebuild())
	for field in ["attack","defence","route","substitution_plan","late_risk"]:
		var entries: Array = {"attack":["possession","direct","counter"],"defence":["high_press","balanced","deep_block"],"route":["mixed","combinations","wide"],"substitution_plan":["balanced","fresh_legs","protect_shape"],"late_risk":["none","trailing_attack","leading_caution"]}[field]
		choice(left,field.replace("_"," ").capitalize(),entries,entries.find(plan.get(field)),func(index): plan.set(field,entries[index]); update_validation())
	choice(left,"Width",["Narrow","Standard","Wide"],[0.85,1.0,1.15].find(plan.width),func(index): plan.width=[0.85,1.0,1.15][index])
	var explanation := text(left,"Possession: short support. Direct: earlier forward service. Counter: depth after recovery. Press advances the line and costs stamina; a block protects the centre.",14)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(VSeparator.new())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var tabs := HBoxContainer.new()
	right.add_child(tabs)
	for section in ["lineup","set pieces","substitutions"]:
		var button := Button.new()
		button.text = section.capitalize()
		button.theme_type_variation = "Primary" if page == section else "Button"
		button.pressed.connect(func(): page=section; rebuild())
		tabs.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",7)
	scroll.add_child(rows)
	if page == "lineup":
		for slot in 11: lineup_row(rows,slot)
		var bench: Array[String] = []
		for index in plan.cards.size():
			if index not in plan.starters: bench.append(plan.cards[index].display_name)
		text(rows,"BENCH  ·  "+", ".join(bench),15,"BodyStrong")
	elif page == "set pieces":
		var names: Array[String] = []
		for slot in 11: names.append(plan.cards[plan.starters[slot]].display_name)
		for field in ["captain","free_kick_taker","corner_taker","penalty_taker"]:
			choice(rows,field.replace("_"," ").capitalize(),names,plan.get(field),func(index): plan.set(field,index))
		text(rows,"Penalty order — selecting a taker swaps their existing place",16,"BodyStrong")
		for order in 11:
			choice(rows,str(order+1),names,plan.penalty_order[order],func(index):
				var old: int = plan.penalty_order[order]
				var other: int = plan.penalty_order.find(index)
				plan.penalty_order[order] = index
				plan.penalty_order[other] = old
				rebuild())
	else:
		text(rows,"Pin replacements, or leave Auto. The first suitable reserve in bench order enters; used, unavailable or harmful replacements are skipped. Maximum five changes in three windows; no re-entry.",16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var reserve_names: Array = []
		var reserves: Array = plan.bench_order.duplicate()
		for index in reserves: reserve_names.append(plan.cards[index].display_name)
		for order in reserves.size():
			choice(rows,"Bench priority %d" % (order+1),reserve_names,reserves.find(plan.bench_order[order]),func(index):
				var other: int = plan.bench_order.find(reserves[index])
				var previous: int = plan.bench_order[order]
				plan.bench_order[order] = reserves[index]
				plan.bench_order[other] = previous
				rebuild())
		rows.add_child(HSeparator.new())
		for slot in range(1,11):
			var entries: Array = ["Auto"]
			var indices := [-1]
			for index in plan.cards.size():
				if index not in plan.starters:
					entries.append(plan.cards[index].display_name+" · "+plan.cards[index].primary_role)
					indices.append(index)
			choice(rows,plan.cards[plan.starters[slot]].display_name,entries,maxi(0,indices.find(plan.pinned_replacements.get(slot,-1))),func(index): plan.pinned_replacements[slot]=indices[index])
	inspection = text(right,"Select or focus a player to inspect base/effective ratings.",15)
	inspection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection.custom_minimum_size.y = 68
	outer.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",18)
	outer.add_child(footer)
	validation = text(footer,"",15)
	validation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): cancelled.emit())
	footer.add_child(back)
	start_button = Button.new()
	start_button.text = "Start match  →"
	start_button.theme_type_variation = "Primary"
	start_button.custom_minimum_size = Vector2(230,45)
	start_button.pressed.connect(func():
		if plans[0].errors().is_empty() and plans[1].errors().is_empty(): submitted.emit(plans[0].duplicate(true),plans[1].duplicate(true),knockout))
	footer.add_child(start_button)
	update_validation()
	start_button.grab_focus()

func lineup_row(parent: Node, slot: int) -> void:
	var plan = plans[team]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	parent.add_child(row)
	var role: String = Lineup.ROLES[plan.formation][slot]
	text(row,"%2d  %s" % [slot+1,role],18,"BodyStrong").custom_minimum_size.x = 75
	var select := OptionButton.new()
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.custom_minimum_size.y = 34
	select.add_theme_font_size_override("font_size",16)
	for card in plan.cards: select.add_item("%s  ·  %s  %d" % [card.display_name,card.primary_role,card.rating()])
	select.select(plan.starters[slot])
	select.item_selected.connect(func(index):
		var previous: int = plan.starters[slot]
		var other: int = plan.starters.find(index)
		if other >= 0: plan.starters[other] = previous
		plan.starters[slot] = index
		plan.refresh_bench_order()
		rebuild())
	select.focus_entered.connect(func(): inspect(slot))
	select.mouse_entered.connect(func(): inspect(slot))
	row.add_child(select)
	var card = plan.cards[plan.starters[slot]]
	text(row,"%d  →  %d" % [card.rating(),card.rating(role,true)],16).custom_minimum_size.x = 90

func inspect(slot: int) -> void:
	var plan = plans[team]
	var card = plan.cards[plan.starters[slot]]
	var stat_text := ""
	for key in card.attributes: stat_text += "%s %d  " % [key,card.attributes[key]]
	if card.primary_role == "GK":
		for key in card.keeper_attributes: stat_text += "%s %d  " % [key,card.keeper_attributes[key]]
	inspection.text = "%s · %s · Base %d / slot %d\n%s\nTrait: %s" % [card.display_name,card.tier().capitalize(),card.rating(),card.rating(Lineup.ROLES[plan.formation][slot],true),stat_text,card.trait_id.replace("_"," ").capitalize() if not card.trait_id.is_empty() else "None"]
	if not card.trait_id.is_empty():
		var definition: Dictionary = card.Traits.catalogue[card.trait_id]
		inspection.text += " · "+("Available" if Lineup.ROLES[plan.formation][slot] in definition.positions else "Unavailable in this role")
		inspection.tooltip_text = definition.trigger+"\n"+definition.effect+"\nCounterplay: "+definition.counterplay

func update_validation() -> void:
	var errors: Array[String] = plans[0].errors()+plans[1].errors()
	validation.text = "Legal XI · tactics and substitutions lock at kickoff" if errors.is_empty() else "; ".join(errors)
	start_button.disabled = not errors.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancelled.emit()
