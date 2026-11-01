extends "res://match/match_view.gd"
## The rich native pitch draws a private frozen copy. Never calls step().
var recorded_cards := {}
func _required_report() -> String: return ""
func _ready() -> void:
	audio_enabled = false
	replays_enabled = false
	fixture_seed = 1
	super._ready()
	for plan in sim.plans:
		for card in plan.cards: recorded_cards[card.card_id]=card
	set_physics_process(false)
	set_process(false)
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control in hud.buttons.values(): control.hide()
	hud.event_list.hide()
	hud.labels.live.text = "REPLAY"
	hud.labels.clock.text = "REPLAY"
	hud.status_color = Color("49D6F5")
	hud.cue.hide()

func recorded_frame(first: Dictionary, second: Dictionary, mix_amount: float) -> void:
	sim.ticks = first.tick
	sim.active_ticks = first.active_tick
	sim.owner = first.owner
	sim.ball_state = first.state
	sim.flight_trait_actor=first.get("flight_actor",-1)
	sim.last_touch=first.get("last_touch",sim.last_touch)
	sim.flight_kind=first.get("flight_kind",sim.flight_kind)
	sim.ball_velocity=first.get("velocity",Vector2.ZERO)
	sim.scores = first.scores.duplicate()
	sim.ball_height = lerpf(first.height,second.height,mix_amount)
	ball = first.ball.lerp(second.ball,mix_amount)
	sim.ball = ball
	for index in 22:
		player_positions[index] = first.positions[index].lerp(second.positions[index],mix_amount)
		sim.players[index].position = player_positions[index]
		sim.players[index].facing = first.facing[index]
		sim.players[index].active = (first.active & (1 << index)) != 0
		sim.players[index].name = first.names[index]
		sim.players[index].role = first.roles[index]
		if first.has("traits"): sim.players[index].trait_state=first.traits[index].duplicate(true)
		if first.has("cards") and recorded_cards.has(first.cards[index]): sim.players[index].card=recorded_cards[first.cards[index]]
	hud.labels.score.text = "%d – %d" % sim.scores
	hud.labels.clock.text = "%d′ · REPLAY" % sim.display_minute()
	queue_redraw()
