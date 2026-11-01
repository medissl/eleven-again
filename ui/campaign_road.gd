extends RefCounted
const Lobby = preload("res://ui/campaign_lobby.gd")
const CENTRES := [Vector2(116,574),Vector2(270,536),Vector2(444,564),Vector2(622,516),Vector2(700,430),Vector2(538,390),Vector2(358,436),Vector2(188,382),Vector2(218,280),Vector2(370,246),Vector2(536,286),Vector2(584,190)]
static func build(app) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	var current: int = data.get("node",data.wins)
	app.road_stage = clampi(app.road_stage,current,mini(11,current+1))
	var selected: int = app.road_stage
	Lobby.copy(app,app.screen,"THE ROAD",Rect2(32,98,700,50),36,"Heading")
	if data.content_version == "campaign_v1": Lobby.copy(app,app.screen,"LEGACY RUN",Rect2(620,114,176,26),13,"Section")
	var board := Board.new()
	board.current = current
	board.size = Vector2(800,636)
	app.screen.add_child(board)
	for index in 12:
		var revealed := index == current or index == current+1
		var stop := Stop.new()
		stop.name = "Fixture"+str(index+1)
		stop.position = CENTRES[index]-Vector2(44,34)
		stop.size = Vector2(88,68)
		stop.disabled = not revealed
		stop.completed = index < current
		stop.selected = index == selected
		stop.current = index == current
		if revealed:
			var fixture: Dictionary = data.fixtures[index]
			var club: Dictionary = app.library.clubs[fixture.club_id]
			stop.crest = preload("res://ui/pixel_art.gd").texture(app.library.badge_path(club.id),Vector2i(32,32))
			stop.tooltip_text = "Current match" if index == current else "Next opponent"
		else: stop.tooltip_text = "Completed" if stop.completed else "Locked"
		stop.pressed.connect(func(): app.road_stage=index; app.render("board"))
		app.screen.add_child(stop)
	var pawn := Pawn.new()
	pawn.name = "RoadPawn"
	pawn.position = CENTRES[current]
	pawn.size = Vector2(48,60)
	app.screen.add_child(pawn)
	if app.road_token_stage >= 0 and app.road_token_stage < current and not app.preferences.data.motion:
		pawn.position = CENTRES[app.road_token_stage]
		var tween := pawn.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for index in range(app.road_token_stage+1,current+1): tween.tween_property(pawn,"position",CENTRES[index],0.65)
	app.road_token_stage = current
	var fixture: Dictionary = data.fixtures[selected]
	var club: Dictionary = app.library.clubs[fixture.club_id]
	var rival: Control = Lobby.panel(app.screen,Rect2(840,174,408,438))
	Lobby.copy(app,rival,"CURRENT MATCH" if selected == current else "NEXT OPPONENT",Rect2(24,22,360,26),16,"Section")
	var crest := TextureRect.new()
	crest.texture = preload("res://ui/pixel_art.gd").texture(app.library.badge_path(club.id),Vector2i(32,32))
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.position = Vector2(132,64)
	crest.size = Vector2(144,154)
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rival.add_child(crest)
	nation_flag(crest,club)
	Lobby.copy(app,rival,club.name,Rect2(24,228,360,70),30,"Heading").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Lobby.copy(app,rival,"%d OVR   %s" % [ceili(app.library.xi_rating(app.library.opponent_plan(fixture.variant_id))),club.formation],Rect2(24,312,360,32),23,"Score")
	Lobby.copy(app,rival,club.attack.capitalize()+" / "+club.defence.replace("_"," ").capitalize(),Rect2(24,358,360,28),18)
	var rule: Dictionary = app.library.rules.stages[current]
	var rewards: Array[String] = []
	if rule.recruit: rewards.append("Signing")
	if rule.market != null: rewards.append("Market")
	if rule.coaching: rewards.append("Coaching")
	Lobby.copy(app,app.screen,"Next node unlocks after this match. Three defeats end the run." if data.has("node") else "After victory: "+" + ".join(rewards),Rect2(44,606,728,28),16,"Section")
	Lobby.action(app,app.screen,"Squad","CampaignSquad",Rect2(32,652,172,44),app.squad)
	Lobby.action(app,app.screen,"Save and exit","PageBack",Rect2(222,652,208,44),app.save_and_exit).theme_type_variation="Quiet"
	if selected != current:
		Lobby.action(app,app.screen,"Return to current match","NextRoadMatch",Rect2(840,646,408,50),func(): app.road_stage=current; app.render("board"),true)
	else: Lobby.action(app,app.screen,"Prepare match","PrepareCampaign",Rect2(840,646,408,50),app.prepare,true)
	if data.has("node"):
		Lobby.action(app,app.screen,"Scouting","MasterScouting",Rect2(468,652,224,44),func(): app.render("master_scout"))
	elif not data.market.is_empty() and data.market.open:
		Lobby.action(app,app.screen,"Market","ReopenMarket",Rect2(468,652,224,44),func(): app.act("reopen_market",[],data.revision))
