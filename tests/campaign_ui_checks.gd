extends SceneTree
const App = preload("res://ui/campaign_app.gd")
const Profile = preload("res://persistence/profile.gd")
var capture := false
var large := false

class ManualApp:
	extends App
	func _show_walkout(_id: String, _newly_discovered: bool) -> void:
		route() # Transaction/lifecycle oracle; recruitment_presentation_checks exercises the full walkout.
	func open_match() -> void:
		super.open_match()
		view.set_physics_process(false)

class FailedStore:
	extends "res://persistence/save_store.gd"
	func write(_kind: String, _data: Variant, _validate: Callable) -> Dictionary:
		return {"ok":false,"error":"Authored test: temporary save write failed."}

func _initialize() -> void: call_deferred("run")

func key(viewport: Viewport, code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		viewport.push_input(event)
	await process_frame
	await process_frame

func press(app: Control, id: String) -> void:
	var button := app.find_child(id,true,false) as BaseButton
	if button == null or button.disabled:
		push_error("Missing/disabled control: "+id)
		quit(1)
		return
	button.grab_focus()
	await key(app.get_viewport(),KEY_ENTER)

func click(app: Control, id: String) -> void:
	var acquisition = app.screen.find_child("Acquisition",true,false) if is_instance_valid(app.screen) else null
	if acquisition != null and acquisition.tiles.any(func(tile): return tile.get_meta("dealing",false)): await create_timer(0.9).timeout
	var control := app.find_child(id,true,false) as Control
	assert(control != null)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = control.get_global_rect().get_center()
		app.get_viewport().push_input(event)
	await process_frame
	await process_frame

func cards_fit(app: Control) -> void:
	var offer = app.screen.find_child("Acquisition",true,false)
	assert(offer.tiles.size() == (4 if offer.market else 5))
	for tile in offer.tiles:
		var bounds: Rect2 = tile.get_global_rect()
		var visible_area: Rect2 = offer.card_area.get_global_rect()
		assert(visible_area.has_point(bounds.position+Vector2.ONE) and visible_area.has_point(bounds.end-Vector2.ONE),"Every complete card must fit without normal-size scrolling")
	assert(offer.card_area.scroll_horizontal == 0 and offer.card_area.scroll_vertical == 0)

func picture(app: Control, label: String) -> void:
	await create_timer(0.22).timeout
	if not capture: return
	await RenderingServer.frame_post_draw
	var destination := "res://reports/screenshots/campaign-%s%s-%dx%d.png" % [label,"-large" if large else "",app.size.x,app.size.y]
	assert(app.get_viewport().get_texture().get_image().save_png(destination) == OK)
	print("CAPTURE ",destination)

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	large = "--large" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://reports/screenshots")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080) if "--1080" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := ManualApp.new()
	app.master_new_runs=false # Frozen legacy five-card/twelve-win UI continuation coverage.
	app.save_root = "user://campaign_ui_test_"+str(Time.get_ticks_usec())
	app.apply_display = false
	viewport.add_child(app)
	await process_frame
	await process_frame
	assert(app.ui_scale() == 1.0 and not app.preferences.change("scale",1.25).ok)
	if "--write-ui-probe" in OS.get_cmdline_user_args() or "--resume-ui-probe" in OS.get_cmdline_user_args():
		await probe(app)
		return
	if "--motion" in OS.get_cmdline_user_args():
		await motion(app)
		return
	await picture(app,"main-empty")
	await click(app,"NewRun")
	assert(app.library.countries.size() == 6)
	for origin in app.library.countries:
		await press(app,origin)
		assert(app.origin_selection == origin and app.library.country_plan(origin).cards.size() == 16)
	await press(app,"BRA")
	await picture(app,"origin")
	await press(app,"StartRun")
	assert(app.page == "offer" and app.session.controller.snapshot().plan.cards.size() == 16)
	await picture(app,"opening")
	cards_fit(app)
	var opening = app.screen.find_child("Acquisition",true,false)
	await click(app,"Candidate_"+opening.state.offer.cards[1])
	assert(opening.selected == opening.state.offer.cards[1])
	await press(app,"ConfirmAcquisition")
	assert(app.page == "board" and app.session.controller.snapshot().plan.cards.size() == 17)
	await picture(app,"board")
	var before_replace: Dictionary = app.session.controller.snapshot()
	app.render("origin")
	app.start_origin("ENG")
	await press(app,"CancelConfirmation")
	assert(app.session.controller.snapshot() == before_replace,"Cancelling a replacement preserves the entire run")
	app.route()
	await press(app,"PrepareCampaign")
	assert(app.modal.campaign_mode and app.modal.find_child("FixtureSquad",true,false) == null)
	var lineup_pitch = app.modal.find_child("LineupPitch",true,false)
	assert(lineup_pitch != null and lineup_pitch.sim.players.filter(func(player): return player.active).size() == 11 and lineup_pitch._formation_opacity() == 1.0,"Static XI preview renders all eleven real players without inheriting kickoff invisibility")
	await picture(app,"preparation")
	var prepared: Dictionary = app.modal.plans[0].to_data()
	await press(app,"TacticalDetails")
	assert(is_instance_valid(app.modal.card_panel) and app.modal.card_panel.find_child("LateRisk",true,false) != null)
	await press(app,"CloseDrawer")
	await press(app,"TeamEditing")
	await press(app,"PreparationSetPieces")
	await picture(app,"set-pieces")
	await press(app,"ShootoutOrder")
	await picture(app,"shootout-order")
	await press(app,"CloseDrawer")
	await press(app,"TeamEditing")
	await press(app,"PreparationSubstitutions")
	await picture(app,"substitutions")
	await press(app,"BenchDetails")
	await picture(app,"bench-plan")
	await press(app,"CloseDrawer")
	assert(app.modal.plans[0].to_data() == prepared,"Navigating preparation/taker/bench drawers cannot alter the private plan")
	app.modal.select_slot(9)
	await press(app,"PlayerOverview")
	assert(is_instance_valid(app.modal.card_panel))
	await key(viewport,KEY_ESCAPE)
	await create_timer(0.22).timeout
	assert(is_instance_valid(app.modal) and not is_instance_valid(app.modal.card_panel),"Escape closes the player file before preparation")
	await press(app,"CommitMatch")
	assert(is_instance_valid(app.view) and app.view.sim == app.session.controller.model)
	await picture(app,"match")
	await key(viewport,KEY_SPACE)
	assert(app.view.paused)
	var paused_signature: Array = app.view.sim.signature()
	app.view._physics_process(1.0/60)
	assert(app.view.sim.signature() == paused_signature,"Pause cannot advance hidden football")
	await key(viewport,KEY_2)
	await key(viewport,KEY_SPACE)
	var ticks: int = app.view.sim.ticks
	app.view._physics_process(1.0/60)
	assert(app.view.sim.ticks == ticks+2)
	await key(viewport,KEY_1)
	app.view._physics_process(1.0/60)
	assert(app.view.sim.ticks == ticks+3)
	var before_autosave: int = app.session.profile.generation
	app.last_saved_tick = app.view.sim.ticks-600
	app._process(0)
	assert(app.session.profile.generation > before_autosave and app.session.controller.model == app.view.sim)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(app.view.paused)
	await key(viewport,KEY_SPACE)
	var signature: Array = app.view.sim.signature()
	await key(viewport,KEY_ESCAPE)
	await picture(app,"pause")
	await press(app,"CampaignSettings")
	assert(app.view.paused and app.view.sim.signature() == signature)
	await press(app,"CloseSettings")
	await press(app,"SaveExit")
	assert(app.page == "main" and app.session.preview().step == "match")
	await picture(app,"main-continue")
	await press(app,"ContinueRun")
	assert(app.view.sim.signature() == signature,"Continue restores exact disk match inputs/state")
	app.view.sim.scores = [1,0]
	app.view.sim.finish_match()
	app.view._sync_state()
	await picture(app,"full-time")
	await press(app,"ContinueResult")
	assert(app.page == "result")
	await picture(app,"result")
	await press(app,"ContinueCampaignResult")
	await press(app,"ConfirmAcquisition")
	assert(app.session.controller.snapshot().plan.cards.size() == 18)
	app.render("main")
	await press(app,"MainSettings")
	await picture(app,"settings")
	assert(app.find_child("Scale125",true,false) == null)
	await press(app,"SettingsControls")
	await press(app,"Rebindpause")
	await key(viewport,KEY_P)
	assert(app.preferences.data.keys.pause == KEY_P)
	await press(app,"Rebindspeed1")
	await key(viewport,KEY_P)
	assert(app.preferences.data.keys.speed1 == KEY_1 and not app.rebind.is_empty(),"Duplicate shortcuts cannot be committed")
	await key(viewport,KEY_ESCAPE)
	await press(app,"SettingsAccessibility")
	await press(app,"motion")
	assert(app.preferences.data.motion)
	await picture(app,"settings-accessibility")
	await press(app,"SettingsAudio")
	var volume := app.modal.find_child("MasterVolume",true,false) as HSlider
	volume.grab_focus()
	await key(viewport,KEY_LEFT)
	assert(is_equal_approx(app.preferences.data.volume,0.9))
	var loaded = app.Preferences.new(app.save_root)
	assert(loaded.data == app.preferences.data,"Settings persist independently on disk")
	await picture(app,"settings-audio")
	await press(app,"SettingsControls")
	await press(app,"ResetShortcuts")
	await picture(app,"settings-controls")
	await press(app,"SettingsAccessibility")
	await press(app,"motion")
	await press(app,"CloseSettings")
	app.render("discovered")
	await picture(app,"discovered")
	app.route()
	var markets := 0
	var principles := 0
	for victory in range(2,13):
		await press(app,"PrepareCampaign")
		await press(app,"CommitMatch")
		app.view.sim.scores = [2,1]
		app.view.sim.finish_match()
		app.view._sync_state()
		await press(app,"ContinueResult")
		if victory == 12: break
		await press(app,"ContinueCampaignResult")
		if app.page == "offer":
			var offer = app.screen.find_child("Acquisition",true,false)
			var before_signing: Dictionary = app.session.controller.snapshot()
			await press(app,"ConfirmAcquisition")
			var option := app.modal.find_child("OutgoingPlayer",true,false) as OptionButton
			var release_index := option.item_count-1
			while option.is_item_disabled(release_index): release_index -= 1
			option.select(release_index)
			option.item_selected.emit(release_index)
			assert(app.session.controller.snapshot() == before_signing,"Choosing a replacement is only a preview")
			await picture(app,"recruitment-replacement")
			await press(app,"CloseDrawer")
			assert(app.session.controller.snapshot() == before_signing and offer.outgoing.is_empty(),"Cancel restores draft facts and leaves squad/cash unchanged")
			await press(app,"ConfirmAcquisition")
			option = app.modal.find_child("OutgoingPlayer",true,false)
			option.select(release_index)
			option.item_selected.emit(release_index)
			await press(app,"CommitReplacement")
		if app.page == "offer" and app.session.controller.snapshot().step == "market":
			markets += 1
			if markets == 1:
				var initial_offer = app.screen.find_child("Acquisition",true,false)
				assert(initial_offer.selected in initial_offer.state.market.cards and initial_offer.outgoing.is_empty(),"A new market cannot inherit an old recruit/release preview")
				await picture(app,"market")
				cards_fit(app)
				var offer = app.screen.find_child("Acquisition",true,false)
				var state: Dictionary = app.session.controller.snapshot()
				var stock: Array = state.market.cards.duplicate()
				await press(app,"MarketNext")
				assert(offer.page == 1 and offer.selected in stock.slice(4,8))
				cards_fit(app)
				await press(app,"MarketPrevious")
				assert(offer.page == 0 and app.session.controller.snapshot().market.cards == stock,"Paging cannot refresh stock")
				var cheapest: Array = state.market.cards.duplicate()
				cheapest.sort_custom(func(a,b): return app.library.price(app.library.cards[a].rating()) < app.library.price(app.library.cards[b].rating()))
				offer.select(cheapest[0])
				var outgoing_index: int = state.plan.cards.size()-1
				for starter in state.plan.starters:
					var old: Resource = app.library.cards[state.plan.cards[starter].card_id]
					if old.primary_role in app.library.cards[cheapest[0]].natural_roles:
						outgoing_index = starter
						break
				await press(app,"ConfirmAcquisition")
				var outgoing_choice := app.modal.find_child("OutgoingPlayer",true,false) as OptionButton
				outgoing_choice.select(outgoing_index+1)
				outgoing_choice.item_selected.emit(outgoing_index+1)
				assert(offer.facts.funds.text == app.money(state.cash-app.library.price(app.library.cards[cheapest[0]].rating())))
				await picture(app,"market-signing")
				var released: Resource = app.library.cards[state.plan.cards[outgoing_index].card_id]
				assert(offer.facts.outgoing.text == released.display_name and offer.facts.outgoing_rating.text == str(released.rating()) and offer.facts.outgoing_role.text == released.primary_role)
				assert(offer.facts.outgoing.get_global_rect().end.x <= offer.facts.outgoing_rating.get_global_rect().position.x and offer.facts.outgoing_rating.get_global_rect().end.x <= offer.facts.outgoing_role.get_global_rect().position.x,"Outgoing name, rating and role occupy separate aligned columns")
				await press(app,"CommitReplacement")
				var signed_offer = app.screen.find_child("Acquisition",true,false)
				assert(signed_offer.outgoing.is_empty(),"A released outgoing player cannot remain selected for a second purchase")
			await press(app,"LeaveOffer")
		if app.page == "coaching":
			principles += 1
			await picture(app,"coaching")
			await press(app,app.session.controller.snapshot().coaching[0])
			await press(app,"ConfirmPrinciple")
	assert(app.page == "terminal" and app.session.preview().is_empty() and markets == 3 and principles == 2)
	await picture(app,"champions")
	await press(app,"ContinueCampaignResult")
	await press(app,"Records")
	await picture(app,"records")
	await press(app,"RecordXI_"+Profile.ranked(app.session.profile)[0].run_id)
	await picture(app,"record-xi")
	var recorded_profile: Dictionary = app.session.profile.duplicate(true)
	await press(app,"InspectRecordPlayer")
	assert(is_instance_valid(app.modal.card_panel))
	await key(viewport,KEY_ESCAPE)
	await create_timer(0.22).timeout
	assert(is_instance_valid(app.modal) and not is_instance_valid(app.modal.card_panel) and app.session.profile == recorded_profile,"Historical card inspection closes before its read-only record XI and never mutates the profile")
	await key(viewport,KEY_ESCAPE)
	app.render("origin")
	app.start_origin("ENG")
	await press(app,"ConfirmAcquisition")
	for defeat in 3:
		await press(app,"PrepareCampaign")
		await press(app,"CommitMatch")
		app.view.sim.scores = [0,1]
		app.view.sim.finish_match()
		app.view._sync_state()
		await press(app,"ContinueResult")
		if defeat < 2: await press(app,"ContinueCampaignResult")
	assert(app.page == "terminal" and app.session.controller.snapshot().defeats == 3)
	await picture(app,"three-defeats")
	app.render("origin")
	app.start_origin("JPN")
	await press(app,"ConfirmAcquisition")
	var before_abandon: Dictionary = app.session.controller.snapshot()
	app.menu()
	await press(app,"AbandonRun")
	await press(app,"CancelConfirmation")
	assert(app.session.controller.snapshot() == before_abandon)
	app.menu()
	await press(app,"AbandonRun")
	await press(app,"AcceptConfirmation")
	assert(app.page == "terminal" and app.session.controller.snapshot().step == "abandoned" and not app.session.profile.discoveries.is_empty())
	var good_store: RefCounted = app.session.store
	app.session.store = FailedStore.new(app.save_root)
	app.save_and_exit()
	assert(app.session.blocked and app.find_child("RetryRecovery",true,false) != null,"A failed save exposes recovery instead of pretending to Continue")
	await picture(app,"recovery")
	app.session.store = good_store
	await press(app,"RetryRecovery")
	assert(not app.session.blocked and app.page == "main")
	var directory: String = app.session.store.directory
	app.queue_free()
	await process_frame
	for file in DirAccess.get_files_at(directory): assert(DirAccess.remove_absolute(directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(directory) == OK)
	viewport.queue_free()
	print("CAMPAIGN UI: native new-run, all twelve wins/rewards, three defeats, signing/market, preparation, exact Continue, settings and discovery checks passed")
	quit()

func motion(app: Control) -> void:
	await press(app,"NewRun")
	await press(app,"StartRun")
	await press(app,"ConfirmAcquisition")
	await press(app,"PrepareCampaign")
	await press(app,"CommitMatch")
	await key(app.get_viewport(),KEY_2)
	app.view.paused = false
	app.view.set_physics_process(true)
	DirAccess.make_dir_recursive_absolute("res://reports/motion/campaign")
	for frame in 36:
		await create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		assert(app.get_viewport().get_texture().get_image().save_png("res://reports/motion/campaign/frame-%03d.png" % frame) == OK)
	assert(app.view.sim.ticks > 200,"The displayed 2x match advances through native physics")
	await key(app.get_viewport(),KEY_ESCAPE)
	var paused: Array = app.view.sim.signature()
	await create_timer(0.3).timeout
	assert(app.view.sim.signature() == paused,"Opening the menu freezes authoritative football")
	await press(app,"Resume")
	await create_timer(0.3).timeout
	assert(app.view.sim.signature() != paused)
	app.view.set_physics_process(false)
	while app.view.sim.period != app.view.Match.Period.HALF_TIME and not app.view.sim.finished: app.view.sim.step()
	app.view._sync_state()
	await picture(app,"actual-halftime")
	await press(app,"ContinueHalf")
	while not app.view.sim.finished:
		app.view.sim.step()
		if app.view.sim.period == app.view.Match.Period.HALF_TIME:
			app.view._sync_state()
			await press(app,"ContinueHalf")
	app.view._sync_state()
	await picture(app,"actual-full-time")
	await press(app,"ContinueResult")
	await picture(app,"actual-result")
	var directory: String = app.session.store.directory
	app.queue_free()
	await process_frame
	for file in DirAccess.get_files_at(directory): assert(DirAccess.remove_absolute(directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(directory) == OK)
	print("MOTION: native 2x physics, calm paused menu, resume, actual halftime/Continue and genuine match result passed")
	quit()

func probe(app: Control) -> void:
	# Two executable launches share only an isolated disk slot and a plain test receipt.
	var args := OS.get_cmdline_user_args()
	var id: String = args[-1]
	assert(id.is_valid_identifier())
	var folder := "user://campaign_ui_test_probe_"+id
	assert(DirAccess.get_files_at(app.session.store.directory).is_empty())
	assert(DirAccess.remove_absolute(app.session.store.directory) == OK)
	app.save_root = folder
	app.session = app.Session.new(folder,app.library)
	app.preferences = app.Preferences.new(folder)
	app.render("main")
	var receipt := folder+"/ui-receipt.bin"
	if "--write-ui-probe" in args:
		await press(app,"NewRun")
		await press(app,"StartRun")
		await press(app,"ConfirmAcquisition")
		await press(app,"PrepareCampaign")
		await press(app,"CommitMatch")
		for tick in 777: app.view.sim.step()
		app.view._sync_state()
		var copy = load("res://match/match_snapshot.gd").restore(load("res://match/match_snapshot.gd").capture(app.view.sim))
		for tick in 600: copy.step()
		var output := FileAccess.open(receipt,FileAccess.WRITE)
		output.store_var({"now":app.view.sim.signature(),"future":copy.signature()})
		output.close()
		assert(app.preferences.change("volume",0.4).ok)
		await key(app.get_viewport(),KEY_ESCAPE)
		await press(app,"SaveExit")
		assert(app.session.preview().step == "match")
		print("UI PROBE: native Save and exit wrote an exact mid-match checkpoint")
	else:
		var input := FileAccess.open(receipt,FileAccess.READ)
		var expected: Dictionary = input.get_var(false)
		input.close()
		assert(is_equal_approx(app.preferences.data.volume,0.4))
		await press(app,"ContinueRun")
		assert(app.view.sim.signature() == expected.now)
		for tick in 600: app.view.sim.step()
		assert(app.view.sim.signature() == expected.future,"A fresh executable Continue preserves the future RNG/state")
		var directory: String = app.session.store.directory
		app.queue_free()
		await process_frame
		for file in DirAccess.get_files_at(directory): assert(DirAccess.remove_absolute(directory+"/"+file) == OK)
		assert(DirAccess.remove_absolute(directory) == OK)
		print("UI PROBE: fresh executable Continue, settings and exact 600-tick future passed")
	quit()
