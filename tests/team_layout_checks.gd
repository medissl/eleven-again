extends SceneTree
const View = preload("res://match/match_view.gd")
var captures := false

func _initialize() -> void: call_deferred("run")

func settle() -> void:
	for frame in 5: await process_frame

func run() -> void:
	captures = "--capture" in OS.get_cmdline_user_args()
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var checked := 0
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		viewport.size = dimensions
		for scale_value in [1.0]:
			for names in [["Meadow XI","Harbor XI"],["Brazil","Eclipse Athletic"],["Foundry Athletic","Stonebridge Rovers"]]:
				var view := View.new()
				view.theme = View.MatchTheme
				view.fixture_seed = 42
				view.team_names = names
				viewport.add_child(view)
				view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				view.paused = true
				view.hud.set_ui_scale(scale_value)
				view._layout()
				await settle()
				var hud: Control = view.hud
				var home: Label = hud.labels.home
				var away: Label = hud.labels.away
				var score: Label = hud.labels.score
				assert(absf(score.get_rect().get_center().x-view.pitch.get_center().x) < 1)
				assert(absf(score.position.x-home.get_rect().end.x-20) < 1)
				assert(absf(away.position.x-score.get_rect().end.x-20) < 1)
				assert(home.position.x-(hud.kit_centers[0].x+17) >= 13.9)
				assert((hud.kit_centers[1].x-17)-away.get_rect().end.x >= 13.9)
				assert(home.get_theme_font_size("font_size") == away.get_theme_font_size("font_size"))
				assert(hud.kit_centers[0].x-17 >= view.pitch.position.x and hud.kit_centers[1].x+17 <= view.pitch.end.x)
				for label in [home,away]: assert(label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x <= label.size.x)
				await picture(viewport,names,"gameplay",scale_value)
				view.sim.halftime_report = view.sim.snapshot_report()
				view.sim.result_report = view.sim.snapshot_report()
				for mode in ["menu","halftime","details","result"]:
					view.hud.show_panel(mode,view.sim)
					await settle()
					var overlay: Control = view.hud.overlay
					var middle := overlay.find_child("TeamScore",true,false) as Label
					var left := overlay.find_child("TeamNameHome",true,false) as Label
					var right := overlay.find_child("TeamKitAway",true,false) as Control
					assert(absf(middle.get_global_rect().position.x-left.get_global_rect().end.x-20*scale_value) < 1.1,"Home identity must hug the score with the same gap")
					assert(absf(right.get_global_rect().position.x-middle.get_global_rect().end.x-20*scale_value) < 1.1,"Away identity must hug the score with the same gap")
					var other := overlay.find_child("TeamNameAway",true,false) as Label
					assert(left.get_theme_font_size("font_size") == other.get_theme_font_size("font_size"))
					assert(not left.text.contains("…") and not other.text.contains("…"))
					for label in [left,other]:
						if label.autowrap_mode == TextServer.AUTOWRAP_OFF: assert(label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x <= label.size.x)
					await picture(viewport,names,mode,scale_value)
					checked += 1
				view.queue_free()
				await process_frame
	viewport.queue_free()
	print("TEAM LAYOUT: ",checked," native gameplay/pause/halftime/details/full-time identity cases passed at both resolutions and fixed 100%")
	quit()

func picture(viewport: SubViewport, names: Array, mode: String, scale_value: float) -> void:
	if not captures or names[0] != "Meadow XI": return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://reports/screenshots/team-%s-%d-%dx%d.png" % [mode,roundi(scale_value*100),viewport.size.x,viewport.size.y]) == OK)
