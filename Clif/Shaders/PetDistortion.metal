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

// MARK: - Evolution Transition Helper Functions

/// Simple hash function for noise generation
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/// Value noise for organic dissolve pattern
float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Smooth interpolation
    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(i + float2(0, 0)), hash(i + float2(1, 0)), u.x),
        mix(hash(i + float2(0, 1)), hash(i + float2(1, 1)), u.x),
        u.y
    );
}

/// Multi-octave fractal noise for more organic patterns
float fractalNoise(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * valueNoise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// MARK: - Evolution Dissolve Effect

/// Noise-based dissolve that scatters pixels organically.
/// Progress 0→0.55: old image dissolves out (longer buildup, accelerating)
/// Progress 0.45→1: new image dissolves in (overlap during transition)
[[ stitchable ]] half4 evolutionDissolve(
    float2 position,
    half4 color,
    float progress,
    float noiseScale,
    float edgeSoftness,
    float2 size,
    float isNewImage
) {
    // Normalized UV
    float2 uv = position / size;

    // Generate noise pattern
    float noise = fractalNoise(uv * noiseScale, 4);

    // Add some variation from center (dissolve from outside in)
    float2 centerDist = uv - float2(0.5, 0.5);
    float radialDist = length(centerDist);
    noise = noise * 0.7 + (1.0 - radialDist) * 0.3;

    // Phase boundaries
    float oldImageEnd = 0.55;
    float newImageStart = 0.45;

    // Calculate threshold based on progress
    float threshold;
    if (isNewImage < 0.5) {
        // Old image: dissolve OUT
        // Use ease-in curve for slower start, faster finish
        float dissolveProgress = clamp(progress / oldImageEnd, 0.0, 1.0);
        float easedProgress = dissolveProgress * dissolveProgress; // Quadratic ease-in

        threshold = easedProgress * 1.2; // Slightly overshoot to ensure full dissolve
        float alpha = smoothstep(threshold - edgeSoftness, threshold + edgeSoftness, noise);
        return half4(color.rgb, color.a * half(alpha));
    } else {
        // New image: dissolve IN
        float dissolveProgress = clamp((progress - newImageStart) / (1.0 - newImageStart), 0.0, 1.0);
        // Ease-out for new image: fast start, slow finish
        float easedProgress = 1.0 - pow(1.0 - dissolveProgress, 2.0);

        threshold = 1.0 - easedProgress * 1.1;
        float alpha = smoothstep(threshold - edgeSoftness, threshold + edgeSoftness, noise);
        return half4(color.rgb, color.a * half(alpha));
    }
}

// MARK: - Evolution Glow Burst Effect

/// Energy accumulation that builds to a bright flash.
/// Phase 1 (0→0.55): Glow builds around edges with eased-in intensity
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
    // Skip transparent pixels - don't apply any effect to them
    if (color.a < 0.01) {
        return color;
    }

    float2 uv = position / size;

    // Phase calculations - longer buildup phase (55% of animation)
    float buildupEnd = 0.55;
    float flashEnd = buildupEnd + flashDuration;

    half4 result = color;

    if (progress < buildupEnd) {
        // Phase 1: Glow buildup (old image visible)
        if (isNewImage > 0.5) {
            return half4(0, 0, 0, 0);
        }

        float glowProgress = progress / buildupEnd;

        // Ease-in curve: slow start, accelerating toward the end
        // Using cubic ease-in for more dramatic buildup
        float easedProgress = glowProgress * glowProgress * glowProgress;

        // Edge glow: stronger at edges
        float2 centerDist = abs(uv - float2(0.5, 0.5)) * 2.0;
        float edgeDist = max(centerDist.x, centerDist.y);

        // Base glow intensity grows with eased progress
        float baseGlow = easedProgress * peakIntensity;

        // Edge emphasis increases as we approach the flash
        float edgeEmphasis = mix(0.3, 1.0, easedProgress);
        float edgeGlow = pow(edgeDist, 1.5) * baseGlow * edgeEmphasis;

        // Overall brightness increases toward the end
        float overallGlow = baseGlow * 0.3;

        // Pulsing glow - starts subtle, becomes more intense
        float pulseIntensity = mix(0.1, 0.4, glowProgress);
        float pulseSpeed = mix(15.0, 40.0, glowProgress); // Speeds up toward end
        float pulse = sin(progress * pulseSpeed) * pulseIntensity + (1.0 - pulseIntensity);

        float totalGlow = (edgeGlow + overallGlow) * pulse;

        // Add glow to color (only to visible pixels)
        result.rgb = color.rgb + half3(glowColor) * half(totalGlow);

    } else if (progress < flashEnd) {
        // Phase 2: Flash (white out) - only affect visible pixels
        float flashProgress = (progress - buildupEnd) / (flashEnd - buildupEnd);
        float flashIntensity = sin(flashProgress * 3.14159);

        // Fade visible pixels to white
        half3 white = half3(1.0, 1.0, 1.0);
        result.rgb = mix(color.rgb, white, half(flashIntensity * 0.95));
        result.a = color.a;

    } else {
        // Phase 3: Fade out glow (new image visible)
        if (isNewImage < 0.5) {
            return half4(0, 0, 0, 0);
        }

        float fadeProgress = (progress - flashEnd) / (1.0 - flashEnd);

        // Ease-out: fast start, slow end
        float easedFade = 1.0 - pow(1.0 - fadeProgress, 2.0);

        // Residual glow fading out
        float2 centerDist = abs(uv - float2(0.5, 0.5)) * 2.0;
        float edgeDist = max(centerDist.x, centerDist.y);
        float edgeGlow = pow(edgeDist, 1.5) * (1.0 - easedFade) * peakIntensity * 0.5;

        result.rgb = color.rgb + half3(glowColor) * half(edgeGlow);
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
