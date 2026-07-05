# UX & konverzní audit — 2026-07-03

> Hloubkový průchod celé appky (onboarding, monetizace, denní loop, retence) třemi průzkumnými agenty + syntéza s produkčními analytickými daty. Cíl: co zjednodušit, kde přitvrdit, co opravit pro dlouhodobou konverzi.
>
> **Kontext z dat (produkce):** drop-off je jen na Screen Time permission (fix shipnut v 1.1). Kdo projde, dojede onboarding celý a retence jádra je výborná (pety cyklí týdně, měsíce). 2 reálné nákupy. 0 US ratings. Vzorek je malý — závěry níže stojí na čtení kódu, ne na statistice.

---

## TL;DR — tři věci, které appku drží zpátky

1. **Premium nemá co prodávat.** Jediná tvrdá brána je Committed Break + kosmetika. Evoluce projde zdarma přes „Evolve anyway", celý katalog essencí je odemknutelný coiny zdarma. Hodnota premium = „+5 coinů za evoluci". → potvrzeno „jsem moc hodnej".
2. **Když uživatel odejde, nikdy se nedozví, že se má vrátit.** Neexistuje jediná re-engagement notifikace. Po ztrátě peta se navíc **všechny notifikace zruší** a uživatel skončí ve slepé uličce (Replay/Delete). Ticho.
3. **Onboarding je delší a přegatovanější, než spec zamýšlel** (13 obrazovek místo 11, wind mechanika učená 3×, blow-away animace v onboardingu v přímém rozporu se spec, ~10 s vynucených čekání).

---

## A. MONETIZACE — kde jsi „moc hodnej" 🔴 P0

### Nálezy (fakta z kódu)

| # | Nález | Kde |
|---|---|---|
| A1 | **Evoluce je fakticky zdarma.** Upsell sheet má tlačítko „Evolve anyway" / „Apply anyway" — free uživatel projde vždy, premium kupuje jen 2× coiny (10 vs 5). | HomeScreen.swift:663-690, EvolutionUpsellSheet.swift:35-46 |
| A2 | **Celý katalog essencí je dosažitelný za 0 Kč.** Free uživatel earnuje coiny (5/evoluci) a `purchaseEssence` nemá žádný premium check. Essence 150–250 coinů ≈ 3–5 dokončených petů grind. | EssenceCatalogManager.swift:41-46, Essence.swift:52-69 |
| A3 | **Pet limit z monetizačního plánu neexistuje** (plán: unlimited pets = premium). Žádný gate v PetManager. | monetization-plan.md:22 vs PetManager.swift |
| A4 | **Paywall nemá žádnou urgenci** — žádný intro offer, countdown, „limited". Jen X pro zavření. Trial copy jen u yearly. | PremiumSheet.swift |
| A5 | Jediné reálné brány: Committed Breaks (+ jejich coiny), stats rozsahy >7 dní, kosmetika (themes, Dynamic Sky), trend chart. | BreakTypePicker.swift:65-81 aj. |
| A6 | A/B test plán (weekly produkt, varianty) je 100% neimplementovaný TODO. | docs/paywall-ab-test-plan.md |

### Doporučení

