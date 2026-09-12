shader_type spatial;
render_mode diffuse_toon, specular_toon;
uniform sampler2D paint : source_color, hint_default_white;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float water_light = 1.0;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 c = texture(paint, UV).rgb * base_color.rgb;
	float brightness = min(c.r, min(c.g, c.b));
	float saturation = max(c.r, max(c.g, c.b)) - brightness;
	float white_mask = smoothstep(0.5, 0.9, brightness) * (1.0 - smoothstep(0.05, 0.22, saturation));
	ALBEDO = mix(c, vec3(0.27, 0.30, 0.32), white_mask);
	ROUGHNESS = 0.85;
	// Stylized light entering through the forward window; no full-screen overlay.
	vec2 p = world_position.xy * 3.2 + world_position.z * vec2(0.5, 1.1);
	float pattern = sin(p.x + sin(p.y + TIME * 0.45)) * sin(p.y - TIME * 0.55);
	float caustic = pow(1.0 - abs(pattern), 16.0);
	float window = (1.0 - smoothstep(1.4, 2.8, abs(world_position.x))) * (1.0 - smoothstep(0.5, 3.5, world_position.z));
	float facing = 0.2 + 0.8 * max(0.0, dot(normalize(world_normal), normalize(vec3(0.0, 0.6, -1.0))));
	EMISSION = vec3(0.04, 0.07, 0.075) * caustic * window * facing * water_light * 0.22;
}
