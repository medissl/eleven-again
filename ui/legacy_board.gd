extends Control
const Legacy=preload("res://run/manager_legacy.gd")
const Parts=preload("res://ui/campaign_parts.gd")
const Lobby=preload("res://ui/campaign_lobby.gd")
const DIRECTIONS := [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,-1)]
const COLOURS := [Color("64979A"),Color("F28768"),Color("F5CE65"),Color("8AC66B"),Color("A8C8BF"),Color("C77BD5")]
const SYMBOLS := ["anticipator","switch_play","tempo_setter","accelerator","third_man","finesse_shot"]
var app: Control
var selected := "scouting1"
var buttons := {}
var details: Label
var title: Label
var buy: Button
var saved: Dictionary
var generation := 0

static func point(branch: int, level: int) -> Vector2:
	var axial: Vector2=Vector2(DIRECTIONS[branch])*level
	return Vector2(830,370)+Vector2(sqrt(3)*(axial.x+axial.y/2),1.5*axial.y)*39

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	saved=app.session.profile.get("legacy",Legacy.empty()).duplicate(true)
	generation=app.session.profile.generation
	Lobby.copy(app,self,"MANAGER LEGACY",Rect2(32,98,900,48),34,"Heading")
	Lobby.copy(app,self,"%d MARKS" % saved.marks,Rect2(32,152,440,36),25,"Score")
	var panel: Control=Lobby.panel(self,Rect2(32,214,440,392))
	title=Lobby.copy(app,panel,"",Rect2(24,24,392,68),28,"Heading")
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; title.size=Vector2(392,68)
	details=Lobby.copy(app,panel,"",Rect2(24,108,392,166),20)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.size=Vector2(392,166)
	buy=Lobby.action(app,panel,"Unlock","BuyLegacyNode",Rect2(24,300,392,52),purchase,true)
	for branch in 6:
		for level in range(1,5):
			var id: String=Legacy.BRANCHES[branch]+str(level)
			var button := Hex.new()
			button.name="LegacyNode"+id; button.position=point(branch,level)-Vector2(32,28); button.size=Vector2(64,56)
			button.level=level; button.colour=COLOURS[branch]; button.glyph=preload("res://ui/ability_icons.gd").texture(SYMBOLS[branch])
			button.owned=id in saved.purchased; button.locked=not Legacy.prerequisites(id,saved.purchased)
			button.tooltip_text=Legacy.NODES[id][0]+" — "+str(Legacy.cost(id))+" Marks"
			button.pressed.connect(func(): select(id))
			buttons[id]=button; add_child(button)
	var centre := TextureRect.new()
	centre.texture=preload("res://assets/ui/arcade/logo.png")
	centre.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; centre.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; centre.mouse_filter=Control.MOUSE_FILTER_IGNORE
	centre.position=Vector2(798,346); centre.size=Vector2(64,32)
	add_child(centre)
	var manager_name: Label=Lobby.copy(app,self,"MANAGER",Rect2(798,380,64,20),12,"Score")
	manager_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	Lobby.copy(app,self,"Upgrades apply to your next run.",Rect2(32,610,600,28),17)
	Lobby.action(app,self,"Back","LegacyBack",Rect2(32,646,172,50),func(): app.render("main"))
	select(selected)
	for id in buttons:
		var current: Button=buttons[id]
		for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
			var best: Button
			var score := INF
			var direction: Vector2={SIDE_LEFT:Vector2.LEFT,SIDE_RIGHT:Vector2.RIGHT,SIDE_TOP:Vector2.UP,SIDE_BOTTOM:Vector2.DOWN}[side]
			for other in buttons.values():
				var delta: Vector2=other.position-current.position
				if delta.dot(direction) <= 1: continue
				var distance := delta.length()+absf(delta.cross(direction))*2
				if distance < score: best=other; score=distance
			if best != null: current.set_focus_neighbor(side,current.get_path_to(best))

func select(id: String) -> void:
	selected=id
	for key in buttons: buttons[key].selected=key == id; buttons[key].queue_redraw()
	title.text=id.left(-1).capitalize()+" "+id.right(1)+"\n"+Legacy.NODES[id][0]
	details.text=Legacy.NODES[id][1]+"\n\n%d Marks   %s" % [Legacy.cost(id),"OWNED" if id in saved.purchased else "Requires preceding node" if not Legacy.prerequisites(id,saved.purchased) else "Available"]
	buy.text="Owned" if id in saved.purchased else "Unlock  %d Marks" % Legacy.cost(id)
	buy.disabled=id in saved.purchased or saved.marks < Legacy.cost(id) or not Legacy.prerequisites(id,saved.purchased)

func purchase() -> void:
	var result: Dictionary=app.session.buy_legacy(selected,generation)
	if not result.ok: app.message(result.error); return
	app.render("master_legacy")

func _draw() -> void:
	for branch in 6:
		var previous := Vector2(830,370)
		for level in range(1,5):
			var next := point(branch,level)
			draw_line(previous,next,COLOURS[branch].darkened(0.55),3,false)
			previous=next

class Hex:
	extends Button
	var level := 1
	var colour := Color.WHITE
	var glyph: Texture2D
	var owned := false
	var locked := true
	var selected := false
	func _init() -> void:
		set_meta("game_control",true)
		for state in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw); focus_entered.connect(queue_redraw); focus_exited.connect(queue_redraw)
	func _draw() -> void:
		draw_set_transform(Vector2(0,2 if is_pressed() else 0))
		var active: bool=selected or is_hovered() or (has_focus() and get_viewport().get_meta("keyboard_navigation",false))
		draw_texture_rect(preload("res://assets/ui/arcade/legacy_hex.png"),Rect2(Vector2.ZERO,size),false,Color.WHITE if active else colour if owned else Color("446C7A"))
		draw_texture_rect(glyph,Rect2(20,10,24,24),false,colour if owned or active else Color("64979A"))
		var font: Font=preload("res://ui/typography.gd").face("Score")
		draw_string(font,Vector2(26,47),str(level),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("FFF4D2"))
		if locked: draw_texture_rect(preload("res://assets/ui/arcade/lock.png"),Rect2(43,35,12,14),false)
		elif owned: draw_string(font,Vector2(44,45),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("FFF4D2"))
