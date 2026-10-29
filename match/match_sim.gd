extends RefCounted
## The match owns outcomes. Rendering and commentary only consume this state.
const BallRules = preload("res://match/ball_rules.gd")
const Roster = preload("res://content/exhibition_roster.tres")
const Lineup = preload("res://squad/lineup.gd")
const FootballAI = preload("res://match/football_ai.gd")
const Substitutions = preload("res://match/substitutions.gd")
const Traits = preload("res://match/traits.gd")
const Offside = preload("res://match/offside.gd")
const Discipline = preload("res://match/discipline.gd")
const Shootout = preload("res://match/shootout.gd")
const Restarts = preload("res://match/restarts.gd")
const Coaching = preload("res://match/coaching.gd")
const ATTRIBUTE_FIELDS := {"PAC":"pace","SHO":"shooting","PAS":"passing","DRI":"dribbling","DEF":"defence","PHY":"physical","REF":"reflexes","HAN":"handling","POS":"positioning","DIV":"diving","KIC":"kicking"}

enum BallState { CONTROLLED, FLIGHT, LOOSE, DEAD, KICKOFF }
enum Period { FIRST_HALF, HALF_TIME, SECOND_HALF, FULL_TIME, EXTRA_FIRST, EXTRA_SECOND, SHOOTOUT }
const DT := 1.0 / 60.0
const FIELD := Vector2(105, 68)
const REGULATION_SECONDS := 180
const KICKOFF_SETUP_TICKS := 12
const CENTRE := FIELD / 2
const MOVEMENT_TEMPO := 1.0
const ANCHORS := [Vector2(6, 34), Vector2(25, 9), Vector2(21, 26),
	Vector2(21, 43), Vector2(25, 59), Vector2(42, 34), Vector2(53, 21),
	Vector2(53, 47), Vector2(72, 10), Vector2(77, 34), Vector2(72, 58)]
const NAMES := ["Ward", "Hart", "Okoro", "Silva", "Sato", "Reed", "Costa",
	"Idris", "Bima", "Arden", "Noor", "Novak", "Park", "Dube", "Bauer",
	"Chen", "Vega", "Musa", "Leone", "Ilyas", "Moreau", "Rossi"]

class Footballer:
	extends RefCounted
	var id: int
	var team: int
	var name: String
	var position: Vector2
	var previous: Vector2
	var target: Vector2
	var pace: int
	var passing: int
	var shooting: int
	var defence: int
	var dribbling: int
	var keeping: int
	var physical: int
	var reflexes: int
	var handling: int
	var positioning: int
	var diving: int
	var kicking: int
	var card: Resource
	var role := ""
	var stamina := 100.0
	var velocity := Vector2.ZERO
	var facing := Vector2.RIGHT
	var ready_tick := 0
	var job := "hold shape"
	var entered_tick := -1
	var trait_state: Dictionary = {}
	var trait_uses := 0
	var trait_ready := 0
	var response_delay := 0
	var run_ready_tick := 0
	var cooldown := 0
	var active := true
	var yellows := 0
	var shootout_trait_used := false
	var anchor_override := Vector2(-1,-1)

var players: Array[Footballer] = []
var rng := RandomNumberGenerator.new()
var match_seed: int
var ticks := 0
var active_ticks := 0
var ball_state := BallState.CONTROLLED
var ball := Vector2(52.5, 34)
var previous_ball := ball
var owner := 9
var last_touch := -1
var held_ticks := 0
var scores := [0, 0]
var events: Array[Dictionary] = []
var possession_ticks := [0, 0]
var pass_attempts := [0, 0]
var completed_passes := [0, 0]
var tackles := [0, 0]
var ball_velocity := Vector2.ZERO
var flight_target := Vector2.ZERO
var flight_source := -1
var flight_kind := "pass"
var pass_pending := false
var shots := [0, 0]
var shots_on_target := [0, 0]
var saves := [0, 0]
var shot_quality := 0.0
var keeper_tested := false
var dead_ticks := 0
var restart_team := 0
var period := Period.FIRST_HALF
var finished := false
var restart_kind := "kickoff"
var restart_position := Vector2(52.5, 34)
var regulation_ticks := REGULATION_SECONDS * 60
var halftime_report: Dictionary = {}
var result_report: Dictionary = {}
var kickoff_taker := -1
var kickoff_ticks := 0
var kickoff_kicker := -1
var ball_height := 0.0
var restart_taker := -1
var restart_counts := {"throw_in": [0,0], "corner": [0,0], "goal_kick": [0,0], "free_kick": [0,0]}
var fouls := [0,0]
var plans: Array[Resource] = []
var combination: Dictionary = {}
var transition_tick := -1000
var flight_delivery := "pass"
var flight_receiver := -1
var substitution_counts := [0,0]
var substitution_windows := [0,0]
var substitution_stages := [0,0]
var used_cards: Array = [[],[]]
var action_id := 0
var flight_trait_actor := -1
var flight_trait_action := -1
var flight_ticks := 0
var flight_origin := Vector2.ZERO
var flight_control := Vector2.ZERO
var flight_duration := 1.0
var flight_curve := 0.0
var flight_peak := 0.0
var shot_context: Dictionary = {}
var pending_shot: Dictionary = {}
var current_restart := ""
var keeper_hand_owner := -1
var offside_context: Dictionary = {}
var restart_untouched := false
var restart_delivery := ""
var restart_kick_team := -1
var forfeit_team := -1
var flight_on_target_recorded := false
var knockout := false
var trait_allowance := 3
var shootout: Dictionary = {}
var last_control_team := -1
var flight_serial := 0
var period_extension := false
var period_extension_contact := false
var principles: Array = [[],[]]

func _init(seed_value: int = 11027, duration_seconds: int = REGULATION_SECONDS, home: Resource = null, away: Resource = null, resolve_ties: bool = false) -> void:
	match_seed = seed_value
	knockout = resolve_ties
	regulation_ticks = maxi(2, duration_seconds) * 60
	rng.seed = seed_value
	plans = [(Lineup.exhibition(0) if home == null else home).duplicate(true), (Lineup.exhibition(1) if away == null else away).duplicate(true)]
	assert(plans[0].errors().is_empty() and plans[1].errors().is_empty(), "Commit a legal lineup before kickoff")
	for id in 22:
		var p := Footballer.new()
		p.id = id
		p.team = int(id / 11.0)
		p.card = plans[p.team].cards[plans[p.team].starters[id%11]]
		p.role = Lineup.ROLES[plans[p.team].formation][id%11]
		load_card(p,p.card)
		players.append(p)
		used_cards[p.team].append(p.card.card_id)
	reset_shape(0)

