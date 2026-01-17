# Dynamic Wind Mode - Plán

## Koncept

Nový režim kde vítr **dynamicky roste i klesá** na základě chování uživatele.

| Aspekt | Daily Limit | Dynamic Wind |
|--------|-------------|--------------|
| Vítr | Jen roste | Roste i klesá |
| Reset | O půlnoci | Průběžně (breaky) |
| Blow away | Při překročení limitu | Při wind = 100 |

## Wind zóny

| Wind | Zóna | Pet mood |
|------|------|----------|
| 0-25 | none | happy |
| 26-50 | low | neutral |
| 51-75 | medium | concerned |
| 76-99 | high | stressed |
| 100 | blow away | - |

## Mechanika

→ Detaily update logiky viz `snapshot-sot-rewrite-plan.md` sekce 5) Dynamic update

**Růst větru:**
- `windPoints += deltaMinutes * riseRate`
- riseRate default: 10 wind/min (0→100 za 10 min)

**Pokles větru (breaky):**
- `windPoints -= breakMinutes * decreaseRate`
- Break = shield aktivní, víme 100% že uživatel nepoužívá appky
- `breakEnded` event přijde ze ShieldAction (uživatel dismissne shield)
- `breakFailed` event přijde ze ShieldAction (uživatel klikne "unblock")

**Denní reset (volitelný):**
- On: o půlnoci wind klesne na 0
- Off: wind pokračuje ze dne na den (default)

## Break typy

| Typ | Decrease rate | Penalizace za porušení |
|-----|---------------|------------------------|
| Free | 0.3 wind/min | Žádná |
| Committed | 0.6 wind/min | Wind neklesne |
| Hardcore | 1.0 wind/min | **Blow away** |

**Délky:** 15 / 30 / 60 / 120 min (nebo neomezený pro free)

## Modely

**Existující:**
- `DailyPet` ✅
- `ArchivedDailyPet` ✅

**Nové:**
- `DynamicPet` - windPoints, lastThresholdMinutes, activeBreak, config
- `ArchivedDynamicPet` - breakHistory, peakWindPoints, totalBreakMinutes
- `ActiveBreak` - startedAt, type, plannedDuration, decreaseRate
- `DynamicWindConfig` - riseRate, decreaseRates, dailyReset

**Protokoly:**
- `PetPresentable` - windProgress, windLevel, mood (pro UI)

## UI Screeny

**Home:**
- Wind progress bar (0-100)
- Break button (prominentní při wind > 50)
- Break countdown (během aktivního breaku)

**Break flow:**
- BreakSheet - výběr typu a délky
- Varování pro committed/hardcore
- BreakCountdownView - odpočet, nelze ukončit bez penalizace

**Detail:**
- Wind history graf
- Break history seznam

## Implementační fáze

1. **Modely** - DynamicPet, ArchivedDynamicPet, ActiveBreak, DynamicWindConfig ✅
2. **Manager** - rozšířit PetManager o Dynamic podporu, persistence ✅
3. **Break mechanika** - start/end/fail, shield aktivace, penalizace
4. **DeviceActivityMonitor** - threshold → windPoints, blow away trigger
5. **UI** - home screen, break flow, detail screen
6. **Settings** - mode selector, Dynamic konfigurace
7. **DTO vrstva** - oddělení persistence od modelů (při Supabase integraci)

## Manager architektura

**Jeden PetManager pro oba typy petů.**

### Principy

1. **Mutace na petovi** - `blowAway()`, `evolve()`, `startBreak()`, `endBreak()` jsou metody na pet modelu
2. **Collection operace na Manageru** - `archive()`, `delete()`, `create*()` jsou metody manageru
3. **`ActivePet` enum** - type-safe wrapper pro UI routing (switch → správný View)
4. **Univerzální metody** - `archive(id:)` místo `archiveDaily(id:)` + `archiveDynamic(id:)`

### ActivePet enum

```swift
enum ActivePet: Identifiable {
    case daily(DailyPet)
    case dynamic(DynamicPet)

    var id: UUID {
        switch self {
        case .daily(let pet): pet.id
        case .dynamic(let pet): pet.id
        }
    }

    var name: String { ... }
    var windProgress: CGFloat { ... }
    var mood: Mood { ... }

    // Pro UI routing
    var isDaily: Bool { ... }
    var isDynamic: Bool { ... }

    // Přímý přístup když potřebuješ konkrétní typ
    var asDaily: DailyPet? { ... }
    var asDynamic: DynamicPet? { ... }
}
```

### Properties

```swift
// Interní storage (private)
private var dailyPets: [DailyPet] = []
private var dynamicPets: [DynamicPet] = []
private var archivedDailyPets: [ArchivedDailyPet] = []
private var archivedDynamicPets: [ArchivedDynamicPet] = []

// Public API
var activePets: [ActivePet]  // computed, merged + sorted by createdAt
var currentPet: ActivePet?   // activePets.first

var archivedPets: [any ArchivedPet]  // computed, merged (potřebuje ArchivedPet protokol)
```

### Metody

**Create (type-specific):**
```swift
func createDaily(name:purpose:dailyLimitMinutes:) -> DailyPet
func createDynamic(name:purpose:config:) -> DynamicPet
```

**Universal operations:**
```swift
func archive(id: UUID)      // Rozliší typ interně
func delete(id: UUID)       // Smaže aktivního peta
func deleteArchived(id: UUID)  // Smaže archivovaného
func pet(by id: UUID) -> ActivePet?
```

### Persistence

**Active peti → SharedDefaults (App Group)**
- Malý dataset (1-3 peti)
- Extensions (DeviceActivityMonitor) potřebují přístup
- JSON encoded

**Archived peti → FileManager**
- Potenciálně velký dataset
- Nepotřebují extensions přístup
- Připraveno pro DTO vrstvu

**Klíče:**
```swift
DefaultsKeys.activeDailyPets
DefaultsKeys.activeDynamicPets
// Archived v ~/Documents/archived_daily_pets.json atd.
```

### Řazení

- Default podle `createdAt` (newest first)
- Uživatel si může přizpůsobit (budoucí feature)

### Důležité

- Mode je per-pet property, nelze měnit po vytvoření
- Pet je vytvořen jako Daily NEBO Dynamic
- Mutace peta automaticky triggeruje uložení (observation)

## DTO Architektura

**Umístění:** `Clif/DTOs/`

**Naming:** `{Model}DTO` (např. `DailyPetDTO`, `DynamicPetDTO`)

**Struktura:**
```
Clif/DTOs/
  DailyPetDTO.swift
  DynamicPetDTO.swift
  ArchivedDailyPetDTO.swift
  ArchivedDynamicPetDTO.swift
  EvolutionHistoryDTO.swift
  ActiveBreakDTO.swift
  CompletedBreakDTO.swift
```

**Konverze:** Na DTO (`DTO(from: model)` init), na Model extension
```swift
// DTO → Model
extension DailyPet {
    convenience init(from dto: DailyPetDTO) { ... }
}

// Model → DTO
extension DailyPetDTO {
    init(from pet: DailyPet) { ... }
}
```

**Výhody:**
- Čisté Codable structs bez computed properties
- Persistence nezávislá na UI modelech
- Snadnější migrace dat
- Validace při konverzi

## Rozhodnutí

- ✅ Break typy: free/committed/hardcore s různými rates
- ✅ Penalizace: free žádná, committed ztráta regenerace, hardcore blow away
- ✅ Denní reset: volitelný (on/off), default off
- ✅ Evoluce: per-day pro oba módy (pet evolvuje každý den co přežije)
