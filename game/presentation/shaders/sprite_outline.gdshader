shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.16, 0.12, 0.09, 1.0);
uniform float outline_width : hint_range(0.5, 4.0, 0.5) = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 pixel_step = TEXTURE_PIXEL_SIZE * outline_width;
	float neighbour_alpha = 0.0;

	// Eight-neighbour alpha dilation creates a clean contour around transparent sprites.
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			if (x == 0 && y == 0) {
				continue;
			}
			vec2 offset = vec2(float(x), float(y)) * pixel_step;
			neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + offset).a);
		}
	}

	float contour_alpha = max(neighbour_alpha - source.a, 0.0) * outline_color.a;
	vec4 contour = vec4(outline_color.rgb, contour_alpha);
	COLOR = source.a > 0.0 ? source : contour;
}
