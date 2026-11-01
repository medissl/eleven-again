extends RefCounted
## Crisp semantic icon admission. Illustration uses generated assets; factual colours stay unchanged.
static var textures := {}
static func texture(path: String, extent: Vector2i = Vector2i(24,24)) -> Texture2D:
	var key := path+str(extent)
	if not textures.has(key):
		var source: Texture2D = load(path)
		assert(source != null,"Missing icon: "+path)
		var image := source.get_image()
		image.convert(Image.FORMAT_RGBA8)
		image.resize(extent.x,extent.y,Image.INTERPOLATE_NEAREST)
		for y in extent.y:
			for x in extent.x:
				var c := image.get_pixel(x,y)
				c.a = 1.0 if c.a >= 0.45 else 0.0
				image.set_pixel(x,y,c)
		textures[key]=ImageTexture.create_from_image(image)
	return textures[key]
