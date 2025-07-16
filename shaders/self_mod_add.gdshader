shader_type canvas_item;

uniform vec4 mod_color: source_color; // No hint needed in Godot 4

vec3 overlay_blend(vec3 base, vec3 blend) {
    vec3 result;
    result.r = (base.r < 0.5) ? (2.0 * base.r * blend.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - blend.r));
    result.g = (base.g < 0.5) ? (2.0 * base.g * blend.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - blend.g));
    result.b = (base.b < 0.5) ? (2.0 * base.b * blend.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - blend.b));
    return result;
}

void fragment() {

    vec4 base_color = texture(TEXTURE, UV) * COLOR; // COLOR includes the theme color

    vec3 final_color;

	final_color = overlay_blend(base_color.rgb, mod_color.rgb);

    // Clamp to prevent color overflow
    COLOR = vec4(clamp(final_color, 0.0, 1.0), base_color.a);
}
