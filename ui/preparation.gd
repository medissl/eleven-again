extends ColorRect
## Native pre-match controls. Emits private plans; submitted matches never read these widgets.
signal submitted(home: Resource, away: Resource, knockout: bool)
signal cancelled
const Lineup = preload("res://squad/lineup.gd")
const Parts = preload("res://ui/campaign_parts.gd")
static var ThemeData: Theme = Parts.ThemeData
var plans: Array[Resource] = [Lineup.exhibition(0),Lineup.exhibition(1)]
var team := 0
var page := "lineup"
var body: HBoxContainer
var validation: Label
var start_button: Button
var inspection: Label
var ui_scale := 1.0
var knockout := false
var card_panel: Control
var reduced_motion := false
var campaign_mode := false
var campaign_library: RefCounted
var campaign_discoveries := {}
var home_name := ""
var scouting := ""
var inspection_slot := 0
var comparison_card: Resource
var squad_mode := false
var unavailable: Array = []
var opponent_mode := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = ThemeData
	color = ThemeData.get_color("forest","Palette")
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
	preload("res://ui/glass_panel.gd").decorate_screen(self)
	if campaign_mode:
		rebuild_campaign()
		return
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,30)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",12)
	margin.add_child(outer)
	text(outer,"MATCH PREPARATION" if campaign_mode else "EXHIBITION PREPARATION",36,"Heading")
	text(outer,scouting if campaign_mode else "Choose your XI and plan. All changes lock at kickoff.  3 active minutes · 1× / 2×",16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(HSeparator.new())
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation",26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	var left_scroll := ScrollContainer.new()
	left_scroll.follow_focus = true
	left_scroll.custom_minimum_size.x = 270
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(left_scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",5)
	left_scroll.add_child(left)
	if not campaign_mode:
		choice(left,"Team",["Meadow XI","Harbor XI"],team,func(index): team=index; rebuild())
		choice(left,"Fixture squad",["Standard","Specialists"],1 if plans[team].cards[0].person_id.begins_with("specialist_") else 0,func(index): plans[team]=Lineup.specialists() if index == 1 else Lineup.exhibition(team); rebuild())
	else: text(left,home_name,24,"Team")
	var plan = plans[team]
	if not campaign_mode: choice(left,"Match rules",["Exhibition draw","Knockout: ET and penalties"],1 if knockout else 0,func(index): knockout=index == 1)
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
	var catalogue_button := Button.new()
	catalogue_button.name = "OpenCollection" if campaign_mode else "OpenPlayerArchive"
	catalogue_button.text = "Collection" if campaign_mode else "Development catalogue"
	catalogue_button.pressed.connect(open_archive)
	tabs.add_child(catalogue_button)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
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
		text(rows,"RESERVES  "+", ".join(bench),15,"BodyStrong").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
					entries.append(plan.cards[index].display_name+"  "+plan.cards[index].primary_role)
					indices.append(index)
			choice(rows,plan.cards[plan.starters[slot]].display_name,entries,maxi(0,indices.find(plan.pinned_replacements.get(slot,-1))),func(index): plan.pinned_replacements[slot]=indices[index])
	inspection = text(right,"Select or focus a player to inspect base/effective ratings.",15)
	inspection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection.custom_minimum_size.y = 68
	if campaign_mode:
		var details := Button.new()
		details.name = "PreparationPlayerDetails"
		details.text = "Player details"
		details.pressed.connect(func(): open_card(plans[team].cards[plans[team].starters[inspection_slot]]))
		right.add_child(details)
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
	start_button.name = "CommitMatch"
	start_button.text = "Start match  →"
	start_button.theme_type_variation = "Primary"
	start_button.custom_minimum_size = Vector2(230,45)
	start_button.pressed.connect(func():
		if plans[0].errors().is_empty() and plans[1].errors().is_empty(): submitted.emit(plans[0].duplicate(true),plans[1].duplicate(true),knockout))
	footer.add_child(start_button)
	update_validation()
	var controls := find_children("*","BaseButton",true,false)
	for index in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[posmod(index-1,controls.size())])
	start_button.grab_focus()

func campaign_region(rect: Rect2, gap: int = 12) -> VBoxContainer:
	var node := Parts.column(self,gap)
	node.position = rect.position
	node.size = rect.size
	return node

func rebuild_campaign() -> void:
	var plan: Resource = plans[team]
	text(self,"Squad" if squad_mode else "Match preparation",34,"Heading").position = Vector2(32,100)
	var context := text(self,scouting.get_slice("\n",0),18)
	context.position = Vector2(32,152)
	context.size = Vector2(1216,30)
	context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	context.tooltip_text = scouting
	for index in 3:
		var section: String = ["lineup","set pieces","substitutions"][index]
		var tab := Parts.button(self,section.capitalize(),"Preparation"+section.to_pascal_case(),func(): page=section; rebuild(),page == section)
		tab.position = Vector2(32+index*196,194)
		tab.size = Vector2(180,44)
	var collection := Parts.button(self,"Collection","OpenCollection",open_archive)
	collection.position = Vector2(1080,100)
	collection.size = Vector2(168,44)
	var highest := Parts.button(self,"Highest OVR","AutoHighestOVR",func():
		if preload("res://squad/auto_lineup.gd").apply(plans[team],unavailable): rebuild()
		elif is_instance_valid(validation): validation.text="No legal available XI. Match preparation supplies temporary cover.")
	highest.position = Vector2(858,194)
	highest.size = Vector2(214,44)
	highest.tooltip_text = "Best legal XI by effective slot OVR. Formation and tactics stay unchanged."
	highest.visible = not opponent_mode
	if page == "lineup":
		var left := campaign_region(Rect2(48,264,212,296),4)
		var formations := ["4-3-3","4-4-2","4-2-3-1"]
		choice(left,"Formation",formations,formations.find(plan.formation),func(index): plan.formation=formations[index]; rebuild())
		for field in ["attack","defence","route"]:
			var entries: Array = {"attack":["possession","direct","counter"],"defence":["high_press","balanced","deep_block"],"route":["mixed","combinations","wide"]}[field]
			choice(left,field.capitalize(),entries,entries.find(plan.get(field)),func(index): plan.set(field,entries[index]); update_validation())
		choice(left,"Width",["Narrow","Standard","Wide"],[0.85,1.0,1.15].find(plan.width),func(index): plan.width=[0.85,1.0,1.15][index])
		var detail := Parts.button(self,"Tactical details","TacticalDetails",tactical_details)
		detail.position = Vector2(640,194)
		detail.size = Vector2(184,44)
		var preview = load("res://ui/formation_preview.gd").new()
		preview.name = "LineupPitch"
		preview.plan = plan
		preview.card_library = campaign_library
		preview.editable = true
		preview.selected = inspection_slot
		preview.position = Vector2(304,264)
		preview.size = Vector2(520,344)
		add_child(preview)
		preview.slot_selected.connect(func(slot): inspection_slot=slot; rebuild())
		text(self,"RESERVES",18,"BodyStrong").position = Vector2(864,252)
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(864,292)
		scroll.size = Vector2(384,230)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		add_child(scroll)
		var reserves := Parts.column(scroll,8)
		var role: String = Lineup.ROLES[plan.formation][inspection_slot]
		for index in plan.cards.size():
			if index in plan.starters: continue
			var card: Resource = plan.cards[index]
			var option := Parts.button(reserves,"%s   %s %d" % [card.display_name,card.primary_role,card.rating()],"Reserve%d" % index,func(): assign_player(index))
			option.clip_text = true
			option.disabled = role == "GK" and "GK" not in card.natural_roles
			option.tooltip_text = "%s\n%s slot %d (base %d)" % [card.display_name,role,card.rating(role,true),card.rating()]
		var picker := campaign_region(Rect2(864,536,384,72),4)
		var entries: Array = plan.cards.map(func(card): return card.display_name+"   "+card.primary_role)
		choice(picker,"Assign to "+role,entries,plan.starters[inspection_slot],assign_player)
	elif page == "set pieces":
		var rows := campaign_region(Rect2(32,264,730,340),12)
		var names: Array = plan.starters.map(func(index): return plan.cards[index].display_name)
		for field in ["captain","free_kick_taker","corner_taker","penalty_taker"]:
			var row := Parts.row(rows,20)
			text(row,field.replace("_"," ").capitalize(),19).custom_minimum_size.x = 260
			var option := OptionButton.new()
			option.name = field.to_pascal_case()
			option.custom_minimum_size = Vector2(430,44)
			for name_text in names: option.add_item(name_text)
			option.select(plan.get(field))
			option.item_selected.connect(func(index): plan.set(field,index))
			row.add_child(option)
		Parts.button(rows,"Shootout order","ShootoutOrder",shootout_order)
		var note := text(self,"Choose takers from your available squad.\nFallbacks still follow the committed match plan.",19)
		note.position = Vector2(820,396)
		note.size = Vector2(400,120)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		text(self,"Automatic substitution plan",26,"Heading").position = Vector2(32,266)
		for index in 3:
			var value: String = ["fresh_legs","balanced","protect_shape"][index]
			var panel := PanelContainer.new()
			panel.position = Vector2(32+index*414,336)
			panel.size = Vector2(390,224)
			panel.add_theme_stylebox_override("panel",preload("res://ui/matchday_theme.gd").box("panel-raised" if plan.substitution_plan == value else "panel"))
			add_child(panel)
			var tile := Parts.column(panel,24)
			var option := Parts.button(tile,["Early","Balanced","Late"][index],"SubPlan"+str(index),func(): plan.substitution_plan=value; rebuild(),plan.substitution_plan == value)
			option.custom_minimum_size.y = 76
			text(tile,["Earlier fresh legs","Default timing","Keep the starting shape longer"][index],18)
		var detail := Parts.button(self,"Bench priority and pinned changes","BenchDetails",bench_details)
		detail.position = Vector2(32,576)
		detail.size = Vector2(390,44)
	inspection = text(self,"",15)
	inspection.position = Vector2(304,610)
	inspection.size = Vector2(520,22)
	inspection.max_lines_visible = 1
	inspection.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	inspect(inspection_slot)
	var rule := HSeparator.new()
	rule.position = Vector2(32,636)
	rule.size.x = 1216
	add_child(rule)
	var back := Parts.button(self,"Back","PreparationBack",func(): cancelled.emit())
	back.position = Vector2(32,652)
	back.size = Vector2(148,44)
	validation = text(self,"",15)
	validation.position = Vector2(204,660)
	validation.size = Vector2(532,30)
	validation.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var details := Parts.button(self,"Player details","PreparationPlayerDetails",func(): open_card(plan.cards[plan.starters[inspection_slot]]))
	details.position = Vector2(776,652)
	details.size = Vector2(184,44)
	start_button = Parts.button(self,"Apply" if squad_mode else "Start match","ApplySquad" if squad_mode else "CommitMatch",func():
		if plans[0].errors().is_empty() and plans[1].errors().is_empty(): submitted.emit(plans[0].duplicate(true),plans[1].duplicate(true),knockout),true)
	start_button.position = Vector2(1008,652)
	start_button.size = Vector2(240,44)
	update_validation()
	if opponent_mode:
		for control in find_children("*","OptionButton",true,false): control.disabled=true
		for control in find_children("*","Slider",true,false): control.editable=false
	Parts.focus_loop(self)

func assign_player(index: int) -> void:
	if opponent_mode: open_card(plans[team].cards[index]); return
	var plan: Resource = plans[team]
	var previous: int = plan.starters[inspection_slot]
	var other: int = plan.starters.find(index)
	if other >= 0: plan.starters[other] = previous
	plan.starters[inspection_slot] = index
	plan.refresh_bench_order()
	rebuild()

func detail_drawer(title_text: String) -> Control:
	var drawer = load("res://ui/matchday_drawer.gd").new()
	drawer.title = title_text
	open_card_panel(drawer)
	drawer.actions.get_child(0).text = "Done"
	return drawer

func tactical_details() -> void:
	if is_instance_valid(card_panel): return
	var drawer = detail_drawer("Tactical details")
	var plan: Resource = plans[team]
	var entries := ["none","trailing_attack","leading_caution"]
	choice(drawer.body,"Late risk",entries,entries.find(plan.late_risk),func(index): plan.late_risk=entries[index])
	text(drawer.body,"Possession offers short support. Direct service arrives earlier. Counter uses space after recovery. High press advances the line and costs stamina; deep block protects the centre.",18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text(drawer.body,scouting,17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func shootout_order() -> void:
	if is_instance_valid(card_panel): return
	var drawer = detail_drawer("Shootout order")
	var plan: Resource = plans[team]
	var names: Array = plan.starters.map(func(index): return plan.cards[index].display_name)
	for order in 11:
		choice(drawer.body,str(order+1),names,plan.penalty_order[order],func(index):
			var previous: int = plan.penalty_order[order]
			var other: int = plan.penalty_order.find(index)
			plan.penalty_order[order] = index
			plan.penalty_order[other] = previous
			drawer.dismiss(); shootout_order())

func bench_details() -> void:
	if is_instance_valid(card_panel): return
	var drawer = detail_drawer("Bench plan")
	var plan: Resource = plans[team]
	text(drawer.body,"Maximum five changes in three windows. No re-entry. Auto chooses a suitable available reserve.",17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var reserves: Array = plan.bench_order.duplicate()
	var names: Array = reserves.map(func(index): return plan.cards[index].display_name)
	for order in reserves.size():
		choice(drawer.body,"Priority %d" % (order+1),names,reserves.find(plan.bench_order[order]),func(index):
			var other: int = plan.bench_order.find(reserves[index])
			var previous: int = plan.bench_order[order]
			plan.bench_order[order] = reserves[index]
			plan.bench_order[other] = previous
			drawer.dismiss(); bench_details())
	for slot in range(1,11):
		var choices: Array = ["Auto"]+names
		var indices: Array = [-1]+reserves
		choice(drawer.body,plan.cards[plan.starters[slot]].display_name,choices,maxi(0,indices.find(plan.pinned_replacements.get(slot,-1))),func(index): plan.pinned_replacements[slot]=indices[index])

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
	for card in plan.cards: select.add_item("%s  %s" % [card.display_name,card.primary_role] if campaign_mode else "%s  %s  %d" % [card.display_name,card.primary_role,card.rating()])
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
	if not campaign_mode:
		var inspect_button := Button.new()
		inspect_button.name = "OpenCardSlot%d" % slot
		inspect_button.text = "Card"
		inspect_button.tooltip_text = "Open player file"
		inspect_button.pressed.connect(func(): open_card(plan.cards[plan.starters[slot]]))
		row.add_child(inspect_button)
	var card = plan.cards[plan.starters[slot]]
	text(row,str(card.rating()) if card.rating() == card.rating(role,true) else "%d → %d" % [card.rating(),card.rating(role,true)],16).custom_minimum_size.x = 90

func inspect(slot: int) -> void:
	inspection_slot = slot
	var plan = plans[team]
	var card = plan.cards[plan.starters[slot]]
	var stat_text := ""
	for key in card.attributes: stat_text += "%s %d  " % [key,card.attributes[key]]
	if card.primary_role == "GK":
		for key in card.keeper_attributes: stat_text += "%s %d  " % [key,card.keeper_attributes[key]]
	var fit: int = card.rating(Lineup.ROLES[plan.formation][slot],true)
	inspection.text = "%s  Base %d%s\n%s\nTrait: %s" % [card.display_name,card.rating()," / slot %d (role penalty)" % fit if fit != card.rating() else "",stat_text,card.trait_id.replace("_"," ").capitalize() if not card.trait_id.is_empty() else "None"]
	if not card.trait_id.is_empty():
		var definition: Dictionary = card.Traits.catalogue[card.trait_id]
		inspection.text += "  "+("Available" if Lineup.ROLES[plan.formation][slot] in definition.positions else "Unavailable in this role")
		inspection.tooltip_text = definition.trigger+"\n"+definition.effect+"\nCounterplay: "+definition.counterplay

func update_validation() -> void:
	var errors: Array[String] = plans[0].errors()+plans[1].errors()
	validation.text = "Legal XI  tactics and substitutions lock at kickoff" if errors.is_empty() else "; ".join(errors)
	start_button.disabled = not errors.is_empty()

func open_card(card: Resource) -> void:
	if is_instance_valid(card_panel): return
	var inspector = load("res://ui/card_inspector.gd").new()
	inspector.definition = card
	if campaign_library != null: inspector.info = campaign_library.metadata(card.card_id)
	inspector.owned = true
	inspector.ui_scale = ui_scale
	if comparison_card != null and comparison_card != card:
		inspector.comparison = comparison_card
		var role: String = Lineup.ROLES[plans[team].formation][inspection_slot]
		if role in card.natural_roles and role in comparison_card.natural_roles: inspector.comparison_role=role
		if campaign_library != null: inspector.comparison_info = campaign_library.metadata(comparison_card.card_id)
	inspector.pin_requested.connect(func(_id): comparison_card=card)
	open_card_panel(inspector)

func open_archive() -> void:
	if is_instance_valid(card_panel): return
	var archive = load("res://ui/collection_screen.gd" if campaign_mode else "res://ui/player_archive.gd").new()
	if campaign_mode: archive.library=campaign_library; archive.discoveries=campaign_discoveries.duplicate(true)
	else: archive.ui_scale = ui_scale
	open_card_panel(archive)

func open_card_panel(panel: Control) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	card_panel = panel
	panel.reduced_motion = reduced_motion
	add_child(panel)
	panel.closed.connect(func():
		card_panel = null
		if is_instance_valid(focused): focused.grab_focus())

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(card_panel): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cancelled.emit()
