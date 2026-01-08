#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Unified pet distortion shader - combines idle, wind, and tap animations.
///
/// Three animation layers (combined additively):
/// - Idle: Continuous breathing animation (subtle vertical scale from bottom)
/// - Wind: Bottom stays stable, top bends with wind direction
/// - Tap: Various animations triggered on user interaction
///
/// Parameters:
/// - position: Current pixel position
/// - time: Animation time for wave calculation
/// - windIntensity: Wind strength (0 = none, 1 = normal, 2 = strong)
/// - windDirection: Wind direction (1.0 = right, -1.0 = left)
/// - bendCurve: Controls bend curve steepness (1.5 = gentle, 2.0 = medium, 3.0 = steep)
/// - swayAmount: Horizontal sway amount for entire view (0 = none, 1 = full)
/// - tapTime: Time when tap occurred (-1 = no active tap animation)
/// - tapType: Animation type (0=none, 1=wiggle, 2=squeeze, 3=jiggle)
/// - tapIntensity: Strength of tap animation
/// - tapDecayRate: How fast the animation fades
/// - tapFrequency: Oscillation frequency
/// - idleEnabled: Whether idle breathing is active (0 or 1)
/// - idleAmplitude: Breathing scale amount (0.03 = 3% size increase)
/// - idleFrequency: Breathing speed in Hz
/// - idleFocusStart: Where breathing starts to fade (0 = bottom, 1 = top)
/// - idleFocusEnd: Where breathing fully fades out (0 = bottom, 1 = top)
/// - size: View size for normalization
[[ stitchable ]] float2 petDistortion(
    float2 position,
    float time,
    // Wind parameters
    float windIntensity,
    float windDirection,
    float bendCurve,
    float swayAmount,
    // Tap parameters
    float tapTime,
    float tapType,
    float tapIntensity,
    float tapDecayRate,
    float tapFrequency,
    // Idle parameters
    float idleEnabled,
    float idleAmplitude,
    float idleFrequency,
    float idleFocusStart,
    float idleFocusEnd,
    // Size
    float2 size
) {
    // ========== WIND EFFECT ==========

    // Normalized Y position (0 = top, 1 = bottom in SwiftUI coordinates)
    float normalizedY = 1.0 - (position.y / size.y);
    normalizedY = clamp(normalizedY, 0.0, 1.0);

    // Configurable falloff - bottom stays still, top moves most
    float bendFactor = pow(normalizedY, bendCurve);

    // Combined sine waves for organic movement
    float windWave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1;

    // Maximum offset (scaled by intensity and direction) - subtle effect
    float maxOffset = size.x * 0.15 * windIntensity * windDirection;

    // Bend effect (top bends)
    float bendOffset = windWave * bendFactor * maxOffset;

    // Sway effect (entire view shifts horizontally)
    float swayOffset = windWave * maxOffset * swayAmount * 0.3;

    float windXOffset = bendOffset + swayOffset;
    float windYOffset = 0.0;

    // ========== TAP EFFECT ==========

    float tapXOffset = 0.0;
    float tapYOffset = 0.0;

    // Only calculate if tap animation is active
    if (tapTime >= 0.0) {
        float timeSinceTap = time - tapTime;

        // Check if animation is still within duration (max ~1 second for safety)
        if (timeSinceTap >= 0.0 && timeSinceTap < 1.0) {
            // Exponential decay
            float decay = exp(-timeSinceTap * tapDecayRate);

            // Oscillation wave
            float tapWave = sin(timeSinceTap * tapFrequency);

            int animationType = int(tapType);

            if (animationType == 1) {
                // ===== WIGGLE =====
                // Rapid horizontal oscillation, uniform across height
                tapXOffset = tapWave * tapIntensity * decay;
            }
            else if (animationType == 2) {
                // ===== SQUEEZE =====
                // Vertical compression toward bottom (size.y)
                // Top compresses more, bottom stays anchored
                float squeezeFactor = 1.0 - tapIntensity * tapWave * decay;
                float distFromBottom = size.y - position.y;
                tapYOffset = distFromBottom * (1.0 - squeezeFactor);
            }
            else if (animationType == 3) {
                // ===== JIGGLE =====
                // Wave propagation from bottom to top with phase shift
                float phase = normalizedY * 3.14159 * 2.0;
                float jiggleWave = sin(timeSinceTap * tapFrequency - phase) * decay;
                // Stronger effect at top
                tapXOffset = jiggleWave * tapIntensity * normalizedY;
            }
        }
    }

    // ========== IDLE EFFECT (BREATHE) ==========

    float idleYOffset = 0.0;

    if (idleEnabled > 0.5) {
        // Smooth breathing wave (0 to 1 range for gentle in-out)
        float breatheWave = sin(time * idleFrequency * 6.28318) * 0.5 + 0.5;

        // Normalized position (0 = bottom, 1 = top)
        float normalizedFromBottom = position.y / size.y;

        // Focus breathing on configurable portion of pet (body area)
        // Uses smoothstep to fade out effect toward the top
        float breatheFocus = 1.0 - smoothstep(idleFocusStart, idleFocusEnd, normalizedFromBottom);

        // Scale from bottom with focused amplitude
        float focusedAmplitude = idleAmplitude * breatheFocus;
        float breatheScale = 1.0 + breatheWave * focusedAmplitude;
        float distFromBottom = size.y - position.y;
        idleYOffset = distFromBottom * (1.0 - breatheScale);
    }

    // ========== COMBINE EFFECTS ==========

    float finalX = position.x + windXOffset + tapXOffset;
    float finalY = position.y + windYOffset + tapYOffset + idleYOffset;

    return float2(finalX, finalY);
}
