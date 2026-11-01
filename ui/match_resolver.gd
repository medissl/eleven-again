extends Control
signal completed
const Runner=preload("res://match/fast_forward.gd")
var model: RefCounted
var highlights := false
var team_names: Array=[]
var team_kits: Array=[]
var runner: RefCounted
var label: Label
var pitch: Control
var clips: Array=[]
var clip_index := -1
var clip_age := 0.0
var resolving := true
var skip: Button
var audio: Node
var sound_cursor := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	runner=Runner.new(model,highlights)
	var shade := ColorRect.new()
	shade.color=Color("101827"); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	label=preload("res://ui/campaign_parts.gd").label(self,"RESOLVING MATCH",32,"Heading")
	label.position=Vector2(40,40); label.size=Vector2(1180,60)
	skip=preload("res://ui/campaign_parts.gd").button(self,"Continue to result","SkipMasterHighlights",func(): completed.emit())
	skip.position=Vector2(900,646); skip.size=Vector2(348,50); skip.hide()

func _process(delta: float) -> void:
	if resolving:
		label.text="RESOLVING MATCH   %d'" % model.display_minute()
		if not runner.advance(): return
		resolving=false
		if not highlights: set_process(false); completed.emit(); return
		clips=runner.selected_clips()
		if clips.is_empty(): set_process(false); completed.emit(); return
		pitch=load("res://match/replay_pitch.gd").new()
		pitch.external_model=load("res://match/match_snapshot.gd").restore(load("res://match/match_snapshot.gd").capture(model))
		pitch.team_names=team_names.duplicate(); pitch.team_kits=team_kits.duplicate()
		pitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(pitch); move_child(pitch,1)
		skip.show(); skip.text="Skip highlights"; skip.grab_focus()
		clip_index=0
		clip_age=0
	else:
		clip_age+=delta
		var clip: Dictionary=clips[clip_index]
		var frames: Array=clip.frames
		var cursor: int=mini(frames.size()-1,int(clip_age*60))
		pitch.recorded_frame(frames[cursor],frames[mini(cursor+1,frames.size()-1)],fmod(clip_age*60,1))
		if is_instance_valid(audio):
			audio.target_energy=0.8 if clip.event.kind == "goal" or absf(frames[cursor].ball.x-52.5) > 35 else 0.2
			if cursor != sound_cursor:
				for cue in frames[cursor].sounds: audio.play({"pass":"kick","cross":"kick","parry":"save","block":"contact"}.get(cue,cue),-13)
				sound_cursor=cursor
		label.text="%s   %d / %d" % [clip.event.kind.replace("_"," ").to_upper(),clip_index+1,clips.size()]
		if clip_age >= maxf(1,float(frames.size())/60):
			if is_instance_valid(audio) and clip.event.kind == "goal": audio.play("goal",-16)
			clip_index+=1; clip_age=0; sound_cursor=-1
			if clip_index >= clips.size(): set_process(false); completed.emit()
