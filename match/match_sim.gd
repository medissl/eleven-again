extends RefCounted
## The match owns outcomes. Rendering and commentary only consume this state.
const BallRules = preload("res://match/ball_rules.gd")

enum BallState { CONTROLLED, FLIGHT, LOOSE, DEAD, KICKOFF }
enum Period { FIRST_HALF, HALF_TIME, SECOND_HALF, FULL_TIME }
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
	var cooldown := 0

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

func _init(seed_value: int = 11027, duration_seconds: int = REGULATION_SECONDS) -> void:
	match_seed = seed_value
	regulation_ticks = maxi(2, duration_seconds) * 60
	rng.seed = seed_value
	for id in 22:
		var p := Footballer.new()
		p.id = id
		p.team = int(id / 11.0)
		p.name = NAMES[id]
		p.pace = rng.randi_range(58, 82)
		p.passing = rng.randi_range(58, 82)
		p.shooting = rng.randi_range(55, 80)
		p.defence = rng.randi_range(55, 80)
		p.dribbling = rng.randi_range(58, 80)
		p.keeping = rng.randi_range(65, 80) if id % 11 == 0 else 35
		players.append(p)
	reset_shape(0)

func direction(team: int) -> float:
	var first_half := 1.0 if team == 0 else -1.0
	return -first_half if period == Period.SECOND_HALF or period == Period.FULL_TIME else first_half

func oriented(point: Vector2, team: int) -> Vector2:
	return point if direction(team) > 0 else FIELD - point

func controlled_ball_position(id: int) -> Vector2:
	return players[id].position + Vector2(direction(players[id].team) * 1.7, 0)

func display_minute() -> int:
	return mini(90, int(active_ticks * 90.0 / regulation_ticks))

func reset_shape(kicking_team: int) -> void:
	restart_team = kicking_team
	restart_kind = "kickoff"
	restart_position = CENTRE
	for p in players:
		var anchor: Vector2 = ANCHORS[p.id % 11]
		p.position = oriented(Vector2(anchor.x * 0.6, anchor.y), p.team)
		if p.team != kicking_team and p.position.distance_to(CENTRE) < 9.15:
			p.position = CENTRE + (p.position - CENTRE).normalized() * 9.15
		p.cooldown = 0
	kickoff_taker = kicking_team * 11 + 9
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
	emit_event("kickoff_setup", kickoff_taker)

func step() -> void:
	if finished or period == Period.HALF_TIME:
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
		pass_to(restart_team * 11 + 6)
		kickoff_kicker = kickoff_taker
		choose_targets()
	if ball_state == BallState.DEAD:
		dead_ticks -= 1
		if dead_ticks <= 0:
			if restart_kind == "kickoff":
				reset_shape(restart_team)
			else:
				deliver_restart()
		return
	active_ticks += 1
	if ticks % 15 == 1:
		choose_targets()
	move_players()
	if ball_state == BallState.CONTROLLED:
		held_ticks += 1
		possession_ticks[players[owner].team] += 1
		ball = controlled_ball_position(owner)
		challenge_carrier()
		if owner >= 0 and ticks % 15 == 1 and held_ticks >= 24:
			choose_action()
	elif ball_state == BallState.FLIGHT:
		advance_flight()
	elif ball_state == BallState.LOOSE:
		ball += ball_velocity * DT
		ball_velocity *= 0.96
		for p in players:
			if p.id == kickoff_kicker: continue
			if p.position.distance_to(ball) < 1.3:
				take_control(p.id)
				break
	if ball_state not in [BallState.DEAD, BallState.KICKOFF]:
		BallRules.resolve(self, previous_ball, ball)
	if period == Period.FIRST_HALF and active_ticks >= regulation_ticks / 2.0:
		period = Period.HALF_TIME
		start_restart(1, Vector2(52.5, 34), "halftime", 0)
		emit_event("halftime", -1)
		halftime_report = snapshot_report()
	elif active_ticks >= regulation_ticks:
		period = Period.FULL_TIME
		finished = true
		owner = -1
		ball_state = BallState.DEAD
		emit_event("full_time", -1, {"score": scores.duplicate()})
		result_report = snapshot_report()

