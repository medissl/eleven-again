extends RefCounted
## Permanent options; each economic concession is finite and snapshotted at run creation.
const COSTS := [70,100,130,170]
const BRANCHES := ["scouting","tactics","finance","academy","chemistry","fortune"]
const NODES := {
	"scouting1":["First Contact","One Position pack costs 40 fewer coins each run."],
	"scouting2":["Wider Network","The first direct market adds three extra candidates."],
	"scouting3":["Second Look","One draft reroll is free each run."],
	"scouting4":["Specialist Search","Position packs can target an exact role, where two candidates remain."],
	"tactics1":["New Playbook","Adds Keeper Outlet, Cutback Pattern and Aerial Duel to Manager offers."],
	"tactics2":["Plan B","Your next Manager event offers one extra choice, once per run."],
	"tactics3":["Route Analyst","The next route decision adds a third opponent option, once per run."],
	"tactics4":["Halfway Pivot","Once in Act II, open a free Manager swap event."],
	"finance1":["Signing Coupon","One paid scouting pack costs 40 fewer coins each run."],
	"finance2":["Fresh Listings","One market refresh is free each run."],
	"finance3":["Sell-On Clause","Release values gain 5%, still below the rarity caps."],
	"finance4":["Scout Contract","One Standard pack costs 90 fewer coins each run."],
	"academy1":["Practice Credit","One training session costs 20 fewer coins each run."],
	"academy2":["Early Session","The first training session costs 30 fewer coins."],
	"academy3":["Final Preparation","One training session before a boss costs 40 fewer coins."],
	"academy4":["Breakthrough","One free +4 session each run, within the two-session player cap."],
	"chemistry1":["Fit Scout","One Position pack costs 40 fewer coins each run."],
	"chemistry2":["Tactical Conversation","Reroll one Manager choice event free each run."],
	"chemistry3":["Combinations","Adds Passing Triangle, Wing Partnership and Last Line Manager Cards."],
	"chemistry4":["Fresh Perspective","Your next Manager event offers one extra choice, once per run."],
	"fortune1":["Cash Advance","Optional once: take 40 coins now; the next winning node pays 60 fewer."],
	"fortune2":["Double or Nothing","Optional once: the next node pays double for a win, zero for a loss."],
	"fortune3":["Extra Invitation","One additional Standard draft after the Act II boss. No rarity guarantee."],
	"fortune4":["World Stage Stakes","Before Act III, choose an optional 120-coin loan with an extra defeat on the next loss, or stake 100 for a 200-coin win bonus."]
}

static func empty() -> Dictionary: return {"marks":0,"purchased":[],"credited":{}}
static func cost(id: String) -> int: return COSTS[int(id.right(1))-1] if NODES.has(id) else -1
static func prerequisites(id: String, purchased: Array) -> bool:
	return NODES.has(id) and (id.ends_with("1") or id.left(-1)+str(int(id.right(1))-1) in purchased)
static func valid_ids(ids: Variant) -> bool:
	if ids is not Array or ids.size() > 24: return false
	var seen := []
	for id in ids:
		if id is not String or id in seen or not prerequisites(id,ids): return false
		seen.append(id)
	return true
static func valid(data: Variant, records: Dictionary) -> bool:
	if data is not Dictionary or data.size() != 3 or data.get("marks") is not int or data.marks < 0 or not valid_ids(data.get("purchased")) or data.get("credited") is not Dictionary: return false
	var earned := 0
	for run_id in data.credited:
		if not records.has(run_id) or records[run_id].get("legacy_marks") != data.credited[run_id] or data.credited[run_id] is not int or data.credited[run_id] < 0: return false
		earned+=data.credited[run_id]
	for id in data.purchased: earned-=cost(id)
	return data.marks == earned
static func purchase(data: Dictionary, id: String) -> String:
	if id in data.purchased: return "This Legacy node is already owned."
	if not prerequisites(id,data.purchased): return "Unlock the preceding node on this branch."
	if data.marks < cost(id): return "Not enough Legacy Marks."
	data.marks-=cost(id); data.purchased.append(id)
	return ""
static func marks(run: Dictionary) -> int:
	var total := 0
	for value in run.marks_receipts.values(): total+=int(value)
	for node in [4,8,12]:
		if run.node >= node: total+=15
	if run.step == "won": total+=100
	return total
static func available(data: Dictionary, id: String) -> bool: return id in data.legacy and id not in data.legacy_used
static func consume(data: Dictionary, id: String) -> bool:
	if not available(data,id): return false
	data.legacy_used.append(id)
	return true
