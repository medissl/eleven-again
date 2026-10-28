extends VBoxContainer
const Parts = preload("res://ui/campaign_parts.gd")
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

func _ready() -> void:
	state = app.session.controller.snapshot()
	revision = state.revision
	market = state.step == "market"
	var candidates: Array = state.market.cards if market else state.offer.cards
	selected = candidates[0] if not candidates.is_empty() else ""
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	var heading := Parts.row(self)
	app.text(heading,"MARKET "+["I","II","III"][state.market.number-1] if market else "CHOOSE ONE PLAYER",48,"Heading")
	if market:
		var club: Dictionary = app.library.clubs[state.fixtures[state.wins].club_id]
		var scout = app.text(heading,"NEXT  %s  %.1f OVR  %s\n%s" % [club.name,app.library.xi_rating(app.library.opponent_plan(state.fixtures[state.wins].variant_id)),club.formation,club.scout_threat],16)
		scout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_area = ScrollContainer.new()
	card_area.name = "CandidateScroll"
	card_area.follow_focus = true
	card_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(card_area)
	var bar := Parts.row(self)
	review = app.text(bar,"",17,"BodyStrong")
	review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if state.plan.cards.size() == 18:
		replacement = OptionButton.new()
		replacement.name = "OutgoingPlayer"
		replacement.custom_minimum_size = Vector2(320,46)
		replacement.add_item("Change outgoing player…")
		for record in state.plan.cards: replacement.add_item(record.display_name+"  "+record.primary_role)
		replacement.item_selected.connect(func(index): outgoing = state.plan.cards[index-1].card_id if index > 0 else ""; update_review())
		bar.add_child(replacement)
	var footer := Parts.row(self)
	app.button(footer,"Leave market" if market else "Skip", "LeaveOffer",func(): app.act("close_market" if market else "skip_recruit",[],revision))
	app.button(footer,"Details","OfferDetails",func(): app.inspect(selected,outgoing))
	if market:
		app.button(footer,"Previous","MarketPrevious",func(): change_page(-1))
		pager = app.text(footer,"1 / 2",18)
		app.button(footer,"Next","MarketNext",func(): change_page(1))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	confirm = app.button(footer,"Sign player" if market else "Confirm recruit","ConfirmAcquisition",func(): app.act("acquire",[selected,outgoing],revision),true)
	confirm.custom_minimum_size.x = 240
	build_cards()

func build_cards() -> void:
	for child in card_area.get_children():
		card_area.remove_child(child)
		child.queue_free()
	tiles.clear()
	var row := Parts.row(card_area,16)
	var ids: Array = state.market.cards.slice(page*4,page*4+4) if market else state.offer.cards
	var width: float = clampf((app.size.y-330-140*(app.ui_scale()-1))/1.4,250,340*app.ui_scale())
	for id in ids:
		var column := Parts.column(row,4)
		column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var tile := Parts.card(column,app.library,id,width,app.ui_scale())
		tile.name = "Candidate_"+id
		tile.pressed.connect(func(): select(id))
		tile.focus_entered.connect(func(): select(id); card_area.ensure_control_visible(tile))
		tiles.append(tile)
		if market:
			var cost: int = app.library.price(app.library.cards[id].rating())
			var signed: bool = id in state.market.purchased
			var caption: String = "Signed" if signed else app.money(cost)+("  Unaffordable" if cost > state.cash else "")
			app.text(column,caption,20,"Score")
	if market: pager.text = "%d / 2" % (page+1)
	update_review()
	Parts.focus_loop(app.screen)

func select(id: String) -> void:
	if id not in (state.market.cards if market else state.offer.cards): return
	selected = id
	update_review()

func change_page(offset: int) -> void:
	page = posmod(page+offset,2)
	# A selection/replacement preview survives paging; stock is never regenerated.
	build_cards()

func update_review() -> void:
	for tile in tiles: tile.set_selected(tile.definition.card_id == selected)
	if selected.is_empty():
		review.text = "No eligible players remain. Continue without signing."
		confirm.disabled = true
		app.screen.find_child("OfferDetails",true,false).disabled = true
		return
	var card: Resource = app.library.cards[selected]
	var cost: int = app.library.price(card.rating()) if market else 0
	var caption: String = card.display_name+"\n"
	caption += "Funds after signing "+app.money(state.cash-cost) if cost <= state.cash else "Shortfall "+app.money(cost-state.cash)
	if not outgoing.is_empty():
		var old: Resource = app.library.cards[outgoing]
		caption += "  Replace "+old.display_name
		if old.primary_role == card.primary_role: caption += "  %s slot %+d" % [old.primary_role,card.rating(old.primary_role,true)-old.rating(old.primary_role,true)]
	elif state.plan.cards.size() == 18: caption += "  Choose a replacement; no player is released until confirmation."
	review.text = caption
	var last_keeper := false
	if not outgoing.is_empty() and "GK" in app.library.cards[outgoing].natural_roles and "GK" not in card.natural_roles:
		last_keeper = state.plan.cards.filter(func(record): return "GK" in record.natural_roles).size() == 1
	confirm.disabled = cost > state.cash or (state.plan.cards.size() == 18 and outgoing.is_empty()) or last_keeper or (market and (selected in state.market.purchased or state.market.purchased.size() >= 2))
	confirm.tooltip_text = "Keep a trained goalkeeper." if last_keeper else ""