func acknowledge_halftime() -> bool:
	if period != Period.HALF_TIME: return false
	period = Period.SECOND_HALF
	reset_shape(1)
	return true

func snapshot_report() -> Dictionary:
	return {"minute": display_minute(), "scores": scores.duplicate(),
		"shots": shots.duplicate(), "on_target": shots_on_target.duplicate(),
		"saves": saves.duplicate(), "completed": completed_passes.duplicate(),
		"attempted": pass_attempts.duplicate(), "possession": possession_ticks.duplicate(),
		"events": events.duplicate(true)}

func start_restart(team: int, location: Vector2, kind: String, duration: int) -> void:
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

func award_restart(team: int, location: Vector2, kind: String, actor: int = -1) -> void:
	start_restart(team, location, kind, 54)
	if restart_counts.has(kind): restart_counts[kind][team] += 1
	restart_taker = team * 11 if kind == "goal_kick" else nearest(team, location, false)
	for p in players:
		if p.id == restart_taker: continue
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
	players[restart_taker].position = (location-Vector2(direction(team)*1.7,0)).clamp(Vector2.ONE,FIELD-Vector2.ONE)
	players[restart_taker].previous = players[restart_taker].position
	players[restart_taker].target = players[restart_taker].position
	emit_event(kind+"_awarded", restart_taker, {"team":team, "last_touch":actor})

func deliver_restart() -> void:
	owner = restart_taker
	ball = restart_position
	var receiver := -1
	var value := -INF
	for p in players:
		if p.team != restart_team or p.id == owner: continue
		var length := ball.distance_to(p.position)
		if length < 4 or length > (32 if restart_kind == "throw_in" else 55): continue
		var rating := -length*0.15-lane_risk(ball,p.position,restart_team)*14
		rating += (p.position.x-ball.x)*direction(restart_team)*0.2
		if rating > value:
			value = rating
			receiver = p.id
	emit_event(restart_kind,owner)
	if receiver >= 0: pass_to(receiver)
	else: launch_ball((ball+Vector2(direction(restart_team)*18,0)).clamp(Vector2(2,2),FIELD-Vector2(2,2)),24,"pass")
	kickoff_kicker = restart_taker
	choose_targets()

func choose_targets() -> void:
	var team_in_control := players[owner].team if owner >= 0 else players[last_touch].team
	for p in players:
		var local_ball := oriented(ball, p.team)
		var anchor: Vector2 = ANCHORS[p.id % 11]
		var shift := (local_ball.x - 52.5) * 0.4 + (8 if p.team == team_in_control else -10)
		if p.id % 11 == 0:
			var keeper_x := 5.5
			if p.team != team_in_control and local_ball.x < 18 and absf(local_ball.y - 34) < 18:
				keeper_x = clampf(local_ball.x - 1.5, 3, 10)
			p.target = oriented(Vector2(keeper_x, clampf(local_ball.y, 27, 41)), p.team)
		else:
			var support := Vector2(clampf(anchor.x + shift, 12, 95), clampf(anchor.y + (local_ball.y - 34) * 0.15, 4, 64))
			if p.team == team_in_control:
				match p.id % 11:
					9:
						support = Vector2(clampf(local_ball.x + 15, 58, 95), 28 if local_ball.y > 34 else 40)
					8, 10:
						support.x = clampf(local_ball.x + 12, 52, 94)
						if local_ball.x > 60:
							support.y = (20 if local_ball.y < 34 else 26) if p.id % 11 == 8 else (48 if local_ball.y > 34 else 42)
					6, 7:
						support.x = clampf(local_ball.x - 5, 35, 80)
						support.y = 24 if p.id % 11 == 6 else 44
			p.target = oriented(support, p.team)
	if owner >= 0:
		var carrier := players[owner]
		var local := oriented(carrier.position, carrier.team)
		var inside := lerpf(local.y, 34, 0.55 if local.x > 60 else 0.15)
		var carry_target := Vector2(minf(local.x + 9, 101), inside)
		var ahead := players[nearest(1 - carrier.team, carrier.position)].position
		if carrier.position.distance_to(ahead) < 5 and (ahead.x - carrier.position.x) * direction(carrier.team) > 0:
			# Move around the presser instead of repeatedly running into the same duel.
			carry_target.y = clampf(local.y + (-6 if local.y > 34 else 6), 6, 62)
		carrier.target = oriented(carry_target, carrier.team)
		var chaser := nearest(1 - carrier.team, ball, false)
		players[chaser].target = ball
	elif ball_state == BallState.LOOSE:
		for team in 2:
			players[nearest(team, ball, false, kickoff_kicker)].target = ball
	elif ball_state == BallState.FLIGHT:
		for team in 2:
			players[nearest(team, flight_target, false, kickoff_kicker)].target = flight_target

