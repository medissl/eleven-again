extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Profile = preload("res://persistence/profile.gd")
const CHAPTERS := ["GRASSROOTS","ELITE LEAGUE","WORLD INVITATIONAL"]
const PRINCIPLES := {"short_combinations":"+3 PAS on ground passes in defensive and middle thirds.","wide_service":"+3 PAS on crosses.","counter_runners":"+3 PAC for two active seconds after controlled recovery.","first_pressure":"+3 DEF on attacking-third standing tackles with High press.","set_piece_preparation":"+3 SHO on direct free kicks and immediate corner headers.","bench_impact":"+3 PHY for substitutes for the rest of the match."}

static func frame(app) -> VBoxContainer:
	var outer := Parts.column(app.screen,16)
	outer.position = Vector2(32,100)
	outer.size = Vector2(1216,596)
	var header := Parts.row(app.screen,16)
	header.position = Vector2(32,16)
	header.size = Vector2(1216,44)
	var rule := HSeparator.new()
	rule.position = Vector2(32,76)
	rule.size.x = 1216
	app.screen.add_child(rule)
	var data: Dictionary = app.session.controller.snapshot()
	if not data.is_empty() and app.page not in ["origin","records","collection"]:
		flag(header,data.origin)
		app.text(header,app.library.countries[data.origin].name.to_upper(),23,"Team")
		if app.page != "offer":
			app.text(header,"%d / 12 wins" % data.wins,16,"Label")
			app.text(header,"Defeats %d/3" % data.defeats,16,"Label")
			pips(header,data.defeats)
		else:
			var space := Control.new()
			space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header.add_child(space)
		app.text(header,app.money(data.cash),28,"Score")
		if app.page == "offer" and data.step == "market": app.text(header,"SIGNINGS %d/2" % data.market.purchased.size(),22,"Score")
	else: app.text(header,"ELEVEN AGAIN",30,"Team")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_FILL if app.page == "offer" else Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var menu: Button = app.button(header,"Back" if app.page in ["origin","records","collection"] else "Menu","PageMenu",func(): app.render("main") if app.page in ["origin","records","collection"] else app.menu())
	if app.page not in ["origin","records","collection"]:
		menu.custom_minimum_size.x = 115
		menu.icon = load("res://assets/ui/matchday/icons/menu.svg")
		menu.add_theme_constant_override("icon_max_width",24)
	return outer

static func flag(parent: Node, code: String) -> void:
	var node := Parts.Mark.new()
	node.kind = "flag"
	node.country = code
	node.custom_minimum_size = Vector2(44,28)
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(node)

static func pips(parent: Node, defeats: int) -> void:
	var node := Parts.Mark.new()
	node.kind = "pips"
	node.used = defeats
	node.custom_minimum_size = Vector2(76,30)
	parent.add_child(node)

static func main(app) -> void:
	var preview: Dictionary = app.session.preview()
	var logo := TextureRect.new()
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.texture = load("res://assets/ui/matchday/art/wordmark.png")
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(32,58)
	logo.size = Vector2(414,207)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.screen.add_child(logo)
	var actions := [["Continue run","ContinueRun",func(): if app.session.reload().ok: app.route()]] if not preview.is_empty() else []
	actions.append_array([["New run","NewRun",func(): app.render("origin")],["Collection","Collection",func(): app.render("collection")],["Records","Records",func(): app.render("records")],["Settings","MainSettings",app.settings],["Quit","QuitGame",func(): app.get_tree().quit()]])
	for index in actions.size():
		var action: Array = actions[index]
		var node: Button = app.button(app.screen,action[0],action[1],action[2],index == 0)
		node.position = Vector2(48,298+index*56)
		node.size = Vector2(346,44)
		node.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if index > 0: node.theme_type_variation = "Quiet"
	if preview.is_empty():
		var cover := TextureRect.new()
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.texture = load("res://assets/ui/matchday/art/tactical-cover.png")
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.position = Vector2(558,48)
		cover.size = Vector2(600,600)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		app.screen.add_child(cover)
		var caption: Label = app.text(app.screen,"Build an eleven. Make another run.",18,"Label",Color("A5B09F"))
		caption.position = Vector2(730,650)
	else:
		app.text(app.screen,"YOUR RUN",16,"Section").position = Vector2(488,66)
		var identity := Parts.row(app.screen)
		identity.position = Vector2(488,110)
		flag(identity,preview.origin)
		app.text(identity,app.library.countries[preview.origin].name,30,"Heading")
		var progress := Parts.row(app.screen)
		progress.position = Vector2(488,154)
		app.text(progress,"%d wins  %s" % [preview.wins,app.money(preview.cash)],18)
		pips(progress,preview.defeats)
		var paper := Parts.Paper.new()
		paper.position = Vector2(488,206)
		paper.size = Vector2(438,420)
		app.screen.add_child(paper)
		var content := Parts.column(paper,6)
		app.text(content,CHAPTERS[preview.chapter-1],26,"Heading",Parts.INK)
		fixture_rows(app,content,preview.fixtures,preview.ledger,preview.wins)
		app.text(content,"Next: "+preview.step.replace("_"," ").capitalize(),16,"Label",Parts.INK)
		for index in preview.best_cards.size():
			var card := Parts.card(app.screen,app.library,preview.best_cards[index],200,1.0,true,true)
			card.position = Vector2(1008,90+index*312)
			card.pressed.connect(func(): app.inspect(preview.best_cards[index]))