func load_card(player: Footballer, card: Resource) -> void:
	player.card = card
	player.yellows = 0
	player.name = card.display_name
	for key in ATTRIBUTE_FIELDS:
		player.set(ATTRIBUTE_FIELDS[key], card.attributes[key] if card.attributes.has(key) else card.keeper_attributes[key])
	player.keeping = card.rating("GK") if player.role == "GK" else 35
	player.stamina = 100
	player.velocity = Vector2.ZERO
	player.trait_uses = 0
	player.trait_ready = 0
	player.facing = Vector2(direction(player.team),0)

func attribute(id: int, key: String, bonus: float = 0, context: Dictionary = {}) -> float:
	var p := players[id]
	var base: float = p.get(ATTRIBUTE_FIELDS[key])
	if key in ["REF","HAN","POS","DIV","KIC"] and "GK" not in p.card.natural_roles: base = 35
	var role_factor: float = p.card.familiarity(p.role) if p.role != "GK" else 1.0
	return clampf((base+clampf(bonus+Traits.bonus(p,key)+Coaching.bonus(self,id,key,context),0,6))*role_factor*(0.88+0.12*clampf(p.stamina/100.0,0,1)),1,120)

func control_team() -> int:
	return players[owner].team if owner >= 0 else (last_control_team if last_control_team >= 0 else restart_team)

func keeper_id(team: int) -> int:
	for p in players:
		if p.active and p.team == team and p.role == "GK": return p.id
	return team*11

func direction(team: int) -> float:
	if period == Period.SHOOTOUT: return 1.0 if team == shootout.get("team",0) else -1.0
	var first_half := 1.0 if team == 0 else -1.0
	return -first_half if period in [Period.SECOND_HALF,Period.FULL_TIME,Period.EXTRA_SECOND] else first_half

func oriented(point: Vector2, team: int) -> Vector2:
	return point if direction(team) > 0 else FIELD - point

func controlled_ball_position(id: int) -> Vector2:
	return players[id].position + players[id].facing * 1.7

func display_minute() -> int:
	return mini(120 if knockout and active_ticks > regulation_ticks else 90, int(active_ticks * 90.0 / regulation_ticks))

func reset_shape(kicking_team: int) -> void:
	last_control_team = kicking_team
	transition_tick = -1000
	restart_team = kicking_team
	restart_kind = "kickoff"
	restart_position = CENTRE
	for p in players:
		var anchor: Vector2 = FootballAI.SHAPES[plans[p.team].formation][p.id % 11]
		if p.anchor_override.x >= 0: anchor = p.anchor_override
		p.position = oriented(Vector2(anchor.x * 0.6, anchor.y), p.team)
		if p.team != kicking_team and p.position.distance_to(CENTRE) < 9.15:
			p.position = CENTRE + (p.position - CENTRE).normalized() * 9.15
		p.cooldown = 0
		p.velocity = Vector2.ZERO
		p.facing = Vector2(direction(p.team),0)
	kickoff_taker = kicking_team * 11 + 9
	if not players[kickoff_taker].active: kickoff_taker = nearest(kicking_team,CENTRE,false)
	# ponytail: one short opening routine; editable takers belong to squad preparation.
	players[kicking_team * 11 + 6].position = oriented(Vector2(44, 28), kicking_team)
	players[kickoff_taker].position = CENTRE - Vector2(direction(kicking_team) * 1.7, 0)
	for p in players:
		p.previous = p.position
		p.target = p.position
	owner = -1
	ball = CENTRE
	previous_ball = ball
	ball_state = BallState.KICKOFF
	kickoff_ticks = KICKOFF_SETUP_TICKS
	kickoff_kicker = -1
	held_ticks = 0
	ball_velocity = Vector2.ZERO
	pass_pending = false
	flight_source = -1
	keeper_tested = false
	combination.clear()
	emit_event("kickoff_setup", kickoff_taker)

func step() -> void:
	if finished or period == Period.HALF_TIME:
		return
	if period == Period.SHOOTOUT:
		Shootout.step(self)
		return
	ticks += 1
	previous_ball = ball
	for p in players:
		p.previous = p.position
		p.cooldown = maxi(0, p.cooldown - 1)
	if ball_state == BallState.KICKOFF:
		kickoff_ticks -= 1
		if kickoff_ticks > 0: return
		owner = kickoff_taker
		emit_event("kickoff", kickoff_taker)
		current_restart = "kickoff"
		pass_to(nearest(restart_team,oriented(Vector2(44,28),restart_team),false,kickoff_taker))
		current_restart = ""
		kickoff_kicker = kickoff_taker
		choose_targets()
	if ball_state == BallState.DEAD:
		Substitutions.apply(self)
		dead_ticks -= 1
		if dead_ticks <= 0:
			if restart_kind == "kickoff":
				reset_shape(restart_team)
			else:
				deliver_restart()
		return
	if not period_extension: active_ticks += 1
	Traits.tick(self)
	if ticks % 15 == 1:
		choose_targets()
	move_players()
	if ball_state == BallState.CONTROLLED:
		held_ticks += 1
		possession_ticks[players[owner].team] += 1
		ball = controlled_ball_position(owner)
		challenge_carrier()
		if not pending_shot.is_empty():
			if owner != pending_shot.actor:
				Traits.resolve(self,pending_shot.actor,pending_shot.action,"failed","possession lost during windup")
				pending_shot.clear()
			elif active_ticks >= pending_shot.release:
				var pressure: float = pending_shot.pressure
				pending_shot.clear()
				shoot(pressure,true)
		if owner >= 0 and ticks % 15 == 1 and held_ticks >= 12 and active_ticks >= players[owner].ready_tick:
			choose_action()
	elif ball_state == BallState.FLIGHT:
		advance_flight()
	elif ball_state == BallState.LOOSE:
		advance_loose()
	if ball_state not in [BallState.DEAD, BallState.KICKOFF]:
		BallRules.resolve(self, previous_ball, ball)
	if period_extension:
		if not period_extension_contact and (ball_state == BallState.FLIGHT or (ball_state == BallState.LOOSE and ball_velocity.length() > 0.4)): return
		period_extension = false
		period_extension_contact = false
	if period == Period.FIRST_HALF and active_ticks >= regulation_ticks / 2.0:
		period = Period.HALF_TIME
		start_restart(1, Vector2(52.5, 34), "halftime", 0)
		emit_event("halftime", -1)
		halftime_report = snapshot_report()
	elif period == Period.SECOND_HALF and active_ticks >= regulation_ticks:
		if knockout and scores[0] == scores[1]:
			period = Period.EXTRA_FIRST
			trait_allowance = 4
			Traits.stop(self)
			reset_shape(0)
			emit_event("extra_time",-1)
		else: finish_match()
	elif period == Period.EXTRA_FIRST and active_ticks >= regulation_ticks*7.0/6:
		period = Period.EXTRA_SECOND
		Traits.stop(self)
		reset_shape(1)
		emit_event("extra_half",-1)
	elif period == Period.EXTRA_SECOND and active_ticks >= regulation_ticks*4.0/3:
		if scores[0] == scores[1]: Shootout.start(self)
		else: finish_match()

