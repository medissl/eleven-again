extends SceneTree
const Campaign = preload("res://content/campaign.gd")
const Controller = preload("res://run/run_controller.gd")
const Session = preload("res://persistence/campaign_session.gd")
const Profile = preload("res://persistence/profile.gd")
func _initialize() -> void:
	var content := Campaign.new()
	assert(content.errors.is_empty(),str(content.errors))
	assert(content.clubs.size() == 40 and content.variants.size() == 100)
	# Captured from the actual pre-change implementation at Git 2ebe064, not regenerated from v2.
	assert(JSON.stringify(content.itinerary(42,Campaign.LEGACY_VERSION)).sha256_text() == "89fa63a530892188b17b68e9357e34e1976865259b33423c4e851ff5553db5b1","Frozen legacy itinerary changed")
	for seed_value in 100:
		var old: Array = content.itinerary(seed_value,Campaign.LEGACY_VERSION)
		var road: Array = content.itinerary(seed_value)
		assert(old.size() == 12 and road.size() == 12)
		for index in 12:
			var club: Dictionary = content.clubs[road[index].club_id]
			if index < 4: assert(road[index] == old[index])
			else:
				assert(club.legacy_source == old[index].club_id)
				assert(club.opposition_kind == ("club" if index < 8 else "nation"))
				assert(content.opponent_plan(old[index].variant_id).to_data() == content.opponent_plan(road[index].variant_id).to_data(),"Existing strength, card definitions and tactics are frozen")
	var controller := Controller.new(content)
	assert(controller.start("ARG",42,"legacy-disk-proof").ok)
	var legacy: Dictionary = controller.snapshot()
	legacy.content_version = Campaign.LEGACY_VERSION
	legacy.fixtures = content.itinerary(42,Campaign.LEGACY_VERSION)
	assert(controller.restore(legacy).ok)
	var root := "user://road_legacy_"+str(Time.get_ticks_usec())
	var session := Session.new(root,content)
	assert(session.persist(controller).ok)
	var reloaded := Session.new(root,content)
	assert(not reloaded.blocked and reloaded.controller.snapshot().fixtures == legacy.fixtures and reloaded.controller.snapshot().content_version == Campaign.LEGACY_VERSION)
	assert(Profile.error(reloaded.profile,content).is_empty())
	assert(reloaded.act("skip_recruit",[],reloaded.controller.revision()).ok)
	assert(reloaded.controller.snapshot().fixtures == legacy.fixtures,"Advancing a legacy run never remaps its opponents")
	assert(reloaded.new_run("ENG",7,"new-road-run",true).ok)
	var current := Session.new(root,content)
	assert(not current.blocked and current.controller.snapshot().content_version == Campaign.VERSION)
	assert(current.profile.runs.has("legacy-disk-proof") and current.profile.runs.has("new-road-run"),"Old and new run records coexist without resetting the profile")
	print("ROAD: 100 deterministic local/club/national itineraries; unchanged opponent strength; actual legacy/new disk continuation and mixed profile passed")
	quit()
