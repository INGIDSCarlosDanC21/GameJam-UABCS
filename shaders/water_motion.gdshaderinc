// World-space shimmer for exterior geometry only. No screen sampling in stereo.
vec3 underwater_warp(vec3 world, float clock) {
    float exterior = 1.0 - smoothstep(-4.5, -2.0, world.z);
    return vec3(sin(world.y * 3.0 + clock * 0.65), cos(world.x * 2.6 - clock * 0.55), 0.0) * 0.035 * exterior;
}
