#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Wind distortion shader - bottom stays stable, top bends with wind
///
/// Parameters:
/// - position: Current pixel position
/// - time: Animation time for wave calculation
/// - intensity: Wind strength (0 = none, 1 = normal, 2 = strong)
/// - direction: Wind direction (1.0 = right, -1.0 = left)
/// - bendCurve: Controls bend curve steepness (1.5 = gentle, 2.0 = medium, 3.0 = steep)
/// - swayAmount: Horizontal sway amount for entire view (0 = none, 1 = full)
/// - size: View size for normalization
[[ stitchable ]] float2 windDistortion(
    float2 position,
    float time,
    float intensity,
    float direction,
    float bendCurve,
    float swayAmount,
    float2 size
) {
    // Normalized Y position (0 = top, 1 = bottom in SwiftUI coordinates)
    float normalizedY = 1.0 - (position.y / size.y);
    normalizedY = clamp(normalizedY, 0.0, 1.0);

    // Configurable falloff - bottom stays still, top moves most
    float bendFactor = pow(normalizedY, bendCurve);

    // Combined sine waves for organic movement
    float wave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1;

    // Maximum offset (scaled by intensity and direction) - subtle effect
    float maxOffset = size.x * 0.15 * intensity * direction;

    // Bend effect (top bends)
    float bendOffset = wave * bendFactor * maxOffset;

    // Sway effect (entire view shifts horizontally)
    float swayOffset = wave * maxOffset * swayAmount * 0.3;

    float xOffset = bendOffset + swayOffset;

    return float2(position.x + xOffset, position.y);
}
