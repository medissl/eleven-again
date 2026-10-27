extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
	var ticks_to_run := 0
	var seed_value := 11027
	var watch := false
	var panel_mode := ""
	var event_kind := ""
	var reduced := false
	var verify_input := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			ticks_to_run = int(argument.trim_prefix("--ticks="))
		elif argument.begins_with("--seed="):
			seed_value = int(argument.trim_prefix("--seed="))
		elif argument == "--watch":
			watch = true
		elif argument.begins_with("--panel="):
			panel_mode = argument.trim_prefix("--panel=")
		elif argument.begins_with("--event="):
			event_kind = argument.trim_prefix("--event=")
		elif argument == "--reduced-motion": reduced = true
		elif argument == "--verify-controls": verify_input = true
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		# Exact render targets avoid Windows clamping large decorated windows.
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene: Control = load("res://match/match_view.tscn").instantiate()
		scene.fixture_seed = seed_value
		viewport.add_child(scene)
		scene.paused = true
		scene.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scene.size = Vector2(1280, 720)
		scene.scale = Vector2(dimensions) / Vector2(1280, 720)
		scene.sim = load("res://match/match_sim.gd").new(seed_value)
		for tick in ticks_to_run:
			scene.sim.acknowledge_halftime()
			scene.sim.step()
		if not event_kind.is_empty():
			while not scene.sim.finished and not scene.sim.events.any(func(event): return event.kind == event_kind):
				scene.sim.acknowledge_halftime()
				scene.sim.step()
			assert(scene.sim.events.any(func(event): return event.kind == event_kind), "Requested fixture event must actually occur")
			if event_kind == "goal":
				for tick in 32: scene.sim.step()
		scene.hud.reduced_motion = reduced
		scene._sync_state()
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
			scene._sync_state()
		if not panel_mode.is_empty():
			scene._on_command(panel_mode)
			await process_frame
			await process_frame
		await RenderingServer.frame_post_draw
		var stage := "result" if scene.sim.finished else ("match" if ticks_to_run > 0 else "board")
		if not panel_mode.is_empty(): stage = panel_mode
		if not event_kind.is_empty(): stage = event_kind + ("-reduced" if reduced else "")
		var path := "res://reports/screenshots/%s-%dx%d.png" % [stage, dimensions.x, dimensions.y]
		var result := viewport.get_texture().get_image().save_png(path)
		assert(result == OK)
		print("CAPTURE ", path)
		if verify_input:
			scene.set_physics_process(false)
			await verify_controls(viewport, scene)
		viewport.queue_free()
	quit()

func send_key(viewport: SubViewport, code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		viewport.push_input(event)
	await process_frame

func click_button(viewport: SubViewport, button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
	await process_frame

func verify_controls(viewport: SubViewport, scene: Control) -> void:
	var before: Array = scene.sim.signature()
	if scene.overlay_mode == "halftime":
		await send_key(viewport, KEY_ESCAPE)
		assert(scene.overlay_mode == "halftime" and scene.sim.signature() == before)
		var focused := viewport.gui_get_focus_owner() as Button
		assert(focused.text == "Continue second half")
		await send_key(viewport, KEY_TAB)
		focused = viewport.gui_get_focus_owner() as Button
		assert(focused.text == "Match menu")
		await click_button(viewport, focused)
		assert(scene.overlay_mode == "menu" and scene.sim.signature() == before)
		await send_key(viewport, KEY_ESCAPE)
		assert(scene.overlay_mode == "halftime")
		await send_key(viewport, KEY_ENTER)
		assert(scene.sim.period == 2 and scene.overlay_mode.is_empty() and not scene.paused)
	elif scene.overlay_mode == "result":
		await send_key(viewport, KEY_ESCAPE)
		assert(scene.overlay_mode == "result")
		await send_key(viewport, KEY_ENTER)
		assert(scene.overlay_mode == "menu" and scene.sim.signature() == before)
	elif scene.overlay_mode == "menu":
		for prefix in ["Celebration effects:", "Reduced motion:"]:
			var value_before: bool = scene.hud.effects_enabled if prefix.begins_with("Celebration") else scene.hud.reduced_motion
			for child in scene.hud.panel_content.get_children():
				if child is Button and child.text.begins_with(prefix):
					await click_button(viewport, child)
					break
			var value_after: bool = scene.hud.effects_enabled if prefix.begins_with("Celebration") else scene.hud.reduced_motion
			assert(value_before != value_after and scene.sim.signature() == before)
	print("NATIVE INPUT ", viewport.size, " focus/Escape/Continue or preference controls passed")
