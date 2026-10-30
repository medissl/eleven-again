extends RefCounted
## One licensed family, real tabular figures and deliberately limited weights.
static var faces := {}
static func face(weight: String = "Medium", italic: bool = false) -> FontVariation:
	var key := weight+str(italic)
	if not faces.has(key):
		var file: FontFile = load("res://assets/ui/premium/fonts/Saira-"+("Italic" if italic else "Upright")+".res")
		file.fallbacks = [load("res://assets/ui/matchday/fonts/SourceSans3-Regular.ttf")]
		var font := FontVariation.new()
		font.base_font = file
		var server := TextServerManager.get_primary_interface()
		font.variation_opentype = {server.name_to_tag("wght"):float({"Medium":500,"SemiBold":600,"Bold":800}[weight]),server.name_to_tag("wdth"):90.0}
		font.opentype_features = {server.name_to_tag("tnum"):1,server.name_to_tag("pnum"):0}
		faces[key] = font
	return faces[key]

static func apply(theme: Theme) -> void:
	theme.default_font = face()
	for role in ["Heading","Team","Score","Section","BodyStrong","Goal"]:
		theme.set_font("font",role,face("SemiBold" if role in ["BodyStrong","Section"] else "Bold",role in ["Heading","Goal"]))
	for role in ["Button","Primary","Quiet","Tab","OptionButton","CheckButton"]: theme.set_font("font",role,face("SemiBold"))
	for role in ["Label","TooltipLabel","LineEdit"]: theme.set_font("font",role,face())
	theme.set_font("normal_font","RichTextLabel",face())
