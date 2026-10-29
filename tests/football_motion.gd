extends SceneTree
## Native before/after footage; presentation cadence never drives authoritative ticks.
const Match = preload("res://match/match_sim.gd")
const Physical = preload("res://tests/physical_ball_checks.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var label := "after"
	var speed := 1
	var height := 720
	var seed_value := 11027
	var frames := 1200
	var scenario := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
		if arg.begins_with("--speed="): speed = int(arg.trim_prefix("--speed="))
		if arg.begins_with("--height="): height = int(arg.trim_prefix("--height="))
		if arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
		if arg.begins_with("--frames="): frames = int(arg.trim_prefix("--frames="))
		if arg.begins_with("--case="): scenario = arg.trim_prefix("--case=")
	assert(label.is_valid_identifier() and speed in [1,2] and height in [720,1080])
	var viewport := SubViewport.new()
	viewport.size = Vector2i(height*16/9,height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view: Control = load("res://match/match_view.tscn").instantiate()
	view.fixture_seed = seed_value
	viewport.add_child(view)
	view.set_physics_process(false)
	view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(1280,720)
	view.scale = Vector2(viewport.size)/view.size
	view.speed = speed
	view.paused = false
	if not scenario.is_empty():
		view.sim = Physical.fixture(3)
		if scenario == "overhit":
			view.sim.players[9].position = Vector2(50,62.3)
			view.sim.players[9].facing = Vector2.DOWN
			view.sim.ball = Vector2(50,64)
			view.sim.launch_ball(Vector2(50,66),24,"pass")
		elif scenario in ["corner","live_save"]:
			var y := 37 if scenario == "corner" else 34
			view.sim.players[9].position = Vector2(88.3,y)
			view.sim.players[9].facing = Vector2.RIGHT
			view.sim.ball = Vector2(90,y)
			view.sim.players[11].position = Vector2(104,34)
			view.sim.players[11].previous = Vector2(104,34)
			view.sim.players[11].handling = 40
			view.sim.launch_ball(Vector2(105,y),32,"shot")
			view.sim.shot_quality = 0.2
		elif scenario == "block":
			view.sim.players[9].position = Vector2(92.3,60)
			view.sim.players[9].facing = Vector2.RIGHT
			view.sim.ball = Vector2(94,60)
			view.sim.players[12].position = Vector2(98,60.9)
			view.sim.players[12].previous = view.sim.players[12].position
			view.sim.launch_ball(Vector2(105,60),30,"shot")
		else: assert(false,"Unknown physical footage scenario")
		for p in view.sim.players: p.previous = p.position
		view.snap_presentation()
	var directory := "res://.godot/football-motion/%s-%d-%dx-%d" % [label,seed_value,speed,height]
	if not scenario.is_empty(): directory += "-"+scenario
	DirAccess.make_dir_recursive_absolute(directory)
	var oracle: RefCounted = load("res://match/match_snapshot.gd").restore(view.sim.snapshot())
	for frame in frames:
		view._physics_process(1.0/60)
		for tick in speed: oracle.step()
		assert(view.sim.signature() == oracle.signature(),"Native presentation must equal headless state at every frame")
		await process_frame
		if frame % 6 == 0:
			await RenderingServer.frame_post_draw
			var capture := viewport.get_texture().get_image()
			assert(capture != null)
			assert(capture.save_png(directory+"/%04d.png" % (frame/6)) == OK)
	print("FOOTBALL MOTION ",directory," frames=",ceili(frames/6.0)," fps=10 ticks=",view.sim.ticks," state/headless equality passed")
	if not scenario.is_empty():
		print("SCENARIO EVENTS ",view.sim.events.map(func(e): return e.kind))
	view.queue_free()
	quit()
