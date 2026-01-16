# Dynamic Wind Mode - Implementační plán

> **Poslední aktualizace:** Leden 2026
>
> **Změny z diskuze:**
> - Přejmenování modelů: `ActivePet` → `DailyPet`, `ArchivedPet` → `ArchivedDailyPet` ✅ HOTOVO
> - Nové modely: `DynamicPet`, `ArchivedDynamicPet`
> - Wind systém sjednocen na `windProgress: CGFloat` (0-1) pro oba módy
> - `WindConfig` je pro animace (interpoluje plynule), `DynamicWindConfig` je pro herní mechaniku
> - `WindLevel.init(fromPoints:)` NENÍ potřeba - používáme `WindLevel.from(progress:)`
> - `PetDisplayable` existuje pro animace, nový `PetPresentable` pro UI data

## Shrnutí konceptu

Nový režim screen time managementu, kde vítr **dynamicky roste i klesá** na základě chování uživatele, na rozdíl od současného Daily Limit módu kde vítr pouze roste.

### Dva režimy aplikace

| Aspekt | Daily Limit (současný) | Dynamic Wind (nový) |
|--------|------------------------|---------------------|
| Vítr | Jen roste | Roste i klesá |
| Reset | O půlnoci | Průběžně (regenerace) |
| Blow away | Při překročení limitu | Při dosažení max větru |
| Kontrola | Pasivní (limit) | Aktivní (odpočinek) |

---

## Klíčová mechanika: Explicitní regenerace

### Proč explicitní a ne pasivní?

Apple API **neumí detekovat** kdy uživatel přestal používat appku. Jediné callbacky jsou:
- `intervalDidStart` - začátek dne
- `intervalDidEnd` - konec dne
- `eventDidReachThreshold` - dosažení kumulativního času

**Řešení:** Místo hádání kdy uživatel není v appce, necháme ho **aktivně zvolit odpočinek**. Během odpočinku je shield aktivní → víme 100% jistě, že appky nepoužívá.

---

## Detailní mechanika

### 1. Wind Level systém

```
WindLevel: 0-100 (continuous scale, ne enum)

Zóny:
0-25:   Klid (none)      - pet happy
26-50:  Mírný (low)      - pet neutral
51-75:  Střední (medium) - pet concerned
76-99:  Silný (high)     - pet stressed
100:    Blow away        - pet odfouknut
```

### 2. Růst větru (Wind Increase)

Vítr roste při používání blokovaných appek.

**Konfigurovatelné parametry:**
- `windIncreaseRate`: Kolik wind pointů za minutu v appce (default: 1.0)
- Uživatel může nastavit: pomalý (0.5), normální (1.0), rychlý (2.0)

**Implementace:**
- Thresholdy v DeviceActivityMonitor mapované na wind pointy
- Např. threshold každých 5 minut → +5 wind pointů

### 3. Pokles větru (Wind Decrease) - Odpočinek

**Tři typy odpočinku:**

#### A) Neomezený odpočinek (Free Break)
- Uživatel zapne shield na **neomezenou dobu**
- Vítr průběžně klesá dokud je shield aktivní
- Kdykoliv může shield vypnout → vítr zase začne růst při používání appek
- **Žádná penalizace** za vypnutí - flexibilní režim

#### B) Závazný odpočinek (Committed Break)
- Uživatel zvolí **konkrétní délku**: 15 / 30 / 60 / 120 minut
- Vyšší efektivita regenerace než neomezený (bonus za závazek)
- **Penalizace za porušení** - pokud shield vypne předčasně:
  - Wind **neklesne** (ztráta celé regenerace)
  - Nebo wind klesne jen minimálně (např. 10% plánované regenerace)

#### C) Hardcore odpočinek (Hardcore Break) ☠️
- Uživatel zvolí **konkrétní délku**: 15 / 30 / 60 / 120 minut
- **Nejvyšší efektivita regenerace** (např. 1.0/min)
- **Extrémní penalizace za porušení** - pokud shield vypne předčasně:
  - Pet je **okamžitě odfouknut** (blow away)
  - Žádná šance na nápravu
- Pro "all-in" uživatele kteří chtějí maximální motivaci
- Varování při výběru: "Přerušení = okamžité odfouknutí peta!"

**Srovnání:**

