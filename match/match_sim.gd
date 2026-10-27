extends RefCounted
## The match owns outcomes. Rendering and commentary only consume this state.

enum BallState { CONTROLLED, FLIGHT, LOOSE, DEAD }
const DT := 1.0 / 60.0
const FIELD := Vector2(105, 68)
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
var last_touch := 9
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

func _init(seed_value: int = 11027) -> void:
	match_seed = seed_value
	rng.seed = seed_value
	for id in 22:
		var p := Footballer.new()
		p.id = id
		p.team = id / 11
		p.name = NAMES[id]
		p.pace = rng.randi_range(58, 82)
		p.passing = rng.randi_range(58, 82)
		p.shooting = rng.randi_range(55, 80)
		p.defence = rng.randi_range(55, 80)
		p.dribbling = rng.randi_range(58, 80)
		p.keeping = rng.randi_range(65, 80) if id % 11 == 0 else 35
		players.append(p)
	reset_shape(0)
	emit_event("kickoff", owner)

func direction(team: int) -> float:
	return 1.0 if team == 0 else -1.0

func oriented(point: Vector2, team: int) -> Vector2:
	return point if team == 0 else FIELD - point

func reset_shape(kicking_team: int) -> void:
	for p in players:
		var anchor: Vector2 = ANCHORS[p.id % 11]
		p.position = oriented(Vector2(anchor.x * 0.6, anchor.y), p.team)
		p.previous = p.position
		p.target = p.position
		p.cooldown = 0
	owner = kicking_team * 11 + 9
	players[owner].position = Vector2(51.5 if kicking_team == 0 else 53.5, 34)
	players[owner].previous = players[owner].position
	ball = players[owner].position
	previous_ball = ball
	ball_state = BallState.CONTROLLED
	last_touch = owner
	held_ticks = 0

func step() -> void:
	ticks += 1
	active_ticks += 1
	previous_ball = ball
	for p in players:
		p.previous = p.position
		p.cooldown = maxi(0, p.cooldown - 1)
	if ticks % 15 == 1:
		choose_targets()
	move_players()
	if ball_state == BallState.CONTROLLED:
		held_ticks += 1
		possession_ticks[players[owner].team] += 1
		ball = players[owner].position
		challenge_carrier()
		if owner >= 0 and ticks % 15 == 1 and held_ticks >= 42:
			choose_action()
	elif ball_state == BallState.FLIGHT:
		advance_flight()
	elif ball_state == BallState.LOOSE:
		for p in players:
			if p.position.distance_to(ball) < 1.3:
				take_control(p.id)
				break
	if ball.x < 0 or ball.x > 105 or ball.y < 0 or ball.y > 68:
		ball = ball.clamp(Vector2(1, 1), FIELD - Vector2.ONE)
		ball_state = BallState.LOOSE
		owner = -1
		emit_event("out", last_touch)

func choose_targets() -> void:
	var team_in_control := players[owner].team if owner >= 0 else players[last_touch].team
	for p in players:
		var local_ball := oriented(ball, p.team)
		var anchor: Vector2 = ANCHORS[p.id % 11]
		var shift := (local_ball.x - 52.5) * 0.4 + (8 if p.team == team_in_control else -10)
		if p.id % 11 == 0:
			p.target = oriented(Vector2(5.5, clampf(local_ball.y, 27, 41)), p.team)
		else:
			p.target = oriented(Vector2(clampf(anchor.x + shift, 12, 95), clampf(anchor.y + (local_ball.y - 34) * 0.15, 4, 64)), p.team)
	if owner >= 0:
		var carrier := players[owner]
		carrier.target = (carrier.position + Vector2(direction(carrier.team) * 9, (34 - carrier.position.y) * 0.1)).clamp(Vector2(1, 2), Vector2(104, 66))
		var chaser := nearest(1 - carrier.team, ball, false)
		players[chaser].target = ball
	elif ball_state == BallState.LOOSE:
		for team in 2:
			players[nearest(team, ball, false)].target = ball
	elif ball_state == BallState.FLIGHT:
		for team in 2:
			players[nearest(team, flight_target, false)].target = flight_target

func nearest(team: int, point: Vector2, include_keeper: bool = true) -> int:
	var result := team * 11 + 1
	var distance := INF
	for p in players:
		if p.team != team or (not include_keeper and p.id % 11 == 0):
			continue
		var candidate := p.position.distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			result = p.id
	return result

