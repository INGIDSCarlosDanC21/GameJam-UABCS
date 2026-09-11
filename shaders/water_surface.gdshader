shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float depth_level = 0.0;
varying vec2 water;
void vertex() {
	water = VERTEX.xz;
	VERTEX.y += sin(VERTEX.x * 0.7 + TIME * 0.65) * 0.14 + cos(VERTEX.z * 0.6 - TIME * 0.4) * 0.1;
}
void fragment() {
	vec2 p = water + vec2(sin(water.y * 1.7 + TIME * 0.4), cos(water.x * 1.1 - TIME * 0.3)) * 0.6;
	float wave = sin(p.x * 1.3 + sin(p.y * 0.9 + TIME * 0.4)) * sin(p.y * 1.7 - TIME * 0.5);
	float light = pow(1.0 - abs(wave), 12.0);
	ALBEDO = mix(vec3(0.025, 0.14, 0.20), vec3(0.20, 0.59, 0.62), light * 0.3) * exp(-depth_level * 0.45);
}
