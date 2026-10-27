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
	elif ball_state == BallState.LOOSE:
		for p in players:
			if p.position.distance_to(ball) < 1.3:
				take_control(p.id)
				break

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
	else:
		for team in 2:
			players[nearest(team, ball, false)].target = ball

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

func emit_event(kind: String, actor: int, extra: Dictionary = {}) -> void:
	var event := {"kind": kind, "actor": actor, "team": players[actor].team if actor >= 0 else -1,
		"tick": ticks, "minute": int(active_ticks / 40), "position": ball}
	event.merge(extra)
	events.append(event)

func signature() -> Array:
	var result: Array = [ticks, active_ticks, ball_state, ball, owner, rng.state, scores.duplicate(), events.duplicate(true)]
	for p in players:
		result.append([p.position, p.target, p.cooldown])
	return result
