extends RefCounted

static func foul(m, offender: int, victim: int, severity: int) -> void:
	if m.ball_state == m.BallState.DEAD or not m.players[offender].active: return
	var defender = m.players[offender]
	var attacker = m.players[victim]
	var dismissed_role: String = defender.role
	var incident: Vector2 = m.ball
	m.fouls[defender.team] += 1
	m.emit_event("foul",offender,{"victim":victim,"victim_name":attacker.name})
	if severity == 1:
		defender.yellows += 1
		m.emit_event("yellow_card",offender)
	if severity >= 2 or defender.yellows >= 2:
		defender.active = false
		m.emit_event("red_card",offender,{"second_yellow":severity < 2})
		if defender.role == "GK": replace_keeper(m,defender.team)
		var remaining: int = m.players.filter(func(p): return p.active and p.team == defender.team).size()
		if remaining < 7:
			m.forfeit_team = defender.team
			m.finished = true
			m.period = m.Period.FULL_TIME
			m.start_restart(1-defender.team,incident,"forfeit",0)
			m.emit_event("forfeit",offender)
			m.result_report = m.snapshot_report()
			return
		if dismissed_role in ["CB","LB","RB","DM"]:
			var replacement := -1
			for p in m.players:
				if not p.active or p.team != defender.team or p.role not in ["CM","DM","AM"]: continue
				if replacement < 0 or m.attribute(p.id,"DEF") > m.attribute(replacement,"DEF"): replacement = p.id
			if replacement >= 0:
				m.players[replacement].role = dismissed_role
				m.players[replacement].anchor_override = defender.anchor_override if defender.anchor_override.x >= 0 else m.FootballAI.SHAPES[m.plans[defender.team].formation][offender%11]
				m.emit_event("reshuffle",replacement,{"assigned_role":dismissed_role})
	var local: Vector2 = m.oriented(incident,defender.team)
	if local.x < 16.5 and absf(local.y-34) < 20.16:
		m.award_restart(attacker.team,m.oriented(Vector2(11,34),defender.team),"penalty",offender)
	else: m.award_restart(attacker.team,incident,"free_kick",offender)

static func replace_keeper(m, team: int) -> void:
	var plan = m.plans[team]
	if m.substitution_counts[team] < 5 and m.substitution_windows[team] < 3:
		for index in plan.bench_order:
			var card = plan.cards[index]
			if "GK" not in card.natural_roles or card.card_id in m.used_cards[team]: continue
			for slot in range(10,0,-1):
				var leaving = m.players[team*11+slot]
				if not leaving.active: continue
				var keeper = m.players[team*11]
				m.load_card(keeper,card)
				keeper.active = true
				keeper.yellows = 0
				keeper.entered_tick = m.active_ticks
				keeper.trait_state.clear()
				leaving.active = false
				m.used_cards[team].append(card.card_id)
				m.substitution_counts[team] += 1
				m.substitution_windows[team] += 1
				m.emit_event("substitution",keeper.id,{"out_name":leaving.name,"out_card":leaving.card.card_id,"in_card":card.card_id})
				return
	var best := -1
	for p in m.players:
		if p.team == team and p.active and (best < 0 or p.physical > m.players[best].physical): best = p.id
	if best >= 0:
		m.players[best].role = "GK"
		m.emit_event("emergency_keeper",best)