func nearest(team: int, point: Vector2, include_keeper: bool = true, excluded: int = -1) -> int:
	var result := team * 11 + 1
	var distance := INF
	for p in players:
		if p.team != team or p.id == excluded or (not include_keeper and p.id % 11 == 0):
			continue
		var candidate := p.position.distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			result = p.id
	return result

func move_players() -> void:
	# ponytail: pairwise separation is bounded to 22 players; spatial buckets only if that grows.
	for p in players:
		var separation := Vector2.ZERO
		for other in players:
			if other.id == p.id:
				continue
			var offset := p.previous - other.previous
			var distance := offset.length()
			if distance > 0.01 and distance < 2.5:
				separation += offset / distance * (2.5 - distance)
		var movement_speed := (5.2 + 3.0 * p.pace / 120.0) * MOVEMENT_TEMPO
		if owner == p.id:
			movement_speed *= 0.96
		p.position = p.position.move_toward(p.target + separation, movement_speed * DT).clamp(Vector2(1, 1), FIELD - Vector2.ONE)

func take_control(id: int, kind: String = "recovery") -> void:
	# AI cannot elect an illegal second touch before another player has touched it.
	if id == kickoff_kicker: return
	kickoff_kicker = -1
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
	held_ticks = 0
	players[id].cooldown = maxi(players[id].cooldown, 18)
	emit_event(kind, id)

func lane_risk(from: Vector2, to: Vector2, team: int, ignore_keeper: bool = false) -> float:
	var result := 0.0
	for p in players:
		if p.team == team or (ignore_keeper and p.id % 11 == 0):
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
	var carrier := players[owner]
	var nearest_defender := nearest(1 - carrier.team, carrier.position)
	var pressure := clampf(1 - players[nearest_defender].position.distance_to(carrier.position) / 6, 0, 1)
	var goal := oriented(Vector2(105, 34), carrier.team)
	var quality := chance_quality(carrier.position, carrier.team)
	var take_chance := quality > 0.55 or (quality > 0.35 and pressure > 0.7 and held_ticks > 90)
	if carrier.id % 11 != 0 and take_chance and absf(carrier.position.y - 34) < 21 and (lane_risk(ball, goal, carrier.team, true) < 0.8 or carrier.position.distance_to(goal) < 17):
		shoot(pressure)
		return
	var best := -1
	var best_score := -INF
	for p in players:
		if p.team != carrier.team or p.id == owner:
			continue
		var length := p.position.distance_to(carrier.position)
		if length < 5 or length > 43:
			continue
		var progress := (p.position.x - carrier.position.x) * direction(carrier.team)
		var space := minf(12, p.position.distance_to(players[nearest(1 - p.team, p.position)].position))
		var threat_gain := chance_quality(p.position, p.team) - quality
		var score := progress * 0.45 + space * 0.55 + threat_gain * 14 - length * 0.10 - lane_risk(carrier.position, p.position, carrier.team) * 12
		score += rng.randf_range(-2, 2)
		if score > best_score:
			best_score = score
			best = p.id
	# A safe dribble can be more useful than recycling to the same marked winger.
	var local := oriented(carrier.position, carrier.team)
	var forward_space := lane_risk(carrier.position, carrier.target, carrier.team)
	var carry_score := 6.0 + quality * 5 - pressure * 3
	if local.x > 58 and forward_space < 0.6:
		carry_score += 5
	if best >= 0 and (carrier.id % 11 == 0 or best_score > carry_score or (held_ticks > 150 and pressure > 0.5)):
		pass_to(best, pressure)

