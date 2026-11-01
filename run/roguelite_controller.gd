extends RefCounted
const Rules=preload("res://run/roguelite_rules.gd")
const Match=preload("res://match/match_sim.gd")
const Snapshot=preload("res://match/match_snapshot.gd")
var content: RefCounted
var model: RefCounted
var _state := {}

func _init(library: RefCounted) -> void: content=library
func revision() -> int: return int(_state.get("revision",0))
func snapshot() -> Dictionary:
	var data := _state.duplicate(true)
	if model != null and data.step == "match": data.match_snapshot=Snapshot.capture(model)
	return data
func failure(error: String) -> Dictionary: return {"ok":false,"error":error,"revision":revision()}
func restore(data: Dictionary) -> Dictionary:
	var error := Rules.validate(data,content)
	if not error.is_empty(): return failure(error)
	_state=data.duplicate(true)
	model=Snapshot.restore(data.match_snapshot) if data.step == "match" else null
	return {"ok":true,"revision":revision()}
func start(origin: String, seed_value: int, run_id: String, perks: Array = []) -> Dictionary:
	if not _state.is_empty(): return failure("This controller already holds a run.")
	var data := Rules.initial(content,origin,seed_value,run_id,perks)
	if data.is_empty(): return failure("Could not create the opening draft.")
	_state=data
	return {"ok":true,"revision":revision()}
func preparation_plan() -> Resource: return Rules.Availability.plan(_state)

func perform(action: String, args: Array, expected: int) -> Dictionary:
	if expected != revision(): return failure("This action is stale. Use the current run state.")
	var values := args.duplicate()
	if action in ["commit_match","update_plan"]:
		if args.size() != 1 or args[0] is not Resource or args[0].get_script() != Rules.Lineup: return failure("Choose a legal lineup.")
		values=[args[0].to_data()]
	elif action == "finish_match":
		if not args.is_empty() or model == null or not model.finished or model.winner() not in [0,1]: return failure("The committed match has not finished.")
		values=[model.snapshot_report()]
		values[0].impact=Match.Analytics.summary(model.events,model.analytics)
	var data := _state.duplicate(true)
	var error := Rules.apply(data,content,action,values)
	if not error.is_empty(): return failure(error)
	if action == "commit_match":
		model=Match.new(data.current_attempt.seed,Match.REGULATION_SECONDS,Rules.Lineup.from_data(data.current_attempt.home_plan),content.opponent_plan(data.current_attempt.fixture.variant_id),true)
		model.analytics=Match.Analytics.empty(true)
		model.manager_cards=[data.managers.duplicate(),[]]
		data.match_snapshot=Snapshot.capture(model)
	elif data.step != "match": model=null
	_state=data
	return {"ok":true,"revision":revision()}
