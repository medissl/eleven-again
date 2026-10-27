extends SceneTree

const Match = preload("res://match/match_sim.gd")

func _initialize() -> void:
	var total_shots := 0
	var total_goals := 0
	var scoreless := 0
	var total_passes := 0
	var failures := 0
	for index in 20:
		var seed_value: int = [11027, 42, 7, 2026][index] if index < 4 else 11024 + index
		var sim := Match.new(seed_value)
		while not sim.finished and sim.ticks < sim.regulation_ticks + 3600:
			sim.step()
		var goals: int = sim.scores[0] + sim.scores[1]
		var shots: int = sim.shots[0] + sim.shots[1]
		total_goals += goals
		total_shots += shots
		total_passes += sim.completed_passes[0] + sim.completed_passes[1]
		if goals == 0: scoreless += 1
		if not sim.finished: failures += 1
		print("SEED ", seed_value, " score=", sim.scores, " shots=", sim.shots, " passes=", sim.completed_passes)
		if index == 0 and "--trace" in OS.get_cmdline_user_args():
			for event in sim.events:
				if event.kind in ["shot", "block", "save", "goal", "miss"]:
					print("  CHANCE ", event)
	print("SAMPLE fixtures=20 goals_mean=", total_goals / 20.0, " shots_mean=", total_shots / 20.0, " passes_mean=", total_passes / 20.0, " scoreless=", scoreless)
	if total_shots < 80 or total_goals < 10 or scoreless > 10:
		push_error("Watchability regression: too few chances or too many scoreless fixtures")
		failures += 1
	quit(0 if failures == 0 else 1)
