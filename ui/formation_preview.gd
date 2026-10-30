extends "res://match/match_view.gd"
## Read-only projection through the real pitch renderer, using an isolated model.
signal slot_selected(slot: int)
var plan: Resource
var editable := false
var card_pitch: Control
var card_views: Array[Control] = []
var slot_card_script: Script
var squad_editor: Control

func _ready() -> void:
	audio_enabled = false
	fixture_seed = 1
	external_model = Match.new(1,Match.REGULATION_SECONDS,plan,plan)
	for actor in external_model.players:
		actor.active = actor.team == 0
		actor.position = Match.FootballAI.SHAPES[plan.formation][actor.id % 11]
		actor.previous = actor.position
		external_model.events.clear()
	external_model.owner = -1
	external_model.ball = Vector2(-1000,-1000)
	external_model.ball_state = Match.BallState.DEAD
	super._ready()
	font = preload("res://ui/campaign_parts.gd").ThemeData.default_font
	hud.hide()
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	card_pitch = preload("res://ui/card_pitch.gd").new()
	add_child(card_pitch)
	for slot in 11:
		var card: Control = slot_card_script.new() if slot_card_script != null else preload("res://ui/player_card.gd").new()
		if squad_editor != null:
			card.editor=squad_editor
			card.card_index=plan.starters[slot]
			card.slot=slot
		var definition: Resource = plan.cards[plan.starters[slot]]
		var metadata: Dictionary = card_library.metadata(definition.card_id) if card_library != null else preload("res://content/catalogue.gd").new().metadata(definition.card_id)
		card.bind(definition,metadata)
		card.set_selected(slot == selected)
		card.pressed.connect(func(): slot_selected.emit(slot))
		card.focus_mode = FOCUS_ALL if editable else FOCUS_NONE
		card.mouse_filter = MOUSE_FILTER_STOP if editable else MOUSE_FILTER_IGNORE
		card_views.append(card)
		add_child(card)
	focus_mode = Control.FOCUS_ALL if editable else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if editable else Control.MOUSE_FILTER_IGNORE
	_layout()

func _formation_opacity() -> float:
	return 1.0

func _layout() -> void:
	var available := Rect2(14,18,maxf(1,size.x-28),maxf(1,size.y-36))
	var factor := minf(available.size.x/105,available.size.y/68)
	pitch = Rect2(available.get_center()-Vector2(105,68)*factor/2,Vector2(105,68)*factor)
	if is_instance_valid(card_pitch):
		card_pitch.position = Vector2(14,8)
		card_pitch.size = size-Vector2(28,16)
		var width := clampf(size.x*0.105,46,96) if squad_editor == null else 78.0
		var diagrams := {
			"4-3-3":[Vector2(.5,.88),Vector2(.15,.67),Vector2(.38,.69),Vector2(.62,.69),Vector2(.85,.67),Vector2(.5,.48),Vector2(.28,.37),Vector2(.72,.37),Vector2(.15,.10),Vector2(.5,.10),Vector2(.85,.10)],
			"4-4-2":[Vector2(.5,.99),Vector2(.15,.80),Vector2(.38,.80),Vector2(.62,.80),Vector2(.85,.80),Vector2(.15,.40),Vector2(.38,.40),Vector2(.62,.40),Vector2(.85,.40),Vector2(.36,.00),Vector2(.64,.00)],
			"4-2-3-1":[Vector2(.5,.99),Vector2(.10,.80),Vector2(.27,.80),Vector2(.73,.80),Vector2(.90,.80),Vector2(.40,.60),Vector2(.60,.60),Vector2(.15,.39),Vector2(.5,.39),Vector2(.85,.39),Vector2(.5,.00)]
		}
		for slot in card_views.size():
			var card: Control = card_views[slot]
			card.custom_minimum_size=Vector2(width,width*1.4)
			card.size=card.custom_minimum_size
			var point: Vector2 = sim.players[slot].position
			var projected: Vector2 = card_pitch.project(Vector2(68-point.y,105-point.x))
			projected.y=48+(105-point.x)/105.0*(size.y-104)
			card.position=card_pitch.position+projected-card.size/2
			if squad_editor != null:
				var normalized: Vector2=diagrams[plan.formation][slot]
				card.position=Vector2(14+normalized.x*(size.x-28),66+normalized.y*(size.y-136))-card.size/2
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("080E1980"))

func _gui_input(event: InputEvent) -> void:
	if not editable: return
	var slot := selected
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for index in 11:
			if _field(player_positions[index]).distance_to(event.position) < 20: slot=index; break
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_LEFT,KEY_UP]: slot=posmod(selected-1,11)
		elif event.keycode in [KEY_RIGHT,KEY_DOWN]: slot=posmod(selected+1,11)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]: slot=maxi(0,selected)
	if slot >= 0 and slot < 11:
		selected=slot
		slot_selected.emit(slot)
		queue_redraw()
		accept_event()
