extends Control
## Read-only content + isolated design state. Never instantiate the real save/session layer.
const C = preload("res://outputs/fc-mobile-ui-v6/components.gd")
const Model = preload("res://outputs/fc-mobile-ui-v6/model.gd")
const Library = preload("res://content/campaign.gd")
const Lineup = preload("res://squad/lineup.gd")
const Motion = preload("res://ui/motion.gd")
var audio: Node
var model := Model.new()
var library := Library.new()
var origins: Array = JSON.parse_string(FileAccess.get_file_as_string(C.ROOT+"origins.json"))
var canvas: Control
var header: Control
var content: Control
var outgoing: Control
var transition: Tween
var page := "home"
var previous_page := "pyramid"
var region := "All"
var market_page := 0
var selected_card := 0
var selected_slot := 9
var formation := "4-3-3"
var tactic := "Possession"
var settings_category := "Display"
var reduced_motion := false
var settings_body: Control
var plan: Resource
var offers: Array = []
var cards: Array = []
var toast := ""
var drawer: Control
var live_view: Control
var live_clock: Label
var live_score: Label
var live_play: Button
var reward_claimed := false
var coaching_choice := 0
var committed_plan := {}
var committed_formation := "4-3-3"
var library_return := "pyramid"
var arena: TextureRect
var arena_shade: ColorRect
var show_player_panel := false
const FORMATIONS := ["4-3-3","4-4-2","4-2-3-1","4-1-4-1","4-2-2-2","4-3-1-2","3-4-3","3-5-2","5-3-2"]

func _ready() -> void:
	audio = preload("res://ui/audio.gd").obtain(self)
	get_tree().node_added.connect(_motion_added)
	DisplayServer.window_set_title("Eleven Again — The Climb / isolated design preview")
	theme = C.make_theme()
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	arena = TextureRect.new()
	arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena.texture = ImageTexture.create_from_image(Image.load_from_file(C.ROOT+"art/arena.png"))
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
	header = Control.new()
	canvas.add_child(header)
	plan = library.country_plan("ENG")
	# An authored late-run design sample, not a production save or balance assertion.
	var used := []
	for slot in 11:
		var role: String = Lineup.ROLES[plan.formation][slot]
		var eligible: Array = library.recruits.filter(func(card): return role in card.natural_roles and card.rating() >= 78 and card.rating() <= 98 and card.person_id not in used)
		if not eligible.is_empty():
			plan.cards[slot] = eligible[0]
			used.append(eligible[0].person_id)
	cards = library.recruits.filter(func(card): return card.rating() >= 94 and card.rating() < 111)
	committed_plan = plan.to_data()
	make_offer()
	resized.connect(layout)
	layout()
	go("home",false)

func _motion_added(node: Node) -> void:
	if node is Control and is_ancestor_of(node): _bind_motion.call_deferred(node.get_instance_id())

func _bind_motion(id: int) -> void:
	var node := instance_from_id(id) as Control
	if is_instance_valid(node) and node.is_inside_tree(): Motion.bind_control(node,func(): return reduced_motion)
	if is_instance_valid(node) and node.is_inside_tree(): audio.bind_control(node)

func layout() -> void:
	canvas.scale = Vector2.ONE*minf(size.x/1280,size.y/720)
	canvas.position = (size-canvas.size*canvas.scale)/2
	queue_redraw()

func _draw() -> void: draw_rect(Rect2(Vector2.ZERO,size),C.BG)

func put(value: String, rect: Rect2, pixels: int = 18, role: String = "Label", ink: Color = C.INK, parent: Node = null) -> Label:
	return C.label(content if parent == null else parent,value,rect,pixels,role,ink)

func action(value: String, rect: Rect2, callback: Callable, role: String = "Button", id: String = "", parent: Node = null) -> Button:
	return C.button(content if parent == null else parent,value,rect,callback,role,id)

func crest(parent: Node, rect: Rect2, motif: String = "bridge", color: Color = Color("29465E"), accent: Color = C.ACCENT) -> Control:
	var node := C.Crest.new()
	node.motif = motif
	node.color = color
	node.accent = accent
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node

func card(parent: Node, definition: Resource, position: Vector2, width: float, known: bool = true) -> Button:
	var node := C.Card.new()
	node.custom_minimum_size = Vector2(width,width*1.4)
	node.size = node.custom_minimum_size
	node.position = position
	node.bind(definition,library.metadata(definition.card_id) if definition != null else {},known)
	parent.add_child(node)
	return node

func freeze_tree(node: Node) -> void:
	if node.has_method("dismiss_hint"): node.dismiss_hint()
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): freeze_tree(child)

