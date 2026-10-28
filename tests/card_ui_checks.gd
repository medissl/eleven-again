extends SceneTree
const CardView = preload("res://ui/player_card.gd")
const Archive = preload("res://ui/player_archive.gd")
const Inspector = preload("res://ui/card_inspector.gd")
const Catalogue = preload("res://content/catalogue.gd")
var capture_enabled := false

func _initialize() -> void:
	call_deferred("run")

func key(viewport: SubViewport, code: Key, shift: bool = false) -> void:
	push_key(viewport,code,shift)
	await process_frame

func push_key(viewport: SubViewport, code: Key, shift: bool = false) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		event.shift_pressed = shift
		viewport.push_input(event)

func click(viewport: SubViewport, control: Control) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event,true)
	await process_frame

func picture(viewport: SubViewport, name_text: String) -> void:
	await create_timer(0.2).timeout
	if not capture_enabled: return
	await RenderingServer.frame_post_draw
	var file := "res://reports/screenshots/cards-%s-%dx%d.png" % [name_text,viewport.size.x,viewport.size.y]
	assert(viewport.get_texture().get_image().save_png(file) == OK)
	print("CAPTURE ",file)

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
	var library := Catalogue.new()
	var base: Resource = library.cards[0]
	var node := CardView.new()
	root.add_child(node)
	for card in library.cards:
		var before: Dictionary = card.to_data()
		node.bind(card,library.metadata(card.card_id))
		assert(node.portrait.texture != null and node.tooltip_text.contains(card.display_name))
		for child in node.content.get_children():
			if child is Label: assert(not child.text.ends_with(".0") and not child.text.contains("â€"))
		assert(card.to_data() == before)
	node.bind(base,library.metadata(base.card_id),false)
	assert(node.definition == null and node.info.is_empty() and node.portrait.texture == null)
	for child in node.content.get_children():
		if child is Label: assert(not child.text.contains(base.display_name) and not child.text.contains(base.trait_id))
	assert(node.tooltip_text == "Undiscovered player")
	node.bind(base,{})
	assert(node.portrait.texture == null and node.definition == base)
	node.queue_free()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var archive := Archive.new()
		archive.reduced_motion = true
		archive.ui_scale = 1.25 if "--large" in OS.get_cmdline_user_args() else 1.0
		viewport.add_child(archive)
		archive.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		archive.size = Vector2(1280,720)
		archive.scale = Vector2(dimensions)/archive.size
		await process_frame
		await process_frame
		assert(archive.results.size() == 200 and archive.tiles.size() == 6)
		await picture(viewport,"archive-large" if archive.ui_scale > 1 else "archive")
		archive.change_page(33)
		assert(archive.tiles.size() == 2 and archive.next.disabled)
		assert(archive.selected_id == archive.tiles[0].definition.card_id)
		archive.tier = "bronze"
		archive.refresh()
		assert(archive.results.is_empty() and archive.pin.disabled and archive.inspect_button.disabled)
		archive.clear_filters()
		archive.search.text = "Mbappé"
		archive.refresh()
		assert(archive.results.size() == 1)
		archive.tiles[0].grab_focus()
		await key(viewport,KEY_ENTER)
		assert(is_instance_valid(archive.inspection) and archive.inspection.definition.display_name.contains("Mbappé"))
		await picture(viewport,"file-large" if archive.ui_scale > 1 else "file")
		await key(viewport,KEY_TAB)
		assert(viewport.gui_get_focus_owner() is LinkButton,"Source is keyboard accessible")
		await picture(viewport,"trait-source-large" if archive.ui_scale > 1 else "trait-source")
		await key(viewport,KEY_TAB)
		assert(viewport.gui_get_focus_owner().name == "CloseFile","File focus stays inside the modal")
		await key(viewport,KEY_ESCAPE)
		assert(not is_instance_valid(archive.inspection))
		archive.clear_filters()
		archive.select(archive.tiles[0].definition.card_id)
		await click(viewport,archive.pin)
		assert(not archive.pinned_id.is_empty())
		archive.select(archive.tiles[1].definition.card_id)
		archive.tiles[1].grab_focus()
		await key(viewport,KEY_ENTER)
		assert(archive.inspection.comparison != null and archive.inspection.comparison.card_id == archive.pinned_id)
		await picture(viewport,"compare-large" if archive.ui_scale > 1 else "compare")
		await key(viewport,KEY_ESCAPE)
		archive.tier = "bronze"
		archive.refresh()
		assert(not archive.pin.disabled)
		await click(viewport,archive.pin)
		archive.find_child("ClearFilters",true,false).grab_focus()
		await key(viewport,KEY_TAB)
		assert(viewport.gui_get_focus_owner().name == "ArchiveBack","Empty results and cleared comparison retain modal focus")
		archive.clear_filters()
		archive.reduced_motion = false
		archive.inspect(archive.selected_id)
		var closing_panel: Control = archive.inspection
		var close_count := [0]
		closing_panel.closed.connect(func(): close_count[0] += 1)
		push_key(viewport,KEY_ESCAPE)
		push_key(viewport,KEY_ESCAPE)
		await create_timer(0.2).timeout
		assert(close_count[0] == 1 and not is_instance_valid(archive.inspection) and is_instance_valid(archive),"Rapid Escape cannot duplicate close or dismiss the underlying archive during a fade")
		await key(viewport,KEY_ESCAPE)
		await process_frame
		assert(not is_instance_valid(archive))
		await render_states(viewport,library)
		await preparation_flow(viewport)
		viewport.queue_free()
	print("CARD UI: 200 bindings, hidden/missing art, search/pages, mouse pin, keyboard inspect/Back and comparison passed")
	quit()

