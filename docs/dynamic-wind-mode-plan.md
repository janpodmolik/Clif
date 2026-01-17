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

1. **Modely** - DynamicPet, ArchivedDynamicPet, ActiveBreak, DynamicWindConfig
2. **Manager** - rozšířit PetManager o Dynamic podporu, persistence
3. **Break mechanika** - start/end/fail, shield aktivace, penalizace
4. **DeviceActivityMonitor** - threshold → windPoints, blow away trigger
5. **UI** - home screen, break flow, detail screen
6. **Settings** - mode selector, Dynamic konfigurace

## Rozhodnutí

- ✅ Break typy: free/committed/hardcore s různými rates
- ✅ Penalizace: free žádná, committed ztráta regenerace, hardcore blow away
- ✅ Denní reset: volitelný (on/off), default off
- ✅ Evoluce: per-day pro oba módy (pet evolvuje každý den co přežije)