- **A-fix-1 (klíčové): Premium = celý katalog essencí odemčený.** Teď je hodnota premium mlhavá („2× coiny"). Nabídka „všechny evoluční cesty hned vs. týdny grindu" je konečně srozumitelná věta. Coiny zůstávají jako poctivá free cesta (pomalá) — nic se nebere, premium se stává zkratkou, jak plán zamýšlel, ale s jasnou prezentací. Změny: PremiumSheet hero copy („Unlock every evolution path"), EssenceUnlockSheet primární CTA = premium (coiny sekundární), feature list. **Effort: M**
- **A-fix-2: Konverzní moment = dokončení prvního peta.** Uživatel dokončil Plant (8 fází, ~8 dní, engaged jak nikdy) → SuccessArchiveSheet → tam patří premium nabídka „vyber si další cestu" s náhledem essencí, ne generický paywall po vytvoření peta. **Effort: M**
- **A-fix-3: Upsell sheets u evoluce zrušit nebo zeslabit.** Interstitial před KAŽDOU evolucí (denní akce!) za +5 coinů je otravný a levný zároveň — trénuje uživatele paywally zavírat. Nechat evoluci čistou, prodávat na essence catalog momentu. **Effort: S**
- ⚠️ **Neměnit ceny/model plošně teď** — vzorek 2 nákupů nic neříká (viz RESTART.md 2.3). Výše uvedené je zostření prezentace hodnoty, ne experiment s cenami.

---

## B. RETENCE — chybějící návratové háčky 🔴 P0

### Nálezy

| # | Nález | Kde |
|---|---|---|
| B1 | **Žádná re-engagement notifikace neexistuje** (lapsed user, we-miss-you, streak-broken — nula). Všechny notifikace vyžadují aktivní používání týž den. | grep celé codebase |
| B2 | **Po blow-away se všechny notifikace zruší** (`cancelAll`) — uživatel, který ztratil peta a zavřel appku, už nikdy nic nedostane. Přesně v nejrizikovějším momentu. | PetManager.swift:204-205 |
| B3 | **Slepá ulička po ztrátě:** blown state nabízí jen „Replay" a „Delete". Po delete/archive prázdný ostrov → uživatel musí sám iniciovat celý 3-krokový create flow, nový pet je blob s 1denní čekačkou na essence. | HomeCardView.swift:352-380, CreatePetCoordinator.swift |
| B4 | **„Streak" je fake** — je to věk peta (`totalDays`), ne série splněných dní. Nejde přerušit, nemá odměnu, nemá cíl. | PetEvolvable.swift:35-43, HomeScreen.swift:586 |
| B5 | Žádný widget / Live Activity — vítr a pet nejsou vidět mimo appku. | grep: 0 výskytů WidgetKit/ActivityKit |
| B6 | Dobré: evolution-ready notifikace (random 8–18 h) + daily summary jsou solidní denní háčky, default ON. | ScheduledNotificationManager.swift |

### Doporučení

- **B-fix-1 (nejlevnější/nejvyšší dopad): re-engagement notifikace.** Při odchodu do pozadí naplánovat lokální notifikace na +2 dny a +5 dní („[Jméno] čeká na ostrově… vítr je dnes klidný") a zrušit je při foregroundu. **Effort: S**
- **B-fix-2: Po blow-away neomlčovat — obrátit.** Nerušit vše, ale naplánovat „nový společník čeká" (+1 den). A po Delete/Archive rovnou otevřít create-pet flow místo prázdného ostrova. **Effort: S**
- **B-fix-3 (později): skutečný streak** — série dní pod limitem, s milníky a odměnami (coiny), reset při překročení. Velká změna, chce design. **Effort: L, mimo build 12**
- **B-fix-4 (později): widget s petem a větrem** — ambient přítomnost na home screen. Nový target. **Effort: L**

---

## C. ONBOARDING — délka a friction 🟠 P1

### Nálezy

| # | Nález | Kde |
|---|---|---|
| C1 | **13 obrazovek** (spec: 11) — login se přesunul dovnitř jako screen 13, progress ukazuje 13 teček. | OnboardingScreen.swift:19-35 |
| C2 | **Wind mechanika učená 3× za sebou** (wind → slider → lock demo). | screens 3, 6, 7 |
| C3 | **Blow-away + rewind sekvence v onboardingu je v rozporu se spec** („No blow-away animation… reserved for real gameplay") — drag na ≥95 % s drag-resistencí, animace odletu, 1,5 s čekání, Rewind tap, další typewriter. Nejdelší a nejvíc gatovaná obrazovka. | OnboardingWindSliderStep.swift:161,469-592 vs spec:108 |
| C4 | **Vynucená čekání:** island 1,0 s sleep; data step 0,6+0,8 s; lock demo 4,0 s skriptovaná animace před Continue. | OnboardingIslandStep.swift:76, OnboardingDataStep.swift:46-53, OnboardingLockStep.swift:22,355-377 |
| C5 | **Essence drag nemá tap fallback** (spec ho u dropu vyžadoval — accessibility + App Review riziko). | OnboardingEssenceStep.swift:249-273 |
| C6 | Mrtvý kód: OnboardingPlaceholderStep, `nonStoryLayout`, `implementedScreens`, `OnboardingAct`, `.description` — vše nedosažitelné. | OnboardingView.swift:248-262 |
| C7 | Drobnosti: „change it later" ujištění 3×; slíbená reakce peta na napsání jména neimplementovaná. | |

**Pozn. k datům:** downstream drop-off jsme v datech neviděli (n=6 — může být neviditelný). Zkrácení je tedy prevence + kvalita, ne oprava měřeného problému. Priorita až po A/B.

### Doporučení

- **C-fix-1: Vyříznout blow-away+rewind ze slider stepu** — slider končí na „scared na kraji ostrova" (jak chtěla spec). Ušetří ~20–30 s a nejfrustrovanější gate. **Effort: M**
- **C-fix-2: Zkrátit skriptovaná čekání** — lock demo 4,0→1,5 s, odstranit island 1,0 s sleep a data 1,4 s. **Effort: S**
- **C-fix-3: Tap fallback pro essence drag** (po 2 neúspěších „Tap to place"). **Effort: S**
- **C-fix-4: Smazat mrtvý kód** (C6). **Effort: S**
- **C-zvážit: sloučit lock demo do slideru** (po blow-away… po scared stavu rovnou „a teď ho zachraň — tap lock") → z 13 na 12 obrazovek. **Effort: M**

---

## D. DENNÍ LOOP — zjednodušení 🟡 P2

| # | Nález | Doporučení |
|---|---|---|
| D1 | Ranní preset picker: v appce 1 tap (OK), ale přes shield 3 tapy + přeskok přes notifikaci. | Zvážit „Stejně jako včera" quick action přímo v shield notifikaci (notification action) — den začne bez otevření appky. Effort: M |
| D2 | Evoluce vyžaduje: vítr = 0 + po random unlock času + manuální tap + (upsell sheet). Čtyři podmínky pro core odměnu. | Upsell pryč (A-fix-3) to zjednoduší na polovinu. |
| D3 | Free break nikdy neexpiruje — uživatel na něj může zapomenout a appka je fakticky vypnutá donekonečna. | Zvážit max délku free breaku / připomínku po X hodinách. Effort: S |

---

## Návrh pro build 12 (seřazeno podle poměru dopad/úsilí)

1. **B-fix-1** Re-engagement notifikace (+2 d, +5 d) — S
2. **B-fix-2** Blow-away/archive: neomlčovat, navést na nového peta — S
3. **A-fix-3** Zrušit evolution/essence upsell interstitial — S
4. **A-fix-1** Premium = plný katalog essencí + nové paywall copy — M
5. **A-fix-2** Premium moment po dokončení prvního peta (SuccessArchiveSheet) — M
6. **C-fix-2/3/4** Onboarding: zkrátit čekání, tap fallback, mrtvý kód — S
7. **C-fix-1** Vyříznout blow-away z onboarding slideru — M

## Později (po buildu 12)

- Skutečný streak s odměnami (B-fix-3)
- Widget / Live Activity (B-fix-4)
- „Stejně jako včera" v shield notifikaci (D1)
- Paywall A/B test podle docs/paywall-ab-test-plan.md — až bude traffic
- Sloučení lock demo + slider (C-zvážit)
