extends SceneTree
const App = preload("res://ui/campaign_app.gd")
var checks := 0
func verify(value: bool, message: String) -> void:
	checks+=1
	assert(value,message)
func _initialize() -> void: call_deferred("run")
func frames(count: int = 3) -> void:
	for index in count: await process_frame
func glyph_y(viewport: SubViewport, button: Button, scale: float) -> float:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var rect := button.get_global_rect()
	var count := 0
	var total := 0.0
	for y in range(ceili(rect.position.y+8*scale),floori(rect.end.y-8*scale)):
		for x in range(ceili(rect.position.x+60*scale),floori(rect.end.x-20*scale)):
			var colour := image.get_pixel(x,y)
			if colour.r > 0.85 and colour.g > 0.8 and colour.b > 0.6:
				total+=y
				count+=1
	verify(count > 0,"Button text is present in the real rendered control")
	return total/maxi(1,count)
func run() -> void:
	for extent in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1280,689),Vector2i(1640,880)]:
		var viewport := SubViewport.new()
		viewport.size=extent
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app := App.new()
		app.master_new_runs=false # Existing five-card fixture; new drafts have separate native coverage.
		app.apply_display=false
		app.save_root="user://pixel_polish_"+str(Time.get_ticks_usec())
		viewport.add_child(app)
		await frames()
		app.preferences.data.motion=true
		app.settings()
		await frames()
		var audio: Button=app.modal.find_child("SettingsAudio",true,false)
		var rest := audio.get_global_rect()
		var base_glyph: float=await glyph_y(viewport,audio,app.canvas.scale.x)
		var down := InputEventMouseButton.new()
		down.button_index=MOUSE_BUTTON_LEFT
		down.pressed=true
		down.position=rest.get_center()
		viewport.push_input(down)
		await frames()
		var held_glyph: float=await glyph_y(viewport,audio,app.canvas.scale.x)
		verify(absf(held_glyph-base_glyph-2*app.canvas.scale.x) < 0.8,"Text and icon descend with the button face, not independently")
		verify(audio.get_global_rect() == rest,"Press leaves the action's hit box stable")
		var release := InputEventMouseButton.new()
		release.button_index=MOUSE_BUTTON_LEFT
		release.position=Vector2.ZERO
		viewport.push_input(release)
		await frames()
		for category in ["audio","display","controls","accessibility","audio"]:
			app.settings_section=category
			app.settings()
			await frames()
			verify(audio.get_global_rect() == rest,"Selected/unselected categories share exact bounds")
		verify(app.modal.find_child("CloseSettings",true,false).position.x+136 <= 1232,"Back respects the panel's inner right padding")
		app.close_modal()
		for code in app.library.countries:
			app.origin_selection=code
			app.render("origin")
			await frames()
			for node in app.screen.get_children():
				if not "card_views" in node: continue
				verify(node.card_views.size() == 11,"Complete origin preview")
				for card in node.card_views:
					verify(card.portrait.texture != null,"Origin portrait metadata is wired for "+code)
					for other in node.card_views:
						if other != card: verify(not card.get_rect().intersects(other.get_rect()),"Origin cards do not collide")
			var button: Control=app.screen.find_child("StartRun",true,false)
			verify(Rect2(Vector2.ZERO,extent).encloses(button.get_global_rect()),"Footer fits the actual client viewport")
		app.start_origin("FRA")
		await frames()
		var offer: Control=app.screen.find_child("Acquisition",true,false)
		var data: Dictionary=app.session.controller.snapshot()
		verify(app.session.act("acquire",[offer.tiles[0].definition.card_id,""],data.revision).ok,"Isolated run enters squad")
		app.route()
		app.squad()
		await frames()
		var editor: Control=app.modal
		var footer: Control=editor.find_child("ApplySquad",true,false)
		verify(Rect2(Vector2.ZERO,extent).encloses(footer.get_global_rect()),"Squad Apply stays inside the viewport")
		for card in editor.get_children():
			if str(card.name).begins_with("BenchCard"):
				verify(card.get_rect().end.y < 634,"Entire substitute card clears the footer rule")
		app.queue_free()
		await frames()
		viewport.queue_free()
		await frames()
	print("PIXEL POLISH checks=",checks," failures=0; six origins, portrait/card bounds and footer safe areas at four viewport sizes")
	quit()
