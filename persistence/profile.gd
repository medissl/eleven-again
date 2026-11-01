extends RefCounted
const State = preload("res://run/run_state.gd")
const Records = preload("res://run/records.gd")

static func empty() -> Dictionary:
	return {"schema":1,"generation":0,"transaction_id":"","discoveries":{},"runs":{}}

static func project(previous: Dictionary, run: Dictionary, generation: int, transaction_id: String, utc_date: String) -> Dictionary:
	var data := previous.duplicate(true)
	data.generation = generation
	data.transaction_id = transaction_id
	for acquisition in run.acquisitions:
		if not data.discoveries.has(acquisition.card_id): data.discoveries[acquisition.card_id] = {"person_id":acquisition.person_id,"first_discovered":utc_date,"run_ids":[]}
		var entry: Dictionary = data.discoveries[acquisition.card_id]
		if run.run_id not in entry.run_ids: entry.run_ids.append(run.run_id)
	data.runs[run.run_id] = Records.summary(run)
	return data

static func error(data: Variant, content: RefCounted) -> String:
	if data is not Dictionary or not State.plain_finite(data) or data.get("schema") != 1 or data.get("generation") is not int or data.generation < 0 or data.get("transaction_id") is not String or data.get("discoveries") is not Dictionary or data.get("runs") is not Dictionary: return "Invalid profile envelope."
	if data.size() != 5: return "Unexpected profile fields."
	if (data.generation == 0) != data.transaction_id.is_empty() or (data.generation == 0 and (not data.runs.is_empty() or not data.discoveries.is_empty())): return "Invalid profile transaction."
	var collectible: Array = content.recruits.map(func(card): return card.card_id)
	for id in data.discoveries:
		var entry = data.discoveries[id]
		if id not in collectible or entry is not Dictionary or entry.get("person_id") != content.cards[id].person_id or entry.get("first_discovered") is not String or entry.first_discovered.is_empty() or entry.get("run_ids") is not Array or entry.run_ids.is_empty(): return "Invalid discovered edition."
		var seen := []
		for run_id in entry.run_ids:
			if run_id is not String or not data.runs.has(run_id) or run_id in seen: return "Invalid discovery run."
			seen.append(run_id)
	for id in data.runs:
		var record = data.runs[id]
		if record is not Dictionary or record.get("run_id") != id or record.get("origin") not in content.countries or not content.supports_version(record.get("content_version")) or record.get("balance_version") is not String or record.get("outcome") not in ["active","won","lost","abandoned"]: return "Invalid run record."
		for key in ["wins","defeats","earnings","goal_difference"]:
			if record.get(key) is not int: return "Invalid record value."
		if record.wins < 0 or record.wins > 12 or record.defeats < 0 or record.defeats > 3: return "Invalid record progress."
		if (record.outcome == "won") != (record.wins == 12) or (record.outcome == "lost") != (record.defeats == 3): return "Invalid terminal record."
		var earnings := 0
		for stage in content.rules.stages.slice(0,record.wins): earnings += int(stage.win_prize)
		if record.earnings != earnings: return "Invalid record earnings."
		var eligible: Array = content.countries[record.origin].cards+collectible
		if not Records.valid(record.get("peak_xi"),content,eligible) or record.get("goals_by_card") is not Dictionary: return "Invalid XI/goals record."
		for card_id in record.goals_by_card:
			if card_id not in eligible or record.goals_by_card[card_id] is not int or record.goals_by_card[card_id] < 1: return "Invalid goals record."
	return ""

static func ranked(data: Dictionary) -> Array:
	var records: Array = data.runs.values().filter(func(record): return record.outcome != "active")
	records.sort_custom(Records.better)
	return records
