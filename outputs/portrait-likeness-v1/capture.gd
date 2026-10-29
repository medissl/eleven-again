extends SceneTree
const CardView = preload("res://ui/player_card.gd")
const Catalogue = preload("res://content/catalogue.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var library := Catalogue.new()
	var ids := ["david_beckham_2000_01","lionel_messi_2008_09","cristiano_ronaldo_2016_17","ronaldo_nazario_1996_97","lev_yashin_1963"]
	var prefix := "native"
	if "--keepers" in OS.get_cmdline_user_args():
		ids = ["alisson_becker_2023_24","ederson_2023_24","edwin_van_der_sar_2008_09","roberto_baggio_1993_94","victor_osimhen_2022_23"]
		prefix = "native-keepers"
	var pages := [ids]
	if "--batch60" in OS.get_cmdline_user_args() or "--all" in OS.get_cmdline_user_args():
		var all_cards := "--all" in OS.get_cmdline_user_args()
		var selection: Array = library.by_id.keys() if all_cards else JSON.parse_string(FileAccess.get_file_as_string("res://outputs/portrait-likeness-v1/batch60-ids.json"))
		assert(selection.size() == (200 if all_cards else 60))
		pages.clear()
		for offset in range(0, selection.size(), 5):
			pages.append(selection.slice(offset, offset + 5))
		prefix = "native-all" if all_cards else "native-batch60"
	for page in pages.size():
		await capture_page(library, pages[page], prefix + ("-%02d" % [page + 1] if pages.size() > 1 else ""))
	print("Modular portrait native CardView captures passed at 720p and 1080p; definitions unchanged.")
	quit()

func capture_page(library: RefCounted, ids: Array, prefix: String) -> void:
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var canvas := Control.new()
		canvas.size = Vector2(1280,720)
		canvas.scale = Vector2.ONE * float(dimensions.x) / 1280.0
		viewport.add_child(canvas)
		var background := ColorRect.new()
		background.color = Color("0c2118")
		background.size = Vector2(1280,720)
		canvas.add_child(background)
		for i in ids.size():
			var card := CardView.new()
			card.position = Vector2(20+i*250,150)
			card.size = Vector2(240,336)
			canvas.add_child(card)
			var definition: Resource = library.by_id[ids[i]]
			var before: Dictionary = definition.to_data()
			card.bind(definition,library.metadata(ids[i]))
			assert(card.portrait.texture.get_size() == Vector2(96,96))
			var source := Image.new()
			assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes(library.metadata(ids[i])["target_asset_path"])) == OK)
			var imported := card.portrait.texture.get_image()
			for y in 96:
				for x in 96:
					var pixel := source.get_pixel(x,y)
					if pixel.a > 0.0:
						assert(imported.get_pixel(x,y) == pixel, "Stale portrait import: " + ids[i])
			assert(definition.to_data() == before)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://outputs/portrait-likeness-v1/%s-%dx%d.png" % [prefix,dimensions.x,dimensions.y]) == OK)
		viewport.queue_free()
		await process_frame
