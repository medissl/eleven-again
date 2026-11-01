extends ColorRect
signal closed
const Catalogue = preload("res://content/catalogue.gd")
const CardView = preload("res://ui/player_card.gd")
const Inspector = preload("res://ui/card_inspector.gd")
static var ThemeData: Theme = preload("res://ui/matchday_theme.gd").build()
const PAGE_SIZE := 6
var catalogue := Catalogue.new()
var ui_scale := 1.0
var reduced_motion := false
var role := ""
var tier := ""
var pool := ""
var order := "name"
var page := 0
var selected_id := ""
var pinned_id := ""
var results: Array[Resource] = []
var grid: GridContainer
var search: LineEdit
var count: Label
var page_label: Label
var pin: Button
var previous: Button
var next: Button
var tiles: Array[Control] = []
var inspection: Control
var inspect_button: Button

func text(parent: Node, value: String, pixels: int, variation: String = "Label") -> Label:
	var node := Label.new()
	node.text = value
	node.theme_type_variation = variation
	node.add_theme_font_size_override("font_size",roundi(pixels*ui_scale))
	parent.add_child(node)
	return node

func button(parent: Node, value: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.add_theme_font_size_override("font_size",roundi(16*ui_scale))
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func filter(parent: Node, title: String, entries: Array, action: Callable) -> void:
	var node := OptionButton.new()
	node.name = title
	node.tooltip_text = title
	node.add_theme_font_size_override("font_size",roundi(16*ui_scale))
	for entry in entries: node.add_item(str(entry))
	node.item_selected.connect(action)
	parent.add_child(node)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = ThemeData
	color = Color("101827")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+edge,24)
	add_child(margins)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",14)
	margins.add_child(outer)
	var heading := HBoxContainer.new()
	outer.add_child(heading)
	text(heading,"PLAYER ARCHIVE",36,"Heading").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(heading,"Back",dismiss).name = "ArchiveBack"
	text(outer,"%d authored editions · %d Modern / %d Retired · choose a card to inspect" % [catalogue.cards.size(),catalogue.query("","","","Modern").size(),catalogue.query("","","","Retired").size()],14)
	outer.add_child(HSeparator.new())
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation",10)
	outer.add_child(filters)
	search = LineEdit.new()
	search.name = "SearchPlayers"
	search.placeholder_text = "Search player, country or edition"
	search.add_theme_font_size_override("font_size",roundi(16*ui_scale))
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.x = 230
	search.text_changed.connect(func(_value): refresh())
	filters.add_child(search)
	var roles := ["All roles","GK","CB","LB","RB","DM","CM","AM","LW","RW","ST"]
	filter(filters,"Role",roles,func(index): role="" if index == 0 else roles[index]; refresh())
	var tiers := ["All tiers","Bronze","Silver","Gold","Legend"]
	filter(filters,"Tier",tiers,func(index): tier="" if index == 0 else tiers[index].to_lower(); refresh())
	filter(filters,"Pool",["Both pools","Modern","Retired"],func(index): pool=["","Modern","Retired"][index]; refresh())
	filter(filters,"Sort",["Name A–Z","Highest OVR"],func(index): order="name" if index == 0 else "rating"; refresh())
	button(filters,"Clear",clear_filters).name = "ClearFilters"
	count = text(outer,"",13,"BodyStrong")
	var scroll := ScrollContainer.new()
	scroll.name = "ArchiveCards"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	outer.add_child(scroll)
	var center := HBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(center)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",24)
	grid.add_theme_constant_override("v_separation",24)
	center.add_child(grid)
	outer.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",14)
	outer.add_child(footer)
	previous = button(footer,"← Previous",func(): change_page(-1))
	page_label = text(footer,"",14)
	next = button(footer,"Next →",func(): change_page(1))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(space)
	pin = button(footer,"Pin selected to compare",pin_selected)
	inspect_button = button(footer,"Inspect selected",func(): inspect(selected_id))
	inspect_button.name = "InspectSelected"
	refresh()
	search.grab_focus()

