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
var collection_page := 0
var coach_selection := ""
var collection_known := false
var collection_query := ""
var collection_role := ""
var collection_tier := ""
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
					if offer.replacement != null:
						var index: int = offer.state.plan.cards.map(func(card): return card.card_id).find(offer.outgoing)
						offer.replacement.select(index+1)
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
	var home := Color(library.countries[data.origin].home_kit)
	var away := Color(club.home_kit)
	if absf(home.get_luminance()-away.get_luminance()) < 0.3: away = Color(club.away_kit)
	if absf(home.get_luminance()-away.get_luminance()) < 0.3: away = Color("ed7864") if home.get_luminance() > 0.4 else Parts.IVORY
	view.team_kits = [home,away]
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
	if is_instance_valid(view): view.paused = true; view.set_process_input(false)

func close_modal() -> void:
	if is_instance_valid(modal):
		modal.get_parent().remove_child(modal)
		modal.queue_free()
	modal = null
	rebind = ""
	if is_instance_valid(view): view.set_process_input(true)
	if is_instance_valid(modal_focus) and modal_focus.is_inside_tree(): modal_focus.grab_focus()

func panel(title: String) -> VBoxContainer:
	var cover := ColorRect.new()
	cover.color = Parts.ThemeData.get_color("forest","Palette")
	open_modal(cover)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,roundi(canvas.size.x*0.2))
	for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,36)
	cover.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left","right","top","bottom"]: inset.add_theme_constant_override("margin_"+side,4)
	scroll.add_child(inset)
	var box := Parts.column(inset,12)
	if not title.is_empty(): text(box,title,42,"Heading")
	return box

func confirm(title: String, detail: String, commit: Callable) -> void:
	var box := panel(title)
	text(box,detail,19).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(box,"Cancel","CancelConfirmation",close_modal,true)
	button(box,"Confirm","AcceptConfirmation",func(): close_modal(); commit.call())
	Parts.focus_loop(modal)

func menu() -> void:
	var box := panel("RUN MENU")
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
	var focus := get_viewport().gui_get_focus_owner()
	var focus_name := str(focus.name) if focus != null and is_instance_valid(modal) else ""
	var box := panel("")
	var heading := Parts.row(box)
	text(heading,"SETTINGS",42,"Heading").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(heading,"Back","CloseSettings",func(): close_modal(); apply_preferences(); if not is_instance_valid(view): render(page))
	box.add_child(HSeparator.new())
	var columns := Parts.row(box,32)
	var general := Parts.column(columns,8)
	var shortcuts := Parts.column(columns,8)
	text(general,"DISPLAY AND MOTION",15,"Section")
	for field in ["motion","effects","fullscreen"]:
		var row := Parts.row(general,12)
		text(row,{"motion":"Reduced motion","effects":"Celebration effects","fullscreen":"Fullscreen"}[field],17).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var toggle := button(row,"On" if preferences.data[field] else "Off",field,func(): change_preference(field,not preferences.data[field]))
		toggle.custom_minimum_size = Vector2(80,38)
	text(general,"Master volume",17)
	var volume_row := Parts.row(general,12)
	var volume := HSlider.new()
	volume.name = "MasterVolume"
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.1
	volume.value = preferences.data.volume
	volume.custom_minimum_size = Vector2(220,32)
	volume_row.add_child(volume)
	var volume_label := text(volume_row,"%d%%" % roundi(volume.value*100),17)
	volume.value_changed.connect(func(value):
		var result: Dictionary = preferences.change("volume",value)
		if not result.ok: volume.set_value_no_signal(preferences.data.volume); message(result.error)
		volume_label.text = "%d%%" % roundi(preferences.data.volume*100)
		apply_preferences())
	text(shortcuts,"SHORTCUTS",15,"Section")
	for action in ["pause","speed1","speed2","menu"]:
		var row := Parts.row(shortcuts,12)
		text(row,{"pause":"Pause / resume","speed1":"1× speed","speed2":"2× speed","menu":"Match menu"}[action],17).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button(row,OS.get_keycode_string(preferences.data.keys[action]),"Rebind"+action,func(): rebind=action; message("Press a new key. Escape cancels rebinding.")).custom_minimum_size = Vector2(110,38)
	button(shortcuts,"Reset shortcuts","ResetShortcuts",func(): change_preference("keys",Preferences.DEFAULT_KEYS.duplicate()))
	box.add_child(HSeparator.new())
	text(box,preferences.error if not preferences.error.is_empty() else "Tab and Enter navigate. Escape closes menus.",14).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Parts.focus_loop(modal)
	if not focus_name.is_empty():
		var previous := modal.find_child(focus_name,true,false) as Control
		if previous != null: previous.grab_focus()

func record_file(record: Dictionary) -> void:
	var box := panel("RECORD XI  "+record.peak_xi.formation)
	text(box,"%.2f OVR  Base slot ratings before match bonuses" % (record.peak_xi.total/11.0),20,"Score")
	button(box,"Back","CloseRecordXI",close_modal,true)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size.y = 440
	box.add_child(scroll)
	var row := Parts.row(scroll)
	for id in record.peak_xi.cards:
		var tile := Parts.card(row,library,id,300,ui_scale())
		tile.focus_entered.connect(func(): scroll.ensure_control_visible(tile))
	Parts.focus_loop(modal)

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
