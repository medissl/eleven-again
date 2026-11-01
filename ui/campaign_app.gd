extends Control
const Session = preload("res://persistence/campaign_session.gd")
const Preferences = preload("res://persistence/preferences.gd")
const Parts = preload("res://ui/campaign_parts.gd")
const Screens = preload("res://ui/campaign_screens.gd")
const Acquisition = preload("res://ui/acquisition_screen.gd")
const LibraryScreen = preload("res://ui/campaign_library.gd")
const MatchView = preload("res://match/match_view.gd")
const Motion = preload("res://ui/motion.gd")
const Audio = preload("res://ui/audio.gd")
var audio: Node
var page_motion := Motion.Swap.new()
var modal_motion := Motion.Swap.new()
var settings_motion := Motion.Swap.new()
var settings_cover: Control
var settings_content: Control
var save_root := "user://campaign"
var session: RefCounted
var library: RefCounted
var preferences: RefCounted
var canvas: Control
var screen: Control
var modal: Control
var view: Control
var page := "main"
var status: Label
var busy := false
var modal_focus: Control
var last_saved_tick := 0
var last_period := -1
var rebind := ""
var apply_display := true
var origin_selection := "ENG"
var coach_selection := ""
var settings_section := "display"
var record_page := 0
var road_stage := -1
var road_token_stage := -1
var pinned_card := ""
var arena: TextureRect
var arena_shade: ColorRect
var walkout: Control
var arena_transition: Tween

func _ready() -> void:
	theme = Parts.ThemeData
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session = Session.new(save_root) if session == null else session
	library = session.content
	preferences = Preferences.new(save_root)
	audio = Audio.obtain(self)
	get_tree().node_added.connect(_motion_added)
	apply_preferences()
	if get_viewport() == get_tree().root: get_tree().auto_accept_quit = false
	resized.connect(func(): if is_instance_valid(screen) and not is_instance_valid(view) and not is_instance_valid(modal): render(page))
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	arena = TextureRect.new()
	arena.texture = preload("res://assets/ui/premium/arena.png")
	arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arena.size = Vector2(1280,720)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(arena)
	arena_shade = ColorRect.new()
	arena_shade.color = Color(0.02,0.05,0.09,0.6)
	arena_shade.size = Vector2(1280,720)
	arena_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(arena_shade)
	var arena_copy := BackBufferCopy.new()
	arena_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	canvas.add_child(arena_copy)
	resized.connect(layout_canvas)
	layout_canvas()
	render("main")

func layout_canvas() -> void:
	if not is_instance_valid(canvas): return
	canvas.scale = Vector2.ONE*minf(size.x/1280,size.y/720)
	canvas.position = (size-canvas.size*canvas.scale)/2

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Parts.ThemeData.get_color("forest","Palette"))


func ui_scale() -> float: return 1.0
func money(value: int) -> String: return "$%sm" % str(value/1000000.0).trim_suffix(".0")
func text(parent: Node, value: String, pixels: int = 18, role: String = "Label", ink: Color = Parts.IVORY) -> Label: return Parts.label(parent,value,roundi(pixels*ui_scale()),role,ink)
func button(parent: Node, caption: String, id: String, action: Callable, primary: bool = false) -> Button:
	var node := Parts.button(parent,caption,id,action,primary)
	node.add_theme_font_size_override("font_size",18)
	return node

func _motion_added(node: Node) -> void:
	if node is Control and is_ancestor_of(node): _bind_motion.call_deferred(node.get_instance_id())

func _bind_motion(id: int) -> void:
	var node := instance_from_id(id) as Control
	if is_instance_valid(node) and node.is_inside_tree(): Motion.bind_control(node,func(): return preferences.data.motion)
	if is_instance_valid(node) and node.is_inside_tree(): audio.bind_control(node)

func clear_screen() -> Control:
	var old: Control = view if is_instance_valid(view) else screen
	screen = null
	view = null
	return old

