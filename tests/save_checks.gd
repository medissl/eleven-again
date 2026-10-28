extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Controller = preload("res://run/run_controller.gd")
const State = preload("res://run/run_state.gd")
const Store = preload("res://persistence/save_store.gd")
const Lineup = preload("res://squad/lineup.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if "--write-probe" in args or "--resume-probe" in args:
		await relaunch_probe(args)
		return
	var content := Campaign.new()
	var controller := Controller.new(content)
	assert(controller.start("BRA",2026,"disk-contract").ok)
	var root_path := "user://campaign_test_"+str(Time.get_ticks_usec())
	var store := Store.new(root_path)
	var validate := func(value): return State.error(value,content).is_empty()
	var initial := controller.snapshot()
	assert(State.error(initial,content).is_empty(),State.error(initial,content))
	assert(store.read("run",validate).status == "missing")
	assert(store.write("run",initial,validate).ok)
	assert(store.read("run",validate).data == initial)
	var corrupt := initial.duplicate(true)
	corrupt.cash += 1
	assert(not store.write("run",corrupt,validate).ok and store.read("run",validate).data == initial)
	corrupt = initial.duplicate(true)
	corrupt.plan.width = NAN
	assert(not store.write("run",corrupt,validate).ok)
	corrupt = initial.duplicate(true)
	corrupt.unexpected = Resource.new()
	assert(not store.write("run",corrupt,validate).ok,"Executable/object data never reaches serialization")
	assert(controller.acquire(initial.offer.cards[0],"",controller.revision()).ok)
	var next := controller.snapshot()
	assert(State.error(next,content).is_empty(),State.error(next,content))
	assert(store.write("run",next,validate).ok)
	assert(store.read_file(store.path("run")+".bak","run",validate).data == initial)
	var output := FileAccess.open(store.path("run"),FileAccess.WRITE)
	output.store_buffer(PackedByteArray([0,1,2,3,4]))
	output.close()
	var recovery := store.read("run",validate)
	assert(recovery.ok and recovery.source == "backup" and recovery.data == initial)
	assert(store.write("run",recovery.data,validate).ok)
	var files := DirAccess.get_files_at(store.directory)
	assert(Array(files).filter(func(file): return ".preserved." in file).size() == 1)
	assert(controller.commit_match(Lineup.from_data(next.plan),controller.revision()).ok)
	for index in 900: controller.model.step()
	var flight := controller.snapshot()
	assert(State.error(flight,content).is_empty(),State.error(flight,content))
	assert(store.write("run",flight,validate).ok)
	var restored := Controller.new(content)
	assert(restored.restore(store.read("run",validate).data).ok)
	assert(restored.model.signature() == controller.model.signature())
	for index in 600:
		controller.model.step()
		restored.model.step()
	assert(restored.model.signature() == controller.model.signature(),"Disk snapshot preserves the exact future football and RNG")
	var broken := flight.duplicate(true)
	broken.fixtures[0].club_id = "unknown"
	assert(not restored.restore(broken).ok)
	broken = flight.duplicate(true)
	broken.plan.cards[0].keeper_attributes.REF = 120
	assert(not restored.restore(broken).ok)
	# Test files are isolated from the actual campaign folder; remove only those created here.
	for file in DirAccess.get_files_at(store.directory):
		assert(DirAccess.remove_absolute(store.directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(store.directory) == OK)
	print("SAVES: exact native disk round-trip, atomic overwrite/backup, cash/content rejection and preserved-corruption recovery passed")
	quit()

func relaunch_probe(args: PackedStringArray) -> void:
	var root_path := ""
	for arg in args:
		if arg.begins_with("--store-root="): root_path = arg.trim_prefix("--store-root=")
	assert(root_path.begins_with("user://campaign_relaunch_test_") and root_path.trim_prefix("user://").is_valid_identifier())
	var content := Campaign.new()
	var store := Store.new(root_path)
	var validate := func(value): return State.error(value,content).is_empty()
	var controller := Controller.new(content)
	var expected_shape := func(value): return value is Dictionary and value.get("expected") is Array
	if "--write-probe" in args:
		assert(store.read("run",validate).status == "missing","Probe must use a fresh isolated directory")
		assert(controller.start("ENG",717,"process-relaunch").ok)
		assert(controller.skip_recruit(controller.revision()).ok)
		assert(controller.commit_match(Lineup.from_data(controller.snapshot().plan),controller.revision()).ok)
		for index in 1100: controller.model.step()
		assert(store.write("run",controller.snapshot(),validate).ok)
		for index in 600: controller.model.step()
		assert(store.write("settings",{"expected":controller.model.signature()},expected_shape).ok)
		print("RELAUNCH WRITE: committed exact native disk snapshot and expected future signature")
	else:
		var loaded := store.read("run",validate)
		assert(loaded.ok and controller.restore(loaded.data).ok)
		for index in 600: controller.model.step()
		assert(controller.model.signature() == store.read("settings",expected_shape).data.expected)
		for file in DirAccess.get_files_at(store.directory): assert(DirAccess.remove_absolute(store.directory+"/"+file) == OK)
		assert(DirAccess.remove_absolute(store.directory) == OK)
		print("RELAUNCH RESUME: fresh executable reproduced the exact future match/RNG signature")
	quit()