func go(next: String, animate: bool = true) -> void:
	audio.set_match(next == "match")
	if transition != null and transition.is_running(): transition.kill()
	if is_instance_valid(outgoing): outgoing.queue_free()
	outgoing = content
	if is_instance_valid(outgoing):
		outgoing.modulate.a = 1
		freeze_tree(outgoing)
	content = Control.new()
	content.size = Vector2(1280,720)
	content.name = "Page_"+next
	canvas.add_child(content)
	page = next
	var shade := 0.25 if page == "home" else 0.72 if page in ["settings","player","records","collection"] else 0.58
	refresh_header()
	match page:
		"home": home()
		"origin": country_page()
		"pyramid": pyramid()
		"squad", "opponent", "record_xi": squad(page != "squad",page == "record_xi")
		"reward", "market": recruitment(page == "market")
		"player": player_sheet()
		"settings": settings()
		"records": records()
		"collection": collection()
		"result": result_page()
		"coaching": coaching()
		"champions", "defeat": terminal(page == "champions")
		"match": match_preview()
	if animate and not reduced_motion and is_instance_valid(outgoing):
		content.modulate.a = 0
		content.position.y = 8
		transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		transition.tween_property(content,"modulate:a",1.0,0.22)
		transition.tween_property(content,"position:y",0.0,0.22)
		transition.tween_property(arena_shade,"color:a",shade,0.22)
		var old := outgoing
		transition.finished.connect(func(): if is_instance_valid(old): old.queue_free())
	else:
		arena_shade.color.a = shade
		if is_instance_valid(outgoing): outgoing.queue_free()
	content.move_to_front()
	header.move_to_front()
	var first := content.find_child("PrimaryAction",true,false) as Control
	if first != null: first.grab_focus()

func refresh_header() -> void:
	for child in header.get_children(): header.remove_child(child); child.queue_free()
	header.visible = page != "home"
	C.label(header,"11",Rect2(32,18,40,42),34,"Score",C.ACCENT)
	C.label(header,"ELEVEN AGAIN",Rect2(78,20,216,38),24,"Team")
	if page in ["origin","settings"]:
		if page == "origin": C.button(header,"Back",Rect2(1140,20,108,42),func(): go("home"),"Quiet")
		return
	var names := ["Pyramid","Squad","Collection","Records"]
	for index in names.size():
		var dest: String = names[index].to_lower()
		var node := C.button(header,names[index],Rect2(380+index*124,20,118,42),func(): go(dest),"Tab")
		if page == dest: node.add_theme_color_override("font_color",C.ACCENT)
	C.label(header,model.money(model.cash),Rect2(998,18,120,44),30,"Score")
	C.button(header,"Menu",Rect2(1140,20,108,42),func(): previous_page=page; go("settings"),"Quiet")
	var rule := ColorRect.new()
	rule.color = C.LINE
	rule.position = Vector2(32,78)
	rule.size = Vector2(1216,1)
	header.add_child(rule)

func title(value: String, subtitle: String = "") -> void:
	put(value,Rect2(32,98,900,58),42,"Heading")
	if not subtitle.is_empty(): put(subtitle,Rect2(34,158,1000,28),17,"Label",C.MUTED)

func home() -> void:
	put("ELEVEN AGAIN",Rect2(42,28,520,56),38,"Heading")
	action("Collection",Rect2(730,32,156,44),func(): library_return="home"; go("collection"),"Quiet")
	action("Records",Rect2(906,32,136,44),func(): library_return="home"; go("records"),"Quiet")
	action("Settings",Rect2(1062,32,176,44),func(): previous_page="home"; go("settings"),"Quiet")
	put("THE CLIMB",Rect2(40,156,680,112),96,"Heading")
	put("12 WINS. ONE TROPHY.",Rect2(48,282,620,42),24,"Team",C.MUTED)
	for index in 2:
		var node := card(content,cards[8+index*13],Vector2(764+index*242,128),214)
		node.pressed.connect(func(): previous_page="home"; selected_card=8+index*13; go("player"))
	var squad_tile := C.panel(content,Rect2(32,486,280,198))
	put("MY SQUAD",Rect2(24,18,220,36),25,"Heading",C.INK,squad_tile)
	put("%d" % ceili(Library.xi_rating(plan)),Rect2(24,68,140,64),54,"Score",C.INK,squad_tile)
	put("OVR",Rect2(146,92,104,32),17,"Team",C.MUTED,squad_tile)
	action("Squad",Rect2(24,142,232,40),func(): go("squad"),"Quiet","",squad_tile)
	var fresh := C.panel(content,Rect2(328,486,280,198))
	crest(fresh,Rect2(24,18,68,75),"trophy",C.SURFACE,C.ACCENT)
	put("NEW RUN",Rect2(112,36,144,40),25,"Heading",C.INK,fresh)
	action("Choose country",Rect2(24,142,232,40),func(): go("origin"),"Quiet","",fresh)
	var play := C.panel(content,Rect2(624,486,624,198))
	put("CLUB CHAMPIONS",Rect2(28,16,550,36),20,"Team",C.MUTED,play)
	put("Rive Athletic",Rect2(28,56,550,50),38,"Heading",C.INK,play)
	put("6 / 12",Rect2(28,130,184,40),24,"Score",C.INK,play)
	action("CONTINUE",Rect2(280,126,316,48),func(): go("pyramid"),"Primary","PrimaryAction",play)