func render(next: String) -> void:
	audio.set_match(false)
	if is_instance_valid(arena_shade):
		if arena_transition != null: arena_transition.kill()
		arena_transition=create_tween()
		arena_transition.tween_property(arena_shade,"color:a",0.25 if next == "main" else 0.65,0.0 if preferences.data.motion else 0.22)
	if page == "offer" and next != "offer" and not pinned_card.is_empty() and not session.profile.discoveries.has(pinned_card): pinned_card = ""
	if next == "discovered": next = "collection"
	var focus_name := ""
	var focus := get_viewport().gui_get_focus_owner()
	if next == page and focus != null: focus_name = focus.name
	var transient := {}
	if next == page and is_instance_valid(screen):
		var offer = screen.find_child("Acquisition",true,false)
		if offer != null:
			var state: Dictionary = session.controller.snapshot()
			var same_offer: bool = state.step == "market" and offer.market and state.market.id == offer.state.market.id
			if state.step in ["opening_recruit","recruit"] and not offer.market: same_offer = state.offer.id == offer.state.offer.id
			if same_offer:
				var owned_ids: Array = state.plan.cards.map(func(card): return card.card_id)
				transient = {"selected":offer.selected,"outgoing":offer.outgoing if offer.outgoing in owned_ids else "","page":offer.page}
	close_modal()
	var old_screen := clear_screen()
	page = next
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(screen)
	if session.blocked:
		Screens.recovery(self)
	elif page == "main": Screens.main(self)
	elif page == "collection":
		var collection = load("res://ui/collection_screen.gd").new()
		collection.library = library
		collection.discoveries = session.profile.discoveries.duplicate(true)
		collection.reduced_motion = preferences.data.motion
		screen.add_child(collection)
		collection.closed.connect(func(): render("main"))
	else:
		var outer := Screens.frame(self)
		match page:
			"origin": Screens.origins(self,outer)
			"board": Screens.board(self,outer)
			"offer":
				var offer := Acquisition.new()
				offer.name = "Acquisition"
				offer.app = self
				outer.add_child(offer)
				if not transient.is_empty():
					offer.selected = transient.selected
					offer.outgoing = transient.outgoing
					offer.page = transient.page
					offer.build_cards()
			"coaching": Screens.coaching(self,outer)
			"result", "terminal": Screens.result(self,outer,page == "terminal")
			"collection", "records": LibraryScreen.build(self,outer,page)
	if is_instance_valid(status): status.queue_free()
	status = text(canvas,"",14)
	status.z_index = 100
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_top = -22
	status.offset_left = 30
	if session.recovery_used: status.text = "Recovered a valid saved checkpoint. Original damaged files were retained."; session.recovery_used = false
	Parts.focus_loop(screen)
	if not focus_name.is_empty():
		var old := screen.find_child(focus_name,true,false) as Control
		if old != null and old.focus_mode == Control.FOCUS_ALL and not (old is BaseButton and old.disabled): old.grab_focus()
	page_motion.replace(old_screen,screen,preferences.data.motion)
	queue_redraw()

func route() -> void:
	var data: Dictionary = session.controller.snapshot()
	match data.get("step",""):
		"match": open_match()
		"prepare": road_stage=data.wins; render("board")
		"opening_recruit", "recruit", "market": render("offer")
		"coaching": render("coaching")
		"result": render("result")
		"won", "lost", "abandoned": render("terminal")
		_: render("main")

func act(action: String, args: Array, revision: int) -> void:
	if busy: return
	busy = true
	var newly_discovered: bool = action == "acquire" and not session.profile.discoveries.has(args[0])
	var result: Dictionary = session.act(action,args,revision)
	busy = false
	if result.ok:
		if action == "acquire": _show_walkout(args[0],newly_discovered)
		else: route()
	elif session.blocked: render("main")
	else: message(result.error)

func _show_walkout(id: String, newly_discovered: bool) -> void:
	walkout = preload("res://ui/recruitment_walkout.gd").new()
	walkout.definition=library.cards[id]
	walkout.info=library.metadata(id)
	walkout.audio=audio
	walkout.reduced=preferences.data.motion
	walkout.effects_enabled=preferences.data.effects
	walkout.newly_discovered=newly_discovered
	open_modal(walkout)
	walkout.completed.connect(func(): walkout=null; close_modal(); route())

