extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view := preload("res://match/match_view.gd").new()
	view.size = viewport.size
	view.fixture_seed = 42
	view.audio_enabled = false
	view.replays_enabled = false
	viewport.add_child(view)
	view.set_physics_process(false)
	for tick in 900: view.sim.step()
	view._sync_state()
	for frame in 45: await process_frame
	var wall: Array[float] = []
	var sim_usec := 0
	var hud_usec := 0
	var stamp := Time.get_ticks_usec()
	for frame in 180:
		var start := Time.get_ticks_usec()
		view.sim.step()
		sim_usec += Time.get_ticks_usec()-start
		start = Time.get_ticks_usec()
		view._sync_state()
		hud_usec += Time.get_ticks_usec()-start
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		wall.append((now-stamp)/1000.0)
		stamp = now
	wall.sort()
	var result := {"resolution":str(viewport.size),"frames":wall.size(),"median_ms":wall[90],"p95_ms":wall[171],"simulation_mean_ms":sim_usec/180000.0,"hud_mean_ms":hud_usec/180000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	print("FRAME PROBE ",JSON.stringify(result))
	DirAccess.make_dir_recursive_absolute("res://reports/flow-repair")
	var args := OS.get_cmdline_user_args()
	var label := "before" if "--before" in args else "after"
	var file := FileAccess.open("res://reports/flow-repair/frame-"+label+"-%d.json" % viewport.size.y,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	quit()
