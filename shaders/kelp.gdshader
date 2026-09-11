shader_type spatial;
render_mode cull_disabled;
uniform float depth_level = 0.0;
void vertex() {
	float tip = 1.0 - UV.y;
	VERTEX.x *= 0.12 + sin(UV.y * 3.14159) * 0.88;
	VERTEX.x += sin(TIME * 0.8 + MODEL_MATRIX[3].x * 2.0 + tip * 2.3) * tip * 0.2;
}
void fragment() {
	ALBEDO = mix(vec3(0.18, 0.42, 0.24), vec3(0.025, 0.095, 0.085), clamp(depth_level / 5.0, 0.0, 1.0));
	ROUGHNESS = 0.85;
}
