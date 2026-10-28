extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Profile = preload("res://persistence/profile.gd")
const CHAPTERS := ["GRASSROOTS","ELITE LEAGUE","WORLD INVITATIONAL"]
const PRINCIPLES := {"short_combinations":"+3 PAS on ground passes in defensive and middle thirds.","wide_service":"+3 PAS on crosses.","counter_runners":"+3 PAC for two active seconds after controlled recovery.","first_pressure":"+3 DEF on attacking-third standing tackles with High press.","set_piece_preparation":"+3 SHO on direct free kicks and immediate corner headers.","bench_impact":"+3 PHY for substitutes for the rest of the match."}

static func frame(app) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	app.screen.add_child(margin)
	var outer := Parts.column(margin,12)
	var header := Parts.row(outer)
	var data: Dictionary = app.session.controller.snapshot()
	if not data.is_empty() and app.page not in ["origin","records","discovered"]:
		flag(header,data.origin)
		app.text(header,app.library.countries[data.origin].name.to_upper(),29,"Team")
		if app.page != "offer":
			app.text(header,"WINS %d/12" % data.wins,22,"Score")
			app.text(header,"DEFEATS %d/3" % data.defeats,22,"Score")
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
	var menu: Button = app.button(header,"Back" if app.page in ["origin","records","discovered"] else "       Menu","PageMenu",func(): app.render("main") if app.page in ["origin","records","discovered"] else app.menu())
	if app.page not in ["origin","records","discovered"]:
		menu.custom_minimum_size.x = 115
		var glyph := Parts.Mark.new()
		glyph.size = Vector2(30,28)
		glyph.position = Vector2(8,9)
		menu.add_child(glyph)
	outer.add_child(HSeparator.new())
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
	var menu_scroll := ScrollContainer.new()
	menu_scroll.position = Vector2(32,24)
	menu_scroll.size = Vector2(app.size.x*0.29,app.size.y-48)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	app.screen.add_child(menu_scroll)
	var left := Parts.column(menu_scroll,6)
	var title: Label = app.text(left,"ELEVEN\nAGAIN",112,"Heading")
	title.add_theme_font_size_override("font_size",clampi(int(menu_scroll.size.x/(3.7*app.ui_scale())),80,140))
	title.add_theme_constant_override("line_spacing",-16)
	var preview: Dictionary = app.session.preview()
	if not preview.is_empty():
		var identity := Parts.row(left)
		flag(identity,preview.origin)
		app.text(identity,app.library.countries[preview.origin].name.to_upper(),25,"Team")
		var progress := Parts.row(left,10)
		var counts: Label = app.text(progress,"%d WINS   %d/3 DEFEATS" % [preview.wins,preview.defeats],16,"Section")
		counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pips(progress,preview.defeats)
		app.button(left,"Continue run","ContinueRun",func(): if app.session.reload().ok: app.route(),true)
	app.button(left,"New run","NewRun",func(): app.render("origin"),preview.is_empty())
	app.button(left,"Player archive","PublicArchive",func():
		var archive = load("res://ui/player_archive.gd").new()
		archive.ui_scale = app.ui_scale()
		archive.reduced_motion = app.preferences.data.motion
		app.open_modal(archive)
		archive.closed.connect(func(): app.modal=null))
	var collection := Parts.row(left,8)
	app.button(collection,"Discovered","Discovered",func(): app.render("discovered"))
	app.button(collection,"Records","Records",func(): app.render("records"))
	left.add_child(HSeparator.new())
	app.button(left,"Settings","MainSettings",app.settings)
	app.button(left,"Quit","QuitGame",func(): app.get_tree().quit())
	for child in left.get_children():
		if child is Button: child.custom_minimum_size.y = 38
	var paper := Parts.Paper.new()
	paper.position = Vector2(app.size.x*0.345,48)
	paper.size = Vector2(app.size.x*0.39,app.size.y-96)
	app.screen.add_child(paper)
	var content := Parts.column(paper,14)
	if preview.is_empty():
		app.text(content,"THE FIXTURE BOOK",36,"Heading",Parts.INK)
		app.text(content,"No active run.\nChoose an origin to begin.",22,"Label",Parts.INK)
		content.add_child(HSeparator.new())
		app.text(content,"Twelve wins.\nThree defeats.\nOne new eleven.",30,"Score",Parts.INK)
	else:
		app.text(content,CHAPTERS[preview.chapter-1],34,"Heading",Parts.INK)
		fixture_rows(app,content,preview.fixtures,preview.ledger,preview.wins)
		app.text(content,"NEXT STEP\n"+preview.step.replace("_"," ").capitalize(),17,"BodyStrong",Parts.INK)
		for index in preview.best_cards.size():
			var width: float = clampf(app.size.x*0.19,240,310)
			var card := Parts.card(app.screen,app.library,preview.best_cards[index],width,app.ui_scale(),true,true)
			card.position = Vector2(app.size.x-width-28-index*12,40+index*(app.size.y-1.4*width-80))
			card.rotation = 0.025 if index == 0 else -0.025
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

