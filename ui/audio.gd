extends Node
## One bounded mixer per app. Match sound consumes events; it never owns football.
const ROOT := "res://assets/audio/"
const FILES := {"click":"ui_click.ogg","hover":"ui_hover.ogg","confirm":"ui_confirm.ogg","back":"ui_back.ogg","shuffle":"card_shuffle.ogg","place":"card_place.ogg","slide":"card_slide.ogg","kick":"football_kick.mp3","dribble":"football_kick.mp3","shot":"football_kick.mp3","save":"shot.ogg","tackle":"grass_contact.ogg","contact":"contact.ogg","whistle":"whistle_referee.mp3","goal":"stadium_goal.mp3"}
var streams := {}
var voices: Array[AudioStreamPlayer] = []
var menu: AudioStreamPlayer
var bed: AudioStreamPlayer
var hype: AudioStreamPlayer
var walkout: AudioStreamPlayer
var in_walkout := false
var walkout_energy := 0.0
var in_match := false
var music_level := 0.65
var effects_level := 0.8
var crowd_energy := 0.0
var target_energy := 0.0
var last_hover := -1000
var last_kick := -1000
var last_dribble := -1000
var dribble_owner := -1
var dribble_position := Vector2.ZERO
var dribble_distance := 0.0
var whistle_generation := 0
var cues: Array[String] = [] # Bounded diagnostic history, never serialized into saves.

static func obtain(owner: Node) -> Node:
	var parent := owner
	while parent != null:
		if parent.has_meta("audio_director"): return parent.get_meta("audio_director")
		parent = parent.get_parent()
	var audio: Node = load("res://ui/audio.gd").new()
	owner.set_meta("audio_director",audio)
	owner.add_child(audio)
	return audio

func stream(file: String, looping: bool = false) -> AudioStream:
	if not streams.has(file):
		var path := ROOT+file
		var sound: AudioStream
		if file.ends_with(".mp3"): sound=AudioStreamMP3.load_from_file(path)
		elif file.ends_with(".wav"): sound=AudioStreamWAV.load_from_file(path)
		else: sound=AudioStreamOggVorbis.load_from_file(path)
		if sound == null: push_error("Unable to decode audio: "+path); return null
		if looping:
			if sound is AudioStreamWAV: sound.loop_mode=AudioStreamWAV.LOOP_FORWARD
			else: sound.loop=true
		streams[file] = sound
	return streams[file]