func pass_to(receiver: int, pressure: float = 0) -> void:
	var passer := players[owner]
	var recipient := players[receiver]
	var aim := recipient.position + (recipient.target - recipient.position).limit_length(3.5)
	var length := ball.distance_to(aim)
	var accuracy := clampf(0.88 + 0.002 * (passer.passing - 80) - 0.10 * pressure - 0.18 * minf(length / 55, 1) - 0.12 * lane_risk(ball, aim, passer.team), 0.25, 0.98)
	if rng.randf() > accuracy:
		aim += Vector2(rng.randf_range(-4.5, 4.5), rng.randf_range(-4.5, 4.5))
	pass_attempts[passer.team] += 1
	launch_ball(aim, 24 + passer.passing * 0.1, "pass")
	emit_event("pass", passer.id, {"receiver": receiver, "target": aim})

func launch_ball(aim: Vector2, velocity: float, kind: String) -> void:
	flight_source = owner
	last_touch = owner
	flight_target = aim
	flight_kind = kind
	pass_pending = kind == "pass"
	ball_velocity = ball.direction_to(aim) * velocity
	ball_state = BallState.FLIGHT
	owner = -1

func advance_flight() -> void:
	var from := ball
	var destination := ball + ball_velocity * DT
	var contact := -1
	var first := INF
	for p in players:
		if p.id == flight_source:
			continue
		if flight_kind == "shot" and (p.team == players[flight_source].team or p.id % 11 == 0):
			continue
		var segment := destination - from
		var along := (p.position - from).dot(segment) / maxf(segment.length_squared(), 0.00001)
		if along < 0 or along > 1:
			continue
		if p.position.distance_to(from.lerp(destination, along)) < 1.25 and along < first:
			contact = p.id
			first = along
	if contact >= 0:
		if flight_kind == "shot":
			kickoff_kicker = -1
			ball = from.lerp(destination, first)
			last_touch = contact
			owner = -1
			ball_state = BallState.LOOSE
			ball_velocity = Vector2(-ball_velocity.x * 0.35, rng.randf_range(-8, 8))
			emit_event("block", contact, {"shooter": flight_source})
			return
		var same_team := players[contact].team == players[flight_source].team
		take_control(contact, "received" if same_team else "interception")
		return
	ball = destination
	if flight_kind == "shot":
		var shooter := players[flight_source]
		var keeper := players[(1 - shooter.team) * 11]
		var crosses_keeper := (from.x - keeper.position.x) * (ball.x - keeper.position.x) <= 0
		if not keeper_tested and crosses_keeper and absf(flight_target.y - 34) <= 3.66:
			keeper_tested = true
			if absf(ball.y - keeper.position.y) <= 5.5 and keeper_save(keeper.id):
				return
		BallRules.resolve(self, from, ball)
		return
	if ball.distance_to(flight_target) <= ball_velocity.length() * DT or (flight_target - ball).dot(ball_velocity) <= 0:
		ball_state = BallState.LOOSE
		ball_velocity = Vector2.ZERO

