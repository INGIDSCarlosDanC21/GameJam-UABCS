shader_type spatial;
render_mode cull_disabled, vertex_lighting;
#include "res://shaders/water_motion.gdshaderinc"
uniform float depth_level = 0.0;
uniform float ecosystem_light = 1.0;
varying vec3 world;
void vertex() {
 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 VERTEX += (inverse(MODEL_MATRIX) * vec4(underwater_warp(world, TIME) * 1.8, 0.0)).xyz;
}
void fragment() {
	vec2 p = world.xz;
	float sand = sin(p.x * 28.0 + sin(p.y * 3.0)) * 0.025;
	float a = sin(p.x * 2.7 + sin(p.y * 2.1 + TIME * 0.6));
	float b = sin(p.y * 3.3 + sin(p.x * 1.7 - TIME * 0.5));
	float caustic = pow(1.0 - abs(a * b), 18.0) * exp(-depth_level * 0.32);
	ALBEDO = mix(vec3(0.22, 0.36, 0.32), vec3(0.035, 0.09, 0.12), smoothstep(5.0,25.0,depth_level)) + sand;
	EMISSION = vec3(0.13, 0.35, 0.29) * caustic * 1.3 * ecosystem_light;
	ROUGHNESS = 0.95;
}
