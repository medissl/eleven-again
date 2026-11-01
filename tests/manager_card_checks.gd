extends SceneTree
const Match=preload("res://match/match_sim.gd")
const Managers=preload("res://match/manager_cards.gd")
const Snapshot=preload("res://match/match_snapshot.gd")
func _initialize() -> void:
	for id in Managers.BASE_IDS:
		assert(preload("res://ui/ability_icons.gd").PATHS.has(Managers.DEFINITIONS[id].icon))
		var m := Match.new(42,180,null,null,true)
		m.manager_cards=[[id],[]]
		m.analytics=Match.Analytics.empty(true)
		var actor := 6
		m.players[actor].role="CM"
		var kind := "shot_accuracy"
		var context := {}
		match id:
			"lightning_counter":
				Managers.control(m,actor,"interception")
				var pass_bonus := Managers.contributions(m,actor,"pass_accuracy",{"progress":10})
				assert(pass_bonus.size() == 1 and pass_bonus[0].amount == 0.06)
				Managers.pass_started(m,actor,{"progress":10,"central":true,"length":20,"delivery":"pass","wide":false})
				Managers.control(m,7,"received")
			"one_touch":
				for index in 3:
					Managers.pass_started(m,actor,{"progress":10,"central":true,"length":20,"delivery":"pass","wide":false})
					Managers.control(m,7,"received")
			"iron_wall":
				m.players[actor].role="DM"; kind="interception_control"
				assert(Managers.contributions(m,actor,"shot_accuracy",{}).is_empty())
			"wide_overload":
				kind="pass_accuracy"; context={"delivery":"cross"}
				Managers.pass_started(m,actor,{"progress":10,"central":false,"length":20,"delivery":"pass","wide":true})
				Managers.control(m,7,"received")
				assert(Managers.pass_preference(m,0,false) < 0)
			"dead_ball": context={"restart":"free_kick"}
			"high_press": kind="interception_control"; assert(Managers.fatigue(m,0) > 1)
			"deep_playmaker":
				Managers.pass_started(m,actor,{"progress":30,"central":true,"length":30,"delivery":"pass","wide":false})
				Managers.control(m,7,"received")
			"last_stand":
				m.active_ticks=9000; m.scores=[0,1]
				assert(Managers.contributions(m,actor,"receive_control",{})[0].amount == -0.04)
		var value: float=m.probability(actor,kind,0.6,0.68,context)
		assert(value > 0.68 and value <= 0.72+0.00001,"Actual shared probability budget: "+id)
		var trace: Dictionary=m.analytics.probabilities.back()
		assert(trace.sources.any(func(source): return source.id == id and source.applied > 0),"Actual applied provenance: "+id)
		var resumed=Snapshot.restore(Snapshot.capture(m))
		assert(resumed != null and resumed.manager_cards == m.manager_cards and resumed.manager_state == m.manager_state)
		# Losing possession removes pending benefits without refilling per-half charges.
		Managers.control(m,17,"interception")
		assert(m.manager_state[0].streak == 0 and m.manager_state[0].deep_shot == -1 and m.manager_state[0].counter_shot == -1)
		if id == "one_touch": assert(m.manager_state[0].one_touch_uses == 1)
		if id == "last_stand": m.scores=[1,0]
		elif id == "high_press": m.active_ticks=5000
		elif id == "iron_wall": m.players[actor].role="ST"
		elif id == "dead_ball": context={}
		assert(Managers.contributions(m,actor,kind,context).is_empty(),"Counterplay/reset removes effect: "+id)
	for id in Managers.TACTIC_IDS+Managers.COMBO_IDS:
		var m := Match.new(42,180)
		for player in m.players:
			player.card=preload("res://content/player_card.gd").from_data(player.card.to_data())
			player.card.trait_id=""
		m.manager_cards=[[id],[]]; m.analytics=Match.Analytics.empty(true)
		var actor := 6
		var kind := "pass_accuracy"
		var context := {}
		match id:
			"keeper_outlet": actor=0; context={"length":30}
			"cutback_pattern": context={"delivery":"cutback"}
			"aerial_duel": kind="aerial_contest"
			"passing_triangle":
				context={"central":true}; m.players[5].card.trait_id="anchor"; m.players[6].card.trait_id="bullet_pass"
			"wing_partnership":
				context={"delivery":"cross"}; m.players[1].card.trait_id="overlap_engine"; m.players[8].card.trait_id="cut_inside"
			"last_line":
				kind="interception_control"; m.players[2].card.trait_id="anticipator"; m.players[5].card.trait_id="anchor"
		assert(m.probability(actor,kind,0.6,0.6,context) > 0.6,"Unlocked option has a real bounded action effect: "+id)
		assert(m.analytics.probabilities.back().sources.any(func(source): return source.id == id and source.applied > 0))
		if id == "keeper_outlet": m.players[0].role="CM"
		elif id == "cutback_pattern": context={}
		elif id == "passing_triangle": m.players[5].active=false
		elif id == "wing_partnership": m.players[1].active=false
		elif id == "last_line": m.players[2].active=false
		else: kind="shot_accuracy"
		assert(Managers.contributions(m,actor,kind,context).is_empty(),"Unlocked option requires its real conditions: "+id)
	# Live action path, snapshot resume and Manager state parity through real football.
	var tempo := Match.new(42,180)
	tempo.manager_cards=[["iron_wall"],[]]
	var accumulated := 0
	for touch in 1000:
		tempo.players[6].ready_tick=tempo.active_ticks+16
		Managers.control(tempo,6,"received")
		accumulated+=tempo.players[6].ready_tick-tempo.active_ticks-16
	assert(absf(accumulated-1000*16*0.03) <= 1,"3% tempo uses fractional ticks, not a whole-tick penalty on each touch")
	var native := Match.new(47,12,null,null,true)
	native.analytics=Match.Analytics.empty(true)
	native.manager_cards=[["high_press","wide_overload","last_stand"],[]]
	for tick in 400: native.step()
	var resumed=Snapshot.restore(Snapshot.capture(native))
	assert(resumed != null)
	for tick in 600:
		if native.period == Match.Period.HALF_TIME: native.acknowledge_halftime(); resumed.acknowledge_halftime()
		native.step(); resumed.step()
		assert(native.signature() == resumed.signature() and native.analytics == resumed.analytics)
	native.kickoff_kicker=-1
	native.take_control(8)
	native.manager_state[0].wide_until=native.active_ticks+180
	native.pass_to(9,0,"cross")
	assert(native.analytics.probabilities.back().sources.any(func(source): return source.id == "wide_overload" and source.applied > 0),"Cross actually uses the Manager probability pipeline")
	print("MANAGER CARDS: eight base plus six unlocked eligibility/effect/reset/cap cases, exact tempo tradeoff, actual probability provenance and native save continuation passed")
	quit()
