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
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.0;
uniform int pattern_style = 0;
uniform float pattern_seed = 0.0;
uniform vec3 pattern_color : source_color = vec3(0.2, 0.8, 0.85);
uniform vec3 body_color : source_color = vec3(0.25, 0.55, 0.95);

vec3 patterned_color(vec3 original, vec2 uv) {
    vec2 p = (uv - art_rect.xy) / art_rect.zw;
    float maximum = max(original.r, max(original.g, original.b));
    float minimum = min(original.r, min(original.g, original.b));
    // Preserve black ink, white highlights and low-saturation facial details.
    float mask = smoothstep(0.12, 0.32, maximum - minimum) * smoothstep(0.12, 0.32, maximum);
    float stripes = sin(p.x * 36.0 + sin(p.y * 8.0) * 0.7 + pattern_seed);
    float aa = max(fwidth(stripes), 0.03);
    float pattern = smoothstep(0.25 - aa, 0.25 + aa, stripes);
    if (pattern_style == 1) {
        vec2 cell = fract(p * vec2(9.0, 5.0) + vec2(pattern_seed, pattern_seed * 0.3)) - 0.5;
        float d = length(cell);
        float width = max(fwidth(d), 0.015);
        pattern = 1.0 - smoothstep(0.19 - width, 0.19 + width, d);
    } else if (pattern_style == 2) {
        pattern = smoothstep(0.3, 0.75, p.y + sin(p.x * 9.0 + pattern_seed) * 0.08);
    } else if (pattern_style == 3) {
        pattern = smoothstep(-0.2, 0.5, sin(p.x * 18.0 + pattern_seed) * cos(p.y * 15.0 + sin(p.x * 7.0)));
    }
    vec3 pigment = mix(body_color, pattern_color, pattern * 0.75);
    pigment *= 0.4 + maximum * 0.6;
    return mix(original, pigment, mask * pattern_strength);
}
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
    ALBEDO = mix(vec3(0.006), patterned_color(c.rgb, uv) * tint, smoothstep(0.05, 0.8, c.a));
    EMISSION = glow_color.rgb * glow_color.a * c.rgb * c.a;
    ALPHA = max(c.a, edge) * fade;
    ALPHA_SCISSOR_THRESHOLD = 0.15;
}