func country_page() -> void:
	title("Choose a country")
	var regions := ["All","Europe","Americas","Africa","Asia","Oceania"]
	for index in regions.size():
		var value: String = regions[index]
		action(value,Rect2(32+index*124,166,116,40),func(): region=value; go("origin"),"Button" if region == value else "Quiet")
	var pool: Array = origins.filter(func(row): return region == "All" or region == row.region)
	for index in pool.size():
		var row: Dictionary = pool[index]
		var selected: bool = row.code == model.origin
		var node := action(row.name,Rect2(32+(index%4)*192,228+int(index/4)*49,180,42),func(): model.origin=row.code; go("origin"),"Button" if selected else "Quiet")
		node.icon = C.flag(row.code)
		node.add_theme_constant_override("icon_max_width",28)
		node.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if selected: node.add_theme_color_override("font_color",C.ACCENT)
	C.panel(content,Rect2(848,166,400,430))
	C.flag_view(content,model.origin,Rect2(954,210,188,128))
	var chosen: Dictionary = origins.filter(func(row): return row.code == model.origin)[0]
	put(chosen.name,Rect2(880,370,344,56),38,"Heading").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	put("16 PLAYERS",Rect2(880,454,170,30),17,"Score",C.MUTED)
	put("$10m",Rect2(1080,450,128,38),30,"Score")
	action("Start run",Rect2(936,646,312,48),begin_run,"Primary","PrimaryAction")

func begin_run() -> void:
	model.new_run(model.origin)
	plan = library.country_plan(model.origin if library.countries.has(model.origin) else "ENG")
	formation = "4-3-3"
	committed_formation = formation
	committed_plan = plan.to_data()
	make_offer()
	go("reward")

func pyramid() -> void:
	title("The climb")
	C.flag_view(content,model.origin,Rect2(34,164,36,25))
	put("%d / 12" % model.wins,Rect2(84,156,100,38),23,"Score")
	for index in 3:
		var pip := C.panel(content,Rect2(220+index*24,168,12,12),Color("F1757B") if index < model.defeats else C.RAISED)
		pip.tooltip_text = "%d of 3 defeats" % model.defeats
	var levels := [[12],[11],[9,10],[7,8],[4,5,6],[1,2,3]]
	var labels := ["WORLD CUP FINAL","WORLD CUP SEMIFINAL","NATIONS CUP","CLUB CHAMPIONS","NATIONAL LEAGUES","LOCAL CLUBS"]
	var spine := ColorRect.new()
	spine.position = Vector2(555,235)
	spine.size = Vector2(2,400)
	spine.color = Color(C.ACCENT,0.25)
	content.add_child(spine)
	for level in 6:
		var stages: Array = levels[level]
		var y := 214+level*72
		C.panel(content,Rect2(498-(stages.size()-1)*66,y-1,120+(stages.size()-1)*132,68),C.SURFACE)
		put(labels[level],Rect2(48,y+20,220,24),14,"Section",C.MUTED)
		for index in stages.size():
			var stage: int = stages[index]
			var x := 506+(index-(stages.size()-1)/2.0)*132
			var current: bool = stage == model.wins+1
			var done: bool = stage <= model.wins
			var btn := action("",Rect2(x,y,104,64),func(): if current: go("opponent"),"Primary" if current else "Button")
			btn.disabled = not current
			if stage in [9,10]: C.flag_view(btn,"BRA" if stage == 9 else "FRA",Rect2(12,18,40,28))
			else: crest(btn,Rect2(10,8,40,44),"trophy" if stage >= 11 else "mountain" if stage == 8 else "bridge" if stage >= 4 else "gate",C.BG if current else C.RAISED,C.INK if done or current else C.MUTED.darkened(0.4))
			put("✓" if done else str(stage),Rect2(64,15,38,34),20,"Score",C.BG if current else C.INK if done else C.MUTED,btn)
			if done: btn.add_theme_color_override("font_disabled_color",C.INK)
	var rival := C.panel(content,Rect2(848,208,400,474))
	if model.wins >= 8: C.flag_view(rival,["BRA","FRA","ARG","BRA"][mini(3,model.wins-8)],Rect2(112,48,176,120))
	else: crest(rival,Rect2(112,20,176,176),"bridge" if model.wins != 7 else "mountain")
	put(rival_name(),Rect2(880,394,336,50),34,"Heading")
	put("%d OVR" % ceili(Library.xi_rating(opposition_plan())),Rect2(880,456,156,34),24,"Score")
	put("4-3-3",Rect2(1080,456,136,34),24,"Score",C.MUTED)
	put("High press",Rect2(880,510,280,28),20,"BodyStrong")
	put("Wide attack",Rect2(880,548,280,28),18,"Label",C.MUTED)
	action("Prepare",Rect2(880,610,336,48),func(): go("opponent"),"Primary","PrimaryAction")