func finish_match() -> void:
	if finished: return
	Traits.stop(self)
	period = Period.FULL_TIME
	finished = true
	owner = -1
	ball_state = BallState.DEAD
	emit_event("full_time",-1,{"score":scores.duplicate()})
	result_report = snapshot_report()

func winner() -> int:
	if forfeit_team >= 0: return 1-forfeit_team
	if scores[0] != scores[1]: return 0 if scores[0] > scores[1] else 1
	if not shootout.is_empty() and Shootout.clinched(shootout): return 0 if shootout.goals[0] > shootout.goals[1] else 1
	return -1

func phase_name() -> String:
	return {Period.FIRST_HALF:"First half",Period.HALF_TIME:"Half time",Period.SECOND_HALF:"Second half",Period.EXTRA_FIRST:"Extra time · first half",Period.EXTRA_SECOND:"Extra time · second half",Period.SHOOTOUT:"Penalty shootout",Period.FULL_TIME:"Full time"}[period]

func acknowledge_halftime() -> bool:
	if period != Period.HALF_TIME: return false
	Substitutions.apply(self,true)
	period = Period.SECOND_HALF
	reset_shape(1)
	return true

func snapshot_report() -> Dictionary:
	return {"minute": display_minute(), "scores": scores.duplicate(),
		"shots": shots.duplicate(), "on_target": shots_on_target.duplicate(),
		"saves": saves.duplicate(), "completed": completed_passes.duplicate(),
		"attempted": pass_attempts.duplicate(), "possession": possession_ticks.duplicate(),
		"events": events.duplicate(true),"forfeit_team":forfeit_team,"penalties":shootout.get("goals",[]).duplicate(),"winner":winner()}

func start_restart(team: int, location: Vector2, kind: String, duration: int) -> void:
	if kind == "penalty" and period_boundary_due():
		period_extension = true
		period_extension_contact = false
	Traits.resolve(self,flight_trait_actor,flight_trait_action,"failed","ball out or play stopped")
	Traits.stop(self)
	restart_team = team
	restart_position = location
	restart_kind = kind
	dead_ticks = duration
	owner = -1
	ball_state = BallState.DEAD
	ball_velocity = Vector2.ZERO
	ball = location
	pass_pending = false
	kickoff_kicker = -1
	kickoff_ticks = 0
	ball_height = 0
	flight_peak = 0
	flight_curve = 0
	keeper_hand_owner = -1
	offside_context.clear()
	restart_untouched = false
	combination.clear()
	transition_tick = -1000
	if not pending_shot.is_empty():
		Traits.resolve(self,pending_shot.actor,pending_shot.action,"failed","play stopped")
		pending_shot.clear()

func award_restart(team: int, location: Vector2, kind: String, actor: int = -1) -> void:
	start_restart(team, location, kind, 54)
	if restart_counts.has(kind): restart_counts[kind][team] += 1
	restart_taker = team * 11 if kind == "goal_kick" else nearest(team, location, false)
	if kind == "goal_kick": restart_taker = keeper_id(team)
	if kind in ["free_kick","corner","penalty"]:
		var slot: int = plans[team].get({"free_kick":"free_kick_taker","corner":"corner_taker","penalty":"penalty_taker"}[kind])
		if players[team*11+slot].active: restart_taker = team*11+slot
	for p in players:
		if p.id == restart_taker: continue
		if not p.active: continue
		var distance := 2.0 if kind == "throw_in" else 9.15
		if p.team != team and p.position.distance_to(location) < distance:
			var away := (p.position-location).normalized()
			if away == Vector2.ZERO: away = Vector2(direction(team),0)
			p.position = (location+away*distance).clamp(Vector2.ONE,FIELD-Vector2.ONE)
		if kind == "goal_kick" and p.team != team:
			var local := oriented(p.position,team)
			if local.x < 16.5 and absf(local.y-34) < 20.16: p.position = oriented(Vector2(18,local.y),team)
		p.previous = p.position
		p.target = p.position
	if kind == "penalty":
		for p in players:
			if not p.active or p.id in [restart_taker,keeper_id(1-team)]: continue
			var local := oriented(p.position,team)
			local.x = minf(local.x,82)
			p.position = oriented(local,team)
			p.previous = p.position
			p.target = p.position
		players[keeper_id(1-team)].position = oriented(Vector2(0.2,34),1-team)
	players[restart_taker].position = (location-Vector2(direction(team)*1.7,0)).clamp(Vector2.ONE,FIELD-Vector2.ONE)
	players[restart_taker].previous = players[restart_taker].position
	players[restart_taker].target = players[restart_taker].position
	players[restart_taker].facing = Vector2(direction(team),0)
	Restarts.arrange(self,team,kind,location,restart_taker)
	emit_event(kind+"_awarded", restart_taker, {"team":team, "last_touch":actor})
	emit_event("restart_setup",restart_taker,{"restart":kind})

func deliver_restart() -> void:
	owner = restart_taker
	ball = restart_position
	current_restart = restart_kind
	var receiver := -1
	var value := -INF
	for p in players:
		if not p.active or p.team != restart_team or p.id == owner: continue
		var length := ball.distance_to(p.position)
		var throw_range := 32.0
		if players[owner].card.trait_id == "long_throw_specialist" and players[owner].trait_uses < 3 and active_ticks >= players[owner].trait_ready: throw_range *= 1.12
		if length < 4 or length > (throw_range if restart_kind == "throw_in" else 55): continue
		var rating := -length*0.15-lane_risk(ball,p.position,restart_team)*14
		rating += (p.position.x-ball.x)*direction(restart_team)*0.2
		if rating > value:
			value = rating
			receiver = p.id
	emit_event(restart_kind,owner)
	if restart_kind == "penalty" or (restart_kind == "free_kick" and chance_quality(ball,restart_team) > 0.38): shoot()
	elif receiver >= 0: pass_to(receiver,0,"cross" if restart_kind == "corner" else "pass")
	else: launch_ball((ball+Vector2(direction(restart_team)*18,0)).clamp(Vector2(2,2),FIELD-Vector2(2,2)),24,"pass")
	kickoff_kicker = restart_taker
	current_restart = ""
	choose_targets()

