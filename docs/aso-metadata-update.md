# ASO — návod na výměnu App Store metadat (s buildem 11)

> Vychází z keyword researche 2026-06-11 (Astro MCP, US store) — detaily v [RESTART.md](../RESTART.md) sekce 3.
> **Klíčové pravidlo:** Title, Subtitle, Keywords i Description jdou změnit JEN při submitu nové verze appky.
> Jediná výjimka: **Promotional Text** — ten jde přepsat kdykoliv, i hned teď (ale neindexuje se do vyhledávání, je čistě konverzní).

---

## Co se mění a na co

| Pole | Limit | Současný stav | Nová hodnota | Proč |
|---|---|---|---|---|
| **App Name (Title)** | 30 | `Uuumi: Screen Time Pet` (22) | **beze změny** | "screen time" (pop 50) + "pet" v nejsilnějším slotu, niche fráze "screen time pet" je naše kategorie |
| **Subtitle** | 30 | `Stop Doomscroll & Bad Habits` | `App Blocker, Focus & Habits` (27) | "doomscroll" má popularitu 5–6 = nikdo to nehledá. Náhrada pokrývá `app blocker` (50/60), `focus` (62/63), `habits` (~44–60) |
| **Keywords** | 100 | *(neznámý — opsat z ASC před přepsáním!)* | `brainrot,tamagotchi,detox,dopamine,digital,wellbeing,block,limit,phone,addiction,study,timer` (92) | viz tabulka dat níže |
| **Promotional Text** | 170 | ? | volitelně, viz níže | jde změnit hned, bez nové verze |

### Přesné stringy ke zkopírování

Subtitle:
```
App Blocker, Focus & Habits
```

Keyword field (bez mezer za čárkami — mezery žerou znaky, Apple je nepotřebuje):
```
brainrot,tamagotchi,detox,dopamine,digital,wellbeing,block,limit,phone,addiction,study,timer
```

Volitelný Promotional Text (jde nasadit ještě dnes, bez submitu):
```
Your pet feels your screen time. Block distracting apps, beat brainrot, and keep your Uuumi alive — one calm day at a time.
```

### Pravidla keyword fieldu (proč vypadá takhle)

- **Neopakovat slova z Title a Subtitle** — Apple je už indexuje, opakování = vyhozené znaky. Proto tam není "screen", "time", "pet", "blocker", "focus", "habits", "app".
- Apple **kombinuje slova napříč poli** — `block` + `tiktok` není potřeba jako fráze; `digital` + `detox` pokryje "digital detox", `dopamine` + `detox` pokryje "dopamine detox" atd.
- Jednotné/množné číslo netřeba duplikovat, Apple to zvládá.
- `brainrot` psát jako JEDNO slovo (pop 54) — dvouslovné "brain rot" má pop jen 7.

### Otevřené rozhodnutí

- [ ] Přidat `unrot` (pop 47, difficulty 46)? Je to **jméno konkurenční appky** — funguje to a spousta apek to dělá, ale je to šedá zóna (riziko App Review je malé, spíš etická otázka). Vejde se: 92 + 6 = 98/100.

---

## Kde co kliknout v App Store Connect

1. **Vytvoř novou verzi:** App Store Connect → Apps → Uuumi → záložka **App Store** → vlevo nahoře u "iOS App" klikni **(+)** → zadej novou verzi, např. **1.1** (Apple vyžaduje vyšší marketing verzi než live 1.0; samotný build number nestačí).
2. **Subtitle:** levý sidebar → **App Information** (sekce General). Pole **Subtitle** se odemkne, jakmile existuje verze ve stavu "Prepare for Submission". Přepiš a ulož. (Title je hned vedle — neměníme.)
3. **Keywords:** zpátky na stránku verze **1.1 Prepare for Submission** → scrollni k poli **Keywords** (vedle Description / Support URL). ⚠️ **Před přepsáním si zkopíruj současný obsah** — po submitu se k němu nejde vrátit a chceme mít diff pro vyhodnocení.
4. **Promotional Text:** tamtéž na stránce verze, pole **Promotional Text** — tohle jde uložit a publikovat **okamžitě i bez nové verze** (propíše se na live 1.0).
5. **What's New:** vyplň release notes pro 1.1.
6. Zbytek (screenshoty, description) beze změny — description se do vyhledávání neindexuje, řešit až někdy jindy.

---

## Vazba na build 11 / verzi 1.1 (checklist před archivací)

Metadata pojedou spolu s code změnami v jednom submitu:

- [ ] **Onboarding fix:** úprava family_controls obrazovky (drop 27→6, viz RESTART.md sekce 2.1) — návrh zatím není hotový.
- [ ] **Marketing version bump v Xcode:** `MARKETING_VERSION` 1.0 → 1.1 ve **všech 5 targetech** (host + 4 extensiony) — stejný lockstep princip jako CURRENT_PROJECT_VERSION.
- [ ] **Build bump:** `CURRENT_PROJECT_VERSION` 10 → 11, opět 10 výskytů napříč všemi targety (viz commit ab5dfc4).
- [ ] **Ověřit time-sensitive entitlement** v Signing & Capabilities (⚠️ z RESTART.md 1.2 — jestli se capability propsala do App ID / provisioning profilů).
- [ ] Po schválení 1.1: sledovat ranking tracknutých keywords v Astru (44 keywords, US) — vyhodnotit po ~2–4 týdnech.

---

## Mimo metadata — největší ASO páka: první US reviews

Na "screen time pet" jsme #29 i s přesnou frází v title; konkurenti s 1–3 ratings jsou top 5. **Uuumi má v US storu 0 hodnocení.** Bez aspoň pár ratings nás metadata sama nevytáhnou.

Nápady (zatím nerozhodnuto):
- [ ] In-app review prompt (`SKStoreReviewController` / `requestReview`) v dobrém momentu — např. po prvním splněném denním limitu nebo po evoluci peta (pozitivní emoce). Smí se max 3× ročně, načasování je klíčové.
- [ ] Požádat stávající aktivní uživatele (~6 lidí prošlo onboardingem) / TestFlight testery s US účtem.

---

## Referenční data (US, 2026-06-11, popularita/difficulty)

| Keyword | Pop | Diff | Poznámka |
|---|---|---|---|
| focus | 62 | 63 | v novém subtitle |
| tamagotchi | 54 | 56 | keyword field |
| **brainrot** | **54** | **48** | nejlepší poměr ve vysokém volume; keyword field |
| screen time control | 52 | 62 | "screen time" pokryto title |
| screen time | 50 | 62 | v title |
| app blocker | 50 | 60 | v novém subtitle |
| pomodoro timer | 50 | 62 | jen "timer" v keyword field |
| unrot | 47 | 46 | jméno konkurence — nerozhodnuto |
| digital detox | 23 | 43 | sweet spot; digital+detox v keyword field |
| digital wellbeing | 21 | 52 | wellbeing v keyword field |
| dopamine detox | 20 | 45 | sweet spot; dopamine v keyword field |
| doomscroll | 6 | 23 | ❌ vyřazeno ze subtitle |
| doomscrolling | 5 | 61 | ❌ mrtvý keyword |
| phone addiction | 5 | 65 | phone+addiction v keyword field (kombinace zadarmo) |
| screen time pet | 5 | 55 | naše niche fráze, rankujeme #29 (cíl: top 3) |
