extends SceneTree
const App = preload("res://ui/campaign_app.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func run() -> void:
	var height := 1080 if "--1080" in OS.get_cmdline_user_args() else 720
	var viewport := SubViewport.new()
	viewport.size = Vector2i(height*16/9,height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app := App.new()
	app.save_root = "user://motion_check_"+str(Time.get_ticks_usec())
	app.apply_display = false
	viewport.add_child(app)
	await frames(20)
	var initial: Dictionary = app.session.profile.duplicate(true)
	var button: Button = app.screen.find_child("NewRun",true,false)
	check(button.has_meta("motion_feedback"),"Production actions receive shared motion")
	viewport.gui_release_focus()
	var hover := InputEventMouseMotion.new()
	hover.position = button.get_global_rect().get_center()
	viewport.push_input(hover)
	await frames(12)
	check(button.scale == Vector2.ONE and button.self_modulate.r > 1,"Hover animates brightness while keeping pixel scale and layout stable")
	var resting := button.self_modulate.r
	var down := InputEventMouseButton.new()
	down.position = hover.position
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	viewport.push_input(down)
	await frames(6)
	check(button.self_modulate.r < resting and button.scale == Vector2.ONE,"Press changes the palette immediately without resampling pixel artwork")
	var cancel := InputEventMouseButton.new()
	cancel.position = Vector2.ZERO
	cancel.button_index = MOUSE_BUTTON_LEFT
	viewport.push_input(cancel)
	app.settings()
	await frames(20)
	var shell := app.modal
	var body := app.settings_content
	app.settings_section = "audio"
	app.settings()
	check(app.modal == shell and app.settings_content != body,"Category changes retain the production settings shell")
	check(body.process_mode == Node.PROCESS_MODE_DISABLED and not body.visible,"Outgoing category is hidden and inactive before replacement")
	for section in ["controls","accessibility","audio","display"]:
		app.settings_section = section
		app.settings()
		await frames(1)
	await frames(20)
	check(shell.get_child_count() < 12,"Rapid category changes leave no old page accumulation")
	app.preferences.data.motion = true
	app.apply_preferences()
	app.settings_section = "audio"
	app.settings()
	check(app.settings_content.modulate.a == 1 and app.settings_content.position == Vector2(352,202),"Reduced motion replaces content immediately at its layout origin")
	app.close_modal()
	app.render("origin")
	check(app.screen.modulate.a == 1,"Reduced scene navigation is immediate")
	app.preferences.data.motion = false
	await frames(2)
	var old := app.screen
	app.render("records")
	check(not old.visible and old.process_mode == Node.PROCESS_MODE_DISABLED,"Scene transition cannot layer two pages or receive outgoing input")
	check(old.find_child("StartRun",true,false) == null,"Old controls cannot shadow new control lookup or receive duplicate actions")
	await frames(20)
	check(not is_instance_valid(old) and app.screen.modulate.a == 1,"Transition disposes the outgoing page and settles completely")
	check(app.session.profile == initial,"Motion and browsing never mutate campaign/profile facts")
	DirAccess.make_dir_recursive_absolute("res://reports/motion")
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://reports/motion/records-%d.png" % height)
	print("MOTION ",height," checks=",checks," failures=",failures)
	app.queue_free()
	quit(1 if failures else 0)
