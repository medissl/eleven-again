extends "res://match/match_view.gd"
## Design skin only: native field, goals, actors, HUD structure and kit drawing remain intact.
const DesignParts = preload("res://outputs/fc-mobile-ui-v6/components.gd")

func _ready() -> void:
	super._ready()
	theme = DesignParts.make_theme()
	font = theme.get_font("font","BodyStrong")
	hud.theme = theme
	hud.AMBER = DesignParts.ACCENT
	for button in hud.buttons.values():
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style: StyleBox = theme.get_stylebox(state,"Button").duplicate()
			if button == hud.buttons.menu:
				style.content_margin_left = 34
				style.content_margin_right = 4
			button.add_theme_stylebox_override(state,style)
		DesignParts.skin_button(button)
	_layout()

func _draw() -> void:
	super._draw()
	# This is parent drawing: the native HUD child still renders shirts/labels above it.
	draw_rect(Rect2(0,0,size.x,77),DesignParts.BG)
	draw_rect(Rect2(size.x-270,78,270,size.y-78),DesignParts.BG)
