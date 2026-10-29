extends ColorRect
signal closed
const Parts = preload("res://ui/campaign_parts.gd")
var record: Dictionary
var library: RefCounted
var reduced_motion := false
var card_panel: Control
var selected := 0
var selection: Label
var comparison_card: Resource

func _ready() -> void:
	theme = Parts.ThemeData
	color = theme.get_color("forest","Palette")
	var heading := Parts.label(self,"Record eleven",34,"Heading")
	heading.position = Vector2(32,100)
	var context := Parts.label(self,"%s   %s   Highest team OVR %.2f" % [library.countries[record.origin].name,record.outcome.capitalize(),record.peak_xi.total/11.0],18)
	context.position = Vector2(32,152)
	var plan = load("res://squad/lineup.gd").new()
	plan.formation = record.peak_xi.formation
	plan.bench_order.clear()
	for id in record.peak_xi.cards: plan.cards.append(library.cards[id])
	var preview = load("res://ui/formation_preview.gd").new()
	preview.plan = plan
	preview.editable = true
	preview.position = Vector2(32,226)
	preview.size = Vector2(600,388)
	add_child(preview)
	preview.slot_selected.connect(func(slot): selected=slot; show_selection())
	Parts.label(self,"SAVED RUN",21,"BodyStrong",Color("A5B09F")).position = Vector2(700,226)
	var detail := Parts.label(self,"Select a player to inspect their historical card.\nThis record is read-only.",20)
	detail.position = Vector2(700,286)
	detail.size = Vector2(500,90)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection = Parts.label(self,"",24,"Team")
	selection.position = Vector2(700,420)
	show_selection()
	var inspect := Parts.button(self,"Inspect selected player","InspectRecordPlayer",func(): open_card(),false)
	inspect.position = Vector2(700,510)
	inspect.size = Vector2(320,44)
	var back := Parts.button(self,"Back","CloseRecordXI",dismiss,false)
	back.position = Vector2(32,652)
	back.size = Vector2(172,44)
	Parts.focus_loop(self)

func show_selection() -> void:
	var card: Resource = library.cards[record.peak_xi.cards[selected]]
	selection.text = "%s   %s   %d" % [card.display_name,card.primary_role,record.peak_xi.ratings[selected]]

func open_card() -> void:
	if is_instance_valid(card_panel): return
	var card: Resource = library.cards[record.peak_xi.cards[selected]]
	card_panel = load("res://ui/card_inspector.gd").new()
	card_panel.definition = card
	card_panel.info = library.metadata(card.card_id)
	card_panel.owned = true
	card_panel.reduced_motion = reduced_motion
	if comparison_card != null and comparison_card != card:
		card_panel.comparison = comparison_card
		var role: String = preload("res://squad/lineup.gd").ROLES[record.peak_xi.formation][selected]
		if role in card.natural_roles and role in comparison_card.natural_roles: card_panel.comparison_role=role
		card_panel.comparison_info = library.metadata(comparison_card.card_id)
	card_panel.pin_requested.connect(func(_id): comparison_card=card)
	add_child(card_panel)
	card_panel.closed.connect(func(): card_panel=null; find_child("InspectRecordPlayer",true,false).grab_focus())

func dismiss() -> void:
	if is_instance_valid(card_panel): return
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(card_panel): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
