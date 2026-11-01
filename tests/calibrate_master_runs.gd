extends SceneTree
## Actual native football only. JSONL receipts are flushed after each complete run and safely resumable.
const Controller=preload("res://run/roguelite_controller.gd")
const Rules=preload("res://run/roguelite_rules.gd")
const Auto=preload("res://squad/auto_lineup.gd")
const Runner=preload("res://match/fast_forward.gd")
var content: RefCounted
var policy := "baseline"
var target := 1000
var first_seed := 1
var output := ""
var controller: RefCounted
var shopping := {}
var matches := []

func act(action: String, args: Array = []) -> void:
	var result: Dictionary=controller.perform(action,args,controller.revision())
	assert(result.ok,action+": "+str(result))

func total(plan: Resource) -> int:
	var result := 0
	for slot in 11: result+=plan.cards[plan.starters[slot]].rating(Rules.Lineup.ROLES[plan.formation][slot],true)
	return result

func best_plan(plan: Resource) -> Resource:
	var best: Resource=plan.duplicate(true)
	assert(Auto.apply(best))
	if policy == "informed":
		for formation in Rules.Lineup.ROLES:
			var candidate: Resource=plan.duplicate(true)
			candidate.formation=formation
			assert(Auto.apply(candidate))
			if total(candidate) > total(best): best=candidate
	return best

func outgoing(data: Dictionary, candidate: Resource) -> String:
	if data.plan.cards.size() < 18: return ""
	var cards: Array=data.plan.cards.map(func(record): return Rules.Economy.Card.from_data(record))
	var keepers: int=cards.filter(func(card): return "GK" in card.natural_roles).size()
	cards=cards.filter(func(card): return not (keepers == 1 and "GK" in card.natural_roles and "GK" not in candidate.natural_roles))
	cards.sort_custom(func(a,b): return a.rating() < b.rating() if a.rating() != b.rating() else a.card_id < b.card_id)
	return cards[0].card_id

func candidate_score(data: Dictionary, id: String) -> float:
	var candidate: Resource=content.cards[id]
	if policy == "baseline": return candidate.rating()
	var owned: Resource=Rules.Lineup.from_data(data.plan)
	var before: int=total(best_plan(owned))
	var replace := outgoing(data,candidate)
	if replace.is_empty(): owned.cards.append(Rules.Economy.Card.from_data(candidate.to_data()))
	else:
		var index: int=owned.cards.find_custom(func(card): return card.card_id == replace)
		owned.cards[index]=Rules.Economy.Card.from_data(candidate.to_data())
	# Fit evaluates the actual best legal XI, never a win-probability formula.
	return total(best_plan(owned))-before

func manager_score(data: Dictionary, id: String) -> float:
	var value: float={"lightning_counter":6.0,"one_touch":4.0,"iron_wall":4.0,"wide_overload":5.0,"dead_ball":2.0,"high_press":3.0,"deep_playmaker":5.0,"last_stand":2.0}.get(id,3.0)
	if id == "wide_overload" and data.plan.cards.filter(func(card): return card.primary_role in ["LW","RW","LB","RB"] and not card.trait_id.is_empty()).size() >= 3: value+=2
	return value

func choose_draft(data: Dictionary) -> void:
	var cards: Array=data.offer.cards.duplicate()
	cards.sort_custom(func(a,b):
		var first: float=candidate_score(data,a)
		var second: float=candidate_score(data,b)
		return first > second if first != second else a < b)
	if data.step != "opening_recruit" and policy == "informed" and candidate_score(data,cards[0]) <= 0: act("skip_recruit"); return
	act("acquire",[cards[0],outgoing(data,content.cards[cards[0]])])

