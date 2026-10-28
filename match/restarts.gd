extends RefCounted
## Short dead-ball routines put real receivers and markers in place; outcomes stay physical.
static func place(m, id: int, point: Vector2) -> void:
	if id < 0: return
	m.players[id].position = point.clamp(Vector2.ONE,m.FIELD-Vector2.ONE)
	m.players[id].previous = m.players[id].position
	m.players[id].target = m.players[id].position
	m.players[id].velocity = Vector2.ZERO

static func role_player(m, team: int, roles: Array, excluded: Array = []) -> int:
	var best := -1
	for p in m.players:
		if not p.active or p.team != team or p.role not in roles or p.id in excluded: continue
		if best < 0 or m.attribute(p.id,"PHY") > m.attribute(best,"PHY"): best = p.id
	return best

static func arrange(m, team: int, kind: String, point: Vector2, taker: int) -> void:
	if kind == "corner":
		var top: bool = point.y < 34
		var striker := role_player(m,team,["ST"],[taker])
		var far := role_player(m,team,["LW","RW"],[taker,striker])
		var aerial := role_player(m,team,["CB"],[taker,striker,far])
		var outlet := role_player(m,team,["CM","AM"],[taker,striker,far,aerial])
		place(m,striker,m.oriented(Vector2(94,28 if top else 40),team))
		place(m,far,m.oriented(Vector2(96,42 if top else 26),team))
		place(m,aerial,m.oriented(Vector2(92,39 if top else 29),team))
		place(m,outlet,m.oriented(Vector2(84,34),team))
		var marked: Array = []
		for actor in [striker,far,aerial]:
			if actor < 0: continue
			var marker := role_player(m,1-team,["CB","DM","LB","RB"],marked)
			if marker >= 0:
				place(m,marker,m.players[actor].position+Vector2(m.direction(team)*1.4,0.5))
				marked.append(marker)
		place(m,m.keeper_id(1-team),m.oriented(Vector2(4,34),1-team))
	elif kind == "throw_in":
		var support: int = m.nearest(team,point,false,taker)
		place(m,support,point+Vector2(-m.direction(team)*5,7 if point.y < 34 else -7))
	elif kind == "goal_kick":
		var outlet := role_player(m,team,["CB"],[taker])
		place(m,outlet,m.oriented(Vector2(18,26),team))
		var holder := role_player(m,team,["DM","CM"],[taker,outlet])
		place(m,holder,m.oriented(Vector2(26,43),team))
	elif kind in ["free_kick","indirect_free_kick"]:
		var forward := role_player(m,team,["ST"],[taker])
		var local: Vector2 = m.oriented(point,team)
		place(m,forward,m.oriented(Vector2(minf(95,local.x+14),28 if local.y > 34 else 40),team))
		if local.x > 65:
			var wall: Array = []
			var to_goal: Vector2 = point.direction_to(m.oriented(Vector2(105,34),team))
			for offset in [-1.0,1.0]:
				var defender := role_player(m,1-team,["CB","DM"],wall)
				place(m,defender,point+to_goal*9.2+to_goal.orthogonal()*offset)
				wall.append(defender)
