extends RefCounted
static var textures := {}
static func texture(code: String) -> Texture2D:
	if textures.has(code): return textures[code]
	var path := "res://assets/ui/premium/flags/"+code+".svg"
	if not FileAccess.file_exists(path): return null
	textures[code] = preload("res://ui/pixel_art.gd").texture(path,Vector2i(24,16))
	return textures[code]
