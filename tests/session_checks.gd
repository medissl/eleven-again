extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Session = preload("res://persistence/campaign_session.gd")
const Store = preload("res://persistence/save_store.gd")
const Profile = preload("res://persistence/profile.gd")
const Records = preload("res://run/records.gd")
const Lineup = preload("res://squad/lineup.gd")
var content: RefCounted

class InterruptStore:
	extends Store
	var writes := 0
	var stop_at := -1
	func _init(folder: String) -> void: super(folder)
	func write(kind: String, data: Variant, validate: Callable) -> Dictionary:
		writes += 1
		if writes == stop_at: return {"ok":false,"error":"Authored interruption"}
		return super.write(kind,data,validate)

func _initialize() -> void: call_deferred("run")

func cleanup(store: RefCounted) -> void:
	assert(store.directory.get_file().begins_with("campaign_session_test_"))
	for file in DirAccess.get_files_at(store.directory): assert(DirAccess.remove_absolute(store.directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(store.directory) == OK)

func run() -> void:
	content = Campaign.new()
	assert(content.errors.is_empty())
	var args := OS.get_cmdline_user_args()
	if "--write-probe" in args or "--resume-probe" in args:
		probe(args)
		return
	for cut in range(1,5):
		var location := "user://campaign_session_test_"+str(Time.get_ticks_usec())
		var backend := InterruptStore.new(location)
		var session := Session.new(location,content,backend)
		assert(not session.blocked and session.new_run("ENG",40,"interruption-"+str(cut)).ok)
		var before: Dictionary = session.controller.snapshot()
		var incoming: String = before.offer.cards[0]
		backend.writes = 0
		backend.stop_at = cut
		assert(not session.act("acquire",[incoming,""],session.controller.revision()).ok and session.blocked)
		assert(session.controller.snapshot() == before,"Failed durable commit never publishes a candidate")
		assert(not session.checkpoint().ok,"Pending recovery blocks further mutations")
		var reopened := Session.new(location,content)
		assert(not reopened.blocked,reopened.last_error)
		assert(reopened.controller.snapshot().plan.cards.size() == (16 if cut == 1 else 17))
		assert(reopened.profile.discoveries.size() == (0 if cut == 1 else 1))
		if cut > 1:
			assert(reopened.profile.discoveries[incoming].run_ids.size() == 1)
			var profile_before: Dictionary = reopened.profile.duplicate(true)
			assert(reopened.reload().ok and reopened.profile == profile_before,"Journal replay is idempotent")
		cleanup(backend)
	main_flow()
	record_checks()
	print("SESSION: all four write interruptions, idempotent recovery/discovery, replacement, terminal cleanup and saved-XI records passed")
	quit()

func main_flow() -> void:
	var location := "user://campaign_session_test_"+str(Time.get_ticks_usec())
	var session := Session.new(location,content)
	assert(session.new_run("JPN",51,"profile-first").ok)
	var initial: Dictionary = session.controller.snapshot()
	assert(session.profile.discoveries.is_empty(),"Opening candidates do not discover editions")
	var preview: Dictionary = session.preview()
	assert(preview.step == "opening_recruit" and preview.best_cards == session.controller.best_owned())
	var stale := Session.new(location,content)
	assert(not session.new_run("BRA",77,"unconfirmed").ok and session.controller.snapshot() == initial)
	assert(not session.new_run("INVALID",77,"bad-origin",true).ok and session.controller.snapshot() == initial)
	assert(session.act("acquire",[initial.offer.cards[0],""],session.controller.revision()).ok)
	assert(session.profile.discoveries.size() == 1)
	var first_date: String = session.profile.discoveries[initial.offer.cards[0]].first_discovered
	assert(session.checkpoint().ok and session.profile.discoveries[initial.offer.cards[0]].first_discovered == first_date)
	assert(stale.preview().is_empty() and not stale.checkpoint().ok,"A stale writer cannot replace newer profile data or preview an inconsistent head")
	for index in 3:
		assert(session.act("commit_match",[Lineup.from_data(session.controller.snapshot().plan)],session.controller.revision()).ok)
		var model: RefCounted = session.controller.model
		for tick in 15: model.step()
		assert(session.checkpoint().ok and session.controller.model == model,"Autosave keeps the live match instance stable")
		model.scores = [0,1]
		model.finish_match()
		assert(session.act("finish_match",[],session.controller.revision()).ok)
		if index < 2: assert(session.act("continue_result",[],session.controller.revision()).ok)
	assert(session.preview().is_empty() and session.profile.runs["profile-first"].outcome == "lost")
	assert(Profile.ranked(session.profile).size() == 1)
	assert(session.reload().ok and session.profile.runs.size() == 1)
	assert(session.new_run("BRA",77,"profile-second").ok)
	assert(session.controller.snapshot().cash == 8000000 and session.controller.snapshot().plan.cards.size() == 16 and session.profile.discoveries.size() == 1)
	assert(session.new_run("ARG",8,"profile-third",true).ok)
	assert(session.profile.runs["profile-second"].outcome == "abandoned")
	assert(not session.new_run("ENG",1,"profile-first",true).ok,"Run identity reuse cannot merge discovery counters")
	# A damaged profile is repaired from the durable latest journal, never reset to empty.
	var output := FileAccess.open(session.store.path("profile"),FileAccess.WRITE)
	output.store_buffer(PackedByteArray([1,2,3]))
	output.close()
	assert(session.reload().ok and session.recovery_used and session.profile.discoveries.size() == 1)
	for kind in ["profile","journal"]:
		for suffix in ["", ".bak"]:
			output = FileAccess.open(session.store.path(kind)+suffix,FileAccess.WRITE)
			output.store_buffer(PackedByteArray([7,8,9]))
			output.close()
	assert(not session.reload().ok and session.blocked,"Unrecoverable profile/journal files are never silently replaced with an empty profile")
	assert(FileAccess.get_file_as_bytes(session.store.path("profile")) == PackedByteArray([7,8,9]))
	cleanup(session.store)

func record_checks() -> void:
	var plan: Resource = content.country_plan("ENG")
	var record := Records.capture(plan)
	assert(Records.valid(record,content,content.cards.keys()))
	var old_total: int = record.total
	for field in plan.cards.back().attributes: plan.cards.back().attributes[field] = 120
	assert(Records.capture(plan).total == old_total,"Bench strength is excluded")
	plan.cards[plan.starters[1]].card_id = "academy_test"
	assert(Records.capture(plan).is_empty())
	var forged := record.duplicate(true)
	forged.ratings[1] += 1
	forged.total += 1
	assert(not Records.valid(forged,content,content.cards.keys()))
	var active := {"run_id":"a","outcome":"lost","wins":10,"defeats":3,"peak_xi":record,"goal_difference":5}
	var champion := active.duplicate(true)
	champion.outcome = "won"
	assert(Records.better(champion,active))

func probe(args: PackedStringArray) -> void:
	var location := ""
	for arg in args:
		if arg.begins_with("--store-root="): location = arg.trim_prefix("--store-root=")
	assert(location.begins_with("user://campaign_session_test_") and location.trim_prefix("user://").is_valid_identifier())
	if "--write-probe" in args:
		var backend := InterruptStore.new(location)
		var session := Session.new(location,content,backend)
		assert(session.new_run("FRA",83,"cold-journal").ok)
		var incoming: String = session.controller.snapshot().offer.cards[0]
		backend.writes = 0
		backend.stop_at = 3
		assert(not session.act("acquire",[incoming,""],session.controller.revision()).ok)
		print("JOURNAL WRITE: stopped after run replacement, before profile commit")
	else:
		var session := Session.new(location,content)
		assert(not session.blocked and session.recovery_used,session.last_error)
		assert(session.controller.snapshot().plan.cards.size() == 17 and session.profile.discoveries.size() == 1)
		var entry: Dictionary = session.profile.discoveries.values()[0]
		assert(entry.run_ids == ["cold-journal"])
		assert(session.reload().ok and session.profile.discoveries.values()[0] == entry)
		cleanup(session.store)
		print("JOURNAL RESUME: fresh executable reconciled acquisition/profile once")
	quit()
