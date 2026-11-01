extends Control
## A brief broadcast ribbon, separate from goal/confetti and persistent period reports.
var title: Label
var detail: Label
var elapsed := 0.0
var duration := 0.0
var reduced := false
var blocked := false
var priority := 0
var accent := Color("F5CE65")
var activation_count := 0
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for role in ["Goal","Section"]:
		var label := Label.new()
		label.theme_type_variation = role
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color",Color("FFF4D2"))
		label.add_theme_font_size_override("font_size",48 if role == "Goal" else 18)
		add_child(label)
	title = get_child(0)
	detail = get_child(1)
	hide()

func present(headline: String, copy: String = "", seconds: float = 1.65, importance: int = 1, ink: Color = Color("F5CE65")) -> void:
	if visible and elapsed < duration*0.5 and importance < priority: return
	accent = ink
	title.text = headline
	detail.text = copy
	elapsed = 0
	duration = seconds
	priority = importance
	activation_count += 1
	show()

func consume(event: Dictionary, teams: Array) -> void:
	var team: int = event.get("team",-1)
	var who: String = teams[team] if team in [0,1] else ""
	match str(event.kind):
		"kickoff_setup": present("KICK-OFF",who,1.2,2)
		"kickoff_whistle": present("KICK-OFF","",0.55,2)
		"offside": present("OFFSIDE",event.get("actor_name",""),1.65,2)
		"foul": present("FOUL",event.get("actor_name",""),1.65,1)
		"yellow_card": present("YELLOW CARD",event.get("actor_name",""),1.8,3,Color("E5C66D"))
		"red_card": present("RED CARD",event.get("actor_name",""),2.2,4,Color("F16883"))
		"restart_setup":
			var kind: String = event.get("restart","")
			if kind in ["free_kick","indirect_free_kick","penalty","corner","throw_in","goal_kick"]:
				present(kind.replace("_"," ").to_upper(),who,1.4,1)
		"extra_time": present("EXTRA TIME","Two halves. One more chance.",2.0,4)
		"extra_half": present("EXTRA TIME","SECOND HALF",1.8,4)
		"shootout_start": present("PENALTY SHOOTOUT","",2.0,4)

func _process(delta: float) -> void:
	if duration <= 0: return
	elapsed += delta
	visible = elapsed < duration and not blocked
	if not visible: return
	var entry := 1.0 if reduced else 1-pow(1-clampf(elapsed/0.2,0,1),3)
	modulate.a = 1 if reduced else minf(clampf(elapsed/0.08,0,1),clampf((duration-elapsed)/0.2,0,1))
	var y := size.y*0.67
	title.position = Vector2((1-entry)*20,y)
	title.size = Vector2(size.x,66)
	detail.position = Vector2(0,y+65)
	detail.size = Vector2(size.x,28)
	queue_redraw()

func _draw() -> void:
	var y := size.y*0.67
	var width := minf(size.x-40,580)
	var left := (size.x-width)/2
	draw_colored_polygon(PackedVector2Array([Vector2(left+18,y-5),Vector2(left+width,y-5),Vector2(left+width-18,y+102),Vector2(left,y+102)]),Color("101827ED"))
	draw_line(Vector2(left+18,y-5),Vector2(left+width,y-5),accent,2,true)
