extends Control
var turf: Texture2D
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
func _ready() -> void:
	var renderer = load("res://match/match_view.gd").new()
	renderer._make_turf()
	turf = renderer.turf
	renderer.free()
func project(point: Vector2) -> Vector2:
	var depth := point.y/105.0
	return Vector2(size.x/2+(point.x/68.0-0.5)*lerpf(size.x*0.79,size.x*0.99,depth),depth*size.y)
func marking(points: Array) -> void:
	var path := PackedVector2Array()
	for point in points: path.append(project(point))
	draw_polyline(path,Color(0.77,0.86,0.87,0.7),1.2,true)
func _draw() -> void:
	var edge := PackedVector2Array([project(Vector2(0,0)),project(Vector2(68,0)),project(Vector2(68,105)),project(Vector2(0,105))])
	draw_colored_polygon(edge,Color("769C93"),PackedVector2Array([Vector2.ZERO,Vector2(3,0),Vector2(3,3),Vector2(0,3)]),turf)
	marking([Vector2(0,0),Vector2(68,0),Vector2(68,105),Vector2(0,105),Vector2(0,0)])
	marking([Vector2(0,52.5),Vector2(68,52.5)])
	var circle: Array = []
	for index in 65:
		var angle := index*TAU/64
		circle.append(Vector2(34+cos(angle)*9.15,52.5+sin(angle)*9.15))
	marking(circle)
	for end in 2:
		var line := 0.0 if end == 0 else 105.0
		var direction := 1.0 if end == 0 else -1.0
		for area in [Vector2(40.32,16.5),Vector2(18.32,5.5)]:
			var left: float = 34-area.x/2
			var right: float = 34+area.x/2
			marking([Vector2(left,line),Vector2(left,line+direction*area.y),Vector2(right,line+direction*area.y),Vector2(right,line)])
		var spot := Vector2(34,line+direction*11)
		draw_circle(project(spot),1.5,Color(0.8,0.9,0.9,0.8))
		var arc: Array = []
		for index in 25:
			var angle := lerpf(0.65,PI-0.65,index/24.0)
			arc.append(spot+Vector2(cos(angle)*9.15,sin(angle)*9.15*direction))
		marking(arc)
