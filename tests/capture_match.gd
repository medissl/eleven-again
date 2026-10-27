extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
	var ticks_to_run := 0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			ticks_to_run = int(argument.trim_prefix("--ticks="))
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		# Exact render targets avoid Windows clamping large decorated windows.
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene: Control = load("res://match/match_view.tscn").instantiate()
		viewport.add_child(scene)
		scene.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scene.size = Vector2(1280, 720)
		scene.scale = Vector2(dimensions) / Vector2(1280, 720)
		for tick in ticks_to_run:
			scene.sim.step()
		scene._sync_state()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://reports/screenshots/%s-%dx%d.png" % ["match" if ticks_to_run > 0 else "board", dimensions.x, dimensions.y]
		var result := viewport.get_texture().get_image().save_png(path)
		assert(result == OK)
		print("CAPTURE ", path)
		viewport.queue_free()
	quit()
