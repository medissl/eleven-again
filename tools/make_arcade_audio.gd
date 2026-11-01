extends SceneTree
## Original short pulse/triangle UI cues and a seamless eight-bar stadium-menu loop.
const RATE := 22050
func hz(note: int) -> float: return 440.0*pow(2,(note-69)/12.0)
func pulse(phase: float) -> float: return 0.7 if fposmod(phase,1.0) < 0.25 else -0.233333
func triangle(phase: float) -> float: return 1.0-4.0*absf(fposmod(phase,1.0)-0.5)
func write(name: String, samples: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size()*2)
	for i in samples.size(): bytes.encode_s16(i*2,roundi(clampf(samples[i],-0.8,0.8)*32767))
	var audio := AudioStreamWAV.new()
	audio.format=AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate=RATE
	audio.data=bytes
	assert(audio.save_to_wav("res://assets/audio/arcade/"+name+".wav") == OK)
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/arcade")
	var cues := {"click":[76,81],"hover":[84],"back":[72,67],"confirm":[72,76,79,84],"place":[60,72],"slide":[69,74]}
	for id in cues:
		var notes: Array=cues[id]
		var step := 0.11 if id == "place" else 0.025 if id == "confirm" else 0.018
		var samples := PackedFloat32Array()
		samples.resize(roundi((notes.size()*step+0.025)*RATE))
		for i in samples.size():
			var time := float(i)/RATE
			var index := mini(int(time/step),notes.size()-1)
			var local := time-index*step
			var envelope := minf(local/0.004,1.0)*clampf((step+0.02-local)/0.025,0,1)
			samples[i]=pulse(time*hz(notes[index]))*envelope*0.24
		write(id,samples)
	for id in ["kick","dribble","shot","save","tackle","contact","whistle","shuffle"]:
		var duration: float={"kick":0.075,"dribble":0.035,"shot":0.12,"save":0.14,"tackle":0.12,"contact":0.09,"whistle":0.32,"shuffle":0.48}[id]
		var samples := PackedFloat32Array()
		samples.resize(roundi(duration*RATE))
		for i in samples.size():
			var t := float(i)/RATE
			var ratio := t/duration
			var noise := (float(posmod(int(i/5)*173+37,251))/125.0-1.0)
			var value := noise*exp(-ratio*8)*0.18+triangle(t*(90+120*exp(-ratio*8)))*exp(-ratio*10)*0.20
			if id == "whistle": value=pulse(t*(2300+40*sin(t*94)))*0.18*minf(1,t/0.012)*minf(1,(duration-t)/0.04)
			elif id == "shuffle":
				var local := fposmod(t,0.06)/0.06
				value=(noise*0.2+pulse(t*(600+int(t/0.06)*55))*0.10)*exp(-local*7)*(1-ratio*0.4)
			elif id == "shot": value+=pulse(t*(180+600*exp(-ratio*12)))*exp(-ratio*8)*0.08
			elif id == "save": value+=triangle(t*hz(72-int(ratio*12)))*exp(-ratio*4)*0.07
			samples[i]=roundf(value*64)/64.0*minf(1,t/0.002)*minf(1,(duration-t)/0.008)
		write(id,samples)
	var beat := 60.0/116
	var melody := [76,79,81,79,76,72,74,76,74,77,79,77,74,71,72,74,72,76,79,76,72,67,69,71,74,77,81,79,77,74,71,74]
	var roots := [48,43,45,41,48,43,41,43]
	var music := PackedFloat32Array()
	music.resize(roundi(beat*32*RATE))
	for i in music.size():
		var t := float(i)/RATE
		var b := int(t/beat)
		var part := fposmod(t,beat)/beat
		var root_note: int=roots[b/4]
		var envelope := minf(part/0.03,1)*clampf((0.82-part)/0.18,0,1)
		var lead := pulse(t*hz(melody[b]))*envelope*0.105
		var bass := triangle(t*hz(root_note-12))*clampf((0.80-part)/0.25,0,1)*0.13
		var arp_note: int=root_note+[0,7,12,16][int(t/(beat/2))%4]
		var arp := triangle(t*hz(arp_note))*0.035
		var kick := sin(TAU*(52*t+4*(1-exp(-part*20))))*exp(-part*22)*0.12 if b%2 == 0 else 0.0
		music[i]=(lead+bass+arp+kick)*minf(1,t/0.01)*minf(1,(beat*32-t)/0.01)
	write("menu",music)
	print("ARCADE AUDIO: six cues and seamless eight-bar loop generated")
	quit()
