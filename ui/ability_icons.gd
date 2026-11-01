extends RefCounted
## Original semantic white glyphs, keyed to the authoritative 36 trait IDs.
const PATHS := {
	"deflector":'<path d="M6 7v10l8 8 8-8V7M14 25v4M24 12h5m-3-3 3 3-3 3"/><circle cx="14" cy="10" r="3"/>',
	"safe_hands":'<path d="M5 8v9l6 9h10l6-9V8M9 8v9l5 4h4l5-4V8"/><circle cx="16" cy="10" r="4"/>',
	"cat_reflexes":'<path d="m18 3-9 14h7l-2 12 10-16h-8z"/>',
	"sweeper_keeper":'<path d="M5 27V7h18v8M11 27V13h12M17 27l10-10m-6 0h6v6"/><circle cx="24" cy="26" r="2"/>',
	"long_throw":'<path d="M5 25V13m-2 4 2-4 4 2M9 23Q11 4 27 7m-5-4 5 4-4 4"/><circle cx="26" cy="20" r="3"/>',
	"hard_tackle":'<path d="m4 9 4 10 15 7h5v-6l-12-5-4-8M6 26h10M20 7l3-3m2 8h4"/>',
	"anticipator":'<path d="M3 16Q16 2 29 16 16 30 3 16Z"/><circle cx="16" cy="16" r="4"/><path d="m23 5 4-2m-1 5 4 1"/>',
	"aerial_fortress":'<path d="m6 6 10-3 10 3v12l-10 11L6 18ZM10 16h12M11 16v-6m5 6V8m5 8v-6"/>',
	"body_block":'<path d="M7 6h18v13l-9 10-9-10Z M9 18h14m-7-9v14"/>',
	"accelerator":'<path d="m8 25 9-9-9-9m9 18 9-9-9-9M3 11h3m-3 5h3m-3 5h3"/>',
	"whipped_cross":'<path d="M5 27V8m0 0h20M9 24Q28 23 25 7m-4 4 4-4 4 4"/><circle cx="9" cy="24" r="2"/>',
	"recovery_sprint":'<path d="M25 11A11 11 0 1 0 26 23M25 4v7h-7m-6 13 8-9h-6l4-7"/>',
	"overlap_engine":'<path d="M7 27V12q0-6 6-6h12m-5-4 5 4-5 4M16 27V17q0-3 3-3h6m-4-4 4 4-4 4"/>',
	"screen":'<path d="M5 10h22M5 22h22M10 6v20m6-20v20m6-20v20M2 16h28"/>',
	"anchor":'<circle cx="16" cy="6" r="3"/><path d="M16 9v19M10 14h12M4 21q12 15 24 0M4 16v5h5m14 0h5v-5"/>',
	"switch_play":'<path d="M4 9h24m-5-5 5 5-5 5M28 23H4m5-5-5 5 5 5"/>',
	"bullet_pass":'<path d="M3 11h12M3 16h16M3 21h12m7-13 8 8-8 8"/>',
	"wall_pass":'<path d="M27 3v26M4 25l14-9L4 7m9 0H4v9"/><circle cx="5" cy="25" r="2"/>',
	"tempo_setter":'<circle cx="16" cy="17" r="11"/><path d="M16 6V2m-4 0h8m-4 15 5-6M9 17h2m10 0h2m-7 7v2"/>',
	"press_resistant":'<path d="M3 8h7l4 8-4 8H3m26-16h-7l-4 8 4 8h7"/><circle cx="16" cy="16" r="3"/>',
	"threader":'<path d="M4 25 25 4m-8 0h8v8M4 12h7v7m10-6v7h7"/>',
	"third_man":'<circle cx="6" cy="24" r="3"/><circle cx="26" cy="24" r="3"/><circle cx="16" cy="6" r="3"/><path d="m8 20 6-10m4 0 6 10M10 24h12"/>',
	"turn_and_go":'<path d="M7 27V14a8 8 0 0 1 16 0v11m-5-5 5 5 5-5M2 27h8"/>',
	"touchline_burst":'<path d="M4 3v26M11 25 23 7m-8 0h8v8M9 12h3m-3 5h3m-3 5h3"/>',
	"cutback":'<path d="M26 4v17H7m5-5-5 5 5 5M22 4h8"/>',
	"cut_inside":'<path d="M27 4v13H10m6-6-6 6 6 6M4 4v24"/>',
	"close_control":'<circle cx="16" cy="16" r="5"/><path d="M8 4H4v8m20-8h4v8M4 24v4h8m12 0h4v-8"/>',
	"finesse_shot":'<path d="M4 27Q5 6 27 5m-5-2 5 2-2 6M15 27q9-2 12-11"/><circle cx="5" cy="25" r="2"/>',
	"first_time_finish":'<circle cx="23" cy="11" r="6"/><path d="m4 22 10-6m-5-2 5 2-2 5M5 27h21M23 8v6"/>',
	"power_strike":'<path d="m18 3-8 13h6l-2 9 11-14h-7ZM2 14h5m-4 6h6m-4 6h6"/>',
	"poacher":'<circle cx="16" cy="16" r="9"/><circle cx="16" cy="16" r="3"/><path d="M16 2v5m0 18v5M2 16h5m18 0h5"/>',
	"aerial_finisher":'<circle cx="17" cy="7" r="4"/><path d="M17 12v7L7 27m10-8 10 7M8 18l9-4 7 2M3 10h6m-4-5h6"/>',
	"dead_ball_artist":'<circle cx="7" cy="25" r="3"/><path d="M5 19Q9 4 27 8m-4-5 4 5-5 4M18 27h11V16"/>',
	"penalty_composure":'<path d="M4 16V5h24v11M9 16V9h14v7M13 20l3 3 7-8"/><circle cx="16" cy="28" r="2"/>',
	"long_throw_specialist":'<path d="M6 28V8h20M10 24Q12 7 26 12m-4-5 4 5-5 3M2 17h5m-5 5h5"/><circle cx="26" cy="24" r="3"/>',
	"super_sub":'<path d="M3 9h23m-5-5 5 5-5 5M29 23H6m5-5-5 5 5 5M13 16h6m-3-3v6"/>'
}
static var textures := {}

static func texture(trait_id: String) -> Texture2D:
	if not PATHS.has(trait_id): return null
	if not textures.has(trait_id):
		var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><g fill="none" stroke="#FFF4D2" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'+str(PATHS[trait_id])+'</g></svg>'
		var pixels := Image.new()
		assert(pixels.load_svg_from_string(svg,1.0) == OK)
		pixels.resize(24,24,Image.INTERPOLATE_NEAREST)
		for y in 24:
			for x in 24:
				var c := pixels.get_pixel(x,y)
				pixels.set_pixel(x,y,Color(Color("FFF4D2"),1.0 if c.a >= 0.4 else 0.0))
		textures[trait_id] = ImageTexture.create_from_image(pixels)
	return textures[trait_id]
