extends RefCounted
## Circle-centre positional approximation; penalise actual ball involvement, never position alone.
static func positioned(m, id: int, team: int) -> bool:
	var point: Vector2 = m.oriented(m.players[id].position,team)
	if point.x <= 52.5 or point.x <= m.oriented(m.ball,team).x+0.01: return false
	var defenders: Array[float] = []
	for p in m.players:
		if p.active and p.team != team: defenders.append(m.oriented(p.position,team).x)
	defenders.sort()
	if defenders.size() < 2: return false
	return point.x > defenders[defenders.size()-2]+0.01

static func capture(m, source: int) -> Dictionary:
	if m.current_restart in ["throw_in","corner","goal_kick"]: return {}
	var team: int = m.players[source].team
	var candidates: Array[int] = []
	for p in m.players:
		if p.active and p.team == team and p.id != source and positioned(m,p.id,team): candidates.append(p.id)
	return {"team":team,"source":source,"candidates":candidates,"tick":m.ticks}

static func involved(m, id: int) -> bool:
	if m.offside_context.is_empty() or id not in m.offside_context.candidates: return false
	var team: int = m.players[id].team
	var point: Vector2 = m.players[id].position
	m.emit_event("offside",id)
	m.award_restart(1-team,point,"indirect_free_kick",id)
	return true
