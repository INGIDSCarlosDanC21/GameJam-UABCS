shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D ocean_screen : hint_screen_texture, filter_linear;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	ALBEDO = mix(vec3(0.12, 0.3, 0.36), vec3(0.42, 0.75, 0.88), rim);
	ROUGHNESS = 0.09;
	SPECULAR = 0.85;
	METALLIC = 0.15;
	vec2 wave = vec2(sin(SCREEN_UV.y*31.0+TIME*.75),cos(SCREEN_UV.x*25.0-TIME*.6))*0.003;
	vec2 uv = clamp(SCREEN_UV+wave,vec2(.002),vec2(.998));
	ALPHA = .65;
	ALBEDO = vec3(0.0);
	EMISSION = texture(ocean_screen,uv).rgb + vec3(0.05, 0.13, 0.18) * rim;
}
