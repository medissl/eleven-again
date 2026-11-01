extends Control
signal closed
const Parts = preload("res://ui/campaign_parts.gd")
const Inspector = preload("res://ui/card_inspector.gd")
var library: RefCounted
var discoveries := {}
var reduced_motion := false
var inspection: Control
var pinned_id := ""
var query := ""
var role := ""
var tier := ""
var known_only := false
var page := 0
var results: Array = []
var tiles: Array[Control] = []
var filter_panel: Control
var body: Control
var grid: Control
var search: LineEdit
var page_label: Label
var discovery_label: Label

func _ready() -> void:
	theme = Parts.ThemeData
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_chrome()
	refresh()

func label(value: String, rect: Rect2, pixels: int = 18, style: String = "Label") -> Label:
	var node := Parts.label(body,value,pixels,style)
	node.position = rect.position
	node.size = rect.size
	return node

func button(value: String, id: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var node := Parts.button(body,value,id,callback,primary)
	node.position = rect.position
	node.size = rect.size
	return node

func build_chrome() -> void:
	body = Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	label("ELEVEN AGAIN",Rect2(32,20,600,32),23,"Team")
	button("Back","CollectionBack",Rect2(1136,16,112,44),func(): closed.emit(); queue_free())
	label("Collection",Rect2(32,100,600,48),34,"Heading")
	discovery_label = label("",Rect2(32,152,600,28),18)
	search = LineEdit.new()
	search.name = "CollectionSearch"
	search.placeholder_text = "Search discovered players"
	search.text = query
	search.position = Vector2(768,110)
	search.size = Vector2(292,44)
	body.add_child(search)
	search.text_submitted.connect(func(value): query=value.strip_edges(); page=0; refresh())
	button("Search","CollectionSearchApply",Rect2(1068,110,84,44),func(): query=search.text.strip_edges(); page=0; refresh())
	button("Filter","CollectionFilter",Rect2(1160,110,88,44),filters)
	button("All cards","CollectionAll",Rect2(32,186,134,44),func(): known_only=false; query=""; role=""; tier=""; page=0; refresh(),not known_only)
	button("Discovered","AcquiredOnly",Rect2(178,186,152,44),func(): known_only=true; page=0; refresh(),known_only)
	button("Previous","CollectionPrevious",Rect2(904,650,134,44),func(): page-=1; refresh())
	page_label = label("",Rect2(1040,658,76,32))
	button("Next","CollectionNext",Rect2(1128,650,120,44),func(): page+=1; refresh())
	grid = Control.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = MOUSE_FILTER_IGNORE
	body.add_child(grid)

func refresh() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	discovery_label.text = "Discovered %d / %d" % [discoveries.size(),library.recruits.size()]
	search.text = query
	body.get_node("CollectionAll").theme_type_variation = "Button" if known_only else "Primary"
	body.get_node("AcquiredOnly").theme_type_variation = "Primary" if known_only else "Button"
	results = visible_cards()
	var pages := maxi(1,ceili(results.size()/12.0))
	page = posmod(page,pages)
	page_label.text = "%d / %d" % [page+1,pages]
	tiles.clear()
	for index in mini(12,results.size()-page*12):
		var card: Resource = results[page*12+index]
		var known: bool = discoveries.has(card.card_id)
		var tile: Control
		if known: tile = Parts.card(grid,library,card.card_id,128,1.0,true)
		else:
			tile = Button.new()
			tile.custom_minimum_size = Vector2(128,179.2)
			grid.add_child(tile)
			for image in [["components/card-back.svg",Rect2(0,0,128,179.2)],["components/portrait-anonymous.svg",Rect2(26,24,76,76)]]:
				var art := TextureRect.new()
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art.texture = load("res://assets/ui/matchday/"+image[0])
				art.position = image[1].position
				art.size = image[1].size
				art.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tile.add_child(art)
			var caption := Parts.label(tile,"Undiscovered",13)
			caption.position = Vector2(8,144)
			caption.size = Vector2(112,24)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.name = "KnownEdition_"+card.card_id if known else "UnknownEdition_"+str(index)
		tile.position = Vector2(32+(index%6)*204,248+int(index/6)*196)
		(tile as BaseButton).pressed.connect(func(): open_file(card.card_id if known else ""))
		tile.tooltip_text = "Open acquired version" if known else "Undiscovered version. Recruit a player during a run to reveal it."
		tiles.append(tile)
	for index in tiles.size():
		for pair in [["focus_neighbor_left",index-1],["focus_neighbor_right",index+1],["focus_neighbor_top",index-6],["focus_neighbor_bottom",index+6]]:
			if pair[1] >= 0 and pair[1] < tiles.size(): tiles[index].set(pair[0],tiles[index].get_path_to(tiles[pair[1]]))
	if results.is_empty():
		var empty := Parts.label(grid,"No discovered players match. Clear search or filters.",22)
		empty.position = Vector2(32,272)
	Parts.focus_loop(body)

func visible_cards() -> Array:
	var filtered := known_only or not query.is_empty() or not role.is_empty() or not tier.is_empty()
	var result: Array = []
	for card in library.recruits:
		if filtered:
			if not discoveries.has(card.card_id): continue
			if not query.is_empty() and not card.display_name.to_lower().contains(query.to_lower()): continue
			if not role.is_empty() and role not in card.natural_roles: continue
			if not tier.is_empty() and card.tier() != tier: continue
		result.append(card)
	# Anonymous, stable album order; hidden identity never influences UI search/counts.
	result.sort_custom(func(a,b): return a.card_id.sha256_text() < b.card_id.sha256_text())
	return result

func open_file(id: String) -> void:
	if is_instance_valid(inspection): return
	var focused := get_viewport().gui_get_focus_owner()
	inspection = Inspector.new()
	if not id.is_empty() and discoveries.has(id):
		inspection.definition = library.cards[id]
		inspection.info = library.metadata(id)
		if not pinned_id.is_empty() and pinned_id != id:
			inspection.comparison = library.cards[pinned_id]
			inspection.comparison_info = library.metadata(pinned_id)
	inspection.reduced_motion = reduced_motion
	inspection.pin_requested.connect(func(card_id): if discoveries.has(card_id): pinned_id=card_id)
	add_child(inspection)
	inspection.closed.connect(func(): inspection=null; if is_instance_valid(focused): focused.grab_focus())

func filters() -> void:
	if is_instance_valid(filter_panel): return
	var cover := ColorRect.new()
	cover.color = Color("111A16F5")
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filter_panel = cover
	add_child(cover)
	var box := VBoxContainer.new()
	box.position = Vector2(816,174)
	box.size = Vector2(432,420)
	box.add_theme_constant_override("separation",16)
	cover.add_child(box)
	Parts.label(box,"Filter discovered cards",28,"Heading")
	var choices := []
	for field in ["role","tier"]:
		Parts.label(box,field.capitalize(),18)
		var option := OptionButton.new()
		option.add_item("All")
		var values: Array[String] = []
		for card in library.recruits:
			if not discoveries.has(card.card_id): continue
			for value in (card.natural_roles if field == "role" else [card.tier()]):
				if value not in values: values.append(value)
		values.sort()
		for value in values: option.add_item(value)
		option.select(values.find(role if field == "role" else tier)+1)
		choices.append(option)
		box.add_child(option)
	var finish := func(): filter_panel.queue_free(); filter_panel=null; body.get_node("CollectionFilter").grab_focus()
	Parts.button(box,"Apply","ApplyCollectionFilter",func(): role=choices[0].get_item_text(choices[0].selected) if choices[0].selected > 0 else ""; tier=choices[1].get_item_text(choices[1].selected) if choices[1].selected > 0 else ""; page=0; finish.call(); refresh(),true)
	Parts.button(box,"Clear","ClearCollectionFilter",func(): role=""; tier=""; query=""; page=0; finish.call(); refresh())
	Parts.button(box,"Close","CloseCollectionFilter",finish)
	Parts.focus_loop(cover)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE): return
	if is_instance_valid(inspection): return
	get_viewport().set_input_as_handled()
	if is_instance_valid(filter_panel): filter_panel.queue_free(); filter_panel=null; body.get_node("CollectionFilter").grab_focus()
	else: closed.emit(); queue_free()