| Aspekt | Neomezený | Závazný | Hardcore |
|--------|-----------|---------|----------|
| Flexibilita | Vysoká | Nízká | Žádná |
| Regenerace/min | Nižší (0.3/min) | Střední (0.6/min) | Nejvyšší (1.0/min) |
| Předčasné ukončení | Bez penalizace | Wind neklesne | **Pet blown away** |
| Use case | "Chci si dát pauzu" | "Potřebuji snížit wind" | "All-in závazek" |

**Konfigurovatelné parametry:**
- `freeBreakDecreaseRate`: Wind pointy za minutu (default: 0.3)
- `committedBreakDecreaseRate`: Wind pointy za minutu (default: 0.6)
- `hardcoreBreakDecreaseRate`: Wind pointy za minutu (default: 1.0)
- `committedBreakPenalty`: Co se stane při porušení (none/partial/full)

**Pravidla:**
- Během odpočinku pet "odpočívá" - speciální animace
- Notifikace když závazný odpočinek skončí
- UI jasně rozlišuje typ odpočinku

### 4. Blow Away podmínka

Když `windLevel >= 100`:
- Pet je odfouknut
- Archivuje se jako "blown"
- Uživatel musí vytvořit nového peta

### 5. Denní reset (volitelný)

Možnosti:
- **Žádný reset** - wind pokračuje ze dne na den
- **Částečný reset** - o půlnoci wind klesne o X%
- **Reset na maximum** - wind klesne max na 50 (polovina)

---

## UI změny

### Home Screen

**Nové prvky:**
- Wind progress bar (0-100) místo "čas do limitu"
- Tlačítko "Odpočinek" (prominentní když wind > 50)
- Indikátor aktivního odpočinku s odpočtem

**Stavy:**
```
Normal:     [Wind: 35/100] [🌿 Odpočinek]
Vysoký:     [Wind: 78/100] [⚠️ Odpočinek!]
Odpočinek:  [Odpočíváš... 24:35 zbývá] [Shield aktivní]
```

### Odpočinek Flow

**Neomezený odpočinek:**
```
1. Tap "Zapnout odpočinek"
2. Shield se aktivuje okamžitě
3. Home screen ukazuje: "Odpočíváš... [elapsed time]" + aktuální wind klesá
4. Kdykoliv tap "Ukončit odpočinek"
5. Shield se deaktivuje, wind zůstává na aktuální (snížené) hodnotě
```

**Závazný odpočinek:**
```
1. Tap "Naplánovat odpočinek"
2. Bottom sheet: "Vyber délku závazného odpočinku"
   - 15 minut (-10 wind) ⚡ bonus
   - 30 minut (-25 wind) ⚡ bonus
   - 60 minut (-50 wind) ⚡ bonus
   - Vlastní délka
3. Varování: "Předčasné ukončení = ztráta regenerace"
4. Potvrzení → aktivace shieldu
5. Countdown na home screen (nelze ukončit bez penalizace)
6. Po skončení: Notifikace + wind reduction
```

**Hardcore odpočinek:**
```
1. Tap "Hardcore odpočinek"
2. Bottom sheet: "Vyber délku hardcore odpočinku"
   - 15 minut (-15 wind) ☠️ max bonus
   - 30 minut (-30 wind) ☠️ max bonus
   - 60 minut (-60 wind) ☠️ max bonus
   - Vlastní délka
3. ⚠️ VÝRAZNÉ VAROVÁNÍ: "Přerušení = okamžité odfouknutí peta!"
4. Potvrzení s extra krokem (např. "Rozumím, pokračovat")
5. Countdown na home screen s skull ikonou
6. Tlačítko "Ukončit" je červené s varováním
7. Po skončení: Celebrační notifikace + wind reduction
```

**Přepnutí mezi typy:**
- Z neomezeného lze kdykoliv přejít na závazný/hardcore (commit na zbytek)
- Ze závazného/hardcore nelze přejít na jiný typ bez penalizace

### Pet Detail Screen

- Graf wind level přes čas (ne jen screen time)
- Historie odpočinků
- Aktuální wind zóna vizuálně

### Settings

**Nová sekce "Dynamic Wind":**
```
Režim: [Daily Limit / Dynamic Wind]

--- Dynamic Wind nastavení ---
Rychlost nárůstu větru: [Pomalá / Normální / Rychlá]
Efektivita odpočinku:   [Nízká / Normální / Vysoká]
Denní reset:            [Žádný / Částečný / Na polovinu]
```

