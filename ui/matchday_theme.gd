extends RefCounted
const BASE := "res://assets/ui/matchday/"
const COLOURS := {"forest":"101827","surface":"17253B","raised":"233A50","ivory":"FFF4D2","muted":"A8C8BF","amber":"F5CE65","brass":"F5CE65","paper":"17253B","ink":"FFF4D2","divider":"31596A","border":"446C7A","coral":"D45A5A","success":"55AA5B"}

static func frame(ink: Color = Color("FFF4D2")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = ink
	style.set_border_width_all(2)
	style.anti_aliasing = false
	return style

static func box(id: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=Color(COLOURS.raised) if "raised" in id or "hover" in id else Color(COLOURS.surface)
	if id == "focus": style.bg_color=Color(0,0,0,0)
	style.border_color=Color(COLOURS.ivory) if "primary" in id or id == "focus" else Color(COLOURS.divider)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	for side in 4:
		style.set_content_margin(side,16 if side in [SIDE_LEFT,SIDE_RIGHT] else 8)
	return style

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = preload("res://ui/typography.gd").face()
	theme.default_font_size = 18
	var strong: Font = preload("res://ui/typography.gd").face("Bold")
	for role in ["Heading","Team","Score","Section","BodyStrong","Goal"]:
		theme.set_type_variation(role,"Label")
		theme.set_font("font",role,strong)
		theme.set_font_size("font_size",role,{"Heading":34,"Team":26,"Score":48,"Section":24,"BodyStrong":18,"Goal":94}[role])
	for key in COLOURS: theme.set_color(key,"Palette",Color(COLOURS[key]))
	for role in ["Label","Button","LineEdit","OptionButton","CheckButton","TooltipLabel"]: theme.set_color("font_color",role,Color(COLOURS.ivory))
	for role in ["Button","OptionButton","CheckButton"]:
		theme.set_font("font",role,strong)
		theme.set_font_size("font_size",role,18)
		for state in ["normal","hover","pressed","disabled","focus"]:
			theme.set_stylebox(state,role,box({"normal":"button-secondary","hover":"button-secondary-hover","pressed":"tab-active","disabled":"button-disabled","focus":"focus"}[state]))
		for state in ["hover","pressed","focus","disabled"]: theme.set_color("font_"+state+"_color",role,Color(COLOURS.muted if state == "disabled" else COLOURS.ivory))
	theme.set_type_variation("Primary","Button")
	theme.set_type_variation("Quiet","Button")
	var quiet := StyleBoxEmpty.new()
	for side in 4: quiet.set_content_margin(side,16 if side in [SIDE_LEFT,SIDE_RIGHT] else 8)
	theme.set_stylebox("normal","Quiet",quiet)
	for state in ["normal","hover","pressed"]: theme.set_stylebox(state,"Primary",box("button-primary"+("" if state == "normal" else "-"+state)))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: theme.set_color(state,"Primary",Color(COLOURS.ink))
	for state in ["normal","focus","read_only"]: theme.set_stylebox(state,"LineEdit",box("focus" if state == "focus" else "input"))
	theme.set_color("font_placeholder_color","LineEdit",Color(COLOURS.muted))
	for role in ["HSeparator","VSeparator"]:
		var line := StyleBoxLine.new()
		line.color = Color(COLOURS.divider)
		line.thickness = 2
		line.vertical = role == "VSeparator"
		theme.set_stylebox("separator",role,line)
	theme.set_stylebox("panel","PanelContainer",StyleBoxEmpty.new())
	for id in ["slider","grabber_area","grabber_area_highlight"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Color(COLOURS.border if id == "slider" else COLOURS.brass)
		track.content_margin_top = 2
		track.content_margin_bottom = 2
		theme.set_stylebox(id,"HSlider",track)
	for id in ["grabber","grabber_highlight","grabber_disabled"]:
		theme.set_icon(id,"HSlider",preload("res://ui/pixel_art.gd").texture(BASE+"components/slider-thumb.svg",Vector2i(16,16)))
	theme.set_stylebox("focus","HSlider",box("focus"))
	theme.set_stylebox("panel","TooltipPanel",box("panel"))
	preload("res://ui/typography.gd").apply(theme)
	for role in ["Button","Primary","Quiet","Tab","OptionButton","CheckButton"]:
		if role in ["Primary","Quiet","Tab"]: theme.set_type_variation(role,"Button")
		for state in ["normal","hover","pressed","disabled","focus"]:
			var skin := StyleBoxFlat.new()
			skin.bg_color = Color(0,0,0,0)
			skin.content_margin_left = 16
			skin.content_margin_right = 16
			skin.content_margin_top = 8
			skin.content_margin_bottom = 8
			theme.set_stylebox(state,role,skin)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: theme.set_color(state,role,Color("101827") if role == "Primary" else Color(COLOURS.ivory))
		for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]: theme.set_color(state,role,Color("101827") if role == "Primary" else Color(COLOURS.ivory))
	return theme
