extends RefCounted
const State = preload("res://run/run_state.gd")
const Records = preload("res://run/records.gd")
const Legacy = preload("res://run/manager_legacy.gd")

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
	if run.content_version == "campaign_roguelite_v3":
		data.schema=2
		if not data.has("legacy"): data.legacy=Legacy.empty()
		var earned := Legacy.marks(run)
		data.legacy.marks+=maxi(0,earned-int(data.legacy.credited.get(run.run_id,0)))
		data.legacy.credited[run.run_id]=earned
	return data

static func error(data: Variant, content: RefCounted) -> String:
	if data is not Dictionary or not State.plain_finite(data) or data.get("schema") not in [1,2] or data.get("generation") is not int or data.generation < 0 or data.get("transaction_id") is not String or data.get("discoveries") is not Dictionary or data.get("runs") is not Dictionary: return "Invalid profile envelope."
	if data.size() != (6 if data.schema == 2 else 5): return "Unexpected profile fields."
	if data.schema == 2 and not Legacy.valid(data.get("legacy"),data.runs): return "Invalid Legacy balance or purchase receipts."
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
		var master: bool=record.content_version == "campaign_roguelite_v3"
		if (record.outcome == "won") != ((record.get("completed_nodes") == 12) if master else (record.wins == 12)) or (record.outcome == "lost") != (record.defeats == 3): return "Invalid terminal record."
		var earnings := 0
		if master:
			if record.get("completed_nodes") is not int or record.completed_nodes not in range(13) or record.get("marks_receipts") is not Dictionary or record.get("legacy_marks") is not int: return "Invalid master progress/Marks record."
			var marks := 0
			for key in record.marks_receipts:
				if key is not String or not key.is_valid_int() or int(key) not in range(12) or record.marks_receipts[key] not in [15,35]: return "Invalid unique-node Marks receipt."
				marks+=record.marks_receipts[key]
			for node in [4,8,12]:
				if record.completed_nodes >= node: marks+=15
			if record.outcome == "won": marks+=100
			if marks != record.legacy_marks: return "Invalid Legacy Marks total."
			if record.get("reward_receipts") is not Dictionary: return "Invalid master reward receipts."
			for key in record.reward_receipts:
				if key is not String or not key.is_valid_int() or int(key) not in range(12): return "Invalid reward node."
				var act: int=clampi(int(key)/4,0,2)
				if record.reward_receipts[key] not in [preload("res://content/master_balance.gd").DATA.win_coins_by_act[act],preload("res://content/master_balance.gd").DATA.loss_coins_by_act[act]]: return "Invalid master reward amount."
				earnings+=int(record.reward_receipts[key])
		else:
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