func message(value: String) -> void:
	if is_instance_valid(status): status.text = value

func start_origin(origin: String, confirmed: bool = false) -> void:
	var data: Dictionary = session.controller.snapshot()
	if not data.is_empty() and data.step not in ["won","lost","abandoned"] and not confirmed:
		confirm("Replace this run?","The active squad and funds will end. Discoveries and records remain.",func(): start_origin(origin,true))
		return
	var seed_value := int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
	var result: Dictionary = session.new_run(origin,seed_value,str(Time.get_ticks_usec())+"_"+str(seed_value),confirmed)
	if result.ok: route()
	else: message(result.error)

func prepare() -> void:
	var data: Dictionary = session.controller.snapshot()
	var club: Dictionary = library.clubs[data.fixtures[data.wins].club_id]
	var node = load("res://ui/squad_editor.gd").new()
	node.campaign_mode = true
	node.opponent_mode = true
	node.team = 1
	node.campaign_library = library
	node.campaign_discoveries = session.profile.discoveries.duplicate(true)
	node.home_name = library.countries[data.origin].name
	node.knockout = true
	node.ui_scale = ui_scale()
	node.reduced_motion = preferences.data.motion
	node.plans[0] = session.controller.preparation_plan()
	node.plans[1] = library.opponent_plan(data.fixtures[data.wins].variant_id)
	var missing: Array = data.plan.cards.filter(func(card): return data.discipline.get(card.person_id,{}).get("ban",0) > 0).map(func(card): return card.display_name)
	node.scouting = club.name+"  "+club.formation+"\n"+club.scout_threat+" "+club.scout_response
	if not missing.is_empty(): node.scouting += "\nUnavailable: "+", ".join(missing)+". Anonymous academy cover is temporary."
	open_modal(node)
	node.submitted.connect(func(home,_away,_knockout): close_modal(); act("commit_match",[home],data.revision))
	node.cancelled.connect(close_modal)

func squad() -> void:
	var data: Dictionary = session.controller.snapshot()
	if data.get("step","") != "prepare": return
	var node := preload("res://ui/squad_editor.gd").new()
	node.campaign_mode = true
	node.squad_mode = true
	node.campaign_library = library
	node.campaign_discoveries = session.profile.discoveries.duplicate(true)
	node.plans[0] = preload("res://squad/lineup.gd").from_data(data.plan)
	node.plans[1] = node.plans[0].duplicate(true)
	node.unavailable = preload("res://run/availability.gd").banned(data.discipline)
	node.reduced_motion = preferences.data.motion
	node.scouting = library.countries[data.origin].name
	open_modal(node)
	node.submitted.connect(func(home,_away,_knockout): close_modal(); act("update_plan",[home],data.revision))
	node.cancelled.connect(close_modal)

func open_match() -> void:
	close_modal()
	var old_screen := clear_screen()
	page = "match"
	var data: Dictionary = session.controller.snapshot()
	var club: Dictionary = library.clubs[data.current_attempt.fixture.club_id]
	view = MatchView.new()
	view.card_library = library
	view.external_model = session.controller.model
	view.campaign_mode = true
	view.team_names = [library.countries[data.origin].name,club.name]
	view.team_kits = Parts.match_kits(library,data.origin,club)
	view.key_bindings = preferences.data.keys.duplicate()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(view)
	page_motion.replace(old_screen,view,preferences.data.motion)
	apply_preferences()
	view.campaign_action.connect(match_action)
	last_saved_tick = view.sim.ticks
	last_period = view.sim.period

func match_action(action: String) -> void:
	if action == "continue_result": act("finish_match",[],session.controller.revision())
	elif action == "campaign_settings": settings()
	elif action == "save_exit": save_and_exit()

func _process(_delta: float) -> void:
	if not is_instance_valid(view) or session.blocked: return
	if view.sim.ticks-last_saved_tick >= 600 or view.sim.period != last_period:
		var result: Dictionary = session.checkpoint()
		last_saved_tick = view.sim.ticks
		last_period = view.sim.period
		if not result.ok: view.paused = true; render("main")

