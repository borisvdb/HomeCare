shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_always, cull_back;

uniform sampler2D matcap : source_color, hint_default_black, filter_linear; // Sampler 2d of the matcap
uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D albedo: source_color, hint_default_white, filter_linear;
uniform bool use_vertex_colors = false;
uniform sampler2D emission: source_color, hint_default_black, filter_linear;
uniform float emission_amount : hint_range(0,1) = 0.0;
uniform sampler2D normal_map: source_color, hint_default_transparent, filter_linear;
uniform float normal_amount : hint_range(-0.5, 0.5) = 0.0;
uniform float uv_blend_sharpness : hint_range(0.0, 150.0, 0.001) = 50.0;
uniform vec3 uv_offset = vec3(0.0, 0.0, 0.0);
uniform float uv_scale = 1.0;
uniform bool uv_global = true;

// Bread and butter: Generates the MatCap's UV's
vec2 generate_matcap_uv(vec3 _normal, vec3 _node_position_view) {
	vec3 cross_space = cross(normalize(_node_position_view), _normal); // cross products the normal with it's base position
	vec2 mat_space = vec2(cross_space.y * 1.0, cross_space.x); // converts to a Vec2 UV, having to switch x and y
	mat_space *= vec2(-0.5, -0.5); // modifies the mat space's size to fit into uv coords, & flips it
	mat_space += vec2(0.5, 0.5); // transforms the mat space into uv coords
	return mat_space; // export the final uv's
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    vec4 samp = vec4(0.0);
    samp += texture(p_sampler, vec2(p_triplanar_pos.x, -p_triplanar_pos.y)) * p_weights.z; // Z projection (flip Y)
    samp += texture(p_sampler, vec2(p_triplanar_pos.x, -p_triplanar_pos.z)) * p_weights.y; // Y projection (flip Z)
    samp += texture(p_sampler, vec2(p_triplanar_pos.z, -p_triplanar_pos.y)) * p_weights.x; // X projection (flip Y)
    return samp;
}

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

void vertex() {
    vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;

    uv1_power_normal = pow(abs(normal), vec3(uv_blend_sharpness));
    uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));

    if (uv_global) {
        uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv_scale + uv_offset;
    } else {
        uv1_triplanar_pos = VERTEX * uv_scale + uv_offset;
    }
}

void fragment(){
	vec2 matcap_uv = (generate_matcap_uv(NORMAL, NODE_POSITION_VIEW)); // Matcap UV's

    vec3 _matcap = texture(matcap, matcap_uv + ((triplanar_texture(normal_map, uv1_power_normal, uv1_triplanar_pos).xy - 0.5) * normal_amount)).rgb;

	vec4 albedo_tex = triplanar_texture(albedo, uv1_power_normal, uv1_triplanar_pos);

	ALBEDO = albedo_tex.rgb;
	ALPHA = 1.0;

	if (use_vertex_colors && (COLOR.r < 0.99 || COLOR.g < 0.99 || COLOR.b < 0.99)){
		ALBEDO *= COLOR.rgb;
	}
	else{
		ALBEDO *= color.rgb;
	}

    ALBEDO *= _matcap; // Sets the albedo to the matcap texture.

    vec4 emission_col = texture(emission, matcap_uv);
    ALBEDO += emission_col.rgb * emission_amount;
}
