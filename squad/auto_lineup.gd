extends RefCounted
## Maximum effective slot OVR with one player per slot; stable ties and a trained goalkeeper.
static func apply(plan: Resource, unavailable: Array = []) -> bool:
	var candidates: Array[int] = []
	for index in plan.cards.size():
		if plan.cards[index].person_id not in unavailable: candidates.append(index)
	if candidates.size() < 11: return false
	var roles: Array = plan.ROLES[plan.formation]
	var u := PackedInt64Array(); u.resize(12)
	var v := PackedInt64Array(); v.resize(candidates.size()+1)
	var p := PackedInt32Array(); p.resize(candidates.size()+1)
	var way := PackedInt32Array(); way.resize(candidates.size()+1)
	for slot in range(1,12):
		p[0] = slot
		var current := 0
		var best := PackedInt64Array(); best.resize(candidates.size()+1); best.fill(100000000)
		var used := PackedByteArray(); used.resize(candidates.size()+1)
		while true:
			used[current] = 1
			var assigned := p[current]
			var delta := 100000000
			var next := 0
			for option in range(1,candidates.size()+1):
				if used[option]: continue
				var card: Resource = plan.cards[candidates[option-1]]
				var cost: int = 10000000 if roles[assigned-1] == "GK" and "GK" not in card.natural_roles else -card.rating(roles[assigned-1],true)*1000+candidates[option-1]
				var reduced := cost-u[assigned]-v[option]
				if reduced < best[option]: best[option]=reduced; way[option]=current
				if best[option] < delta: delta=best[option]; next=option
			for option in range(candidates.size()+1):
				if used[option]: u[p[option]]+=delta; v[option]-=delta
				else: best[option]-=delta
			current = next
			if p[current] == 0: break
		while current != 0:
			var previous := way[current]
			p[current] = p[previous]
			current = previous
	var starters: Array[int] = []
	starters.resize(11)
	for option in range(1,candidates.size()+1):
		if p[option] > 0: starters[p[option]-1]=candidates[option-1]
	if "GK" not in plan.cards[starters[0]].natural_roles: return false
	plan.starters = starters
	plan.refresh_bench_order()
	return true
