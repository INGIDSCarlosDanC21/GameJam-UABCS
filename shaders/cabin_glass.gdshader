shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	ALBEDO = mix(vec3(0.12, 0.3, 0.36), vec3(0.42, 0.75, 0.88), rim);
	ROUGHNESS = 0.09;
	SPECULAR = 0.85;
	METALLIC = 0.15;
	ALPHA = 0.025 + rim * 0.3;
	EMISSION = vec3(0.05, 0.13, 0.18) * rim;
}
