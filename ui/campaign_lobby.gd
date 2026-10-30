extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Glass = preload("res://ui/glass_panel.gd")
const Lineup = preload("res://squad/lineup.gd")
static func copy(app, parent: Node, value: String, rect: Rect2, pixels: int = 20, role: String = "Label") -> Label:
	var label: Label = app.text(parent,value,pixels,role)
	label.position = rect.position
	label.size = rect.size
	return label
static func panel(parent: Node, rect: Rect2) -> Control:
	var surface := Glass.new()
	surface.position = rect.position
	surface.size = rect.size
	parent.add_child(surface)
	return surface
static func action(app, parent: Node, value: String, id: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var button: Button = app.button(parent,value,id,callback,primary)
	button.position = rect.position
	button.size = rect.size
	return button
static func main(app) -> void:
	var preview: Dictionary = app.session.preview()
	copy(app,app.screen,"ELEVEN AGAIN",Rect2(40,28,500,52),34,"Heading")
	for entry in [["Collection","Collection",func(): app.render("collection")],["Records","Records",func(): app.render("records")],["Settings","MainSettings",app.settings],["Quit","QuitGame",func(): app.get_tree().quit()]]:
		var index: int = ["Collection","Records","Settings","Quit"].find(entry[0])
		action(app,app.screen,entry[0],entry[1],Rect2(680+index*144,32,132,44),entry[2]).theme_type_variation="Quiet"
	copy(app,app.screen,"THE CLIMB",Rect2(40,160,720,116),96,"Heading")
	copy(app,app.screen,"12 WINS. ONE TROPHY.",Rect2(48,284,660,42),24,"Team")
	if not preview.is_empty():
		for index in preview.best_cards.size():
			var card: Control = Parts.card(app.screen,app.library,preview.best_cards[index],214,1.0,true,true)
			card.position = Vector2(764+index*242,134)
			card.size = Vector2(214,299.6)
			card.pressed.connect(func(): app.inspect(preview.best_cards[index]))
	var squad := panel(app.screen,Rect2(32,486,280,198))
	copy(app,squad,"MY SQUAD",Rect2(24,18,232,40),25,"Heading")
	var data: Dictionary = app.session.controller.snapshot()
	var plan: Resource = Lineup.from_data(data.plan) if not data.is_empty() else null
	copy(app,squad,str(ceili(app.library.xi_rating(plan)))+" OVR" if plan != null else "0 COLLECTED",Rect2(24,74,240,52),36,"Score")
	action(app,squad,"Squad" if plan != null and data.step == "prepare" else "Collection","HomeSquad",Rect2(24,142,232,40),func(): app.squad() if plan != null and data.step == "prepare" else app.render("collection"))
	var fresh := panel(app.screen,Rect2(328,486,280,198))
	copy(app,fresh,"NEW RUN",Rect2(24,28,232,48),30,"Heading")
	action(app,fresh,"Start","NewRun",Rect2(24,132,232,50),func(): app.render("origin"),preview.is_empty())
	var resume := panel(app.screen,Rect2(624,486,624,198))
	if not preview.is_empty():
		copy(app,resume,app.library.countries[preview.origin].name.to_upper(),Rect2(28,22,560,44),30,"Heading")
		copy(app,resume,"%d / 12 wins     %s" % [preview.wins,app.money(preview.cash)],Rect2(28,80,560,32),22,"Score")
		var pips := Parts.Mark.new()
		pips.kind="pips"; pips.used=preview.defeats; pips.position=Vector2(450,82); pips.size=Vector2(90,28)
		resume.add_child(pips)
		action(app,resume,"Continue","ContinueRun",Rect2(28,132,568,50),func(): if app.session.reload().ok: app.route(),true)
	else:
		copy(app,resume,"YOUR COLLECTION",Rect2(28,22,560,44),30,"Heading")
		copy(app,resume,"%d / 200" % app.session.profile.discoveries.size(),Rect2(28,80,560,32),25,"Score")
		action(app,resume,"Open collection","HomeCollection",Rect2(28,132,568,50),func(): app.render("collection"))

static func board(app, outer: Node) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	copy(app,app.screen,"THE CLIMB",Rect2(32,98,700,64),42,"Heading")
	var levels := [[12],[11],[9,10],[7,8],[4,5,6],[1,2,3]]
	var labels := ["THE FINAL","FINAL FOUR","ELITE OPPOSITION","LEAGUES","CLUBS","GRASSROOTS"]
	for level in 6:
		var stages: Array = levels[level]
		var y := 182+level*70
		panel(app.screen,Rect2(498-(stages.size()-1)*66,y-1,120+(stages.size()-1)*132,66))
		copy(app,app.screen,labels[level],Rect2(40,y+20,250,26),15,"Section")
		for index in stages.size():
			var stage: int = stages[index]
			var fixture: Dictionary = data.fixtures[stage-1]
			var club: Dictionary = app.library.clubs[fixture.club_id]
			var current: bool = stage == data.wins+1
			var done: bool = stage <= data.wins
			var x := 506+(index-(stages.size()-1)/2.0)*132
			var button := action(app,app.screen,"","Fixture"+str(stage),Rect2(x,y,104,62),func(): if current: app.prepare(),current)
			button.disabled = not current
			var badge := TextureRect.new()
			badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			badge.texture = load(app.library.badge_path(club.id) if current or done or club.is_boss else "res://assets/ui/matchday/icons/lock.svg")
			badge.position=Vector2(10,8); badge.size=Vector2(42,44); badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
			button.add_child(badge)
			copy(app,button,"✓" if done else str(stage),Rect2(64,14,38,34),22,"Score")
	var rival := panel(app.screen,Rect2(848,178,400,432))
	var fixture: Dictionary = data.fixtures[data.wins]
	var club: Dictionary = app.library.clubs[fixture.club_id]
	var crest := TextureRect.new()
	crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	crest.texture=load(app.library.badge_path(club.id))
	crest.position=Vector2(120,24); crest.size=Vector2(160,160); crest.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rival.add_child(crest)
	copy(app,rival,club.name,Rect2(28,198,344,78),32,"Heading").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	copy(app,rival,"%d OVR   %s" % [ceili(app.library.xi_rating(app.library.opponent_plan(fixture.variant_id))),club.formation],Rect2(28,292,344,34),24,"Score")
	copy(app,rival,club.attack.capitalize(),Rect2(28,346,344,34),21,"BodyStrong")
	action(app,app.screen,"Squad","CampaignSquad",Rect2(32,652,172,44),app.squad)
	action(app,app.screen,"Save and exit","PageBack",Rect2(222,652,208,44),app.save_and_exit).theme_type_variation="Quiet"
	action(app,app.screen,"Prepare match","PrepareCampaign",Rect2(880,646,336,50),app.prepare,true)
	if not data.market.is_empty() and data.market.open:
		action(app,app.screen,"Return to market","ReopenMarket",Rect2(468,652,224,44),func(): app.act("reopen_market",[],data.revision))
