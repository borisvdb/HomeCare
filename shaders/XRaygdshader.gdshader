shader_type spatial;
render_mode unshaded, blend_mix, cull_back;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	ALBEDO = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	ALPHA = 0.8;
}