func make_offer() -> void:
	var lo := 75 if model.wins == 0 else (94 if model.wins >= 9 else 85 if model.wins >= 6 else 75)
	var hi := 79 if model.wins == 0 else (114 if model.wins >= 9 else 104 if model.wins >= 6 else 94)
	var rng := RandomNumberGenerator.new()
	rng.seed = 541+model.wins*31+model.rolls*17+(127 if model.market_restocked else 0)
	var generated: Dictionary = load("res://run/acquisition.gd").generate(library.recruits,[{"min":lo,"max":hi,"weight":100}],["GK","DEF","MID","ATT","WILD","DEF","MID","ATT"],plan.cards.map(func(item): return item.person_id),rng)
	assert(generated.ok)
	offers = generated.cards.map(func(id): return library.cards[id])
	model.choice = 0

func opposition_plan() -> Resource:
	var candidates: Array = library.variants.values().filter(func(row): return row.stage == mini(12,model.wins+1))
	return library.opponent_plan(candidates[0].id)

func rival_name() -> String:
	return ["Marshgate FC","Harbor Rovers","Foundry Town","Forge Sporting","Crown Vale","Rive Athletic","Rive Athletic","Isar Union","Brazil","France","Argentina","Brazil"][mini(11,model.wins)]

func squad(opponent: bool, record: bool = false) -> void:
	title("Saved eleven" if record else rival_name() if opponent else "Squad")
	var active: Resource = opposition_plan() if opponent and not record else plan
	var selected_formation: String = active.formation if opponent else formation
	C.panel(content,Rect2(32,176,194,406))
	if opponent: crest(content,Rect2(48,198,72,80),"bridge" if model.wins != 7 else "mountain")
	else: C.flag_view(content,model.origin,Rect2(52,214,64,44))
	put("OVR",Rect2(136,194,80,28),14,"Team",C.MUTED)
	put(str(ceili(Library.xi_rating(active))),Rect2(128,220,88,62),44,"Score")
	put(selected_formation,Rect2(48,294,160,44),29,"Team")
	if record: pass
	elif opponent:
		put("High press",Rect2(48,368,160,30),20,"BodyStrong")
		put("Wide attack",Rect2(48,414,160,30),18,"Label",C.MUTED)
		action("Squad",Rect2(48,506,162,44),func(): show_player_panel=false; go("squad"),"Button")
	else:
		action("Formation",Rect2(48,358,162,44),formation_drawer,"Button")
		action("Tactics",Rect2(48,414,162,44),tactics_drawer,"Button")
		action("Assignments",Rect2(48,470,162,44),assignments_drawer,"Button")
		put(tactic,Rect2(48,538,162,30),16,"Label",C.MUTED)
	var pitch := C.Pitch.new()
	pitch.position = Vector2(258,168)
	pitch.size = Vector2(958,440)
	content.add_child(pitch)
	var rows: Array = {"4-3-3":[[8,9,10],[5,6,7],[1,2,3,4],[0]],"4-4-2":[[9,10],[5,6,7,8],[1,2,3,4],[0]],"4-2-3-1":[[9],[7,8,10],[5,6],[1,2,3,4],[0]],"4-1-4-1":[[9],[6,7,8,10],[5],[1,2,3,4],[0]],"4-2-2-2":[[9,10],[7,8],[5,6],[1,2,3,4],[0]],"4-3-1-2":[[9,10],[8],[5,6,7],[1,2,3,4],[0]],"3-4-3":[[8,9,10],[4,5,6,7],[1,2,3],[0]],"3-5-2":[[9,10],[4,5,6,7,8],[1,2,3],[0]],"5-3-2":[[9,10],[6,7,8],[1,2,3,4,5],[0]]}[selected_formation]
	for row_index in rows.size():
		var row: Array = rows[row_index]
		for index in row.size():
			var slot: int = row[index]
			var width := 96.0 if rows.size() <= 4 else 82.0
			var x: float = 258+479+(index-(row.size()-1)/2.0)*minf(206,790.0/row.size())-width/2
			var y: float = 166+row_index*312.0/maxi(1,rows.size()-1)
			var node := card(content,active.cards[active.starters[slot]],Vector2(x,y),width)
			node.set_selected(show_player_panel and slot == selected_slot)
			node.name = "PitchSlot"+str(slot)
			node.pressed.connect(func(): selected_slot=slot; show_player_panel=true; go(page))
	put("RESERVES",Rect2(258,610,200,24),12,"Section",C.MUTED)
	if not opponent:
		action("Cancel",Rect2(32,652,164,44),func(): plan=Lineup.from_data(committed_plan); formation=committed_formation; go("pyramid"),"Quiet","CancelSquad")
	var bench: Array = active.bench_order
	for index in mini(7,bench.size()):
		var node := card(content,active.cards[bench[index]],Vector2(258+index*88,640),46)
		node.name = "Reserve"+str(index)
		node.pressed.connect(func():
			if opponent: return
			var incoming: int = bench[index]
			if selected_slot == 0 and "GK" not in plan.cards[incoming].natural_roles: return
			plan.starters[selected_slot] = incoming
			plan.refresh_bench_order()
			go("squad"))
	if show_player_panel:
		C.panel(content,Rect2(936,160,312,540))
		action("Close",Rect2(1120,112,128,42),func(): show_player_panel=false; go(page),"Quiet")
		var chosen: Resource = active.cards[active.starters[selected_slot]]
		var large := card(content,chosen,Vector2(960,184),264)
		large.pressed.connect(func():
			selected_card=cards.find(chosen)
			if selected_card < 0:
				cards.append(chosen)
				selected_card=cards.size()-1
			previous_page=page
			go("player"))
		var target_role: String = Lineup.ROLES[active.formation][selected_slot]
		put("%s slot   %d OVR" % [target_role,chosen.rating(target_role,true)],Rect2(958,582,290,28),16,"Label",C.MUTED if target_role in chosen.natural_roles else C.ACCENT)
	action("Back" if record else "Start match" if opponent else "Apply squad",Rect2(960,652,288,44),func(): go("records") if record else go("match") if opponent else apply_squad(),"Primary","PrimaryAction")

