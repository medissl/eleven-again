extends "res://match/match_view.gd"
## The rich native pitch draws a private frozen copy. Never calls step().
func _required_report() -> String: return ""
func _ready() -> void:
	audio_enabled = false
	replays_enabled = false
	fixture_seed = 1
	super._ready()
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
	hud.labels.score.text = "%d – %d" % sim.scores
	hud.labels.clock.text = "%d′ · REPLAY" % sim.display_minute()
	queue_redraw()
