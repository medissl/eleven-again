extends RefCounted
## A viewer changes which ticks are rendered, never how football is resolved.
const Replay=preload("res://match/replay_buffer.gd")
var model: RefCounted
var history := Replay.new()
var clips: Array[Dictionary]=[]
var collect := false
var cursor := 0
var last_clip_tick := -10000

func _init(match_model: RefCounted, highlights: bool = false) -> void:
	model=match_model
	collect=highlights
	cursor=model.events.size()

func advance(max_steps: int = 240, wall_budget_us: int = 8000) -> bool:
	var start := Time.get_ticks_usec()
	for index in max_steps:
		if model.finished: return true
		if model.period == model.Period.HALF_TIME: model.acknowledge_halftime()
		model.step()
		if collect:
			history.capture(model)
			for event_index in range(cursor,model.events.size()):
				var event: Dictionary=model.events[event_index]
				if event.kind not in ["goal","save","parry","shot","trait_execution"]: continue
				if event.kind != "goal" and model.ticks-last_clip_tick < 300: continue
				var frames: Array[Dictionary]=history.frames.duplicate()
				clips.append({"event":event.duplicate(true),"frames":frames})
				last_clip_tick=model.ticks
				if clips.size() > 18:
					var removable: int=clips.find_custom(func(clip): return clip.event.kind != "goal")
					clips.remove_at(removable if removable >= 0 else 0)
			cursor=model.events.size()
		if wall_budget_us > 0 and Time.get_ticks_usec()-start >= wall_budget_us: break
	return model.finished

func selected_clips() -> Array[Dictionary]:
	var selected: Array[Dictionary]=clips.filter(func(clip): return clip.event.kind == "goal")
	selected=selected.slice(maxi(0,selected.size()-8))
	for clip in clips:
		if selected.size() >= 8: break
		if clip.event.kind != "goal": selected.append(clip)
	selected.sort_custom(func(a,b): return a.event.tick < b.event.tick)
	return selected
