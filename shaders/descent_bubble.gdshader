shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.5);
	ALBEDO = mix(vec3(0.15, 0.48, 0.64), vec3(0.77, 0.96, 1.0), rim);
	ALPHA = 0.045 + rim * 0.55;
}
