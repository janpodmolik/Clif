# Clif 🧗

> *Screen time management through emotional connection*  
> *Správa času u obrazovky skrze emoční propojení*

---

## 🇨🇿 Česky

Clif je iOS aplikace, která pomáhá uživateli omezit čas strávený v rozptylujících aplikacích (Instagram, TikTok, YouTube apod.) vytvořením záměrné bariéry a emoční motivace prostřednictvím vyvíjející se postavy.

**Inspirace:** ScreenZen, Brainrot, Opal

### 🎯 Koncept

Když se pokusíš otevřít omezenou aplikaci, Clif zobrazí **krátký delay** — moment k zamyšlení, který ti připomene tvé cíle. Během tohoto delay se zobrazí **aktuální progress** — kolik z denního limitu už máš spotřebováno a jak blízko je tvá postava k okraji útesu. Díky tomu okamžitě vidíš, jaký dopad bude mít další použití aplikace.

Hlavní motivace je vizuálně vyjádřená pomocí **postavy, která se každý den vyvíjí** podle toho, jak dodržuješ své limity.

### Základní mechaniky

- **Vyber aplikace**, které chceš omezit
- **Nastav denní limit** (např. 25 minut pro sociální sítě)
- **Vizuální metafora**: Postava je tlačena k okraji útesu, jak spotřebováváš svůj denní limit
- **Dodržíš limity** → Postava se vyvíjí do vyšších forem
- **Překročíš limity** → Postava spadne z útesu, ztratí evoluční pokrok a začíná znovu

### Klíčové principy

- ❌ Žádné kredity, body ani podmíněné nákupy
- ✅ Motivace skrze **emoční zpětnou vazbu** a evoluci
- ✅ Riziko ztráty progresu vytváří skutečné sázky
- ✅ Staráš se o postavu tím, že se staráš o svůj screen time

---

## 🇬🇧 English

Clif is an iOS app that helps users reduce time spent in distracting applications (Instagram, TikTok, YouTube, etc.) by creating intentional friction and emotional motivation through an evolving character system.

**Inspired by:** ScreenZen, Brainrot, Opal

### 🎯 Concept

When you try to open a restricted app, Clif displays a **short delay screen** — a moment of reflection to remind you of your goals. During this delay, you'll see your **current progress** — how much of your daily limit you've already used and how close your character is to the cliff edge. This gives you immediate visibility into the impact of continued app usage.

The core motivation is visualized through a **character that evolves daily** based on how well you respect your screen time limits.

### Core Mechanics

- **Select apps** you want to limit
- **Set daily allowance** (e.g., 25 minutes for social media)
- **Visual metaphor**: Your character is pushed toward a cliff edge as you consume your daily limit
- **Stay within limits** → Character evolves into higher forms
- **Exceed limits** → Character falls off the cliff, loses evolution progress, and restarts

### Key Principles

- ❌ No credits, points, or conditional purchases
- ✅ Motivation through **emotional feedback** and evolution
- ✅ Risk of losing progress creates real stakes
- ✅ Care for your character by caring for your screen time

---

## 🏗️ Architektura / Architecture

### Dynamic Shield with Progress

The app uses **App Groups** to connect three components:

| Component | Role |
|-----------|------|
| **Main App** | Sets daily limits, manages settings |
| **DeviceActivityMonitor** | Tracks usage, writes progress |
| **ShieldConfiguration** | Displays dynamic shield UI |

Communication happens via shared **`UserDefaults`**.

### How It Works

```
┌─────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│  Main App   │────▶│ DeviceActivityMonitor│────▶│ ShieldConfiguration │
│             │     │                      │     │                     │
│ • Set limit │     │ • 10 thresholds      │     │ • Read progress     │
│ • Config    │     │ • Write progress     │     │ • Show icon/text    │
└─────────────┘     └──────────────────────┘     └─────────────────────┘
                              │
                              ▼
                    Shared UserDefaults
                      (App Groups)
```

1. Main app sets daily limit and creates **10 thresholds** (each 10%)
2. `DeviceActivityMonitor` writes progress to shared `UserDefaults` at each threshold
3. `ShieldConfiguration` reads current progress and displays matching icon/text

### Assets

ShieldConfiguration includes **10 progress icons**:

```
progress_10.png  → progress_100.png
```