func shoot(pressure: float = 0) -> void:
	var shooter := players[owner]
	var goal := oriented(Vector2(105, 34), shooter.team)
	shot_quality = chance_quality(ball, shooter.team)
	var accuracy := clampf(0.30 + 0.004 * (shooter.shooting - 60) + 0.32 * shot_quality - 0.16 * pressure, 0.15, 0.95)
	shots[shooter.team] += 1
	var target_y := 34 + rng.randf_range(-3.2, 3.2)
	var on_target := rng.randf() < accuracy
	if not on_target:
		target_y = 34 + (-1 if rng.randf() < 0.5 else 1) * rng.randf_range(5.5, 10)
	keeper_tested = false
	launch_ball(Vector2(goal.x, target_y), 28 + shooter.shooting * 0.08, "shot")
	emit_event("shot", shooter.id, {"on_target": on_target, "quality": shot_quality})

func keeper_save(keeper_id: int) -> bool:
	var shooter := players[flight_source]
	var keeper := players[keeper_id]
	var chance := clampf(0.90 - 0.65 * shot_quality + 0.003 * (keeper.keeping - 80) - 0.002 * (shooter.shooting - 80), 0.10, 0.95)
	if rng.randf() >= chance:
		return false
	shots_on_target[shooter.team] += 1
	saves[keeper.team] += 1
	last_touch = keeper_id
	kickoff_kicker = -1
	emit_event("save", keeper_id, {"shooter": flight_source})
	if rng.randf() < 0.72:
		take_control(keeper_id, "hold")
	else:
		owner = -1
		ball_state = BallState.LOOSE
		ball = keeper.position + Vector2(-direction(shooter.team) * 1.5, 0)
		ball_velocity = Vector2(-direction(shooter.team) * 12, rng.randf_range(-8, 8))
		emit_event("parry", keeper_id)
	return true

func goal_scored(shooter_id: int, scoring_team: int = -1) -> void:
	var team: int = players[shooter_id].team if scoring_team < 0 else scoring_team
	scores[team] += 1
	shots_on_target[team] += 1
	ball = Vector2(105 if direction(team) > 0 else 0, ball.y)
	emit_event("goal", shooter_id, {"score": scores.duplicate(), "team":team, "own_goal":players[shooter_id].team != team})
	start_restart(1 - team, ball, "kickoff", 150)

func challenge_carrier() -> void:
	if held_ticks < 18:
		return
	var attacker := players[owner]
	var keeper := players[(1 - attacker.team) * 11]
	var keeper_ball := oriented(ball, keeper.team)
	if keeper.cooldown == 0 and keeper_ball.x < 16.5 and absf(keeper_ball.y - 34) < 20.16 and keeper.position.distance_to(ball) < 2.4:
		keeper.cooldown = 75
		if rng.randf() < clampf(0.50 + 0.004 * (keeper.keeping - attacker.dribbling), 0.20, 0.78):
			attacker.cooldown = 60
			take_control(keeper.id, "smother")
			return
	var defender := players[nearest(1 - attacker.team, ball, false)]
	if defender.cooldown > 0 or defender.position.distance_to(ball) > 1.8:
		return
	defender.cooldown = 48
	var angle := (attacker.position - defender.position).normalized().dot(Vector2(direction(attacker.team), 0))
	var clean_win := clampf(0.48 + 0.004 * (defender.defence - attacker.dribbling) + 0.10 * angle, 0.12, 0.85)
	if rng.randf() < clean_win:
		attacker.cooldown = 60
		tackles[defender.team] += 1
		take_control(defender.id, "tackle")
	else:
		# Contact from behind can be a foul; a failed legal challenge remains ordinary play.
		if angle > 0.45 and rng.randf() < clampf(0.08 + (80-defender.defence)*0.001,0.02,0.14):
			fouls[defender.team] += 1
			emit_event("foul",defender.id,{"victim":attacker.id})
			award_restart(attacker.team,ball,"free_kick",defender.id)
		else: emit_event("challenge", defender.id)

func emit_event(kind: String, actor: int, extra: Dictionary = {}) -> void:
	var event := {"kind": kind, "actor": actor, "team": players[actor].team if actor >= 0 else -1,
		"tick": ticks, "minute": display_minute(), "position": ball}
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
	for p in players:
		result.append([p.position, p.target, p.cooldown])
	return result
