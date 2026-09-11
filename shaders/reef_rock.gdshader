shader_type spatial;
uniform float depth_level = 0.0;
uniform float ecosystem_light = 1.0;
varying vec3 world;
void vertex() {
 VERTEX *= 1.0 + sin(VERTEX.x * 17.0 + VERTEX.y * 13.0) * 0.12;
 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
 float strata = sin(world.y * 18.0 + sin(world.x * 2.0)) * 0.5 + 0.5;
 float moss = smoothstep(0.1, 0.9, sin(world.x * 1.7) * cos(world.z * 2.1));
 ALBEDO = mix(mix(vec3(0.16, 0.23, 0.25), vec3(0.33, 0.40, 0.37), strata), vec3(0.12, 0.32, 0.24), moss);
 float caustic = pow(1.0 - abs(sin(world.x * 2.7 + TIME * 0.4) * sin(world.z * 3.1 - TIME * 0.3)), 20.0);
 EMISSION = vec3(0.08, 0.20, 0.18) * caustic * exp(-depth_level * 0.5) * ecosystem_light;
 ROUGHNESS = 0.94;
}
