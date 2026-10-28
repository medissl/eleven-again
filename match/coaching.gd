extends RefCounted
## Contextual action bonuses only; no RNG, animation, permanent ratings or extra fatigue path.
const IDS := ["short_combinations","wide_service","counter_runners","first_pressure","set_piece_preparation","bench_impact"]

static func bonus(m, id: int, key: String, context: Dictionary) -> float:
	var player = m.players[id]
	if not player.active: return 0
	var owned: Array = m.principles[player.team]
	if owned.is_empty(): return 0
	var kind: String = context.get("kind","")
	var local: Vector2 = m.oriented(player.position,player.team)
	var value := 0.0
	if key == "PAS" and kind == "pass":
		if "short_combinations" in owned and context.get("ground",false) and local.x < 70: value += 3
		if "wide_service" in owned and context.get("delivery","") == "cross": value += 3
	if key == "PAC" and "counter_runners" in owned and m.last_control_team == player.team and m.active_ticks >= m.transition_tick and m.active_ticks-m.transition_tick < 120 and m.ball_state not in [m.BallState.DEAD,m.BallState.KICKOFF]: value += 3
	if key == "DEF" and "first_pressure" in owned and kind == "standing_tackle" and local.x >= 70 and m.plans[player.team].defence == "high_press": value += 3
	if key == "SHO" and "set_piece_preparation" in owned and kind == "shot" and (context.get("restart","") == "free_kick" or (context.get("aerial",false) and context.get("from_corner",false))): value += 3
	if key == "PHY" and "bench_impact" in owned and player.entered_tick >= 0: value += 3
	return value

static func valid(value: Variant) -> bool:
	if value is not Array or value.size() != 2: return false
	for team in value:
		if team is not Array or team.size() > 2: return false
		var seen := []
		for id in team:
			if id not in IDS or id in seen: return false
			seen.append(id)
	return true
