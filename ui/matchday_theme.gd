extends RefCounted
const BASE := "res://assets/ui/matchday/"
const COLOURS := {"forest":"111A16","surface":"1B2921","raised":"26392C","ivory":"F1ECDD","muted":"A5B09F","amber":"D4BD6A","brass":"D4BD6A","paper":"DDD5BE","ink":"172219","divider":"3B493B","border":"7B8976","coral":"D67B68","success":"8FB7A0"}

static func box(id: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(BASE+"components/"+id+".svg")
	for side in 4:
		style.set_texture_margin(side,8)
		style.set_content_margin(side,16 if side in [SIDE_LEFT,SIDE_RIGHT] else 8)
	return style

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = load(BASE+"fonts/SourceSans3-Regular.ttf")
	theme.default_font_size = 18
	var strong: Font = load(BASE+"fonts/SourceSans3-Semibold.ttf")
	for role in ["Heading","Team","Score","Section","BodyStrong","Goal"]:
		theme.set_type_variation(role,"Label")
		var file := "BarlowSemiCondensed-Bold.ttf" if role in ["Heading","Score"] else "BarlowSemiCondensed-SemiBold.ttf"
		if role == "BodyStrong": file = "SourceSans3-Semibold.ttf"
		if role == "Goal": file = "BarlowCondensed-BoldItalic.ttf"
		theme.set_font("font",role,load(BASE+"fonts/"+file))
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
		line.thickness = 1
		line.vertical = role == "VSeparator"
		theme.set_stylebox("separator",role,line)
	theme.set_stylebox("panel","PanelContainer",StyleBoxEmpty.new())
	theme.set_stylebox("panel","TooltipPanel",box("panel"))
	return theme
