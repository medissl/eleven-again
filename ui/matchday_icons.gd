extends RefCounted
const BASE := "res://assets/ui/matchday/"
static var event_map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"event-map.json")).events
static var textures := {}
static var traits := {}

static func texture(id: String) -> Texture2D:
	if not textures.has(id): textures[id] = load(BASE+id+".svg")
	return textures[id]

static func event(kind: String) -> Texture2D:
	if kind in ["yellow_card","red_card"]: return texture("components/"+kind.replace("_","-")+"-solid")
	return texture(event_map.get(kind,"icons/info"))

static func signature_icon(id: String) -> Texture2D:
	if traits.is_empty():
		for entry in JSON.parse_string(FileAccess.get_file_as_string(BASE+"trait-map.json")).traits: traits[entry.id] = entry.icon
	return texture(traits.get(id,"icons/star"))