static func fixture_rows(app, parent: Node, fixtures: Array, ledger: Array, wins: int) -> void:
	for fixture in fixtures:
		var club: Dictionary = app.library.clubs[fixture.club_id]
		var reveal: bool = fixture.stage <= wins+1 or club.is_boss
		var row := Parts.row(parent,12)
		app.text(row,str(fixture.stage),23,"Score",Parts.INK).custom_minimum_size.x = 28
		if reveal: Parts.badge(row,app.library,club.id,48)
		var box := Parts.column(row,2)
		app.text(box,club.name.to_upper() if reveal else "UNDISCOVERED OPPONENT",21,"Team",Parts.INK)
		var attempts: Array = ledger.filter(func(item): return item.stage == fixture.stage)
		var line := "Final" if club.is_boss else "Upcoming"
		if fixture.stage == wins+1: line = "Next opponent"
		if not attempts.is_empty():
			var last: Dictionary = attempts.back().report
			line = "%d – %d  %s" % [last.scores[0],last.scores[1],"WIN" if last.winner == 0 else "DEFEAT"]
			if not last.penalties.is_empty(): line += "  Penalties %d–%d" % last.penalties
		app.text(box,line,18,"Label",Parts.INK)
		parent.add_child(HSeparator.new())

static func region(app, rect: Rect2, gap: int = 12) -> VBoxContainer:
	var node := Parts.column(app.screen,gap)
	node.position = rect.position
	node.size = rect.size
	return node

static func footer(app, caption: String, primary: String, id: String, action: Callable, back: String = "Back", go_back: Callable = Callable()) -> void:
	var rule := HSeparator.new()
	rule.position = Vector2(32,632)
	rule.size.x = 1216
	app.screen.add_child(rule)
	if not caption.is_empty():
		var hint: Label = app.text(app.screen,caption,16,"Label",Color("A5B09F"))
		hint.position = Vector2(224,660)
		hint.size = Vector2(660,30)
		hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var secondary: Button = app.button(app.screen,back,"PageBack",go_back if go_back.is_valid() else func(): app.render("main"))
	secondary.theme_type_variation = "Quiet"
	secondary.position = Vector2(32,652)
	secondary.size = Vector2(172,44)
	var next: Button = app.button(app.screen,primary,id,action,true)
	next.position = Vector2(1008,652)
	next.size = Vector2(240,44)

static func origins(app, outer: Node) -> void:
	app.text(outer,"Choose your origin",34,"Heading")
	app.text(outer,"A starting eleven. No nationality bonuses. Recruit from every country.",18,"Label",Color("A5B09F"))
	var index := 0
	for country in app.library.countries.values():
		var option: Button = app.button(app.screen,country.name,country.id,func(): app.origin_selection=country.id; app.render("origin"),app.origin_selection == country.id)
		option.position = Vector2(32+(index%3)*228,218+(index/3)*170)
		option.size = Vector2(212,148)
		option.icon = load("res://assets/ui/matchday/flags/"+country.id+".svg")
		option.add_theme_constant_override("icon_max_width",36)
		option.add_theme_constant_override("h_separation",8)
		option.add_theme_font_size_override("font_size",18)
		index += 1
	var plan: Resource = app.library.country_plan(app.origin_selection)
	var preview = load("res://ui/formation_preview.gd").new()
	preview.plan = plan
	preview.position = Vector2(736,210)
	preview.size = Vector2(512,344)
	app.screen.add_child(preview)
	var info := region(app,Rect2(752,564,480,52),4)
	app.text(info,app.library.countries[app.origin_selection].name+"   "+plan.formation,23,"Team")
	app.text(info,"16 players   $8m   Starting XI %.1f OVR" % app.library.xi_rating(plan),18)
	footer(app,"Your origin changes the starting squad.","Start run","StartRun",func(): app.start_origin(app.origin_selection))

