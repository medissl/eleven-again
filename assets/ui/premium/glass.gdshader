shader_type canvas_item;
render_mode unshaded;

// One explicit arena copy supplies all surfaces; text/cards never enter the blur.
uniform sampler2D arena_buffer : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 panel_rect = vec4(0.0,0.0,1.0,1.0);
uniform vec4 tint : source_color = vec4(0.06,0.12,0.18,1.0);
uniform float cut_px = 12.0;
uniform float activity = 0.0;
uniform int kind = 0;
uniform bool disabled_surface = false;

void fragment() {
	vec4 modulation = COLOR;
	vec2 p = SCREEN_UV / SCREEN_PIXEL_SIZE - panel_rect.xy;
	vec2 extent = max(panel_rect.zw,vec2(1.0));
	float cut = min(cut_px,min(extent.x,extent.y)*0.22);
	float edge = min(min(p.x,p.y),min(extent.x-p.x,extent.y-p.y));
	edge = min(edge,(extent.x-cut-p.x+p.y)*0.7071068);
	edge = min(edge,(p.x+extent.y-cut-p.y)*0.7071068);
	float coverage = smoothstep(-0.65,0.65,edge);
	float y = clamp(p.y/extent.y,0.0,1.0);
	// Filtered mipmaps blur continuously, avoiding nine repeated player silhouettes.
	vec3 blur = textureLod(arena_buffer,SCREEN_UV,3.0).rgb;
	vec3 top = tint.rgb*1.45 + vec3(0.012,0.025,0.035);
	vec3 bottom = tint.rgb*0.52;
	if (kind == 2) {
		top = vec3(0.05,0.40,0.51);
		bottom = vec3(0.015,0.13,0.24);
	}
	vec3 base = mix(blur,mix(top,bottom,y),kind == 2 ? 0.82 : 0.66);
	float gloss = pow(1.0-y,6.0)*0.055;
	float rim = 1.0-smoothstep(0.7,1.65+activity,edge);
	vec3 ice = vec3(0.39,0.88,1.0);
	vec3 border = mix(vec3(0.13,0.31,0.41),ice,0.26+0.60*pow(1.0-y,3.0));
	float glow = exp(-max(edge,0.0)*0.24)*(0.045+activity*0.055);
	base += vec3(gloss) + ice*glow;
	base = mix(base,border,rim*(0.70+activity*0.25));
	float outer = exp(min(edge,0.0)*0.55)*(0.035+activity*0.10);
	float alpha = coverage+(1.0-coverage)*outer;
	base = mix(ice,base,coverage);
	if (kind == 3 && activity < 0.01) alpha = 0.0;
	if (disabled_surface) { base *= 0.63; alpha *= 0.75; }
	COLOR = vec4(base,alpha)*modulation;
}
