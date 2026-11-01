extends RefCounted
const Lobby = preload("res://ui/campaign_lobby.gd")
const CENTRES := [Vector2(116,574),Vector2(270,536),Vector2(444,564),Vector2(622,516),Vector2(700,430),Vector2(538,390),Vector2(358,436),Vector2(188,382),Vector2(218,280),Vector2(370,246),Vector2(536,286),Vector2(584,190)]
static func build(app) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	var current: int = data.wins
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
			stop.crest = load(app.library.badge_path(club.id))
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
	crest.texture = load(app.library.badge_path(club.id))
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
	Lobby.copy(app,app.screen,"After victory: "+" + ".join(rewards),Rect2(44,606,728,28),16,"Section")
	Lobby.action(app,app.screen,"Squad","CampaignSquad",Rect2(32,652,172,44),app.squad)
	Lobby.action(app,app.screen,"Save and exit","PageBack",Rect2(222,652,208,44),app.save_and_exit).theme_type_variation="Quiet"
	if selected != current:
		Lobby.action(app,app.screen,"Return to current match","NextRoadMatch",Rect2(840,646,408,50),func(): app.road_stage=current; app.render("board"),true)
	else: Lobby.action(app,app.screen,"Prepare match","PrepareCampaign",Rect2(840,646,408,50),app.prepare,true)
	if not data.market.is_empty() and data.market.open:
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
	func _draw() -> void:
		var hot: bool = not disabled and (is_hovered() or (has_focus() and get_viewport().get_meta("keyboard_navigation",false)))
		draw_set_transform(Vector2(44,42),0,Vector2(1,0.48))
		draw_circle(Vector2(0,8),35,Color("030A12"))
		draw_circle(Vector2.ZERO,34,Color("132C3A") if not disabled else Color("101D27"))
		draw_arc(Vector2.ZERO,33,0,TAU,48,Color("8BEDFF") if selected or hot else Color("3E7487"),2,true)
		if current: draw_arc(Vector2.ZERO,38,0,TAU,48,Color("DECA8C"),2,true)
		draw_set_transform(Vector2.ZERO)
		if crest != null:
			draw_texture_rect(crest,Rect2(24,4,40,46),false)
		elif completed:
			draw_polyline(PackedVector2Array([Vector2(35,37),Vector2(42,44),Vector2(56,28)]),Color("72CBBE"),3,true)
		else:
			draw_arc(Vector2(44,25),7,PI,TAU,16,Color("6C8799"),2,true)
			draw_rect(Rect2(34,25,20,16),Color("243E4D"))
			draw_circle(Vector2(44,31),2,Color("9AB3BE"))
class Pawn:
	extends Control
	func _init() -> void: mouse_filter=MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_set_transform(Vector2(0,4),0,Vector2(1,0.4))
		draw_circle(Vector2.ZERO,17,Color(0,0,0,0.6))
		draw_set_transform(Vector2.ZERO)
		draw_colored_polygon(PackedVector2Array([Vector2(-12,-4),Vector2(-6,-14),Vector2(-4,-31),Vector2(4,-31),Vector2(6,-14),Vector2(12,-4)]),Color("C7A761"))
		draw_colored_polygon(PackedVector2Array([Vector2(-9,-5),Vector2(-3,-19),Vector2(-2,-32),Vector2(2,-32),Vector2(2,-4)]),Color("F2E4B5"))
		draw_circle(Vector2(0,-37),9,Color("C7A761"))
		draw_arc(Vector2(0,-37),8,PI,TAU,24,Color("F8EDD1"),2,true)
		draw_line(Vector2(-12,-4),Vector2(12,-4),Color("F8EDD1"),2,true)
class Board:
	extends Control
	var current := 0
	func _init() -> void: mouse_filter=MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var corners := PackedVector2Array([Vector2(124,164),Vector2(680,164),Vector2(800,600),Vector2(28,600)])
		for depth in range(7,0,-1):
			draw_set_transform(Vector2(0,depth*2))
			draw_colored_polygon(corners,Color("07131C"))
		draw_set_transform(Vector2.ZERO)
		draw_colored_polygon(corners,Color("10262E"))
		draw_polyline(PackedVector2Array([corners[0],corners[1],corners[2],corners[3],corners[0]]),Color("457682"),1.5,true)
		for row in 14:
			var y := 178+row*29
			var t := (y-164)/436.0
			draw_line(Vector2(lerpf(124,28,t),y),Vector2(lerpf(680,800,t),y),Color(0.2,0.5,0.55,0.045),1,true)
		# Football miniatures frame the road: floodlights, flags and training cones, never trees.
		for point in [Vector2(145,236),Vector2(648,208),Vector2(70,475),Vector2(760,548)]:
			draw_line(point,point-Vector2(0,56),Color("496775"),3,true)
			draw_rect(Rect2(point-Vector2(13,63),Vector2(26,12)),Color("9EDAE2"))
			for lamp in 4: draw_circle(point+Vector2(-9+lamp*6,-57),1.6,Color.WHITE)
			draw_colored_polygon(PackedVector2Array([point-Vector2(10,52),point+Vector2(-38,12),point+Vector2(38,12)]),Color(0.25,0.75,0.9,0.035))
		for index in 11:
			var point := Vector2(95+fposmod(index*137,650),225+fposmod(index*89,330))
			var near_path := false
			for centre in CENTRES: near_path = near_path or point.distance_to(centre) < 58
			if near_path: continue
			draw_colored_polygon(PackedVector2Array([point+Vector2(-5,3),point+Vector2(0,-11),point+Vector2(5,3)]),Color("9B624A"))
			draw_line(point+Vector2(-2,-3),point+Vector2(2,-3),Color("E8DDD0"),2,true)
		# A small practice ground and seating give the board a football setting.
		var field := PackedVector2Array([Vector2(354,318),Vector2(452,318),Vector2(466,358),Vector2(340,358),Vector2(354,318)])
		draw_colored_polygon(field,Color("173D3B"))
		draw_polyline(field,Color("608982"),1,true)
		draw_line(Vector2(402,318),Vector2(402,358),Color("608982"),1,true)
		for point in [Vector2(96,310),Vector2(664,332),Vector2(310,476)]:
			for row in 3:
				draw_rect(Rect2(point+Vector2(-26+row*3,-row*5),Vector2(52-row*6,4)),Color("355564"))
			for seat in 6: draw_rect(Rect2(point+Vector2(-22+seat*8,-9),Vector2(4,3)),Color("6A8791"))
		for index in 11:
			var from: Vector2 = CENTRES[index]
			var to: Vector2 = CENTRES[index+1]
			var length := from.distance_to(to)
			var direction := from.direction_to(to)
			for step in range(30,int(length)-28,16):
				var point := from+direction*step
				draw_line(point,point+direction*8,Color("9ABFC6") if index <= current else Color("35505C"),3,true)
