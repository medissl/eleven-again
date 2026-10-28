extends RefCounted
## One conditional specialty, one commit per action. Effects are consumed by real football code.
static var catalogue: Dictionary = read_catalogue()

static func read_catalogue() -> Dictionary:
	var result := {}
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/traits.json"))
	assert(data is Dictionary and data.traits.size() == 36)
	for entry in data.traits: result[entry.id] = entry
	return result

static func eligible(id: String, c: Dictionary) -> bool:
	var kind: String = c.get("kind","")
	match id:
		"deflector": return kind == "parry"
		"safe_hands": return kind == "save" and c.get("pressure",1.0) < 0.5
		"cat_reflexes": return kind == "save" and c.get("distance",99.0) < 20
		"sweeper_keeper": return kind == "run" and c.get("job","") == "sweep"
		"long_throw": return kind == "pass" and c.get("delivery","") == "keeper_throw" and c.get("hand_control",false) and c.get("risk",1.0) < 0.35 and c.get("length",0.0) > 20
		"hard_tackle": return kind == "tackle" and c.get("legal_angle",false)
		"anticipator": return kind == "respond" and c.get("reachable",false)
		"aerial_fortress": return kind == "aerial" and c.get("defending",false)
		"body_block": return kind == "block" and c.get("reachable",false)
		"accelerator": return kind == "run" and c.get("open",false) and c.get("job","") in ["overlap","depth run","width outlet","carry"]
		"whipped_cross": return kind == "pass" and c.get("delivery","") == "cross"
		"recovery_sprint": return kind == "run" and c.get("recovery",false)
		"overlap_engine": return kind == "run" and c.get("job","") == "overlap" and c.get("covered",false)
		"screen": return kind == "receive" and c.get("interception",false) and c.get("central",false)
		"anchor": return kind == "shield" and c.get("pressure",0.0) > 0.5
		"switch_play": return kind == "pass" and c.get("lateral",0.0) > 25 and c.get("risk",1.0) < 0.6
		"bullet_pass": return kind == "pass" and c.get("length",0.0) >= 12 and c.get("length",99.0) <= 40 and c.get("delivery","") != "cross"
		"wall_pass": return kind == "receive" and c.get("bounce",false)
		"tempo_setter": return kind == "receive" and c.get("pressure",1.0) < 0.3 and c.get("recycle",false)
		"press_resistant": return kind in ["receive","shield"] and c.get("opponents",0) >= 2
		"threader": return kind == "pass" and c.get("progress",0.0) > 12 and c.get("delivery","") != "cross"
		"third_man": return kind == "run" and c.get("job","") == "third-man run"
		"turn_and_go": return kind == "receive" and c.get("open",false)
		"touchline_burst": return kind == "run" and c.get("job","") == "carry" and c.get("wide",false) and c.get("open",false)
		"cutback": return kind == "pass" and c.get("delivery","") == "cutback" and c.get("risk",1.0) < 0.55
		"cut_inside": return kind == "run" and c.get("job","") == "carry" and c.get("inside",false) and c.get("open",false)
		"close_control": return kind == "receive" and c.get("difficult",false)
		"finesse_shot": return kind == "shot" and c.get("curve",0.0) > 0
		"first_time_finish": return kind == "shot" and c.get("first_time",false)
		"power_strike": return kind == "shot" and c.get("pressure",1.0) < 0.3 and not c.get("first_time",false) and not c.get("prepared",false)
		"poacher": return kind == "receive" and c.get("box",false) and c.get("rebound",false)
		"aerial_finisher": return kind == "shot" and c.get("aerial",false)
		"dead_ball_artist": return kind in ["shot","pass"] and c.get("restart","") == "free_kick"
		"penalty_composure": return kind == "shot" and c.get("restart","") == "penalty"
		"long_throw_specialist": return kind == "pass" and c.get("restart","") == "throw_in" and c.get("length",0.0) > 20
		"super_sub": return kind == "entry"
	return false

static func activate(m, id: int, context: Dictionary) -> Dictionary:
	var player = m.players[id]
	var trait_id: String = player.card.trait_id
	if not catalogue.has(trait_id) or not eligible(trait_id,context): return {}
	if player.role not in catalogue[trait_id].positions: return {}
	if player.trait_uses >= 3 or m.active_ticks < player.trait_ready: return {}
	if player.trait_state.get("state","") == "active": return {}
	player.trait_uses += 1
	player.trait_ready = m.active_ticks+roundi(m.regulation_ticks/9.0)
	player.stamina = maxf(0,player.stamina-2)
	m.action_id += 1
	var parameters: Dictionary = catalogue[trait_id].parameters.duplicate(true)
	var duration := roundi(float(parameters.get("duration_seconds",0.8))*60)
	if parameters.has("duration_match_minutes"): duration = roundi(m.regulation_ticks*float(parameters.duration_match_minutes)/90)
	player.trait_state = {"trait":trait_id,"action":m.action_id,"state":"active","kind":context.kind,"parameters":parameters,"started":m.active_ticks,"expires":m.active_ticks+duration,"position":player.position,"actor_card":player.card.card_id}
	if context.kind == "run" and parameters.has("reaction_delay_multiplier"): player.run_ready_tick = m.active_ticks+roundi(12*float(parameters.reaction_delay_multiplier))
	m.emit_event("trait_activation",id,{"trait":trait_id,"action":m.action_id,"state":"active"})
	return player.trait_state

static func parameter(player, key: String, fallback: float = 1.0) -> float:
	if player.trait_state.get("state","") != "active": return fallback
	return float(player.trait_state.parameters.get(key,fallback))

static func bonus(player, key: String) -> float:
	if player.trait_state.get("state","") != "active": return 0
	return float(player.trait_state.parameters.get("bonus",0)) if player.trait_state.parameters.get("attribute","") == key else 0.0

static func resolve(m, id: int, action: int, outcome: String, reason: String) -> void:
	if id < 0: return
	var player = m.players[id]
	if player.trait_state.get("action",-1) != action or player.trait_state.get("state","") != "active": return
	player.trait_state.state = outcome
	player.trait_state.resolved = m.active_ticks
	m.emit_event("trait_result",id,{"trait":player.trait_state.trait,"action":action,"state":outcome,"reason":reason})

static func tick(m) -> void:
	for p in m.players:
		if p.trait_state.get("state","") != "active" or m.active_ticks < p.trait_state.expires: continue
		# Movement/touch windows expire neutrally. Flights resolve at actual contact/outcome.
		if p.trait_state.kind not in ["pass","shot"]: resolve(m,p.id,p.trait_state.action,"complete","window expired")

static func runs(m) -> void:
	for p in m.players:
		if not p.active: continue
		if p.position.distance_to(p.target) < 5: continue
		var space: float = p.position.distance_to(m.players[m.nearest(1-p.team,p.position)].position)
		var local: Vector2 = m.oriented(p.position,p.team)
		activate(m,p.id,{"kind":"run","job":p.job,"open":space > 5,"wide":absf(local.y-34) > 18,"inside":absf(m.oriented(p.target,p.team).y-34) < absf(local.y-34),"recovery":p.team != m.control_team() and m.active_ticks-m.transition_tick < 120,"covered":m.players[p.team*11+5].job == "screen counter"})

static func stop(m) -> void:
	for p in m.players:
		if p.trait_state.get("state","") == "active":
			resolve(m,p.id,p.trait_state.action,"failed" if p.trait_state.kind in ["pass","shot"] else "complete","play stopped")
