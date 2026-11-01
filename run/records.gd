extends RefCounted
const Lineup = preload("res://squad/lineup.gd")

static func capture(plan: Resource, unavailable: Array = []) -> Dictionary:
	if plan == null or not plan.errors().is_empty(): return {}
	var result := {"formation":plan.formation,"cards":[],"ratings":[],"total":0}
	for slot in 11:
		var card: Resource = plan.cards[plan.starters[slot]]
		if card.person_id in unavailable or card.card_id.begins_with("academy_"): return {}
		var rating: int = card.rating(Lineup.ROLES[plan.formation][slot],true)
		result.cards.append(card.card_id)
		result.ratings.append(rating)
		result.total += rating
	return result

static func valid(record: Variant, content: RefCounted, eligible_ids: Array) -> bool:
	if record is not Dictionary or record.get("formation") not in Lineup.ROLES or record.get("cards") is not Array or record.cards.size() != 11 or record.get("ratings") is not Array or record.ratings.size() != 11 or record.get("total") is not int: return false
	var people := []
	var total := 0
	for slot in 11:
		var card: Resource = content.cards.get(record.cards[slot])
		if card == null or card.card_id not in eligible_ids or card.person_id in people or (slot == 0 and "GK" not in card.natural_roles): return false
		people.append(card.person_id)
		var rating: int = card.rating(Lineup.ROLES[record.formation][slot],true)
		if record.ratings[slot] is not int or record.ratings[slot] != rating: return false
		total += rating
	return record.total == total

static func summary(data: Dictionary) -> Dictionary:
	var result := {"run_id":data.run_id,"origin":data.origin,"content_version":data.content_version,"balance_version":"campaign_v1_unmeasured","outcome":data.step if data.step in ["won","lost","abandoned"] else "active","wins":data.wins,"defeats":data.defeats,"earnings":data.earnings,"peak_xi":data.peak_xi.duplicate(true),"goal_difference":0,"goals_by_card":{}}
	if data.get("content_version") == "campaign_roguelite_v3":
		result.balance_version="master_v1_unmeasured"
		result.completed_nodes=data.node
		result.reward_receipts=data.reward_receipts.duplicate(true)
		result.legacy_marks=load("res://run/manager_legacy.gd").marks(data)
		result.marks_receipts=data.marks_receipts.duplicate(true)
	for attempt in data.ledger:
		result.goal_difference += int(attempt.report.scores[0])-int(attempt.report.scores[1])
		for event in attempt.report.events:
			if event.kind != "goal" or event.get("team",-1) != 0 or event.get("own_goal",false): continue
			var id: String = event.get("actor_card","")
			if not id.is_empty() and not id.begins_with("academy_"): result.goals_by_card[id] = result.goals_by_card.get(id,0)+1
	return result

static func better(a: Dictionary, b: Dictionary) -> bool:
	if b.is_empty(): return true
	for pair in [[int(a.outcome == "won"),int(b.outcome == "won")],[a.wins,b.wins],[-a.defeats,-b.defeats],[a.peak_xi.total,b.peak_xi.total],[a.goal_difference,b.goal_difference]]:
		if pair[0] != pair[1]: return pair[0] > pair[1]
	return a.run_id < b.run_id