static func board(app, outer: Node) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	var chapter := mini(3,int(data.wins/4.0)+1)
	app.text(outer,CHAPTERS[chapter-1].capitalize(),34,"Heading")
	app.text(outer,"Four fixtures. One chapter final.",18,"Label",Color("A5B09F"))
	var index := 0
	for fixture in data.fixtures.slice((chapter-1)*4,chapter*4):
		var club: Dictionary = app.library.clubs[fixture.club_id]
		var reveal: bool = fixture.stage <= data.wins+1 or club.is_boss
		var panel := PanelContainer.new()
		panel.position = Vector2(32+index*228,214)
		panel.size = Vector2(212,356)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("26392C") if fixture.stage == data.wins+1 else Color("1B2921")
		style.border_color = Parts.BRASS if fixture.stage == data.wins+1 else Color("3B493B")
		style.set_border_width_all(2 if fixture.stage == data.wins+1 else 1)
		for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(edge,20)
		panel.add_theme_stylebox_override("panel",style)
		app.screen.add_child(panel)
		var tile := Parts.column(panel,18)
		app.text(tile,"FIXTURE %d" % fixture.stage,16,"BodyStrong",Color("A5B09F"))
		if reveal: Parts.badge(tile,app.library,club.id,80)
		else:
			var unknown := TextureRect.new()
			unknown.texture = load("res://assets/ui/matchday/icons/lock.svg")
			unknown.custom_minimum_size = Vector2(80,80)
			unknown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			unknown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tile.add_child(unknown)
		var name: Label = app.text(tile,club.name if reveal else "Undiscovered",23,"Team")
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name.custom_minimum_size.y = 76
		var attempts: Array = data.ledger.filter(func(item): return item.stage == fixture.stage)
		var caption := "Next match" if fixture.stage == data.wins+1 else "Chapter final" if club.is_boss else "Not yet revealed"
		if not attempts.is_empty(): caption = "%d – %d  %s" % [attempts.back().report.scores[0],attempts.back().report.scores[1],"Won" if attempts.back().report.winner == 0 else "Defeat"]
		app.text(tile,caption,16,"BodyStrong",Parts.BRASS if fixture.stage == data.wins+1 else Color("A5B09F"))
		index += 1
	var scout := region(app,Rect2(968,236,256,334),18)
	var club: Dictionary = app.library.clubs[data.fixtures[data.wins].club_id]
	var name: Label = app.text(scout,club.name,28,"Heading")
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.text(scout,"%.1f OVR   %s" % [app.library.xi_rating(app.library.opponent_plan(data.fixtures[data.wins].variant_id)),club.formation],21,"BodyStrong")
	app.text(scout,club.attack.capitalize()+" passing",20)
	var threat: Label = app.text(scout,club.scout_threat,17,"Label",Color("A5B09F"))
	threat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	threat.tooltip_text = club.scout_response
	var stage: Dictionary = app.library.rules.stages[data.wins]
	var reward := "Recruitment" if stage.recruit else "Coaching choice" if stage.coaching else "Championship"
	if stage.market != null: reward += " and Market "+str(int(stage.market))
	footer(app,"After victory: "+reward,"Prepare match","PrepareCampaign",app.prepare,"Save and exit",app.save_and_exit)
	if not data.market.is_empty() and data.market.open:
		var reopen: Button = app.button(app.screen,"Return to market","ReopenMarket",func(): app.act("reopen_market",[],data.revision))
		reopen.position = Vector2(968,576)
		reopen.size = Vector2(256,44)