---

## Architektura modelů

### Přehled

Dva režimy vyžadují **separátní modely** pro Active i Archived pety, propojené protokoly pro sdílené UI komponenty.

```
Současný stav (po rename):
├── DailyPet (dříve ActivePet) ✅
└── ArchivedDailyPet (dříve ArchivedPet) ✅

Cílový stav:
├── DailyPet ✅
├── DynamicPet (nový model)
├── ArchivedDailyPet ✅
├── ArchivedDynamicPet (nový model)
└── Protokoly:
    ├── PetEvolvable (evoluce) - oba active konformují (existující)
    ├── PetDisplayable (animace) - pro FloatingIslandView (existující)
    └── PetPresentable (UI data) - nový protokol pro sdílené UI
```

### Protokoly

```swift
// Existující - pro evoluci (jen active pets)
// Soubor: Clif/Models/PetEvolvable.swift
protocol PetEvolvable {
    var evolutionHistory: EvolutionHistory { get }
    // Extension poskytuje: essence, currentPhase, isBlob, canEvolve, isBlown,
    // evolutionPath, phase, themeColor, displayScale, assetName(for:)
}

// Existující - pro animace ve FloatingIslandView
// Soubor: Shared/Models/Evolution/PetDisplayable.swift
// Konformuje: EvolutionPhase, Blob
protocol PetDisplayable {
    var displayScale: CGFloat { get }
    var idleConfig: IdleConfig { get }
    func assetName(for mood: Mood) -> String
    func assetName(for windLevel: WindLevel) -> String
    func tapConfig(for type: TapAnimationType) -> TapConfig
}

// NOVÝ - pro sdílené UI komponenty (všechny pet typy)
// Soubor: Shared/Models/PetPresentable.swift
protocol PetPresentable {
    var id: UUID { get }
    var name: String { get }
    var purpose: String? { get }
    var evolutionHistory: EvolutionHistory { get }
    var windProgress: CGFloat { get }  // 0-1, jednotné rozhraní pro animace
    var windLevel: WindLevel { get }   // Computed z windProgress
    var mood: Mood { get }             // Computed z windLevel
}
```

### DailyPet ✅ (implementováno)

```swift
// Soubor: Clif/Models/DailyPet.swift
@Observable
final class DailyPet: Identifiable, PetEvolvable {  // TODO: přidat PetPresentable
    let id: UUID
    let name: String
    private(set) var evolutionHistory: EvolutionHistory
    let purpose: String?
    var todayUsedMinutes: Int
    let dailyLimitMinutes: Int
    var dailyStats: [DailyUsageStat]
    var appUsage: [AppUsage]
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>

    // PetPresentable conformance
    var windProgress: CGFloat {
        guard dailyLimitMinutes > 0 else { return 0 }
        let raw = CGFloat(todayUsedMinutes) / CGFloat(dailyLimitMinutes)
        return min(raw, 1.0)  // Clamp na 1.0, hodnoty nad = over-limit
    }

    var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    var mood: Mood {
        Mood(from: windLevel)
    }
    // ... zbytek beze změny
}
```

### DynamicPet - NOVÝ MODEL

```swift
// Soubor: Clif/Models/DynamicPet.swift
@Observable
final class DynamicPet: Identifiable, PetEvolvable, PetPresentable {
    let id: UUID
    let name: String
    private(set) var evolutionHistory: EvolutionHistory
    let purpose: String?

    // Dynamic Wind specifické
    var windPoints: Int  // 0-100 continuous scale
    var activeBreak: ActiveBreak?
    var breakHistory: [BreakRecord]
    var config: DynamicWindConfig

    // Sdílené s DailyLimitPet
    var dailyStats: [DailyUsageStat]
    var appUsage: [AppUsage]
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>

    // PetPresentable conformance
    var windProgress: CGFloat {
        CGFloat(windPoints) / 100.0  // windPoints 0-100 → progress 0-1
    }

    var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    var mood: Mood {
        Mood(from: windLevel)
    }
}

struct ActiveBreak: Codable {
    let startedAt: Date
    let type: BreakType
    let committedDuration: TimeInterval?  // jen pro .committed
    let decreaseRate: Double  // wind points za minutu

    var endsAt: Date? {
        guard let duration = committedDuration else { return nil }
        return startedAt.addingTimeInterval(duration)
    }

    var isActive: Bool {
        if let end = endsAt {
            return Date() < end
        }
        return true  // unlimited je vždy aktivní dokud nevypneš
    }

    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }

    var remainingTime: TimeInterval? {
        guard let end = endsAt else { return nil }
        return max(0, end.timeIntervalSince(Date()))
    }

    var currentWindReduction: Int {
        Int(elapsedTime / 60.0 * decreaseRate)
    }

    enum BreakType: String, Codable {
        case unlimited  // Neomezený - nižší rate, bez penalizace
        case committed  // Závazný - vyšší rate, penalizace za porušení
        case hardcore   // Hardcore - nejvyšší rate, blow away při porušení
    }
}

struct BreakRecord: Codable {
    let date: Date
    let type: ActiveBreak.BreakType
    let duration: TimeInterval
    let windBefore: Int
    let windAfter: Int
    let wasCompleted: Bool  // false pokud přerušen předčasně
}
```

