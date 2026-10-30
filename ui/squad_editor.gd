extends "res://ui/preparation.gd"
## Card-first private squad editing; only Apply reaches the save journal.
var field: Control
var popup: Control
var drawer_motion := preload("res://ui/motion.gd").Swap.new()

func label_at(value: String, rect: Rect2, pixels: int = 18, role: String = "Label", parent: Node = null) -> Label:
	var label := text(self if parent == null else parent,value,pixels,role)
	label.position=rect.position
	label.size=rect.size
	return label

func action(value: String, id: String, rect: Rect2, callback: Callable, primary: bool = false, parent: Node = null) -> Button:
	var button := Parts.button(self if parent == null else parent,value,id,callback,primary)
	button.position=rect.position
	button.size=rect.size
	return button

func rebuild_campaign() -> void:
	card_panel=null
	popup=null
	var plan: Resource=plans[team]
	label_at("OPPOSITION" if opponent_mode else "MY TEAM",Rect2(32,22,720,52),34,"Heading")
	action("Collection","OpenCollection",Rect2(1040,24,208,44),open_archive)
	var sidebar := preload("res://ui/glass_panel.gd").new()
	sidebar.position=Vector2(24,94)
	sidebar.size=Vector2(216,526)
	add_child(sidebar)
	var code: String=str(campaign_library.metadata(plan.cards[plan.starters[0]].card_id).get("country_code","")) if campaign_library != null else ""
	var country := TextureRect.new()
	country.texture=preload("res://ui/flags.gd").texture(code)
	country.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	country.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	country.position=Vector2(40,110)
	country.size=Vector2(64,44)
	country.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(country)
	label_at(scanning_name(),Rect2(40,166,184,42),20,"Team").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label_at(str(ceili(campaign_library.xi_rating(plan))),Rect2(40,210,128,72),54,"Score")
	label_at("OVR",Rect2(158,238,64,30),17,"Section")
	label_at(plan.formation,Rect2(40,286,176,38),28,"Team")
	label_at(plan.attack.capitalize()+" / "+plan.defence.replace("_"," ").capitalize(),Rect2(40,330,176,48),15).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	action("Game plan","TacticalDetails",Rect2(36,392,192,44),game_plan)
	if not opponent_mode:
		action("Auto build","AutoHighestOVR",Rect2(36,446,192,44),auto_build)
		action("Reserves","SquadReserves",Rect2(36,500,192,44),reserves)
	action("Team editing","TeamEditing",Rect2(36,554,192,44),team_editing)
	field=preload("res://ui/formation_preview.gd").new()
	field.name="LineupPitch"
	field.plan=plan
	field.card_library=campaign_library
	field.editable=true
	field.selected=inspection_slot
	field.slot_card_script=preload("res://ui/squad_slot_card.gd")
	field.squad_editor=self
	field.position=Vector2(260,84)
	field.size=Vector2(988,432)
	add_child(field)
	field.focus_mode=FOCUS_NONE
	field.mouse_filter=MOUSE_FILTER_IGNORE
	field.slot_selected.connect(select_slot)
	label_at("SUBSTITUTES",Rect2(280,514,600,28),16,"Section")
	var bench: Array=plan.bench_order
	for order in bench.size():
		var index: int=bench[order]
		var card := slot_card(index,-1,72)
		card.name="BenchCard"+str(index)
		card.position=Vector2(292+order*108,546)
		add_child(card)
	var divider := HSeparator.new()
	divider.position=Vector2(32,644)
	divider.size.x=1216
	add_child(divider)
	action("Back","PreparationBack",Rect2(32,660,148,44),func(): cancelled.emit())
	inspection=label_at("",Rect2(268,660,620,44),15)
	validation=label_at("",Rect2(268,636,690,24),14)
	start_button=action("Apply" if squad_mode else "Start match","ApplySquad" if squad_mode else "CommitMatch",Rect2(1008,660,240,44),func():
		if plans[0].errors().is_empty() and plans[1].errors().is_empty(): submitted.emit(plans[0].duplicate(true),plans[1].duplicate(true),knockout),true)
	update_validation()
	validation.text="" if start_button.disabled == false else validation.text
	Parts.focus_loop(self)

