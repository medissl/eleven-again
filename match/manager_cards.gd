extends RefCounted
## Event-conditioned run tactics. No card changes scores, shot geometry or unreachable contacts.
const BASE_IDS := ["lightning_counter","one_touch","iron_wall","wide_overload","dead_ball","high_press","deep_playmaker","last_stand"]
const TACTIC_IDS := ["keeper_outlet","cutback_pattern","aerial_duel"]
const COMBO_IDS := ["passing_triangle","wing_partnership","last_line"]
const DEFINITIONS := {
	"keeper_outlet":{"name":"Keeper Outlet","icon":"long_throw","effect":"Keeper passes over 20m: accuracy +4pp.","counter":"Close the keeper's long outlet."},
	"cutback_pattern":{"name":"Cutback Pattern","icon":"cutback","effect":"Actual cutback deliveries: pass accuracy +5pp.","counter":"Protect the byline and mark the penalty spot."},
	"aerial_duel":{"name":"Aerial Duel","icon":"aerial_fortress","effect":"Reachable contested headers: aerial win chance +5pp.","counter":"Keep the ball on the ground."},
	"passing_triangle":{"name":"Passing Triangle","icon":"third_man","effect":"Two active midfielders with signature traits: central midfield passes +3pp.","counter":"Disrupt the midfield or force wide passes."},
	"wing_partnership":{"name":"Wing Partnership","icon":"overlap_engine","effect":"An active winger and fullback with signature traits: cross accuracy +4pp.","counter":"Isolate the wide pair and deny crosses."},
	"last_line":{"name":"Last Line","icon":"body_block","effect":"Two active CB/DM with defensive traits: difficult interception control +4pp.","counter":"Attack the flanks and avoid difficult central passes."},
	"lightning_counter":{"name":"Lightning Counter","icon":"bullet_pass","effect":"After an interception: immediate forward pass +6pp; its next shot +4pp.","counter":"Close the forward lane; the window lasts three active seconds."},
	"one_touch":{"name":"One-Touch Football","icon":"wall_pass","effect":"Three completed forward central passes: next shot +5pp. Twice per half.","counter":"Break possession or force play wide."},
	"iron_wall":{"name":"Iron Wall","icon":"anticipator","effect":"CB/DM difficult interception control +5pp. Team release tempo 3% slower.","counter":"Switch play and press the slower release."},
	"wide_overload":{"name":"Wide Overload","icon":"whipped_cross","effect":"After a completed wide advance: cross accuracy +7pp. Less preference for central passes.","counter":"Block the flank and challenge the aerial delivery."},
	"dead_ball":{"name":"Dead-Ball Specialists","icon":"dead_ball_artist","effect":"Real direct free kicks, penalties and corner headers: shot accuracy +6pp.","counter":"Avoid conceding dangerous restarts; mark the receiver."},
	"high_press":{"name":"High Press Trap","icon":"screen","effect":"First 30 minutes: difficult interception control +6pp. More fatigue and a higher defensive line.","counter":"Play behind the press; exploit the extra fatigue."},
	"deep_playmaker":{"name":"Deep Playmaker","icon":"switch_play","effect":"Completed CM/DM pass over 25m: next shot +4pp. Once per possession.","counter":"Deny the deep passer or win possession before the shot."},
	"last_stand":{"name":"Last Stand","icon":"power_strike","effect":"Trailing after 70 minutes: pass/shot accuracy +5pp; difficult recovery control -4pp.","counter":"Counter into the riskier shape and protect your lead."}
}

static func team_state() -> Dictionary:
	return {"streak":0,"half":-1,"one_touch_uses":0,"counter_until":-1,"counter_actor":-1,"counter_shot":-1,"deep_shot":-1,"deep_used":false,"wide_until":-1,"pending":{},"tempo_fraction":0.0}
static func empty() -> Array: return [team_state(),team_state()]
static func reset_possession(state: Dictionary) -> Dictionary:
	var clean := team_state()
	clean.half=state.half
	clean.one_touch_uses=state.one_touch_uses
	clean.tempo_fraction=state.tempo_fraction
	return clean
static func valid(cards: Variant, state: Variant) -> bool:
	if cards is not Array or cards.size() != 2 or state is not Array or state.size() != 2: return false
	for team in 2:
		if cards[team] is not Array or cards[team].size() > 3 or state[team] is not Dictionary: return false
		var seen := []
		for id in cards[team]:
			if not DEFINITIONS.has(id) or id in seen: return false
			seen.append(id)
		for key in team_state():
			if typeof(state[team].get(key)) != typeof(team_state()[key]): return false
		if state[team].streak < 0 or state[team].streak > 3 or state[team].one_touch_uses not in [0,1,2]: return false
		if not is_finite(state[team].tempo_fraction) or state[team].tempo_fraction < 0 or state[team].tempo_fraction >= 1: return false
		if not state[team].pending.is_empty():
			for key in ["forward","central","counter","deep","wide"]:
				if state[team].pending.get(key) is not bool: return false
	return true
static func has(m, team: int, id: String) -> bool: return id in m.manager_cards[team]
static func trailing(m, team: int) -> bool: return m.display_minute() >= 70 and m.scores[team] < m.scores[1-team]
static func trait_count(m, team: int, roles: Array, traits: Array = []) -> int:
	var count := 0
	for player in m.players:
		if player.active and player.team == team and player.role in roles and not player.card.trait_id.is_empty() and (traits.is_empty() or player.card.trait_id in traits): count+=1
	return count

