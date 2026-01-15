# Dynamic Wind Mode - Implementační plán

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
Současný stav:
├── ActivePet (Daily Limit)
└── ArchivedPet

Nový stav:
├── ActivePet (Daily Limit) - beze změny
├── DynamicPet (Dynamic Wind) - nový model
├── ArchivedPet (Daily Limit) - beze změny
├── ArchivedDynamicPet (Dynamic Wind) - nový model
└── Protokoly:
    ├── PetEvolvable (evoluce) - oba active konformují
    ├── PetDisplayable (UI zobrazení) - všechny 4 modely konformují
    └── ArchivedPetDisplayable (archived UI) - oba archived konformují
```

### Protokoly

```swift
// Existující - pro evoluci (jen active pets)
protocol PetEvolvable {
    var evolutionHistory: EvolutionHistory { get }
    var isBlob: Bool { get }
    var canEvolve: Bool { get }
    func applyEssence(_ essence: Essence)
    func evolve()
}

// Nový - pro UI zobrazení (všechny pet typy)
protocol PetDisplayable {
    var id: UUID { get }
    var name: String { get }
    var purpose: String? { get }
    var windLevel: WindLevel { get }  // Computed - oba módy vrátí WindLevel
    var mood: Mood { get }
    var isBlown: Bool { get }
    var currentPhase: Int { get }
    var essence: Essence? { get }
}

// Nový - pro archived pets UI
protocol ArchivedPetDisplayable: PetDisplayable {
    var archivedAt: Date { get }
    var totalDays: Int { get }
}
```

### ActivePet (Daily Limit) - BEZE ZMĚNY

```swift
// Současný model zůstává
@Observable
final class ActivePet: Identifiable, PetEvolvable, PetDisplayable {
    let id: UUID
    let name: String
    var evolutionHistory: EvolutionHistory
    let purpose: String?
    var windLevel: WindLevel  // Enum: none/low/medium/high
    var todayUsedMinutes: Int
    let dailyLimitMinutes: Int
    var dailyStats: [DailyUsageStat]
    // ... zbytek beze změny
}
```

### DynamicPet (Dynamic Wind) - NOVÝ MODEL

```swift
@Observable
final class DynamicPet: Identifiable, PetEvolvable, PetDisplayable {
    let id: UUID
    let name: String
    var evolutionHistory: EvolutionHistory
    let purpose: String?

    // Dynamic Wind specifické
    var windPoints: Int  // 0-100 continuous scale
    var activeBreak: ActiveBreak?
    var breakHistory: [BreakRecord]
    var config: DynamicWindConfig

    // PetDisplayable conformance
    var windLevel: WindLevel {
        WindLevel(fromPoints: windPoints)
    }

    var mood: Mood {
        windLevel.mood
    }

    var isBlown: Bool {
        evolutionHistory.isBlown
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

### ArchivedPet (Daily Limit) - BEZE ZMĚNY

```swift
// Současný model zůstává
struct ArchivedPet: Identifiable, Codable, ArchivedPetDisplayable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let isBlown: Bool
    let archivedAt: Date
    let dailyStats: [DailyUsageStat]
    let streak: Int
    // ...
}
```

### ArchivedDynamicPet (Dynamic Wind) - NOVÝ MODEL

```swift
struct ArchivedDynamicPet: Identifiable, Codable, ArchivedPetDisplayable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let isBlown: Bool
    let archivedAt: Date

    // Dynamic Wind specifické statistiky
    let breakHistory: [BreakRecord]
    let peakWindPoints: Int  // Nejvyšší dosažený wind
    let totalBreakMinutes: Int  // Celkový čas v odpočinku
    let completedBreaksCount: Int  // Počet dokončených závazných odpočinků

    // ArchivedPetDisplayable
    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: evolutionHistory.createdAt, to: archivedAt).day ?? 0
    }

    var windLevel: WindLevel { .none }  // Archived = no wind
    var mood: Mood { isBlown ? .sad : .happy }
}
```

### DynamicWindConfig

```swift
struct DynamicWindConfig: Codable {
    var increaseRate: WindRate = .normal
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

### WindLevel rozšíření

```swift
// Současný enum - zachovat
enum WindLevel: Int, CaseIterable {
    case none, low, medium, high
}

// Nový initializer pro Dynamic mode
extension WindLevel {
    init(fromPoints points: Int) {
        switch points {
        case 0..<26: self = .none
        case 26..<51: self = .low
        case 51..<76: self = .medium
        default: self = .high
        }
    }
}
```

---

## Views architektura

### Sdílené komponenty (používají PetDisplayable)

```
Shared/
├── FloatingIslandView - animace ostrova a peta
├── PetAnimationView - pet sprite/animace
├── EvolutionCarousel - výběr evoluce
├── MoodIndicator - zobrazení nálady
├── WeatherCard - počasí/vítr indikátor (částečně)
└── PetAvatarView - malý avatar peta
```

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

### Fáze 1: Protokoly a základní modely
- [ ] Vytvořit `PetDisplayable` protokol
- [ ] Vytvořit `ArchivedPetDisplayable` protokol
- [ ] Upravit `ActivePet` aby konformoval `PetDisplayable`
- [ ] Upravit `ArchivedPet` aby konformoval `ArchivedPetDisplayable`
- [ ] Přidat `WindLevel.init(fromPoints:)` extension

### Fáze 2: Dynamic modely
- [ ] Vytvořit `DynamicPet` model (konformuje PetEvolvable, PetDisplayable)
- [ ] Vytvořit `ArchivedDynamicPet` model
- [ ] Vytvořit `ActiveBreak` struct
- [ ] Vytvořit `BreakRecord` struct
- [ ] Vytvořit `DynamicWindConfig` struct

### Fáze 3: Manager a persistence
- [ ] Vytvořit `DynamicPetManager` (nebo rozšířit PetManager)
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
- [ ] Refaktor FloatingIslandView na PetDisplayable
- [ ] Refaktor dalších sdílených views na protokoly
- [ ] Zajistit že existující Daily Limit UI funguje

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