func scanning_name() -> String:
	return scouting.get_slice("\n",0).get_slice("  ",0)

func slot_card(index: int, slot: int, width: float) -> Control:
	var plan: Resource=plans[team]
	var card := preload("res://ui/squad_slot_card.gd").new()
	card.editor=self
	card.card_index=index
	card.slot=slot
	card.custom_minimum_size=Vector2(width,width*1.4)
	card.size=card.custom_minimum_size
	card.bind(plan.cards[index],campaign_library.metadata(plan.cards[index].card_id),true,not opponent_mode)
	card.pressed.connect(func(): player_actions(index,slot,card))
	return card

func select_slot(slot: int) -> void:
	inspection_slot=slot
	for index in field.card_views.size(): field.card_views[index].set_selected(index == slot)
	player_actions(plans[team].starters[slot],slot,field.card_views[slot])

func player_actions(index: int, slot: int, source: Control) -> void:
	if is_instance_valid(popup): popup.queue_free()
	var plan: Resource=plans[team]
	if slot >= 0: inspection_slot=slot
	popup=preload("res://ui/glass_panel.gd").new()
	popup.z_index=200
	var point := get_global_transform().affine_inverse()*source.get_global_rect().end
	popup.position=Vector2(clampf(point.x-24,248,1008),clampf(point.y-40,110,450))
	popup.size=Vector2(236,190 if slot >= 0 and not opponent_mode else 136)
	add_child(popup)
	label_at(plan.cards[index].display_name,Rect2(14,10,208,28),17,"BodyStrong",popup)
	action("Overview","PlayerOverview",Rect2(14,46,208,38),func(): popup.queue_free(); open_card(plan.cards[index]),false,popup)
	if not opponent_mode:
		action("Replace","ReplacePlayer",Rect2(14,90,208,38),func():
			popup.queue_free()
			if slot >= 0: reserves()
			else: assign_index(index,inspection_slot),false,popup)
		if slot >= 0:
			var bench_button := action("Send to bench","BenchPlayer",Rect2(14,136,208,38),func(): send_to_bench(slot),false,popup)
			bench_button.disabled=best_replacement(slot) < 0
	Parts.focus_loop(popup)

func can_assign(index: int, slot: int) -> bool:
	var plan: Resource=plans[team]
	if opponent_mode or index < 0 or index >= plan.cards.size() or slot < 0 or slot >= 11 or plan.cards[index].person_id in unavailable: return false
	var starters: Array=plan.starters.duplicate()
	var other := starters.find(index)
	if other >= 0: starters[other]=starters[slot]
	starters[slot]=index
	return "GK" in plan.cards[starters[0]].natural_roles

func assign_index(index: int, slot: int) -> void:
	if not can_assign(index,slot): return
	var plan: Resource=plans[team]
	var other: int=plan.starters.find(index)
	if other >= 0: plan.starters[other]=plan.starters[slot]
	plan.starters[slot]=index
	plan.refresh_bench_order()
	inspection_slot=slot
	rebuild()

func best_replacement(slot: int) -> int:
	var best := -1
	var plan: Resource=plans[team]
	for index in plan.cards.size():
		if index in plan.starters or not can_assign(index,slot): continue
		if best < 0 or plan.cards[index].rating(Lineup.ROLES[plan.formation][slot],true) > plan.cards[best].rating(Lineup.ROLES[plan.formation][slot],true): best=index
	return best

func send_to_bench(slot: int) -> void:
	var replacement := best_replacement(slot)
	if replacement >= 0: assign_index(replacement,slot)

func auto_build() -> void:
	if preload("res://squad/auto_lineup.gd").apply(plans[team],unavailable): rebuild()

func open_card_panel(panel: Control) -> void:
	var old: Control=card_panel
	card_panel=panel
	panel.reduced_motion=reduced_motion
	add_child(panel)
	panel.closed.connect(func(): if card_panel == panel: card_panel=null)
	drawer_motion.replace(old,panel,reduced_motion,Vector2.ZERO)

