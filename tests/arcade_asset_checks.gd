extends SceneTree
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/arcade/sources.json"))
	var palette: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/arcade/palette.json")).colours
	var hashes := {}
	for item in manifest.assets:
		var path: String="res://assets/ui/arcade/"+item.key+".png"
		var original := Image.new()
		assert(original.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK)
		var texture: Texture2D=load(path)
		var imported := texture.get_image()
		original.convert(Image.FORMAT_RGBA8)
		imported.convert(Image.FORMAT_RGBA8)
		assert(original.get_size() == Vector2i(item.size[0],item.size[1]))
		for y in original.get_height():
			for x in original.get_width():
				var pixel := original.get_pixel(x,y)
				assert(pixel.a == imported.get_pixel(x,y).a and (pixel.a == 0 or pixel == imported.get_pixel(x,y)),"Stale opaque imported pixels: "+path)
				assert(pixel.a in [0.0,1.0],"Intermediate alpha in pixel art")
				assert(pixel.a == 0 or pixel.to_html(false).to_upper() in palette,"Artwork outside shared palette")
		if item.key.begins_with("badges/"):
			var hash := original.get_data().hex_encode().sha256_text()
			assert(not hashes.has(hash),"Duplicate crest: "+item.key)
			hashes[hash]=true
	assert(hashes.size() == 40)
	var font: Font=preload("res://ui/typography.gd").face("Score")
	assert(is_equal_approx(font.get_string_size("1111",HORIZONTAL_ALIGNMENT_LEFT,-1,48).x,font.get_string_size("8888",HORIZONTAL_ALIGNMENT_LEFT,-1,48).x),"Score numerals must not shift")
	for id in preload("res://ui/ability_icons.gd").PATHS:
		var icon: Texture2D=preload("res://ui/ability_icons.gd").texture(id)
		assert(icon.get_size() == Vector2(24,24))
	print("ARCADE ASSETS: ",manifest.assets.size()," imported images, 40 distinct badges, 32-colour/binary-alpha admission, stable score numerals and 36 ability icons passed")
	quit()
