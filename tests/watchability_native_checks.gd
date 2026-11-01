extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view := preload("res://match/match_view.gd").new()
	view.fixture_seed = 42
	view.audio_enabled = false
	view.replays_enabled = false
	view.size = viewport.size
	viewport.add_child(view)
	view.set_physics_process(false)
	view.set_process(false)
	for frame in 3: await process_frame
	view.sim.kickoff_ticks = 180
	view._sync_state()
	check(view.hud.cue.title.text == "3","Native countdown shows 3 before kickoff whistle")
	view.sim.kickoff_ticks = 120
	view._sync_state()
	check(view.hud.cue.title.text == "2","Countdown advances to 2")
	view.sim.kickoff_ticks = 60
	view._sync_state()
	check(view.hud.cue.title.text == "1","Countdown advances to 1")
	view.sim.kickoff_ticks = 1
	view.sim.step()
	view._sync_state()
	check(view.hud.cue.title.text == "KICK-OFF" and view.sim.events.any(func(event): return event.kind == "kickoff_whistle"),"Whistle and opening kick follow 1")
	view.hud.cue.hide()
	view.hud.cue.duration = 0
	view.sim.kickoff_kicker = -1
	view.sim.players[9].position = Vector2(58,34)
	view.sim.take_control(9)
	check(view.sim.owner == 9,"Trajectory fixture launches from an actual legal ball owner")
	view.sim.launch_ball(Vector2(98,34),36,"pass")
	for frame in 18:
		view.sim.advance_flight()
		view._sync_state()
		var before: Dictionary = view.sim.snapshot()
		view._process(1.0/60)
		check(view.sim.snapshot() == before,"Trajectory rendering never alters football state or RNG")
		await process_frame
	check(view.ball_trail.size() > 4 and view.ball_trail.size() <= 24,"Trajectory lasts longer than the old four-frame flicker and remains bounded")
	check(not view.ball_trail.is_empty() and view.ball.distance_to(view.ball_trail[0]) <= 8.0,"Trace never extends beyond the recent actual path")
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://reports/flow-repair/football-trail-%d.png" % viewport.size.y)
	view.hud.reduced_motion = true
	view._process(1.0/60)
	check(view.ball_trail.is_empty(),"Reduced motion removes the trajectory effect")
	print("NATIVE WATCHABILITY ",viewport.size.y," CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)
