extends "res://tests/roguelite_ui_checks.gd"
const Rules=preload("res://run/roguelite_rules.gd")
const Controller=preload("res://run/roguelite_controller.gd")
func apply(data: Dictionary, action: String, args: Array = []) -> Dictionary:
	var next := data.duplicate(true)
	assert(Rules.apply(next,app.library,action,args).is_empty())
	return next
func show_fixture(data: Dictionary, page: String) -> void:
	var controller := Controller.new(app.library)
	assert(controller.restore(data).ok,"Authored UI fixture passes the actual run validator")
	app.session.controller=controller
	app.render(page)
	await process_frame; await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/master-brief")
	viewport=SubViewport.new(); viewport.size=Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	app=App.new(); app.save_root="user://legacy_ui_"+str(Time.get_ticks_usec()); app.apply_display=false
	viewport.add_child(app); await process_frame; await process_frame
	await click("ManagerLegacy")
	assert(app.page == "master_legacy")
	for branch in Rules.Legacy.BRANCHES:
		for level in range(1,5):
			var node: Control=app.find_child("LegacyNode"+branch+str(level),true,false)
			assert(node != null and viewport.get_visible_rect().encloses(node.get_global_rect()),"All 24 hexes fit")
	await click("LegacyNodefortune4")
	assert(app.find_child("BuyLegacyNode",true,false).disabled,"Locked/unaffordable purchase is unavailable")
	await picture("legacy-board")
	await click("LegacyBack")
	var data := Rules.initial(app.library,"ENG",42,"legacy_ui_fixture",Rules.Legacy.NODES.keys())
	data=apply(data,"acquire",[data.offer.cards[0],""])
	data=apply(data,"open_market")
	assert(data.market.cards.size() == 7)
	await show_fixture(data,"master_market")
	await click("MasterMarketNext")
	assert(app.find_child("DraftCard4",true,false) != null and app.find_child("DraftCard0",true,false) == null)
	for index in range(4,7): assert(viewport.get_visible_rect().encloses(app.find_child("DraftCard"+str(index),true,false).get_global_rect()))
	await picture("expanded-market")
	data=apply(data,"close_market")
	data=apply(data,"commit_match",[Rules.Availability.plan(data).to_data()])
	# Authored result fixture drives layout; actual-engine result flow has its own native check.
	var report := {"winner":0,"scores":[1,0],"events":[],"shots":[1,1],"on_target":[1,1],"saves":[0,1],"completed":[1,1],"attempted":[1,1],"possession":[5000,5000],"penalties":[]}
	data=apply(data,"finish_match",[report]); data=apply(data,"continue_result")
	assert(data.manager_offer.size() == 5)
	await show_fixture(data,"master_manager")
	for index in 3: assert(app.find_child("ManagerEffect"+str(index),true,false).size.x <= 346,"Wrapped Manager copy stays inside its panel")
	await picture("manager-expanded-first")
	await click("ManagerChoicesNext")
	assert(app.find_child("ChooseMasterManager3",true,false) != null)
	await picture("manager-expanded-last")
	data=apply(data,"choose_manager",[data.manager_offer[0],""])
	data=apply(data,"commit_match",[Rules.Availability.plan(data).to_data()])
	data=apply(data,"finish_match",[report]); data=apply(data,"continue_result"); data=apply(data,"skip_recruit")
	assert(data.step == "route" and Rules.routes(data,app.library).size() == 3)
	await show_fixture(data,"master_route")
	for index in 3: assert(viewport.get_visible_rect().encloses(app.find_child("ChooseMasterRoute"+str(index),true,false).get_global_rect()))
	await picture("expanded-route")
	print("LEGACY UI: 24 generated pixel hexes, native selection/Back, locked states, expanded market and Manager paging, three routes passed at ",viewport.size)
	app.queue_free(); viewport.queue_free(); await process_frame; quit()