func move_players() -> void:
	for p in players:
		var separation := Vector2.ZERO
		for other in players:
			if other.id == p.id:
				continue
			var offset := p.previous - other.previous
			var distance := offset.length()
			if distance > 0.01 and distance < 2.5:
				separation += offset / distance * (2.5 - distance)
		var movement_speed := 5.2 + 3.0 * p.pace / 120.0
		if owner == p.id:
			movement_speed *= 0.87
		p.position = p.position.move_toward(p.target + separation, movement_speed * DT).clamp(Vector2(1, 1), FIELD - Vector2.ONE)

func take_control(id: int, kind: String = "recovery") -> void:
	owner = id
	last_touch = id
	ball_state = BallState.CONTROLLED
	ball = players[id].position
	held_ticks = 0
	players[id].cooldown = maxi(players[id].cooldown, 18)
	emit_event(kind, id)

func lane_risk(from: Vector2, to: Vector2, team: int) -> float:
	var result := 0.0
	for p in players:
		if p.team == team:
			continue
		var along := segment_fraction(p.position, from, to)
		if along > 0.08 and along < 0.96:
			var distance := p.position.distance_to(from.lerp(to, along))
			result = maxf(result, clampf(1 - distance / 4.5, 0, 1))
	return result

func segment_fraction(point: Vector2, from: Vector2, to: Vector2) -> float:
	var delta := to - from
	return clampf((point - from).dot(delta) / maxf(delta.length_squared(), 0.00001), 0, 1)

func choose_action() -> void:
	var carrier := players[owner]
	var nearest_defender := nearest(1 - carrier.team, carrier.position)
	var pressure := clampf(1 - players[nearest_defender].position.distance_to(carrier.position) / 6, 0, 1)
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
		var score := progress * 0.6 + space * 0.9 - length * 0.13 - lane_risk(carrier.position, p.position, carrier.team) * 15
		score += rng.randf_range(-2, 2)
		if score > best_score:
			best_score = score
			best = p.id
	# ponytail: local lane heuristics; expand only after match outliers show a need.
	if best >= 0 and (pressure > 0.25 or held_ticks > 100 or best_score > 13):
		pass_to(best, pressure)

func pass_to(receiver: int, pressure: float = 0) -> void:
	var passer := players[owner]
	var aim := players[receiver].position
	var length := ball.distance_to(aim)
	var accuracy := clampf(0.88 + 0.002 * (passer.passing - 80) - 0.10 * pressure - 0.18 * minf(length / 55, 1) - 0.12 * lane_risk(ball, aim, passer.team), 0.25, 0.98)
	if rng.randf() > accuracy:
		aim += Vector2(rng.randf_range(-4.5, 4.5), rng.randf_range(-4.5, 4.5))
	pass_attempts[passer.team] += 1
	launch_ball(aim, 18 + passer.passing * 0.1, "pass")
	emit_event("pass", passer.id, {"receiver": receiver})

func launch_ball(aim: Vector2, velocity: float, kind: String) -> void:
	flight_source = owner
	last_touch = owner
	flight_target = aim
	flight_kind = kind
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
		var along := segment_fraction(p.position, from, destination)
		if p.position.distance_to(from.lerp(destination, along)) < 1.25 and along < first:
			contact = p.id
			first = along
	if contact >= 0:
		var same_team := players[contact].team == players[flight_source].team
		if same_team:
			completed_passes[players[contact].team] += 1
		take_control(contact, "received" if same_team else "interception")
		return
	ball = destination
	if ball.distance_to(flight_target) <= ball_velocity.length() * DT or (flight_target - ball).dot(ball_velocity) <= 0:
		ball_state = BallState.LOOSE
		ball_velocity = Vector2.ZERO

func challenge_carrier() -> void:
	if held_ticks < 18:
		return
	var attacker := players[owner]
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
		emit_event("challenge", defender.id)

func emit_event(kind: String, actor: int, extra: Dictionary = {}) -> void:
	var event := {"kind": kind, "actor": actor, "team": players[actor].team if actor >= 0 else -1,
		"tick": ticks, "minute": int(active_ticks / 40), "position": ball}
	event.merge(extra)
	events.append(event)

func signature() -> Array:
	var result: Array = [ticks, active_ticks, ball_state, ball, owner, last_touch, held_ticks,
		ball_velocity, flight_target, flight_source, flight_kind, rng.state, scores.duplicate(),
		possession_ticks.duplicate(), pass_attempts.duplicate(), completed_passes.duplicate(),
		tackles.duplicate(), events.duplicate(true)]
	for p in players:
		result.append([p.position, p.target, p.cooldown])
	return result
