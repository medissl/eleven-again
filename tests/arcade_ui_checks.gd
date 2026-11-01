extends "res://tests/campaign_ui_checks.gd"
var scenes := 0
func picture(app: Control, label: String) -> void:
	await create_timer(0.90 if label in ["opening","recruitment-replacement","market","market-signing"] else 0.24).timeout
	assert(app.arena.material != null,"The persistent stadium has a dedicated background-only blur")
	inspect_fonts(app)
	if label == "origin":
		for node in app.screen.find_children("*","Control",true,false):
			if node.has_method("layout_card"): assert(node.portrait.texture != null,"Origin preview must have real campaign portrait metadata")
	await RenderingServer.frame_post_draw
	var folder := "res://reports/arcade-ui"
	DirAccess.make_dir_recursive_absolute(folder)
	var destination := folder+"/%s-%d.png" % [label,app.size.y]
	assert(app.get_viewport().get_texture().get_image().save_png(destination) == OK)
	scenes += 1
	print("ARCADE CAPTURE ",destination)

func inspect_fonts(node: Node) -> void:
	if node is Label and node.is_visible_in_tree():
		var face: Font=node.get_theme_font("font")
		assert("Pixel Operator" in face.get_font_name(),"Mixed family on "+str(node.get_path())+": "+face.get_font_name())
	for child in node.get_children(): inspect_fonts(child)
