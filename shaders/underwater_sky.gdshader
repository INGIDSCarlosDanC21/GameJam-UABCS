shader_type sky;
// Continuous water column: no finite plane edge or bright tiled ceiling.
void sky() {
	float upward = smoothstep(-0.28, 0.85, EYEDIR.y);
	vec3 deep = vec3(0.012, 0.065, 0.10);
	vec3 shallows = vec3(0.055, 0.29, 0.34);
	vec3 water = mix(deep, shallows, upward);
	vec3 sun_dir = normalize(vec3(-0.35, 0.92, -0.6));
	float sun = pow(max(dot(EYEDIR, sun_dir), 0.0), 28.0);
	float ripples = sin(EYEDIR.x * 32.0 + sin(EYEDIR.z * 23.0)) * 0.5 + 0.5;
	COLOR = water + vec3(0.10, 0.20, 0.17) * sun * (0.8 + ripples * 0.2);
}
