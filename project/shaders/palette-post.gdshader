shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

#define PALETTE_X(X) \
	X(0xff8274) \
	X(0xd53c6a) \
	X(0x7c183c) \
	X(0x460e2b) \
	X(0x31051e) \
	X(0x1f0510) \
	X(0x130208) \


#define X_COUNT(x) + 1

#define X_VEC(hex) vec3( \
		float((hex) >> 16) / 255.0, \
		float(((hex) >> 8) & 0xff) / 255.0, \
		float((hex) & 0xff) / 255.0 \
	),

const vec3 palette[] = {
	PALETTE_X(X_VEC)
	vec3(0,0,0)
};
const int palette_size = PALETTE_X(X_COUNT);

vec3 get_closest_palette(vec3 color) {
	vec3 closest_color = color;
	float closest_dist = 9999.0;
	for (int i = 0; i < palette_size; ++i) {
		float d = distance(color, palette[i]);
		if (d < closest_dist) {
			closest_dist = d;
			closest_color = palette[i];
		}
	}
	return closest_color;
}

void fragment() {
	COLOR = textureLod(screen_texture, SCREEN_UV, 0.0);
	COLOR.rgb = get_closest_palette(COLOR.rgb);
}
