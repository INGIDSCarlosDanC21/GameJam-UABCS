shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float gold = 0.5;
void fragment() {
 float r = length(UV - vec2(0.5)) * 2.0;
 ALBEDO = mix(vec3(0.5,0.9,1.0), vec3(1.0,0.63,0.04), gold);
 ALPHA = smoothstep(0.15,0.6,r) * (1.0-smoothstep(0.6,1.0,r)) * 0.4;
}