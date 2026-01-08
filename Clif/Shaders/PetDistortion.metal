#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Helper Functions

/// Organic wave combining multiple frequencies for natural movement
float organicWave(float time) {
    return sin(time * 1.5) * 0.6
         + sin(time * 2.3) * 0.3
         + sin(time * 0.7) * 0.1;
}

/// Normalized Y from top (0 = top, 1 = bottom in SwiftUI coords)
float normalizedYFromTop(float2 position, float2 size) {
    float normalized = 1.0 - (position.y / size.y);
    return clamp(normalized, 0.0, 1.0);
}

/// Normalized Y from bottom (0 = bottom, 1 = top)
float normalizedYFromBottom(float2 position, float2 size) {
    return position.y / size.y;
}

// MARK: - Wind Effect

float2 calculateWindOffset(
    float2 position,
    float2 size,
    float time,
    float intensity,
    float direction,
    float bendCurve,
    float swayAmount
) {
    if (intensity == 0.0) {
        return float2(0.0, 0.0);
    }

    float normalizedY = normalizedYFromTop(position, size);

    // Bend factor: bottom stays still, top moves most
    float bendFactor = pow(normalizedY, bendCurve);

    // Wave oscillation with directional bias
    // Pet bends IN the wind direction (wind pushes it)
    // Forward swing (with wind): 100% amplitude
    // Back swing (against wind): 50% amplitude
    float rawWave = organicWave(time);
    float wave = rawWave < 0.0 ? rawWave : rawWave * 0.5;

    // Base offset scaled by intensity and direction
    float maxOffset = size.x * 0.15 * intensity * direction;

    // Bend: top bends with wind
    float bendOffset = wave * bendFactor * maxOffset;

    // Sway: entire view shifts horizontally
    float swayOffset = wave * maxOffset * swayAmount * 0.3;

    return float2(bendOffset + swayOffset, 0.0);
}

// MARK: - Tap Effects

float2 calculateTapOffset(
    float2 position,
    float2 size,
    float time,
    float tapTime,
    int tapType,
    float intensity,
    float decayRate,
    float frequency
) {
    // No active tap
    if (tapTime < 0.0) {
        return float2(0.0, 0.0);
    }

    float timeSinceTap = time - tapTime;

    // Animation expired
    if (timeSinceTap < 0.0 || timeSinceTap >= 1.0) {
        return float2(0.0, 0.0);
    }

    float decay = exp(-timeSinceTap * decayRate);
    float wave = sin(timeSinceTap * frequency);
    float normalizedY = normalizedYFromTop(position, size);

    float xOffset = 0.0;
    float yOffset = 0.0;

    switch (tapType) {
        case 1: {
            // WIGGLE: Rapid horizontal oscillation
            xOffset = wave * intensity * decay;
            break;
        }
        case 2: {
            // SQUEEZE: Vertical compression toward bottom
            float squeezeFactor = 1.0 - intensity * wave * decay;
            float distFromBottom = size.y - position.y;
            yOffset = distFromBottom * (1.0 - squeezeFactor);
            break;
        }
        case 3: {
            // JIGGLE: Wave propagation from bottom to top
            float phase = normalizedY * 3.14159 * 2.0;
            float jiggleWave = sin(timeSinceTap * frequency - phase) * decay;
            xOffset = jiggleWave * intensity * normalizedY;
            break;
        }
    }

    return float2(xOffset, yOffset);
}

// MARK: - Idle (Breathing) Effect

float calculateIdleYOffset(
    float2 position,
    float2 size,
    float time,
    bool enabled,
    float amplitude,
    float frequency,
    float focusStart,
    float focusEnd
) {
    if (!enabled) {
        return 0.0;
    }

    // Breathing wave (0 to 1 range)
    float breatheWave = sin(time * frequency * 6.28318) * 0.5 + 0.5;

    // Focus area (strongest at bottom, fades toward top)
    float normalizedFromBottom = normalizedYFromBottom(position, size);
    float breatheFocus = 1.0 - smoothstep(focusStart, focusEnd, normalizedFromBottom);

    // Scale from bottom
    float focusedAmplitude = amplitude * breatheFocus;
    float breatheScale = 1.0 + breatheWave * focusedAmplitude;
    float distFromBottom = size.y - position.y;

    return distFromBottom * (1.0 - breatheScale);
}

// MARK: - Main Shader

/// Unified pet distortion shader combining wind, tap, and idle animations.
///
/// Parameters:
/// - position: Current pixel position
/// - time: Animation time
/// - windIntensity: Wind strength (0-2)
/// - windDirection: 1.0 = right, -1.0 = left
/// - bendCurve: Bend steepness (1.5 gentle, 3.0 steep)
/// - swayAmount: Horizontal sway (0-1)
/// - tapTime: When tap occurred (-1 = inactive)
/// - tapType: 0=none, 1=wiggle, 2=squeeze, 3=jiggle
/// - tapIntensity, tapDecayRate, tapFrequency: Tap animation params
/// - idleEnabled, idleAmplitude, idleFrequency: Breathing params
/// - idleFocusStart, idleFocusEnd: Breathing focus zone
/// - size: View size
[[ stitchable ]] float2 petDistortion(
    float2 position,
    float time,
    // Wind
    float windIntensity,
    float windDirection,
    float bendCurve,
    float swayAmount,
    // Tap
    float tapTime,
    float tapType,
    float tapIntensity,
    float tapDecayRate,
    float tapFrequency,
    // Idle
    float idleEnabled,
    float idleAmplitude,
    float idleFrequency,
    float idleFocusStart,
    float idleFocusEnd,
    // Size
    float2 size
) {
    // Calculate each effect
    float2 windOffset = calculateWindOffset(
        position, size, time,
        windIntensity, windDirection, bendCurve, swayAmount
    );

    float2 tapOffset = calculateTapOffset(
        position, size, time,
        tapTime, int(tapType), tapIntensity, tapDecayRate, tapFrequency
    );

    float idleYOffset = calculateIdleYOffset(
        position, size, time,
        idleEnabled > 0.5, idleAmplitude, idleFrequency,
        idleFocusStart, idleFocusEnd
    );

    // Combine all effects
    return float2(
        position.x + windOffset.x + tapOffset.x,
        position.y + windOffset.y + tapOffset.y + idleYOffset
    );
}
