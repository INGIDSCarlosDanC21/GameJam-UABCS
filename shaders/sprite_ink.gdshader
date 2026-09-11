shader_type spatial;
render_mode diffuse_toon, cull_disabled;
#include "res://shaders/water_motion.gdshaderinc"
uniform sampler2D art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 texel;
uniform float fade = 1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec4 glow_color : source_color = vec4(0.0);
uniform vec4 art_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float swim_time = 0.0;
uniform float bend_strength = 0.0;
void vertex() {
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX += (inverse(MODEL_MATRIX) * vec4(underwater_warp(world, TIME), 0.0)).xyz;
}
vec2 bent_uv(vec2 uv) {
    vec2 local = (uv - art_rect.xy) / art_rect.zw;
    float tail = 1.0 - smoothstep(0.0, 0.8, local.x);
    uv.y += sin(local.x * 7.0 - swim_time) * bend_strength * (0.2 + tail * 0.8) * art_rect.w;
    return uv;
}
void fragment() {
    vec2 uv = bent_uv(UV);
    vec4 c = texture(art, uv);
    float edge = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            edge = max(edge, texture(art, uv + vec2(float(x), float(y)) * texel * 3.0).a);
        }
    }
    ALBEDO = mix(vec3(0.006), c.rgb * tint, smoothstep(0.05, 0.8, c.a));
    EMISSION = glow_color.rgb * glow_color.a * c.rgb * c.a;
    ALPHA = max(c.a, edge) * fade;
    ALPHA_SCISSOR_THRESHOLD = 0.15;
}
