# Uuumi 🧗

> *Screen time management through emotional connection*
> *Správa času u obrazovky skrze emoční propojení*

---

## 🎯 Koncept

Uuumi je iOS aplikace, která pomáhá omezit čas strávený v rozptylujících aplikacích vytvořením záměrné bariéry a emoční motivace prostřednictvím vyvíjející se postavy.

**Inspirace:** ScreenZen, Brainrot, Opal

### Základní mechaniky

- Vyber aplikace, které chceš omezit
- Nastav denní limit
- **Vizuální metafora**: Postava je tlačena k okraji útesu, jak spotřebováváš svůj denní limit
- **Dodržíš limity** → Postava se vyvíjí do vyšších forem
- **Překročíš limity** → Postava spadne z útesu, ztratí evoluční pokrok a začíná znovu

### Klíčové principy

- ❌ Žádné kredity, body ani podmíněné nákupy
- ✅ Motivace skrze **emoční zpětnou vazbu** a evoluci
- ✅ Riziko ztráty progresu vytváří skutečné sázky

---

## 🎨 Design Language

Aplikace používá **moderní iOS design** podle aktuálních Apple Human Interface Guidelines:

- **Materials & Vibrancy** - Průsvitné pozadí s blur efekty
- **SF Symbols** - Systémové ikony pro konzistentní vzhled
- **Dynamic Type** - Podpora škálování textu
- **Adaptive Colors** - Automatická podpora Dark Mode
- **Spatial Design** - Hloubka, stíny a 3D efekty (iOS 18+)

Inspirace designem z nativních iOS aplikací jako Health, Screen Time, a moderních fitness aplikací.

---

## 🛠️ Tech Stack

- **Platform:** iOS 18+
- **Language:** Swift 6
- **Frameworks:**
  - Screen Time API (DeviceActivity, FamilyControls, ManagedSettings)
  - SwiftUI
  - Supabase (Backend)
- **Architecture:** MV Pattern (Model-View)
- **Communication:** App Groups + UserDefaults

---

## 📋 Roadmap

### ✅ Implementováno

- Screen Time API integrace (monitoring, shield)
- DeviceActivityReport zobrazení
- Dynamic shield s progress indikátorem
- Supabase backend setup
- Debug view pro vývoj

### 🚧 V práci

- Nový ContentView design (čistý slate)
- Avatar & streak systém UI
- Moderní iOS design implementace

### 📝 Plánováno

- Heartbeat anti-cheat systém
- Onboarding flow
- Notifikace při dosažení limitů
- Avatar animace a evoluce

---

## 🔐 Backend

### Supabase

Backend řešení pro:
- Autentizaci uživatelů
- Ukládání nastavení
- Streak & avatar systém
- Anti-cheat mechanismy

### Databázové tabulky

- `profiles` - Uživatelské profily
- `user_settings` - Nastavení aplikace
- `user_progress` - Streak, avatar level, XP
- `streak_history` - Denní log pro streak tracking
- `heartbeat_log` - Anti-cheat monitoring

### Data Storage

| Data | Storage | Důvod |
|------|---------|-------|
| `FamilyActivitySelection` | Lokálně (App Group) | Device-specific tokeny |
| Nastavení & limity | Supabase | Synchronizace mezi zařízeními |
| Streak & avatar | Supabase | Anti-cheat, server-side validace |

---

## 🎮 Avatar & Streak Systém

### Avatar Evoluce

```
Level 1-4:   🥚 Egg
Level 5-14:  🐣 Baby
Level 15-29: 🐥 Teen
Level 30-49: 🐔 Adult
Level 50+:   🦅 Master
```

### XP & Streak Mechanika

- Splněný den (pod limitem): +10 XP, streak +1
- Využití < 50% limitu: +10 bonus XP
- Nesplněný den: streak reset na 0
- Vše počítáno na serveru s anti-cheat validací

---

## 🛡️ Anti-cheat

### Heartbeat Systém

- Background task každé 4 hodiny
- Detekuje odinstalaci aplikace
- 36h tolerance (pro offline/vypnutý telefon)
- Gap detection = penalty (ztráta XP a streak)

### Server-side Validace

- Server timestamp (ne device date)
- Heartbeat monitoring
- Suspicious activity tracking

---

## 📄 License

*TBD*
