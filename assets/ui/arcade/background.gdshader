shader_type canvas_item;
render_mode unshaded;
// Decorative stadium only. Text, cards and interactive pixel edges remain untouched.
void fragment() {
	vec2 d = TEXTURE_PIXEL_SIZE * 4.0;
	vec4 c = texture(TEXTURE,UV)*0.20;
	c += texture(TEXTURE,UV+vec2(d.x,0.0))*0.12;
	c += texture(TEXTURE,UV-vec2(d.x,0.0))*0.12;
	c += texture(TEXTURE,UV+vec2(0.0,d.y))*0.12;
	c += texture(TEXTURE,UV-vec2(0.0,d.y))*0.12;
	c += texture(TEXTURE,UV+d)*0.08;
	c += texture(TEXTURE,UV-d)*0.08;
	c += texture(TEXTURE,UV+vec2(d.x,-d.y))*0.08;
	c += texture(TEXTURE,UV+vec2(-d.x,d.y))*0.08;
	COLOR = c;
}