func choose_targets() -> void:
	FootballAI.targets(self)
	Traits.runs(self)

func nearest(team: int, point: Vector2, include_keeper: bool = true, excluded: int = -1) -> int:
	var result := team * 11 + 1
	var distance := INF
	for p in players:
		if not p.active or p.team != team or p.id == excluded or (not include_keeper and p.role == "GK"):
			continue
		var candidate := p.position.distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			result = p.id
	return result

func move_players() -> void:
	# ponytail: pairwise separation is bounded to 22 players; spatial buckets only if that grows.
	for p in players:
		if not p.active: continue
		var separation := Vector2.ZERO
		for other in players:
			if not other.active or other.id == p.id:
				continue
			var offset := p.previous - other.previous
			var distance := offset.length()
			if distance > 0.01 and distance < 2.5:
				separation += offset / distance * (2.5 - distance)
		var movement_speed := (4.2 + 2.4 * attribute(p.id,"PAC") / 120.0) * MOVEMENT_TEMPO
		movement_speed = minf(7,movement_speed*Traits.parameter(p,"top_speed_multiplier"))
		if owner == p.id:
			movement_speed *= 0.96
		var desired := p.position.direction_to(p.target+separation)*movement_speed
		if active_ticks < p.run_ready_tick: desired = Vector2.ZERO
		if p.position.distance_to(p.target+separation) < movement_speed*DT: desired = (p.target+separation-p.position)/DT
		var acceleration := (12.0+attribute(p.id,"PAC")*0.08)*minf(1.35,Traits.parameter(p,"acceleration_multiplier"))
		p.velocity = p.velocity.move_toward(desired,acceleration*DT)
		var turn := (3+attribute(p.id,"DRI")/40)*minf(1.15,Traits.parameter(p,"turn_rate_multiplier"))
		if p.velocity.length() > 0.1: p.facing = p.facing.rotated(clampf(p.facing.angle_to(p.velocity),-DT*turn,DT*turn))
		p.position = (p.position+p.velocity*DT).clamp(Vector2(1, 1), FIELD - Vector2.ONE)
		var effort := p.velocity.length()/maxf(movement_speed,0.01)
		var intensity := 1.35 if plans[p.team].defence == "high_press" else (0.75 if plans[p.team].defence == "deep_block" else 1.0)
		p.stamina = maxf(0,p.stamina-effort*intensity*(1.0-p.physical/240.0)*85.0/regulation_ticks*Traits.parameter(p,"stamina_drain_multiplier"))

func take_control(id: int, kind: String = "recovery") -> void:
	var hand_claim := kind in ["hold","smother"]
	# AI cannot elect an illegal second touch before another player has touched it.
	if id == kickoff_kicker: return
	if not players[id].active or Offside.involved(self,id): return
	if not offside_context.is_empty() and players[id].team != offside_context.team: offside_context.clear()
	restart_untouched = false
	if ball_state == BallState.LOOSE:
		Traits.activate(self,id,{"kind":"receive","box":oriented(players[id].position,players[id].team).x > 88,"rebound":flight_kind == "shot","pressure":0.0})
	if last_control_team >= 0 and players[id].team != last_control_team:
		transition_tick = active_ticks
		combination.clear()
	last_control_team = players[id].team
	if period_extension: period_extension_contact = true
	kickoff_kicker = -1
	if pass_pending:
		Traits.resolve(self,flight_trait_actor,flight_trait_action,"success" if id == flight_receiver else ("partial" if players[id].team == players[flight_source].team else "failed"),"physical reception" if id == flight_receiver else "different player reached delivery")
	if pass_pending:
		if players[id].team == players[flight_source].team and id != flight_source:
			completed_passes[players[id].team] += 1
			kind = "received"
		elif players[id].team != players[flight_source].team:
			kind = "interception"
		pass_pending = false
	owner = id
	last_touch = id
	ball_state = BallState.CONTROLLED
	ball = controlled_ball_position(id)
	ball_velocity = Vector2.ZERO
	ball_height = 0
	flight_peak = 0
	flight_curve = 0
	keeper_hand_owner = id if hand_claim and players[id].role == "GK" else -1
	held_ticks = 0
	players[id].cooldown = maxi(players[id].cooldown, 18)
	players[id].ready_tick = active_ticks+roundi((24-attribute(id,"DRI")*0.12)*Traits.parameter(players[id],"preparation_time_multiplier"))
	if players[id].trait_state.get("trait","") in ["screen","anticipator","close_control"]:
		Traits.resolve(self,id,players[id].trait_state.action,"success","actual controlled touch")
	emit_event(kind, id)
	if hand_claim and kind not in ["hold","smother"]: emit_event("hold",id)

func lane_risk(from: Vector2, to: Vector2, team: int, ignore_keeper: bool = false) -> float:
	var result := 0.0
	for p in players:
		if not p.active or p.team == team or (ignore_keeper and p.role == "GK"):
			continue
		var along := segment_fraction(p.position, from, to)
		if along > 0.08 and along < 0.96:
			var distance := p.position.distance_to(from.lerp(to, along))
			result = maxf(result, clampf(1 - distance / 4.5, 0, 1))
	return result

func segment_fraction(point: Vector2, from: Vector2, to: Vector2) -> float:
	var delta := to - from
	return clampf((point - from).dot(delta) / maxf(delta.length_squared(), 0.00001), 0, 1)

func chance_quality(position: Vector2, team: int) -> float:
	return clampf(1.05 - position.distance_to(oriented(Vector2(105, 34), team)) / 40 - absf(position.y - 34) / 70, 0, 1)

func choose_action() -> void:
	if not pending_shot.is_empty(): return
	FootballAI.action(self)

