#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float2 remnHash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

static float remnGradientNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = dot(remnHash22(cell) * 2.0 - 1.0, f);
    float b = dot(remnHash22(cell + float2(1.0, 0.0)) * 2.0 - 1.0, f - float2(1.0, 0.0));
    float c = dot(remnHash22(cell + float2(0.0, 1.0)) * 2.0 - 1.0, f - float2(0.0, 1.0));
    float d = dot(remnHash22(cell + float2(1.0, 1.0)) * 2.0 - 1.0, f - float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// How high the sheet's surface stands at `p`: bumps a few points across with finer ones on top.
static float remnPaperHeight(float2 p) {
    float height = 0.0;
    float amplitude = 1.0;
    for (int octave = 0; octave < 5; octave++) {
        height += amplitude * remnGradientNoise(p);
        p = float2(0.8 * p.x - 0.6 * p.y, 0.6 * p.x + 0.8 * p.y) * 2.03 + float2(17.3, 5.1);
        amplitude *= 0.5;
    }
    return height;
}

/// The soft tooth of cold-pressed paper lit from the top left, as a small lift or dip in brightness.
/// `strength` is about how far a typical spot moves from the plain tone.
[[ stitchable ]] half4 remnPaperGrain(float2 position, half4 color, float strength) {
    float2 p = position / 7.0;
    float relief = remnPaperHeight(p) - remnPaperHeight(p - 0.05);
    float shade = relief * 14.0;
    return half4(color.rgb + half3(shade * strength) * color.a, color.a);
}
