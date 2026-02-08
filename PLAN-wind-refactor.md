# Wind System Refactoring Plan

## Problém

Současný systém počítá wind inkrementálně (`wind += delta * riseRate`), což způsobuje:
1. Po několika unlock cyklech "dojdou" thresholdy (limit 20)
2. Wind nikdy spolehlivě nedosáhne 100%
3. Složitá logika s `riseRate`/`fallRate` v extension

## Nový přístup

```swift
wind = (cumulativeSeconds - totalBreakReduction) / limitSeconds * 100
```

- `cumulativeSeconds` = kumulativní použití z DeviceActivity thresholdu
- `totalBreakReduction` = součet sekund "odpuštěných" breaky
- `limitSeconds` = denní limit z presetu

---

## Fáze 1: SharedDefaults + Constants ✅

### 1.1 Constants.swift
- [x] Přidat `DefaultsKeys.totalBreakReduction = "totalBreakReduction"`

### 1.2 SharedDefaults.swift
- [x] Přidat property `totalBreakReduction: Int` (s fresh UserDefaults pro cross-process sync)

---

## Fáze 2: DeviceActivityMonitorExtension ✅

### 2.1 intervalDidStart()
- [x] Přidat reset `totalBreakReduction` na začátku dne

### 2.2 processThresholdEvent()
- [x] Nahradit inkrementální výpočet absolutním

### 2.3 Odstranit nepotřebný kód
- [x] Smazat metodu `updateWindPoints(oldWindPoints:deltaSeconds:riseRate:)`
- [x] Odstranit čtení `riseRate` z `processThresholdEvent`
- [x] Odstranit `effectiveDelta` logiku (handling monitoring restart)

### 2.4 Aktualizovat logy
- [x] Upravit debug logy aby odpovídaly novému výpočtu

---

## Fáze 3: ScreenTimeManager ✅

### 3.1 Nová metoda applyBreakReduction()
- [x] Vytvořit metodu která nahradí `applyWindDecreaseFromShield()`

### 3.2 Upravit processUnlock()
- [x] Nahradit `applyWindDecreaseFromShield()` → `applyBreakReduction()`

### 3.3 Odstranit applyWindDecreaseFromShield()
- [x] Smazat celou metodu (nahrazena `applyBreakReduction()`)

### 3.4 Upravit toggleShield()
- [x] V části "shield OFF": nahradit `applyWindDecreaseFromShield()` → `applyBreakReduction()`

### 3.5 Upravit buildEventsFromPosition() - dynamický target
- [x] Počítat target dynamicky podle aktuálního `totalBreakReduction`
- [x] Vzorec: `targetSeconds = breakReduction + limitSeconds` (kdy wind = 100%)
- [x] Přidat buffer 10% pro jistotu

### 3.6 Upravit buildEvents() - také dynamický target
- [x] Stejný princip jako `buildEventsFromPosition()` pro initial start

### 3.7 Cleanup startMonitoring()
- [x] `riseRatePerSecond` parametr ponechán (používá se pro UI/debug)
- [x] Ponechat `fallRatePerSecond` pro výpočet break reduction

---

## Fáze 4: Zjednodušení - odstranění automatických shieldů ✅

**Důvod:** Automatické shieldy při dosažení wind levelů způsobují problémy se synchronizací stavu mezi procesy. Zjednodušíme systém tak, že extension pouze posílá notifikace a shield se aktivuje pouze manuálně uživatelem (break) nebo volitelně při 100%.

### User Flow
1. **Uživatel používá apps** → wind roste (thresholdy, notifikace)
2. **Uživatel chce break** → jde do Uuumi app, zapne shield manuálně (tlačítko)
3. **Během breaku** → shield blokuje apps, wind se automaticky redukuje (podle fallRate)
4. **Uživatel chce pokračovat** → unlock v app → shield se vypne, thresholdy se restartují

### 4.1 Extension: checkWindLevelChange()
- [x] Odstranit shield aktivaci - nechat pouze notifikace
- [x] Odstranit reference na `shieldActivationLevel`

### 4.2 Extension: checkSafetyShield()
- [x] Odstranit cooldown logiku
- [x] Ponechat volitelný shield při 100% (bez cooldownu)

### 4.3 Extension: Smazat isShieldOnCooldown()
- [x] Smazat celou metodu (již není potřeba)

### 4.4 LimitSettings
- [x] Odstranit `shieldActivationLevel` property
- [x] Odstranit `shieldCooldownSeconds` property