### ArchivedDailyPet ✅ (implementováno)

```swift
// Soubor: Clif/Models/ArchivedDailyPet.swift
struct ArchivedDailyPet: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int
    let dailyLimitMinutes: Int
    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]

    // Archiving initializer
    init(archiving pet: DailyPet, archivedAt: Date = Date()) { ... }
}
```

### ArchivedDynamicPet - NOVÝ MODEL

```swift
// Soubor: Clif/Models/ArchivedDynamicPet.swift
struct ArchivedDynamicPet: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let totalDays: Int

    // Sdílené s ArchivedDailyLimitPet
    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]

    // Dynamic Wind specifické statistiky
    let breakHistory: [BreakRecord]
    let peakWindPoints: Int  // Nejvyšší dosažený wind
    let totalBreakMinutes: Int  // Celkový čas v odpočinku
    let completedBreaksCount: Int  // Počet dokončených závazných odpočinků

    // Archiving initializer
    init(archiving pet: DynamicPet, archivedAt: Date = Date()) { ... }
}
```

### DynamicWindConfig

```swift
// Soubor: Shared/Models/DynamicWindConfig.swift
// Herní mechanika - NE animační parametry (ty řeší WindConfig)
struct DynamicWindConfig: Codable {
    var riseRate: WindRate = .normal  // body/min při používání appek
    var freeBreakDecreaseRate: Double = 0.3  // wind points/min
    var committedBreakDecreaseRate: Double = 0.6  // wind points/min
    var hardcoreBreakDecreaseRate: Double = 1.0  // wind points/min
    var dailyReset: DailyResetType = .none

    enum WindRate: String, Codable {
        case slow, normal, fast

        var multiplier: Double {
            switch self {
            case .slow: return 0.5
            case .normal: return 1.0
            case .fast: return 2.0
            }
        }
    }

    enum DailyResetType: String, Codable {
        case none        // Žádný reset
        case partial     // -25% wind o půlnoci
        case toHalf      // Reset max na 50
    }
}
```

### WindConfig (existující - pro animace)

```swift
// Soubor: Shared/Models/WindConfig.swift
// Animační parametry - interpoluje plynule na základě progress (0-1)
struct WindConfig: Equatable {
    let intensity: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    static func interpolated(
        progress: CGFloat,
        bounds: WindConfigBounds = .default
    ) -> WindConfig
}

// WindConfigBounds definuje min/max hodnoty a exponenty pro každý parametr
```

### WindLevel (aktualizovaný)

```swift
// Soubor: Shared/Models/Evolution/WindLevel.swift
enum WindLevel: Int, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    // Již implementováno - jednotné rozhraní pro oba módy
    static func from(progress: CGFloat) -> WindLevel {
        switch progress {
        case ..<0.05: return .none
        case ..<0.50: return .low
        case ..<0.75: return .medium
        default: return .high
        }
    }

    var representativeProgress: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 0.25
        case .medium: return 0.60
        case .high: return 0.90
        }
    }

    // + displayName, icon, label, color
}
```

**Poznámka:** `WindLevel.init(fromPoints:)` z původního plánu NENÍ potřeba.
Oba módy používají `windProgress: CGFloat` (0-1) a `WindLevel.from(progress:)`.

---

## Views architektura

### Sdílené komponenty