static func nation_flag(crest: TextureRect, club: Dictionary) -> void:
	var texture := preload("res://ui/flags.gd").texture(club.get("country_code",""))
	if texture == null: return
	var flag := TextureRect.new()
	flag.texture=texture; flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.position=Vector2(crest.size.x*0.2,crest.size.y*0.38); flag.size=Vector2(crest.size.x*0.6,crest.size.x*0.4)
	flag.mouse_filter=Control.MOUSE_FILTER_IGNORE
	crest.add_child(flag)
class Stop:
	extends Button
	var crest: Texture2D
	var selected := false
	var current := false
	var completed := false
	func _init() -> void:
		set_meta("game_control",true)
		for state in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	func _ready() -> void:
		if crest != null:
			var image := TextureRect.new()
			image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			image.texture=crest; image.position=Vector2(28,12); image.size=Vector2(32,36)
			image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.mouse_filter=MOUSE_FILTER_IGNORE; add_child(image)
		elif not completed:
			var image := TextureRect.new()
			image.texture=preload("res://assets/ui/arcade/lock.png"); image.position=Vector2(32,16); image.size=Vector2(24,30)
			image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.mouse_filter=MOUSE_FILTER_IGNORE; image.modulate=Color(1,1,1,0.85)
			add_child(image)
		else:
			var check := Label.new()
			check.text="✓"; check.position=Vector2(30,12); check.add_theme_font_size_override("font_size",26)
			check.mouse_filter=MOUSE_FILTER_IGNORE; add_child(check)
	func _draw() -> void:
		var hot: bool=not disabled and (is_hovered() or (has_focus() and get_viewport().get_meta("keyboard_navigation",false)))
		draw_texture_rect(preload("res://assets/ui/arcade/node.png"),Rect2(12,8,64,52),false,Color.WHITE if selected or hot or current else Color(0.65,0.70,0.75,1))

class Pawn:
	extends Control
	func _ready() -> void:
		mouse_filter=MOUSE_FILTER_IGNORE
		var image := TextureRect.new()
		image.texture=preload("res://assets/ui/arcade/pawn.png")
		image.position=Vector2(-24,-60); image.size=Vector2(48,64)
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter=MOUSE_FILTER_IGNORE
		add_child(image)
class Board:
	extends Control
	var current := 0
	func _init() -> void: mouse_filter=MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_texture_rect(preload("res://assets/ui/arcade/board.png"),Rect2(16,156,800,448),false)
		# Only live route connections are geometry; all board/lock/pawn illustration is generated artwork.
		for index in 11:
			var from: Vector2=CENTRES[index]
			var to: Vector2=CENTRES[index+1]
			var length:=from.distance_to(to)
			var direction:=from.direction_to(to)
			for step in range(32,int(length)-30,14):
				var point:=(from+direction*step).snapped(Vector2(2,2))
				draw_line(point,point+direction*7,Color("F5CE65") if index <= current else Color("A8C8BF"),4,false)