static func coaching(app, outer: Node) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	app.text(outer,"Choose a principle",34,"Heading")
	app.text(outer,"A precise team bonus. Base cards stay unchanged.",18,"Label",Color("A5B09F"))
	for index in data.coaching.size():
		var id: String = data.coaching[index]
		var panel := PanelContainer.new()
		panel.position = Vector2(32+index*412,248)
		panel.size = Vector2(392,304)
		panel.add_theme_stylebox_override("panel",preload("res://ui/matchday_theme.gd").box("panel-raised" if app.coach_selection == id else "panel"))
		app.screen.add_child(panel)
		var box := Parts.column(panel,20)
		var option: Button = app.button(box,id.replace("_"," ").capitalize(),id,func(): app.coach_selection=id; app.render("coaching"),app.coach_selection == id)
		option.custom_minimum_size.y = 76
		var effect: Label = app.text(box,PRINCIPLES[id],20)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var note: Label = app.text(box,"Contextual +3. Shares the +6 cap with signature traits.",16,"Label",Color("A5B09F"))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer(app,"Two principles per run.","Confirm principle","ConfirmPrinciple",func(): app.act("choose_principle",[app.coach_selection],data.revision))
	app.screen.find_child("ConfirmPrinciple",true,false).disabled = app.coach_selection not in data.coaching

static func result(app, outer: Node, terminal: bool) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	app.text(outer,{"won":"Champions","lost":"Run ended","abandoned":"Run abandoned"}.get(data.step,"Match result"),34,"Heading")
	if terminal:
		var artwork := TextureRect.new()
		artwork.texture = load("res://assets/ui/matchday/art/trophy-album.png")
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		artwork.position = Vector2(64,200)
		artwork.size = Vector2(480,384)
		app.screen.add_child(artwork)
		var summary := region(app,Rect2(640,248,560,310),24)
		app.text(summary,"%d wins   %d defeats" % [data.wins,data.defeats],36,"Score")
		app.text(summary,"Peak XI %.2f OVR" % (data.peak_xi.total/11.0),26,"Team")
		app.text(summary,"Total prizes "+app.money(data.earnings),22)
		app.text(summary,"Your collection and records carry forward.",18,"Label",Color("A5B09F"))
		footer(app,"Build another eleven.","New run","TerminalNewRun",func(): app.render("origin"),"Main menu",func(): app.render("main"))
		app.screen.find_child("PageBack",true,false).name = "ContinueCampaignResult"
		return
	var attempt: Dictionary = data.ledger.back()
	var result_box := region(app,Rect2(112,232,1056,330),24)
	var score_row := Parts.row(result_box,24)
	score_row.custom_minimum_size.y = 80
	var names: Array = [app.library.countries[data.origin].name,app.library.clubs[attempt.fixture.club_id].name]
	var kits: Array = Parts.match_kits(app.library,data.origin,app.library.clubs[attempt.fixture.club_id])
	var score_text := "%d – %d" % [attempt.report.scores[0],attempt.report.scores[1]]
	var score_width := maxf(160,Parts.ThemeData.get_font("font","Score").get_string_size(score_text,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x+8)
	for team in 2:
		var identity := Parts.row(score_row,14)
		identity.custom_minimum_size.x = (1056-score_width-48)/2
		identity.alignment = BoxContainer.ALIGNMENT_END if team == 0 else BoxContainer.ALIGNMENT_BEGIN
		identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var shirt = preload("res://ui/match_overlay.gd").Icon.new()
		shirt.kind = "kit"
		shirt.ink = kits[team]
		shirt.custom_minimum_size = Vector2(32,32)
		identity.add_child(shirt)
		var name: Label = app.text(identity,names[team].to_upper(),32,"Team")
		name.tooltip_text = names[team]
		if team == 0:
			var score: Label = app.text(score_row,score_text,48,"Score")
			score.custom_minimum_size.x = score_width
			score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not attempt.report.penalties.is_empty(): app.text(result_box,"Penalties %d – %d" % attempt.report.penalties,24,"Score")
	app.text(result_box,"Prize "+app.money(attempt.prize) if attempt.prize > 0 else "One defeat. Your opponent, roster and funds are retained.",24,"BodyStrong")
	app.text(result_box,"Shots %d – %d     On target %d – %d\nPasses completed %d – %d" % (attempt.report.shots+attempt.report.on_target+attempt.report.completed),20)
	footer(app,"Result recorded once.","Continue","ContinueCampaignResult",func(): app.act("continue_result",[],data.revision))

static func recovery(app) -> void:
	var box = app.panel("Save recovery",Rect2(328,132,624,456))
	app.text(box,app.session.last_error,19).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.text(box,"Original files are retained. Restore a valid file or backup before retrying.",18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.button(box,"Retry recovery","RetryRecovery",func(): app.session.reload(); app.render("main"),true)
	app.button(box,"Open save folder","OpenSaveFolder",func(): OS.shell_open(app.session.store.directory))
	app.button(box,"Quit","RecoveryQuit",func(): app.get_tree().quit())
	Parts.focus_loop(app.modal)