### 4.5 SharedDefaults
- [x] Odstranit `lastUnlockAt` property

### 4.6 ScreenTimeManager
- [x] Odstranit nastavování `lastUnlockAt` v `processUnlock()`

### 4.7 ShieldActionExtension
- [x] Odstranit nastavování `lastUnlockAt` v `handleUnlockRequest()`

### 4.8 Constants
- [x] Odstranit `DefaultsKeys.lastUnlockAt`

### 4.9 Cleanup riseRate (ponecháno)
- [x] `monitoredRiseRate` ponecháno - používá se pro UI/debug zobrazení
- [x] Ponechat `monitoredFallRate` (používá se pro break reduction)

---

## Fáze 5: WindCalculator - Single Source of Truth ✅

**Cíl:** Konsolidovat wind výpočet na jedno místo. Teď je roztříštěný:
- Extension `processThresholdEvent()` - počítá wind při thresholdech
- ScreenTimeManager `applyBreakReduction()` - počítá wind při ukončení breaku
- Pet `effectiveWindPoints` - počítá real-time wind během aktivního shieldu

### 5.1 Vytvořit WindCalculator
- [x] Vytvořit `Shared/Wind/WindCalculator.swift`
- [x] Implementovat `calculate(cumulativeSeconds:breakReduction:limitSeconds:) -> Double`
- [x] Implementovat `currentWind() -> Double` (convenience z SharedDefaults)
- [x] Implementovat `effectiveWind(shieldActivatedAt:fallRate:) -> Double` (real-time během shieldu)

```swift
struct WindCalculator {
    /// Absolutní výpočet wind z raw hodnot
    static func calculate(
        cumulativeSeconds: Int,
        breakReduction: Int,
        limitSeconds: Int
    ) -> Double {
        guard limitSeconds > 0 else { return 0 }
        let effective = max(0, cumulativeSeconds - breakReduction)
        return min(Double(effective) / Double(limitSeconds) * 100, 100)
    }

    /// Convenience: výpočet z aktuálních SharedDefaults hodnot
    static func currentWind() -> Double {
        calculate(
            cumulativeSeconds: SharedDefaults.monitoredLastThresholdSeconds,
            breakReduction: SharedDefaults.totalBreakReduction,
            limitSeconds: SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        )
    }

    /// Real-time wind během aktivního shieldu
    static func effectiveWind(shieldActivatedAt: Date?, fallRate: Double) -> Double {
        let baseWind = currentWind()
        guard let activatedAt = shieldActivatedAt else { return baseWind }
        let elapsed = Date().timeIntervalSince(activatedAt)
        return max(0, baseWind - elapsed * fallRate)
    }
}
```

### 5.2 Refaktorovat Extension
- [x] Nahradit inline výpočet v `processThresholdEvent()` voláním `WindCalculator.calculate()`

### 5.3 Refaktorovat ScreenTimeManager
- [x] Nahradit inline výpočet v `applyBreakReduction()` voláním `WindCalculator.currentWind()`

### 5.4 Refaktorovat Pet
- [x] Nahradit `effectiveWindPoints` computed property voláním `WindCalculator.effectiveWind()`
- [x] Ponechat `windPoints` getter/setter (stále potřeba pro write operace a @Observable)

### 5.5 Aktualizovat dokumentaci
- [ ] Aktualizovat `ai-rules/wind-system.md` s novým WindCalculator

---

## Fáze 6: Testování a opravy z logů ⏳

**Status:** Analýza logů odhalila problémy, které je třeba opravit.

### 6.0 Identifikované problémy z logů
Z analýzy logu (2026-01-25 10:40-10:41) byly identifikovány tyto problémy:

#### Problém 1: `isShieldActive=false` hned po aktivaci
- Shield aktivován v 10:41:24 (`isShieldActive = true`)
- O 7 sekund později (10:41:31) extension čte `isShieldActive=false`
- Někdo zavolal deaktivaci bez explicitní user akce
- **TODO:** Zjistit co způsobuje nechtěnou deaktivaci

#### Problém 2: Shield se znovu aktivoval při 100% místo blow-away
- Po deaktivaci wind dosáhl znovu 100%
- Místo blow-away se aktivoval další shield
- Chybí ochrana před opakovanou aktivací po unlocku

