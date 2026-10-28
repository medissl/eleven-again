extends RefCounted
## Small utility decisions and interruptible intentions; no hidden score or matchup table.
const SHAPES := {"4-3-3":[Vector2(6,34),Vector2(25,9),Vector2(21,26),Vector2(21,43),Vector2(25,59),Vector2(42,34),Vector2(53,21),Vector2(53,47),Vector2(72,10),Vector2(77,34),Vector2(72,58)],"4-4-2":[Vector2(6,34),Vector2(24,9),Vector2(21,26),Vector2(21,43),Vector2(24,59),Vector2(52,10),Vector2(48,27),Vector2(48,43),Vector2(52,58),Vector2(76,27),Vector2(76,43)],"4-2-3-1":[Vector2(6,34),Vector2(24,9),Vector2(21,26),Vector2(21,43),Vector2(24,59),Vector2(42,24),Vector2(42,44),Vector2(65,34),Vector2(69,10),Vector2(80,34),Vector2(69,58)]}

static func late_risk(m, team: int) -> float:
	if m.display_minute() < 70: return 0.0
	if m.plans[team].late_risk == "trailing_attack" and m.scores[team] < m.scores[1-team]: return 1.0
	if m.plans[team].late_risk == "leading_caution" and m.scores[team] > m.scores[1-team]: return -1.0
	return 0.0

static func targets(m) -> void:
	var previous_jobs: Array = m.players.map(func(p): return p.job)
	var control: int = m.players[m.owner].team if m.owner >= 0 else (m.players[m.last_touch].team if m.last_touch >= 0 else m.restart_team)
	if not m.combination.is_empty() and (m.active_ticks > m.combination.expires or control != m.combination.team): m.combination.clear()
	for p in m.players:
		if not p.active: continue
		var plan = m.plans[p.team]
		var local: Vector2 = m.oriented(m.ball,p.team)
		var anchor: Vector2 = SHAPES[plan.formation][p.id%11]
		var attacking: bool = control == p.team
		var countering: bool = attacking and plan.attack == "counter" and m.active_ticks-m.transition_tick < 240
		var shift := (local.x-52.5)*0.4+(8 if attacking else -10)
		shift += late_risk(m,p.team)*5
		if not attacking and plan.defence == "deep_block": shift -= 10
		if not attacking and plan.defence == "high_press": shift += 8
		var target := Vector2(clampf(anchor.x+shift,10,96),clampf(34+(anchor.y-34)*plan.width+(local.y-34)*0.12,4,64))
		p.job = "support" if attacking else "hold shape"
		if p.role == "GK":
			target = Vector2(5.5,lerpf(34,clampf(local.y,27,41),clampf(m.attribute(p.id,"POS")/100,0.3,1)))
			if not attacking and local.x < 18 and absf(local.y-34) < 18: target.x = clampf(local.x-1.5,3,10)
			p.job = "cover goal"
		elif attacking:
			if p.role == "ST":
				target = Vector2(clampf(local.x+14,58,96),28 if local.y > 34 else 40)
				p.job = "depth run"
			elif p.role in ["LW","RW"]:
				target.x = clampf(local.x+(18 if countering else 12),48,95)
				if local.x > 60: target.y = 20 if p.role == "LW" else 48
				p.job = "width outlet"
			elif p.role in ["CM","AM"]:
				target = Vector2(clampf(local.x-(5 if plan.attack == "possession" else 11),28,84),clampf(local.y+(-10 if p.id%2 == 0 else 10),12,56))
				p.job = "triangle support"
			elif p.role == "DM":
				target = Vector2(clampf(local.x-17,24,65),lerpf(local.y,34,0.65))
				p.job = "screen counter"
			elif p.role in ["LB","RB"] and local.x > 60 and absf(local.y-34) > 14 and ((p.role == "LB") == (local.y < 34)):
				target.x = clampf(local.x+6,45,91)
				p.job = "overlap"
			if plan.attack == "counter" and not countering and p.role in ["LB","RB","CM","DM"]: target.x -= 5
		p.target = m.oriented(target,p.team)
	if m.owner >= 0:
		var carrier = m.players[m.owner]
		var local: Vector2 = m.oriented(carrier.position,carrier.team)
		var target := Vector2(minf(local.x+9,101),lerpf(local.y,34,0.55 if local.x > 60 else 0.15))
		var ahead = m.players[m.nearest(1-carrier.team,carrier.position)]
		if carrier.position.distance_to(ahead.position) < 5 and (ahead.position.x-carrier.position.x)*m.direction(carrier.team) > 0: target.y = clampf(local.y+(-6 if local.y > 34 else 6),6,62)
		carrier.target = m.oriented(target,carrier.team)
		carrier.job = "carry"
		var chaser: int = m.nearest(1-carrier.team,m.ball,false)
		if m.plans[1-carrier.team].defence != "deep_block" or m.oriented(m.ball,1-carrier.team).x < 55:
			m.players[chaser].target = m.ball
			m.players[chaser].job = "press"
		var cover: int = m.nearest(1-carrier.team,m.ball,false,chaser)
		m.players[cover].target = (m.ball+m.oriented(Vector2(0,34),1-carrier.team))*0.5
		m.players[cover].job = "cover presser"
	elif m.ball_state in [m.BallState.LOOSE,m.BallState.FLIGHT]:
		for team in 2:
			var target: Vector2 = m.ball if m.ball_state == m.BallState.LOOSE else m.flight_target
			var chaser: int = m.nearest(team,target,false,m.kickoff_kicker)
			m.players[chaser].target = target
			m.players[chaser].job = "receive" if team == control else "intercept"
			var keeper = m.players[m.keeper_id(team)]
			if team != control and m.flight_kind != "shot" and m.oriented(target,team).x < 23 and keeper.position.distance_to(target) < m.players[chaser].position.distance_to(target):
				keeper.target = target
				keeper.job = "sweep"
	if not m.combination.is_empty():
		for key in ["passer","third"]:
			var p = m.players[m.combination[key]]
			if p.id == m.owner: continue
			var local: Vector2 = m.oriented(p.position,p.team)
			p.target = m.oriented(Vector2(minf(local.x+12,96),clampf(local.y+(-5 if key == "third" else 4),10,58)),p.team)
			p.job = "third-man run" if key == "third" else "one-two run"
	for p in m.players:
		if p.job == "third-man run" and previous_jobs[p.id] != p.job: p.run_ready_tick = m.active_ticks+12