static func origins(app, outer: Node) -> void:
	app.text(outer,"CHOOSE YOUR ORIGIN",48,"Heading")
	app.text(outer,"16 players   $8m   All nationalities can be recruited",18)
	var row := Parts.row(outer,24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var options := Parts.column(row,6)
	options.size_flags_horizontal = Control.SIZE_FILL
	options.custom_minimum_size.x = 260
	for country in app.library.countries.values():
		app.button(options,country.name,country.id,func(): app.origin_selection=country.id; app.render("origin"),app.origin_selection == country.id)
	var plan: Resource = app.library.country_plan(app.origin_selection)
	var paper := Parts.Paper.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(paper)
	var details := Parts.column(paper,8)
	app.text(details,app.library.countries[app.origin_selection].name.to_upper(),38,"Heading",Parts.INK)
	app.text(details,"4-3-3  Starting XI %.1f OVR" % app.library.xi_rating(plan),22,"Score",Parts.INK)
	var columns := Parts.row(details,24)
	for group in [plan.cards.slice(0,8),plan.cards.slice(8,16)]:
		var list := Parts.column(columns,3)
		for card in group: app.text(list,"%s  %s" % [card.primary_role,card.display_name],16,"Label",Parts.INK)
	app.button(outer,"Start run","StartRun",func(): app.start_origin(app.origin_selection),true)

static func board(app, outer: Node) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	var chapter := mini(3,int(data.wins/4.0)+1)
	app.text(outer,CHAPTERS[chapter-1],48,"Heading")
	var row := Parts.row(outer,28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := Parts.Paper.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(paper)
	var itinerary := Parts.column(paper,18)
	var stages := Parts.row(itinerary,12)
	stages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for fixture in data.fixtures.slice((chapter-1)*4,chapter*4):
		var club: Dictionary = app.library.clubs[fixture.club_id]
		var reveal: bool = fixture.stage <= data.wins+1 or club.is_boss
		var node := PanelContainer.new()
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var border := StyleBoxFlat.new()
		border.bg_color = Color(0,0,0,0)
		border.border_color = Parts.BRASS if fixture.stage == data.wins+1 else Color("879084")
		border.set_border_width_all(2 if fixture.stage == data.wins+1 else 1)
		for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: border.set_content_margin(edge,10)
		node.add_theme_stylebox_override("panel",border)
		stages.add_child(node)
		var tile := Parts.column(node,12)
		app.text(tile,"STAGE %d" % fixture.stage,17,"Section",Parts.INK)
		if reveal: Parts.badge(tile,app.library,club.id,80)
		else:
			var blank := Control.new()
			blank.custom_minimum_size.y = 80
			tile.add_child(blank)
		var name: Label = app.text(tile,club.name.to_upper() if reveal else "OPPONENT\nUNKNOWN",21,"Team",Parts.INK)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name.custom_minimum_size.y = 64
		var attempts: Array = data.ledger.filter(func(item): return item.stage == fixture.stage)
		var caption := "NEXT" if fixture.stage == data.wins+1 else ("FINAL" if club.is_boss else "UPCOMING")
		if not attempts.is_empty(): caption = "%d – %d\n%s" % [attempts.back().report.scores[0],attempts.back().report.scores[1],"WIN" if attempts.back().report.winner == 0 else "DEFEAT"]
		app.text(tile,caption,24,"Score",Parts.INK)
	var next: Dictionary = app.library.rules.stages[data.wins]
	var reward := "Recruit" if next.recruit else "Coaching choice" if next.coaching else "Championship"
	if next.market != null: reward += " and Market "+str(int(next.market))
	app.text(itinerary,"AFTER VICTORY  "+reward,18,"BodyStrong",Parts.INK)
	var scout_column := Parts.column(row,12)
	scout_column.size_flags_horizontal = Control.SIZE_FILL
	scout_column.custom_minimum_size.x = minf(350,app.size.x*0.29)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scout_column.add_child(scroll)
	var scout := Parts.column(scroll,12)
	var club: Dictionary = app.library.clubs[data.fixtures[data.wins].club_id]
	Parts.badge(scout,app.library,club.id,104)
	app.text(scout,club.name.to_upper(),32,"Team")
	scout.add_child(HSeparator.new())
	app.text(scout,"%.1f OVR   %s" % [app.library.xi_rating(app.library.opponent_plan(data.fixtures[data.wins].variant_id)),club.formation],26,"Score")
	app.text(scout,club.attack.capitalize()+" passing\n"+club.defence.replace("_"," ").capitalize(),19)
	app.text(scout,club.scout_threat+"\n"+club.scout_response,17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.button(scout_column,"Prepare match","PrepareCampaign",app.prepare,true)
	if not data.market.is_empty() and data.market.open: app.button(scout_column,"Return to market","ReopenMarket",func(): app.act("reopen_market",[],data.revision))

static func coaching(app, outer: Node) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	app.text(outer,"CHOOSE A PRINCIPLE",48,"Heading")
	app.text(outer,"Contextual +3 bonuses share the +6 cap with traits. Base cards stay unchanged.",18)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	outer.add_child(scroll)
	var choices := Parts.column(scroll,14)
	for id in data.coaching:
		var box := Parts.column(choices,3)
		var option: Button = app.button(box,id.replace("_"," ").capitalize(),id,func(): app.coach_selection=id; app.render("coaching"),app.coach_selection == id)
		option.toggle_mode = true
		option.set_pressed_no_signal(app.coach_selection == id)
		app.text(box,PRINCIPLES[id],18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(HSeparator.new())
	app.button(outer,"Confirm principle","ConfirmPrinciple",func(): app.act("choose_principle",[app.coach_selection],data.revision),true).disabled = app.coach_selection not in data.coaching

static func result(app, outer: Node, terminal: bool) -> void:
	var data: Dictionary = app.session.controller.snapshot()
	app.text(outer,{"won":"CHAMPIONS","lost":"RUN COMPLETE","abandoned":"RUN ABANDONED"}.get(data.step,"MATCH RESULT"),56,"Heading")
	var paper := Parts.Paper.new()
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(paper)
	var box := Parts.column(paper,12)
	if not data.ledger.is_empty():
		var attempt: Dictionary = data.ledger.back()
		app.text(box,"%s   %d – %d   %s" % [app.library.countries[data.origin].name,attempt.report.scores[0],attempt.report.scores[1],app.library.clubs[attempt.fixture.club_id].name],32,"Team",Parts.INK)
		if not attempt.report.penalties.is_empty(): app.text(box,"Penalties %d – %d" % attempt.report.penalties,22,"Score",Parts.INK)
		app.text(box,"Prize "+app.money(attempt.prize) if attempt.prize > 0 else "One defeat. Your opponent, roster and funds are retained.",22,"Score",Parts.INK)
		app.text(box,"Shots %d – %d     On target %d – %d\nPasses completed %d – %d" % (attempt.report.shots+attempt.report.on_target+attempt.report.completed),20,"Label",Parts.INK)
	if terminal: app.text(box,"%d wins   %d defeats\nPeak valid XI %.2f OVR\nTotal prizes %s" % [data.wins,data.defeats,data.peak_xi.total/11.0,app.money(data.earnings)],28,"Score",Parts.INK)
	app.button(outer,"Return to main menu" if terminal else "Continue","ContinueCampaignResult",func(): app.render("main") if terminal else app.act("continue_result",[],data.revision),true)

static func recovery(app) -> void:
	var outer := frame(app)
	app.text(outer,"SAVE RECOVERY",48,"Heading")
	app.text(outer,app.session.last_error+"\nOriginal save files have been retained. Recover a valid file or backup, then retry.",21).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.button(outer,"Retry recovery","RetryRecovery",func(): app.session.reload(); app.render("main"),true)
	app.button(outer,"Open save folder","OpenSaveFolder",func(): OS.shell_open(app.session.store.directory))
	app.button(outer,"Quit","RecoveryQuit",func(): app.get_tree().quit())
