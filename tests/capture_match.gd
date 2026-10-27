extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
	var ticks_to_run := 0
	var seed_value := 11027
	var watch := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			ticks_to_run = int(argument.trim_prefix("--ticks="))
		elif argument.begins_with("--seed="):
			seed_value = int(argument.trim_prefix("--seed="))
		elif argument == "--watch":
			watch = true
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
		scene.sim = load("res://match/match_sim.gd").new(seed_value)
		scene.last_event_count = -1
		for tick in ticks_to_run:
			scene.sim.step()
		scene._sync_controls()
		await process_frame
		await process_frame
		if watch:
			scene.paused = false
			for frame in 30:
				await process_frame
			var started := Time.get_ticks_usec()
			for frame in 180:
				await process_frame
			print("RENDER ", dimensions, " fps=", snappedf(180000000.0 / (Time.get_ticks_usec() - started), 0.1), " sim_ticks=", scene.sim.ticks)
			scene.paused = true
			scene._sync_controls()
		await RenderingServer.frame_post_draw
		var stage := "result" if scene.sim.finished else ("match" if ticks_to_run > 0 else "board")
		var path := "res://reports/screenshots/%s-%dx%d.png" % [stage, dimensions.x, dimensions.y]
		var result := viewport.get_texture().get_image().save_png(path)
		assert(result == OK)
		print("CAPTURE ", path)
		viewport.queue_free()
	quit()
