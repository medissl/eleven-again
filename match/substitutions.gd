extends RefCounted
## Windows are consumed by an actual group of legal replacements, never by a skipped plan.
static func apply(m, halftime: bool = false) -> void:
	for team in 2:
		if m.substitution_counts[team] >= 5 or (not halftime and m.substitution_windows[team] >= 3): continue
		var plan = m.plans[team]
		var minute: int = m.display_minute()
		var stage: int = m.substitution_stages[team]
		var threshold := (60 if stage == 0 else 75) if plan.substitution_plan == "balanced" else ((55 if stage == 0 else 70) if plan.substitution_plan == "fresh_legs" else (65 if stage == 0 else 78))
		if minute < threshold or stage >= 2: continue
		var candidates: Array = []
		for slot in range(1,11): candidates.append(team*11+slot)
		candidates.sort_custom(func(a,b): return m.players[a].stamina < m.players[b].stamina)
		var changed := 0
		for id in candidates:
			if changed >= (3 if stage == 0 else 2) or m.substitution_counts[team] >= 5: break
			var player = m.players[id]
			if not player.active or player.role == "GK": continue
			if plan.substitution_plan == "fresh_legs" and player.stamina >= (55 if stage == 0 else 45): continue
			if plan.substitution_plan == "protect_shape" and player.stamina > 75: continue
			var replacement := -1
			var quality := -INF
			var pinned: int = plan.pinned_replacements.get(id%11,-1)
			for index in plan.bench_order:
				if index < 0 or index >= plan.cards.size() or index in plan.starters or plan.cards[index].card_id in m.used_cards[team]: continue
				if pinned >= 0 and index != pinned: continue
				var card = plan.cards[index]
				if player.role not in card.natural_roles+card.familiar_roles: continue
				var candidate: float = card.rating(player.role,true)
				if candidate < player.card.rating(player.role,true)*(0.88+0.12*player.stamina/100.0)*0.9: continue
				if candidate > quality:
					replacement = index
					quality = candidate
			if replacement < 0: continue
			var old_name: String = player.name
			var old_card: String = player.card.card_id
			m.load_card(player,plan.cards[replacement])
			player.entered_tick = m.active_ticks
			player.trait_state.clear()
			m.used_cards[team].append(player.card.card_id)
			m.substitution_counts[team] += 1
			changed += 1
			m.emit_event("substitution",id,{"out_name":old_name,"out_card":old_card,"in_card":player.card.card_id})
			m.Traits.activate(m,id,{"kind":"entry"})
		if changed > 0:
			if not halftime: m.substitution_windows[team] += 1
			m.substitution_stages[team] += 1
