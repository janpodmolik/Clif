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

// MARK: - Evolution Glow Burst Effect

/// Simple hash for pseudo-random noise
float glowHash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/// Multi-scale noise for organic glow pattern
float glowNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(glowHash(i), glowHash(i + float2(1, 0)), u.x),
        mix(glowHash(i + float2(0, 1)), glowHash(i + float2(1, 1)), u.x),
        u.y
    );
}

/// Fractal noise combining multiple octaves
float glowFractalNoise(float2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;

    // Layer 1: Base pattern
    value += amplitude * glowNoise(p * 3.0 + time * 0.5);
    amplitude *= 0.5;

    // Layer 2: Medium detail
    value += amplitude * glowNoise(p * 6.0 - time * 0.3);
    amplitude *= 0.5;

    // Layer 3: Fine detail
    value += amplitude * glowNoise(p * 12.0 + time * 0.7);

    return value;
}

/// Energy accumulation that builds to a bright flash.
/// Phase 1 (0→0.55): Organic glow builds with noise-based pattern
/// Phase 2 (0.55→0.65): Flash (white out)
/// Phase 3 (0.65→1.0): Glow fades, reveal new pet
[[ stitchable ]] half4 evolutionGlowBurst(
    float2 position,
    half4 color,
    float progress,
    float3 glowColor,
    float peakIntensity,
    float flashDuration,
    float2 size,
    float isNewImage
) {
    // Skip transparent pixels
    if (color.a < 0.01) {
        return color;
    }

    float2 uv = position / size;

    // Phase calculations
    float buildupEnd = 0.55;
    float flashEnd = buildupEnd + flashDuration;

    half4 result = color;

    if (progress < buildupEnd) {
        // Phase 1: Organic glow buildup
        if (isNewImage > 0.5) {
            return half4(0, 0, 0, 0);
        }

        float glowProgress = progress / buildupEnd;

        // Cubic ease-in for dramatic buildup
        float easedProgress = glowProgress * glowProgress * glowProgress;

        // Animated time for noise movement
        float animTime = progress * 8.0;

        // Organic noise pattern - shifts and evolves over time
        float noise = glowFractalNoise(uv, animTime);

        // Edge distance for base shape (soft falloff from center)
        float2 centerDist = uv - float2(0.5, 0.5);
        float radialDist = length(centerDist);

        // Combine noise with radial pattern
        // Early: mostly noise-based random sparkles
        // Late: noise + radial for full glow before flash
        float noiseWeight = mix(0.8, 0.4, easedProgress);
        float radialWeight = 1.0 - noiseWeight;

        float pattern = noise * noiseWeight + (1.0 - radialDist) * radialWeight;

        // Threshold rises with progress - reveals more glow over time
        float threshold = mix(-0.2, 0.3, easedProgress);
        float glowMask = smoothstep(threshold, threshold + 0.3, pattern);

        // Base intensity grows with progress
        float baseGlow = easedProgress * peakIntensity * glowMask;

        // Sparkle effect - random bright spots that appear and fade
        float sparkle = step(0.85, glowNoise(uv * 20.0 + animTime * 2.0));
        sparkle *= sin(animTime * 10.0 + uv.x * 50.0) * 0.5 + 0.5;
        float sparkleGlow = sparkle * easedProgress * peakIntensity * 0.5;

        // Pulsing overall intensity
        float pulseIntensity = mix(0.1, 0.3, glowProgress);
        float pulseSpeed = mix(12.0, 30.0, glowProgress);
        float pulse = sin(progress * pulseSpeed) * pulseIntensity + (1.0 - pulseIntensity);

        float totalGlow = (baseGlow + sparkleGlow) * pulse;

        result.rgb = color.rgb + half3(glowColor) * half(totalGlow);

    } else if (progress < flashEnd) {
        // Phase 2: Flash (white out)
        float flashProgress = (progress - buildupEnd) / (flashEnd - buildupEnd);
        float flashIntensity = sin(flashProgress * 3.14159);

        half3 white = half3(1.0, 1.0, 1.0);
        result.rgb = mix(color.rgb, white, half(flashIntensity * 0.95));
        result.a = color.a;

    } else {
        // Phase 3: Fade out glow
        if (isNewImage < 0.5) {
            return half4(0, 0, 0, 0);
        }

        float fadeProgress = (progress - flashEnd) / (1.0 - flashEnd);
        float easedFade = 1.0 - pow(1.0 - fadeProgress, 2.0);

        // Residual organic glow fading
        float animTime = progress * 4.0;
        float noise = glowFractalNoise(uv, animTime);

        float2 centerDist = uv - float2(0.5, 0.5);
        float radialDist = length(centerDist);

        float pattern = noise * 0.4 + (1.0 - radialDist) * 0.6;
        float residualGlow = pattern * (1.0 - easedFade) * peakIntensity * 0.4;

        result.rgb = color.rgb + half3(glowColor) * half(residualGlow);
    }

    return result;
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
