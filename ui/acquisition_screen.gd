extends Control
const Parts = preload("res://ui/campaign_parts.gd")
const Lineup = preload("res://squad/lineup.gd")
var app
var state: Dictionary
var market := false
var selected := ""
var outgoing := ""
var page := 0
var tiles: Array[Control] = []
var review: Label
var confirm: Button
var replacement: Button
var pager: Label
var card_area: ScrollContainer
var revision := 0
var facts := {}

func put(node: Control, rect: Rect2) -> Control:
	node.position=rect.position
	node.size=rect.size
	return node

func _ready() -> void:
	state = app.session.controller.snapshot()
	revision = state.revision
	market = state.step == "market"
	var candidates: Array = state.market.cards if market else state.offer.cards
	selected = candidates[0] if not candidates.is_empty() else ""
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	put(app.text(self,"Transfer market" if market else "Choose one player",34,"Heading"),Rect2(0,0,1216,44))
	put(app.text(self,"Two signings" if market else "Free signing",18,"Label",Color("A0B2C9")),Rect2(0,54,1216,30))
	card_area = ScrollContainer.new()
	card_area.name = "CandidateScroll"
	card_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(card_area)
	put(card_area,Rect2(0,116 if market else 120,916 if market else 1216,340))
	if market:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",preload("res://ui/matchday_theme.gd").box("panel"))
		add_child(panel)
		put(panel,Rect2(940,116,276,384))
		var side := Parts.column(self,10)
		put(side,Rect2(956,130,244,356))
		app.text(side,"SIGNING",16,"BodyStrong",Color("A5B09F"))
		facts.name = app.text(side,"",27,"Heading")
		facts.name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		facts.role = app.text(side,"",19,"BodyStrong")
		fact(side,"Fee","fee")
		fact(side,"Cash remaining","funds")
		side.add_child(HSeparator.new())
		var row := Parts.row(side,12)
		facts.outgoing = app.text(row,"",17)
		facts.outgoing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		facts.outgoing.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		facts.outgoing_rating = app.text(row,"",20,"Score")
		facts.outgoing_role = app.text(row,"",20,"Team")
		facts.comparison = fact(side,"","slot")
		if state.plan.cards.size() == 18:
			replacement = app.button(side,"Change","ChangeOutgoing",replacement_drawer)
			replacement.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var nav := Parts.row(self,16)
		put(nav,Rect2(0,470,400,44))
		app.button(nav,"Previous","MarketPrevious",func(): change_page(-1))
		pager = app.text(nav,"1 / 2",18)
		app.button(nav,"Next","MarketNext",func(): change_page(1))
	review = app.text(self,"",16,"Label",Color("A5B09F"))
	put(review,Rect2(428 if market else 0,470,788 if market else 1216,44))
	review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var rule := HSeparator.new()
	add_child(rule)
	put(rule,Rect2(0,532,1216,1))
	if market: put(app.button(self,"Leave market","LeaveOffer",func(): app.act("close_market",[],revision)),Rect2(0,552,172,44)).theme_type_variation = "Quiet"
	put(app.button(self,"Player details","OfferDetails",func(): app.inspect(selected,outgoing)),Rect2(186,552,180,44)).theme_type_variation = "Quiet"
	confirm = app.button(self,"Sign player" if market else "Recruit player","ConfirmAcquisition",acquire,true)
	put(confirm,Rect2(976,552,240,44))
	build_cards()

func fact(parent: Node, caption: String, id: String) -> HBoxContainer:
	var row := Parts.row(parent,12)
	row.custom_minimum_size.y = 30
	var label: Label = app.text(row,caption,17)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value: Label = app.text(row,"",21,"Score")
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	facts[id] = value
	if id == "slot": facts.slot_caption = label
	return row

func build_cards() -> void:
	for child in card_area.get_children(): card_area.remove_child(child); child.queue_free()
	tiles.clear()
	var row := Parts.row(card_area,16 if market else 14)
	var ids: Array = state.market.cards.slice(page*4,page*4+4) if market else state.offer.cards
	for id in ids:
		var column := Parts.column(row,4)
		column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var tile := Parts.card(column,app.library,id,212 if market else 232,1.0)
		tile.name = "Candidate_"+id
		tile.pressed.connect(func(): select(id))
		tile.focus_entered.connect(func(): select(id))
		tiles.append(tile)
		if market:
			var cost: int = app.library.price(app.library.cards[id].rating())
			var caption: String = "Signed" if id in state.market.purchased else app.money(cost)
			app.text(column,caption,23,"Score",Parts.BRASS).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if market: pager.text = "%d / 2" % (page+1)
	update_review()
	var deal := preload("res://ui/card_deal.gd").new()
	deal.audio = app.audio
	deal.reduced = app.preferences.data.motion
	add_child(deal)
	deal.deal(tiles.duplicate())

func select(id: String) -> void:
	var ids: Array = state.market.cards if market else state.offer.cards
	if id not in ids: return
	if selected != id: outgoing = ""
	selected = id
	if market and page != int(ids.find(id)/4): page=int(ids.find(id)/4); build_cards()
	else: update_review()