func apply_squad() -> void:
	toast = "Squad saved"
	committed_plan = plan.to_data()
	committed_formation = formation
	model.revision += 1
	go("pyramid")

func recruitment(market: bool) -> void:
	title("Market" if market else "Free signing")
	if not market: put("VICTORY 2–1    +$%dm" % model.rules.win_prizes_m[maxi(0,model.wins-1)],Rect2(34,158,860,30),17,"Score",C.MUTED)
	else: put("%d / 2 signings" % model.market_bought,Rect2(34,158,300,30),17,"Score",C.MUTED)
	var count := 4 if market else 5
	var width := 224.0 if market else 232.0
	var gap := 40.0 if market else 12.0
	var start := (1280-(count*width+(count-1)*gap))/2
	for index in count:
		var offer_index: int = market_page*4+index if market else index
		var definition: Resource = offers[offer_index]
		var node := card(content,definition,Vector2(start+index*(width+gap),216),width)
		node.set_selected(offer_index == model.choice)
		node.disabled = market and definition.card_id in model.purchased
		if node.disabled: node.status.text = "SIGNED"
		node.name = "OfferCard"+str(index)
		node.pressed.connect(func(): model.choice=offer_index; go(page))
		if market: put(model.money(model.price(definition.rating())),Rect2(node.position.x,536,width,36),26,"Score").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chosen: Resource = offers[model.choice]
	put(chosen.display_name,Rect2(32,580,610,34),24,"Team")
	put("Balance after "+model.money(model.cash-model.price(chosen.rating())) if market else "Free signing",Rect2(32,616,610,24),16,"Label",C.MUTED)
	action("Player details",Rect2(690,582,202,44),func(): cards.append(chosen); selected_card=cards.size()-1; previous_page=page; go("player"),"Quiet")
	var sign := action("Sign "+chosen.display_name.split(" ")[-1],Rect2(944,646,304,48),func(): sign_player(chosen,market),"Primary","PrimaryAction")
	if market:
		sign.disabled = model.cash < model.price(chosen.rating()) or model.market_bought >= 2 or chosen.card_id in model.purchased
		var restock_cost: int = int(model.rules.market_restock_prices_m[clampi(int(model.wins/3),1,3)-1])*1000000
		var refresh := action("Restock "+model.money(restock_cost),Rect2(32,646,230,48),func(): if model.restock(): make_offer(); go("market"))
		refresh.disabled = model.market_restocked or model.market_bought >= 2 or model.cash < restock_cost
		action("Leave market",Rect2(288,646,220,48),func(): go("pyramid"),"Quiet")
		action("%d / 2" % (market_page+1),Rect2(574,646,112,48),func(): market_page=1-market_page; model.choice=market_page*4; go("market"),"Quiet","MarketPage")
	else:
		var cost := model.reroll_cost()
		var roll := action("Reroll "+model.money(cost) if cost >= 0 else "No rerolls left",Rect2(32,646,224,48),func(): if model.reroll(): make_offer(); go("reward"))
		roll.disabled = cost < 0 or cost > model.cash
		if model.wins > 0: action("Take $2m",Rect2(280,646,224,48),func(): model.bank(); go(reward_destination()),"Quiet")
func make_drawer(heading: String) -> Control:
	if is_instance_valid(drawer): drawer.queue_free()
	drawer = C.panel(content,Rect2(760,92,488,610),C.RAISED)
	put(heading,Rect2(24,20,340,46),30,"Heading",C.INK,drawer)
	action("Close",Rect2(360,22,104,42),func(): drawer.queue_free(),"Quiet","",drawer)
	if not reduced_motion:
		drawer.position.x += 14
		drawer.modulate.a = 0
		var tween := drawer.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(drawer,"position:x",760,0.18)
		tween.tween_property(drawer,"modulate:a",1,0.18)
	return drawer

func formation_drawer() -> void:
	var box := make_drawer("Formation")
	for index in FORMATIONS.size():
		var value: String = FORMATIONS[index]
		action(value,Rect2(24+index%3*148,104+int(index/3)*130,136,108),func():
			formation=value
			if Lineup.ROLES.has(value): plan.formation=value
			go("squad"),"Primary" if value == formation else "Button","Formation"+str(index),box)

