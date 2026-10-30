extends SceneTree
const Match = preload("res://match/match_sim.gd")
const Buffer = preload("res://match/replay_buffer.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func shot(viewport: SubViewport, name: String, height: int) -> void:
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png("res://reports/replay/"+name+"-%d.png" % height) == OK,"Native replay capture: "+name)
func run() -> void:
	var height := 1080 if "--1080" in OS.get_cmdline_user_args() else 720
	DirAccess.make_dir_recursive_absolute("res://reports/replay")
	var history := Buffer.new()
	var model := Match.new(42)
	history.capture(model)
	while model.scores[0]+model.scores[1] == 0 and model.ticks < 24000:
		model.acknowledge_halftime()
		model.step()
		history.capture(model)
	var event: Dictionary = {}
	var event_index := -1
	for index in model.events.size():
		if model.events[index].kind == "goal": event=model.events[index]; event_index=index
	check(not event.is_empty(),"Replay source is a real seeded goal, not an authored animation")
	check(history.frames.size() <= Buffer.LIMIT,"Replay history is bounded to four seconds")
	var clip := history.goal_clip(model,event)
	check(clip.frames.size() > 30 and clip.frames.back().ball == model.ball,"Clip ends at the actual goal-line crossing")
	check(clip.frames.any(func(frame): return frame.tick == clip.shot_tick),"Actual shot release exists in the recorded clip")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(height*16/9,height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view := preload("res://match/match_view.gd").new()
	view.fixture_seed = 42
	view.external_model = model
	view.size = viewport.size
	viewport.add_child(view)
	view.set_physics_process(false)
	view.replay_history = history
	view.presentation_events = event_index
	view._sync_state()
	await frames(12)
	check(is_instance_valid(view.goal_replay),"Real goal opens the replacement replay by default")
	var director: Control = view.goal_replay
	var frozen: Dictionary = model.snapshot()
	for tick in 20: view._physics_process(Match.DT)
	check(model.snapshot() == frozen,"Authoritative model is frozen throughout branding and playback")
	await shot(viewport,"brand",height)
	await frames(48)
	check(is_instance_valid(director.pitch_view) and director.pitch_view.sim != model,"Replay renderer owns a private model copy")
	await shot(viewport,"build-up",height)
	var native_path := "res://.godot/replay-motion-%d" % height
	DirAccess.make_dir_recursive_absolute(native_path)
	var saw_slow := false
	var max_frames := 0
	while is_instance_valid(view.goal_replay) and max_frames < 900:
		if director.slow_motion and not saw_slow:
			saw_slow = true
			await shot(viewport,"slow-motion",height)
		if max_frames%8 == 0:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(native_path+"/%03d.png" % max_frames)
		await process_frame
		max_frames += 1
	check(saw_slow and max_frames < 900,"Recorded build-up reaches slow motion and finishes without intervention")
	check(model.snapshot() == frozen,"Watching a replay changes no ticks, RNG, score, possession or saved facts")
	view._show_goal_replay(event)
	await frames(16)
	var skip := InputEventMouseButton.new()
	skip.button_index = MOUSE_BUTTON_LEFT
	skip.pressed = true
	skip.position = Vector2(600,300)
	viewport.push_input(skip)
	await frames(12)
	check(not is_instance_valid(view.goal_replay) and model.snapshot() == frozen,"Mouse skip fades out without advancing or altering the match")
	view._show_goal_replay(event)
	await frames(4)
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	viewport.push_input(key)
	await frames(12)
	check(not is_instance_valid(view.goal_replay) and model.snapshot() == frozen,"Escape skips replay without opening the pause menu")
	view.hud.reduced_motion = true
	view._show_goal_replay(event)
	await frames(10)
	check(not is_instance_valid(view.goal_replay.pitch_view),"Reduced motion uses an immediate static goal treatment")
	await shot(viewport,"reduced-motion",height)
	await frames(64)
	check(not is_instance_valid(view.goal_replay) and model.snapshot() == frozen,"Reduced-motion goal exits automatically with no confetti or hidden play")
	view._physics_process(Match.DT)
	check(model.ticks == frozen.state.ticks+1 and model.active_ticks == frozen.state.active_ticks,"Resume advances the actual post-goal stoppage once, preserving regulation")
	print("REPLAY ",height," checks=",checks," failures=",failures," source_seed=42 goal_tick=",event.tick," clip_frames=",clip.frames.size())
	view.queue_free()
	quit(1 if failures else 0)
