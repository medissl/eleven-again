extends SceneTree
const App = preload("res://ui/campaign_app.gd")
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int = 18) -> void:
	for frame in count: await process_frame
func click(viewport: SubViewport, control: Control) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event)
	await frames(2)
func capture(viewport: SubViewport, caption: String) -> void:
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://reports/flow-repair/"+caption+"-%d.png" % viewport.size.y)
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := App.new()
	app.apply_display = false
	app.save_root = "user://flow_repair_"+str(Time.get_ticks_usec())
	viewport.add_child(app)
	await frames()
	app.settings()
	await frames()
	var shell: Control = app.modal
	var content: Control = app.settings_content
	await click(viewport,shell.find_child("SettingsAudio",true,false))
	check(not is_instance_valid(content) or not content.is_visible_in_tree(),"Old category must disappear immediately, without overlapping incoming settings")
	for section in ["display","audio","controls","accessibility"]:
		app.settings_section = section
		app.settings()
		await frames(1)
	await frames()
	await capture(viewport,"settings")
	await click(viewport,shell.find_child("CloseSettings",true,false))
	await frames(24)
	check(not is_instance_valid(shell),"Settings Back disposes its old screen even though processing was frozen")
	app.start_origin("ARG")
	var state: Dictionary = app.session.controller.snapshot()
	check(app.session.act("acquire",[state.offer.cards[0],""],state.revision).ok,"Disposable campaign acquisition succeeds")
	app.route()
	await frames()
	app.squad()
	await frames()
	var squad: Control = app.modal
	check(squad.find_child("OpenCollection",true,false) == null,"Squad has no unrelated collection navigation")
	await click(viewport,squad.find_child("PreparationBack",true,false))
	await frames(24)
	check(not is_instance_valid(squad),"Squad Back removes the entire pitch, bench and rail")
	await capture(viewport,"campaign")
	var saved: Dictionary = app.session.controller.snapshot()
	check(app.screen.find_child("Fixture12",true,false).disabled and app.screen.find_child("Fixture12",true,false).crest == null,"Distant road stops are locked and reveal no opponent identity")
	check(app.screen.find_child("RoadPawn",true,false).position == preload("res://ui/campaign_road.gd").CENTRES[saved.wins],"Physical player pawn occupies the actual current stop")
	await click(viewport,app.screen.find_child("Fixture2",true,false))
	await frames()
	check(app.road_stage == 1 and app.screen.find_child("PrepareCampaign",true,false) == null and app.screen.find_child("NextRoadMatch",true,false) != null,"Only the immediate next opponent can be previewed without starting a locked fixture")
	await capture(viewport,"next-opponent")
	await click(viewport,app.screen.find_child("NextRoadMatch",true,false))
	check(app.road_stage == saved.wins and app.session.controller.snapshot() == saved,"Preview returns to the actual next fixture without changing the saved itinerary")
	app.render("collection")
	await frames()
	var collection: Control = app.screen.get_child(0)
	var back: Control = collection.find_child("CollectionBack",true,false)
	await click(viewport,collection.find_child("CollectionNext",true,false))
	check(is_instance_valid(back) and collection.find_child("CollectionBack",true,false) == back,"Collection paging retains the same Back button")
	check(viewport.gui_get_focus_owner().name == "CollectionNext","Paging keeps focus on Next instead of flashing Back")
	await frames()
	check(back.get_meta("motion_feedback").amount == 0,"Unhovered Back has no artificial mouse-mode focus glow")
	var key := InputEventKey.new()
	key.keycode = KEY_TAB
	key.pressed = true
	viewport.push_input(key)
	await frames()
	check(viewport.get_meta("keyboard_navigation",false) and viewport.gui_get_focus_owner() != null,"Keyboard navigation restores visible focus")
	await frames()
	await capture(viewport,"collection")
	collection.open_file("")
	await frames()
	check(collection.inspection.definition == null,"Anonymous collection slots still hide identity")
	collection.inspection.dismiss()
	await frames()
	var known: String = app.session.profile.discoveries.keys()[0]
	collection.open_file(known)
	await frames()
	await capture(viewport,"player-overview")
	print("FLOW REPAIR ",viewport.size.y," CHECKS ",checks," FAILURES ",failures)
	app.queue_free()
	quit(1 if failures else 0)
