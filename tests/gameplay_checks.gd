extends RefCounted
const Match = preload("res://match/match_sim.gd")
const Card = preload("res://content/player_card.gd")

func run(check: Callable) -> void:
	var roster = load("res://content/exhibition_roster.tres")
	check.call(roster.cards.size() == 32 and roster.errors().is_empty(), "authored Resources have stable unique identities and valid attributes")
	var specialists = load("res://content/specialist_roster.tres")
	check.call(specialists.cards.size() == 16 and specialists.errors().is_empty(), "specialist fixture squad validates")
	var represented := {}
	for card in roster.cards+specialists.cards: represented[card.trait_id] = true
	check.call(represented.size() == 36, "all 36 specialties are represented by selectable fixture cards")
	var card := Card.new()
	card.person_id = "test"
	card.card_id = "test_base"
	card.display_name = "Test"
	card.natural_roles = ["CM"]
	card.familiar_roles = ["DM"]
	check.call(card.rating() == 70 and card.tier() == "silver", "card OVR derives from actual role weights and four tiers")
	card.attributes.PAS = 84.9
	check.call(not card.errors().is_empty(), "invalid fractional authored stats are rejected")
	card.attributes.PAS = 70
	var model := Match.new(42)
	model.players[6].card = card
	model.players[6].role = "DM"
	model.players[6].passing = 100
	check.call(is_equal_approx(model.attribute(6,"PAS"),95), "familiar-role penalty applies exactly once")
	model.players[6].stamina = 0
	check.call(is_equal_approx(model.attribute(6,"PAS"),83.6), "fatigue has a capped twelve-percent penalty")
	check.call(model.attribute(9,"REF") == 35, "emergency keeper does not inherit outfield OVR")
	var low := Match.new(1)
	var high := Match.new(1)
	for pair in [[low,60],[high,100]]:
		var sim = pair[0]
		for p in sim.players:
			p.position = Vector2(5+p.id*4,8)
			p.previous = p.position
			p.target = p.position
		sim.players[6].pace = pair[1]
		sim.players[6].target = sim.players[6].position+Vector2(20,0)
		for tick in 60: sim.move_players()
	check.call(high.players[6].position.x > low.players[6].position.x, "higher PAC improves the same actual run")
	var base: Dictionary = roster.cards[6].attributes.duplicate()
	model.players[6].stamina = 50
	model.attribute(6,"PAS",6)
	check.call(roster.cards[6].attributes == base, "effective attributes never mutate shared card Resources")
	var Lineup = load("res://squad/lineup.gd")
	var plan = Lineup.exhibition(0)
	check.call(plan.errors().is_empty(), "default authored preparation is legal")
	plan.starters[1] = plan.starters[2]
	check.call(not plan.errors().is_empty(), "duplicate lineup selections are rejected")
	plan = Lineup.exhibition(0)
	var committed := Match.new(42,180,plan)
	plan.attack = "counter"
	check.call(committed.plans[0].attack == "possession", "submitted preparation is isolated from later edits")
	for attack in ["possession","direct","counter"]:
		for defence in ["high_press","balanced","deep_block"]:
			plan.attack = attack
			plan.defence = defence
			check.call(plan.errors().is_empty(), "all nine tactical combinations are legal")
	var compact := Match.new(42)
	compact.take_control(9)
	compact.plans[1].defence = "deep_block"
	compact.choose_targets()
	var deep_target: Vector2 = compact.players[13].target
	compact.plans[1].defence = "high_press"
	compact.choose_targets()
	check.call(compact.players[13].target.x < deep_target.x, "high press actually advances the opposing defensive line")
	check.call(compact.players.filter(func(p): return p.job == "press").size() <= 1, "one elected presser preserves team shape")
	var subs := Match.new(42)
	subs.active_ticks = roundi(subs.regulation_ticks*60.0/90)
	for p in subs.players: p.stamina = 50
	subs.Substitutions.apply(subs)
	check.call(subs.substitution_counts[0] > 0 and subs.substitution_counts[0] <= 3 and subs.substitution_windows[0] == 1, "balanced template makes bounded actual changes in one window")
	var first_window: int = subs.substitution_counts[0]
	subs.Substitutions.apply(subs)
	check.call(subs.substitution_counts[0] == first_window, "same stoppage cannot replay a substitution window")
	for p in subs.players:
		if p.entered_tick >= 0: check.call(p.stamina >= 98 and p.trait_uses <= 1, "substitutes enter fresh with only real entry-trait cost")
	var Snapshot = load("res://match/match_snapshot.gd")
	for stage in ["kickoff","flight","dead","trait","substitution"]:
		var original := Match.new(42)
		if stage == "flight":
			for tick in 15: original.step()
		elif stage == "dead":
			original.take_control(9)
			original.goal_scored(9)
		elif stage == "trait": original.Traits.activate(original,1,{"kind":"run","job":"carry","open":true})
		elif stage == "substitution":
			original.active_ticks = original.regulation_ticks*2/3
			for p in original.players: p.stamina = 50
			original.Substitutions.apply(original)
		var encoded: Dictionary = bytes_to_var(var_to_bytes(original.snapshot()))
		var restored: RefCounted = Snapshot.restore(encoded)
		check.call(restored != null, stage+" snapshot restores")
		if restored == null: continue
		check.call(restored.snapshot() == original.snapshot(), stage+" snapshot includes complete match/card/trait/RNG state")
		for tick in 180:
			original.acknowledge_halftime()
			restored.acknowledge_halftime()
			original.step()
			restored.step()
		check.call(restored.signature() == original.signature(), stage+" resume preserves subsequent actions and RNG")
	check.call(Snapshot.restore({"schema":999}) == null, "incompatible snapshots are rejected")
