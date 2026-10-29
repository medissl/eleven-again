extends "res://match/match_view.gd"
## Read-only projection through the real pitch renderer, using an isolated model.
signal slot_selected(slot: int)
var plan: Resource
var editable := false

func _ready() -> void:
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
	focus_mode = Control.FOCUS_ALL if editable else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if editable else Control.MOUSE_FILTER_IGNORE
	_layout()

func _formation_opacity() -> float:
	return 1.0

func _layout() -> void:
	var available := Rect2(14,18,maxf(1,size.x-28),maxf(1,size.y-36))
	var factor := minf(available.size.x/105,available.size.y/68)
	pitch = Rect2(available.get_center()-Vector2(105,68)*factor/2,Vector2(105,68)*factor)
	queue_redraw()

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
