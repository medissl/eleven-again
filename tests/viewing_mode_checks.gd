extends SceneTree
const Match=preload("res://match/match_sim.gd")
const Runner=preload("res://match/fast_forward.gd")
const Snapshot=preload("res://match/match_snapshot.gd")
func _initialize() -> void:
	var start := Time.get_ticks_usec()
	var live := Match.new(47,Match.REGULATION_SECONDS,null,null,true)
	live.analytics=Match.Analytics.empty(true)
	var instant := Snapshot.restore(Snapshot.capture(live))
	var highlights := Snapshot.restore(Snapshot.capture(live))
	while not live.finished:
		if live.period == Match.Period.HALF_TIME: live.acknowledge_halftime()
		live.step()
	var fast := Runner.new(instant)
	while not fast.advance(500,0): pass
	var clips := Runner.new(highlights,true)
	while not clips.advance(500,0): pass
	assert(live.signature() == instant.signature() and instant.signature() == highlights.signature(),"Exact scores/events/RNG/player state across all three modes")
	assert(live.analytics == instant.analytics and instant.analytics == highlights.analytics,"Exact probability provenance")
	assert(instant.regulation_ticks == 10800)
	assert(not clips.selected_clips().is_empty())
	for clip in clips.selected_clips():
		assert(clip.event in live.events and clip.frames.back().tick == clip.event.tick,"Highlights are actual recorded render frames")
	var seconds: float=(Time.get_ticks_usec()-start)/1000000.0
	print("VIEWING MODES: three complete 180-active-second native matches, exact signatures/analytics, recorded highlights passed in %.3fs; score %s, ticks %d" % [seconds,str(live.scores),live.ticks])
	quit()