func tactics_drawer() -> void:
	var box := make_drawer("Tactics")
	var groups := [["Attack","attack",["possession","direct","counter"]],["Defence","defence",["balanced","high_press","deep_block"]],["Route","route",["mixed","wide","central"]]]
	for index in groups.size():
		var group: Array = groups[index]
		put(group[0],Rect2(24,100+index*136,400,32),20,"BodyStrong",C.INK,box)
		for option_index in 3:
			var value: String = group[2][option_index]
			action(value.replace("_"," ").capitalize(),Rect2(24+option_index*148,148+index*136,136,48),func(): plan.set(group[1],value); tactic=plan.attack.capitalize(); tactics_drawer(),"Primary" if plan.get(group[1]) == value else "Button","Tactic"+value,box)
	put("Changes apply before kickoff.",Rect2(24,532,430,30),16,"Label",C.MUTED,box)

func assignments_drawer() -> void:
	var box := make_drawer("Assignments")
	var fields := [["Captain","captain"],["Free kicks","free_kick_taker"],["Corners","corner_taker"],["Penalties","penalty_taker"]]
	for index in 4:
		var field: Array = fields[index]
		put(field[0],Rect2(24,94+index*112,420,28),18,"BodyStrong",C.INK,box)
		var choice := OptionButton.new()
		choice.position = Vector2(24,132+index*112)
		choice.size = Vector2(440,44)
		for slot in 11: choice.add_item(plan.cards[plan.starters[slot]].display_name)
		choice.select(plan.get(field[1]))
		choice.item_selected.connect(func(slot): plan.set(field[1],slot))
		box.add_child(choice)

func sign_player(chosen: Resource, market: bool) -> void:
	if plan.cards.size() < 18:
		if market and not model.buy(chosen.rating(),chosen.card_id): return
		plan.cards.append(chosen)
		plan.refresh_bench_order()
		committed_plan = plan.to_data()
		go("market" if market else reward_destination())
		return
	var box := make_drawer("Replace a player")
	card(box,chosen,Vector2(24,96),164)
	var incoming := chosen
	put("Incoming",Rect2(24,334,200,28),16,"Label",C.MUTED,box)
	for index in mini(5,plan.bench_order.size()):
		var outgoing_index: int = plan.bench_order[index]
		var old: Resource = plan.cards[outgoing_index]
		action(old.display_name,Rect2(216,100+index*72,248,58),func():
			if market and not model.buy(incoming.rating(),incoming.card_id): return
			plan.cards[outgoing_index] = incoming
			committed_plan = plan.to_data()
			go("market" if market else reward_destination()),"Button","Replace"+str(index),box)

func reward_destination() -> String:
	return "market" if model.wins in [3,6,9] else "coaching" if model.wins in [4,8] else "pyramid"

func player_sheet() -> void:
	var chosen: Resource = cards[clampi(selected_card,0,cards.size()-1)]
	title(chosen.display_name)
	action("Back",Rect2(1112,108,136,44),func(): go(previous_page),"Quiet","PrimaryAction")
	card(content,chosen,Vector2(56,188),326)
	C.panel(content,Rect2(424,176,824,464))
	put(chosen.primary_role,Rect2(460,192,120,44),30,"Score")
	put("%d OVR" % chosen.rating(),Rect2(650,192,280,44),30,"Score")
	var keys: Array = chosen.KEEPING.duplicate() if chosen.primary_role == "GK" else chosen.STATS.duplicate()
	if chosen.primary_role == "GK": keys.append("PHY")
	for index in keys.size():
		var key: String = keys[index]
		var value: int = chosen.attributes.get(key,chosen.keeper_attributes.get(key,0))
		var x := 460+(index%2)*354
		var y := 268+int(index/2)*72
		put(key,Rect2(x,y,80,34),17,"BodyStrong",C.MUTED)
		var stat_value := put(str(value),Rect2(x+200,y-5,100,42),30,"Score")
		stat_value.name = "Stat"+key
	if not chosen.trait_id.is_empty():
		var ability: Dictionary = chosen.Traits.catalogue[chosen.trait_id]
		put(ability.name,Rect2(460,500,700,42),28,"Heading")
		var effect := put(ability.effect,Rect2(460,550,720,82),19)
		effect.name = "TraitEffect"
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		effect.clip_text = true
		effect.custom_minimum_size = Vector2.ZERO
		effect.size = Vector2(720,82)
		effect.set_deferred("size",Vector2(720,82))
	action("Details",Rect2(460,648,180,44),func():
		var box := make_drawer("Player details")
		put("Natural: "+", ".join(chosen.natural_roles),Rect2(24,108,440,38),18,"Label",C.INK,box)
		var familiarity := put("Familiar: "+", ".join(chosen.familiar_roles),Rect2(24,164,440,68),18,"Label",C.MUTED,box)
		familiarity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var meta: Dictionary = library.metadata(chosen.card_id)
		var source := put(str(meta.get("reference_note","Original provisional game ratings.")),Rect2(24,268,440,240),16,"Label",C.MUTED,box)
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART,"Quiet")
	action("Compare",Rect2(664,648,180,44),func():
		var other: Resource = plan.cards[plan.starters[selected_slot]]
		var box := C.panel(content,Rect2(112,120,1056,576),C.RAISED)
		card(box,chosen,Vector2(132,36),264)
		card(box,other,Vector2(640,36),264)
		put("%s slot" % other.primary_role,Rect2(408,214,224,36),20,"Team",C.INK,box)
		put("%d     %d" % [chosen.rating(other.primary_role,true),other.rating(other.primary_role,true)],Rect2(416,264,216,38),28,"Score",C.INK,box)
		action("Close",Rect2(848,514,176,44),func(): box.queue_free(),"Quiet","",box),"Quiet")