static func action(m) -> void:
	if m.owner < 0: return
	var carrier = m.players[m.owner]
	var plan = m.plans[carrier.team]
	var near = m.players[m.nearest(1-carrier.team,carrier.position)]
	var pressure := clampf(1-near.position.distance_to(carrier.position)/6,0,1)
	var quality: float = m.chance_quality(carrier.position,carrier.team)
	var local: Vector2 = m.oriented(carrier.position,carrier.team)
	var best := -1
	var value := 6.0+quality*5-pressure*3
	var shot: float = 25*quality*(0.4+m.attribute(carrier.id,"SHO")/200)-pressure*2-m.lane_risk(m.ball,m.oriented(Vector2(105,34),carrier.team),carrier.team,true)*4
	shot += late_risk(m,carrier.team)*2
	if carrier.role != "GK" and quality > 0.30 and absf(local.y-34) < 23 and shot > value:
		best = -2
		value = shot
	var kind := "pass"
	for p in m.players:
		if not p.active or p.team != carrier.team or p.id == carrier.id or m.Offside.positioned(m,p.id,carrier.team): continue
		var length: float = p.position.distance_to(carrier.position)
		if length < 5 or length > (56 if plan.attack == "direct" else 43): continue
		var progress: float = (p.position.x-carrier.position.x)*m.direction(carrier.team)
		var risk: float = m.lane_risk(m.ball,p.position,carrier.team)
		var space := minf(12,p.position.distance_to(m.players[m.nearest(1-p.team,p.position)].position))
		var candidate: float = progress*(0.55 if plan.attack == "direct" else 0.35)+space*0.55+(m.chance_quality(p.position,p.team)-quality)*18-length*0.10-risk*14
		candidate *= 0.75+m.attribute(carrier.id,"PAS")/300
		if plan.attack == "possession" and length < 20: candidate += 3
		if plan.route == "combinations" and length < 18: candidate += 2
		candidate += progress*late_risk(m,carrier.team)*0.12
		if plan.attack == "counter" and m.active_ticks-m.transition_tick < 240 and progress > 5: candidate += 5
		var delivery := "through" if progress > 12 else "pass"
		if m.keeper_hand_owner == carrier.id and length <= 26*(1.12 if carrier.card.trait_id == "long_throw" and carrier.trait_uses < 3 and m.active_ticks >= carrier.trait_ready else 1): delivery = "keeper_throw"
		if absf(local.y-34) > 18 and local.x > 76 and absf(m.oriented(p.position,p.team).y-34) < 16:
			delivery = "cutback" if progress < 0 else "cross"
			candidate += 5 if plan.route == "wide" else 2
		if not m.combination.is_empty() and carrier.id == m.combination.bounce and p.id in [m.combination.passer,m.combination.third] and progress > 2 and risk < 0.55:
			candidate += 6
			delivery = "one_two"
		candidate += m.rng.randf_range(-1,1)
		if candidate > value or (carrier.role == "GK" and best == -1):
			best = p.id
			value = candidate
			kind = delivery
	if best == -2: m.shoot(pressure)
	elif best >= 0: m.pass_to(best,pressure,kind)
