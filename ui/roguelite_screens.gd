extends RefCounted
const Parts=preload("res://ui/campaign_parts.gd")
const Lobby=preload("res://ui/campaign_lobby.gd")
const Rules=preload("res://run/roguelite_rules.gd")

static func heading(app, title: String, subtitle: String = "") -> void:
	Lobby.copy(app,app.screen,title,Rect2(32,96,1000,48),34,"Heading")
	Lobby.copy(app,app.screen,subtitle,Rect2(34,148,1196,34),18)

static func build(app) -> void:
	match app.page:
		"master_draft","master_market": draft(app,app.page == "master_market")
		"master_scout": scouting(app)
		"master_training": training(app)
		"master_route": route_choice(app)
		"master_manager": manager_choice(app)
		"master_result": result(app)
		"master_legacy":
			var board := preload("res://ui/legacy_board.gd").new()
			board.app=app; app.screen.add_child(board)
		"master_opportunities": opportunities(app)

static func scouting(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	heading(app,"SCOUTING","Four candidates. Sign one. Coins and run training reset when this campaign ends.")
	var target := OptionButton.new()
	target.name="ScoutTarget"
	for group in Rules.Economy.Packs.GROUPS: target.add_item(group)
	if "scouting4" in data.legacy:
		for role in ["LB","CB","RB","DM","CM","AM","LW","RW","ST"]: target.add_item(role)
	target.position=Vector2(452,536); target.size=Vector2(360,44)
	app.screen.add_child(target)
	for index in 3:
		var kind: String=["standard","position","elite"][index]
		var panel: Control=Lobby.panel(app.screen,Rect2(32+index*410,202,394,310))
		Lobby.copy(app,panel,kind.to_upper(),Rect2(24,24,346,38),28,"Heading")
		var weights: Array=Rules.Balance.DATA[("elite" if kind == "elite" else "standard")+"_weights"][Rules.Balance.act(data.node)-1]
		Lobby.copy(app,panel,"BRONZE  %s%%\nSILVER  %s%%\nGOLD    %s%%\nLEGEND  %s%%" % weights.map(func(w): return str(float(w)/100).trim_suffix(".0")),Rect2(24,78,346,108),20,"Score")
		var art := TextureRect.new()
		art.texture=preload("res://assets/ui/arcade/scout_pack.png")
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position=Vector2(278,78); art.size=Vector2(88,121)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		panel.add_child(art)
		var cost: int=Rules.pack_quote(data,kind).cost
		var button: Button=Lobby.action(app,panel,"Open  %d coins" % cost,"BuyPack"+kind,Rect2(24,228,346,50),func(): app.act("buy_pack",[kind,target.get_item_text(target.selected) if kind == "position" else ""],data.revision),true)
		button.disabled=data.cash < cost
	Lobby.copy(app,app.screen,"Position pack: at least two candidates from",Rect2(34,542,408,32),17)
	Lobby.action(app,app.screen,"Legacy options","MasterOpportunities",Rect2(840,536,408,44),func(): app.render("master_opportunities"))
	Lobby.action(app,app.screen,"Back","ScoutBack",Rect2(32,646,172,50),func(): app.render("board"))
	Lobby.action(app,app.screen,"Direct market","OpenMasterMarket",Rect2(438,646,360,50),func(): app.act("open_market",[],data.revision))
	Lobby.action(app,app.screen,"Training","OpenMasterTraining",Rect2(840,646,408,50),func(): app.render("master_training"))

static func draft(app, market: bool) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	var stock: Dictionary=data.market if market else data.offer
	heading(app,"MARKET" if market else "CHOOSE ONE", "Fixed stock. Pay only when you sign." if market else "Four revealed candidates. One signing.")
	var selected := {"id":"","outgoing":""}
	var confirm: Button=Lobby.action(app,app.screen,"Select a player","ConfirmMasterSigning",Rect2(840,646,408,50),func():
		app.confirm("Confirm signing?","%s joins your squad%s." % [app.library.cards[selected.id].display_name,"; "+app.library.cards[selected.outgoing].display_name+" leaves" if not selected.outgoing.is_empty() else ""],func(): app.act("sign_market" if market else "acquire",[selected.id,selected.outgoing],data.revision)),true)
	confirm.disabled=true
	var outgoing := OptionButton.new()
	outgoing.name="MasterReplacement"
	outgoing.position=Vector2(34,576); outgoing.size=Vector2(762,44)
	outgoing.add_item("Choose a player to replace" if data.plan.cards.size() == 18 else "No replacement needed")
	if data.plan.cards.size() == 18:
		for card in data.plan.cards: outgoing.add_item(card.display_name)
	else: outgoing.disabled=true
	app.screen.add_child(outgoing)
	var tiles := []
	var page_count: int=ceili(stock.cards.size()/4.0)
	app.market_offer_page=clampi(app.market_offer_page,0,page_count-1) if market else 0
	var first: int=app.market_offer_page*4 if market else 0
	var update := func():
		selected.outgoing=data.plan.cards[outgoing.selected-1].card_id if outgoing.selected > 0 else ""
		var cost: int=Rules.Balance.direct_price(app.library.cards[selected.id]) if market and not selected.id.is_empty() else 0
		confirm.text="Sign  %d coins" % cost if market else "Confirm signing"
		confirm.disabled=selected.id.is_empty() or (data.plan.cards.size() == 18 and selected.outgoing.is_empty()) or cost > data.cash
	outgoing.item_selected.connect(func(_index): update.call())
	for index in range(first,mini(first+4,stock.cards.size())):
		var id: String=stock.cards[index]
		var tile: Control=Parts.card(app.screen,app.library,id,216,1.0,true,false)
		tile.name="DraftCard"+str(index)
		tile.position=Vector2(64+(index-first)*306,214)
		tile.size=Vector2(216,302.4)
		tiles.append(tile)
		var sold: bool=market and id in stock.purchased
		tile.pressed.connect(func():
			if sold: return
			selected.id=id
			for item in tiles: item.set_pressed_no_signal(item == tile); item.queue_redraw()
			update.call())
		if sold: tile.modulate=Color(0.4,0.4,0.4)
		Lobby.copy(app,app.screen,"SIGNED" if sold else "%d coins" % Rules.Balance.direct_price(app.library.cards[id]) if market else "",Rect2(64+(index-first)*306,526,216,28),19,"Score")
	if not market:
		var weights: Array=data.offer.slot_weights[0]
		var total: float=weights.reduce(func(a,b): return a+b,0)
		var odds: String="Opening Silver signing (75-79 OVR)" if data.offer.kind == "starter" else "B %s%% / S %s%% / G %s%% / L %s%%" % weights.map(func(w): return str(snappedf(100.0*w/total,0.01)).trim_suffix(".0"))
		Lobby.copy(app,app.screen,odds+"  (adjusted for remaining pool)" if not data.offer.shortage_slots.is_empty() else odds,Rect2(34,182,1196,28),16)
	if market:
		Lobby.action(app,app.screen,"Back","MarketBack",Rect2(32,646,172,50),func(): app.act("close_market",[],data.revision))
		var cost := 0 if Rules.Legacy.available(data,"finance2") else 45
		var refresh: Button=Lobby.action(app,app.screen,"Refresh  %d coins" % cost,"RefreshMasterMarket",Rect2(236,646,270,50),func(): app.act("refresh_market",[],data.revision))
		refresh.disabled=data.cash < cost
		if page_count > 1:
			Lobby.action(app,app.screen,"Previous","MasterMarketPrevious",Rect2(532,646,132,50),func(): app.market_offer_page-=1; app.render("master_market")).disabled=app.market_offer_page == 0
			Lobby.action(app,app.screen,"Next","MasterMarketNext",Rect2(688,646,132,50),func(): app.market_offer_page+=1; app.render("master_market")).disabled=app.market_offer_page == page_count-1
	else:
		var cost := 0 if Rules.Legacy.available(data,"scouting3") else 45
		var reroll: Button=Lobby.action(app,app.screen,"Reroll  %d coins" % cost,"RerollMasterPack",Rect2(32,646,260,50),func(): app.act("reroll_pack",[],data.revision))
		reroll.disabled=data.cash < cost or data.step == "opening_recruit"
		var voucher: Button=Lobby.action(app,app.screen,"Take 25 coins","MasterVoucher",Rect2(326,646,248,50),func(): app.confirm("Trade this pack?","All four candidates leave. Receive 25 coins.",func(): app.act("skip_recruit",[],data.revision)))
		voucher.disabled=data.step == "opening_recruit"
		var reveal := PackReveal.new()
		reveal.tiles=tiles
		reveal.reduced=app.preferences.data.motion
		reveal.audio=app.audio
		reveal.position=Vector2(0,0); reveal.size=Vector2(1280,630)
		app.screen.add_child(reveal)
		var focus_id: String=app.pending_pack_focus
		app.pending_pack_focus=""
		reveal.revealed.connect(func(skipped: bool): if not skipped: app.pack_walkout(focus_id))

static func training(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	heading(app,"TRAINING","+4 to one attribute. Two sessions per player each run. Maximum 120. Cost: 140 coins.")
	var player := OptionButton.new()
	player.name="TrainingPlayer"; player.position=Vector2(34,226); player.size=Vector2(570,50)
	for card in data.plan.cards: player.add_item(card.display_name+"  "+card.primary_role)
	app.screen.add_child(player)
	var stat := OptionButton.new()
	stat.name="TrainingStat"; stat.position=Vector2(636,226); stat.size=Vector2(300,50)
	app.screen.add_child(stat)
	var preview: Label=Lobby.copy(app,app.screen,"",Rect2(34,310,1150,100),26,"Score")
	var update_stat := func():
		var card: Dictionary=data.plan.cards[player.selected]
		var key: String=stat.get_item_text(stat.selected)
		var values: Dictionary=card.keeper_attributes if key in Rules.Economy.Card.KEEPING else card.attributes
		preview.text="%s\n%s  %d -> %d    %d / 2 sessions used" % [card.display_name,key,values[key],mini(120,values[key]+4),data.training.filter(func(row): return row.card_id == card.card_id).size()]
	var update := func():
		var card: Dictionary=data.plan.cards[player.selected]
		stat.clear()
		for key in Rules.Economy.Card.KEEPING if card.primary_role == "GK" else Rules.Economy.Card.STATS: stat.add_item(key)
		update_stat.call()
	player.item_selected.connect(func(_index): update.call())
	stat.item_selected.connect(func(_index): update_stat.call())
	update.call()
	Lobby.action(app,app.screen,"Back","TrainingBack",Rect2(32,646,172,50),func(): app.render("master_scout"))
	var price: int=Rules.training_quote(data).cost
	Lobby.action(app,app.screen,"Train  %d coins" % price,"TrainMasterPlayer",Rect2(840,646,408,50),func(): app.act("train",[data.plan.cards[player.selected].card_id,stat.get_item_text(stat.selected)],data.revision),true).disabled=data.cash < price
	if Rules.Legacy.available(data,"academy4"): Lobby.action(app,app.screen,"Use free training","FreeMasterTraining",Rect2(636,470,570,50),func(): app.act("train_free",[data.plan.cards[player.selected].card_id,stat.get_item_text(stat.selected)],data.revision))
	Lobby.action(app,app.screen,"Release benched player","ReleaseMasterPlayer",Rect2(34,470,570,50),func():
		var id: String=data.plan.cards[player.selected].card_id
		app.confirm("Release this player?","This player leaves for the rest of this run. Return: %d coins." % Rules.Economy.release_value(data,app.library,id),func(): app.act("release",[id],data.revision)))

static func opportunities(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	heading(app,"LEGACY OPTIONS","Optional, bounded opportunities. Decline by returning to Scouting.")
	var row := 0
	for entry in [["tactics4","pivot",[],"Free Act II Manager swap"],["fortune1","fortune_advance",[],"Take 40 now; next winning reward -60"],["fortune2","fortune_double",[],"Next reward: double on win, zero on loss"],["fortune4","fortune_world",["loan"],"Take 120 now; next loss costs two defeats"],["fortune4","fortune_world",["wager"],"Stake 100 now; next win returns 200"]]:
		if not Rules.Legacy.available(data,entry[0]): continue
		if entry[0] == "tactics4" and Rules.Balance.act(data.node) != 2: continue
		if entry[0] == "fortune4" and data.node != 8: continue
		Lobby.action(app,app.screen,entry[3],"LegacyOpportunity"+str(row),Rect2(34,214+row*70,1212,54),func(): app.confirm("Use this opportunity?",entry[3],func(): app.act(entry[1],entry[2],data.revision)))
		row+=1
	if row == 0: Lobby.copy(app,app.screen,"No unused Legacy opportunity is available at this node.",Rect2(34,250,1190,60),22)
	Lobby.action(app,app.screen,"Back","LegacyOptionsBack",Rect2(32,646,172,50),func(): app.render("master_scout"))

static func route_choice(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	heading(app,"CHOOSE YOUR ROUTE","Different opponent. Same scheduled node and rewards.")
	var options := Rules.routes(data,app.library)
	var width: float=(1216.0-16*(options.size()-1))/options.size()
	for index in options.size():
		var fixture: Dictionary=options[index]
		var club: Dictionary=app.library.clubs[fixture.club_id]
		var panel: Control=Lobby.panel(app.screen,Rect2(32+index*(width+16),212,width,380))
		var crest: TextureRect=Parts.badge(panel,app.library,club.id,96)
		crest.position=Vector2(width/2-48,24)
		var name_label: Label=Lobby.copy(app,panel,club.name,Rect2(24,138,width-48,46),28,"Heading")
		name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; name_label.size=Vector2(width-48,60)
		var tactics: Label=Lobby.copy(app,panel,"%d OVR   %s\n%s / %s" % [roundi(app.library.xi_rating(app.library.opponent_plan(fixture.variant_id))),club.formation,club.attack.capitalize(),club.defence.capitalize()],Rect2(24,208,width-48,70),20)
		tactics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; tactics.size=Vector2(width-48,70)
		Lobby.action(app,panel,"Take this route","ChooseMasterRoute"+str(index),Rect2(24,304,width-48,50),func(): app.act("choose_route",[index],data.revision),true)

static func manager_choice(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	heading(app,"MANAGER CARD","Choose one run tactic. Three equipped slots. Effects apply to real football actions.")
	var replacement := OptionButton.new()
	replacement.name="ManagerReplacement"
	replacement.position=Vector2(34,568); replacement.size=Vector2(762,44)
	replacement.add_item("Choose a Manager Card to replace" if data.managers.size() == 3 else "An empty slot is available")
	for id in data.managers: replacement.add_item(Rules.Managers.DEFINITIONS[id].name)
	replacement.disabled=data.managers.size() < 3
	app.screen.add_child(replacement)
	var pages: int=ceili(data.manager_offer.size()/3.0)
	app.manager_offer_page=clampi(app.manager_offer_page,0,pages-1)
	var first: int=app.manager_offer_page*3
	for index in range(first,mini(first+3,data.manager_offer.size())):
		var id: String=data.manager_offer[index]
		var definition: Dictionary=Rules.Managers.DEFINITIONS[id]
		var panel: Control=Lobby.panel(app.screen,Rect2(32+(index-first)*410,202,394,340))
		var icon := TextureRect.new()
		icon.texture=preload("res://ui/ability_icons.gd").texture(definition.icon)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.position=Vector2(24,22); icon.size=Vector2(48,48); icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
		Lobby.copy(app,panel,definition.name,Rect2(24,82,346,40),26,"Heading")
		var effect: Label=Lobby.copy(app,panel,"",Rect2(24,130,346,148),18)
		effect.name="ManagerEffect"+str(index)
		effect.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		effect.size=Vector2(346,148)
		effect.clip_text=true
		effect.text=definition.effect+"\n\nCounter: "+definition.counter
		Lobby.action(app,panel,"Equip","ChooseMasterManager"+str(index),Rect2(24,276,346,46),func():
			if data.managers.size() == 3 and replacement.selected == 0: app.message("Choose which equipped Manager Card leaves first."); return
			app.act("choose_manager",[id,data.managers[replacement.selected-1] if data.managers.size() == 3 else ""],data.revision),true)
	if pages > 1:
		Lobby.action(app,app.screen,"Previous","ManagerChoicesPrevious",Rect2(840,568,192,46),func(): app.manager_offer_page-=1; app.render("master_manager")).disabled=app.manager_offer_page == 0
		Lobby.action(app,app.screen,"Next","ManagerChoicesNext",Rect2(1056,568,192,46),func(): app.manager_offer_page+=1; app.render("master_manager")).disabled=app.manager_offer_page == pages-1
	if Rules.Legacy.available(data,"chemistry2"): Lobby.action(app,app.screen,"Use free redraw","RedrawManagerChoices",Rect2(32,646,360,50),func(): app.act("reroll_manager",[],data.revision))
	Lobby.action(app,app.screen,"Keep current tactics","SkipMasterManager",Rect2(840,646,408,50),func(): app.act("skip_manager",[],data.revision))

static func result(app) -> void:
	var data: Dictionary=app.session.controller.snapshot()
	var terminal: bool=data.step in ["won","lost","abandoned"]
	var title := "WORLD CHAMPIONS" if data.step == "won" else "RUN ENDED" if terminal else "FULL TIME"
	heading(app,title,"World Stage Invitational: mixed-nationality squads compete from local clubs to the world final." if data.step == "won" else "")
	if not data.ledger.is_empty():
		var entry: Dictionary=data.ledger.back()
		var report: Dictionary=entry.report
		Lobby.copy(app,app.screen,"%d  -  %d" % report.scores,Rect2(32,216,460,110),80,"Score")
		var decision: String="VICTORY" if report.winner == 0 else "DEFEAT"
		if not report.get("penalties",[]).is_empty(): decision+="  (PENS %d-%d)" % report.penalties
		Lobby.copy(app,app.screen,"%s\n+%d coins" % [decision,entry.prize],Rect2(34,344,560,90),28,"Heading")
		Lobby.copy(app,app.screen,"SHOTS  %d - %d\nON TARGET  %d - %d\nPASSES  %d - %d" % [report.shots[0],report.shots[1],report.on_target[0],report.on_target[1],report.completed[0],report.completed[1]],Rect2(34,446,560,92),20,"Score")
		var summary: Dictionary=report.get("impact",{})
		var lines := "ACTUAL MATCH IMPACT\n"
		for row in summary.get("players",[]).slice(0,5): lines+="%s: %d activated, %d confirmed successes\n" % [row.name,row.activations,row.successes]
		for id in summary.get("manager_actions",{}): lines+="%s: %d modified actions\n" % [Rules.Managers.DEFINITIONS[id].name,summary.manager_actions[id]]
		Lobby.copy(app,app.screen,lines,Rect2(640,220,608,340),20)
	Lobby.copy(app,app.screen,"%d / 12 nodes    %d wins    %d / 3 defeats" % [data.node,data.wins,data.defeats],Rect2(34,560,1150,44),24,"Score")
	Lobby.action(app,app.screen,"Main menu" if terminal else "Continue","MasterResultContinue",Rect2(840,646,408,50),func(): app.render("main") if terminal else app.act("continue_result",[],data.revision),true)

class PackReveal:
	extends Control
	signal revealed(skipped: bool)
	var tiles: Array=[]
	var audio: Node
	var reduced := false
	var age := 0.0
	var shown := 0
	var skip: Button
	var finished := false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		for tile in tiles: tile.modulate.a=0; tile.mouse_filter=Control.MOUSE_FILTER_IGNORE; tile.focus_mode=Control.FOCUS_NONE
		skip=Button.new(); skip.text="Reveal all"; skip.name="RevealAllMasterPack"; skip.position=Vector2(1010,142); skip.size=Vector2(238,44)
		add_child(skip); skip.pressed.connect(func(): finish(true))
		if reduced: finish(true)
	func _process(delta: float) -> void:
		age+=delta
		for index in tiles.size():
			var t := clampf((age-0.5-index*0.8)/0.45,0,1)
			tiles[index].modulate.a=t
			tiles[index].scale=Vector2.ONE*(0.96+0.04*t)
			if t > 0 and shown <= index:
				shown=index+1
				if is_instance_valid(audio): audio.play("place")
		if age >= 4.2: finish(false)
	func finish(skipped: bool = false) -> void:
		if finished: return
		finished=true
		for tile in tiles: tile.modulate.a=1; tile.scale=Vector2.ONE; tile.mouse_filter=Control.MOUSE_FILTER_STOP; tile.focus_mode=Control.FOCUS_ALL
		set_process(false); skip.queue_free()
		Parts.focus_loop(get_parent())
		revealed.emit(skipped)
