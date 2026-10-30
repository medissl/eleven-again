extends Control
signal finished
const Snapshot = preload("res://match/match_snapshot.gd")
var clip: Dictionary
var match_view: Control
var pitch_view: Control
var veil: ColorRect
var brand: Label
var goal: Label
var slow: Label
var age := 0.0
var cursor := 0.0
var last_sound_frame := -1
var ending := -1.0
var slow_motion := false
var skipped := false
var reduced := false
var goal_hold := 0.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = match_view.theme
	reduced = match_view.hud.reduced_motion
	var frames: Array = clip.frames
	if frames.size() >= 2 and not reduced:
		pitch_view = load("res://match/replay_pitch.gd").new()
		pitch_view.external_model = Snapshot.restore(clip.snapshot)
		pitch_view.team_names = match_view.team_names.duplicate()
		pitch_view.team_kits = match_view.team_kits.duplicate()
		pitch_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(pitch_view)
		pitch_view.recorded_frame(frames[0],frames[1],0)
	goal = label("GOAL",22,"Heading",Rect2(size.x-246,138,222,34))
	var scorer: Resource = match_view.sim.players[clip.event.actor].card
	var metadata: Dictionary = match_view.card_library.metadata(scorer.card_id) if match_view.card_library != null else preload("res://content/catalogue.gd").new().metadata(scorer.card_id)
	var card := preload("res://ui/player_card.gd").new()
	card.name = "ScorerCard"
	card.custom_minimum_size=Vector2(222,310.8)
	card.size=card.custom_minimum_size
	card.position=Vector2(size.x-246,184)
	card.bind(scorer,metadata)
	card.focus_mode=Control.FOCUS_NONE
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(card)
	slow = label("REPLAY",18,"Section",Rect2(size.x-246,524,222,34))
	var skip := Button.new()
	skip.text = "Skip replay"
	skip.name = "SkipReplay"
	skip.position = Vector2(size.x-246,size.y-62)
	skip.size = Vector2(222,44)
	skip.pressed.connect(skip_replay)
	skip.tooltip_text = "Click, Space or Escape"
	add_child(skip)
	veil = ColorRect.new()
	veil.color = Color("080E19")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	brand = label("ELEVEN AGAIN",60,"Heading",Rect2(0,size.y/2-54,size.x,108))
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if reduced or frames.size() < 2:
		brand.text = "GOAL  %d – %d" % clip.event.score
		veil.color.a = 0.94

func label(value: String, pixels: int, role: String, rect: Rect2) -> Label:
	var node := Label.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.theme_type_variation = role
	node.add_theme_font_size_override("font_size",pixels)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func skip_replay() -> void:
	if ending >= 0: return
	skipped = true
	ending = 0

func _process(delta: float) -> void:
	if ending >= 0:
		ending += delta
		veil.color.a = 1 if reduced else clampf(ending/0.12,0,1)
		brand.modulate.a = 0
		if ending >= (0.01 if reduced else 0.14): finished.emit(); queue_free()
		return
	if match_view.paused: return
	age += delta
	if is_instance_valid(match_view.audio): match_view.audio.target_energy=0.65
	if reduced or not is_instance_valid(pitch_view):
		if age >= 1.0: skip_replay()
		return
	if age < 0.8:
		brand.modulate.a = sin(clampf(age/0.8,0,1)*PI)
		veil.color.a = 1 if age < 0.4 else 1-smoothstep(0.4,0.8,age)
		return
	brand.hide()
	veil.color.a = 0
	var frames: Array = clip.frames
	var index := mini(frames.size()-1,floori(cursor))
	var tick: int = frames[index].tick
	slow_motion = tick >= clip.shot_tick-24
	slow.text = "SLOW MOTION  0.3×" if slow_motion else "REPLAY"
	for frame_index in range(last_sound_frame+1,index+1):
		if is_instance_valid(match_view.audio):
			for cue in frames[frame_index].sounds:
				match_view.audio.consume({"kind":cue})
	last_sound_frame = index
	pitch_view.recorded_frame(frames[index],frames[mini(index+1,frames.size()-1)],fmod(cursor,1))
	if index >= frames.size()-1:
		goal_hold += delta
		if goal_hold > 0.7: skip_replay()
	else: cursor=minf(frames.size()-1,cursor+delta*60*(0.3 if slow_motion else 1.0))
