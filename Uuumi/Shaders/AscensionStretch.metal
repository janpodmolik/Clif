#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Organic vertical stretch for archive ascension animation.
/// Bottom pixels stay in place, top pixels shift upward proportionally to `amount`.
/// Uses a power curve for a natural "pull from above" feel.
///
/// Parameters:
/// - position: Current pixel position
/// - amount: Stretch intensity (0 = no stretch, 1 = full stretch)
/// - size: View size
[[ stitchable ]] float2 ascensionStretch(
    float2 position,
    float amount,
    float2 size
) {
    if (amount <= 0.0) {
        return position;
    }

    // Normalized distance from bottom (0 = bottom, 1 = top)
    float normalizedFromBottom = 1.0 - (position.y / size.y);

    // Power curve: top pixels stretch much more than middle
    // pow(x, 2.0) gives aggressive acceleration toward the top for visible deformation
    float stretchFactor = pow(normalizedFromBottom, 2.0);

    // Maximum vertical displacement at full stretch (pixels)
    // Pet view is small (~85pt), so multiplier must be large for visible effect
    float maxDisplacement = size.y * 1.5;

    // Shift sampling position downward = visual content moves upward
    float yOffset = stretchFactor * amount * maxDisplacement;

    return float2(position.x, position.y + yOffset);
}
