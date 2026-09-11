shader_type spatial;
#include "res://shaders/water_motion.gdshaderinc"
uniform float depth_level = 0.0;
uniform float ecosystem_light = 1.0;
varying float tone;
void vertex() {
 tone = sin(MODEL_MATRIX[3].x * 1.3) * 0.5 + 0.5;
 vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 VERTEX += (inverse(MODEL_MATRIX) * vec4(underwater_warp(world, TIME), 0.0)).xyz;
}
void fragment() {
 ALBEDO = mix(vec3(0.43, 0.22, 0.32), vec3(0.23, 0.46, 0.42), tone);
 float tip = smoothstep(0.6, 1.0, 1.0 - UV.y);
 EMISSION = ALBEDO * tip * min(depth_level * 0.06, 0.2) * ecosystem_light;
 ROUGHNESS = 0.85;
}
