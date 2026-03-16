shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const float vertical_stretch = 0.707106781187;

void fragment() {
	vec2 uv = SCREEN_UV;
    uv.y = (uv.y - 0.5) * vertical_stretch + 0.5;
    COLOR = textureLod(screen_texture, uv, 0.0);
}
