extends "res://tests/roguelite_economy_checks.gd"
const Legacy=preload("res://run/manager_legacy.gd")
const Profile=preload("res://persistence/profile.gd")
func settle(data: Dictionary) -> Dictionary:
	while data.step in ["recruit","manager","route"]:
		if data.step == "recruit": data=action(data,"skip_recruit")
		elif data.step == "manager": data=manager(data)
		else: data=action(data,"choose_route",[0])
	return data
func run() -> void:
	content=load("res://content/campaign.gd").new()
	var total := 0
	for id in Legacy.NODES: total+=Legacy.cost(id)
	check(Legacy.NODES.size() == 24 and total == 2820,"Exactly 24 nodes / 2820 Marks")
	var data := Rules.initial(content,"ENG",47,"legacy_fixture")
	data=action(data,"acquire",[data.offer.cards[0],""])
	for node in 12:
		data=settle(data)
		data=result(data,true)
		if data.step != "won": data=action(data,"continue_result")
	check(Rules.validate(data,content).is_empty() and Legacy.marks(data) == 565,"Perfect native-rules reducer clear earns 565")
	var profile := Profile.empty()
	for index in 5:
		var completed := data.duplicate(true)
		completed.run_id="legacy_credit_"+str(index)
		profile=Profile.project(profile,completed,index+1,"credit"+str(index),"2026-11-01T00:00:00Z")
		var same := Profile.project(profile,completed,index+1,"credit"+str(index),"2026-11-01T00:00:00Z")
		check(profile == same,"Repeat projection cannot award Marks twice")
	check(profile.schema == 2 and profile.legacy.marks == 2825 and Profile.error(profile,content).is_empty(),"Explicit schema1->2 migration with valid credited receipts")
	check(not Legacy.purchase(profile.legacy,"scouting2").is_empty(),"Prerequisite enforced")
	for branch in Legacy.BRANCHES:
		for level in range(1,5):
			check(Legacy.purchase(profile.legacy,branch+str(level)).is_empty(),"Purchase "+branch+str(level))
	check(profile.legacy.marks == 5 and Legacy.valid(profile.legacy,profile.runs),"All tree costs deducted exactly")
	check(not Legacy.purchase(profile.legacy,"scouting1").is_empty(),"Duplicate purchase rejected")
	var all_perks: Array=profile.legacy.purchased
	var rich := Rules.initial(content,"ENG",42,"perk_units",all_perks)
	rich=action(rich,"acquire",[rich.offer.cards[0],""])
	# Unit fixture grant exercises finite services; full run validator deliberately rejects fixture grants.
	check(Economy.receipt(rich,"fixture_grant",3000,"test").is_empty(),"Fixture funds")
	rich=action(rich,"open_market")
	check(rich.market.cards.size() == 7 and "scouting2" in rich.legacy_used,"Wider Network adds three actual listings")
	var bank: int=rich.cash
	rich=action(rich,"refresh_market")
	check(rich.cash == bank and "finance2" in rich.legacy_used,"One free refresh")
	rich=action(rich,"refresh_market")
	check(rich.cash == bank-45,"Second refresh charges normal price")
	rich=action(rich,"close_market")
	var player_id: String=rich.plan.cards[1].card_id
	rich=action(rich,"train",[player_id,"PAC"])
	check(rich.training.back().cost == 90,"Practice and first-session credits are real")
	rich=action(rich,"train_free",[player_id,"PAC"])
	check(rich.training.back().cost == 0 and "academy4" in rich.legacy_used,"One free training within two-session limit")
	var before := rich.duplicate(true)
	check(not Rules.apply(before,content,"train_free",[player_id,"PAC"]).is_empty(),"Free training cannot repeat")
	rich=action(rich,"buy_pack",["standard",""])
	check(rich.offer.cost == 50 and "finance1" in rich.legacy_used and "finance4" in rich.legacy_used,"Finite pack coupons")
	bank=rich.cash
	rich=action(rich,"reroll_pack")
	check(rich.cash == bank and "scouting3" in rich.legacy_used,"Free reroll once")
	rich=action(rich,"skip_recruit")
	rich=action(rich,"buy_pack",["position","CB"])
	check(rich.offer.cost == 200 and rich.offer.cards.slice(0,2).all(func(id): return content.cards[id].primary_role == "CB"),"Exact role target plus finite fit discounts")
	rich=action(rich,"skip_recruit")
	rich=action(rich,"fortune_advance")
	rich=action(rich,"fortune_double")
	bank=rich.cash
	rich=result(rich,true)
	check(rich.cash == bank+140,"Double win 200 less advance settlement 60")
	rich=action(rich,"continue_result")
	check(rich.manager_offer.size() == 5 and "tactics2" in rich.legacy_used and "chemistry4" in rich.legacy_used,"Two bounded extra Manager options")
	rich=action(rich,"reroll_manager")
	check(rich.manager_offer.size() == 3 and "chemistry2" in rich.legacy_used,"Free Manager reroll is finite")
	rich=manager(rich)
	# Full-featured reducer run: deterministic routes, extra Act II draft, pivot, boss training and World Stage stakes.
	var full := Rules.initial(content,"ENG",23,"all_perks_replay",all_perks)
	full=action(full,"acquire",[full.offer.cards[0],""])
	var draft_count := 0
	for node in 12:
		while full.step in ["recruit","manager","route"]:
			if full.step == "recruit": draft_count+=1; full=action(full,"skip_recruit")
			elif full.step == "manager": full=manager(full)
			else:
				if node == 2: check(Rules.routes(full,content).size() == 3,"One expanded route: "+str(Rules.routes(full,content))+" used "+str(full.legacy_used))
				full=action(full,"choose_route",[0])
		if node == 3:
			full=action(full,"train",[full.plan.cards[1].card_id,"PAC"])
			check(full.training.back().cost == 50,"Boss preparation credit applied")
		if node == 4: full=action(full,"pivot"); full=manager(full)
		if node == 8:
			full=action(full,"fortune_world",["wager"])
		full=result(full,true)
		if full.step != "won": full=action(full,"continue_result")
	check(draft_count == 7 and "fortune3" in full.legacy_used,"One extra Act II draft without rarity promise")
	check(Rules.validate(full,content).is_empty(),"All-perk run replays exactly")
	# Journalled purchases and next-run snapshot preserve existing profile history.
	var session := Session.new("user://legacy_checks_"+str(Time.get_ticks_usec()),content)
	var controller=load("res://run/roguelite_controller.gd").new(content)
	check(controller.restore(data).ok and session.persist(controller).ok,"Durable earned Marks")
	var generation: int=session.profile.generation
	check(session.buy_legacy("scouting1",generation).ok,"Journalled purchase")
	check(not session.buy_legacy("scouting2",generation).ok,"Stale purchase rejected")
	var reload := Session.new(session.store.directory,content)
	check(reload.profile.legacy.marks == 495 and reload.profile.legacy.purchased == ["scouting1"],"Purchase and Marks survive reload")
	check(reload.new_run("BRA",55,"next_with_legacy",false,true).ok and reload.controller.snapshot().legacy == ["scouting1"],"Next run snapshots owned Legacy")
	print("LEGACY: %d checks, %d failures; migration, 24 nodes, finite services, new options, exact Marks and journalled purchases" % [checks,failures])
	quit(1 if failures else 0)
