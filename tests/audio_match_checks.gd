extends SceneTree
const Match = preload("res://match/match_sim.gd")
const Clock = preload("res://match/broadcast_clock.gd")
const Snapshot = preload("res://match/match_snapshot.gd")
const Audio = preload("res://ui/audio.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func capture(viewport: SubViewport, name: String, height: int) -> void:
	await frames(28)
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png("res://reports/match-audio/"+name+"-%d.png" % height) == OK,"Native broadcast capture: "+name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/match-audio")
	var model := Match.new(42)
	var initial_rng := model.rng.state
	for tick in 71: model.step()
	check(model.active_ticks == 0 and model.events.filter(func(event): return event.kind == "kickoff_whistle").is_empty(),"Arrival precedes the kickoff whistle")
	model.step()
	check(model.events.back().kind == "kickoff_whistle" and model.kickoff_ticks == 180,"Whistle occurs exactly three simulation seconds before the kick")
	var saved: Dictionary = model.snapshot()
	var resumed: RefCounted = Snapshot.restore(saved)
	check(resumed != null and resumed.snapshot() == saved,"A saved whistle countdown restores exactly")
	for tick in 179:
		model.step()
		resumed.step()
	check(model.ball == model.CENTRE and model.active_ticks == 0 and model.rng.state == initial_rng,"Post-whistle delay consumes no active time or RNG")
	model.step()
	resumed.step()
	check(model.snapshot() == resumed.snapshot() and model.active_ticks == 1 and model.ball_state == model.BallState.FLIGHT,"The delayed kick is physical, active and identical after resume")
	model = Match.new(42)
	model.take_control(9)
	model.ball = model.CENTRE
	model.Discipline.foul(model,12,9,1)
	check(model.fouls[1] == 1 and model.players[12].yellows == 1 and model.restart_kind == "free_kick" and model.dead_ticks == 180,"A real foul awards a real free kick, discipline and a three-second wait")
	for tick in 179: model.step()
	check(model.active_ticks == 0 and model.ball_state == model.BallState.DEAD,"Whistled restart never advances regulation during its wait")
	model.step()
	check(model.ball_state != model.BallState.DEAD,"Free kick actually restarts after the wait")
	var clock_model := Match.new(42)
	clock_model.events.clear()
	clock_model.scores = [1,0]
	clock_model.ticks = 100
	clock_model.emit_event("goal",9,{"team":0,"score":[1,0]})
	clock_model.ticks = 700
	clock_model.emit_event("kickoff",9)
	clock_model.ticks = 5500
	clock_model.active_ticks = 4800
	var before: Dictionary = clock_model.snapshot()
	var clock := Clock.read(clock_model)
	check(clock.added and clock.minimum == 5 and clock.text == "45′ +1" and clock.lost_ticks == 600,"Added-time board derives from actual dead-ball spans, not random minutes")
	check(clock_model.snapshot() == before,"Broadcast time changes no authoritative state or RNG")
	clock_model.period = Match.Period.SECOND_HALF
	clock_model.emit_event("halftime",-1)
	clock = Clock.read(clock_model)
	check(not clock.added and clock.minimum == 0,"Each half starts with its own lost-time ledger")
	var Preferences = load("res://persistence/preferences.gd")
	var save_root := "user://audio_check_"+str(Time.get_ticks_usec())
	var prefs: RefCounted = Preferences.new(save_root)
	var legacy: Dictionary = prefs.data.duplicate(true)
	legacy.erase("music_volume")
	legacy.erase("effects_volume")
	check(Preferences.valid(legacy),"Existing settings remain valid without new channel fields")
	check(not prefs.change("music_volume",NAN).ok and not prefs.change("effects_volume",-0.1).ok,"Audio controls reject nonfinite and out-of-range values")
	check(prefs.change("music_volume",0.3).ok and Preferences.new(save_root).data.music_volume == 0.3,"Menu music gain persists independently")
	var height := 1080 if "--1080" in OS.get_cmdline_user_args() else 720
	var viewport := SubViewport.new()
	viewport.size = Vector2i(height*16/9,height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view := preload("res://match/match_view.gd").new()
	view.fixture_seed = 42
	view.size = viewport.size
	viewport.add_child(view)
	view.set_physics_process(false)
	var audio: Node = view.audio
	for file in ["menu.ogg","stadium_bed.mp3","stadium_hype.mp3"]+Audio.FILES.values():
		var sound: AudioStream = audio.stream(file,file in ["menu.ogg","stadium_bed.mp3","stadium_hype.mp3"])
		check(sound != null and sound.get_length() > 0,"Native decoder reads licensed asset: "+file)
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	audio.set_match(false)
	await frames(72)
	check(audio.menu.playing and not audio.bed.playing,"Menus have music and no stadium bed")
	audio.play("click")
	audio.set_match(true)
	for tick in 72: view.sim.step()
	view._sync_state()
	await capture(viewport,"kickoff",height)
	await frames(50)
	check(not audio.menu.playing and audio.bed.playing,"Gameplay has stadium ambience and no menu music")
	check(audio.cues.count("whistle") == 1,"Only the new kickoff whistle is consumed; historical events do not replay")
	var signature: Array = view.sim.signature()
	view._sync_state()
	check(audio.cues.count("whistle") == 1 and view.sim.signature() == signature,"Repeated render synchronization duplicates neither sounds nor football")
	view.sim.kickoff_ticks = 1
	view.sim.step()
	view.sim.take_control(8)
	view.sim.ball = view.sim.oriented(Vector2(97,34),0)
	view._sync_state()
	await frames(60)
	check(audio.target_energy > 0.8 and audio.crowd_energy > 0.5,"A real attacking position raises the crowd, independent of scoring")
	view.sim.ball = view.sim.oriented(Vector2(20,34),0)
	view._sync_state()
	check(audio.target_energy < 0.1,"Crowd tension falls when the ball leaves danger")
	view.sim.ball = view.sim.CENTRE
	view.sim.Discipline.foul(view.sim,12,8,1)
	view._sync_state()
	await capture(viewport,"foul",height)
	view.sim = clock_model
	clock_model.events.pop_back() # Remove the authored reset probe before rendering live first-half evidence.
	view.sim.period = Match.Period.FIRST_HALF
	view.hud.added_period = -1
	view._sync_state()
	await capture(viewport,"added-time",height)
	check("+" in view.hud.labels.clock.text,"Native clock shows added time while active regulation remains")
	view.sim.period = Match.Period.HALF_TIME
	view.sim.active_ticks = view.sim.regulation_ticks/2
	view.sim.emit_event("halftime",-1)
	view.sim.halftime_report = view.sim.snapshot_report()
	view._sync_state()
	await capture(viewport,"halftime",height)
	check(view.paused and view.overlay_mode == "halftime" and view.hud.panel_content.find_child("PhaseTitle",true,false).text == "HALF TIME","Animated halftime title leads to the deliberate report")
	view._close_overlay(false)
	view.sim.active_ticks = view.sim.regulation_ticks
	view.sim.finish_match()
	view._sync_state()
	var whistle_before: int = audio.cues.count("whistle")
	await frames(90)
	check(audio.cues.count("whistle") == whistle_before+2,"Full-time whistle has exactly three scheduled blows")
	await capture(viewport,"fulltime",height)
	check(view.overlay_mode == "result" and view.paused,"Final report remains until Continue")
	recorder.set_recording_active(false)
	var recording: AudioStreamWAV = recorder.get_recording()
	check(recording != null and recording.data.size() > 10000,"Native audio mix actually produced PCM frames")
	if recording != null:
		var peak := 0
		var pcm := recording.data
		for offset in range(0,pcm.size()-2,2): peak=maxi(peak,absi(pcm.decode_s16(offset)))
		check(peak > 100 and peak < 32767,"Recorded mix is audible and not digitally clipped")
		recording.save_to_wav("res://reports/match-audio/native-mix-%d.wav" % height)
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	print("AUDIO MATCH ",height," checks=",checks," failures=",failures)
	view.queue_free()
	quit(1 if failures else 0)