func render_states(viewport: SubViewport, library: RefCounted) -> void:
	var board := ColorRect.new()
	board.color = Color("0c2117")
	board.size = Vector2(1280,720)
	board.scale = Vector2(viewport.size)/board.size
	viewport.add_child(board)
	var caption := Label.new()
	caption.text = "NATIVE CARD STATES · authored layout checks"
	caption.position = Vector2(30,35)
	caption.add_theme_font_size_override("font_size",24)
	board.add_child(caption)
	for index in 4:
		var data: Resource = library.cards[index].duplicate(true)
		data.primary_role = "AM"
		data.natural_roles.assign(["AM"])
		data.trait_id = "threader"
		data.display_name = "Alexandré van der Meer-Santos" if index == 3 else ["Bronze Study","Silver Study","Gold Study"][index]
		for stat in data.attributes: data.attributes[stat] = [69,84,99,120][index]
		var card := CardView.new()
		card.position = Vector2(30+index*310,100)
		card.size = Vector2(285,399)
		board.add_child(card)
		card.bind(data,library.metadata(library.cards[index].card_id))
		card.set_selected(index == 1)
	await picture(viewport,"tiers")
	for child in board.get_children():
		if child is CardView: child.queue_free()
	await process_frame
	for index in 4:
		var card := CardView.new()
		card.position = Vector2(30+index*310,100)
		card.size = Vector2(285,399)
		card.disabled = index == 3
		board.add_child(card)
		var info: Dictionary = library.metadata(library.cards[index].card_id)
		if index == 1: info.target_asset_path = ""
		card.bind(library.cards[index],info,index != 0,index == 2)
	await picture(viewport,"identity")
	board.queue_free()

func preparation_flow(viewport: SubViewport) -> void:
	await process_frame
	var match_view: Control = load("res://match/match_view.tscn").instantiate()
	match_view.fixture_seed = 42
	viewport.add_child(match_view)
	match_view.set_physics_process(false)
	match_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	match_view.size = Vector2(1280,720)
	match_view.scale = Vector2(viewport.size)/match_view.size
	match_view.hud.reduced_motion = true
	match_view.hud.set_ui_scale(1.25)
	match_view.open_preparation()
	var before: Array = match_view.sim.signature()
	var plan: Dictionary = match_view.preparation.plans[0].to_data()
	await process_frame
	await picture(viewport,"preparation")
	var prep: Control = match_view.preparation
	await click(viewport,prep.find_child("OpenPlayerArchive",true,false))
	assert(is_instance_valid(prep.card_panel))
	prep.card_panel.find_child("ArchiveBack",true,false).grab_focus()
	await key(viewport,KEY_TAB,true)
	assert(viewport.gui_get_focus_owner() == prep.card_panel.inspect_button)
	await key(viewport,KEY_TAB)
	assert(viewport.gui_get_focus_owner().name == "ArchiveBack","Archive focus cannot activate underlying preparation")
	for tick in 20: match_view._physics_process(1.0/60.0)
	assert(match_view.paused and match_view.sim.signature() == before)
	await key(viewport,KEY_ESCAPE)
	assert(not is_instance_valid(prep.card_panel),"Escape closes archive even when search has focus")
	assert(match_view.sim.signature() == before,"Archive inspection leaves the match unchanged")
	prep.find_child("OpenCardSlot0",true,false).grab_focus()
	await key(viewport,KEY_ENTER)
	assert(prep.card_panel.definition.display_name == "Ward")
	await picture(viewport,"fixture-file")
	await key(viewport,KEY_TAB)
	assert(viewport.gui_get_focus_owner().name == "CloseFile","A file without an external source keeps focus inside")
	await key(viewport,KEY_ESCAPE)
	assert(not is_instance_valid(prep.card_panel) and prep.plans[0].to_data() == plan and match_view.sim.signature() == before)
	match_view.queue_free()