func settings() -> void:
	title("Settings")
	C.panel(content,Rect2(328,184,920,480))
	for index in 4:
		var value: String = ["Display","Audio","Controls","Accessibility"][index]
		action(value,Rect2(32,208+index*64,244,48),func(): settings_category=value; setting_content(),"Button" if settings_category == value else "Quiet","Settings"+value)
	action("Back",Rect2(1112,108,136,44),func(): go(previous_page),"Quiet","PrimaryAction")
	setting_content()

func setting_content() -> void:
	for node in content.get_children():
		if node is Button and str(node.name).begins_with("Settings"):
			node.theme_type_variation = "Button" if node.name == "Settings"+settings_category else "Quiet"
			node.add_theme_color_override("font_color",C.ACCENT if node.name == "Settings"+settings_category else C.INK)
	var old: Control = settings_body if is_instance_valid(settings_body) and settings_body.get_parent() == content else null
	settings_body = Control.new()
	settings_body.position = Vector2(352,202)
	settings_body.size = Vector2(864,434)
	content.add_child(settings_body)
	if is_instance_valid(old):
		old.modulate.a = 1
		freeze_tree(old)
		if not reduced_motion:
			settings_body.modulate.a = 0
			var tween := settings_body.create_tween()
			tween.tween_property(settings_body,"modulate:a",1,0.16)
			tween.finished.connect(func(): if is_instance_valid(old): old.queue_free())
		else: old.queue_free()
	put(settings_category,Rect2(0,0,840,44),30,"Heading",C.INK,settings_body)
	if settings_category == "Audio":
		for index in 2:
			put(["Music","Effects"][index],Rect2(0,96+index*130,600,34),20,"BodyStrong",C.INK,settings_body)
			var slider := HSlider.new()
			slider.min_value = 0
			slider.max_value = 100
			slider.value = 70 if index == 0 else 85
			slider.position = Vector2(0,150+index*130)
			slider.size = Vector2(680,40)
			settings_body.add_child(slider)
			var amount := put("%d%%" % slider.value,Rect2(740,146+index*130,100,40),24,"Score",C.INK,settings_body)
			slider.value_changed.connect(func(value): amount.text="%d%%" % value)
	elif settings_category == "Controls":
		for index in 4:
			put(["Pause","Normal speed","Double speed","Menu"][index],Rect2(0,90+index*72,540,44),20,"Label",C.INK,settings_body)
			action(["Space","1","2","Esc"][index],Rect2(652,90+index*72,188,44),func(): toast="Key rebinding is an implementation task.","Button","",settings_body)
	else:
		var fields := ["Fullscreen"] if settings_category == "Display" else ["Reduced motion","Match effects"]
		for index in fields.size():
			put(fields[index],Rect2(0,96+index*106,600,44),20,"Label",C.INK,settings_body)
			var toggle := C.Toggle.new()
			toggle.position = Vector2(664,96+index*106)
			toggle.size = Vector2(176,44)
			toggle.text = "On" if (index == 0 and reduced_motion and settings_category == "Accessibility") else "Off"
			toggle.button_pressed = toggle.text == "On"
			toggle.toggled.connect(func(on):
				toggle.text="On" if on else "Off"
				if settings_category == "Accessibility" and index == 0: reduced_motion=on)
			settings_body.add_child(toggle)
		if settings_category == "Display":
			put("Interface",Rect2(0,202,600,44),20,"Label",C.INK,settings_body)
			put("100%",Rect2(664,202,176,44),24,"Score",C.MUTED,settings_body)
			put("Resolution",Rect2(0,308,600,44),20,"Label",C.INK,settings_body)
			var pixels := get_viewport().get_visible_rect().size
			put("%d × %d" % [pixels.x,pixels.y],Rect2(590,308,250,44),24,"Score",C.MUTED,settings_body)
func records() -> void:
	title("Records")
	for index in 3:
		var row := C.panel(content,Rect2(32,222+index*132,1216,108))
		C.flag_view(row,["ENG","BRA","JPN"][index],Rect2(24,30,64,44))
		put(["England","Brazil","Japan"][index],Rect2(124,18,300,36),28,"Team",C.INK,row)
		put("Champions" if index == 0 else "%d wins   3 defeats" % (10-index*3),Rect2(124,60,360,28),17,"Label",C.MUTED,row)
		put("%d OVR" % (ceili(Library.xi_rating(plan))+index),Rect2(664,28,240,44),30,"Score",C.INK,row)
		action("View eleven",Rect2(956,32,224,44),func(): go("record_xi"),"Button","",row)