func save_and_exit() -> void:
	var data: Dictionary = session.controller.snapshot()
	if not data.is_empty() and not session.checkpoint().ok: render("main"); return
	render("main")

func _notification(what: int) -> void:
	if session == null: return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if session.controller.snapshot().is_empty() or session.checkpoint().ok: get_tree().quit()
		else: render("main")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(view):
		view.paused = true
		if not session.checkpoint().ok: render("main")

func open_modal(node: Control) -> void:
	var old: Control = modal if is_instance_valid(modal) else null
	if old == null: modal_focus = get_viewport().gui_get_focus_owner()
	settings_cover = null
	settings_content = null
	rebind = ""
	modal = node
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(node)
	modal_motion.replace(old,node,preferences.data.motion)
	if is_instance_valid(view): view.paused = true; view.set_process_input(false)

func close_modal() -> void:
	var had_modal := is_instance_valid(modal)
	if had_modal:
		modal_motion.replace(modal,null,preferences.data.motion)
	modal = null
	settings_cover = null
	settings_content = null
	rebind = ""
	if is_instance_valid(view): view.set_process_input(true)
	if had_modal and is_instance_valid(modal_focus) and modal_focus.is_inside_tree(): modal_focus.grab_focus()

func panel(title: String, rect: Rect2 = Rect2(328,186,624,348)) -> VBoxContainer:
	var cover := ColorRect.new()
	cover.color = Color(Parts.ThemeData.get_color("forest","Palette"),0.88)
	open_modal(cover)
	var frame := PanelContainer.new()
	frame.position = rect.position
	frame.size = rect.size
	var style := preload("res://ui/matchday_theme.gd").box("panel-raised")
	for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(edge,24)
	frame.add_theme_stylebox_override("panel",style)
	cover.add_child(frame)
	var box := Parts.column(frame,16)
	if not title.is_empty(): text(box,title,30,"Heading")
	return box

func confirm(title: String, detail: String, commit: Callable) -> void:
	var box := panel(title)
	text(box,detail,19).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(space)
	var actions := Parts.row(box,16)
	button(actions,"Cancel","CancelConfirmation",close_modal)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(gap)
	button(actions,"Abandon run" if title.to_lower().contains("abandon") else "Start new run","AcceptConfirmation",func(): close_modal(); commit.call(),true)
	Parts.focus_loop(modal)

func menu() -> void:
	var box := panel("Run menu",Rect2(328,130,624,460))
	button(box,"Resume","ResumeCampaign",close_modal,true)
	button(box,"Settings","RunSettings",settings)
	button(box,"Save and exit to main menu","CampaignSaveExit",save_and_exit)
	box.add_child(HSeparator.new())
	button(box,"Abandon run","AbandonRun",func(): confirm("Abandon this run?","Discoveries and records remain. This squad and its funds will end.",func(): act("abandon",[],session.controller.revision())))
	Parts.focus_loop(modal)

func inspect(id: String, comparison: String = "") -> void:
	var node = load("res://ui/card_inspector.gd").new()
	node.definition = library.cards[id]
	node.info = library.metadata(id)
	node.ui_scale = ui_scale()
	node.reduced_motion = preferences.data.motion
	if comparison.is_empty() and not pinned_card.is_empty() and pinned_card != id: comparison = pinned_card
	node.pin_requested.connect(func(card_id): pinned_card = card_id; message("Comparison pinned."))
	if not comparison.is_empty(): node.comparison = library.cards[comparison]; node.comparison_info = library.metadata(comparison)
	open_modal(node)
	node.closed.connect(func(): modal = null; if is_instance_valid(modal_focus): modal_focus.grab_focus())