static func control(m, id: int, kind: String) -> void:
	if m.manager_cards == [[],[]]: return
	var player=m.players[id]
	var team: int=player.team
	var state: Dictionary=m.manager_state[team]
	if kind in ["interception","tackle","recovery","smother","hold"]:
		m.manager_state[1-team]=reset_possession(m.manager_state[1-team])
		state.streak=0
		if kind == "interception" and has(m,team,"lightning_counter"):
			state.counter_until=m.active_ticks+60
			state.counter_actor=id
	if kind == "received" and not state.pending.is_empty():
		var pending: Dictionary=state.pending
		if pending.forward and pending.central: state.streak=mini(3,state.streak+1)
		else: state.streak=0
		if pending.counter: state.counter_shot=m.active_ticks+180
		if pending.deep and not state.deep_used: state.deep_shot=m.active_ticks+180; state.deep_used=true
		if pending.wide: state.wide_until=m.active_ticks+180
	state.pending={}
	if has(m,team,"iron_wall"):
		# Carry fractional ticks so a 3% tradeoff does not become a whole-tick 6-12% penalty.
		state.tempo_fraction+=maxi(0,player.ready_tick-m.active_ticks)*0.03
		var delay := floori(state.tempo_fraction)
		player.ready_tick+=delay
		state.tempo_fraction-=delay

static func pass_started(m, id: int, context: Dictionary) -> void:
	if m.manager_cards == [[],[]]: return
	var p=m.players[id]
	var state: Dictionary=m.manager_state[p.team]
	state.pending={"forward":context.progress > 1,"central":context.central,"counter":has(m,p.team,"lightning_counter") and state.counter_actor == id and m.active_ticks <= state.counter_until and context.progress > 1,"deep":has(m,p.team,"deep_playmaker") and p.role in ["CM","DM"] and context.length > 25,"wide":has(m,p.team,"wide_overload") and context.progress > 1 and context.wide}
	state.counter_until=-1

static func contributions(m, id: int, kind: String, context: Dictionary) -> Array:
	var p=m.players[id]
	var team: int=p.team
	var state: Dictionary=m.manager_state[team]
	var result := []
	var half: int=m.period
	if state.half != half: state.one_touch_uses=0; state.half=half
	if kind == "pass_accuracy":
		if has(m,team,"keeper_outlet") and p.role == "GK" and context.get("length",0) > 20: result.append({"id":"keeper_outlet","amount":0.04})
		if has(m,team,"cutback_pattern") and context.get("delivery") == "cutback": result.append({"id":"cutback_pattern","amount":0.05})
		if has(m,team,"passing_triangle") and p.role in ["DM","CM","AM"] and context.get("central",false) and trait_count(m,team,["DM","CM","AM"]) >= 2: result.append({"id":"passing_triangle","amount":0.03})
		if has(m,team,"wing_partnership") and context.get("delivery") == "cross" and trait_count(m,team,["LW","RW"]) >= 1 and trait_count(m,team,["LB","RB"]) >= 1: result.append({"id":"wing_partnership","amount":0.04})
		if has(m,team,"lightning_counter") and state.counter_actor == id and m.active_ticks <= state.counter_until and context.get("progress",0) > 1: result.append({"id":"lightning_counter","amount":0.06})
		if has(m,team,"wide_overload") and m.active_ticks <= state.wide_until and context.get("delivery") == "cross": result.append({"id":"wide_overload","amount":0.07})
	if kind == "shot_accuracy":
		if has(m,team,"lightning_counter") and m.active_ticks <= state.counter_shot:
			result.append({"id":"lightning_counter","amount":0.04}); state.counter_shot=-1
		if has(m,team,"one_touch") and state.streak >= 3 and state.one_touch_uses < 2:
			result.append({"id":"one_touch","amount":0.05}); state.streak=0; state.one_touch_uses+=1
		if has(m,team,"deep_playmaker") and m.active_ticks <= state.deep_shot:
			result.append({"id":"deep_playmaker","amount":0.04}); state.deep_shot=-1
		if has(m,team,"dead_ball") and (context.get("restart") in ["free_kick","penalty"] or context.get("from_corner",false)): result.append({"id":"dead_ball","amount":0.06})
	if kind == "interception_control":
		if has(m,team,"last_line") and trait_count(m,team,["CB","DM"],["anticipator","screen","anchor","body_block"]) >= 2: result.append({"id":"last_line","amount":0.04})
		if has(m,team,"iron_wall") and p.role in ["CB","DM"]: result.append({"id":"iron_wall","amount":0.05})
		if has(m,team,"high_press") and m.display_minute() < 30: result.append({"id":"high_press","amount":0.06})
	if kind == "aerial_contest" and has(m,team,"aerial_duel"): result.append({"id":"aerial_duel","amount":0.05})
	if has(m,team,"last_stand") and trailing(m,team):
		if kind in ["shot_accuracy","pass_accuracy"]: result.append({"id":"last_stand","amount":0.05})
		elif kind in ["interception_control","receive_control"]: result.append({"id":"last_stand","amount":-0.04})
	return result

static func fatigue(m, team: int) -> float:
	return 1.2 if has(m,team,"high_press") and m.display_minute() < 30 else 1.0
static func pass_preference(m, team: int, wide: bool) -> float:
	return (1.5 if wide else -1.5) if has(m,team,"wide_overload") else 0.0