func change_page(offset: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	page = posmod(page+offset,2)
	outgoing = ""
	selected = state.market.cards[page*4]
	build_cards()
	Parts.focus_loop(app.screen)
	if is_instance_valid(focused) and focused.is_inside_tree() and not focused.is_queued_for_deletion(): focused.grab_focus()

func update_review() -> void:
	for tile in tiles: tile.set_selected(tile.definition.card_id == selected)
	if selected.is_empty():
		review.text = "No eligible players remain. Continue without signing."
		confirm.disabled = true
		find_child("OfferDetails",true,false).disabled = true
		return
	var card: Resource = app.library.cards[selected]
	var cost: int = app.library.price(card.rating()) if market else 0
	var used: bool = market and state.market.purchased.size() >= 2
	var bought: bool = market and selected in state.market.purchased
	confirm.disabled = cost > state.cash or used or bought
	review.text = "Need %s more" % app.money(cost-state.cash) if cost > state.cash else "Both signings used" if used else "Already signed" if bought else "Squad full. Choose an outgoing player when signing." if state.plan.cards.size() == 18 else ""
	if not market: return
	var old: Resource = app.library.cards.get(outgoing)
	facts.name.text = card.display_name
	facts.role.text = "%s   %d" % [card.primary_role,card.rating()]
	facts.fee.text = app.money(cost)
	facts.funds.text = app.money(state.cash-cost) if cost <= state.cash else "—"
	facts.outgoing.text = old.display_name if old != null else "Choose an outgoing player" if state.plan.cards.size() == 18 else "Joins your squad"
	facts.outgoing.tooltip_text = facts.outgoing.text
	facts.outgoing_rating.text = str(old.rating()) if old != null else ""
	facts.outgoing_role.text = old.primary_role if old != null else ""
	var role := comparable_role(outgoing,card)
	facts.slot_caption.text = role+" slot" if not role.is_empty() else ""
	facts.slot.text = "%d → %d" % [old.rating(role,true),card.rating(role,true)] if not role.is_empty() else ""

func comparable_role(id: String, card: Resource) -> String:
	var index: int = state.plan.cards.map(func(record): return record.card_id).find(id)
	var slot: int = state.plan.starters.find(index)
	if slot < 0: return ""
	var role: String = Lineup.ROLES[state.plan.formation][slot]
	var old: Resource = app.library.cards[id]
	return role if role in old.natural_roles and role in card.natural_roles else ""

func acquire() -> void:
	if state.plan.cards.size() == 18: replacement_drawer()
	else: app.act("acquire",[selected,""],revision)

func replacement_drawer() -> void:
	if is_instance_valid(app.modal) or selected.is_empty(): return
	var drawer = load("res://ui/matchday_drawer.gd").new()
	drawer.title = "Replace a player"
	app.open_modal(drawer)
	var before := outgoing
	drawer.closed.connect(func():
		outgoing=before
		update_review()
		app.modal=null
		if is_instance_valid(app.modal_focus): app.modal_focus.grab_focus())
	var card: Resource = app.library.cards[selected]
	var cost: int = app.library.price(card.rating()) if market else 0
	app.text(drawer.body,card.display_name,27,"Heading").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.text(drawer.body,"%s   %d" % [card.primary_role,card.rating()],21,"Team")
	for pair in [["Fee",app.money(cost) if market else "Free signing"],["Cash after signing",app.money(state.cash-cost)]]:
		var row := Parts.row(drawer.body,12)
		app.text(row,pair[0],17).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		app.text(row,pair[1],21,"Score")
	app.text(drawer.body,"Outgoing player",17,"BodyStrong")
	var selector := OptionButton.new()
	selector.name = "OutgoingPlayer"
	selector.custom_minimum_size.y = 44
	selector.add_item("Choose a player…")
	for owned in state.plan.cards:
		selector.add_item(owned.display_name+"   "+owned.primary_role)
		var candidate: Resource = app.library.cards[owned.card_id]
		var protected: bool = "GK" in candidate.natural_roles and "GK" not in card.natural_roles and state.plan.cards.filter(func(record): return "GK" in record.natural_roles).size() == 1
		selector.set_item_disabled(selector.item_count-1,protected or owned.card_id.begins_with("academy_"))
	drawer.body.add_child(selector)
	var detail: Label = app.text(drawer.body,"Choose the player this signing replaces.",18)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.text(drawer.body,"No sale or refund. Cancel leaves your squad and money unchanged.",16,"Label",Color("A5B09F")).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var working := {"id":""}
	var accept: Button = app.button(drawer.actions,"Sign" if market else "Recruit","CommitReplacement",func():
		outgoing=working.id
		app.act("acquire",[selected,outgoing],revision)
		if is_instance_valid(drawer) and app.modal == drawer: detail.text=app.status.text,true)
	accept.disabled = true
	selector.item_selected.connect(func(index):
		working.id = state.plan.cards[index-1].card_id if index > 0 else ""
		outgoing=working.id
		update_review()
		accept.disabled = index == 0 or selector.is_item_disabled(index)
		if index == 0: detail.text="Choose the player this signing replaces."; return
		var old: Resource = app.library.cards[working.id]
		var role := comparable_role(working.id,card)
		detail.text = "%s   %s %d" % [old.display_name,old.primary_role,old.rating()]
		if not role.is_empty(): detail.text += "\n%s slot  %d → %d" % [role,old.rating(role,true),card.rating(role,true)])