---

## 🛠️ Tech Stack

- **Platform:** iOS
- **Frameworks:** 
  - Screen Time API
  - DeviceActivity
  - FamilyControls
- **Communication:** App Groups + UserDefaults

---

## 📁 Project Structure

```
Clif/
├── Clif/                     # Main app target
├── DeviceActivityMonitor/    # Extension for tracking
├── ShieldConfiguration/      # Extension for shield UI
│   └── Assets/               # Progress icons (10-100%)
└── Shared/                   # Shared code & models
```

---

## 🚧 Status

**Work in Progress** — The project name "Clif" is a working title and may change.

---

## 📋 TODO

### Priorita 1: Core Features
- [x] **DeviceActivityReport integration** — Zobrazení dnešního screen time v aplikaci ✅
  - Implementováno: `TotalActivityReport`, `TotalActivityView` s progress circle a app breakdown
  - Data: Celkový čas, breakdown per app, progress vůči limitu
  
- [ ] **Heartbeat systém** — Background task pro anti-cheat
  - Důvod: Detekce odinstalace aplikace
  - Implementace: `BGTaskScheduler` každé 4 hodiny
  - Info.plist: `BGTaskSchedulerPermittedIdentifiers`

- [ ] **Streak & Avatar UI** — Vizualizace progressu
  - Důvod: Emoční motivace, hlavní mechanika hry
  - Komponenty: Avatar display, XP bar, streak counter

### Priorita 2: Backend Integration
- [ ] **Swift modely pro Supabase** — `UserSettings`, `UserProgress`, `StreakHistory`
- [ ] **Sync nastavení** — Upload/download při změně
- [ ] **Report daily progress** — Volání server funkce na konci dne

### Priorita 3: Polish
- [ ] **Onboarding flow** — Registrace, výběr aplikací, nastavení limitu
- [ ] **Notifikace** — 50%, 80%, 100% limitu
- [ ] **Avatar animace** — Spine/Lottie pro evoluci
- [ ] **Penalty UI** — Zobrazení trestu po návratu (nemocný avatar)

---

## 🔐 Backend & Supabase Integration

### Přehled

Aplikace používá **Supabase** jako backend pro:
- Autentizaci uživatelů
- Ukládání nastavení (synchronizovatelná mezi zařízeními)
- Streak & avatar systém
- Anti-cheat mechanismy

### Konfigurace Supabase

```swift
// Clif/Supabase/SupabaseConfig.swift
let client = SupabaseClient(
    supabaseURL: URL(string: "https://xxx.supabase.co")!,
    supabaseKey: "anon_key",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true  // Důležité!
        )
    )
)
```

### Architektura: MV (Model-View)

Aplikace používá **MV pattern** (ne MVVM):
- `@State` přímo ve View
- Logika v extension View
- Žádné ViewModely
- Modely jsou čisté datové struktury s `Codable`

---

## 📊 Databázová struktura

### Tabulky

| Tabulka | Účel |
|---------|------|
| `profiles` | Základní info o uživateli |
| `user_settings` | Nastavení aplikace (limity, notifikace) |
| `user_progress` | Streak, avatar level, XP |
| `streak_history` | Log každého dne (důkaz pro streak) |
| `heartbeat_log` | Anti-cheat heartbeaty |
| `avatar_unlocks` | Odemčené kosmetické položky |

### Co kam ukládat

| Data | Kam | Důvod |
|------|-----|-------|
| `FamilyActivitySelection` | **Lokálně** (SharedDefaults) | Tokeny jsou device-specific, nelze sync |
| `daily_limit_minutes` | **Supabase** | Číslo, lze synchronizovat |
| `notifications_enabled` | **Supabase** | Boolean, lze synchronizovat |
| Streak & avatar | **Supabase** | Anti-cheat, nelze lokálně |
| Denní statistiky | **Supabase** | Historie, reporting |

### ⚠️ Family Controls tokeny

`FamilyActivitySelection` obsahuje opaque tokeny (`ApplicationToken`, `CategoryToken`), které:
- Jsou **device-specific** a **user-specific**
- **Nelze serializovat** do JSONu pro uložení do DB
- **Musí zůstat lokálně** v `SharedDefaults` / App Group

---

## 🎮 Streak & Avatar systém

### Avatar Evolution

