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
	preload("res://ui/campaign_lobby.gd").main(app)

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
	app.text(outer,"Origin",34,"Heading")
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
	app.text(info,"16 players   $8m   %d OVR" % ceili(app.library.xi_rating(plan)),18)
	footer(app,"","Start run","StartRun",func(): app.start_origin(app.origin_selection))

static func board(app, outer: Node) -> void:
	preload("res://ui/campaign_lobby.gd").board(app,outer)

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
		app.text(summary,"Peak XI %d OVR" % ceili(data.peak_xi.total/11.0),26,"Team")
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
