extends SceneTree
const App = preload("res://ui/campaign_app.gd")
const Session = preload("res://persistence/campaign_session.gd")
const Auto = preload("res://squad/auto_lineup.gd")
const Lineup = preload("res://squad/lineup.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func capture(viewport: SubViewport, name: String, height: int) -> void:
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png("res://reports/recruitment/"+name+"-%d.png" % height) == OK,"Native production capture: "+name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/recruitment")
	var height := 1080 if "--1080" in OS.get_cmdline_user_args() else 720
	var viewport := SubViewport.new()
	viewport.size=Vector2i(height*16/9,height)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := App.new()
	app.apply_display=false
	app.save_root="user://recruitment_presentation_"+str(Time.get_ticks_usec())
	viewport.add_child(app)
	await frames(25)
	check(app.screen.find_child("NewRun",true,false) != null and app.arena.texture != null,"Normal campaign entry uses the approved stadium menu")
	await capture(viewport,"home",height)
	app.start_origin("ENG")
	await frames(4)
	var offer: Control=app.screen.find_child("Acquisition",true,false)
	check(offer.tiles.size() == 5,"Free signing shows five complete native cards")
	await capture(viewport,"deal-stack",height)
	await frames(60)
	check(offer.tiles.all(func(card): return not card.get_meta("dealing",false)),"Stack animation settles every card into its layout slot")
	check(app.audio.cues.has("shuffle") and app.audio.cues.count("place") >= 5,"Real card shuffle and placement recordings accompany the deal")
	await capture(viewport,"free-pick",height)
	var id: String=offer.tiles[1].definition.card_id
	offer.select(id)
	var revision: int=app.session.controller.revision()
	var old_generation: int=app.session.profile.generation
	offer.acquire()
	await frames(45)
	check(is_instance_valid(app.walkout) and app.session.controller.snapshot().plan.cards.size() == 17,"Signing commits once before the tunnel presentation")
	var acquired: Dictionary=app.session.controller.snapshot()
	check(app.session.profile.generation == old_generation+1 and app.session.profile.discoveries.has(id),"Owned card and discovery are durably published together")
	check(not app.session.act("acquire",[id,""],revision).ok and app.session.controller.snapshot() == acquired,"Duplicate signing during walkout cannot charge or grant twice")
	check(Session.new(app.save_root).controller.snapshot() == acquired,"A fresh session resumes the committed signing during its presentation")
	await capture(viewport,"walkout-position",height)
	await frames(64)
	await capture(viewport,"walkout-country",height)
	await frames(66)
	await capture(viewport,"walkout-playstyle",height)
	await frames(160)
	check(app.walkout.confirm.visible and app.audio.in_walkout,"Walkout reaches the actual card reveal with its own music")
	check(app.walkout.card.content.scale.x > 0 and app.walkout.card.portrait.size.x > 0,"Revealed native card has a nonzero rendered layout")
	await capture(viewport,"walkout-reveal",height)
	app.walkout.confirm_player()
	await frames(12)
	await capture(viewport,"recruited",height)
	app.walkout.confirm_player()
	await frames(24)
	check(app.page == "board" and not is_instance_valid(app.walkout) and app.session.controller.snapshot() == acquired,"Confirm then Continue returns to the saved campaign without another transaction")
	await capture(viewport,"pyramid",height)
	app.squad()
	await frames(25)
	var owned_before: Dictionary=app.session.controller.snapshot()
	var plan: Resource=app.modal.plans[0]
	var before_total := 0
	for slot in 11: before_total+=plan.cards[plan.starters[slot]].rating(Lineup.ROLES[plan.formation][slot],true)
	check(Auto.apply(plan),"Highest OVR finds a trained-keeper legal XI")
	var after_total := 0
	for slot in 11: after_total+=plan.cards[plan.starters[slot]].rating(Lineup.ROLES[plan.formation][slot],true)
	check(after_total >= before_total and plan.errors().is_empty(),"Automatic XI never lowers the total effective slot OVR")
	var first: Dictionary=plan.to_data()
	Auto.apply(plan)
	check(plan.to_data() == first,"Highest OVR has stable tie-breaking and no random side effects")
	check(app.session.controller.snapshot() == owned_before,"Squad preview stays private before Apply")
	app.modal.rebuild()
	await frames(25)
	await capture(viewport,"squad",height)
	app.modal.submitted.emit(plan,plan,false)
	await frames(24)
	var saved_plan: Dictionary=app.session.controller.snapshot().plan
	check(saved_plan == plan.to_data() and Session.new(app.save_root).controller.snapshot().plan == saved_plan,"Apply persists the owned plan without committing a match")
	check(app.session.controller.snapshot().step == "prepare" and app.session.controller.snapshot().cash == owned_before.cash,"Squad editing advances neither campaign nor currency")
	app.prepare()
	await frames(25)
	check(app.modal.opponent_mode and app.modal.team == 1,"Prepare is the opponent view; Squad is separate")
	check(app.modal.find_child("LineupPitch",true,false).card_views.size() == 11,"Opponent shape uses eleven real native cards")
	await capture(viewport,"opponent",height)
	app.close_modal()
	app.settings_section="audio"
	app.settings()
	await frames(24)
	await capture(viewport,"settings-audio",height)
	check(app.modal.find_child("MusicVolume",true,false) != null and app.modal.find_child("EffectsVolume",true,false) != null,"Production audio settings expose independent channels")
	app.close_modal()
	var legend: Resource=app.library.recruits.filter(func(card): return card.tier() == "legend")[0]
	var proof := preload("res://ui/recruitment_walkout.gd").new()
	proof.definition=legend; proof.info=app.library.metadata(legend.card_id); proof.audio=app.audio; proof.newly_discovered=true
	app.canvas.add_child(proof)
	proof.age=4.1
	await frames(12)
	await capture(viewport,"legend-reveal",height)
	check(proof.card.legend_reveal and proof.headline.text == "LEGEND DISCOVERED","Legend climax uses the shared purple frame, glow and truthful discovery text")
	proof.queue_free()
	await frames(2)
	print("RECRUITMENT ",height," checks=",checks," failures=",failures)
	app.queue_free()
	quit(1 if failures else 0)
