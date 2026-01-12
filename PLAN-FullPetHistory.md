# Full Pet History Screen - Implementační plán

## Cíl

Screen zobrazující kompletní historii screen time pro peta (5-30 dnů), přístupný z `WeeklyHistoryCard` přes tap na chevron.

## Obsah screenu

1. **HistorySummaryCard** - souhrn (celkem dní, denní průměr, success rate, dny pod/přes limit)
2. **FullHistoryChart** - horizontálně scrollovatelný bar chart všech dnů
3. **TrendMiniChart** - sparkline s trend badge (klesá/stabilní/roste)
4. **AppUsageBreakdownCard** - per-app breakdown (seřazeno dle času, progress bary)

---

## Existující UI Patterns (dodržet!)

### Styling
- **`.glassCard()`** - cornerRadius 32, iOS 26+ glassEffect, jinak ultraThinMaterial + shadow
- **Over-limit**: `.red` gradient
- **Today**: `.blue.opacity(0.9)` → `.cyan` gradient
- **Theme color**: `themeColor.opacity(0.9)` → `themeColor.opacity(0.5)` bottom→top

### Bar Chart (z `PetWeeklyChart`)
```swift
barHeight: 70pt
spacing: 6pt
// Minuty nahoře
.font(.system(size: 9, weight: .medium))
// Background
Color.primary.opacity(0.08), cornerRadius: 6
// Fill
max(8, barHeight * normalized)
// Den label
.font(.caption2)
```

### Card Headers
- Icon (`.secondary`) + Title (`.headline`) + Spacer + meta (`.caption`)

### Date Formatters (cs_CZ)
```swift
formatter.setLocalizedDateFormatFromTemplate("EEE")  // "Po", "Út"
formatter.dateFormat = "d.M."  // "12.1."
```

---

## 1. Data modely

### 1.1 `ActiveAppUsage` (NOVÝ)
**Soubor:** `Clif/Models/ActiveAppUsage.swift`

```swift
struct ActiveAppUsage: Codable, Identifiable, Equatable {
    let id: UUID
    let displayName: String
    var dailyMinutes: [Date: Int]

    var totalMinutes: Int { dailyMinutes.values.reduce(0, +) }
    var averageMinutes: Int { totalMinutes / max(dailyMinutes.count, 1) }
}

// + mock() a mockList()
```

### 1.2 `BlockedAppsFullStats` (NOVÝ)
**Soubor:** `Shared/Models/BlockedAppsFullStats.swift`

```swift
struct BlockedAppsFullStats: Codable, Equatable {
    let days: [BlockedAppsDailyStat]
    let limitMinutes: Int

    var totalDays: Int { days.count }
    var totalMinutes: Int { ... }
    var averageMinutes: Int { ... }
    var maxMinutes: Int { ... }
    var daysOverLimit: Int { ... }
    var daysUnderLimit: Int { ... }
    var complianceRate: Double { ... }  // 0-1
    var trend: Trend { ... }  // .improving / .stable / .worsening

    func normalizedValues() -> [CGFloat]  // pro sparkline
}

// + mock()
```

### 1.3 Rozšíření `ActivePet` (MODIFY)
**Soubor:** `Clif/Models/ActivePet.swift`

Přidat:
```swift
let dailyStats: [BlockedAppsDailyStat]
let appUsage: [ActiveAppUsage]

var fullStats: BlockedAppsFullStats {
    BlockedAppsFullStats(days: dailyStats, limitMinutes: limitMinutes)
}
```

Update init + mock().

---

## 2. UI komponenty

### 2.1 `FullHistoryChart` (NOVÝ)
**Soubor:** `Clif/Screens/PetDetail/Components/FullHistoryChart.swift`

- ScrollView(.horizontal) s bary
- Reuse styling z `PetWeeklyChart`
- Auto-scroll na konec (ScrollViewReader)
- `onDayTap` → existující `DayDetailSheet`

### 2.2 `TrendMiniChart` (NOVÝ)
**Soubor:** `Clif/Screens/PetDetail/Components/TrendMiniChart.swift`

- Header: chart.line icon + "Trend" + trend badge
- SparklineView (Path) ~40pt výška
- V `.glassCard()`

### 2.3 `HistorySummaryCard` (NOVÝ)
**Soubor:** `Clif/Screens/PetDetail/Components/HistorySummaryCard.swift`

- 3 stat items: Celkem dní, Denní průměr, Úspěšnost
- Pod tím: "X pod limitem ✓" | "Y přes limit ⚠"
- V `.glassCard()`

