#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float remnHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float remnValueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float a = remnHash(cell);
    float b = remnHash(cell + float2(1.0, 0.0));
    float c = remnHash(cell + float2(0.0, 1.0));
    float d = remnHash(cell + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// The fine, even tooth of a sheet of paper, as a small lift or dip in brightness.
[[ stitchable ]] half4 remnPaperGrain(float2 position, half4 color, float strength) {
    float tooth = remnHash(floor(position * 2.0)) - 0.5;
    float grit = remnValueNoise(position * 0.6) - 0.5;
    float shade = tooth * 0.8 + grit * 0.3;
    return half4(color.rgb + half3(shade * strength) * color.a, color.a);
}