```
Level 1-4:   🥚 Egg (vejce)
Level 5-14:  🐣 Baby (mládě)  
Level 15-29: 🐥 Teen (mladý)
Level 30-49: 🐔 Adult (dospělý)
Level 50+:   🦅 Master (mistr)
```

### XP systém

| Akce | XP |
|------|-----|
| Splněný den (pod limitem) | +10 |
| Využití < 50% limitu | +10 bonus |
| Využití < 25% limitu | +10 extra |
| 7+ denní streak | +5 denně |
| 30+ denní streak | +10 denně |
| Nesplněný den | 0 (streak reset) |

### Streak logika

- Streak se počítá **na serveru** (ne lokálně)
- Používá **server timestamp** (ne device date)
- Při splnění limitu: streak +1
- Při překročení limitu: streak = 0

---

## 🛡️ Anti-cheat systém

### Problém: Odinstalace aplikace

Uživatel může:
1. Odinstalovat Clif
2. Používat zablokované aplikace bez omezení
3. Znovu nainstalovat Clif
4. Očekávat zachovaný streak

### Řešení: Heartbeat systém

```
┌─────────────────────────────────────────────────────────────┐
│ HEARTBEAT FLOW                                              │
│                                                             │
│ Aplikace nainstalovaná:                                     │
│   BGTaskScheduler posílá heartbeat každé 4 hodiny          │
│   Server aktualizuje last_heartbeat timestamp              │
│                                                             │
│ Aplikace odinstalovaná:                                     │
│   Žádné heartbeaty                                          │
│   Server detekuje gap při příštím přihlášení               │
│                                                             │
│ Při reinstalaci + přihlášení:                              │
│   Server: "Poslední heartbeat před X dny"                  │
│   Gap > 36 hodin = PENALTY                                 │
└─────────────────────────────────────────────────────────────┘
```

### Heartbeat tolerance

- **36 hodin** = 1 den + 12h buffer
- Důvody pro buffer:
  - iOS může zabít background task
  - Telefon může být vypnutý
  - Legitimní důvody (nový telefon, oprava)

### Penalty systém při detekci odinstalace

| Zmeškané dny | Streak | XP ztráta | Avatar efekt |
|--------------|--------|-----------|--------------|
| 1-2 dny | Reset na 0 | -20 až -40 | Smutný 😢 |
| 3-5 dnů | Reset na 0 | -60 až -100 | Nemocný 🤒 |
| 6-14 dnů | Reset na 0 | -120 až -280 | Degradace stage |
| 15+ dnů | Reset na 0 | -300+ | Zpět na egg 🥚 |

### Anti-cheat mechanismy

| Mechanismus | Co řeší |
|-------------|---------|
| **Heartbeat každé 4h** | Detekuje odinstalaci |
| **36h timeout** | Tolerance pro spánek/offline |
| **Server timestamp** | Zabraňuje změně data na zařízení |
| **Suspicious counter** | Trackuje podezřelé chování |
| **Device date check** | Porovnání device vs server date |
| **Usage jen roste** | SQL `GREATEST()` zabraňuje snížení |

### Co se stane v různých scénářích

| Scénář | Výsledek |
|--------|----------|
| Nezapne aplikaci, ale má ji | ✅ Background heartbeat běží, OK |
| Odinstalace + reinstalace | ⚠️ Gap detekován, PENALTY |
| Změna data na telefonu | ⚠️ Server detekuje rozdíl, flaguje |
| Nový telefon (do 7 dnů) | ✅ Jiné device_id, grace period |
| Nový telefon (po 7 dnech) | ⚠️ Streak ztracen |
| Offline 1 den | ✅ Buffer 36h, OK |
| Offline 7 dní | ❌ Streak ztracen |

---

## 🗄️ SQL Schema

### Kompletní SQL pro Supabase

