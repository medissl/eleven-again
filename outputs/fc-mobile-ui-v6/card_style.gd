extends RefCounted
## One frame/palette for every native card. Person/portrait/ratings stay in existing data.
const PALETTES := {
	"bronze":["C38E68","F4C49B","483028"],
	"silver":["90ADBE","EDF8FF","304D62"],
	"gold":["D9B971","FFF0B8","695329"],
	"legend":["B68AE9","F1DBFF","573477"],
	"unknown":["435967","80939D","202E3B"]
}
static var textures := {}

static func gradient(key: String, colors: PackedColorArray, offsets: PackedFloat32Array) -> Texture2D:
	if not textures.has(key):
		var ramp := Gradient.new()
		ramp.colors = colors
		ramp.offsets = offsets
		var texture := GradientTexture2D.new()
		texture.width = 512
		texture.height = 512
		texture.fill_from = Vector2(0.1,0)
		texture.fill_to = Vector2(0.9,1)
		texture.gradient = ramp
		textures[key] = texture
	return textures[key]

static func foil(tier: String) -> Texture2D:
	var swatch: Array = PALETTES[tier]
	var main := Color(swatch[0])
	var light := Color(swatch[1])
	var dark := Color(swatch[2])
	return gradient(tier,PackedColorArray([dark,main,light,main,dark,main,light,main]),PackedFloat32Array([0,0.14,0.27,0.39,0.56,0.70,0.86,1]))

static func textured(card: Control, points: PackedVector2Array, texture: Texture2D) -> void:
	var uv := PackedVector2Array()
	for point in points: uv.append(point/Vector2(300,420))
	card.draw_colored_polygon(points,Color.WHITE,uv,texture)

static func paint(card: Control) -> void:
	if not is_instance_valid(card.content): return
	var tier: String = card.definition.tier() if card.definition != null else "unknown"
	var accent := Color(PALETTES[tier][0])
	var light := Color(PALETTES[tier][1])
	card.draw_set_transform(card.content.position,0,card.content.scale)
	var frame := PackedVector2Array([Vector2(16,0),Vector2(284,0),Vector2(300,16),Vector2(300,132),Vector2(294,156),Vector2(300,182),Vector2(300,400),Vector2(280,420),Vector2(20,420),Vector2(0,400),Vector2(0,182),Vector2(6,156),Vector2(0,132),Vector2(0,16)])
	var outline := frame.duplicate()
	outline.append(frame[0])
	if card.button_pressed or card.has_focus():
		card.draw_polyline(outline,Color(0.29,0.87,1,0.12),12,true)
		card.draw_polyline(outline,Color(0.29,0.87,1,0.35),5,true)
	textured(card,frame,foil(tier))
	var inset := PackedVector2Array()
	for point in frame: inset.append((point-Vector2(150,210))*Vector2(0.963,0.974)+Vector2(150,210))
	var face := gradient("night",PackedColorArray([Color("193044"),Color("0C1929"),Color("07101C")]),PackedFloat32Array([0,0.42,1]))
	textured(card,inset,face)
	card.draw_polyline(outline,Color(light,0.85),0.8,true)
	card.draw_colored_polygon(PackedVector2Array([Vector2(98,20),Vector2(280,20),Vector2(287,27),Vector2(287,222),Vector2(220,222)]),Color(accent,0.055))
	card.draw_line(Vector2(100,24),Vector2(274,24),Color(light,0.22),1,true)
	card.draw_line(Vector2(274,24),Vector2(285,35),Color(light,0.4),1.4,true)
	card.draw_colored_polygon(PackedVector2Array([Vector2(16,16),Vector2(86,16),Vector2(92,22),Vector2(92,150),Vector2(16,150)]),Color(0.01,0.035,0.065,0.4))
	if card.portrait.texture == null:
		card.draw_circle(Vector2(156,127),33,Color(accent,0.13))
		card.draw_arc(Vector2(156,215),61,PI,TAU,32,Color(accent,0.13),42,true)
	textured(card,PackedVector2Array([Vector2(18,231),Vector2(282,231),Vector2(275,253),Vector2(25,253)]),foil(tier))
	var marks: int = {"bronze":1,"silver":2,"gold":3,"legend":4,"unknown":0}[tier]
	for index in marks:
		var x := 244+index*7
		card.draw_line(Vector2(x,247),Vector2(x+4,237),Color("132331"),1.2,true)
	card.draw_line(Vector2(24,306),Vector2(276,306),Color(accent,0.5),0.8,true)
	card.draw_line(Vector2(150,315),Vector2(150,407),Color(accent,0.16),0.8,true)
	if card.is_hovered() and not card.disabled: card.draw_polyline(outline,light,2,true)
	if card.button_pressed or card.has_focus(): card.draw_polyline(outline,Color("84EBFF"),2.5,true)
	card.draw_set_transform(Vector2.ZERO)
