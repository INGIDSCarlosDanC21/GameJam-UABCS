shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 texel;
uniform vec4 glow_color : source_color = vec4(0.0);
void fragment() {
    vec4 c = texture(art, UV);
    float edge = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            edge = max(edge, texture(art, UV + vec2(float(x), float(y)) * texel * 3.0).a);
        }
    }
    ALBEDO = mix(vec3(0.006), c.rgb, smoothstep(0.05, 0.8, c.a));
    EMISSION = glow_color.rgb * glow_color.a * c.rgb * c.a;
    ALPHA = max(c.a, edge);
    ALPHA_SCISSOR_THRESHOLD = 0.15;
}
