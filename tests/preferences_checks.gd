extends SceneTree
const Preferences = preload("res://persistence/preferences.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var location := "user://campaign_preferences_test_"+str(Time.get_ticks_usec())
	var settings := Preferences.new(location)
	assert(settings.error.is_empty() and settings.data.scale == 1.0)
	var original: Dictionary = settings.data.duplicate(true)
	for invalid in [-0.1,1.1,NAN,INF,"loud"]: assert(not settings.change("volume",invalid).ok and settings.data == original)
	assert(not settings.change("scale",1.25).ok)
	var duplicate: Dictionary = Preferences.DEFAULT_KEYS.duplicate()
	duplicate.pause = KEY_1
	assert(not settings.change("keys",duplicate).ok)
	var keys: Dictionary = Preferences.DEFAULT_KEYS.duplicate()
	keys.pause = KEY_P
	assert(settings.change("keys",keys).ok and settings.change("volume",0.4).ok)
	var legacy: Dictionary = settings.data.duplicate(true)
	legacy.scale = 1.25
	assert(settings.store.write("settings",legacy,Preferences.valid).ok)
	var reopened := Preferences.new(location)
	assert(reopened.data.scale == 1.0 and reopened.data.keys.pause == KEY_P and is_equal_approx(reopened.data.volume,0.4),"Old scale preferences normalize without losing controls or sound")
	assert(reopened.change("motion",true).ok)
	assert(reopened.store.read("settings",Preferences.valid).data.scale == 1.0)
	for file in DirAccess.get_files_at(settings.store.directory): assert(DirAccess.remove_absolute(settings.store.directory+"/"+file) == OK)
	assert(DirAccess.remove_absolute(settings.store.directory) == OK)
	print("PREFERENCES: fixed 100%, legacy normalization, independent disk settings and invalid/duplicate input checks passed")
	quit()
