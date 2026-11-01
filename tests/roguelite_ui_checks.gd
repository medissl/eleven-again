extends SceneTree
const App=preload("res://ui/campaign_app.gd")
var viewport: SubViewport
var app: Control
func _initialize() -> void: call_deferred("run")
func click(id: String) -> void:
	var node: Control=app.find_child(id,true,false)
	assert(node != null and not (node is BaseButton and node.disabled),"Available control: "+id)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; event.position=node.get_global_rect().get_center()
		viewport.push_input(event)
	await process_frame; await process_frame
func picture(name: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://reports/master-brief/"+name+"-%d.png" % viewport.size.y) == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/master-brief")
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	app=App.new(); app.save_root="user://master_ui_"+str(Time.get_ticks_usec()); app.apply_display=false; app.master_new_runs=true
	viewport.add_child(app)
	await process_frame; await process_frame
	assert(app.session.new_run("FRA",42,"master_native_ui",false,true).ok)
	app.route()
	await create_timer(0.35).timeout
	await click("RevealAllMasterPack")
	await picture("opening-draft")
	for index in 4:
		var tile: Control=app.find_child("DraftCard"+str(index),true,false)
		assert(tile.get_global_rect().end.x <= viewport.size.x and tile.get_global_rect().end.y < 0.78*viewport.size.y,"Whole readable card fits")
	await click("DraftCard0")
	await click("ConfirmMasterSigning")
	assert(app.modal != null and app.find_child("AcceptConfirmation",true,false).text == "Confirm")
	await click("AcceptConfirmation")
	assert(app.page == "board" and app.session.controller.snapshot().plan.cards.size() == 17)
	await picture("road")
	await click("MasterScouting")
	assert(app.page == "master_scout")
	await picture("scouting")
	await click("OpenMasterTraining")
	assert(app.page == "master_training" and app.find_child("TrainMasterPlayer",true,false).disabled)
	await picture("training")
	await click("TrainingBack")
	await click("OpenMasterMarket")
	assert(app.page == "master_market")
	await picture("market")
	await click("DraftCard0")
	assert(app.find_child("ConfirmMasterSigning",true,false).disabled,"Cannot sign without coins")
	await click("MarketBack")
	assert(app.page == "board")
	app.settings(); await process_frame
	await click("CloseSettings")
	assert(app.modal == null)
	app.inspect(app.session.controller.snapshot().plan.cards[0].card_id)
	await process_frame
	assert(app.modal.find_child("PinComparison",true,false) == null)
	await picture("player-overview-no-pin")
	await click("CloseFile")
	await create_timer(0.2).timeout
	app.start_origin("BRA",true)
	assert(app.is_master() and app.session.controller.snapshot().offer.cards.size() == 4,"Normal F5 New Run factory uses the new rules")
	app.queue_free(); viewport.queue_free(); await process_frame
	print("ROGUELITE UI: native four-card selection/confirmation, bounds, scouting, market, training, settings and Back passed at ",1920 if "--1080" in OS.get_cmdline_user_args() else 1280)
	quit()