func make_drawer(title_text: String, wide: bool = false) -> Control:
	var drawer := preload("res://ui/matchday_drawer.gd").new()
	drawer.title=title_text
	if wide: drawer.panel_left=520; drawer.panel_width=760
	open_card_panel(drawer)
	return drawer

func reserves() -> void:
	var drawer := make_drawer("Reserves",true)
	var grid := GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",20)
	grid.add_theme_constant_override("v_separation",18)
	drawer.body.add_child(grid)
	var plan: Resource=plans[team]
	for index in plan.cards.size():
		if index in plan.starters: continue
		var card := slot_card(index,-1,154)
		card.name="ReserveCard"+str(index)
		grid.add_child(card)
	drawer.focus_contents()

func begin_player_drag() -> void:
	if is_instance_valid(popup): popup.hide()
	if is_instance_valid(card_panel): card_panel.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_instance_valid(card_panel) and not card_panel.visible:
		if get_viewport().gui_is_drag_successful(): card_panel.dismiss()
		else: card_panel.show()

func game_plan() -> void:
	var drawer := make_drawer("Game plan")
	var plan: Resource=plans[team]
	var formations := ["4-3-3","4-4-2","4-2-3-1"]
	choice(drawer.body,"Formation",formations,formations.find(plan.formation),func(index): plan.formation=formations[index])
	for field_name in ["attack","defence","route","late_risk"]:
		var values: Array={"attack":["possession","direct","counter"],"defence":["high_press","balanced","deep_block"],"route":["mixed","combinations","wide"],"late_risk":["none","trailing_attack","leading_caution"]}[field_name]
		choice(drawer.body,field_name.replace("_"," ").capitalize(),values,values.find(plan.get(field_name)),func(index): plan.set(field_name,values[index]))
	choice(drawer.body,"Width",["Narrow","Standard","Wide"],[0.85,1.0,1.15].find(plan.width),func(index): plan.width=[0.85,1.0,1.15][index])
	var done: Button=drawer.actions.get_child(0)
	done.text="Done"
	done.pressed.connect(func(): rebuild())
	lock_opponent(drawer)

func team_editing() -> void:
	var drawer := make_drawer("Team editing")
	Parts.button(drawer.body,"Captain and set pieces","PreparationSetPieces",set_pieces)
	Parts.button(drawer.body,"Substitutions","PreparationSubstitutions",substitution_settings)
	Parts.button(drawer.body,"Shootout order","ShootoutOrder",func():
		card_panel=null
		drawer.dismiss()
		shootout_order())

func set_pieces() -> void:
	var drawer := make_drawer("Captain and set pieces")
	var plan: Resource=plans[team]
	var names: Array=plan.starters.map(func(index): return plan.cards[index].display_name)
	for field_name in ["captain","free_kick_taker","corner_taker","penalty_taker"]:
		choice(drawer.body,field_name.replace("_"," ").capitalize(),names,plan.get(field_name),func(index): plan.set(field_name,index))
	Parts.button(drawer.body,"Shootout order","ShootoutOrder",func(): card_panel=null; drawer.dismiss(); shootout_order())
	lock_opponent(drawer)

func substitution_settings() -> void:
	var drawer := make_drawer("Substitutions")
	var values := ["fresh_legs","balanced","protect_shape"]
	var plan: Resource=plans[team]
	choice(drawer.body,"Timing",values,values.find(plan.substitution_plan),func(index): plan.substitution_plan=values[index])
	Parts.button(drawer.body,"Bench priority and pinned changes","BenchDetails",func(): card_panel=null; drawer.dismiss(); bench_details())
	lock_opponent(drawer)

func lock_opponent(drawer: Control) -> void:
	if opponent_mode:
		for node in drawer.find_children("*","OptionButton",true,false): node.disabled=true

func shootout_order() -> void:
	super.shootout_order()
	if is_instance_valid(card_panel): lock_opponent(card_panel)

func bench_details() -> void:
	super.bench_details()
	if is_instance_valid(card_panel): lock_opponent(card_panel)

func handle_cancel() -> bool:
	if is_instance_valid(popup): popup.queue_free(); popup=null; return true
	if is_instance_valid(card_panel):
		if card_panel.has_method("dismiss"): card_panel.dismiss()
		return true
	return false