func pass_to(receiver: int, pressure: float = 0, delivery_kind: String = "pass") -> void:
	var passer := players[owner]
	var recipient := players[receiver]
	flight_delivery = delivery_kind
	flight_receiver = receiver
	var aim := recipient.position + (recipient.target - recipient.position).limit_length(3.5)
	var length := ball.distance_to(aim)
	var enhancement := Traits.activate(self,passer.id,{"kind":"pass","length":length,"progress":(aim.x-ball.x)*direction(passer.team),"lateral":absf(aim.y-ball.y),"risk":lane_risk(ball,aim,passer.team),"delivery":delivery_kind,"restart":current_restart,"hand_control":keeper_hand_owner == passer.id})
	if enhancement.is_empty() and passer.trait_state.get("state","") == "active" and passer.trait_state.get("trait","") in ["wall_pass","tempo_setter"]: enhancement = passer.trait_state
	var pass_context := {"kind":"pass","delivery":delivery_kind,"ground":delivery_kind not in ["cross","keeper_throw"] and current_restart != "throw_in" and not (plans[passer.team].attack == "direct" and length > 32)}
	var delivery := attribute(passer.id,"KIC") if passer.role == "GK" and oriented(passer.position,passer.team).x < 16.5 else attribute(passer.id,"PAS",0,pass_context)
	var accuracy := clampf(0.88 + 0.002 * (delivery - 80) - 0.10 * pressure - 0.18 * minf(length / 55, 1) - 0.12 * lane_risk(ball, aim, passer.team), 0.25, 0.98)
	if rng.randf() > accuracy:
		aim += Vector2(rng.randf_range(-4.5, 4.5), rng.randf_range(-4.5, 4.5))*Traits.parameter(passer,"aim_dispersion_multiplier")
	pass_attempts[passer.team] += 1
	if delivery_kind == "one_two": combination.clear()
	elif length < 20 and passer.id%11 != 0 and (recipient.position.x-passer.position.x)*direction(passer.team) > 1:
		var third := passer.team*11+(7 if passer.id%11 != 7 and receiver%11 != 7 else 8)
		combination = {"passer":passer.id,"bounce":receiver,"third":third,"team":passer.team,"expires":active_ticks+150}
	flight_curve = (minf(1.8,length*0.09) if delivery_kind == "cross" else 0.0)*Traits.parameter(passer,"curve_capacity_multiplier")
	flight_peak = 3.2 if delivery_kind == "cross" or (plans[passer.team].attack == "direct" and length > 32) else 0.0
	if delivery_kind == "keeper_throw": flight_peak = 1.1
	if current_restart == "throw_in": flight_peak = 2.4 if length > 20 else 1.2
	launch_ball(aim, minf(34,(19 + delivery * 0.08)*Traits.parameter(passer,"ball_speed_multiplier")), "pass")
	if not enhancement.is_empty():
		flight_trait_actor = passer.id
		flight_trait_action = enhancement.action
		emit_event("trait_execution",passer.id,{"trait":enhancement.trait,"action":enhancement.action,"flight":flight_serial})
	emit_event("pass", passer.id, {"receiver": receiver,"receiver_name":recipient.name,"receiver_card":recipient.card.card_id, "target": aim, "delivery":delivery_kind})

func launch_ball(aim: Vector2, velocity: float, kind: String) -> void:
	flight_serial += 1
	last_control_team = players[owner].team
	flight_on_target_recorded = false
	offside_context = Offside.capture(self,owner)
	restart_untouched = not current_restart.is_empty()
	restart_delivery = current_restart
	restart_kick_team = players[owner].team
	flight_ticks = 0
	flight_origin = ball
	var bend := minf(4,ball.distance_to(aim)*0.12)
	flight_control = (ball+aim)*0.5+ball.direction_to(aim).orthogonal()*clampf(flight_curve,-bend,bend)
	flight_duration = maxf(DT,(ball.distance_to(flight_control)+flight_control.distance_to(aim))/velocity)
	flight_trait_actor = -1
	flight_trait_action = -1
	flight_source = owner
	last_touch = owner
	flight_target = aim
	flight_kind = kind
	pass_pending = kind == "pass"
	ball_velocity = ball.direction_to(aim) * velocity
	ball_state = BallState.FLIGHT
	owner = -1
	keeper_hand_owner = -1
	for p in players:
		if not p.active or p.team == players[flight_source].team: continue
		var response := Traits.activate(self,p.id,{"kind":"respond","reachable":p.position.distance_to(aim) < 12})
		p.response_delay = roundi((18-attribute(p.id,"DEF")*0.10)*Traits.parameter(p,"reaction_delay_multiplier"))

