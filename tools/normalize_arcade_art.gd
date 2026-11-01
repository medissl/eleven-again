extends SceneTree
## Deterministic asset admission. Never touches catalogue portraits or factual flag colours.
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/arcade/sources.json"))
	var colours: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/arcade/palette.json")).colours
	var palette: Array[Color] = []
	for hex in colours: palette.append(Color(hex))
	for asset in manifest.assets:
		var image := Image.load_from_file(asset.source)
		assert(image != null and not image.is_empty())
		image.convert(Image.FORMAT_RGBA8)
		if asset.has("cell"):
			var cell_size := Vector2i(image.get_width()/5,image.get_height()/4)
			image = image.get_region(Rect2i(Vector2i(int(asset.cell)%5,int(asset.cell)/5)*cell_size,cell_size))
		if asset.has("cell") or asset.key in ["logo","pawn","lock","trophy","button","button_primary","goal","goal_flipped","node"]:
			var used := image.get_used_rect()
			image = image.get_region(used)
		image.resize(asset.size[0],asset.size[1],Image.INTERPOLATE_NEAREST)
		var cache := {}
		for y in image.get_height():
			for x in image.get_width():
				var colour := image.get_pixel(x,y)
				if colour.a < 0.5:
					image.set_pixel(x,y,Color.TRANSPARENT)
					continue
				var key := colour.to_rgba32()
				if not cache.has(key):
					var nearest := palette[0]
					var distance := INF
					for candidate in palette:
						var delta := Vector3(colour.r-candidate.r,colour.g-candidate.g,colour.b-candidate.b).length_squared()
						if delta < distance: distance=delta; nearest=candidate
					cache[key]=nearest
				image.set_pixel(x,y,cache[key])
		if asset.key in ["goal","goal_flipped"]: retain_largest_component(image)
		if asset.get("flip",false): image.flip_x()
		assert(image.save_png("res://assets/ui/arcade/"+asset.key+".png") == OK)
		print("NORMALIZED ",asset.key," ",image.get_size())
	quit()

func retain_largest_component(image: Image) -> void:
	var seen := {}
	var largest: Array[Vector2i] = []
	for y in image.get_height():
		for x in image.get_width():
			var point := Vector2i(x,y)
			if seen.has(point) or image.get_pixelv(point).a == 0: continue
			var component: Array[Vector2i] = [point]
			seen[point]=true
			var cursor := 0
			while cursor < component.size():
				var current := component[cursor]
				cursor+=1
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next: Vector2i=current+offset
					if Rect2i(Vector2i.ZERO,image.get_size()).has_point(next) and not seen.has(next) and image.get_pixelv(next).a > 0:
						seen[next]=true
						component.append(next)
			if component.size() > largest.size(): largest=component
	for point in seen:
		if point not in largest: image.set_pixelv(point,Color.TRANSPARENT)
