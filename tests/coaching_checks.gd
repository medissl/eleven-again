extends SceneTree
const Match = preload("res://match/match_sim.gd")
const Snapshot = preload("res://match/match_snapshot.gd")

func _initialize() -> void:
	var model := Match.new(42)
	for player in model.players:
		player.card.trait_id = ""
		player.stamina = 100
	var id := 6
	var player = model.players[id]
	player.position = Vector2(50,25)
	model.principles[0] = ["short_combinations","wide_service"]
	var original: float = model.attribute(id,"PAS")
	assert(model.attribute(id,"PAS",0,{"kind":"pass","ground":true}) == original+3)
	assert(model.attribute(id,"PAS",0,{"kind":"pass","ground":false}) == original)
	assert(model.attribute(id,"PAS",0,{"kind":"pass","delivery":"cross"}) == original+3)
	player.position.x = 70
	assert(model.attribute(id,"PAS",0,{"kind":"pass","ground":true}) == original)
	model.principles[0] = ["first_pressure","bench_impact"]
	model.plans[0].defence = "high_press"
	original = model.attribute(id,"DEF")
	assert(model.attribute(id,"DEF",0,{"kind":"standing_tackle"}) == original+3)
	assert(model.attribute(id,"DEF") == original,"Interceptions/blocks do not receive a standing-tackle bonus")
	model.plans[0].defence = "balanced"
	assert(model.attribute(id,"DEF",0,{"kind":"standing_tackle"}) == original)
	original = model.attribute(id,"PHY")
	player.entered_tick = 20
	assert(model.attribute(id,"PHY") == original+3)
	player.stamina = 50
	assert(is_equal_approx(model.attribute(id,"PHY"),(player.physical+3)*0.94),"Fatigue applies once, after capped bonuses")
	player.stamina = 100
	player.trait_state = {"state":"active","parameters":{"attribute":"PHY","bonus":4}}
	assert(model.attribute(id,"PHY") == minf(120,player.physical+6))
	player.trait_state.clear()
	model.principles[0] = ["counter_runners","set_piece_preparation"]
	model.ball_state = model.BallState.CONTROLLED
	model.last_control_team = 0
	model.transition_tick = 100
	model.active_ticks = 219
	original = player.pace
	assert(model.attribute(id,"PAC") == original+3)
	model.active_ticks = 220
	assert(model.attribute(id,"PAC") == original)
	model.active_ticks = 100
	model.ball_state = model.BallState.DEAD
	assert(model.attribute(id,"PAC") == original)
	model.ball_state = model.BallState.CONTROLLED
	original = model.attribute(id,"SHO")
	for context in [{"kind":"shot","restart":"free_kick"},{"kind":"shot","aerial":true,"from_corner":true}]: assert(model.attribute(id,"SHO",0,context) == original+3)
	for context in [{"kind":"shot","restart":"penalty"},{"kind":"shot","aerial":true},{"kind":"shot","from_corner":true}]: assert(model.attribute(id,"SHO",0,context) == original)
	var restored: RefCounted = Snapshot.restore(Snapshot.capture(model))
	assert(restored != null and restored.signature() == model.signature())
	for tick in 300:
		model.step()
		restored.step()
	assert(model.signature() == restored.signature(),"Coaching and recovery timing survive snapshots exactly")
	var legacy := Snapshot.capture(Match.new(7))
	legacy.schema = 1
	legacy.state.erase("principles")
	assert(Snapshot.restore(legacy).principles == [[],[]])
	actual_actions()
	print("COACHING: all six positive/negative contexts, fatigue/cap, native pass/shot execution and snapshot/legacy checks passed")
	quit()

func actual_actions() -> void:
	var model := Match.new(52)
	for player in model.players: player.card.trait_id = ""
	model.players[6].position = Vector2(45,25)
	model.players[8].position = Vector2(65,25)
	model.players[8].target = model.players[8].position
	model.take_control(6)
	model.principles[0] = ["short_combinations"]
	var effective: float = model.attribute(6,"PAS",0,{"kind":"pass","ground":true})
	model.pass_to(8)
	assert(is_equal_approx(model.ball_velocity.length(),19+effective*0.08),"Actual ground delivery uses the contextual PAS")
	model.players[9].position = Vector2(86,34)
	model.take_control(9)
	model.current_restart = "free_kick"
	model.principles[0] = ["set_piece_preparation"]
	effective = model.attribute(9,"SHO",0,{"kind":"shot","restart":"free_kick"})
	model.shoot()
	assert(is_equal_approx(model.ball_velocity.length(),minf(36,26+effective*0.08)),"Actual free-kick speed uses contextual SHO")
	assert(model.rng.state != 0)
	var charged := Match.new(4)
	charged.players[9].card.trait_id = "power_strike"
	charged.players[9].position = Vector2(86,34)
	charged.principles[0] = ["set_piece_preparation"]
	charged.take_control(9)
	charged.current_restart = "free_kick"
	charged.shoot()
	assert(not charged.pending_shot.is_empty() and charged.shot_context.restart == "free_kick")
	charged.current_restart = ""
	var resumed: RefCounted = Snapshot.restore(Snapshot.capture(charged))
	assert(resumed != null)
	charged.pending_shot.clear()
	resumed.pending_shot.clear()
	charged.shoot(0,true)
	resumed.shoot(0,true)
	assert(charged.restart_delivery == "free_kick" and charged.restart_untouched,"A delayed kick keeps its real restart restrictions")
	assert(charged.signature() == resumed.signature(),"Saved windup retains coaching and physical delivery context")
