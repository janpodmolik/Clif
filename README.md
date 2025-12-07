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

## 📄 License

*TBD*
