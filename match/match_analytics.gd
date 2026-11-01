extends RefCounted
## Diagnostics never roll RNG or decide football. Summary claims come from actual action/flight events.
static func empty(enabled: bool = false) -> Dictionary:
	return {"enabled":enabled,"opportunities":{},"probabilities":[]}

static func opportunity(data: Dictionary, card: String, trait_id: String, kind: String, tick: int, eligible: bool, ready: bool) -> void:
	if not data.enabled: return
	var key := card+"/"+kind
	var row: Dictionary=data.opportunities.get(key,{"card":card,"trait":trait_id,"kind":kind,"checks":0,"eligible":0,"ready":0,"last_tick":-1})
	if row.last_tick == tick: return
	row.last_tick=tick
	row.checks+=1
	row.eligible+=int(eligible)
	row.ready+=int(ready)
	data.opportunities[key]=row

static func probability(data: Dictionary, tick: int, actor: String, kind: String, base: float, value: float, sources: Array = []) -> void:
	if not data.enabled: return
	data.probabilities.append({"tick":tick,"actor_card":actor,"kind":kind,"base":base,"value":value,"sources":sources.duplicate(true)})

static func summary(events: Array, data: Dictionary = {}) -> Dictionary:
	var players := {}
	var managers := {}
	for event in events:
		var card: String=event.get("actor_card","")
		if event.kind.begins_with("trait_") and not card.is_empty():
			var row: Dictionary=players.get(card,{"card":card,"name":event.get("actor_name",card),"trait":event.get("trait",""),"activations":0,"executions":0,"successes":0,"partial":0,"failures":0,"goals":0})
			if event.kind == "trait_activation": row.activations+=1
			elif event.kind == "trait_execution": row.executions+=1
			elif event.kind == "trait_result":
				if event.get("state") == "success": row.successes+=1
				elif event.get("state") == "partial": row.partial+=1
				elif event.get("state") == "failed": row.failures+=1
				if event.get("reason") == "actual goal-line crossing": row.goals+=1
			players[card]=row
	for event in data.get("probabilities",[]):
		for source in event.sources:
			if source.get("applied",0.0) == 0: continue
			managers[source.id]=managers.get(source.id,0)+1
	var rows: Array=players.values()
	rows.sort_custom(func(a,b): return a.activations > b.activations if a.activations != b.activations else a.card < b.card)
	return {"players":rows,"manager_actions":managers,"opportunities":data.get("opportunities",{}).duplicate(true)}

static func valid(data: Variant) -> bool:
	if data is not Dictionary or data.get("enabled") is not bool or data.get("opportunities") is not Dictionary or data.get("probabilities") is not Array: return false
	for row in data.opportunities.values():
		if row is not Dictionary: return false
		for key in ["checks","eligible","ready","last_tick"]:
			if row.get(key) is not int or row[key] < -1: return false
	for row in data.probabilities:
		if row is not Dictionary or row.get("base") is not float or row.get("value") is not float or not is_finite(row.base) or not is_finite(row.value) or row.get("sources") is not Array: return false
	return true
