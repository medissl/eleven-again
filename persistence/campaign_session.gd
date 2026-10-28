extends RefCounted
## One local writer: prepare on a copy, journal both files, then publish the controller.
const Campaign = preload("res://content/campaign.gd")
const Controller = preload("res://run/run_controller.gd")
const State = preload("res://run/run_state.gd")
const Profile = preload("res://persistence/profile.gd")
const Store = preload("res://persistence/save_store.gd")
const ACTIONS := ["acquire","skip_recruit","continue_result","close_market","reopen_market","choose_principle","commit_match","finish_match","abandon"]
var content: RefCounted
var store: RefCounted
var controller: RefCounted
var profile: Dictionary = Profile.empty()
var blocked := false
var recovery_used := false
var last_error := ""

func _init(root: String = "user://campaign", library: RefCounted = null, backend: RefCounted = null) -> void:
	content = library if library != null else Campaign.new()
	store = backend if backend != null else Store.new(root)
	controller = Controller.new(content)
	reload()

func run_valid(value: Variant) -> bool:
	return State.error(value,content).is_empty() and value.get("disk_generation") is int and value.disk_generation > 0 and value.get("transaction_id") is String

func profile_valid(value: Variant) -> bool:
	return Profile.error(value,content).is_empty()

func journal_valid(value: Variant) -> bool:
	return value is Dictionary and value.get("schema") == 1 and value.get("pending") is bool and value.get("generation") is int and value.generation > 0 and value.get("transaction_id") is String and run_valid(value.get("run")) and profile_valid(value.get("profile")) and value.run.disk_generation == value.generation and value.profile.generation == value.generation and value.run.transaction_id == value.transaction_id and value.profile.transaction_id == value.transaction_id

func fail(message: String, stop: bool = false) -> Dictionary:
	last_error = message
	if stop: blocked = true
	return {"ok":false,"error":message}

func reload() -> Dictionary:
	blocked = true
	recovery_used = false
	if not content.errors.is_empty(): return fail("Campaign content could not be validated.",true)
	var run_file: Dictionary = store.read("run",run_valid)
	var profile_file: Dictionary = store.read("profile",profile_valid)
	var journal: Dictionary = store.read("journal",journal_valid)
	if journal.ok:
		var proposal: Dictionary = journal.data
		var run_generation: int = run_file.data.disk_generation if run_file.ok else 0
		var profile_generation: int = profile_file.data.generation if profile_file.ok else 0
		if run_generation > proposal.generation or profile_generation > proposal.generation:
			# A stale backup journal cannot roll either newer committed file backwards.
			if not run_file.ok or not profile_file.ok or run_generation != profile_generation or run_file.data.transaction_id != profile_file.data.transaction_id: return fail("Newer save files conflict with the available journal. Recovery is required.",true)
		else:
			for entry in [["run",run_file,proposal.run,run_valid],["profile",profile_file,proposal.profile,profile_valid]]:
				var loaded: Dictionary = entry[1]
				var generation: int = run_generation if entry[0] == "run" else profile_generation
				if loaded.ok and generation == proposal.generation and loaded.data != entry[2]: return fail("Save transaction contents conflict. Original files have been retained.",true)
				if not loaded.ok or loaded.data != entry[2]:
					var repaired: Dictionary = store.write(entry[0],entry[2],entry[3])
					if not repaired.ok: return fail(repaired.error,true)
					recovery_used = true
			if proposal.pending or journal.source == "backup":
				proposal = proposal.duplicate(true)
				proposal.pending = false
				var closed: Dictionary = store.write("journal",proposal,journal_valid)
				if not closed.ok: return fail(closed.error,true)
				recovery_used = true
			run_file = {"ok":true,"data":proposal.run}
			profile_file = {"ok":true,"data":proposal.profile}
	elif journal.status != "missing": return fail("The transaction journal needs recovery. Original files have been retained.",true)
	if not run_file.ok and run_file.status != "missing": return fail("The active run needs recovery.",true)
	if not profile_file.ok and profile_file.status != "missing": return fail("The profile needs recovery.",true)
	if run_file.ok and (not profile_file.ok or run_file.data.disk_generation != profile_file.data.generation or run_file.data.transaction_id != profile_file.data.transaction_id): return fail("Run/profile transaction generations do not match.",true)
	if not run_file.ok and profile_file.ok and profile_file.data.generation != 0: return fail("The run checkpoint is missing; refusing to replace existing progress.",true)
	var loaded_controller := Controller.new(content)
	if run_file.ok:
		var restored: Dictionary = loaded_controller.restore(run_file.data)
		if not restored.ok: return fail(restored.error,true)
	controller = loaded_controller
	profile = profile_file.data.duplicate(true) if profile_file.ok else Profile.empty()
	blocked = false
	last_error = ""
	return {"ok":true,"recovered":recovery_used}