func advance_flight() -> void:
	var from := ball
	flight_ticks += 1
	var progress := minf(1.0,flight_ticks*DT/flight_duration)
	var destination := ball + ball_velocity * DT
	if absf(flight_curve) > 0.001 and (flight_ticks-1)*DT < flight_duration:
		destination = (1-progress)*(1-progress)*flight_origin+2*(1-progress)*progress*flight_control+progress*progress*flight_target
		ball_velocity = 2*((1-progress)*(flight_control-flight_origin)+progress*(flight_target-flight_control))/flight_duration
	ball_height = maxf(0,4*flight_peak*progress*(1-progress))
	var contact := -1
	var first := INF
	for p in players:
		if not p.active: continue
		if p.id == flight_source:
			continue
		if ball_height > (2.4 if p.role == "GK" else 1.9): continue
		if flight_kind != "shot" and p.team != players[flight_source].team and flight_ticks < p.response_delay: continue
		if flight_kind == "shot" and (p.team == players[flight_source].team or p.role == "GK"):
			continue
		var along := segment_fraction(p.position,from,destination)
		var reach := 1.25
		if flight_kind == "shot" and p.position.distance_to(from.lerp(destination,along)) <= 1.4:
			Traits.activate(self,p.id,{"kind":"block","reachable":true})
			reach += Traits.parameter(p,"block_reach_add",0)
		var contact_time := BallRules.contact_fraction(from,destination,p.position,reach)
		if contact_time < first:
			contact = p.id
			first = contact_time
	var boundary := BallRules.crossing(from,destination)
	var boundary_time: float = boundary.get("fraction",INF)
	if flight_kind == "shot" and not keeper_tested:
		var keeper := players[keeper_id(1-players[flight_source].team)]
		var delta_x := destination.x-from.x
		var glove_time := (keeper.position.x-from.x)/delta_x if absf(delta_x) > 0.000001 else INF
		if glove_time >= 0 and glove_time <= 1 and glove_time < minf(first,boundary_time):
			keeper_tested = true
			ball = from.lerp(destination,glove_time)
			if absf(flight_target.y-34) <= 3.66 and keeper_save(keeper.id): return
	if boundary_time <= first:
		if BallRules.resolve(self,from,destination): return
	if contact >= 0:
		if period_extension: period_extension_contact = true
		if Offside.involved(self,contact): return
		restart_untouched = false
		if flight_kind == "shot":
			kickoff_kicker = -1
			ball = from.lerp(destination, first)
			last_touch = contact
			owner = -1
			ball_state = BallState.LOOSE
			deflect_ball(contact,0.55)
			players[contact].cooldown = maxi(players[contact].cooldown,10)
			emit_event("block", contact, {"shooter": flight_source})
			Traits.resolve(self,flight_trait_actor,flight_trait_action,"failed","shot blocked")
			Traits.resolve(self,contact,players[contact].trait_state.get("action",-1),"success","physical block")
			flight_peak = 0
			return
		var same_team := players[contact].team == players[flight_source].team
		var contact_point := from.lerp(destination,first)
		ball = contact_point
		if players[contact].position.distance_to(contact_point) > 0.01: players[contact].facing = players[contact].position.direction_to(contact_point)
		if players[contact].role == "GK" and not same_team and legal_hand_contact(contact):
			keeper_delivery_contact(contact)
			return
		var pressure := clampf(1-players[nearest(1-players[contact].team,players[contact].position)].position.distance_to(players[contact].position)/4,0,1)
		var skill := attribute(contact,"DRI") if same_team else attribute(contact,"DEF")
		var local: Vector2 = oriented(players[contact].position,players[contact].team)
		var receive_trait := Traits.activate(self,contact,{"kind":"receive","pressure":pressure,"interception":not same_team,"central":absf(local.y-34) < 12,"bounce":not combination.is_empty() and combination.bounce == contact,"recycle":local.x < 65,"opponents":close_opponents(contact,5),"open":pressure < 0.3,"difficult":ball_velocity.length() > 27 or pressure > 0.5,"box":local.x > 88,"rebound":false})
		skill = attribute(contact,"DRI") if same_team else attribute(contact,"DEF")
		if ball_height > 0.6:
			Traits.activate(self,contact,{"kind":"aerial","defending":not same_team,"descending":progress > 0.5})
			var opponent := nearest(1-players[contact].team,players[contact].position)
			if players[opponent].position.distance_to(contact_point) < 1.4 and rng.randf() > clampf(0.5+(attribute(contact,"PHY")-attribute(opponent,"PHY"))*0.005,0.15,0.85): contact = opponent
			ball = from.lerp(destination,first)
			if players[contact].position.distance_to(ball) > 0.01: players[contact].facing = players[contact].position.direction_to(ball)
			take_control(contact,"aerial_win")
			if owner != contact: return
			Traits.resolve(self,contact,players[contact].trait_state.get("action",-1),"success","aerial contact won")
			if chance_quality(ball,players[contact].team) > 0.45:
				shot_context = {"aerial":progress > 0.5,"first_time":true,"from_corner":players[contact].team == players[flight_source].team and restart_delivery == "corner" and flight_kind == "pass"}
				shoot(pressure)
			else: emit_event("header",contact)
			return
		if (ball_velocity.length() > 27 or pressure > 0.6) and rng.randf() > clampf(0.65+skill*0.003-pressure*0.12-ball_velocity.length()*0.002,0.4,0.98):
			ball = from.lerp(destination,first)
			last_touch = contact
			kickoff_kicker = -1
			pass_pending = false
			ball_state = BallState.LOOSE
			ball_velocity *= 0.4*Traits.parameter(players[contact],"first_touch_error_multiplier")
			players[contact].cooldown = maxi(players[contact].cooldown,10)
			emit_event("poor_touch",contact)
			Traits.resolve(self,flight_trait_actor,flight_trait_action,"partial","receiver could not control")
			Traits.resolve(self,contact,receive_trait.get("action",-1),"partial" if players[contact].card.trait_id == "close_control" else "failed","first touch escaped control")
		else:
			take_control(contact, "received" if same_team else "interception")
			if owner == contact and same_team and chance_quality(ball,players[contact].team) > 0.58 and pressure < 0.55:
				shot_context = {"first_time":true}
				shoot(pressure)
		return
	ball = destination
	if flight_kind == "shot":
		BallRules.resolve(self, from, ball)
		return
	if progress >= 1 or (flight_target - ball).dot(ball_velocity) <= 0:
		ball_state = BallState.LOOSE
		# The intended arrival ends; the physical ball keeps its incoming momentum.

func advance_loose(recover: bool = true) -> void:
	var from := ball
	var destination := ball+ball_velocity*DT
	ball_height = maxf(0,ball_height-4*DT)
	ball_velocity = ball_velocity.move_toward(Vector2.ZERO,BallRules.ROLL_DECELERATION*DT)
	var contact := -1
	var first := INF
	if recover and ball_height <= 1.9:
		for p in players:
			if not p.active or p.id == kickoff_kicker: continue
			if p.id == last_touch and p.cooldown > 0: continue
			var fraction := BallRules.contact_fraction(from,destination,p.position,1.3)
			if fraction < first:
				first = fraction
				contact = p.id
	var boundary := BallRules.crossing(from,destination)
	if float(boundary.get("fraction",INF)) <= first:
		if BallRules.resolve(self,from,destination): return
	ball = destination if contact < 0 else from.lerp(destination,first)
	if contact >= 0:
		if players[contact].position.distance_to(ball) > 0.01: players[contact].facing = players[contact].position.direction_to(ball)
		take_control(contact)

func deflect_ball(id: int, retained: float) -> void:
	var normal := players[id].position.direction_to(ball)
	if normal.length_squared() < 0.01: normal = -ball_velocity.normalized()
	ball_velocity = ball_velocity.bounce(normal)*retained

func legal_hand_contact(id: int) -> bool:
	var local := oriented(ball,players[id].team)
	return local.x >= 0 and local.x <= 16.5 and absf(local.y-34) <= 20.16

func keeper_delivery_contact(id: int) -> void:
	var opponent := nearest(1-players[id].team,ball)
	var pressure := clampf(1-players[opponent].position.distance_to(ball)/4,0,1)
	var catch_chance := clampf(0.35+attribute(id,"HAN")*0.005-maxf(0,ball_velocity.length()-12)*0.012-pressure*0.2-absf(ball_height-1)*0.06,0.1,0.95)
	if rng.randf() < catch_chance: take_control(id,"hold")
	else: keeper_parry(id)

