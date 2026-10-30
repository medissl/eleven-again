extends SceneTree
const App = preload("res://ui/campaign_app.gd")
const Session = preload("res://persistence/campaign_session.gd")
var checks := 0
var failures := 0
var held := false
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func mouse(viewport: SubViewport, point: Vector2, down: Variant = null, relative: Vector2 = Vector2.ZERO) -> void:
	if down == null:
		var motion := InputEventMouseMotion.new()
		motion.position=point
		motion.relative=relative
		motion.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
		viewport.push_input(motion)
	else:
		var button := InputEventMouseButton.new()
		button.position=point
		button.button_index=MOUSE_BUTTON_LEFT
		button.pressed=down
		held=down
		viewport.push_input(button)
	await frames(2)
func click(viewport: SubViewport, control: Control) -> void:
	var point := control.get_global_rect().get_center()
	await mouse(viewport,point)
	await mouse(viewport,point,true)
	await mouse(viewport,point,false)
func capture(viewport: SubViewport, name: String, height: int) -> void:
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png("res://reports/squad/"+name+"-%d.png" % height) == OK,"Native squad capture: "+name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/squad")
	var height := 1080 if "--1080" in OS.get_cmdline_user_args() else 720
	var viewport := SubViewport.new()
	viewport.size=Vector2i(height*16/9,height)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := App.new()
	app.apply_display=false
	app.save_root="user://squad_drag_"+str(Time.get_ticks_usec())
	viewport.add_child(app)
	app.start_origin("ENG")
	var state: Dictionary=app.session.controller.snapshot()
	check(app.session.act("acquire",[state.offer.cards[0],""],state.revision).ok,"Disposable owned squad is acquired through the real journal")
	app.route()
	app.squad()
	await frames(24)
	var editor: Control=app.modal
	var before: Dictionary=app.session.controller.snapshot()
	for formation in ["4-3-3","4-4-2","4-2-3-1"]:
		editor.plans[0].formation=formation
		editor.rebuild()
		await frames(3)
		var cards: Array=editor.field.card_views
		for index in cards.size():
			check(Rect2(Vector2.ZERO,editor.field.size).encloses(Rect2(cards[index].position,cards[index].size)),"Every complete field card fits in "+formation)
			for other in range(index+1,cards.size()):
				check(not Rect2(cards[index].position,cards[index].size).intersects(Rect2(cards[other].position,cards[other].size)),"Field card bounds never overlap in "+formation)
		await capture(viewport,"formation-"+formation,height)
	editor.plans[0].formation="4-3-3"
	editor.rebuild()
	await frames(3)
	check(editor.field.card_views.size() == 11 and editor.find_child("AutoHighestOVR",true,false) != null,"Card pitch, left management rail and bench are the production editor")
	await capture(viewport,"team",height)
	await click(viewport,editor.field.card_views[9])
	check(is_instance_valid(editor.popup) and editor.popup.find_child("ReplacePlayer",true,false) != null and editor.popup.find_child("PlayerOverview",true,false) != null,"Clicking a field card offers Replace and Overview")
	check(editor.popup.find_child("Training",true,false) == null,"There is no training control")
	await capture(viewport,"player-actions",height)
	editor.handle_cancel()
	await click(viewport,editor.find_child("SquadReserves",true,false))
	await frames(16)
	var drawer: Control=editor.card_panel
	var plan: Resource=editor.plans[0]
	var reserve := -1
	for index in plan.bench_order:
		if "GK" not in plan.cards[index].natural_roles: reserve=index; break
	var source: Control=drawer.find_child("ReserveCard"+str(reserve),true,false)
	check(source != null,"Reserves drawer contains the actual owned non-starters")
	await capture(viewport,"reserves",height)
	var origin := source.get_global_rect().get_center()
	await mouse(viewport,origin)
	await mouse(viewport,origin,true)
	await mouse(viewport,origin+Vector2(36,0),null,Vector2(36,0))
	await frames(3)
	check(viewport.gui_is_dragging() and not drawer.visible,"Starting a real reserve drag closes the covering drawer")
	var destination: Vector2=editor.field.card_views[9].get_global_rect().get_center()
	await mouse(viewport,destination,null,destination-origin)
	await mouse(viewport,destination,false)
	await frames(10)
	check(editor.plans[0].starters[9] == reserve and editor.plans[0].errors().is_empty(),"Dropping on a field card replaces that slot with a legal owned player")
	check(app.session.controller.snapshot() == before,"Drag/drop edits stay private before Apply")
	await capture(viewport,"after-drop",height)
	check(not editor.field.card_views[0]._can_drop_data(Vector2.ZERO,{"type":"foreign"}),"Foreign drag payloads are rejected")
	await click(viewport,editor.find_child("AutoHighestOVR",true,false))
	await frames(8)
	var optimized: Dictionary=editor.plans[0].to_data()
	check(editor.plans[0].errors().is_empty(),"Auto build leaves a legal XI")
	await click(viewport,editor.find_child("ApplySquad",true,false))
	await frames(20)
	check(app.session.controller.snapshot().plan == optimized and app.session.controller.snapshot().step == "prepare","Apply saves the private squad and stays before kickoff")
	check(Session.new(app.save_root).controller.snapshot().plan == optimized,"Saved drag/auto-build plan survives disk reload")
	check(not app.session.act("update_plan",[preload("res://squad/lineup.gd").from_data(optimized)],before.revision).ok,"A duplicate stale Apply is rejected")
	check(app.session.controller.snapshot().cash == before.cash and app.session.controller.snapshot().acquisitions == before.acquisitions,"Squad editing changes neither currency nor ownership")
	print("SQUAD DRAG ",height," checks=",checks," failures=",failures)
	app.queue_free()
	quit(1 if failures else 0)
