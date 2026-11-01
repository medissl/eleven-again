shader_type canvas_item;
render_mode unshaded;
uniform float rush = 0.0;
void fragment() {
	vec4 modulation = COLOR;
	vec4 color = texture(TEXTURE,UV);
	if (rush > 0.001) {
		vec2 ray = (UV-vec2(0.5,0.46))*rush*0.075;
		for (int i=1; i<8; i++) color += texture(TEXTURE,clamp(UV-ray*float(i)/7.0,vec2(0.0),vec2(1.0)));
		color /= 8.0;
	}
	COLOR = color*modulation;
}
