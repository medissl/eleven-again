extends SceneTree
const ROOT := "res://outputs/fc-mobile-ui-v6/"
const Model = preload("res://outputs/fc-mobile-ui-v6/model.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void: call_deferred("run")

func click(viewport: SubViewport, node: Control) -> void:
	var point := node.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event)
		await process_frame

func key(viewport: SubViewport, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	viewport.push_input(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	viewport.push_input(event)

func has_chalk(pixels: Image, point: Vector2i) -> bool:
	for y in range(point.y-2,point.y+3):
		for x in range(point.x-2,point.x+3):
			var color := pixels.get_pixel(x,y)
			if color.r > 0.68 and color.g > 0.68 and color.b > 0.55: return true
	return false

func consistent_type(node: Node) -> bool:
	if node is Control and not node.is_visible_in_tree(): return true
	if (node is Label or node is Button) and not node.text.is_empty():
		if not node.get_theme_font("font").get_font_name().begins_with("Saira"): return false
	for child in node.get_children():
		if not consistent_type(child): return false
	return true

func run() -> void:
	var model := Model.new()
	model.cash = 3000000
	check(model.reroll() and model.cash == 2000000,"First roll costs exactly $1m")
	check(model.reroll() and model.cash == 0,"Second roll costs exactly $2m")
	var revision: int = model.revision
	check(not model.reroll() and model.revision == revision,"Third roll cannot spend or mutate")
	model.new_run("JPN")
	check(model.cash == 10000000 and model.wins == 0,"New-run proposed budget")
	model.cash = 0
	check(not model.reroll() and model.cash == 0,"Unaffordable reroll is inert")
	model.cash = 50000000
	model.wins = 6
	check(model.buy(80),"First market signing")
	check(model.restock() and model.market_bought == 1 and not model.restock(),"Restock cannot reset purchase count or repeat")
	check(model.buy(80) and not model.buy(80) and not model.restock(),"No further spending after the two-signing cap")
	model.new_run("ENG")
	model.cash = 50000000
	check(model.buy(80,"sample") and not model.buy(80,"sample"),"Same card cannot be purchased twice")
	for ovr in range(65,121): check(model.price(ovr) > 0 and model.price(ovr)%1000000 == 0,"Integer cash price")
	var height := 720
	if "--1080" in OS.get_cmdline_user_args(): height = 1080
	var viewport := SubViewport.new()
	viewport.size = Vector2i(height*16/9,height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app: Control = load(ROOT+"preview.gd").new()
	viewport.add_child(app)
	app.set_anchors_preset(Control.PRESET_TOP_LEFT)
	app.size = Vector2(viewport.size)
	await process_frame
	var catalogue: RefCounted = load("res://content/catalogue.gd").new()
	var probe: Control = app.C.Card.new()
	viewport.add_child(probe)
	probe.hide()
	probe.size = Vector2(300,420)
	for definition in catalogue.cards:
		var country: String = catalogue.metadata(definition.card_id).get("country_code","")
		check(app.C.flag(country) != null,"Every settled catalogue card has an accurate available flag asset")
		var before: Dictionary = definition.to_data()
		probe.bind(definition,catalogue.metadata(definition.card_id))
		check(probe.portrait.texture != null and definition.to_data() == before,"Shared frame preserves every definition and original portrait binding")
		var same_family := true
		for label in probe.content.get_children():
			if label is Label and not label.text.is_empty() and not label.get_theme_font("font").get_font_name().begins_with("Saira"): same_family=false
		check(same_family,"All 200 cards use the same family as actions, numbers and UI labels")
	probe.free()
	var glyphs: GDScript = load(ROOT+"ability_icons.gd")
	var icon_hashes := {}
	for trait_id in catalogue.cards[0].Traits.catalogue:
		var icon: Texture2D = glyphs.texture(trait_id)
		check(icon != null and icon.get_width() == 64,"Every authoritative ability has a crisp white glyph")
		icon_hashes[hash(icon.get_image().get_data())] = true
	check(icon_hashes.size() == 36,"All 36 ability glyphs are distinct")
	var directory := ROOT+"captures"
	DirAccess.make_dir_recursive_absolute(directory)
	for page in ["home","origin","pyramid","squad","opponent","reward","market","player","settings","records","collection","result","coaching","champions","defeat","match"]:
		app.go(page,false)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		check(app.content.modulate.a == 1,"Complete stable native page")
		check(consistent_type(app.content),"Visible native labels and buttons share one athletic font family: "+page)
		var pixels := viewport.get_texture().get_image()
		check(pixels.save_png(directory+"/%s-%d.png" % [page,height]) == OK,"Native image written")
		if page == "squad":
			check(app.content.find_child("PitchSlot0",true,false) != null,"Eleven card pitch exists")
			app.formation_drawer()
			await create_timer(0.25).timeout
			var choice: Button = app.drawer.find_child("Formation7",true,false)
			await click(viewport,choice)
			check(app.formation == "3-5-2" and app.page == "squad","All formation choices actually update native layout")
			app.formation = "4-3-3"
		if page == "player":
			check(app.content.find_child("StatPHY",true,false) != null,"Player sheet retains all six domains, including keeper physical ability")
			var effect: Label = app.content.find_child("TraitEffect",true,false)
			if effect != null:
				print("TRAIT BODY size=",effect.size," lines=",effect.get_line_count())
				check(effect.size.x <= 720 and effect.get_line_count() > 1,"Player trait copy stays inside the native sheet")
		if page == "reward":
			var badge: Button = app.content.find_child("AbilityIcon",true,false)
			badge.grab_focus()
			await process_frame
			check(is_instance_valid(badge.hint),"Keyboard focus exposes the actual ability name and effect")
			await process_frame
			var details: Label = badge.hint.get_child(1)
			check(details.size.x < badge.hint.size.x and details.get_line_count() > 1,"Ability details wrap inside their glass panel")
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(directory+"/ability-details-%d.png" % height)
			await key(viewport,KEY_ESCAPE)
			check(app.page == "reward" and not is_instance_valid(badge.hint),"Escape closes ability details before leaving recruitment")
			viewport.gui_release_focus()
		if page == "match":
			check(app.live_view.hud.kit_centers.size() == 2,"Both native uniform icons retained")
			check(app.live_view.pitch.size.x > 900 and app.live_view.pitch.size.y > 600,"Full native field and markings retain their original frame")
			var scale_factor: float = viewport.size.x/1280.0
			for team in 2:
				var at := Vector2i(app.live_view.hud.kit_centers[team]*scale_factor)
				check(pixels.get_pixelv(at).is_equal_approx(app.live_view.hud.team_kits[team]),"Actual native uniform pixels are visible, not covered by the design skin")
			for marking in [Vector2(11,34),Vector2(94,34),Vector2(20.15,34),Vector2(84.85,34),Vector2(61.65,34),Vector2(0.707,0.707),Vector2(104.293,67.293)]:
				check(has_chalk(pixels,Vector2i(app.live_view._field(marking)*scale_factor)),"Actual pitch spots, D arcs, centre circle and corner lines remain rendered")
		if page == "reward":
			for index in 5:
				var node: Control = app.content.find_child("OfferCard"+str(index),true,false)
				check(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(Rect2(node.position,node.size)),"Five complete cards fit at 720p logical")
		if page == "market":
			var old_card: String = app.offers[app.model.choice].card_id
			await click(viewport,app.content.find_child("MarketPage",true,false))
			check(app.market_page == 1 and app.offers[app.model.choice].card_id != old_card,"All eight market cards are reachable without refreshing stock")
			app.market_page = 0
			app.model.choice = 0
		if page == "settings":
			var shell_id: int = app.content.get_instance_id()
			var category: Button = app.content.find_child("SettingsAudio",true,false)
			await click(viewport,category)
			check(app.content.get_instance_id() == shell_id and app.settings_category == "Audio","Category change preserves settings shell")
			await create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			check(viewport.get_texture().get_image().save_png(directory+"/settings-audio-%d.png" % height) == OK,"Audio category native reference")
			await key(viewport,KEY_TAB)
			check(viewport.gui_get_focus_owner() != null,"Tab reaches native settings controls")
	app.go("settings",false)
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var sample_region := Rect2i(Vector2i(Vector2(352,296)*height/720.0),Vector2i(Vector2(210,44)*height/720.0))
	var opaque_old := viewport.get_texture().get_image().get_region(sample_region).get_data()
	app.go("records")
	app.transition.pause()
	app.content.modulate.a = 0
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().get_region(sample_region).get_data() == opaque_old,"Zero-alpha incoming glass cannot erase retained outgoing content")
	app.transition.kill()
	app.go("pyramid",false)
	for frame in 16:
		app.go("squad" if frame%2 == 0 else "pyramid")
		check(app.outgoing.modulate.a == 1,"Rapid transitions always retain an opaque outgoing page")
		await process_frame
	app.go("squad",false)
	app.formation_drawer()
	await process_frame
	await key(viewport,KEY_ESCAPE)
	check(app.page == "squad" and (not is_instance_valid(app.drawer) or app.drawer.is_queued_for_deletion()),"Escape closes the drawer before leaving Squad")
	app.reduced_motion = true
	app.go("settings")
	check(app.content.modulate.a == 1 and app.content.position == Vector2.ZERO,"Reduced motion has no blank/fade wait")
	var font: Font = app.theme.get_font("font","Score")
	check(absf(font.get_string_size("1111",0,-1,46).x-font.get_string_size("8888",0,-1,46).x) < 0.1,"Design theme uses true tabular data numerals")
	app.reduced_motion = false
	app.go("settings",false)
	var motion_path := "res://.godot/climb-design-motion-%d" % height
	DirAccess.make_dir_recursive_absolute(motion_path)
	for frame in 48:
		if frame in [8,20,32]:
			app.settings_category = {8:"Audio",20:"Accessibility",32:"Display"}[frame]
			app.setting_content()
		await process_frame
		if frame%2 == 0:
			await RenderingServer.frame_post_draw
			check(viewport.get_texture().get_image().save_png(motion_path+"/%03d.png" % frame) == OK,"Native tab-motion frame saved")
	app.go("home",false)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(directory+"/home-%d.png" % height)
	app.content.hide()
	app.header.hide()
	var proof := Control.new()
	proof.size = Vector2(1280,720)
	app.canvas.add_child(proof)
	app.C.label(proof,"One card system",Rect2(32,92,1000,72),44,"Heading")
	var finishes := ["bronze","silver","gold","legend","unknown"]
	for index in 5:
		var definition: Resource = null
		if index < 4: definition=app.library.recruits.filter(func(item): return item.tier() == finishes[index])[0]
		var node: Control = app.card(proof,definition,Vector2(32+index*244,220),232,index < 4)
		node.disabled = index == 4
		app.C.label(proof,finishes[index].capitalize(),Rect2(32+index*244,580,232,42),24,"Team")
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(directory+"/card-finishes-%d.png" % height) == OK,"Native shared tier-frame reference captured")
	proof.queue_free()
	await process_frame
	proof = Control.new()
	proof.size = Vector2(1280,720)
	app.canvas.add_child(proof)
	app.C.label(proof,"Ability symbols",Rect2(32,36,1000,72),44,"Heading")
	var trait_ids: Array = catalogue.cards[0].Traits.catalogue.keys()
	for index in trait_ids.size():
		var icon := TextureRect.new()
		icon.texture = glyphs.texture(trait_ids[index])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.position = Vector2(34+index%6*204,124+int(index/6)*92)
		icon.size = Vector2(32,32)
		proof.add_child(icon)
		app.C.label(proof,catalogue.cards[0].Traits.catalogue[trait_ids[index]].name,Rect2(icon.position+Vector2(0,38),Vector2(198,28)),15,"BodyStrong")
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(directory+"/ability-icons-%d.png" % height) == OK,"Native 36-icon atlas reference captured")
	proof.queue_free()
	print("CLIMB DESIGN ",height," native checks=",checks," failures=",failures,". No campaign/session/save writes.")
	app.queue_free()
	quit(1 if failures > 0 else 0)
