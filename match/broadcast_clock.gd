extends RefCounted
## Reconstruct lost time from existing event spans. Regulation's active budget is unchanged.
static func read(model: RefCounted) -> Dictionary:
	var lost := [0,0,0,0]
	var index := 0
	var pending := -1
	for event in model.events:
		var kind: String = event.kind
		if kind in ["goal","restart_setup"] and pending < 0: pending=event.tick
		if kind in ["kickoff","throw_in","corner","free_kick","indirect_free_kick","goal_kick","penalty","halftime","extra_time","extra_half","full_time"] and pending >= 0:
			lost[index] += maxi(0,event.tick-pending)
			pending = -1
		if kind == "halftime": index=1
		elif kind == "extra_time": index=2
		elif kind == "extra_half": index=3
	var period: int = {model.Period.FIRST_HALF:0,model.Period.HALF_TIME:0,model.Period.SECOND_HALF:1,model.Period.EXTRA_FIRST:2,model.Period.EXTRA_SECOND:3}.get(model.period,index)
	if pending >= 0 and period == index: lost[period] += maxi(0,model.ticks-pending)
	var starts := [0.0,0.5,1.0,7.0/6]
	var lengths := [0.5,0.5,1.0/6,1.0/6]
	var minutes := [0,45,90,105]
	var end_minute: int = [45,90,105,120][period]
	var active := clampi(roundi(model.active_ticks-model.regulation_ticks*starts[period]),0,roundi(model.regulation_ticks*lengths[period]))
	var elapsed: int = active+lost[period]
	var boundary := roundi(model.regulation_ticks*lengths[period])
	var minimum := ceili(lost[period]*90.0/model.regulation_ticks)
	var added: bool = elapsed >= boundary and minimum > 0
	var minute := mini(end_minute,minutes[period]+floori(elapsed*90.0/model.regulation_ticks))
	var extra := maxi(1,floori((elapsed-boundary)*90.0/model.regulation_ticks)) if added else 0
	return {"text":"%d′%s" % [minute," +%d" % extra if added else ""],"added":added,"minimum":minimum,"lost_ticks":lost[period],"period":period,"active_ticks":active}
