extends SceneTree
func _initialize() -> void: call_deferred("run")
func white_near(image: Image, point: Vector2) -> bool:
	for y in range(-2,3):
		for x in range(-2,3):
			var p := Vector2i(point)+Vector2i(x,y)
			if not Rect2i(Vector2i.ZERO,image.get_size()).has_point(p): continue
			var colour := image.get_pixelv(p)
			if colour.r > 0.7 and colour.g > 0.7 and colour.b > 0.65: return true
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/master-brief")
	for extent in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1280,689),Vector2i(1640,880)]:
		var viewport := SubViewport.new(); viewport.size=extent; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var view := preload("res://match/match_view.gd").new()
		view.fixture_seed=42; view.audio_enabled=false; view.replays_enabled=false; view.size=extent
		viewport.add_child(view); view.set_physics_process(false); view.set_process(false)
		for tick in 700: view.sim.step()
		view.snap_presentation(); view._sync_state(); view.hud.cue.hide()
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://reports/master-brief/pitch-%dx%d.png" % [extent.x,extent.y]) == OK)
		var clock: Label=view.hud.labels.clock
		assert(clock.text.contains(":") and clock.get_rect().position.y >= view.hud.labels.score.get_rect().end.y and clock.get_rect().end.y < view.pitch.position.y,"Clock fits completely below score and above field: "+str([clock.text,clock.get_rect(),view.hud.labels.score.get_rect(),view.pitch]))
		var text: String=clock.text
		var before: Dictionary=view.sim.snapshot()
		for tick in 60: view.sim.step()
		view._sync_state()
		assert(clock.text != text,"Match clock visibly advances in seconds")
		assert(view.sim.regulation_ticks == 10800)
		for metric in view.name_metrics.values(): assert(metric.pixels == 14,"Field names use the requested smaller size")
		# Marking-only render removes player occlusion for actual-pixel coverage checks.
		for player in view.sim.players: player.active=false
		view._sync_state(); view.hud.cue.hide(); view.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		for x in [0.0,5.5,16.5,52.5,88.5,99.5,105.0]:
			var low := 0.0 if x in [0.0,52.5,105.0] else 24.84 if x in [5.5,99.5] else 13.84
			var high := 68.0-low
			var hits := 0
			for index in 40:
				if white_near(image,view._mark_point(Vector2(x,lerpf(low,high,index/39.0)))): hits+=1
			assert(hits >= 38,"Every vertical field/box line remains continuous at "+str(extent)+" x="+str(x)+" hits="+str(hits))
		for end in 2:
			var mouth: Vector2=view._mark_point(Vector2(0 if end == 0 else 105,34))
			var depth := floorf(minf(3.2*view._scale(),view.pitch.position.x-8)/maxi(1,roundi(extent.y/360.0)))*maxi(1,roundi(extent.y/360.0))
			var back: Vector2=mouth+Vector2(-depth if end == 0 else depth,0)
			assert(back.x >= 6 and back.x <= view.hud.divider-6,"Complete goal depth stays in the visible gutter")
			assert(white_near(image,Vector2(mouth.x,view._field(Vector2(0,30.34)).y+3)),"Goal mouth is visible and aligned")
			var step := float(maxi(1,roundi(extent.y/360.0)))
			for y in [floorf(view._field(Vector2(0,30.34)).y/step)*step+step,ceilf(view._field(Vector2(0,37.66)).y/step)*step-step]:
				var hits := 0
				for index in range(2,9):
					if white_near(image,Vector2(lerpf(back.x,mouth.x,index/10.0),y)): hits+=1
				assert(hits >= 5,"The generated goal has complete top and bottom frame edges: "+str([extent,end,y,hits,back,mouth,depth]))
		viewport.queue_free(); await process_frame
	print("PITCH READABILITY: full vertical markings and goals, seconds clock bounds/progression, 14px unboxed names at four native client sizes passed")
	quit()
