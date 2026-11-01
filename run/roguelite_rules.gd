extends RefCounted
## Replayable new-run rules. Every committed decision is replayed when validating a save.
## Legacy campaign controllers/data never enter this ruleset.
const Balance=preload("res://content/master_balance.gd")
const Economy=preload("res://run/recruitment_economy.gd")
const Lineup=preload("res://squad/lineup.gd")
const Records=preload("res://run/records.gd")
const Availability=preload("res://run/availability.gd")
const Managers=preload("res://match/manager_cards.gd")
const Legacy=preload("res://run/manager_legacy.gd")

static func initial(content: RefCounted, origin: String, seed_value: int, run_id: String, perks: Array = []) -> Dictionary:
	if not content.errors.is_empty() or not content.countries.has(origin) or run_id.is_empty(): return {}
	var plan: Resource=content.country_plan(origin)
	var data := Economy.empty(plan,seed_value)
	data.merge({"schema":4,"content_version":Balance.VERSION,"origin":origin,"seed":seed_value,"run_id":run_id,"revision":1,"node":0,"wins":0,"defeats":0,"earnings":0,"step":"opening_recruit","fixtures":content.itinerary(seed_value),"ledger":[],"history":[],"queue":[],"principles":[],"managers":[],"manager_offer":[],"manager_rng":"","market":{},"coaching":[],"current_attempt":{},"match_snapshot":{},"peak_xi":Records.capture(plan),"discipline":{},"abandoned_attempt":{},"routes":{},"reward_receipts":{},"marks_receipts":{},"legacy":[],"legacy_used":[]})
	for stream_name in ["attempts","manager","market"]:
		var rng := RandomNumberGenerator.new()
		rng.seed=seed_value ^ {"attempts":31027,"manager":41027,"market":21027}[stream_name]
		data[stream_name+"_rng"]=str(rng.state)
	if not Legacy.valid_ids(perks): return {}
	data.legacy=perks.duplicate()
	data.risks={}
	data.view_mode="live"
	if not Economy.open_pack(data,content,1,"starter","",run_id+"/opening",true).is_empty(): return {}
	return data

static func receipt_id(data: Dictionary) -> String:
	return data.run_id+"/decision/"+str(data.history.size()+1)

static func pack_quote(data: Dictionary, kind: String) -> Dictionary:
	var coupons := []
	var discount := 0
	for perk in ["finance1","finance4","scouting1","chemistry1"]:
		if Legacy.available(data,perk) and (perk == "finance1" or (perk == "finance4" and kind == "standard") or (perk in ["scouting1","chemistry1"] and kind == "position")):
			coupons.append(perk); discount+=90 if perk == "finance4" else 40
	return {"cost":maxi(0,Balance.cost(kind)-discount),"discount":discount,"coupons":coupons}

static func training_quote(data: Dictionary, free: bool = false) -> Dictionary:
	var coupons := []
	var discount := 0
	if free:
		if Legacy.available(data,"academy4"): coupons=["academy4"]; discount=140
	else:
		for perk in ["academy1","academy2","academy3"]:
			if Legacy.available(data,perk) and (perk == "academy1" or (perk == "academy2" and data.training.is_empty()) or (perk == "academy3" and data.node in [3,7,11])):
				coupons.append(perk); discount+={"academy1":20,"academy2":30,"academy3":40}[perk]
	return {"cost":maxi(0,140-discount),"discount":discount,"coupons":coupons}

