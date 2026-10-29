extends RefCounted
## Attempts use the ordinary physical shot/keeper path. Only the tally is separate.
static func start(m) -> void:
	m.Traits.stop(m)
	m.period = m.Period.SHOOTOUT
	var orders: Array = [[],[]]
	for team in 2:
		for slot in m.plans[team].penalty_order:
			if m.players[team*11+slot].active: orders[team].append(team*11+slot)
	var equal_count := mini(orders[0].size(),orders[1].size())
	for team in 2:
		var keeper: int = m.keeper_id(team)
		orders[team].resize(equal_count)
		if keeper not in orders[team]: orders[team][-1] = keeper
	m.shootout = {"team":0,"attempts":[0,0],"goals":[0,0],"order":orders,"phase":"setup","remaining":36,"actor":-1,"keeper":-1}
	m.start_restart(0,m.CENTRE,"shootout",0)
	m.emit_event("shootout_start",-1)
	arrange(m)

static func arrange(m) -> void:
	var team: int = m.shootout.team
	var order: Array = m.shootout.order[team]
	var actor: int = order[m.shootout.attempts[team]%order.size()]
	var keeper: int = m.keeper_id(1-team)
	m.shootout.actor = actor
	m.shootout.keeper = keeper
	for p in m.players:
		p.position = Vector2(44+p.team*12,9+(p.id%11)*4.8)
		p.previous = p.position
		p.velocity = Vector2.ZERO
		p.trait_state.clear()
		p.shootout_trait_used = false
	m.players[actor].position = Vector2(92.3,34)
	m.players[actor].facing = Vector2.RIGHT
	m.players[keeper].position = Vector2(104.8,34)
	m.players[keeper].facing = Vector2.LEFT
	m.ball = Vector2(94,34)
	m.previous_ball = m.ball
	m.ball_height = 0
	m.owner = -1
	m.ball_state = m.BallState.DEAD
	m.emit_event("shootout_setup",actor)

static func step(m) -> void:
	m.ticks += 1
	m.previous_ball = m.ball
	if m.shootout.phase == "flight":
		if m.ball_state == m.BallState.FLIGHT: m.advance_flight()
		elif m.ball_state == m.BallState.LOOSE:
			m.advance_loose(false)
		if m.shootout.phase == "flight" and (m.ball_state in [m.BallState.CONTROLLED,m.BallState.DEAD] or (m.ball_state == m.BallState.LOOSE and m.ball_velocity.length() < 0.4)): finish_attempt(m,false)
		return
	m.shootout.remaining -= 1
	if m.shootout.remaining > 0: return
	if m.shootout.phase == "wait":
		m.shootout.team = 1-m.shootout.team
		m.shootout.phase = "setup"
		m.shootout.remaining = 36
		arrange(m)
		return
	m.owner = m.shootout.actor
	m.last_touch = m.owner
	m.current_restart = "penalty"
	m.shootout.phase = "flight"
	m.shoot()
	m.current_restart = ""

static func clinched(state: Dictionary) -> bool:
	var attempts: Array = state.attempts
	var score: Array = state.goals
	if attempts[0] <= 5 and attempts[1] <= 5:
		if score[0] > score[1]+(5-attempts[1]) or score[1] > score[0]+(5-attempts[0]): return true
	return attempts[0] >= 5 and attempts[0] == attempts[1] and score[0] != score[1]

static func finish_attempt(m, scored: bool) -> void:
	if m.shootout.phase != "flight": return
	if not scored: m.Traits.resolve(m,m.flight_trait_actor,m.flight_trait_action,"failed","shootout attempt did not score")
	var team: int = m.shootout.team
	m.shootout.attempts[team] += 1
	if scored: m.shootout.goals[team] += 1
	m.emit_event("shootout_goal" if scored else "shootout_miss",m.shootout.actor,{"penalties":m.shootout.goals.duplicate()})
	m.owner = -1
	m.ball_velocity = Vector2.ZERO
	m.ball_state = m.BallState.DEAD
	m.shootout.phase = "wait"
	m.shootout.remaining = 40
	if clinched(m.shootout): m.finish_match()
