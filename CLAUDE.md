# Uuumi - Screen Time Management App

## Core Concept

Uuumi je screen time management app s virtuálním mazlíčkem (pet). Pet žije na plovoucím ostrově a reaguje na uživatelovo používání telefonu:

- **Wind System**: Čím více času strávíš v blokovaných aplikacích, tím silnější vítr fouká na peta
- **Mood**: Pet má náladu (happy/neutral/sad) podle síly větru
- **Evolution**: Pet evolvuje skrz fáze (phase 1-4) pomocí Essence - základní blob + essence určuje evoluční cestu
- **Streak**: Denní série splněných limitů
- **Blow Away**: Při překročení limitu může být pet odfouknut

### Key Models
- **Essence**: Určuje evoluční cestu peta (PlantEssence → PlantEvolution phases 1-4)
- **WindLevel**: none/low/medium/high - mapuje se na Mood
- **EvolutionType**: Protokol pro různé evoluční cesty (PlantEvolution, BlobEvolution)

## Repository Architecture

- `Uuumi/` - Main iOS app (iOS 18+)
  - `App/` - Entry point, deep linking
  - `Managers/` - Business logic (ScreenTimeManager)
  - `Screens/` - UI screens (Home, Profile, Overview, StrictMode)
  - `Auth/Supabase/` - Backend integration
- `Shared/` - Cross-target code (Constants, Models, Storage)
- `DeviceActivityMonitor/` - Extension for threshold monitoring
- `DeviceActivityReport/` - Extension for activity reports
- `ShieldConfiguration/` - Extension for shield UI
- `ShieldAction/` - Extension for shield actions

## Common Commands

- Build: `xcodebuild -scheme Uuumi -destination 'platform=iOS Simulator'`
- Run: Open in Xcode, Cmd+R

## Dependencies

- Supabase v2.38.0 (only external dependency)

## AI Rules

For detailed domain-specific rules, see `ai-rules/` folder.
Load rules on-demand based on the task at hand.

---

# Claude Code Project Rules

## File Creation Policy

When creating new Swift files, always remove the default Xcode header comment block:
```swift
//
//  FileName.swift
//  Uuumi
//
//  Created by Jan Podmolík on XX.XX.XXXX.
//
```
Files should start directly with `import` statements.

## External Libraries & Documentation

**Always use Context7 MCP server for documentation lookup.**

When implementing or working with external libraries (e.g., Supabase, Firebase, etc.):
1. Use Context7 MCP server to fetch the latest documentation
2. Do not rely on outdated knowledge - always verify current API usage
3. This ensures we use up-to-date patterns and avoid deprecated methods

## Architecture

**This project uses MV (Model-View) architecture.**

Guidelines:
- Views are SwiftUI views that directly observe and interact with models
- Models contain the data and business logic
- Use @Observable (iOS 17+) or ObservableObject for reactive state
- Keep views simple - they should primarily handle UI rendering
- Avoid unnecessary abstraction layers (no ViewModels, Coordinators unless explicitly needed)

## Liquid Glass (iOS 26+)

**Filozofie:** Liquid Glass je navigační vrstva - obsah je dole, glass komponenty "plavou" nahoře. Nepoužívat pro hlavní obsah, ale pro kontrolní prvky (toolbary, tlačítka, karty).

### API
```swift
// Základní použití
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

// Interaktivní (pro tlačítka, tappable elementy)
.glassEffect(.regular.interactive(), in: .capsule)

// S tintem (POUZE se sémantikou - primární akce, stav)
.glassEffect(.regular.tint(.blue), in: .circle)
```

### Glass Varianty
- `.regular` - standardní blur s reflexí
- `.clear` - minimální blur pro subtle efekty
- `.regular.interactive()` - reaguje na touch/hover

### Button Styles
```swift
.buttonStyle(.glass)           // sekundární akce
.buttonStyle(.glassProminent)  // primární akce
```

### GlassEffectContainer
Použít když máme více glass elementů blízko sebe (glass nemůže samplovat jiný glass):
```swift
GlassEffectContainer {
    HStack {
        Button("A") { }.glassEffect()
        Button("B") { }.glassEffect()
    }
}
```

### Morphing animace
```swift
@Namespace var namespace

// Element 1
.glassEffectID("button", in: namespace)

// Element 2 (při změně stavu se plynule transformuje)
.glassEffectID("button", in: namespace)
```

### CO NEDĚLAT
- ❌ Nepřidávat `.blur`, `.opacity`, `.background` na glass view
- ❌ Nedávat solid barvy (`Color.white`, `Color.black`) pod glass
- ❌ Nepoužívat `.tint` jen pro dekoraci - pouze se sémantikou
- ❌ Nepřidávat vlastní background na toolbary (mají automaticky glass)
- ❌ Nemíchat `.regular` a `.clear` ve stejné skupině kontrolů

### Fallback pro iOS < 26
```swift
if #available(iOS 26.0, *) {
    content.glassEffect(.regular, in: shape)
} else {
    content
        .background(.ultraThinMaterial)
        .clipShape(shape)
}
```

### Accessibility
- Ověřit s Increase Contrast, Reduce Transparency, Reduce Motion
- Aplikovat glass podmíněně v low power mode nebo při accessibility settings

### Container Concentricity (Vnořené zaoblení)

**Princip:** Vnořené elementy sdílí stejný střed zaoblení s rodičem. Vnitřní radius = vnější radius - padding.

```swift
// Automatické koncentrické zaoblení
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))

// S minimálním fallback radius
.rect(corners: .concentric(minimum: 12), isUniform: true)

// Definice container shape pro potomky
.containerShape(.rect(cornerRadius: 24))
```

**Kdy použít:**
- Tlačítka/badges uvnitř karet
- Vnořené glass elementy
- Komponenty které fungují standalone i nested

**Pravidla:**
- Vyhýbat se "pinched" (příliš malé) nebo "flared" (příliš velké) vnitřním rohům
- `isUniform: true` pro off-center elementy (všechny rohy stejné)
- Dostatečný padding mezi containerem a vnitřními elementy
