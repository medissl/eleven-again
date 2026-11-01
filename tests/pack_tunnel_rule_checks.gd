extends "res://tests/roguelite_ui_checks.gd"
const Rules=preload("res://run/roguelite_rules.gd")
func apply(data: Dictionary, action: String, args: Array = []) -> Dictionary:
	var next := data.duplicate(true)
	assert(Rules.apply(next,app.library,action,args).is_empty())
	return next
func run() -> void:
	viewport=SubViewport.new(); viewport.size=Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	app=App.new(); app.save_root="user://pack_tunnel_rule_"+str(Time.get_ticks_usec()); app.apply_display=false
	viewport.add_child(app); await process_frame; await process_frame
	var data := {}
	var focus := ""
	for seed_value in range(1,101):
		data=Rules.initial(app.library,"ENG",seed_value,"pack_rule_fixture")
		data=apply(data,"acquire",[data.offer.cards[0],""])
		for node in 2:
			data=apply(data,"commit_match",[Rules.Availability.plan(data).to_data()])
			var report := {"winner":0,"scores":[1,0],"events":[],"shots":[1,1],"on_target":[1,1],"saves":[0,1],"completed":[1,1],"attempted":[1,1],"possession":[5000,5000],"penalties":[]}
			data=apply(data,"finish_match",[report]); data=apply(data,"continue_result")
			if data.step == "manager": data=apply(data,"choose_manager",[data.manager_offer[0],""])
		focus=Rules.Economy.Packs.focus_card(data.offer.cards.map(func(id): return app.library.cards[id]))
		if not focus.is_empty(): break
	assert(not focus.is_empty())
	var controller=load("res://run/roguelite_controller.gd").new(app.library)
	assert(controller.restore(data).ok and app.session.persist(controller).ok)
	app.route()
	await create_timer(4.5).timeout
	assert(is_instance_valid(app.walkout) and app.walkout.definition.card_id == focus,"Exactly the highest Gold/Legend gets the tunnel")
	assert(app.page == "master_draft" and app.session.controller.snapshot().offer.presentation_seen)
	app.walkout.skip_intro()
	await picture("highest-pack-tunnel")
	app.walkout.confirm_player()
	await create_timer(0.25).timeout
	assert(not is_instance_valid(app.walkout) and app.page == "master_draft","Tunnel returns directly to four-card selection")
	await click("DraftCard0")
	await click("ConfirmMasterSigning")
	await click("AcceptConfirmation")
	assert(not is_instance_valid(app.walkout) and app.page != "master_draft","Signing cannot create a second tunnel/recruit scene")
	var low: Array=app.library.recruits.filter(func(card): return card.tier() in ["bronze","silver"]).slice(0,4)
	assert(Rules.Economy.Packs.focus_card(low).is_empty())
	print("PACK TUNNEL: highest Gold/Legend only, saved reveal acknowledgement, direct return to four choices, no post-sign duplicate; Bronze/Silver excluded")
	app.queue_free(); viewport.queue_free(); await process_frame; quit()
