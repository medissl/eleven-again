extends Control
## Match-tick driven broadcast cue: refresh never restarts its animation.
static var MatchTheme: Theme = preload("res://ui/matchday_theme.gd").build()
const Icons = preload("res://ui/match_overlay.gd")
var title: Label
var detail: Label
var team_line: Label
var event_id := ""
var activation_count := 0
var age := 150
var team := 0
var reduced := false
var effects := true
var entry := 1.0
var opacity := 0.0
var jersey: Control
var particles: Array[Dictionary] = []
var team_names: Array = ["Meadow XI","Harbor XI"]
var team_kits: Array = [Color("efe9d9"),Color("ed7864")]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	clip_contents = true
	for role in ["Goal", "Heading", "Section"]:
		var label := Label.new()
		label.theme_type_variation = role
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", MatchTheme.get_color("ivory", "Palette"))
		label.add_theme_color_override("font_shadow_color", Color(0.015,0.045,0.025,0.9))
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 4)
		add_child(label)
	title = get_child(0)
	detail = get_child(1)
	team_line = get_child(2)
	title.text = "GOAL!"
	jersey = Icons.Icon.new()
	jersey.kind = "kit"
	jersey.mouse_filter = MOUSE_FILTER_IGNORE
	jersey.size = Vector2(34,34)
	add_child(jersey)
	resized.connect(_layout)
	hide()

func sync(sim: RefCounted, event: Dictionary, reduce: bool, show_effects: bool, blocked: bool) -> void:
	reduced = reduce
	effects = show_effects
	if event.is_empty():
		event_id = ""
		age = 150
		particles.clear()
	else:
		var identity := "%d:%d:%d" % [sim.get_instance_id(),event.tick,event.actor]
		if event_id != identity:
			event_id = identity
			activation_count += 1
			_make_particles(sim.match_seed ^ event.tick ^ event.actor,event.team)
		team = event.team
		age = sim.ticks - event.tick
		detail.text = event.get("actor_name",sim.players[event.actor].name).to_upper()+(" (OG)" if event.get("own_goal",false) else "")
		team_line.text = "%s  ·  %d′" % [team_names[team].to_upper(),event.minute]
	var active: bool = age >= 0 and age < 150 and not blocked and sim.period != 1 and not sim.finished
	visible = active
	for label in [title,detail,team_line]: label.visible = active
	jersey.visible = active
	jersey.ink = team_kits[team]
	if not active: return
	entry = 1.0 if reduced else 1.0 - pow(1.0 - clampf(age / 16.0,0,1),3)
	opacity = minf(clampf(age / 5.0,0,1),clampf((150-age)/18.0,0,1))
	modulate.a = opacity
	_layout()
	queue_redraw()

func _layout() -> void:
	if not title or size.x <= 0: return
	var pixels := roundi(minf(size.y * 0.47,size.x * 0.32))
	title.add_theme_font_size_override("font_size",pixels)
	title.position = Vector2(-18 * (1-entry),size.y * 0.21)
	title.size = Vector2(size.x,size.y * 0.48)
	title.pivot_offset = title.size / 2
	title.scale = Vector2.ONE * (0.94 + entry * 0.06)
	detail.add_theme_font_size_override("font_size",42)
	detail.position = Vector2(size.x*0.08,size.y*0.70)
	detail.size = Vector2(size.x*0.84,54)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.tooltip_text = detail.text
	var name_width: float = detail.get_theme_font("font").get_string_size(detail.text,HORIZONTAL_ALIGNMENT_LEFT,-1,42).x
	jersey.position = Vector2(maxf(12,(size.x-minf(name_width,size.x*0.75))/2-44),size.y*0.70+11)
	team_line.add_theme_font_size_override("font_size",15)
	team_line.position = Vector2(0,size.y*0.79)
	team_line.size = Vector2(size.x,30)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.05,0.025,0.16))
	var ink := Color("efe9d9") if team == 0 else Color("ed7864")
	var offset := size.y * 0.26 * (1-entry)
	var sweep := PackedVector2Array([Vector2(0,minf(size.y,size.y*0.82+offset)),Vector2(size.x,size.y*0.16+offset),Vector2(size.x,size.y*0.29+offset),Vector2(0,minf(size.y,size.y*0.95+offset))])
	draw_colored_polygon(sweep,Color(ink,0.42 if team == 0 else 0.78))
	if reduced or not effects: return
	for particle in particles:
		var t: float = age/60.0-particle.delay
		if t < 0 or t > particle.life: continue
		var point: Vector2 = particle.origin*size + particle.velocity*t + Vector2(0,115*t*t)
		var edge_fade := clampf(minf(minf(point.x,size.x-point.x),minf(point.y,size.y-point.y))/48.0,0,1)
		var alpha := edge_fade*clampf(t/0.08,0,1)*clampf((particle.life-t)/0.28,0,1)
		if alpha <= 0: continue
		var edge: Vector2 = Vector2.from_angle(particle.angle+t*particle.spin)*particle.radius
		var side := edge.orthogonal()*0.4
		draw_colored_polygon(PackedVector2Array([point-edge-side,point+edge-side,point+edge+side,point-edge+side]),Color(particle.color,alpha))

func _make_particles(seed_value: int, scoring_team: int) -> void:
	# One bounded cosmetic burst, independent of the authoritative match RNG.
	var cosmetic_rng := RandomNumberGenerator.new()
	cosmetic_rng.seed = seed_value
	particles.clear()
	for i in 60:
		var x := cosmetic_rng.randf_range(0.14,0.86)
		particles.append({"origin":Vector2(x,0.83-0.58*x+cosmetic_rng.randf_range(-0.18,0.18)),
			"velocity":Vector2(cosmetic_rng.randf_range(-160,160),cosmetic_rng.randf_range(-190,-65)),
			"delay":cosmetic_rng.randf_range(0.05,0.22),"life":cosmetic_rng.randf_range(0.85,1.4),
			"angle":cosmetic_rng.randf_range(0,TAU),"spin":cosmetic_rng.randf_range(-5,5),
			"radius":cosmetic_rng.randf_range(2.5,5.0),
			"color":[Color("efe9d9"),Color("cfa55d"),Color("efe9d9") if scoring_team == 0 else Color("ed7864")][i%3]})
