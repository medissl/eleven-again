extends RefCounted
## Four seconds of compact, recorded render state. No re-simulation and no gameplay RNG.
const LIMIT := 240
var frames: Array[Dictionary] = []
var event_cursor := 0
func clear() -> void:
	frames.clear()
	event_cursor = 0
func capture(model: RefCounted) -> void:
	var positions := PackedVector2Array()
	var facing := PackedVector2Array()
	var names := PackedStringArray()
	var roles := PackedStringArray()
	var active := 0
	for player in model.players:
		positions.append(player.position)
		facing.append(player.facing)
		names.append(player.name)
		roles.append(player.role)
		if player.active: active |= 1 << player.id
	var sounds: Array[String] = []
	for index in range(event_cursor,model.events.size()):
		if model.events[index].kind in ["pass","cross","shot","save","parry","block","tackle"]: sounds.append(model.events[index].kind)
	event_cursor = model.events.size()
	frames.append({"tick":model.ticks,"active_tick":model.active_ticks,"positions":positions,"facing":facing,"names":names,"roles":roles,"active":active,"ball":model.ball,"height":model.ball_height,"owner":model.owner,"state":model.ball_state,"scores":model.scores.duplicate(),"sounds":sounds})
	if frames.size() > LIMIT: frames.pop_front()

func goal_clip(model: RefCounted, event: Dictionary) -> Dictionary:
	var shot: int = event.tick
	for entry in model.events:
		if entry.tick > event.tick: break
		if entry.kind == "shot": shot=entry.tick
	# Do not replay a shape teleport from an earlier restart as a football movement.
	var start: int = frames[0].tick if not frames.is_empty() else event.tick
	for entry in model.events:
		if entry.tick > event.tick: break
		if entry.kind in ["kickoff_setup","restart_setup"]: start=maxi(start,entry.tick)
	if shot < start: shot=event.tick
	var clip: Array[Dictionary] = []
	for frame in frames:
		if frame.tick >= start and frame.tick <= event.tick: clip.append(frame)
	return {"frames":clip,"shot_tick":shot,"event":event.duplicate(true),"snapshot":model.snapshot()}
