shader_type canvas_item;
// Palette swap: every pixel close to from_colors[i] is drawn as to_colors[i] instead.
// Mario's PlayerAnimatedSprite sets these for each power-up (Inspector > Palette Swap).

const int MAX_COLORS = 8;
uniform int color_count = 0;
uniform vec4 from_colors[MAX_COLORS];
uniform vec4 to_colors[MAX_COLORS];
uniform float tolerance = 0.06;

varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;   // modulate / self_modulate (star flashing, fading) still work
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 rgb = tex.rgb;
	for (int i = 0; i < MAX_COLORS; i++) {
		if (i >= color_count) { break; }
		if (distance(tex.rgb, from_colors[i].rgb) <= tolerance) {
			rgb = to_colors[i].rgb;
			break;
		}
	}
	COLOR = vec4(rgb, tex.a) * modulate_color;
}
