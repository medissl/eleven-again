extends VBoxContainer
const Parts = preload("res://ui/campaign_parts.gd")
const Overlay = preload("res://ui/match_overlay.gd")
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
var replacement: OptionButton
var pager: Label
var card_area: ScrollContainer
var revision := 0
var facts := {}

func _ready() -> void:
	state = app.session.controller.snapshot()
	revision = state.revision
	market = state.step == "market"
	var candidates: Array = state.market.cards if market else state.offer.cards
	selected = candidates[0] if not candidates.is_empty() else ""
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",16)
	app.text(self,"MARKET "+["I","II","III"][state.market.number-1] if market else "CHOOSE ONE PLAYER",48,"Heading")
	var middle := Parts.row(self,22)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := Parts.column(middle,12)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_area = ScrollContainer.new()
	card_area.name = "CandidateScroll"
	card_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(card_area)
	if market:
		middle.add_child(VSeparator.new())
		var side := Parts.column(middle,12)
		side.size_flags_horizontal = Control.SIZE_FILL
		side.custom_minimum_size.x = side_width()
		facts.name = app.text(side,"",32,"Team")
		facts.name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		facts.role = app.text(side,"",26,"Score")
		side.add_child(HSeparator.new())
		fact(side,"Signing fee","fee")
		fact(side,"Funds after signing","funds")
		side.add_child(HSeparator.new())
		app.text(side,"Replaces" if state.plan.cards.size() == 18 else "Squad",17)
		facts.outgoing = app.text(side,"",18,"BodyStrong")
		facts.outgoing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if state.plan.cards.size() == 18: choose_outgoing(side)
		facts.comparison_rule = HSeparator.new()
		side.add_child(facts.comparison_rule)
		facts.comparison = fact(side,"","slot")
		review = app.text(side,"",14)
		review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var space := Control.new()
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
		side.add_child(space)
		confirm = app.button(side,"Sign player","ConfirmAcquisition",func(): app.act("acquire",[selected,outgoing],revision),true)
		confirm.custom_minimum_size.y = 50
		var fixture: Dictionary = state.fixtures[state.wins]
		var club: Dictionary = app.library.clubs[fixture.club_id]
		var next_opponent: Label = app.text(left,"NEXT  %s  %.1f OVR  %s" % [club.name,app.library.xi_rating(app.library.opponent_plan(fixture.variant_id)),club.formation],15)
		next_opponent.tooltip_text = club.scout_threat+"\n"+club.scout_response
		footer(left)
	else:
		if state.plan.cards.size() == 18:
			var strip := Parts.row(self,16)
			app.text(strip,"Squad full",17,"BodyStrong")
			choose_outgoing(strip)
			review = app.text(strip,"Choose a replacement before recruiting.",15)
			review.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(HSeparator.new())
		footer(self)
	build_cards()

func side_width() -> float: return clampf(app.size.x*0.26,300,400)

func fact(parent: Node, caption: String, id: String) -> HBoxContainer:
	var row := Parts.row(parent,12)
	row.custom_minimum_size.y = 34
	var label: Label = app.text(row,caption,17)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value: Label = app.text(row,"",22,"Score")
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	facts[id] = value
	if id == "slot": facts.slot_caption = label
	return row

func choose_outgoing(parent: Node) -> void:
	replacement = OptionButton.new()
	replacement.name = "OutgoingPlayer"
	replacement.custom_minimum_size = Vector2(220,40)
	replacement.add_item("Choose outgoing player…")
	for record in state.plan.cards: replacement.add_item(record.display_name+"  "+record.primary_role)
	replacement.item_selected.connect(func(index): outgoing = state.plan.cards[index-1].card_id if index > 0 else ""; update_review())
	parent.add_child(replacement)

func footer(parent: Node) -> void:
	var row := Parts.row(parent,12)
	icon(app.button(row,"Leave market" if market else "Skip","LeaveOffer",func(): app.act("close_market" if market else "skip_recruit",[],revision)),"quit")
	if not market: row.add_child(VSeparator.new())
	icon(app.button(row,"Player details","OfferDetails",func(): app.inspect(selected,outgoing)),"info")
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	if market:
		app.button(row,"‹","MarketPrevious",func(): change_page(-1))
		pager = app.text(row,"1 / 2",18)
		app.button(row,"›","MarketNext",func(): change_page(1))
	else:
		confirm = app.button(row,"Recruit player","ConfirmAcquisition",func(): app.act("acquire",[selected,outgoing],revision),true)
		confirm.custom_minimum_size = Vector2(220,50)