func persist(candidate: RefCounted) -> Dictionary:
	if blocked: return fail("Reload and recover the pending save before continuing.")
	var disk_profile: Dictionary = store.read("profile",profile_valid)
	if (disk_profile.ok and disk_profile.data != profile) or (not disk_profile.ok and (disk_profile.status != "missing" or profile.generation != 0)): return fail("The disk profile changed or needs recovery. Reload before saving.",true)
	var data: Dictionary = candidate.snapshot()
	var error := State.error(data,content)
	if not error.is_empty(): return fail(error)
	var generation: int = profile.generation+1
	var transaction_id: String = data.run_id+"/tx/"+str(generation)
	data.disk_generation = generation
	data.transaction_id = transaction_id
	var updated := Profile.project(profile,data,generation,transaction_id,Time.get_datetime_string_from_system(true)+"Z")
	if not profile_valid(updated): return fail("The resulting profile is invalid.")
	var journal := {"schema":1,"pending":true,"generation":generation,"transaction_id":transaction_id,"run":data,"profile":updated}
	for entry in [["journal",journal,journal_valid],["run",data,run_valid],["profile",updated,profile_valid]]:
		var written: Dictionary = store.write(entry[0],entry[1],entry[2])
		if not written.ok: return fail(written.error+" Reload to reconcile any durable pending transaction.",true)
	journal.pending = false
	var closed: Dictionary = store.write("journal",journal,journal_valid)
	if not closed.ok: return fail(closed.error+" Reload to reconcile the committed transaction.",true)
	# Preserve the live match object's identity during ordinary autosave.
	candidate._state.disk_generation = generation
	candidate._state.transaction_id = transaction_id
	controller = candidate
	profile = updated
	last_error = ""
	return {"ok":true,"revision":controller.revision(),"transaction_id":transaction_id}

func act(action: String, arguments: Array, expected: int) -> Dictionary:
	if blocked: return fail("Reload and recover the pending save before continuing.")
	if action not in ACTIONS: return fail("Unknown campaign action.")
	var count: int = {"acquire":2,"choose_principle":1,"commit_match":1}.get(action,0)
	if arguments.size() != count: return fail("Invalid campaign action arguments.")
	var candidate := Controller.new(content)
	var restored: Dictionary = candidate.restore(controller.snapshot())
	if not restored.ok: return fail(restored.error)
	var args := arguments.duplicate()
	args.append(expected)
	var result: Dictionary = candidate.callv(action,args)
	if not result.ok: return result
	return persist(candidate)

func new_run(origin: String, seed_value: int, run_id: String, replace_confirmed: bool = false) -> Dictionary:
	if blocked: return fail("Recover existing save files before starting a run.")
	if profile.runs.has(run_id) or run_id.is_empty(): return fail("Choose a new unique run identity.")
	var candidate := Controller.new(content)
	var created: Dictionary = candidate.start(origin,seed_value,run_id)
	if not created.ok: return created
	var current: Dictionary = controller.snapshot()
	if not current.is_empty() and current.step not in ["won","lost","abandoned"]:
		if not replace_confirmed: return fail("Confirm replacement of the active run first.")
		var abandoned := act("abandon",[],controller.revision())
		if not abandoned.ok: return abandoned
	return persist(candidate)

func checkpoint() -> Dictionary:
	return persist(controller)

func preview() -> Dictionary:
	if blocked: return {}
	# Deliberately read the valid disk head, never an unsaved in-memory candidate.
	var saved: Dictionary = store.read("run",run_valid)
	if not saved.ok or saved.data.step in ["won","lost","abandoned"]: return {}
	var data: Dictionary = saved.data
	var owned: Array = data.plan.cards.map(func(card): return content.cards[card.card_id])
	owned.sort_custom(func(a,b): return a.rating() > b.rating() if a.rating() != b.rating() else a.card_id < b.card_id)
	var chapter := mini(3,int(data.wins/4.0)+1)
	return {"run_id":data.run_id,"origin":data.origin,"wins":data.wins,"defeats":data.defeats,"cash":data.cash,"step":data.step,"best_cards":owned.slice(0,2).map(func(card): return card.card_id),"chapter":chapter,"fixtures":data.fixtures.slice((chapter-1)*4,chapter*4),"ledger":data.ledger.duplicate(true),"next_opponent":data.fixtures[data.wins].club_id,"transaction_id":data.transaction_id}
