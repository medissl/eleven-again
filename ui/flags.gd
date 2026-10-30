extends RefCounted
static var textures := {}
static func texture(code: String) -> Texture2D:
	if textures.has(code): return textures[code]
	var path := "res://assets/ui/premium/flags/"+code+".svg"
	if not FileAccess.file_exists(path): return null
	var pixels := Image.new()
	if pixels.load_svg_from_string(FileAccess.get_file_as_string(path),0.3) != OK: return null
	textures[code] = ImageTexture.create_from_image(pixels)
	return textures[code]