```sql
-- ============================================
-- 1. PROFILES
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. USER_SETTINGS
-- ============================================
CREATE TABLE user_settings (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Screen Time nastavení
    daily_limit_minutes INTEGER DEFAULT 120,
    warning_threshold_percent INTEGER DEFAULT 80,
    
    -- Family Controls metadata (ne tokeny!)
    has_apps_selected BOOLEAN DEFAULT FALSE,
    selected_apps_count INTEGER DEFAULT 0,
    selected_categories_count INTEGER DEFAULT 0,
    
    -- Notifikace
    notifications_enabled BOOLEAN DEFAULT TRUE,
    notification_at_50_percent BOOLEAN DEFAULT TRUE,
    notification_at_80_percent BOOLEAN DEFAULT TRUE,
    notification_at_100_percent BOOLEAN DEFAULT TRUE,
    
    -- Shield nastavení
    shield_enabled BOOLEAN DEFAULT TRUE,
    
    -- Časová okna
    schedule_start_hour INTEGER DEFAULT 0,
    schedule_start_minute INTEGER DEFAULT 0,
    schedule_end_hour INTEGER DEFAULT 23,
    schedule_end_minute INTEGER DEFAULT 59,
    
    -- Víkendové nastavení
    weekend_limit_minutes INTEGER DEFAULT 180,
    weekend_different_limit BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. USER_PROGRESS (streak & avatar)
-- ============================================
CREATE TABLE user_progress (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Streak
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_successful_date DATE,
    
    -- Avatar
    avatar_level INTEGER DEFAULT 1,
    avatar_xp INTEGER DEFAULT 0,
    avatar_xp_to_next_level INTEGER DEFAULT 100,
    avatar_stage TEXT DEFAULT 'egg' 
        CHECK (avatar_stage IN ('egg', 'baby', 'teen', 'adult', 'master')),
    
    -- Statistiky
    total_successful_days INTEGER DEFAULT 0,
    total_failed_days INTEGER DEFAULT 0,
    total_xp_earned INTEGER DEFAULT 0,
    
    -- Anti-cheat
    last_heartbeat TIMESTAMPTZ,
    streak_verified_at TIMESTAMPTZ DEFAULT NOW(),
    suspicious_activity_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. STREAK_HISTORY (denní log)
-- ============================================
CREATE TABLE streak_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    was_successful BOOLEAN NOT NULL,
    
    limit_minutes INTEGER NOT NULL,
    actual_usage_minutes INTEGER NOT NULL,
    usage_percent DECIMAL(5,2) NOT NULL,
    
    xp_earned INTEGER DEFAULT 0,
    xp_bonus_reason TEXT,
    
    -- Anti-cheat
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    server_verified_at TIMESTAMPTZ DEFAULT NOW(),
    device_date DATE,
    timezone TEXT,
    
    UNIQUE(user_id, date),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. HEARTBEAT_LOG
-- ============================================
CREATE TABLE heartbeat_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    heartbeat_at TIMESTAMPTZ DEFAULT NOW(),
    
    shield_active BOOLEAN NOT NULL,
    apps_selected_count INTEGER NOT NULL,
    current_usage_minutes INTEGER NOT NULL,
    daily_limit_minutes INTEGER NOT NULL,
    
    device_id TEXT,
    app_version TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY (všechny tabulky)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE heartbeat_log ENABLE ROW LEVEL SECURITY;

-- Policies: users can only access their own data
-- (SELECT, INSERT, UPDATE for each table where auth.uid() = id/user_id)
```

---

## 📱 Swift implementace

### Struktura souborů

```
Clif/Supabase/
├── SupabaseConfig.swift         # Konfigurace klienta
├── Models/
│   ├── Profile.swift            # Uživatelský profil
│   ├── UserSettings.swift       # Nastavení
│   ├── UserProgress.swift       # Streak & avatar
│   └── AvatarStage.swift        # Enum pro stage avatara
└── Views/
    └── SupabaseTestView.swift   # Testovací UI (MV pattern)
```

### Background Heartbeat

```swift
// Info.plist
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.clif.heartbeat</string>
</array>

// HeartbeatService.swift
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.clif.heartbeat",
    using: nil
) { task in
    // Odešli heartbeat na server
    // Naplánuj další za 4 hodiny
}
```

---

## 🔧 Supabase Setup Checklist

1. [ ] Vytvořit projekt na supabase.com
2. [ ] Spustit SQL schema (výše)
3. [ ] Nastavit RLS policies
4. [ ] **Authentication → Providers → Email**: Vypnout "Confirm email" pro dev
5. [ ] Přidat URL a anon key do `SupabaseConfig.swift`
6. [ ] Přidat `Supabase` SPM package do projektu

---

## 📄 License

*TBD*