func collection() -> void:
	title("Collection")
	put("3 / 200",Rect2(1052,110,196,42),27,"Score",C.MUTED)
	for index in 8:
		var known := index < 3
		var node := card(content,cards[index] if known else null,Vector2(32+index*154,244),138,known)
		node.disabled = not known
		if known: node.pressed.connect(func(): selected_card=index; previous_page="collection"; go("player"))
	action("Acquired",Rect2(32,166,164,40),func(): go("collection"),"Button")

func result_page() -> void:
	title("Victory")
	put("2 – 1",Rect2(32,214,580,144),108,"Score")
	put("England",Rect2(36,370,410,44),30,"Team")
	put("Rive Athletic",Rect2(462,370,410,44),30,"Team",C.MUTED)
	var receipt := C.panel(content,Rect2(888,218,360,284))
	put("MATCH WINNINGS",Rect2(28,24,300,30),15,"Section",C.MUTED,receipt)
	var prize: int = int(model.rules.win_prizes_m[mini(11,model.wins)])
	put("+"+model.money(prize*1000000),Rect2(28,80,300,80),64,"Score",C.INK,receipt)
	put("Balance "+model.money(model.cash),Rect2(28,202,300,34),22,"Score",C.MUTED,receipt)
	put("Shots",Rect2(36,494,180,30),18,"Label",C.MUTED)
	put("8    5",Rect2(260,490,240,38),26,"Score")
	put("Possession",Rect2(36,550,180,30),18,"Label",C.MUTED)
	put("54%    46%",Rect2(260,546,300,38),26,"Score")
	action("Continue",Rect2(944,646,304,48),func():
		if reward_claimed: return
		reward_claimed = true
		model.wins=mini(12,model.wins+1)
		model.cash+=prize*1000000
		model.rolls=0
		if model.wins == 12: go("champions")
		else: make_offer(); go("reward"),"Primary","PrimaryAction")

func coaching() -> void:
	title("Choose a principle")
	var options := [["Short combinations","+3 PAS","Ground passes in your own and middle third."],["Wide service","+3 PAS","Crosses from wide positions."],["Counter runners","+3 PAC","Two seconds after a controlled recovery."]]
	for index in 3:
		var option: Array = options[index]
		var box := C.panel(content,Rect2(32+index*412,230,392,330))
		put(option[0],Rect2(24,24,344,46),28,"Heading",C.INK,box)
		put(option[1],Rect2(24,102,344,84),54,"Score",C.ACCENT,box)
		var detail := put(option[2],Rect2(24,210,344,84),19,"Label",C.MUTED,box)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.set_deferred("size",Vector2(344,84))
		action("Selected" if coaching_choice == index else "Choose",Rect2(24,272,344,44),func(): coaching_choice=index; go("coaching"),"Button","",box)
	action("Confirm principle",Rect2(944,646,304,48),func(): go("pyramid"),"Primary","PrimaryAction")

func terminal(won: bool) -> void:
	header.visible = false
	crest(content,Rect2(134,188,200,220),"trophy" if won else "gate",C.SURFACE,C.ACCENT)
	put("WORLD CHAMPIONS" if won else "NEXT TIME.",Rect2(430,204,800,90),66,"Heading")
	put("12 wins" if won else "%d wins   3 defeats" % model.wins,Rect2(436,326,650,48),30,"Score",C.MUTED)
	put("%d OVR" % ceili(Library.xi_rating(plan)),Rect2(436,394,640,48),30,"Score")
	action("New run",Rect2(438,536,328,52),func(): go("origin"),"Primary","PrimaryAction")
	action("Records",Rect2(792,536,328,52),func(): go("records"),"Quiet")

func match_preview() -> void:
	reward_claimed = false
	header.visible = false
	live_view = load("res://outputs/fc-mobile-ui-v6/match_reference.gd").new()
	live_view.fixture_seed = 2026
	live_view.external_model = load("res://match/match_sim.gd").new(2026,180,plan,opposition_plan(),true)
	live_view.team_names = ["England",rival_name()]
	content.add_child(live_view)
	live_view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	live_view.size = Vector2(1280,720)
	live_view.set_physics_process(false)
	live_view.paused = true
	for tick in 1200: live_view.sim.step()
	live_view._sync_state()
	live_view.snap_presentation()
	# Preserve the complete native HUD: shirts, measured team/score spacing and controls.
	# The previous design overlay covered the kit icons and is withdrawn.
	live_score = live_view.hud.labels.score
	live_clock = live_view.hud.labels.clock

func _process(_delta: float) -> void:
	if page != "match" or not is_instance_valid(live_view): return
	live_score.text = "%d – %d" % live_view.sim.scores
	live_clock.text = "%d′" % live_view.sim.display_minute()
	if live_view.sim.finished: go("result")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(drawer) and drawer.get_parent() == content: drawer.queue_free()
		elif page in ["collection","records"]: go(library_return)
		elif page == "record_xi": go("records")
		else: go(previous_page if page in ["settings","player"] else "home" if page == "origin" else "pyramid")
		get_viewport().set_input_as_handled()