#### Problém 3: Chybí cooldown po unlocku
- Po unlock by neměl být shield znovu aktivován určitou dobu
- Nebo po dosažení 100%+ by měl být pet rovnou blown away
- **TODO:** Implementovat cooldown nebo změnit logiku blow-away

#### Problém 4: Wind skočil na 0
- Pravděpodobně souvisí s nějakým nechtěným resetem
- **TODO:** Prozkoumat všechna místa kde se nastavuje `monitoredWindPoints = 0`

### 6.1 Opravy
- [ ] Opravit problém 1: nechtěná deaktivace shieldu
- [ ] Opravit problém 2: opakovaná aktivace shieldu při 100%
- [ ] Opravit problém 3: implementovat cooldown nebo změnit blow-away logiku
- [ ] Opravit problém 4: nechtěný reset wind na 0

### 6.2 Základní použití
- [ ] Start monitoring, použít apps, ověřit že wind dosáhne 100% při limitu

### 6.3 Notifikace
- [ ] Ověřit že notifikace přijdou při low/medium/high (bez dvojitého triggeru)

### 6.4 Manuální break
- [ ] Zapnout break v app, ověřit že shield se aktivuje
- [ ] Počkat, unlock, ověřit že wind se redukoval správně

### 6.5 Více breaků
- [ ] Ověřit že `totalBreakReduction` se kumuluje správně

### 6.6 Safety shield při 100%
- [ ] Ověřit že volitelný shield při 100% funguje
- [ ] Ověřit že po unlocku při 100%+ je pet blown away (ne další shield)

### 6.7 Hranice dne
- [ ] Ověřit že `totalBreakReduction` se resetuje o půlnoci

### 6.8 Edge cases
- [ ] Break delší než zbývající wind (wind by měl být min 0)
- [ ] Použití přesahující limit (wind by měl být max 100)
- [ ] Unlock při 100%+ wind → blow away notifikace + pet blown

---

## Fáze 7: Dokumentace ✅

### 7.1 wind-system.md
- [x] Aktualizovat sekci "Wind Calculation" s novým vzorcem
- [x] Přidat sekci "Break Reduction"
- [x] Aktualizovat diagram architektury
- [ ] Aktualizovat po odstranění automatických shieldů

---

## Shrnutí změn

| Soubor | Změna | Status |
|--------|-------|--------|
| `Shared/Constants/Constants.swift` | + `DefaultsKeys.totalBreakReduction`, - `lastUnlockAt` | ✅ |
| `Shared/Storage/SharedDefaults.swift` | + `totalBreakReduction`, - `lastUnlockAt` | ✅ |
| `Shared/Models/Evolution/WindLevel.swift` | LimitSettings: - `shieldActivationLevel`, - `shieldCooldownSeconds` | ✅ |
| `Shared/Wind/WindCalculator.swift` | + Nový soubor - single source of truth pro wind výpočty | ✅ |
| `DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` | Absolutní výpočet via WindCalculator, pouze notifikace | ✅ |
| `Uuumi/Managers/ScreenTimeManager.swift` | + `applyBreakReduction()` via WindCalculator, dynamický target | ✅ |
| `Uuumi/Models/Pet.swift` | `effectiveWindPoints` via WindCalculator | ✅ |
| `ShieldAction/ShieldActionExtension.swift` | - `lastUnlockAt` nastavování | ✅ |
| `ai-rules/wind-system.md` | Aktualizovat dokumentaci | ⏳ |

## Co zůstane
- `monitoredLastThresholdSeconds` - pro určení odkud generovat nové thresholdy
- `checkWindLevelChange()` - pouze notifikace (bez shield aktivace)
- `buildEventsFromPosition()` - s dynamickým target výpočtem
- `toggleShield()` - manuální break z UI
- `processUnlock()` - ukončení breaku + restart thresholdů
- `checkSafetyShield()` - safety shield při 100% (vždy, bez cooldownu)
- `monitoredRiseRate` - pro UI/debug zobrazení
- `monitoredFallRate` - pro výpočet break reduction

## Co odpadlo
- `riseRate` v extension výpočtech
- Inkrementální wind výpočet (`wind += delta * rate`)
- `updateWindPoints()` metoda
- `effectiveDelta` logika
- Automatická shield aktivace při wind levelech
- `shieldActivationLevel` v LimitSettings
- `shieldCooldownSeconds` v LimitSettings
- `lastUnlockAt` v SharedDefaults
- `isShieldOnCooldown()` v extension
