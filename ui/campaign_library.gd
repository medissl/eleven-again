extends RefCounted
const Parts = preload("res://ui/campaign_parts.gd")
const Profile = preload("res://persistence/profile.gd")

static func build(app, outer: Node, page: String) -> void:
	app.text(outer,"DISCOVERED" if page == "discovered" else "RUN RECORDS",48,"Heading")
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var body := Parts.column(scroll,16)
	if page == "records":
		var history := Profile.ranked(app.session.profile)
		if history.is_empty(): app.text(body,"No completed runs yet. Records never change starting power.",21)
		for record in history:
			app.text(body,"%s  %s" % [app.library.countries[record.origin].name,record.outcome.capitalize()],30,"Team")
			app.text(body,"%d wins   %d defeats   Peak XI %.2f OVR\nGoal difference %+d   %s" % [record.wins,record.defeats,record.peak_xi.total/11.0,record.goal_difference,record.balance_version.replace("_"," ")],19)
			app.button(body,"View record XI","RecordXI_"+record.run_id,func(): app.record_file(record))
			body.add_child(HSeparator.new())
		return
	app.text(body,"%d / %d editions acquired. Unchosen and opponent cards stay hidden." % [app.session.profile.discoveries.size(),app.library.recruits.size()],18)
	var filter := CheckButton.new()
	filter.name = "AcquiredOnly"
	filter.text = "Acquired editions only"
	filter.button_pressed = app.collection_known
	filter.toggled.connect(func(value): app.collection_known=value; app.collection_page=0; app.render("discovered"))
	body.add_child(filter)
	var pool: Array = app.library.recruits.filter(func(card): return not app.collection_known or app.session.profile.discoveries.has(card.card_id))
	var pages := maxi(1,ceili(pool.size()/3.0))
	app.collection_page = mini(app.collection_page,pages-1)
	if pool.is_empty(): app.text(body,"No acquired editions yet.",23)
	var first: int = app.collection_page*3
	var row := Parts.row(body,20)
	for card in pool.slice(first,first+3):
		var known: bool = app.session.profile.discoveries.has(card.card_id)
		var box := Parts.column(row,6)
		var tile := Parts.card(box,app.library,card.card_id,300,app.ui_scale(),known)
		if known:
			var entry: Dictionary = app.session.profile.discoveries[card.card_id]
			app.text(box,"First acquired "+entry.first_discovered.left(10)+"\nRuns recruited "+str(entry.run_ids.size()),15)
			tile.pressed.connect(func(): app.inspect(card.card_id))
		else: tile.disabled = true
	var footer := Parts.row(outer)
	app.button(footer,"Previous","CollectionPrevious",func(): app.collection_page=posmod(app.collection_page-1,pages); app.render("discovered"))
	app.text(footer,"%d / %d" % [app.collection_page+1,pages],20)
	app.button(footer,"Next","CollectionNext",func(): app.collection_page=posmod(app.collection_page+1,pages); app.render("discovered"))