```
FloatingIslandView - přijímá:
├── pet: any PetDisplayable (EvolutionPhase nebo Blob)
├── windProgress: CGFloat (0-1)
├── windDirection: CGFloat
└── windRhythm: WindRhythm?

Interně počítá:
├── windLevel = WindLevel.from(progress: windProgress)
├── windConfig = WindConfig.interpolated(progress: windProgress)
└── currentMood = Mood(from: windLevel)
```

**Klíčové:** `FloatingIslandView` nepotřebuje vědět o pet módu - dostane pouze `windProgress` a `PetDisplayable` pro assety/animace.

### Daily Limit specifické

```
Screens/DailyLimit/
├── DailyLimitHomeScreen
├── DailyLimitDetailScreen
├── UsageProgressCard - "45/120 min"
├── DailyStatsChart
└── ArchivedDailyLimitDetailScreen
```

### Dynamic Wind specifické

```
Screens/DynamicWind/
├── DynamicWindHomeScreen
├── DynamicWindDetailScreen
├── WindPointsCard - "Wind: 67/100"
├── BreakButton - "Odpočinek"
├── BreakCountdownView - aktivní odpočinek
├── BreakHistoryList
├── BreakSheet - bottom sheet pro výběr typu
└── ArchivedDynamicDetailScreen
```

### Evoluce

**Evoluce zůstává per-day pro oba módy** - pet evolvuje každý den co přežije (bez blow away), nezávisle na wind mechanice.

---

## DeviceActivityMonitor změny

### Threshold mapování na wind pointy

```swift
// Pro Dynamic mode - thresholdy každých 5 minut
let dynamicThresholds = [5, 10, 15, 20, 25, 30, ...]  // minuty

override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, ...) {
    // Parse minuty z event name
    guard let minutes = parseMinutes(from: event) else { return }

    // Spočítej wind pointy
    let windPoints = Int(Double(minutes) * config.increaseRate.multiplier)

    SharedDefaults.currentWindPoints = min(100, windPoints)

    // Check blow away
    if SharedDefaults.currentWindPoints >= 100 {
        // Trigger blow away
        SharedDefaults.shouldBlowAway = true
    }
}
```

### Break monitoring

```swift
// Při startu odpočinku
func startBreak(duration: TimeInterval, windReduction: Int) {
    let breakEnd = Date().addingTimeInterval(duration)
    SharedDefaults.activeBreakEnd = breakEnd
    SharedDefaults.pendingWindReduction = windReduction

    // Aktivuj shield
    activateShield()

    // Naplánuj local notification
    scheduleBreakEndNotification(at: breakEnd)
}

// Při otevření appky - check jestli break skončil
func checkBreakCompletion() {
    guard let breakEnd = SharedDefaults.activeBreakEnd,
          Date() >= breakEnd else { return }

    // Aplikuj wind reduction
    let reduction = SharedDefaults.pendingWindReduction ?? 0
    SharedDefaults.currentWindPoints = max(0, SharedDefaults.currentWindPoints - reduction)

    // Clear break state
    SharedDefaults.activeBreakEnd = nil
    SharedDefaults.pendingWindReduction = nil

    // Deaktivuj shield (pokud nemá být aktivní z jiného důvodu)
    deactivateShield()
}
```

---

## SharedDefaults rozšíření

```swift
extension SharedDefaults {
    // Dynamic Wind
    static var currentWindPoints: Int
    static var petMode: PetMode
    static var dynamicWindConfig: DynamicWindConfig

    // Break state
    static var activeBreakEnd: Date?
    static var pendingWindReduction: Int?

    // Blow away flag
    static var shouldBlowAway: Bool
}
```

---

## Notifikace

### Nové notifikace pro Dynamic mode

1. **Wind warning** (při 75 wind points)
   - "Vítr sílí! Zvažte odpočinek."

2. **Critical wind** (při 90 wind points)
   - "Kritický vítr! Pet je v ohrožení!"

3. **Break ended**
   - "Odpočinek skončil. Vítr se uklidnil."

4. **Break reminder** (volitelné)
   - "Neodpočíval jsi už X hodin..."

---

## Migration path