func refresh() -> void:
	page = 0
	results = catalogue.query(search.text,role,tier,pool,order)
	show_page()

func clear_filters() -> void:
	search.text = ""
	role = ""
	tier = ""
	pool = ""
	order = "name"
	for title in ["Role","Tier","Pool","Sort"]: (find_child(title,true,false) as OptionButton).select(0)
	refresh()
	search.grab_focus()

func change_page(delta: int) -> void:
	page = clampi(page+delta,0,maxi(0,ceili(results.size()/float(PAGE_SIZE))-1))
	show_page()

func show_page() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	tiles.clear()
	var pages := maxi(1,ceili(results.size()/float(PAGE_SIZE)))
	count.text = "%d matching editions · browsing does not change your squad" % results.size()
	page_label.text = "%d / %d" % [page+1,pages]
	previous.disabled = page == 0
	next.disabled = page >= pages-1
	if not catalogue.errors.is_empty(): text(grid,"Catalogue unavailable: "+"; ".join(catalogue.errors),16)
	elif results.is_empty():
		selected_id = ""
		text(grid,"No matching editions. Try another search or clear the filters.",17)
	else:
		for index in range(page*PAGE_SIZE,mini((page+1)*PAGE_SIZE,results.size())):
			var card: Resource = results[index]
			var tile := CardView.new()
			tile.name = "Card_"+card.card_id
			tile.font_scale = ui_scale
			tile.custom_minimum_size = Vector2(270,378)
			tile.bind(card,catalogue.metadata(card.card_id))
			tile.focus_entered.connect(func(): select(card.card_id))
			tile.pressed.connect(func(): select(card.card_id); inspect(card.card_id))
			grid.add_child(tile)
			tiles.append(tile)
		if not tiles.any(func(tile): return tile.definition.card_id == selected_id): selected_id = results[page*PAGE_SIZE].card_id
	select(selected_id)
	(find_child("ArchiveCards",true,false) as ScrollContainer).scroll_vertical = 0

func select(card_id: String) -> void:
	selected_id = card_id
	for tile in tiles: tile.set_selected(tile.definition.card_id == card_id)
	pin.disabled = selected_id.is_empty() and pinned_id.is_empty()
	inspect_button.disabled = selected_id.is_empty()
	pin.text = "Clear comparison: "+catalogue.by_id[pinned_id].display_name if not pinned_id.is_empty() else "Pin selected to compare"
	var back := find_child("ArchiveBack",true,false) as Button
	var clear := find_child("ClearFilters",true,false) as Button
	for control in [inspect_button,pin,next,previous,clear]: control.focus_next = NodePath("")
	var last: Control = inspect_button if not inspect_button.disabled else (pin if not pin.disabled else clear)
	back.focus_previous = back.get_path_to(last)
	last.focus_next = last.get_path_to(back)

func pin_selected() -> void:
	pinned_id = selected_id if pinned_id.is_empty() else ""
	select(selected_id)

func inspect(card_id: String) -> void:
	if is_instance_valid(inspection) or not catalogue.by_id.has(card_id): return
	var focused := get_viewport().gui_get_focus_owner()
	inspection = Inspector.new()
	inspection.definition = catalogue.by_id[card_id]
	inspection.info = catalogue.metadata(card_id)
	inspection.ui_scale = ui_scale
	inspection.reduced_motion = reduced_motion
	inspection.pin_requested.connect(func(id): pinned_id=id; select(selected_id))
	if not pinned_id.is_empty() and pinned_id != card_id:
		inspection.comparison = catalogue.by_id[pinned_id]
		inspection.comparison_info = catalogue.metadata(pinned_id)
	add_child(inspection)
	inspection.closed.connect(func():
		inspection = null
		if is_instance_valid(focused): focused.grab_focus())

func dismiss() -> void:
	if is_instance_valid(inspection): return
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB and not is_instance_valid(inspection) and get_viewport().gui_get_focus_owner() == null:
		get_viewport().set_input_as_handled()
		search.grab_focus()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not is_instance_valid(inspection):
		get_viewport().set_input_as_handled()
		dismiss()
