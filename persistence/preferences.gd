extends RefCounted
const Store = preload("res://persistence/save_store.gd")
const DEFAULT_KEYS := {"pause":KEY_SPACE,"speed1":KEY_1,"speed2":KEY_2,"menu":KEY_ESCAPE}
var store: RefCounted
var data := {"schema":1,"scale":1.0,"motion":false,"effects":true,"volume":1.0,"fullscreen":false,"keys":{"pause":KEY_SPACE,"speed1":KEY_1,"speed2":KEY_2,"menu":KEY_ESCAPE}}
var error := ""

func _init(root: String = "user://campaign") -> void:
	store = Store.new(root)
	var loaded: Dictionary = store.read("settings",valid)
	if loaded.ok:
		data = loaded.data
		# Retain older settings/remaps, but the interface now always uses 100%.
		data.scale = 1.0
	elif loaded.status != "missing": error = "Settings could not be read. Original files are retained."

static func valid(value: Variant) -> bool:
	if value is not Dictionary or value.get("schema") != 1 or value.get("scale") not in [1.0,1.15,1.25] or value.get("volume") is not float or not is_finite(value.volume) or value.volume < 0 or value.volume > 1 or value.get("keys") is not Dictionary: return false
	for key in ["motion","effects","fullscreen"]:
		if value.get(key) is not bool: return false
	var used := []
	for action in ["pause","speed1","speed2","menu"]:
		var code = value.keys.get(action)
		if code is not int or code <= 0 or code in used or code in [KEY_TAB,KEY_ENTER,KEY_KP_ENTER] or (code == KEY_ESCAPE and action != "menu"): return false
		used.append(code)
	return true

func change(key: String, value: Variant) -> Dictionary:
	if key == "scale" and value != 1.0: return {"ok":false,"error":"The interface uses its standard size."}
	var proposed := data.duplicate(true)
	proposed[key] = value
	if not valid(proposed): return {"ok":false,"error":"Choose distinct keys; Tab and Enter remain navigation controls."}
	var result: Dictionary = store.write("settings",proposed,valid)
	if result.ok:
		data = proposed
		error = ""
	return result
