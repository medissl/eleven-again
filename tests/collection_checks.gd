extends SceneTree
const Collection = preload("res://ui/collection_screen.gd")
const Campaign = preload("res://content/campaign.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	root.add_child(viewport)
	var album := Collection.new()
	album.library = Campaign.new()
	album.reduced_motion = true
	viewport.add_child(album)
	await process_frame
	assert(album.results.size() == 300 and album.tiles.size() == 12)
	for node in album.body.find_children("*","Label",true,false):
		for card in album.library.recruits: assert(not node.text.contains(card.display_name))
	for tile in album.tiles:
		assert(tile.name.begins_with("UnknownEdition_") and tile.tooltip_text == album.tiles[0].tooltip_text)
		assert(tile.find_child("Portrait",true,false) == null,"Hidden versions cannot retain a real portrait")
	album.query = album.library.recruits[0].display_name
	assert(album.visible_cards().is_empty(),"Searching for a hidden identity cannot leak existence/count")
	album.role = "GK"
	assert(album.visible_cards().is_empty())
	album.query = ""
	album.role = ""
	var id: String = album.library.recruits[0].card_id
	album.discoveries[id] = {"first_discovered":"2026-10-29","run_ids":["test"]}
	album.known_only = true
	album.refresh()
	await process_frame
	assert(album.results.size() == 1 and album.tiles[0].definition.card_id == id)
	album.open_file(id)
	assert(album.inspection.definition.card_id == id)
	album.inspection.dismiss()
	await process_frame
	album.open_file("")
	assert(album.inspection.definition == null and album.inspection.info.is_empty())
	album.inspection.dismiss()
	album.discoveries.clear()
	for card in album.library.recruits: album.discoveries[card.card_id] = {"run_ids":["test"]}
	album.known_only = false
	album.page = 24
	album.refresh()
	await process_frame
	assert(album.results.size() == 300 and album.tiles.size() == 12)
	album.queue_free()
	await process_frame
	print("COLLECTION: empty/partial/full, anonymous versions, search/filter non-disclosure, acquired-only inspection and last-page checks passed")
	quit()