func keeper_parry(id: int) -> void:
	owner = -1
	last_touch = id
	kickoff_kicker = -1
	restart_untouched = false
	if pass_pending: Traits.resolve(self,flight_trait_actor,flight_trait_action,"failed","keeper deflected delivery")
	pass_pending = false
	ball_state = BallState.LOOSE
	# Glancing glove contacts preserve more forward travel; central saves turn it away.
	var normal := Vector2(direction(players[id].team),(ball.y-players[id].position.y)/1.7).normalized()
	ball_velocity = ball_velocity.bounce(normal)*0.55 if ball_velocity.length() > 0.1 else Vector2(direction(players[id].team)*12,0)
	players[id].cooldown = maxi(players[id].cooldown,18)
	var deflection := Traits.activate(self,id,{"kind":"parry"})
	if not deflection.is_empty():
		var danger := nearest(1-players[id].team,ball,false)
		ball_velocity.y = absf(ball_velocity.y)+6 if players[danger].position.y < ball.y else -absf(ball_velocity.y)-6
		ball_velocity = (ball_velocity*Traits.parameter(players[id],"rebound_speed_multiplier")).limit_length(20)
	emit_event("parry",id)

func shoot(pressure: float = 0, prepared: bool = false) -> void:
	var shooter := players[owner]
	var goal := oriented(Vector2(105, 34), shooter.team)
	shot_quality = chance_quality(ball, shooter.team)
	var base_curve := minf(1.6,ball.distance_to(goal)*0.09) if absf(ball.y-34) > 5 and shot_quality > 0.35 else 0.0
	var context := {"kind":"shot","curve":base_curve,"first_time":shot_context.get("first_time",false),"aerial":shot_context.get("aerial",false),"from_corner":shot_context.get("from_corner",false),"pressure":pressure,"prepared":prepared,"restart":shot_context.get("restart",current_restart)}
	var enhancement := Traits.activate(self,shooter.id,context) if not prepared else shooter.trait_state
	if not prepared and not enhancement.is_empty() and enhancement.trait == "power_strike":
		shot_context = context.duplicate(true)
		pending_shot = {"actor":shooter.id,"action":enhancement.action,"release":active_ticks+9,"pressure":pressure}
		return
	var shooting := attribute(shooter.id,"SHO",0,context)
	var accuracy := clampf(0.30 + 0.004 * (shooting - 60) + 0.32 * shot_quality - 0.16 * pressure, 0.15, 0.95)
	if period != Period.SHOOTOUT: shots[shooter.team] += 1
	var target_y := 34 + rng.randf_range(-3.2, 3.2)*Traits.parameter(shooter,"aim_dispersion_multiplier")
	var on_target := rng.randf() < accuracy
	if not on_target:
		target_y = 34 + (-1 if rng.randf() < 0.5 else 1) * rng.randf_range(5.5, 10)
	keeper_tested = false
	flight_curve = base_curve*Traits.parameter(shooter,"curve_capacity_multiplier")*(-1 if ball.y > 34 else 1)
	flight_peak = 0.8 if shot_context.get("aerial",false) else 0.0
	var previous_restart := current_restart
	if prepared: current_restart = context.restart
	launch_ball(Vector2(goal.x, target_y), minf(36,(26 + shooting * 0.08)*Traits.parameter(shooter,"ball_speed_multiplier")), "shot")
	current_restart = previous_restart
	if not enhancement.is_empty():
		flight_trait_actor = shooter.id
		flight_trait_action = enhancement.action
		emit_event("trait_execution",shooter.id,{"trait":enhancement.trait,"action":enhancement.action,"flight":flight_serial})
	shot_context.clear()
	emit_event("shootout_shot" if period == Period.SHOOTOUT else "shot", shooter.id, {"on_target": on_target, "quality": shot_quality})

func close_opponents(id: int, radius: float) -> int:
	var count := 0
	for p in players:
		if p.active and p.team != players[id].team and p.position.distance_to(players[id].position) < radius: count += 1
	return count

func keeper_save(keeper_id: int) -> bool:
	var shooter := players[flight_source]
	var keeper := players[keeper_id]
	if not legal_hand_contact(keeper_id) or ball_height > 2.4+attribute(keeper_id,"DIV")*0.005: return false
	var reach := 2.5+attribute(keeper_id,"DIV")*0.04
	if absf(ball.y-keeper.position.y) > reach: return false
	var enhancement := Traits.activate(self,keeper_id,{"kind":"save","distance":keeper.position.distance_to(flight_origin),"pressure":clampf(1-keeper.position.distance_to(shooter.position)/8,0,1)})
	var reaction := maxf(0.12,(0.32-attribute(keeper_id,"REF")*0.0015)*Traits.parameter(keeper,"reaction_delay_multiplier"))
	if flight_ticks*DT < reaction:
		Traits.resolve(self,keeper_id,enhancement.get("action",-1),"failed","shot arrived before reaction")
		return false
	var chance := clampf(0.90 - 0.65 * shot_quality + 0.003 * (attribute(keeper_id,"REF") - 80) - 0.002 * (attribute(shooter.id,"SHO") - 80), 0.10, 0.95)
	if rng.randf() >= chance:
		Traits.resolve(self,keeper_id,enhancement.get("action",-1),"failed","save attempt beaten")
		return false
	if period != Period.SHOOTOUT:
		shots_on_target[shooter.team] += 1
		flight_on_target_recorded = true
		saves[keeper.team] += 1
	last_touch = keeper_id
	restart_untouched = false
	kickoff_kicker = -1
	emit_event("shootout_save" if period == Period.SHOOTOUT else "save", keeper_id, {"shooter": flight_source})
	if period != Period.SHOOTOUT: Traits.resolve(self,flight_trait_actor,flight_trait_action,"failed","goalkeeper saved")
	if rng.randf() < clampf(0.45+attribute(keeper_id,"HAN")*0.0035,0.4,0.9):
		take_control(keeper_id, "hold")
		Traits.resolve(self,keeper_id,enhancement.get("action",-1),"success","legal hand control")
	else:
		Traits.resolve(self,keeper_id,enhancement.get("action",-1),"partial","save became live rebound")
		keeper_parry(keeper_id)
	return true

