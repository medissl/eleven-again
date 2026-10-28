extends RefCounted
const Match = preload("res://match/match_sim.gd")

func fixture(seed_value: int) -> RefCounted:
	var m := Match.new(seed_value)
	for p in m.players:
		p.card.trait_id = ""
		p.position = Vector2(10 if p.team == 0 else 95,5+(p.id%11)*2)
		p.target = p.position
		p.previous = p.position
	m.players[11].position = Vector2(99.5,34)
	return m

func run(check: Callable) -> void:
	var pass_error := [0.0,0.0]
	var touches := [0,0]
	var tackles := [0,0]
	var shield_losses := [0,0]
	var reflex_saves := [0,0]
	var holds := [0,0]
	var dive_saves := [0,0]
	for seed_value in 96:
		for band in 2:
			var value := 60 if band == 0 else 100
			var passer := fixture(seed_value)
			passer.players[6].position = Vector2(40,34)
			passer.players[7].position = Vector2(65,34)
			passer.players[7].target = Vector2(65,34)
			passer.players[6].passing = value
			passer.take_control(6)
			passer.pass_to(7)
			pass_error[band] += passer.flight_target.distance_to(Vector2(65,34))
			passer.players[7].dribbling = value
			passer.flight_target = Vector2(65,34)
			passer.ball = Vector2(63.5,34)
			passer.ball_velocity = Vector2(34,0)
			for tick in 3:
				if passer.ball_state == Match.BallState.FLIGHT: passer.advance_flight()
			if passer.owner == 7: touches[band] += 1
			for strength in [false,true]:
				var duel := fixture(seed_value)
				duel.players[9].position = Vector2(65,34)
				duel.players[12].position = Vector2(67.7,34)
				duel.players[12].defence = 80 if strength else value
				duel.players[12].physical = 80
				duel.players[9].physical = value if strength else 80
				duel.players[9].dribbling = 80
				duel.take_control(9)
				duel.held_ticks = 30
				duel.challenge_carrier()
				if duel.owner == 12:
					if strength: shield_losses[band] += 1
					else: tackles[band] += 1
			for domain in ["REF","HAN","DIV"]:
				var keeper := fixture(seed_value)
				keeper.flight_source = 9
				keeper.flight_ticks = 60
				keeper.shot_quality = 0.6
				keeper.players[11].reflexes = 80
				keeper.players[11].handling = 80
				keeper.players[11].diving = 80
				keeper.players[11].set(Match.ATTRIBUTE_FIELDS[domain],value)
				keeper.ball = Vector2(99.5,34)
				if domain == "DIV": keeper.players[11].position.y = 28
				if keeper.keeper_save(11):
					if domain == "REF": reflex_saves[band] += 1
					if domain == "DIV": dive_saves[band] += 1
					if domain == "HAN" and keeper.owner == 11: holds[band] += 1
	check.call(pass_error[1] < pass_error[0], "paired PAS improves real delivery dispersion")
	check.call(touches[1] > touches[0], "paired DRI improves difficult physical reception")
	check.call(tackles[1] > tackles[0], "paired DEF improves reachable clean challenges")
	check.call(shield_losses[1] < shield_losses[0], "paired PHY improves actual shielding contests")
	check.call(reflex_saves[1] > reflex_saves[0], "paired REF improves the same reachable save")
	check.call(holds[1] > holds[0], "paired HAN improves legal secure holds")
	check.call(dive_saves[1] > dive_saves[0], "paired DIV extends physically reachable saves")
	var targets: Array[Vector2] = []
	var kicking := []
	var endurance := []
	for value in [60,100]:
		var m := fixture(42)
		m.players[20].position = Vector2(20,40)
		m.take_control(20)
		m.players[0].positioning = value
		m.choose_targets()
		targets.append(m.players[0].target)
		m.players[0].kicking = value
		m.players[6].position = Vector2(30,34)
		m.players[6].target = Vector2(30,34)
		m.take_control(0,"hold")
		m.pass_to(6)
		kicking.append(m.ball_velocity.length())
		m.players[6].physical = value
		m.players[6].target = Vector2(80,34)
		for tick in 120: m.move_players()
		endurance.append(m.players[6].stamina)
	check.call(absf(targets[1].y-40) < absf(targets[0].y-40), "paired POS improves actual keeper positioning")
	check.call(kicking[1] > kicking[0], "paired KIC changes actual keeper delivery")
	check.call(endurance[1] > endurance[0], "paired PHY reduces work-rate fatigue")
	print("ATTRIBUTE PAIRS PAS_error=",pass_error," touches=",touches," DEF_wins=",tackles," PHY_losses=",shield_losses," REF_saves=",reflex_saves," HAN_holds=",holds," DIV_saves=",dive_saves)