func icon(button: Button, kind: String) -> void:
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for style in ["normal","hover","pressed"]:
		var box: StyleBox = button.get_theme_stylebox(style).duplicate()
		box.content_margin_left = 40
		button.add_theme_stylebox_override(style,box)
	var glyph := Overlay.Icon.new()
	glyph.kind = kind
	glyph.ink = Parts.IVORY
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	var align_icon := func(): glyph.position = Vector2(8,(button.size.y-24)/2)
	button.resized.connect(align_icon)
	align_icon.call()

func build_cards() -> void:
	var focus: Control = get_viewport().gui_get_focus_owner()
	for child in card_area.get_children():
		card_area.remove_child(child)
		child.queue_free()
	tiles.clear()
	var row := Parts.row(card_area,14)
	var ids: Array = state.market.cards.slice(page*4,page*4+4) if market else state.offer.cards
	var available: float = app.size.x-48-(side_width()+45 if market else 0)
	var width: float = minf(340,minf((available-14*(ids.size()-1))/maxi(1,ids.size()),(app.size.y-300-(54 if replacement != null and not market else 0))/1.4))
	for id in ids:
		var column := Parts.column(row,4)
		column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var tile := Parts.card(column,app.library,id,width,1.0)
		tile.name = "Candidate_"+id
		tile.pressed.connect(func(): select(id))
		tile.focus_entered.connect(func(): select(id))
		tiles.append(tile)
		if market:
			var cost: int = app.library.price(app.library.cards[id].rating())
			var caption: String = "Signed" if id in state.market.purchased else app.money(cost)+("  Unaffordable" if cost > state.cash else "")
			app.text(column,caption,20,"Score")
	if market: pager.text = "%d / 2" % (page+1)
	update_review()
	Parts.focus_loop(app.screen)
	if is_instance_valid(focus) and focus.is_inside_tree(): focus.grab_focus()

func select(id: String) -> void:
	var ids: Array = state.market.cards if market else state.offer.cards
	if id not in ids: return
	selected = id
	if market and page != int(ids.find(id)/4):
		page = int(ids.find(id)/4)
		build_cards()
	else: update_review()

func change_page(offset: int) -> void:
	page = posmod(page+offset,2)
	selected = state.market.cards[page*4]
	# Paging changes only the preview; saved stock and transactions remain untouched.
	build_cards()

func update_review() -> void:
	for tile in tiles: tile.set_selected(tile.definition.card_id == selected)
	if selected.is_empty():
		if review != null: review.text = "No eligible players remain. Continue without signing."
		confirm.disabled = true
		app.screen.find_child("OfferDetails",true,false).disabled = true
		return
	var card: Resource = app.library.cards[selected]
	var cost: int = app.library.price(card.rating()) if market else 0
	var old: Resource = app.library.cards.get(outgoing)
	var last_keeper: bool = old != null and "GK" in old.natural_roles and "GK" not in card.natural_roles and state.plan.cards.filter(func(record): return "GK" in record.natural_roles).size() == 1
	confirm.disabled = cost > state.cash or (state.plan.cards.size() == 18 and outgoing.is_empty()) or last_keeper or (market and (selected in state.market.purchased or state.market.purchased.size() >= 2))
	confirm.tooltip_text = "Keep a trained goalkeeper." if last_keeper else ""
	if review != null: review.text = "Keep a trained goalkeeper." if last_keeper else ("" if market or old != null else "Choose a replacement before recruiting.")
	if not market: return
	facts.name.text = card.display_name.to_upper()
	facts.role.text = "%s  %d" % [card.primary_role,card.rating()]
	facts.fee.text = app.money(cost)
	facts.funds.text = app.money(state.cash-cost) if cost <= state.cash else "Shortfall "+app.money(cost-state.cash)
	facts.outgoing.text = "%s  %d  %s" % [old.display_name,old.rating(),old.primary_role] if old != null else ("Choose an outgoing player." if replacement != null else "Joins your %d-player squad." % state.plan.cards.size())
	if replacement != null: replacement.text = "Change" if old != null else "Choose outgoing player…"
	var owned_index: int = state.plan.cards.map(func(record): return record.card_id).find(outgoing)
	var slot: int = state.plan.starters.find(owned_index)
	var role: String = Lineup.ROLES[state.plan.formation][slot] if slot >= 0 else ""
	var comparable: bool = old != null and slot >= 0 and role in old.natural_roles and role in card.natural_roles
	facts.comparison.visible = comparable
	facts.comparison_rule.visible = comparable
	if comparable:
		facts.slot_caption.text = role+" slot"
		facts.slot.text = "%d → %d" % [old.rating(role,true),card.rating(role,true)]
