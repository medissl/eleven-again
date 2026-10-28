extends RefCounted
## Plain data only: no serialized executable objects or runtime UI state.
const FIELDS := ["match_seed","ticks","active_ticks","ball_state","ball","previous_ball","owner","last_touch","held_ticks","scores","events","possession_ticks","pass_attempts","completed_passes","tackles","ball_velocity","flight_target","flight_source","flight_kind","pass_pending","shots","shots_on_target","saves","shot_quality","keeper_tested","dead_ticks","restart_team","period","finished","restart_kind","restart_position","regulation_ticks","halftime_report","result_report","kickoff_taker","kickoff_ticks","kickoff_kicker","ball_height","restart_taker","restart_counts","fouls","combination","transition_tick","flight_delivery","flight_receiver","substitution_counts","substitution_windows","substitution_stages","used_cards","action_id","flight_trait_actor","flight_trait_action","flight_ticks","flight_origin","flight_control","flight_duration","flight_curve","flight_peak","shot_context","pending_shot","current_restart","keeper_hand_owner","offside_context","restart_untouched","restart_delivery","restart_kick_team","forfeit_team","flight_on_target_recorded"]
const PLAYER_FIELDS := ["id","team","name","position","previous","target","pace","passing","shooting","defence","dribbling","keeping","physical","reflexes","handling","positioning","diving","kicking","role","stamina","velocity","facing","ready_tick","job","entered_tick","trait_state","trait_uses","trait_ready","response_delay","run_ready_tick","cooldown","active","yellows"]

static func capture(m) -> Dictionary:
	var data := {"schema":1,"engine":Engine.get_version_info().string,"rng":m.rng.state,"plans":m.plans.map(func(plan): return plan.to_data()),"players":[],"state":{}}
	for key in FIELDS:
		var value = m.get(key)
		data.state[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	for player in m.players:
		var state := {"card":player.card.to_data()}
		for key in PLAYER_FIELDS:
			var value = player.get(key)
			state[key] = value.duplicate(true) if value is Array or value is Dictionary else value
		data.players.append(state)
	return data

static func restore(data: Dictionary) -> RefCounted:
	if data.get("schema") != 1 or data.get("engine") != Engine.get_version_info().string: return null
	if data.get("state") is not Dictionary or data.get("plans") is not Array or data.plans.size() != 2 or data.get("players") is not Array or data.players.size() != 22 or data.get("rng") is not int: return null
	if data.plans[0] is not Dictionary or data.plans[1] is not Dictionary: return null
	var Lineup = load("res://squad/lineup.gd")
	var home = Lineup.from_data(data.plans[0])
	var away = Lineup.from_data(data.plans[1])
	if home == null or away == null: return null
	for key in FIELDS:
		if not data.state.has(key): return null
	if data.state.regulation_ticks is not int or data.state.regulation_ticks < 120 or data.state.regulation_ticks > 43200 or data.state.match_seed is not int: return null
	var model = load("res://match/match_sim.gd").new(data.state.match_seed,roundi(data.state.regulation_ticks/60.0),home,away)
	for key in FIELDS:
		if typeof(data.state[key]) != typeof(model.get(key)): return null
		if key == "events": model.events.assign(data.state.events.duplicate(true))
		else: model.set(key,data.state[key].duplicate(true) if data.state[key] is Array or data.state[key] is Dictionary else data.state[key])
	for index in 22:
		if data.players[index] is not Dictionary: return null
		var state: Dictionary = data.players[index]
		var card = load("res://content/player_card.gd").from_data(state.get("card",{}))
		if card == null: return null
		model.players[index].card = card
		for key in PLAYER_FIELDS:
			if not state.has(key): return null
			if typeof(state[key]) != typeof(model.players[index].get(key)): return null
			model.players[index].set(key,state[key].duplicate(true) if state[key] is Array or state[key] is Dictionary else state[key])
		if model.players[index].id != index or model.players[index].team != int(index/11.0) or not model.players[index].position.is_finite(): return null
	if model.owner < -1 or model.owner >= 22 or not model.ball.is_finite(): return null
	model.rng.state = data.rng
	return model