### 2.4 `AppUsageBreakdownCard` (NOVÝ)
**Soubor:** `Clif/Screens/PetDetail/Components/AppUsageBreakdownCard.swift`

- Header: app.badge icon + "Aplikace"
- List seřazený dle totalMinutes desc
- Každý řádek: název, total, avg/day, progress bar
- V `.glassCard()`

---

## 3. Main screen

### `FullPetHistoryScreen` (NOVÝ)
**Soubor:** `Clif/Screens/PetDetail/FullPetHistoryScreen.swift`

```swift
struct FullPetHistoryScreen: View {
    let petName: String
    let stats: BlockedAppsFullStats
    let appUsage: [ActiveAppUsage]
    var themeColor: Color = .green

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: BlockedAppsDailyStat?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HistorySummaryCard(stats:, themeColor:)

                    // Chart section
                    VStack(alignment: .leading, spacing: 8) {
                        // Header: icon + "Denní přehled" + "X dní"
                        FullHistoryChart(stats:, themeColor:, onDayTap:)
                    }
                    .padding()
                    .glassCard()

                    TrendMiniChart(stats:, themeColor:)

                    if !appUsage.isEmpty {
                        AppUsageBreakdownCard(appUsage:, totalDays:, themeColor:)
                    }
                }
                .padding()
            }
            .navigationTitle("Historie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { /* xmark button */ }
            .sheet(item: $selectedDay) { DayDetailSheet(day: $0) }
        }
    }
}
```

---

## 4. Integrace

### `PetActiveDetailScreen` (MODIFY)
```swift
// Nové properties
let dailyStats: [BlockedAppsDailyStat]
let appUsage: [ActiveAppUsage]

@State private var showFullHistory = false

// Wire WeeklyHistoryCard
WeeklyHistoryCard(..., onTap: { showFullHistory = true })

// Přidat cover
.fullScreenCover(isPresented: $showFullHistory) {
    FullPetHistoryScreen(
        petName: petName,
        stats: BlockedAppsFullStats(days: dailyStats, limitMinutes: limitMinutes),
        appUsage: appUsage,
        themeColor: evolutionHistory.essence.themeColor
    )
}
```

### Call sites (MODIFY)
- `OverviewScreen.swift` - předat `dailyStats` a `appUsage`
- `HomeScreen.swift` - předat `dailyStats` a `appUsage`
- `PetDetailScreenDebug.swift` - předat `dailyStats` a `appUsage`

---

## 5. Souhrn souborů

### Nové (7):
1. `Clif/Models/ActiveAppUsage.swift`
2. `Shared/Models/BlockedAppsFullStats.swift`
3. `Clif/Screens/PetDetail/FullPetHistoryScreen.swift`
4. `Clif/Screens/PetDetail/Components/FullHistoryChart.swift`
5. `Clif/Screens/PetDetail/Components/TrendMiniChart.swift`
6. `Clif/Screens/PetDetail/Components/HistorySummaryCard.swift`
7. `Clif/Screens/PetDetail/Components/AppUsageBreakdownCard.swift`

### Modifikované (4):
1. `Clif/Models/ActivePet.swift` - přidat `dailyStats`, `appUsage`, `fullStats`
2. `Clif/Screens/PetDetail/PetActiveDetailScreen.swift` - navigace + props
3. `Clif/Screens/Overview/OverviewScreen.swift` - předat data
4. `Clif/Screens/Home/HomeScreen.swift` - předat data
5. `Clif/Screens/PetDetail/Debug/PetDetailScreenDebug.swift` - předat data

---

## 6. Pořadí implementace

1. **Data modely** - `BlockedAppsFullStats`, `ActiveAppUsage`, rozšíření `ActivePet` + mocks
2. **FullHistoryChart** - scrollovatelný bar chart
3. **Helper komponenty** - `TrendMiniChart`, `HistorySummaryCard`, `AppUsageBreakdownCard`
4. **Main screen** - `FullPetHistoryScreen`
5. **Integrace** - wire `PetActiveDetailScreen`, update call sites

---

## 7. Ověření

1. Každá komponenta má `#Preview`
2. Tap na chevron v `WeeklyHistoryCard` → `FullPetHistoryScreen`
3. Chart scrolluje, auto-scroll na konec (nejnovější den)
4. Tap na bar → `DayDetailSheet`
5. Bar styling konzistentní s `PetWeeklyChart`
6. Build passes bez errorů
