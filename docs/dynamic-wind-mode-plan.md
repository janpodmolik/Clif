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
2. **DTO vrstva** - oddělení persistence od modelů
3. **Manager** - rozšířit PetManager o Dynamic podporu, persistence
4. **Break mechanika** - start/end/fail, shield aktivace, penalizace
5. **DeviceActivityMonitor** - threshold → windPoints, blow away trigger
6. **UI** - home screen, break flow, detail screen
7. **Settings** - mode selector, Dynamic konfigurace

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