func settings() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name := str(focused.name) if focused != null and is_instance_valid(modal) else ""
	if not is_instance_valid(settings_cover) or modal != settings_cover:
		var cover := ColorRect.new()
		cover.color = Color(Parts.ThemeData.get_color("forest","Palette"),0.55)
		open_modal(cover)
		settings_cover = cover
		var copy := BackBufferCopy.new()
		copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		cover.add_child(copy)
		var surface := preload("res://ui/glass_panel.gd").new()
		cover.add_child(surface)
		surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		surface.offset_left = 24
		surface.offset_top = 84
		surface.offset_right = -24
		surface.offset_bottom = -24
		var title: Label = text(cover,"Settings",34,"Heading")
		title.position = Vector2(32,100)
		var back: Button = button(cover,"Back","CloseSettings",func(): close_modal(); apply_preferences())
		back.position = Vector2(1112,100)
		back.size = Vector2(136,44)
		for index in 4:
			var id: String = ["display","audio","controls","accessibility"][index]
			var item: Button = button(cover,id.capitalize(),"Settings"+id.capitalize(),func(): settings_section=id; settings(),settings_section == id)
			item.icon = load("res://assets/ui/matchday/icons/"+id+".svg")
			item.add_theme_constant_override("icon_max_width",24)
			item.position = Vector2(32,206+index*62)
			item.size = Vector2(244,48)
	for id in ["display","audio","controls","accessibility"]:
		var tab: Button = settings_cover.find_child("Settings"+str(id).capitalize(),true,false)
		tab.theme_type_variation = "Primary" if settings_section == id else "Button"
	var cover := settings_cover
	var old_content := settings_content
	var content := Parts.column(cover,24)
	settings_content = content
	content.position = Vector2(352,202)
	content.size = Vector2(864,392)
	text(content,"Keyboard shortcuts" if settings_section == "controls" else settings_section.capitalize(),28,"Heading")
	if settings_section == "controls":
		for action in ["pause","speed1","speed2","menu"]:
			var row := Parts.row(content,24)
			text(row,{"pause":"Pause / resume","speed1":"Normal speed","speed2":"Double speed","menu":"Open menu"}[action],19).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button(row,OS.get_keycode_string(preferences.data.keys[action]),"Rebind"+action,func(): rebind=action; message("Press a new key. Escape cancels rebinding.")).custom_minimum_size = Vector2(232,44)
		button(content,"Reset shortcuts","ResetShortcuts",func(): change_preference("keys",Preferences.DEFAULT_KEYS.duplicate())).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	elif settings_section == "audio":
		for field in ["volume","music_volume","effects_volume"]:
			var row := Parts.row(content,28)
			text(row,{"volume":"Master","music_volume":"Menu music","effects_volume":"Stadium / effects"}[field],20).custom_minimum_size.x = 180
			var volume := HSlider.new()
			volume.name = {"volume":"MasterVolume","music_volume":"MusicVolume","effects_volume":"EffectsVolume"}[field]
			volume.min_value = 0
			volume.max_value = 1
			volume.step = 0.1
			volume.value = preferences.data[field]
			volume.custom_minimum_size = Vector2(480,44)
			row.add_child(volume)
			var value: Label = text(row,"%d%%" % roundi(volume.value*100),24,"BodyStrong")
			volume.value_changed.connect(func(amount):
				var result: Dictionary = preferences.change(field,amount)
				if not result.ok: volume.set_value_no_signal(preferences.data[field]); message(result.error)
				value.text = "%d%%" % roundi(preferences.data[field]*100)
				apply_preferences())
		button(content,"Audio credits","AudioCredits",audio_credits).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	else:
		for field in (["fullscreen"] if settings_section == "display" else ["motion","effects"]):
			var row := Parts.row(content,24)
			var caption: String = {"motion":"Reduced motion","effects":"Celebration effects","fullscreen":"Fullscreen"}[field]
			text(row,caption,19).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var toggle: Button = button(row,"On" if preferences.data[field] else "Off",field,func(): change_preference(field,not preferences.data[field]))
			toggle.icon = load("res://assets/ui/matchday/components/toggle-"+("on" if preferences.data[field] else "off")+".svg")
			toggle.add_theme_constant_override("icon_max_width",48)
			toggle.custom_minimum_size = Vector2(152,44)
			toggle.tooltip_text = caption
		text(content,"The interface uses its standard size.",18,"Label",Color("A5B09F"))
	settings_motion.replace(old_content,content,preferences.data.motion,Vector2(0,4))
	Parts.focus_loop(modal)
	if not focus_name.is_empty():
		var previous := modal.find_child(focus_name,true,false) as Control
		if previous != null: previous.grab_focus()