func prepare(data: Dictionary) -> void:
	if not shopping.has(data.node):
		shopping[data.node]=true
		var kind := "standard"
		var group := ""
		if policy == "informed" and data.cash >= 480 and data.node >= 8: kind="elite"
		elif policy == "informed" and data.cash >= 280:
			kind="position"
			var plan: Resource=best_plan(Rules.Lineup.from_data(data.plan))
			var weakest := 0
			for slot in 11:
				if plan.cards[plan.starters[slot]].rating(Rules.Lineup.ROLES[plan.formation][slot],true) < plan.cards[plan.starters[weakest]].rating(Rules.Lineup.ROLES[plan.formation][weakest],true): weakest=slot
			var role: String=Rules.Lineup.ROLES[plan.formation][weakest]
			for key in Rules.Economy.Packs.GROUPS:
				if role in Rules.Economy.Packs.GROUPS[key]: group=key
		if data.cash >= Rules.Balance.cost(kind): act("buy_pack",[kind,group]); return
	var plan: Resource=best_plan(controller.preparation_plan())
	if policy == "informed":
		var opponent: Dictionary=content.clubs[data.fixtures[data.node].club_id]
		plan.attack="counter" if opponent.defence == "high_press" else "possession"
		if "wide_overload" in data.managers: plan.route="wide"; plan.width=1.15
	act("commit_match",[plan])

func resolve_match() -> void:
	var model: RefCounted=controller.model
	var started := Time.get_ticks_usec()
	var runner := Runner.new(model)
	while not runner.advance(1000,0): pass
	var opportunities := {"checks":0,"eligible":0,"ready":0}
	for row in model.analytics.opportunities.values():
		for key in opportunities: opportunities[key]+=row[key]
	var impact: Dictionary=model.Analytics.summary(model.events,model.analytics)
	matches.append({"node":controller._state.node+1,"seed":model.match_seed,"winner":model.winner(),"scores":model.scores.duplicate(),"shots":model.shots.duplicate(),"on_target":model.shots_on_target.duplicate(),"passes":model.completed_passes.duplicate(),"saves":model.saves.duplicate(),"ticks":model.ticks,"active_ticks":model.active_ticks,"elapsed_seconds":(Time.get_ticks_usec()-started)/1000000.0,"opportunities":opportunities,"trait_activations":impact.players.reduce(func(sum,row): return sum+row.activations,0),"trait_executions":impact.players.reduce(func(sum,row): return sum+row.executions,0),"trait_successes":impact.players.reduce(func(sum,row): return sum+row.successes,0),"manager_modified_actions":impact.manager_actions})
	act("finish_match")

func run_seed(seed_value: int) -> Dictionary:
	controller=Controller.new(content)
	assert(controller.start(["ENG","BRA","FRA","JPN","IDN","ARG"][posmod(seed_value-1,6)],seed_value,"calibration_"+policy+"_"+str(seed_value)).ok)
	shopping={}; matches=[]
	var started := Time.get_ticks_usec()
	for decision in 256:
		var data: Dictionary=controller._state
		match data.step:
			"opening_recruit","recruit": choose_draft(data)
			"prepare": prepare(data)
			"match": resolve_match()
			"result": act("continue_result")
			"route":
				var options := Rules.routes(data,content)
				var selected := 0
				if policy == "informed":
					for index in options.size():
						if content.xi_rating(content.opponent_plan(options[index].variant_id)) < content.xi_rating(content.opponent_plan(options[selected].variant_id)): selected=index
				act("choose_route",[selected])
			"manager":
				var offers: Array=data.manager_offer.duplicate()
				var replace := ""
				if policy == "informed":
					offers.sort_custom(func(a,b): return manager_score(data,a) > manager_score(data,b) if manager_score(data,a) != manager_score(data,b) else a < b)
				if data.managers.size() == 3:
					var owned: Array=data.managers.duplicate()
					owned.sort_custom(func(a,b): return manager_score(data,a) < manager_score(data,b) if manager_score(data,a) != manager_score(data,b) else a < b)
					replace=owned[0]
					if policy == "informed" and manager_score(data,offers[0]) <= manager_score(data,replace): act("skip_manager"); continue
				act("choose_manager",[offers[0],replace])
			"won","lost":
				assert(Rules.validate(controller.snapshot(),content).is_empty(),"Each completed run validates against its deterministic decision receipts")
				return {"type":"run","seed":seed_value,"policy":policy,"origin":data.origin,"outcome":data.step,"completed_nodes":data.node,"wins":data.wins,"defeats":data.defeats,"cash":data.cash,"base_match_earnings":data.earnings,"spent":-data.wallet.filter(func(row): return row.amount < 0).reduce(func(sum,row): return sum+row.amount,0),"marks":Rules.Legacy.marks(data),"acquisitions":data.acquisitions.size(),"packs":data.packs.size(),"rerolls":data.wallet.filter(func(row): return row.kind == "reroll").size(),"training_sessions":data.training.size(),"managers":data.managers.duplicate(),"matches":matches.duplicate(true),"elapsed_seconds":(Time.get_ticks_usec()-started)/1000000.0}
	assert(false,"Bot exceeded the bounded campaign decision count")
	return {}

