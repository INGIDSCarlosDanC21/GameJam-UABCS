shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
uniform sampler2D color_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway = 0.15;
uniform float tint_strength = 0.0;
uniform float depth_level = 0.0;
uniform float ecosystem_light = 1.0;
uniform float world_height = 0.0;
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float tip = clamp((world.y - INSTANCE_CUSTOM.y - world_height) / max(INSTANCE_CUSTOM.z, 0.01), 0.0, 1.0);
	vec3 offset = vec3(sin(TIME * 0.65 + INSTANCE_CUSTOM.x + tip * 1.4), 0.0, cos(TIME * 0.48 + INSTANCE_CUSTOM.x)) * sway * tip * tip;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
}
void fragment() {
	vec3 texture_color = texture(color_texture, UV).rgb;
	vec3 pigment = mix(texture_color * COLOR.rgb, COLOR.rgb * (0.6 + texture_color.r * 0.4), tint_strength);
	float depth_light = exp(-depth_level * 0.25);
	ALBEDO = pigment;
	float caustic = pow(1.0 - abs(sin(world.x * 2.4 + TIME * 0.45) * sin(world.z * 2.9 - TIME * 0.35)), 16.0);
	EMISSION = pigment * (0.16 + caustic * 0.16) * ecosystem_light * depth_light;
	ROUGHNESS = 0.9;
}