func record_file(record: Dictionary) -> void:
	var node = load("res://ui/record_eleven.gd").new()
	node.record = record.duplicate(true)
	node.library = library
	node.reduced_motion = preferences.data.motion
	open_modal(node)
	node.closed.connect(func(): modal=null; if is_instance_valid(modal_focus): modal_focus.grab_focus())

func audio_credits() -> void:
	var box := panel("Audio credits",Rect2(240,124,800,500))
	var credits := text(box,"Menu Music — wipics (CC0)\nhttps://opengameart.org/content/menu-music-1\n\nInterface / Impact / Card Sounds — Kenney (CC0)\nhttps://kenney.nl/assets\n\nFree Crowd Cheering Sounds — Gregor Quendel (CC BY 4.0)\nhttps://opengameart.org/content/free-crowd-cheering-sounds\nhttps://creativecommons.org/licenses/by/4.0/\n\nReferee whistle — Rosa-Orenes256 (CC0)\nhttps://freesound.org/s/538422/\nFootball kick — bittermelonheart (CC0)\nhttps://freesound.org/s/555042/\n\nRenamed files; playback gains / pitch / sequencing adjusted.",16)
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(box,"Back","CloseAudioCredits",settings)
	Parts.focus_loop(modal)

func change_preference(key: String, value: Variant) -> void:
	var result: Dictionary = preferences.change(key,value)
	if result.ok: apply_preferences(); settings()
	else: message(result.error)

func apply_preferences() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,preferences.data.volume)))
	if is_instance_valid(audio):
		audio.music_level = preferences.data.music_volume
		audio.effects_level = preferences.data.effects_volume
	Motion.settle_tree(self)
	if preferences.data.motion:
		page_motion.finish()
		modal_motion.finish()
		settings_motion.finish()
	if apply_display and get_viewport() == get_tree().root: get_tree().root.mode = Window.MODE_FULLSCREEN if preferences.data.fullscreen else Window.MODE_WINDOWED
	if is_instance_valid(view) and is_instance_valid(view.hud):
		view.hud.effects_enabled = preferences.data.effects
		view.hud.reduced_motion = preferences.data.motion
		view.hud.set_ui_scale(ui_scale())
		view.key_bindings = preferences.data.keys.duplicate()
		view._layout()
		if not view.overlay_mode.is_empty(): view.hud.show_panel(view.overlay_mode,view.sim)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if is_instance_valid(walkout):
		if event.keycode == KEY_ESCAPE: walkout.skip_intro(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER and not walkout.confirm.visible: walkout.skip_intro(); get_viewport().set_input_as_handled()
		return
	var focused := get_viewport().gui_get_focus_owner()
	if event.keycode == KEY_ESCAPE and is_instance_valid(focused) and focused.has_method("dismiss_hint") and is_instance_valid(focused.hint):
		focused.dismiss_hint()
		get_viewport().set_input_as_handled()
		return
	if not rebind.is_empty():
		get_viewport().set_input_as_handled()
		if event.keycode != KEY_ESCAPE:
			var keys: Dictionary = preferences.data.keys.duplicate()
			keys[rebind] = event.keycode
			var result: Dictionary = preferences.change("keys",keys)
			if not result.ok: message(result.error); return
		rebind = ""
		settings()
	elif event.keycode == KEY_ESCAPE:
		if page == "collection" and not is_instance_valid(modal): return
		if is_instance_valid(modal):
			if modal.has_method("handle_cancel") and modal.handle_cancel():
				get_viewport().set_input_as_handled()
				return
			if modal.has_method("open_card") and is_instance_valid(modal.card_panel): return
			if modal.has_method("pin_selected") and is_instance_valid(modal.inspection): return
			if modal.has_method("dismiss"): modal.dismiss()
			else: close_modal()
		elif is_instance_valid(view): return
		elif page == "main": return
		elif page in ["origin","records","collection"]: render("main")
		else: menu()
		get_viewport().set_input_as_handled()