func goal_scored(shooter_id: int, scoring_team: int = -1) -> void:
	if period == Period.SHOOTOUT:
		Traits.resolve(self,flight_trait_actor,flight_trait_action,"success","shootout goal")
		Shootout.finish_attempt(self,true)
		return
	var team: int = players[shooter_id].team if scoring_team < 0 else scoring_team
	if players[shooter_id].team != team and flight_kind == "shot" and flight_source >= 0 and players[flight_source].team == team and last_control_team == team and absf(flight_target.y-34) <= 3.66:
		shooter_id = flight_source
	scores[team] += 1
	Traits.resolve(self,flight_trait_actor,flight_trait_action,"success","actual goal-line crossing")
	if flight_kind == "shot" and not flight_on_target_recorded and flight_source >= 0 and players[flight_source].team == team and absf(flight_target.y-34) <= 3.66:
		shots_on_target[team] += 1
		flight_on_target_recorded = true
	ball = Vector2(105 if direction(team) > 0 else 0, ball.y)
	emit_event("goal", shooter_id, {"score": scores.duplicate(), "team":team, "own_goal":players[shooter_id].team != team,"last_touch":last_touch})
	start_restart(1 - team, ball, "kickoff", 150)

func challenge_carrier() -> void:
	if held_ticks < 18:
		return
	var attacker := players[owner]
	var keeper := players[keeper_id(1-attacker.team)]
	var keeper_ball := oriented(ball, keeper.team)
	if keeper.cooldown == 0 and keeper_ball.x < 16.5 and absf(keeper_ball.y - 34) < 20.16 and keeper.position.distance_to(ball) < 2.4:
		keeper.cooldown = 75
		if rng.randf() < clampf(0.50 + 0.004 * (attribute(keeper.id,"REF") - attribute(attacker.id,"DRI")), 0.20, 0.78):
			attacker.cooldown = 60
			take_control(keeper.id, "smother")
			return
	var defender := players[nearest(1 - attacker.team, ball, false)]
	if defender.cooldown > 0 or defender.position.distance_to(ball) > 1.8:
		return
	defender.cooldown = 48
	var angle := (attacker.position - defender.position).normalized().dot(Vector2(direction(attacker.team), 0))
	var enhancement := Traits.activate(self,defender.id,{"kind":"tackle","legal_angle":angle <= 0.45})
	Traits.activate(self,attacker.id,{"kind":"shield","pressure":1.0,"opponents":close_opponents(attacker.id,5)})
	var clean_win := clampf(0.48 + 0.004 * (attribute(defender.id,"DEF",0,{"kind":"standing_tackle"}) - attribute(attacker.id,"DRI")) + 0.0015*(attribute(defender.id,"PHY")-attribute(attacker.id,"PHY")) + 0.10 * angle, 0.12, 0.85)
	if rng.randf() < clean_win:
		attacker.cooldown = 60
		tackles[defender.team] += 1
		take_control(defender.id, "tackle")
		Traits.resolve(self,defender.id,enhancement.get("action",-1),"success","clean possession win")
	else:
		Traits.resolve(self,defender.id,enhancement.get("action",-1),"failed","challenge did not win possession")
		# Contact from behind can be a foul; a failed legal challenge remains ordinary play.
		if angle > 0.45 and rng.randf() < clampf(0.08 + (80-defender.defence)*0.001,0.02,0.14):
			var speed := (defender.velocity-attacker.velocity).length()
			Discipline.foul(self,defender.id,attacker.id,2 if speed > 11 else (1 if speed > 6 else 0))
		else: emit_event("challenge", defender.id)

func emit_event(kind: String, actor: int, extra: Dictionary = {}) -> void:
	var event := {"kind": kind, "actor": actor, "team": players[actor].team if actor >= 0 else -1,
		"tick": ticks, "minute": display_minute(), "position": ball}
	if actor >= 0:
		event["actor_name"] = players[actor].name
		event["actor_card"] = players[actor].card.card_id
		event["flight"] = flight_serial
		if players[actor].trait_state.get("state","") == "active": event["action"] = players[actor].trait_state.action
	event.merge(extra)
	events.append(event)

func signature() -> Array:
	var result: Array = [ticks, active_ticks, ball_state, ball, owner, last_touch, held_ticks,
		ball_velocity, flight_target, flight_source, flight_kind, pass_pending, rng.state, scores.duplicate(),
		possession_ticks.duplicate(), pass_attempts.duplicate(), completed_passes.duplicate(),
		tackles.duplicate(), events.duplicate(true)]
	result.append([shots.duplicate(), shots_on_target.duplicate(), saves.duplicate(), shot_quality, keeper_tested, dead_ticks, restart_team])
	result.append([period, finished, restart_kind, restart_position, regulation_ticks,
		halftime_report.duplicate(true), result_report.duplicate(true)])
	result.append([kickoff_taker, kickoff_ticks, kickoff_kicker])
	result.append([ball_height, restart_taker, restart_counts.duplicate(true), fouls.duplicate()])
	result.append([combination.duplicate(true), transition_tick, flight_delivery, flight_receiver])
	result.append([substitution_counts.duplicate(),substitution_windows.duplicate(),substitution_stages.duplicate(),used_cards.duplicate(true)])
	result.append([action_id,flight_trait_actor,flight_trait_action,flight_ticks,flight_origin,flight_control,flight_duration,flight_curve,flight_peak,shot_context.duplicate(true),pending_shot.duplicate(true),current_restart,keeper_hand_owner])
	result.append([offside_context.duplicate(true),restart_untouched,restart_delivery,restart_kick_team,forfeit_team])
	result.append([knockout,trait_allowance,shootout.duplicate(true),flight_on_target_recorded])
	result.append([last_control_team,flight_serial,period_extension,period_extension_contact])
	result.append(principles.duplicate(true))
	for p in players:
		result.append([p.position, p.target, p.cooldown, p.card.card_id, p.role, p.stamina, p.velocity, p.facing, p.ready_tick,p.trait_state.duplicate(true),p.trait_uses,p.trait_ready,p.response_delay,p.run_ready_tick,p.entered_tick,p.active,p.yellows,p.shootout_trait_used,p.anchor_override])
	return result

func snapshot() -> Dictionary:
	return load("res://match/match_snapshot.gd").capture(self)

func period_boundary_due() -> bool:
	return (period == Period.FIRST_HALF and active_ticks >= regulation_ticks/2.0) or (period == Period.SECOND_HALF and active_ticks >= regulation_ticks) or (period == Period.EXTRA_FIRST and active_ticks >= regulation_ticks*7.0/6) or (period == Period.EXTRA_SECOND and active_ticks >= regulation_ticks*4.0/3)
