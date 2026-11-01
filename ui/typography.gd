extends RefCounted
## One CC0 pixel family. Mono numerals keep clocks and ratings steady.
static var faces := {}
static func face(weight: String = "Medium", _italic: bool = false) -> FontVariation:
	var key := "Mono-Bold" if weight == "Score" else "Bold" if weight in ["Bold","SemiBold"] else "Regular"
	if not faces.has(key):
		var file: FontFile = load("res://assets/ui/arcade/fonts/PixelOperator"+("" if key == "Regular" else "Mono-Bold" if key == "Mono-Bold" else "-Bold")+".ttf")
		file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		var symbols: FontFile=load("res://assets/ui/matchday/fonts/SourceSans3-Regular.ttf")
		symbols.antialiasing=TextServer.FONT_ANTIALIASING_NONE
		symbols.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
		file.fallbacks=[symbols] # Only missing prime/arrow symbols; all ordinary text remains Pixel Operator.
		var font := FontVariation.new()
		font.base_font = file
		font.variation_opentype = {}
		faces[key] = font
	return faces[key]

static func apply(theme: Theme) -> void:
	theme.default_font = face()
	for role in ["Heading","Team","Section","BodyStrong","Goal"]: theme.set_font("font",role,face("Bold"))
	theme.set_font("font","Score",face("Score"))
	for role in ["Button","Primary","Quiet","Tab","OptionButton","CheckButton"]: theme.set_font("font",role,face("SemiBold"))
	for role in ["Label","TooltipLabel","LineEdit"]: theme.set_font("font",role,face())
	theme.set_font("normal_font","RichTextLabel",face())
