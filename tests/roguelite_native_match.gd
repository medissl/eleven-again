extends SceneTree
const App=preload("res://ui/campaign_app.gd")
var viewport: SubViewport
var app: Control
func _initialize() -> void: call_deferred("run")
func press(id: String) -> void:
	var button: BaseButton=app.find_child(id,true,false)
	assert(button != null and not button.disabled,"Available control "+id)
	button.grab_focus()
	for down in [true,false]:
		var key := InputEventKey.new(); key.keycode=KEY_ENTER; key.pressed=down
		viewport.push_input(key)
	await process_frame; await process_frame
func capture(name: String) -> void:
	await create_timer(0.3).timeout; await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://reports/master-brief/"+name+"-%d.png" % viewport.size.y) == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/master-brief")
	viewport=SubViewport.new(); viewport.size=Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	app=App.new(); app.save_root="user://master_native_match_"+str(Time.get_ticks_usec()); app.apply_display=false
	viewport.add_child(app); await process_frame; await process_frame
	assert(app.session.new_run("ENG",47,"native_match_flow",false,true).ok)
	var state: Dictionary=app.session.controller.snapshot()
	assert(app.session.act("acquire",[state.offer.cards[0],""],state.revision).ok)
	app.route(); await process_frame
	app.select_viewing_mode(app.session.controller.preparation_plan(),app.session.controller.revision())
	await process_frame
	await press("ViewingModeInstantResult")
	var start := Time.get_ticks_msec()
	while app.page == "master_resolve":
		await process_frame
		assert(Time.get_ticks_msec()-start < 120000,"Native result finishes within two minutes")
	assert(app.page == "master_result")
	state=app.session.controller.snapshot()
	assert(state.node == 1 and state.ledger.size() == 1 and state.ledger[0].report.has("impact"))
	assert(load("res://persistence/campaign_session.gd").new(app.save_root).controller.snapshot() == state,"Actual result and coins survive a fresh session")
	await capture("native-result")
	await press("MasterResultContinue")
	assert(app.page == "master_manager" and app.session.controller.snapshot().manager_offer.size() == 3)
	await capture("manager-choice")
	await press("ChooseMasterManager0")
	assert(app.page == "board" and app.session.controller.snapshot().managers.size() == 1)
	await capture("node-two")
	print("ROGUELITE NATIVE MATCH: keyboard Instant Result -> real 180-second football -> saved result/reward -> three Manager choices -> equipped tactic -> next node passed at ",viewport.size)
	app.queue_free(); viewport.queue_free(); await process_frame; quit()
