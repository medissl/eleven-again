extends RefCounted
## Shared generated nine-slice sprites. Small assets keep fixed bevels on every screen.
static var styles := {}
static func surface(kind: String) -> StyleBoxTexture:
	if not styles.has(kind):
		var style := StyleBoxTexture.new()
		style.texture=load("res://assets/ui/arcade/"+kind+".png")
		for side in 4: style.set_texture_margin(side,8 if kind == "panel" else 4)
		style.set_content_margin(SIDE_LEFT,16)
		style.set_content_margin(SIDE_RIGHT,16)
		if kind == "panel": style.draw_center=false
		styles[kind]=style
	return styles[kind]
