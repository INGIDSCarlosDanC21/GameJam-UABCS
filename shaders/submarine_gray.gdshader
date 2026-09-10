shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform sampler2D paint : source_color, hint_default_white;
uniform vec4 base_color : source_color = vec4(1.0);
void fragment() {
	vec3 c = texture(paint, UV).rgb * base_color.rgb;
	float brightness = min(c.r, min(c.g, c.b));
	float saturation = max(c.r, max(c.g, c.b)) - brightness;
	float white_mask = smoothstep(0.5, 0.9, brightness) * (1.0 - smoothstep(0.05, 0.22, saturation));
	ALBEDO = mix(c, vec3(0.27, 0.30, 0.32), white_mask);
	ROUGHNESS = 0.85;
}