static func manager_offer(data: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.state=int(data.manager_rng)
	var pool: Array=Managers.BASE_IDS.duplicate()
	if "tactics1" in data.legacy: pool.append_array(Managers.TACTIC_IDS)
	if "chemistry3" in data.legacy: pool.append_array(Managers.COMBO_IDS)
	var available: Array=pool.filter(func(id): return id not in data.managers)
	available.sort()
	var count: int=3+int(Legacy.consume(data,"tactics2"))+int(Legacy.consume(data,"chemistry4"))
	data.manager_offer=[]
	for index in mini(count,available.size()): data.manager_offer.append(available.pop_at(rng.randi_range(0,available.size()-1)))
	data.manager_rng=str(rng.state)

static func finish_step(data: Dictionary, content: RefCounted) -> String:
	if not data.queue.is_empty():
		data.step=data.queue.pop_front()
		if data.step == "manager": manager_offer(data)
		if data.step == "recruit": return Economy.open_pack(data,content,Balance.act(maxi(0,data.node-1)),"standard","",receipt_id(data)+"/earned",true)
		return ""
	data.step="route" if data.node+1 in Balance.DATA.route_before_nodes and not data.routes.has(str(data.node)) else "prepare"
	return ""

static func routes(data: Dictionary, content: RefCounted) -> Array:
	var current: Dictionary=data.fixtures[data.node]
	var faced: Array=data.fixtures.slice((data.node/4)*4,data.node).map(func(fixture): return fixture.club_id)
	var alternatives: Array=content.variants.values().filter(func(row): return int(row.stage) == data.node+1 and row.team_id != current.club_id and row.team_id not in faced and not content.road_aliases.has(row.team_id))
	alternatives.sort_custom(func(a,b): return a.id < b.id)
	if alternatives.is_empty(): return [current]
	var alternate: Dictionary=alternatives[abs(data.seed+data.node)%alternatives.size()]
	var result: Array=[current,{"stage":data.node+1,"club_id":alternate.team_id,"variant_id":alternate.id}]
	if Legacy.available(data,"tactics3"):
		var third: Array=alternatives.filter(func(row): return row.id != alternate.id)
		if not third.is_empty(): result.append({"stage":data.node+1,"club_id":third[0].team_id,"variant_id":third[0].id})
	return result

static func same_owned(plan: Resource, expected: Resource) -> bool:
	if plan == null or not plan.errors().is_empty() or expected == null or plan.cards.size() != expected.cards.size(): return false
	var records := {}
	for card in expected.cards: records[card.card_id]=card.to_data()
	for card in plan.cards:
		if records.get(card.card_id) != card.to_data(): return false
	return true

static func restock(data: Dictionary, content: RefCounted, refresh: bool) -> String:
	var rng := RandomNumberGenerator.new()
	rng.state=int(data.market_rng)
	var stock := Economy.Packs.generate(content.recruits,Balance.act(data.node),"standard","",Economy.excluded(data),rng)
	if not stock.ok: return stock.error
	if Legacy.available(data,"scouting2"):
		var people: Array=Economy.excluded(data)
		for id in stock.cards: people.append(content.cards[id].person_id)
		var extra := Economy.Packs.generate(content.recruits,Balance.act(data.node),"standard","",people,rng)
		if extra.ok: stock.cards.append_array(extra.cards.slice(0,3)); Legacy.consume(data,"scouting2")
	var free: bool=refresh and Legacy.available(data,"finance2")
	var error := Economy.receipt(data,receipt_id(data),-Balance.cost("refresh") if refresh and not free else 0,"market_refresh" if refresh else "market_open")
	if not error.is_empty(): return error
	if free: Legacy.consume(data,"finance2")
	data.market_rng=str(rng.state)
	data.market={"id":receipt_id(data),"cards":stock.cards,"purchased":[],"node":data.node}
	return ""

static func apply(data: Dictionary, content: RefCounted, action: String, args: Array) -> String:
	var id := receipt_id(data)
	var error := ""
	match action:
		"set_viewing_mode":
			if data.step != "prepare" or args.size() != 1 or args[0] not in ["live","highlights","instant"]: return "Choose a match viewing mode before kickoff."
			data.view_mode=args[0]
		"fortune_advance","fortune_double","fortune_world":
			if data.step != "prepare": return "Legacy opportunities are available between matches."
			var perk: String={"fortune_advance":"fortune1","fortune_double":"fortune2","fortune_world":"fortune4"}[action]
			if not Legacy.available(data,perk): return "This opportunity has already been used."
			if action == "fortune_world":
				if data.node != 8 or args.size() != 1 or args[0] not in ["loan","wager"]: return "Choose the optional World Stage stake before node nine."
				error=Economy.receipt(data,id,120 if args[0] == "loan" else -100,"fortune_"+args[0])
				if error.is_empty(): data.risks[args[0]]=true
			else:
				if not args.is_empty(): return "Invalid opportunity."
				if action == "fortune_advance": error=Economy.receipt(data,id,40,"fortune_advance")
				if error.is_empty(): data.risks["advance" if action == "fortune_advance" else "double"]=true
			if error.is_empty(): Legacy.consume(data,perk)
		"pivot":
			if data.step != "prepare" or Balance.act(data.node) != 2 or not args.is_empty() or not Legacy.consume(data,"tactics4"): return "The free tactical pivot is available once in Act II."
			data.step="manager"; manager_offer(data)
		"reroll_manager":
			if data.step != "manager" or not args.is_empty() or not Legacy.consume(data,"chemistry2"): return "No free Manager reroll remains."
			manager_offer(data)
		"reveal_pack":
			if data.step not in ["opening_recruit","recruit"] or not args.is_empty() or data.offer.presentation_seen: return "This reveal has already been presented."
			data.offer.presentation_seen=true
		"choose_manager":
			if data.step != "manager" or args.size() != 2 or args[0] not in data.manager_offer or args[1] is not String: return "Choose one offered Manager Card."
			if data.managers.size() == 3:
				if args[1] not in data.managers: return "Replace one of your three equipped Manager Cards."
				data.managers.erase(args[1])
			elif not args[1].is_empty(): return "No Manager replacement is needed."
			data.managers.append(args[0])
			data.manager_offer=[]
			error=finish_step(data,content)
		"skip_manager":
			if data.step != "manager" or not args.is_empty(): return "No Manager choice to decline."
			data.manager_offer=[]
			error=finish_step(data,content)
		"open_market":
			if data.step != "prepare" or not args.is_empty(): return "The market is available between matches."
			if data.market.is_empty() or data.market.node != data.node: error=restock(data,content,false)
			if error.is_empty(): data.step="market"
		"close_market":
			if data.step != "market" or not args.is_empty(): return "No open market."
			data.step="prepare"
		"refresh_market":
			if data.step != "market" or not args.is_empty(): return "No market to refresh."
			error=restock(data,content,true)
		"sign_market":
			if data.step != "market" or args.size() != 2 or args[0] is not String or args[1] is not String or args[0] not in data.market.cards or args[0] in data.market.purchased: return "Choose an available market player."
			error=Economy.sign(data,content,args[0],args[1],id,true)
			if error.is_empty(): data.market.purchased.append(args[0])
		"acquire":
			if data.step not in ["opening_recruit","recruit"] or args.size() != 2 or args[0] is not String or args[1] is not String: return "No draft signing is available."
			error=Economy.sign(data,content,args[0],args[1],id)
			if error.is_empty(): error=finish_step(data,content)
		"skip_recruit":
			if data.step != "recruit" or not args.is_empty(): return "No draft voucher is available."
			error=Economy.voucher(data,id)
			if error.is_empty(): error=finish_step(data,content)
		"buy_pack":
			if data.step != "prepare" or args.size() != 2 or args[0] not in ["standard","position","elite"] or args[1] is not String: return "Scouting is available between matches."
			if args[0] == "position" and args[1] not in Economy.Packs.GROUPS and "scouting4" not in data.legacy: return "Exact-role targeting requires Specialist Search; position groups are available now."
			var quote := pack_quote(data,args[0])
			error=Economy.open_pack(data,content,Balance.act(data.node),args[0],args[1],id,false,false,quote.discount)
			if error.is_empty():
				for perk in quote.coupons: Legacy.consume(data,perk)
				data.step="recruit"
		"reroll_pack":
			if data.step != "recruit" or not args.is_empty(): return "No draft to reroll."
			var free: bool=Legacy.available(data,"scouting3")
			error=Economy.open_pack(data,content,int(data.offer.act),data.offer.kind,data.offer.target,id,free,true)
			if error.is_empty() and free: Legacy.consume(data,"scouting3")
		"train","train_free":
			if data.step != "prepare" or args.size() != 2 or args[0] is not String or args[1] is not String: return "Training is available between matches."
			if action == "train_free" and not Legacy.available(data,"academy4"): return "The free training session has been used."
			var quote := training_quote(data,action == "train_free")
			error=Economy.train(data,args[0],args[1],id,quote.discount)
			if error.is_empty():
				for perk in quote.coupons: Legacy.consume(data,perk)
		"release":
			if data.step != "prepare" or args.size() != 1 or args[0] is not String: return "Release is available between matches."
			error=Economy.release(data,content,args[0],id)
		"update_plan":
			if data.step != "prepare" or args.size() != 1 or args[0] is not Dictionary: return "No editable squad."
			var plan: Resource=Lineup.from_data(args[0])
			if not same_owned(plan,Lineup.from_data(data.plan)): return "Squad editing changed an owned player definition."
			data.plan=plan.to_data()
		"choose_route":
			if data.step != "route" or args.size() != 1 or args[0] is not int: return "No route choice."
			var options := routes(data,content)
			if args[0] < 0 or args[0] >= options.size(): return "Choose a visible route."
			data.routes[str(data.node)]=options[args[0]].duplicate(true)
			Legacy.consume(data,"tactics3")
			data.fixtures[data.node]=options[args[0]].duplicate(true)
			data.step="prepare"
		"commit_match":
			if data.step != "prepare" or args.size() != 1 or args[0] is not Dictionary: return "No match to start."
			var plan: Resource=Lineup.from_data(args[0])
			if not same_owned(plan,Availability.plan(data)): return "Preparation changed an available player."
			data.plan=Availability.remember(Lineup.from_data(data.plan),plan).to_data()
			var rng := RandomNumberGenerator.new()
			rng.state=int(data.attempts_rng)
			data.current_attempt={"id":data.run_id+"/attempt/"+str(data.ledger.size()+1),"seed":rng.randi_range(1,2147483646),"stage":data.node+1,"fixture":data.fixtures[data.node].duplicate(true),"home_plan":plan.to_data(),"served":Availability.banned(data.discipline)}
			data.attempts_rng=str(rng.state)
			data.step="match"
		"finish_match":
			if data.step != "match" or args.size() != 1 or not valid_report(args[0]): return "The match result is incomplete."
			var report: Dictionary=args[0]
			var won: bool=report.winner == 0
			var node: int=data.node
			var act: int=Balance.act(node)
			var result: Dictionary=data.current_attempt.duplicate(true)
			result.report=report.duplicate(true)
			var earned: int=int(Balance.DATA[("win" if won else "loss")+"_coins_by_act"][act-1])
			var previously: int=data.reward_receipts.get(str(node),0)
			result.prize=maxi(0,earned-previously)
			if result.prize > 0:
				error=Economy.receipt(data,id,result.prize,"match_reward")
				data.reward_receipts[str(node)]=maxi(previously,earned)
				data.earnings+=result.prize
			var settlement := 0
			if data.risks.has("double"):
				settlement+=result.prize if won else -result.prize
				data.risks.erase("double")
			if data.risks.has("advance") and won: settlement-=60; data.risks.erase("advance")
			if data.risks.has("wager"):
				if won: settlement+=200
				data.risks.erase("wager")
			var extra_defeat: bool=not won and data.risks.has("loan")
			if extra_defeat: data.risks.erase("loan")
			if settlement != 0:
				error=Economy.receipt(data,id+"/fortune",settlement,"fortune_settlement")
				result.prize+=settlement
			# A failed final pays once. A later victory tops up the same node receipt.
			data.marks_receipts[str(node)]=maxi(int(data.marks_receipts.get(str(node),0)),35 if won else 15)
			data.discipline=Availability.advance(data.discipline,report.events,result.served,result.home_plan.cards)
			data.ledger.append(result)
			data.wins+=int(won)
			data.defeats=mini(3,data.defeats+int(not won)+int(extra_defeat))
			data.queue=[]
			if node < 11 or won: data.node+=1
			data.step="won" if node == 11 and won else "lost" if data.defeats >= 3 else "result"
			if data.step == "result" and data.node != node and data.node in Balance.DATA.draft_after_nodes:
				data.queue.append("recruit")
			if data.step == "result" and data.node != node and data.node in Balance.DATA.manager_after_nodes:
				data.queue.append("manager")
			if data.step == "result" and data.node == 8 and node == 7 and Legacy.consume(data,"fortune3"): data.queue.append("recruit")
			data.match_snapshot={}
		"continue_result":
			if data.step != "result" or not args.is_empty(): return "No result to continue."
			error=finish_step(data,content)
		"abandon":
			if data.step in ["won","lost","abandoned"] or not args.is_empty(): return "This run has already ended."
			data.step="abandoned"
			data.match_snapshot={}
			data.queue=[]
		_: return "Unknown roguelite action."
	if not error.is_empty(): return error
	var record := Records.capture(Lineup.from_data(data.plan),Availability.banned(data.discipline))
	# Records use canonical base OVR; training impact is separately retained in its ledger.
	if not record.is_empty():
		var canonical: Resource=Lineup.from_data(data.plan)
		for index in canonical.cards.size(): canonical.cards[index]=content.Card.from_data(content.cards[canonical.cards[index].card_id].to_data())
		record=Records.capture(canonical,Availability.banned(data.discipline))
		if not record.is_empty() and record.total > data.peak_xi.total: data.peak_xi=record
	data.history.append({"action":action,"args":args.duplicate(true)})
	data.revision+=1
	return ""

static func valid_report(report: Variant) -> bool:
	if report is not Dictionary or report.get("winner") not in [0,1] or report.get("scores") is not Array or report.scores.size() != 2 or report.get("events") is not Array: return false
	for score in report.scores:
		if score is not int or score < 0 or score > 100: return false
	for key in ["shots","on_target","saves","completed","attempted","possession","penalties"]:
		if report.get(key) is not Array or (report[key].size() != 2 and not (key == "penalties" and report[key].is_empty())): return false
		for value in report[key]:
			if value is not int or value < 0: return false
	for event in report.events:
		if event is not Dictionary or event.get("kind") is not String: return false
	return true

static func validate(data: Dictionary, content: RefCounted) -> String:
	if data.get("schema") != 4 or data.get("content_version") != Balance.VERSION or data.get("origin") is not String or data.get("seed") is not int or data.get("run_id") is not String or data.get("history") is not Array or data.history.size() > 512: return "Invalid roguelite envelope."
	if not Legacy.valid_ids(data.get("legacy")): return "Invalid starting Legacy snapshot."
	var expected := initial(content,data.origin,data.seed,data.run_id,data.legacy)
	if expected.is_empty(): return "Invalid origin or content."
	for row in data.history:
		if row is not Dictionary or row.get("action") is not String or row.get("args") is not Array: return "Invalid decision receipt."
		var error := apply(expected,content,row.action,row.args)
		if not error.is_empty(): return "Invalid decision history: "+error
	var actual := data.duplicate(true)
	for key in ["disk_generation","transaction_id","match_snapshot"]: actual.erase(key); expected.erase(key)
	if actual != expected: return "Run state differs from its deterministic decision receipts."
	if data.get("match_snapshot") is not Dictionary: return "Invalid match checkpoint."
	if data.step == "match":
		var model=load("res://match/match_snapshot.gd").restore(data.match_snapshot)
		if model == null or model.match_seed != data.current_attempt.seed or model.plans[0].to_data() != data.current_attempt.home_plan or model.plans[1].to_data() != content.opponent_plan(data.current_attempt.fixture.variant_id).to_data() or model.regulation_ticks != 10800 or not model.knockout or model.manager_cards != [data.managers,[]]: return "Match checkpoint does not match the committed fixture."
		if model.period not in model.Period.values() or model.ball_state not in model.BallState.values() or model.ticks < 0 or model.active_ticks < 0 or model.principles != [[],[]]: return "Invalid new-mode football state."
		for player in model.players:
			var approved: Array=model.plans[player.team].cards.filter(func(card): return card.card_id == player.card.card_id and card.to_data() == player.card.to_data())
			if approved.size() != 1 or player.role not in Economy.Card.WEIGHTS or player.stamina < 0 or player.stamina > 100: return "Changed or uncommitted match player."
			for key in model.ATTRIBUTE_FIELDS:
				if player.get(model.ATTRIBUTE_FIELDS[key]) != player.card.attributes.get(key,player.card.keeper_attributes.get(key)): return "Changed base match attribute."
	elif not data.match_snapshot.is_empty(): return "Unexpected match checkpoint."
	return ""
