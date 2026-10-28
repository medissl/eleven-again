extends RefCounted
const Match = preload("res://match/match_sim.gd")
const Traits = preload("res://match/traits.gd")
const OPPORTUNITIES := {
	"deflector":{"kind":"parry"},"safe_hands":{"kind":"save","pressure":0.1},"cat_reflexes":{"kind":"save","distance":12.0},"sweeper_keeper":{"kind":"run","job":"sweep"},"long_throw":{"kind":"pass","delivery":"keeper_throw","hand_control":true,"risk":0.1,"length":27.0},
	"hard_tackle":{"kind":"tackle","legal_angle":true},"anticipator":{"kind":"respond","reachable":true},"aerial_fortress":{"kind":"aerial","defending":true},"body_block":{"kind":"block","reachable":true},
	"accelerator":{"kind":"run","job":"carry","open":true},"whipped_cross":{"kind":"pass","delivery":"cross"},"recovery_sprint":{"kind":"run","recovery":true},"overlap_engine":{"kind":"run","job":"overlap","covered":true},
	"screen":{"kind":"receive","interception":true,"central":true},"anchor":{"kind":"shield","pressure":0.8},"switch_play":{"kind":"pass","lateral":30.0,"risk":0.1},"bullet_pass":{"kind":"pass","length":25.0,"delivery":"pass"},
	"wall_pass":{"kind":"receive","bounce":true},"tempo_setter":{"kind":"receive","pressure":0.1,"recycle":true},"press_resistant":{"kind":"receive","opponents":2},"threader":{"kind":"pass","progress":20.0,"delivery":"through"},
	"third_man":{"kind":"run","job":"third-man run"},"turn_and_go":{"kind":"receive","open":true},"touchline_burst":{"kind":"run","job":"carry","wide":true,"open":true},"cutback":{"kind":"pass","delivery":"cutback","risk":0.1},"cut_inside":{"kind":"run","job":"carry","inside":true,"open":true},"close_control":{"kind":"receive","difficult":true},
	"finesse_shot":{"kind":"shot","curve":1.6},"first_time_finish":{"kind":"shot","first_time":true},"power_strike":{"kind":"shot","pressure":0.1},"poacher":{"kind":"receive","box":true,"rebound":true},"aerial_finisher":{"kind":"shot","aerial":true},"dead_ball_artist":{"kind":"pass","restart":"free_kick"},"penalty_composure":{"kind":"shot","restart":"penalty"},"long_throw_specialist":{"kind":"pass","restart":"throw_in","length":28.0},"super_sub":{"kind":"entry"}}

func run(check: Callable) -> void:
	check.call(Traits.catalogue.size() == 36 and OPPORTUNITIES.size() == 36, "every researched trait has an explicit legal opportunity scenario")
	for ability in OPPORTUNITIES:
		var model := Match.new(42)
		var actor := 0
		for p in model.players:
			if p.role in Traits.catalogue[ability].positions:
				actor = p.id
				break
		var player = model.players[actor]
		player.card.trait_id = ability
		var rng_before: int = model.rng.state
		check.call(Traits.activate(model,actor,{"kind":"unrelated"}).is_empty(), ability+" rejects an irrelevant action")
		var activation := Traits.activate(model,actor,OPPORTUNITIES[ability])
		check.call(not activation.is_empty() and player.trait_uses == 1 and player.stamina == 98, ability+" commits one bounded activation")
		var before: Array = model.signature()
		check.call(Traits.activate(model,actor,OPPORTUNITIES[ability]).is_empty() and model.signature() == before, ability+" cannot stack or consume twice")
		check.call(model.rng.state == rng_before, ability+" activation never draws an outcome lottery")
		Traits.resolve(model,actor,activation.action,"failed","authored counterplay")
		var count: int = model.events.size()
		Traits.resolve(model,actor,activation.action,"success","duplicate callback")
		check.call(model.events.size() == count and player.trait_uses == 1, ability+" failure consumes use and resolution is idempotent")
		check.call(Traits.activate(model,actor,OPPORTUNITIES[ability]).is_empty(), ability+" respects cooldown")
		player.trait_uses = 3
		player.trait_ready = 0
		check.call(Traits.activate(model,actor,OPPORTUNITIES[ability]).is_empty(), ability+" respects fixture budget")
	var normal := pass_fixture("")
	var bullet := pass_fixture("bullet_pass")
	check.call(bullet.ball_velocity.length() > normal.ball_velocity.length() and bullet.ball_velocity.length() <= 34, "Bullet Pass changes actual bounded ball speed")
	var ordinary := shot_fixture("")
	var finesse := shot_fixture("finesse_shot")
	check.call(absf(finesse.flight_curve) > absf(ordinary.flight_curve), "Finesse Shot changes the actual curve, not just a trail")
	for tick in 8:
		ordinary.advance_flight()
		finesse.advance_flight()
	check.call(not ordinary.ball.is_equal_approx(finesse.ball), "curved trait changes real ball positions")
	var power := shot_fixture("power_strike",Vector2(88,34))
	check.call(not power.pending_shot.is_empty() and power.shots[0] == 0, "Power Strike pays a real windup before shooting")
	var model := Match.new(42)
	model.players[6].card.trait_id = "threader"
	Traits.activate(model,6,{"kind":"pass","progress":20.0,"delivery":"through"})
	var value: float = model.attribute(6,"PAS",99)
	check.call(value <= (model.players[6].passing+6)*(0.88+0.12*0.98), "combined attribute bonuses share the +6 cap")

func pass_fixture(ability: String) -> RefCounted:
	var m := Match.new(42)
	for p in m.players:
		p.position = Vector2(5+p.id*3,5)
		p.target = p.position
	m.players[6].position = Vector2(40,34)
	m.players[7].position = Vector2(65,34)
	m.players[7].target = m.players[7].position
	m.players[6].card.trait_id = ability
	m.take_control(6)
	m.pass_to(7)
	return m

func shot_fixture(ability: String, position: Vector2 = Vector2(88,25)) -> RefCounted:
	var m := Match.new(42)
	for p in m.players: p.position = Vector2(10,5+p.id*2)
	m.players[9].position = position
	m.players[9].card.trait_id = ability
	m.take_control(9)
	m.shoot()
	return m