func sources_hash() -> String:
	var paths := ["res://tests/calibrate_master_runs.gd"]
	for directory in ["res://match","res://run","res://squad","res://content","res://content/campaign"]:
		for file in DirAccess.get_files_at(directory):
			if file.get_extension() in ["gd","json","tres"]: paths.append(directory+"/"+file)
	paths.sort()
	var hashes := ""
	for path in paths: hashes+=path+":"+FileAccess.get_sha256(path)+"\n"
	return hashes.sha256_text()

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(0,args.size(),2):
		assert(index+1 < args.size())
		match args[index]:
			"--policy": policy=args[index+1]
			"--runs": target=int(args[index+1])
			"--seed": first_seed=int(args[index+1])
			"--output": output=args[index+1]
			_: assert(false,"Unknown batch argument")
	assert(policy in ["baseline","informed"] and target > 0 and first_seed > 0)
	if output.is_empty(): output="res://reports/master-brief/calibration-"+policy+".jsonl"
	content=load("res://content/campaign.gd").new()
	assert(content.errors.is_empty())
	var fingerprint := sources_hash()
	var completed := []
	if FileAccess.file_exists(output):
		var existing := FileAccess.open(output,FileAccess.READ)
		var header: Variant=JSON.parse_string(existing.get_line())
		assert(header is Dictionary and header.get("sources_sha256") == fingerprint and header.get("policy") == policy and header.get("engine") == Engine.get_version_info().string,"Refuse mixing code, policy or engine generations in a calibration receipt")
		while not existing.eof_reached():
			var line := existing.get_line()
			if line.is_empty(): continue
			var row: Variant=JSON.parse_string(line)
			assert(row is Dictionary and row.get("type") == "run" and row.get("seed") is float and int(row.seed) not in completed,"Incomplete or duplicate run receipt")
			completed.append(int(row.seed))
		existing.close()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var file := FileAccess.open(output,FileAccess.READ_WRITE if FileAccess.file_exists(output) else FileAccess.WRITE_READ)
	file.seek_end()
	if file.get_length() == 0:
		file.store_line(JSON.stringify({"type":"header","sources_sha256":fingerprint,"engine":Engine.get_version_info().string,"policy":policy,"regulation_active_seconds":180,"legacy_snapshot":[],"minimum_required_runs":1000,"note":"Actual native football, no sampled win-rate table. Pilot samples do not satisfy calibration acceptance."}))
	for seed_value in range(first_seed,first_seed+target):
		if seed_value in completed: continue
		var receipt := run_seed(seed_value)
		file.store_line(JSON.stringify(receipt)); file.flush()
		print("CALIBRATION ",policy," seed=",seed_value," outcome=",receipt.outcome," nodes=",receipt.completed_nodes," wins=",receipt.wins," seconds=",snappedf(receipt.elapsed_seconds,0.01))
	file.close()
	print("CALIBRATION BATCH COMPLETE ",policy," seeds ",first_seed,"..",first_seed+target-1)
	quit()