### Fáze 1: Přejmenování existujících modelů ✅ HOTOVO
- [x] Přejmenovat `ActivePet` → `DailyPet`
- [x] Přejmenovat `ArchivedPet` → `ArchivedDailyPet`
- [x] Aktualizovat všechny reference v codebase
- [ ] Vytvořit `PetPresentable` protokol
- [ ] Přidat `PetPresentable` conformance na oba modely

### Fáze 2: Dynamic modely
- [ ] Vytvořit `DynamicPet` model (konformuje PetEvolvable, PetPresentable)
- [ ] Vytvořit `ArchivedDynamicPet` model
- [ ] Vytvořit `ActiveBreak` struct
- [ ] Vytvořit `BreakRecord` struct
- [ ] Vytvořit `DynamicWindConfig` struct

### Fáze 3: Manager a persistence
- [ ] Rozšířit `PetManager` o podporu Dynamic petů
- [ ] Rozšířit SharedDefaults pro Dynamic Wind data
- [ ] Persistence pro DynamicPet a ArchivedDynamicPet

### Fáze 4: Break mechanika
- [ ] Break start/end logika v manageru
- [ ] Shield aktivace/deaktivace během breaku
- [ ] Local notifications pro break (start, end, warning)
- [ ] Penalizace za předčasné ukončení committed breaku
- [ ] Hardcore break: blow away při předčasném ukončení

### Fáze 5: DeviceActivityMonitor
- [ ] Rozlišení módu v extension
- [ ] Threshold mapování na wind pointy pro Dynamic
- [ ] Blow away trigger pro Dynamic mode (wind >= 100)

### Fáze 6: UI - Sdílené komponenty
- [ ] FloatingIslandView již používá windProgress - ověřit kompatibilitu
- [ ] Refaktor dalších views aby používaly PetPresentable kde dává smysl
- [ ] Zajistit že existující Daily Limit UI funguje s přejmenovanými modely

### Fáze 7: UI - Dynamic Wind screens
- [ ] `DynamicWindHomeScreen`
- [ ] `WindPointsCard`
- [ ] `BreakButton`
- [ ] `BreakSheet` (bottom sheet pro výběr typu)
- [ ] `BreakCountdownView`

### Fáze 8: UI - Dynamic Wind detail
- [ ] `DynamicWindDetailScreen`
- [ ] `BreakHistoryList`
- [ ] Wind history graf
- [ ] `ArchivedDynamicDetailScreen`

### Fáze 9: Settings a onboarding
- [ ] Mode selector při vytváření peta
- [ ] Dynamic Wind konfigurace v settings
- [ ] Onboarding/tutorial pro nový mode

### Fáze 10: Polish
- [ ] Animace přechodů mezi stavy
- [ ] Pet "odpočívá" animace během breaku
- [ ] Testování edge cases
- [ ] Performance optimalizace

---

## Open questions

1. **~~Může uživatel přerušit odpočinek předčasně?~~** ✅ Vyřešeno
   - Neomezený: Ano, bez penalizace
   - Závazný: Ano, ale wind neklesne (penalizace)
   - Hardcore: Ano, ale pet je blown away

2. **~~Co se stane s wind přes noc?~~** ✅ Vyřešeno
   - Wind zůstává - přes noc uživatel stejně nepoužívá limitované appky

3. **~~Jak řešit více petů?~~** ✅ Vyřešeno
   - Každý pet má vlastní wind points a logiku (stejně jako Daily Limit)

4. **~~Shield během breaku - co blokovat?~~** ✅ Vyřešeno
   - Stejné appky jako normálně

5. **Gamifikace odpočinku?** 📋 TODO (post-MVP)
   - Streak odpočinků?
   - Bonusy za pravidelné odpočinky?
   - Achievements?

---

## Rizika a mitigace

| Riziko | Mitigace |
|--------|----------|
| Uživatel nikdy neodpočívá | Push notifikace, vizuální urgence |
| Odpočinek je "otravný" | Gamifikace, pet animace během odpočinku |
| Příliš snadné/těžké | Konfigurovatelné rates |
| Komplexní pro nové uživatele | Default na Daily Limit, Dynamic jako "advanced" |

---

## Závěr

Dynamic Wind mode přináší aktivnější zapojení uživatele do screen time managementu. Klíčová inovace je **explicitní odpočinek** místo pasivního decay, což obchází limitace Apple API a zároveň vytváří zajímavější herní mechaniku.

MVP doporučení: Začít s Fázemi 1-4, zbytek iterativně.
