#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Wind distortion shader - spodek stabilní, vrchol se ohýbá
/// direction: 1.0 = doprava, -1.0 = doleva
/// bendCurve: ovládá křivku ohybu (1.5 = jemný, 2.0 = střední, 3.0 = prudký)
/// swayAmount: míra horizontálního posunu celého peta (0 = žádný, 1 = plný)
[[ stitchable ]] float2 windDistortion(
    float2 position,
    float time,
    float intensity,
    float direction,
    float bendCurve,
    float swayAmount,
    float2 size
) {
    // Normalizovaná Y pozice (0 = vrchol, 1 = spodek v SwiftUI souřadnicích)
    float normalizedY = 1.0 - (position.y / size.y);
    normalizedY = clamp(normalizedY, 0.0, 1.0);

    // Konfigurovatelný falloff - spodek se nehýbe, vrchol maximálně
    float bendFactor = pow(normalizedY, bendCurve);

    // Kombinace sinusových vln pro organický pohyb
    float wave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1;

    // Maximální vychýlení (škálováno intenzitou a směrem)
    float maxOffset = size.x * 0.5 * intensity * direction;

    // Bend efekt (vrchol se ohýbá)
    float bendOffset = wave * bendFactor * maxOffset;

    // Sway efekt (celý pet se posouvá)
    float swayOffset = wave * maxOffset * swayAmount * 0.3;

    float xOffset = bendOffset + swayOffset;

    // Vertikální komprese - při ohybu se pet lehce zmáčkne
    float compressionFactor = abs(bendOffset) / (abs(maxOffset) + 0.001);
    float yOffset = compressionFactor * bendFactor * size.y * 0.03;

    return float2(position.x + xOffset, position.y + yOffset);
}
