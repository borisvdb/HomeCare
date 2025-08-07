shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // red outline
uniform float edge_threshold : hint_range(0.0, 2.0, 0.01) = 0.2;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Gaussian blur function (unchanged)
vec3 gaussian5x5(sampler2D tex, vec2 uv, vec2 pix_size)
{
	vec3 p = vec3(0.0);
	float coef[25] = float[](
		0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625,
		0.015625,  0.0625,    0.09375,   0.0625,   0.015625,
		0.0234375, 0.09375,   0.140625,  0.09375,  0.0234375,
		0.015625,  0.0625,    0.09375,   0.0625,   0.015625,
		0.00390625,0.015625,  0.0234375, 0.015625, 0.00390625
	);

	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			vec2 offset = vec2(float(x), float(y)) * pix_size;
			p += texture(tex, uv + offset).rgb * coef[(y+2)*5 + (x+2)];
		}
	}
	return p;
}

void fragment()
{
	vec3 pix[9];

	// Apply Gaussian filter to the 3x3 kernel
	for (int y = 0; y < 3; y++) {
		for (int x = 0; x < 3; x++) {
			vec2 offset = vec2(float(x - 1), float(y - 1)) * SCREEN_PIXEL_SIZE;
			pix[y*3 + x] = gaussian5x5(SCREEN_TEXTURE, SCREEN_UV + offset, SCREEN_PIXEL_SIZE);
		}
	}

	// Sobel Filter
	vec3 sobel_x = (
		pix[0] * -1.0 + pix[3] * -2.0 + pix[6] * -1.0 +
		pix[2] *  1.0 + pix[5] *  2.0 + pix[8] *  1.0
	);
	vec3 sobel_y = (
		pix[0] * -1.0 + pix[1] * -2.0 + pix[2] * -1.0 +
		pix[6] *  1.0 + pix[7] *  2.0 + pix[8] *  1.0
	);

	// Gradient magnitude
	vec3 sobel = sqrt(sobel_x * sobel_x + sobel_y * sobel_y);
	float edge_strength = length(sobel); // grayscale edge intensity

	// Outline condition
	if (edge_strength > edge_threshold) {
		COLOR = vec4(outline_color.rgb, outline_color.a * alpha);
	} else {
		COLOR = vec4(0.0); // transparent background
	}
}
