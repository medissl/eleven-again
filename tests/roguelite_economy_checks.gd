extends SceneTree
const Rules=preload("res://run/roguelite_rules.gd")
const Economy=preload("res://run/recruitment_economy.gd")
const Session=preload("res://persistence/campaign_session.gd")
var content: RefCounted
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func action(data: Dictionary, name: String, args: Array = []) -> Dictionary:
	var next := data.duplicate(true)
	var error := Rules.apply(next,content,name,args)
	check(error.is_empty(),name+": "+error)
	return next
func result(data: Dictionary, won: bool) -> Dictionary:
	# Reducer fixtures test scheduling/receipts. Actual native matches are a separate check.
	data=action(data,"commit_match",[Rules.Availability.plan(data).to_data()])
	return action(data,"finish_match",[{"winner":0 if won else 1,"scores":[1,0] if won else [0,1],"events":[],"shots":[1,1],"on_target":[1,1],"saves":[0,0],"completed":[0,0],"attempted":[0,0],"possession":[0,0],"penalties":[]}])
func manager(data: Dictionary) -> Dictionary:
	return action(data,"choose_manager",[data.manager_offer[0],data.managers[0] if data.managers.size() == 3 else ""]) if data.step == "manager" else data
func _initialize() -> void: call_deferred("run")
func run() -> void:
	content=load("res://content/campaign.gd").new()
	check(content.errors.is_empty(),"Content baseline")
	var originals := {}
	for id in content.cards: originals[id]=content.cards[id].to_data()
	var data := Rules.initial(content,"ENG",47,"economy_reducer")
	check(data.offer.cards.size() == 4 and data.cash == 0,"Opening draft and wallet")
	var blocked := data.duplicate(true)
	check(not Rules.apply(blocked,content,"skip_recruit",[]).is_empty(),"Opening signing required")
	data=action(data,"acquire",[data.offer.cards[0],""])
	check(data.step == "prepare" and data.plan.cards.size() == 17,"Signed opening card")
	var opening: Dictionary=data.duplicate(true)
	for node in 12:
		if data.step == "route": data=action(data,"choose_route",[node%2])
		check(data.node == node,"Scheduled node progression")
		data=result(data,true)
		if data.step == "won": break
		data=action(data,"continue_result")
		data=manager(data)
		if data.step == "recruit":
			check(data.node in [2,4,6,8,10,11] and data.offer.cards.size() == 4,"Six milestone drafts")
			data=action(data,"skip_recruit")
	check(data.node == 12 and data.wins == 12 and data.earnings == 1840 and data.cash == 1990,"Perfect clear receipts plus six 25-coin vouchers: "+str([data.node,data.wins,data.earnings,data.cash]))
	check(Rules.validate(data,content).is_empty(),"Full replay validation")
	var corrupt := data.duplicate(true)
	corrupt.cash+=1
	check(not Rules.validate(corrupt,content).is_empty(),"Reject edited wallet")
	corrupt=data.duplicate(true); corrupt.offers_rng="10"
	check(not Rules.validate(corrupt,content).is_empty(),"Reject changed draft stream")
	var losses := opening.duplicate(true)
	for node in 3:
		if losses.step == "route": losses=action(losses,"choose_route",[0])
		losses=result(losses,false)
		if losses.step == "lost": break
		losses=action(losses,"continue_result")
		losses=manager(losses)
		if losses.step == "recruit": losses=action(losses,"skip_recruit")
	check(losses.node == 3 and losses.defeats == 3 and losses.step == "lost","Loss advances and three defeats eliminate")
	# Replay final failures, including a later win: this node never pays twice.
	var final := opening.duplicate(true)
	for node in 11:
		if final.step == "route": final=action(final,"choose_route",[0])
		final=result(final,true); final=manager(action(final,"continue_result"))
		if final.step == "recruit": final=action(final,"skip_recruit")
	var bank: int=final.cash
	final=result(final,false); final=action(final,"continue_result")
	check(final.node == 11 and final.cash == bank+70,"Final retry consolation once")
	final=result(final,false); final=action(final,"continue_result")
	check(final.cash == bank+70,"No final loss farming")
	final=result(final,true)
	check(final.step == "won" and final.cash == bank+210 and final.earnings == 1840,"Final win tops up original reward")
	check(Rules.validate(final,content).is_empty(),"Final replay validation")
	# Training/release use owned copies and cannot mint money from starters.
	var rich := opening.duplicate(true)
	check(Economy.receipt(rich,"test_grant",2000,"test").is_empty(),"Test wallet")
	var id: String=rich.plan.cards[1].card_id
	check(Economy.train(rich,id,"PAC","train1").is_empty(),"First training")
	check(Economy.train(rich,id,"PAC","train2").is_empty(),"Second training")
	check(not Economy.train(rich,id,"PAC","train3").is_empty(),"Third training rejected")
	check(rich.plan.cards[1].attributes.PAC == originals[id].attributes.PAC+8,"Training gives eight actual stat points")
	var starter_id: String=rich.plan.cards[15].card_id
	bank=rich.cash
	check(Economy.release(rich,content,starter_id,"release").is_empty() and rich.cash == bank,"Starters cannot farm coins")
	check(not Economy.receipt(rich,"release",10,"release").is_empty(),"Duplicate receipt rejected")
	for card_id in originals: check(content.cards[card_id].to_data() == originals[card_id],"Canonical cards unchanged")
	# Real durable opening draft, stale revision, reload and legacy coexistence.
	var root := "user://master_economy_"+str(Time.get_ticks_usec())
	var session := Session.new(root,content)
	check(session.new_run("ENG",42,"native_master",false,true).ok,"Durable new-mode creation")
	var saved: Dictionary=session.controller.snapshot()
	var reload := Session.new(root,content)
	check(not reload.blocked and reload.controller.snapshot() == saved,"Reload preserves revealed offers and RNG")
	check(not reload.act("acquire",[saved.offer.cards[0],""],0).ok,"Stale action rejected")
	check(reload.act("acquire",[saved.offer.cards[0],""],saved.revision).ok,"Durable signing")
	check(not reload.act("acquire",[saved.offer.cards[0],""],saved.revision).ok,"Duplicate signing rejected")
	check(Session.new(root,content).controller.snapshot().plan.cards.size() == 17,"Signing survives fresh session")
	check(reload.new_run("BRA",23,"native_legacy",true).ok,"Legacy creation stays supported")
	check(Session.new(root,content).controller.snapshot().schema == 3,"Legacy schema untouched")
	print("ROGUELITE ECONOMY: %d checks, %d failures; reducer receipts, four-card drafts, training, compatibility and durable continuation" % [checks,failures])
	quit(1 if failures else 0)
