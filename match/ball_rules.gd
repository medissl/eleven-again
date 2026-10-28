extends RefCounted
## Ground-plane law boundaries. Height is supplied by the flight model, never the renderer.
const RADIUS := 0.11

static func contact_fraction(from: Vector2, to: Vector2, centre: Vector2, radius: float) -> float:
	var offset := from-centre
	if offset.length_squared() <= radius*radius: return 0.0
	var delta := to-from
	var a := delta.length_squared()
	if a < 0.0000001: return INF
	var b := 2*offset.dot(delta)
	var discriminant := b*b-4*a*(offset.length_squared()-radius*radius)
	if discriminant < 0: return INF
	var entry := (-b-sqrt(discriminant))/(2*a)
	return entry if entry >= 0 and entry <= 1 else INF

static func crossing(from: Vector2, to: Vector2) -> Dictionary:
	var first := 2.0
	var axis := -1
	var edge := 0.0
	for component in 2:
		var limit := 105.0 if component == 0 else 68.0
		var delta := to[component] - from[component]
		if absf(delta) < 0.000001: continue
		var boundary := limit + RADIUS if delta > 0 else -RADIUS
		var fraction := (boundary - from[component]) / delta
		if fraction >= 0 and fraction <= 1 and fraction < first:
			first = fraction
			axis = component
			edge = limit if delta > 0 else 0.0
	if axis < 0: return {}
	var point := from.lerp(to, first)
	point[axis] = edge
	return {"axis": axis, "edge": edge, "point": point.clamp(Vector2.ZERO, Vector2(105,68)), "fraction": first}

static func resolve(model, from: Vector2, to: Vector2) -> bool:
	var hit := crossing(from, to)
	if hit.is_empty(): return false
	var touch: int = model.last_touch
	var touching_team: int = model.players[touch].team
	model.ball = hit.point
	if hit.axis == 1:
		model.award_restart(1-touching_team, hit.point, "throw_in", touch)
		return true
	var attacking_team := 0 if model.direction(0) == (1.0 if hit.edge > 0 else -1.0) else 1
	if absf(hit.point.y-34) + RADIUS <= 3.66 and model.ball_height <= 2.44-RADIUS:
		if model.restart_untouched and (attacking_team != model.restart_kick_team or model.restart_delivery in ["throw_in","indirect_free_kick"]):
			if attacking_team != model.restart_kick_team: model.award_restart(attacking_team,Vector2(hit.edge,0 if hit.point.y < 34 else 68),"corner",touch)
			else: model.award_restart(1-attacking_team,model.oriented(Vector2(5.5,34),1-attacking_team),"goal_kick",touch)
		else: model.goal_scored(touch, attacking_team)
	elif touching_team == attacking_team:
		if model.flight_kind == "shot": model.emit_event("miss", model.flight_source)
		model.award_restart(1-attacking_team, model.oriented(Vector2(5.5,34),1-attacking_team), "goal_kick", touch)
	else:
		model.award_restart(attacking_team, Vector2(hit.edge,0 if hit.point.y < 34 else 68), "corner", touch)
	return true
