shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform int pixel_size : hint_range(1, 64) = 1;
//uniform vec2 screen_size = vec2(1920.0, 1080.0);

#define INT2VEC(hex) vec3( \
		float((hex) >> 16) / 255.0, \
		float(((hex) >> 8) & 0xff) / 255.0, \
		float((hex) & 0xff) / 255.0 \
	)

const float SCALE = 0.5;

const vec3 DARK_RGB = INT2VEC(0x1e1c32);
const vec3 LITE_RGB = INT2VEC(0xc6baac);

const float BAYER4[] = {
	 1.0/17.0,  9.0/17.0,  3.0/17.0, 11.0/17.0,
	13.0/17.0,  5.0/17.0, 15.0/17.0,  7.0/17.0,
	 4.0/17.0, 12.0/17.0,  2.0/17.0, 10.0/17.0,
	16.0/17.0,  8.0/17.0, 14.0/17.0,  6.0/17.0
};

uint bayer_index(vec2 xy, uint dim) {
	return uint(xy.x) % dim + (uint(xy.y) % dim) * dim;
}

float luminance(vec3 rgb) {
	return dot(rgb, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 screen_size = vec2(1.0) / SCREEN_PIXEL_SIZE;
	vec2 screen_xy = floor(SCREEN_UV * screen_size / float(pixel_size));
	vec2 screen_uv = (screen_xy * float(pixel_size)) / screen_size;

	COLOR = textureLod(screen_texture, screen_uv, 0.0);
	float brightness = luminance(COLOR.rgb);
	float threshold = BAYER4[bayer_index(screen_xy, 4)];
	//COLOR.r = COLOR.g = COLOR.b = brightness;
	//COLOR.r = COLOR.g = COLOR.b = threshold;
	COLOR.rgb = brightness <= threshold ? DARK_RGB : LITE_RGB;
}