func layer(file: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream(file,true)
	player.volume_db = -80
	add_child(player)
	return player

func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	menu = layer("menu.ogg")
	bed = layer("stadium_bed.mp3")
	hype = layer("stadium_hype.mp3")
	walkout = layer("walkout.mp3")
	for index in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	menu.play()

func _node_added(node: Node) -> void:
	if node is Control and get_parent().is_ancestor_of(node): _bind_added.call_deferred(node.get_instance_id())

func _bind_added(id: int) -> void:
	var node := instance_from_id(id) as Control
	if is_instance_valid(node) and node.is_inside_tree(): bind_control(node)

func set_match(value: bool) -> void:
	if value == in_match: return
	in_match = value
	whistle_generation += 1
	target_energy = 0
	if value:
		if not bed.playing: bed.play()
		if not hype.playing: hype.play()
	elif not menu.playing: menu.play()

func gain(player: AudioStreamPlayer, target: float, delta: float) -> void:
	var current := db_to_linear(player.volume_db)
	var value := lerpf(current,target,1-exp(-delta*7))
	if target == 0 and value < 0.001: value=0
	player.volume_db = linear_to_db(maxf(value,0.00001))
	if value == 0 and player.playing: player.stop()
	elif target > 0 and not player.playing: player.play()

func _process(delta: float) -> void:
	crowd_energy = lerpf(crowd_energy,target_energy,1-exp(-delta*(2.2 if target_energy > crowd_energy else 0.9)))
	gain(menu,0.0 if in_match or in_walkout else music_level*0.32,delta)
	gain(walkout,music_level*(0.14+walkout_energy*0.34) if in_walkout else 0.0,delta)
	gain(bed,effects_level*(0.10+walkout_energy*0.12) if in_walkout else effects_level*0.22 if in_match else 0.0,delta)
	gain(hype,effects_level*walkout_energy*0.58 if in_walkout else effects_level*crowd_energy*0.34 if in_match else 0.0,delta)

func set_walkout(value: bool) -> void:
	in_walkout = value
	if not value: walkout_energy = 0
	if value and not walkout.playing: walkout.play()

func reveal_sting(seconds: float) -> void:
	play("goal",-9)
	var voice: AudioStreamPlayer
	for candidate in voices:
		if candidate.playing and candidate.stream == stream(FILES.goal): voice=candidate
	if voice == null: return
	var token := Time.get_ticks_usec()
	voice.set_meta("reveal_token",token)
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(voice) and voice.get_meta("reveal_token",-1) == token: voice.stop()

func bind_control(control: Control) -> void:
	if not (control is BaseButton or control is Slider) or control.has_meta("audio_bound"): return
	control.set_meta("audio_bound",true)
	var hover := func():
		if control is BaseButton and control.disabled: return
		var now := Time.get_ticks_msec()
		if now-last_hover > 90: last_hover=now; play("hover",-23)
	control.mouse_entered.connect(hover)
	# Keyboard focus gets the same cue; page construction never emits a selection sound.
	control.focus_entered.connect(func(): if control.is_visible_in_tree(): hover.call())
	if control is BaseButton: control.button_down.connect(func(): if not control.disabled: play("click",-13))

func play(cue: String, db: float = -9, pitch: float = 1.0) -> void:
	if not FILES.has(cue): return
	cues.append(cue)
	if cues.size() > 64: cues.pop_front()
	var voice: AudioStreamPlayer
	for candidate in voices:
		if not candidate.playing: voice=candidate; break
	# Preserve referee/goal cues over incidental foley when all eight voices are busy.
	if voice == null:
		if cue not in ["whistle","goal"]: return
		voice = voices[0]
	voice.stream = stream(FILES[cue])
	voice.set_meta("reveal_token",-1)
	voice.volume_db = db+linear_to_db(maxf(0.00001,effects_level))
	voice.pitch_scale = pitch
	voice.play()

func whistle(count: int = 1) -> void:
	whistle_generation += 1 # A new referee sequence cancels any unfinished previous pattern.
	var generation := whistle_generation
	for index in count:
		if generation != whistle_generation or not in_match: return
		play("whistle",-7,1.0)
		if index < count-1: await get_tree().create_timer(0.6).timeout

func consume(event: Dictionary) -> void:
	match str(event.kind):
		"kickoff_setup": whistle_generation += 1
		"kickoff_whistle", "foul", "offside": whistle()
		"halftime", "extra_half": whistle(2)
		"full_time": whistle(3)
		"extra_time", "shootout_start": whistle(3)
		"goal", "shootout_goal": play("goal",-11)
		"pass", "cross", "kickoff", "throw_in", "corner", "goal_kick", "free_kick", "indirect_free_kick", "penalty":
			var now := Time.get_ticks_msec()
			if now-last_kick > 70: last_kick=now; play("kick",-16)
		"shot", "shootout_shot": play("shot",-7,0.92)
		"save", "parry", "smother": play("save",-12,0.88)
		"block": play("contact",-16)
		"tackle": play("tackle",-12); play("contact",-16,0.9)

func watch_match(model: RefCounted, paused: bool) -> void:
	if model.owner != dribble_owner or paused or model.ball_state != model.BallState.CONTROLLED:
		dribble_owner = model.owner
		dribble_position = model.ball
		dribble_distance = 0
	elif model.owner >= 0:
		dribble_distance += dribble_position.distance_to(model.ball)
		dribble_position = model.ball
		var now := Time.get_ticks_msec()
		if dribble_distance >= 2.6 and now-last_dribble >= 230:
			play("dribble",-23,1.2)
			last_dribble = now
			dribble_distance = 0
	if paused or model.finished or model.ball_state in [model.BallState.DEAD,model.BallState.KICKOFF]:
		target_energy = 0.08
		return
	var attacking := 0
	if model.owner >= 0: attacking=model.players[model.owner].team
	elif model.flight_source >= 0: attacking=model.players[model.flight_source].team
	var local: Vector2 = model.oriented(model.ball,attacking)
	var threat := smoothstep(66,99,local.x)*(1.0-0.55*clampf(absf(local.y-34)/34,0,1))
	if model.ball_state == model.BallState.FLIGHT and model.flight_kind in ["shot","header"]: threat=maxf(threat,0.9)
	target_energy = clampf(threat,0,1)
