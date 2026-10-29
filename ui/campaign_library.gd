extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Profile = preload("res://persistence/profile.gd")

static func build(app, outer: Node, _page: String) -> void:
	app.text(outer,"Run records",34,"Heading")
	var history := Profile.ranked(app.session.profile)
	if history.is_empty():
		var art := TextureRect.new()
		art.texture = load("res://assets/ui/matchday/art/trophy-album.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position = Vector2(132,242)
		art.size = Vector2(320,350)
		app.screen.add_child(art)
		var details: VBoxContainer = app.Screens.region(app,Rect2(540,254,640,364),24)
		app.text(details,"Your first run starts the story.",32,"Heading")
		app.text(details,"Completed runs and your strongest eleven appear here.",18,"Label",Color("A5B09F"))
		for pair in [["Completed runs","0"],["Best finish","—"],["Highest team OVR","—"]]:
			var row := Parts.row(details)
			app.text(row,pair[0],18).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			app.text(row,pair[1],23,"Score")
		app.button(details,"Start a run","RecordsStartRun",func(): app.render("origin"),true).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		return
	app.text(outer,"Your strongest elevens, kept after the final whistle.",18,"Label",Color("A5B09F"))
	var pages := ceili(history.size()/3.0)
	app.record_page = clampi(app.record_page,0,pages-1)
	for index in mini(3,history.size()-app.record_page*3):
		var record: Dictionary = history[app.record_page*3+index]
		var row := Parts.row(app.screen,24)
		row.position = Vector2(56,234+index*124)
		row.size = Vector2(1160,76)
		app.Screens.flag(row,record.origin)
		var identity := Parts.column(row,4)
		identity.custom_minimum_size.x = 360
		app.text(identity,app.library.countries[record.origin].name,27,"Team")
		app.text(identity,"Champions" if record.outcome == "won" else "%d wins   %d defeats" % [record.wins,record.defeats],17,"Label",Color("A5B09F"))
		app.text(row,"%.2f OVR" % (record.peak_xi.total/11.0),27,"Team").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		app.button(row,"View eleven","RecordXI_"+record.run_id,func(): app.record_file(record)).custom_minimum_size = Vector2(200,44)
		var rule := HSeparator.new()
		rule.position = Vector2(32,326+index*124)
		rule.size.x = 1216
		app.screen.add_child(rule)
	var nav := Parts.row(app.screen,20)
	nav.position = Vector2(32,652)
	app.button(nav,"Previous","RecordsPrevious",func(): app.record_page=posmod(app.record_page-1,pages); app.render("records"))
	app.text(nav,"%d / %d" % [app.record_page+1,pages],18)
	app.button(nav,"Next","RecordsNext",func(): app.record_page=posmod(app.record_page+1,pages); app.render("records"))
