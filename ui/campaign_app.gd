extends Control
const Session = preload("res://persistence/campaign_session.gd")
const Preferences = preload("res://persistence/preferences.gd")
const Parts = preload("res://ui/campaign_parts.gd")
const Screens = preload("res://ui/campaign_screens.gd")
const Acquisition = preload("res://ui/acquisition_screen.gd")
const LibraryScreen = preload("res://ui/campaign_library.gd")
const MatchView = preload("res://match/match_view.gd")
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
var pinned_card := ""

func _ready() -> void:
	theme = Parts.ThemeData
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session = Session.new(save_root) if session == null else session
	library = session.content
	preferences = Preferences.new(save_root)
	apply_preferences()
	if get_viewport() == get_tree().root: get_tree().auto_accept_quit = false
	resized.connect(func(): if is_instance_valid(screen) and not is_instance_valid(view) and not is_instance_valid(modal): render(page))
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	add_child(canvas)
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
func text(parent: Node, value: String, pixels: int = 18, role: String = "Label", ink: Color = Parts.IVORY) -> Label: return Parts.label(parent,value,mini(pixels,34) if role == "Heading" else roundi(pixels*ui_scale()),role,ink)
func button(parent: Node, caption: String, id: String, action: Callable, primary: bool = false) -> Button:
	var node := Parts.button(parent,caption,id,action,primary)
	node.add_theme_font_size_override("font_size",18)
	return node

func clear_screen() -> void:
	if is_instance_valid(screen):
		screen.get_parent().remove_child(screen)
		screen.queue_free()
	if is_instance_valid(view):
		view.get_parent().remove_child(view)
		view.queue_free()
	view = null

func render(next: String) -> void:
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
	clear_screen()
	page = next
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(screen)
	if session.blocked:
		Screens.recovery(self)
		return
	if page == "main": Screens.main(self)
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
	if not preferences.data.motion:
		screen.modulate.a = 0
		screen.create_tween().tween_property(screen,"modulate:a",1,0.17)
	queue_redraw()

func route() -> void:
	var data: Dictionary = session.controller.snapshot()
	match data.get("step",""):
		"match": open_match()
		"prepare": render("board")
		"opening_recruit", "recruit", "market": render("offer")
		"coaching": render("coaching")
		"result": render("result")
		"won", "lost", "abandoned": render("terminal")
		_: render("main")

func act(action: String, args: Array, revision: int) -> void:
	if busy: return
	busy = true
	var result: Dictionary = session.act(action,args,revision)
	busy = false
	if result.ok: route()
	elif session.blocked: render("main")
	else: message(result.error)

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
	var node = load("res://ui/preparation.gd").new()
	node.campaign_mode = true
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

func open_match() -> void:
	close_modal()
	clear_screen()
	page = "match"
	var data: Dictionary = session.controller.snapshot()
	var club: Dictionary = library.clubs[data.current_attempt.fixture.club_id]
	view = MatchView.new()
	view.external_model = session.controller.model
	view.campaign_mode = true
	view.team_names = [library.countries[data.origin].name,club.name]
	view.team_kits = Parts.match_kits(library,data.origin,club)
	view.key_bindings = preferences.data.keys.duplicate()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(view)
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
	close_modal()
	modal_focus = get_viewport().gui_get_focus_owner()
	modal = node
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(node)
	if not preferences.data.motion and node.get_script() == null:
		node.modulate.a = 0
		node.create_tween().tween_property(node,"modulate:a",1,0.18)
	if is_instance_valid(view): view.paused = true; view.set_process_input(false)

func close_modal() -> void:
	var had_modal := is_instance_valid(modal)
	if had_modal:
		modal.get_parent().remove_child(modal)
		modal.queue_free()
	modal = null
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
	var cover := ColorRect.new()
	cover.color = Parts.ThemeData.get_color("forest","Palette")
	open_modal(cover)
	var title: Label = text(cover,"Settings",34,"Heading")
	title.position = Vector2(32,100)
	var back: Button = button(cover,"Back","CloseSettings",func(): close_modal(); apply_preferences(); if not is_instance_valid(view): render(page))
	back.position = Vector2(1112,100)
	back.size = Vector2(136,44)
	for index in 4:
		var id: String = ["display","audio","controls","accessibility"][index]
		var item: Button = button(cover,id.capitalize(),"Settings"+id.capitalize(),func(): settings_section=id; settings(),settings_section == id)
		item.icon = load("res://assets/ui/matchday/icons/"+id+".svg")
		item.add_theme_constant_override("icon_max_width",24)
		item.position = Vector2(32,206+index*62)
		item.size = Vector2(244,48)
	var content := Parts.column(cover,24)
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
		text(content,"Master volume",20)
		var row := Parts.row(content,28)
		var volume := HSlider.new()
		volume.name = "MasterVolume"
		volume.min_value = 0
		volume.max_value = 1
		volume.step = 0.1
		volume.value = preferences.data.volume
		volume.custom_minimum_size = Vector2(640,44)
		row.add_child(volume)
		var value: Label = text(row,"%d%%" % roundi(volume.value*100),24,"BodyStrong")
		volume.value_changed.connect(func(amount):
			var result: Dictionary = preferences.change("volume",amount)
			if not result.ok: volume.set_value_no_signal(preferences.data.volume); message(result.error)
			value.text = "%d%%" % roundi(preferences.data.volume*100)
			apply_preferences())
		text(content,"Adjust the game's overall sound level.",18,"Label",Color("A5B09F"))
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
	var line := HSeparator.new()
	line.position = Vector2(352,634)
	line.size.x = 864
	cover.add_child(line)
	text(cover,preferences.error if not preferences.error.is_empty() else "Changes save automatically. Escape goes back.",16,"Label",Color("A5B09F")).position = Vector2(352,650)
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

func change_preference(key: String, value: Variant) -> void:
	var result: Dictionary = preferences.change(key,value)
	if result.ok: apply_preferences(); settings()
	else: message(result.error)

func apply_preferences() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,preferences.data.volume)))
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
			if modal.has_method("open_card") and is_instance_valid(modal.card_panel): return
			if modal.has_method("pin_selected") and is_instance_valid(modal.inspection): return
			if modal.has_method("dismiss"): modal.dismiss()
			else: close_modal()
		elif is_instance_valid(view): return
		elif page == "main": return
		elif page in ["origin","records","collection"]: render("main")
		else: menu()
		get_viewport().set_input_as_handled()
