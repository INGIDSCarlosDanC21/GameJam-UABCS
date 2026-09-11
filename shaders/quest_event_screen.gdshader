shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, fog_disabled;
uniform float fever = 0.0;
uniform float stun = 0.0;
void fragment() {
	// No screen texture: safe for stereo multiview on standalone headsets.
	float edge = smoothstep(0.18, 0.68, length(UV - vec2(0.5)));
	ALBEDO = mix(vec3(1.0, 0.62, 0.06), vec3(0.04, 0.07, 0.1), stun);
	ALPHA = clamp(fever * edge * 0.45 + stun * (0.12 + edge * 0.35), 0.0, 0.6);
}
