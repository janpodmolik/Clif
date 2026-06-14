# Uuumi — Restart / Continuation Plan

> Pracovní TODO z restartu projektu po ~měsíční pauze (2026-06-08).
> Z tohoto filu vycházíme a postupně odškrtáváme. Sekce řazené zhruba podle priority.
> Stav kódu při sepsání: na `main`, posledně shippeno jako **build 10** (resubmit po rejection buildu 9).

---

## Kontext projektu (rychlé navnímání)

Uuumi = screen time blocker s virtuálním mazlíčkem na plovoucím ostrově (iOS 18+).
- **Wind system**: čím víc času v blokovaných appkách, tím silnější vítr na petovi. Wind řízen DeviceActivity threshold eventy.
- **Mechanika**: Mood (happy/neutral/sad) ← WindLevel ← wind %. Evolution přes Essence (Plant zdarma, Crystal/Flame/Water premium). Streak, Blow Away při překročení limitu.
- **Stav byznysu**: Live na App Store. ~4 měsíce vývoje, indie. Reálný dosah ~nulový. Onboarding má vysoký drop-off (viz PostHog níže). App update už nelze vydat → spoléháme na ASO + marketing.
- **Architektura**: MV (Model-View), `@Observable`. Hlavní app + 4 extensiony (DeviceActivityMonitor, DeviceActivityReport, ShieldConfiguration, ShieldAction).
- **Závislosti**: Supabase v2.38.0 (jediná externí). PostHog (analytics). StoreKit (premium).

---

## 1. BUGY NA STRANĚ APPLE (nejvíc otravné, blokují kvalitu produktu)

### 1.1 Burst threshold eventy → wind vyskočí o 80–100 % bez interakce uživatele 🟡 INVESTIGACE DOKONČENA — NEOPRAVUJEME Z NAŠÍ STRANY

> **Rozhodnutí (2026-06-08):** Tohle z naší strany NEopravujeme. Předchozí pokusy o client-side fix (dropování eventů) appce spíš uškodily — padaly i legitimní eventy, které se měly započítat, a způsobovalo to víc problémů než ten samotný Apple bug. Šlo čistě o **investigaci, jestli se Apple pohnul**. → Nepohnul (viz níže). Stav: **monitoring only**, žádný náš zásah do threshold pipeline.

**Symptom:** Uživatel dá telefon na nabíječku, celý den nebyl v limitovaných appkách, a najednou přijde nárazový (burst) event a wind skočí o 80–100 %. Není to způsobeno usage — je to chyba Apple Screen Time accountingu.

**Co už víme z kódu:**
- Troubleshooting copy pro uživatele: [TroubleshootingScreen.swift](Uuumi/Screens/Profile/TroubleshootingScreen.swift) — odkazuje na Apple forum thread **811305** a feedback **FB21450954**. Aktuálně to jen omlouvá jako "iOS 26.2 confirmed bug, Apple na tom pracuje".
- Threshold pipeline: [DeviceActivityMonitorExtension.swift](DeviceActivityMonitor/DeviceActivityMonitorExtension.swift) — entry `eventDidReachThreshold` (L95-131), parsuje `second_N`, baseline accounting (L46-62).
- Wind formula: [SharedDefaults+Wind.swift](Shared/Storage/SharedDefaults/SharedDefaults+Wind.swift#L143) — `wind = (cumulative - breakReduction) / limit * 100`.
- Threshold builder: [ScreenTimeManager.swift](Uuumi/Managers/ScreenTimeManager.swift#L354) `MonitoringEventBuilder.buildEvents` — 17 evenly-spaced + snap-to-limit + safety-net.
- **Existující obrany:** (a) out-of-order guard `currentSeconds > lastProcessed` (L116-121), (b) shield-active guard (L145-157), (c) `isMonitoringActive` proti zbytečným restartům (ScreenTimeManager L228).

**Proč existující obrany NESTAČÍ:** out-of-order guard chytí jen eventy *nižší* než poslední zpracovaný. Burst, který přijde jako jeden *vysoký* event (např. iOS nárazově naúčtuje 800s najednou po probuzení z nabíječky), projde — `currentSeconds` je vyšší než `lastProcessed`, takže se zpracuje a wind skočí.

**Výsledek investigace — pohnul se Apple?** ❌ NE (k 2026-06-08):
- Thread 719905 (ShieldAction, sledovaný i pro obecný Screen Time stav): žádná nová odpověď od Apple, jen čeká.
- Apple oficiálně potvrdil burst/over-reporting bug (viz troubleshooting copy odkazující na thread 811305 + FB21450954), ale **žádný fix neshippnul** a nedal ETA.
- Bug postihuje každou app postavenou na Screen Time API — není to specifické pro Uuumi.

**Proč to NEopravujeme (poznámka pro budoucí já):** Jakýkoliv client-side filtr na "podezřele velký" event nutně zahazuje i legitimní eventy. Apple accounting je nedeterministický — nedá se spolehlivě odlišit burst od reálného usage, které se naúčtovalo se zpožděním. Předchozí pokusy → víc dropnutých legitimních eventů → horší UX než samotný bug. Necháváme threshold pipeline tak, jak je.

**Co zbývá (pasivní):**
- [ ] Občas zkontrolovat thread 811305 / FB21450954, jestli Apple neshippnul fix. Pokud ano → odstranit troubleshooting omluvnou copy.

**Update 2026-06-10 — přidána flag-only vrstva (NEfiltruje, jen označuje):**
- Extension detekuje fyzikálně nemožné skoky (usage delta > wall-clock elapsed + 120s slack v rámci burst skupiny) — `detectWindAnomaly` v DeviceActivityMonitorExtension. Event se VŽDY zpracuje normálně, jen se označí.
- Nový snapshot event typ `windAnomaly(jumpSeconds:)` (zpětně kompatibilní — starší verze dekódují jako `.unknown`).
- SafetyUnlockSheet nabízí "Unlock — wind glitch" (omilostněný unlock bez ztráty peta, odpustí anomální sekundy přes break reduction), rate-limit 1× za 7 dní (`AppConstants.anomalyPardonCooldown`).
- PostHog eventy `wind_anomaly_detected` + `wind_anomaly_pardoned` → data o prevalenci pro FB21450954.

---

### 1.2 ShieldAction nemůže otevřít host app → řešeno přes notifikaci 🟡 VYŘEŠENO (workaround), čeká na Apple

**Symptom:** ShieldActionExtension nemá supported API pro otevření containing app. Původně řešeno přes `LSApplicationWorkspace` (private API) → **Apple rejectnul build 9** (guideline 2.5.1).

**Stav:** Už opraveno v buildu 10 (commit 62bbc97) — nahrazeno **local-notification deep-link** patternem (tap Unlock → naplánuje notifikaci → tap notifikace → `uuumi://shield` / `uuumi://preset-picker` → DeepLinkRouter). Implementace v [ShieldActionExtension.swift](ShieldAction/ShieldActionExtension.swift).

**Research výsledek (Apple forum thread 719905, ověřeno 2026-06-08):**
- Apple Frameworks Engineer (Nov 2022, reaffirmed Jan 2025): *"There's no supported way for your extension to open your main app with the APIs currently available."* → file enhancement request.
- **Žádný public API se nechystá.** K thread 719905 přibyla nová zpráva (FB22696417, May 2026) žádající `ShieldActionResponse.openContainingApp`, ale **Apple zatím nic neslíbil** (jen 4 palečky, žádná odpověď).
- Tvoje vlákno s LSApplicationWorkspace rejection je tam zdokumentované. Pattern, který teď máš (notifikace), je **jediná schválitelná cesta** — používá ho i Opal.

**Akce:**
- [ ] Žádná code akce nutná — workaround je správný a shippnutý. Jen sledovat Apple thread 719905 / FB22696417 pro případný budoucí public API.
- [x] ~~(Volitelně) zlepšit UX notifikačního flow~~ → hotovo 2026-06-10:
  - **`.timeSensitive` na unlock notifikaci** — největší nález: Focus režimy tichou default notifikaci schovaly → "ťukl jsem Unlock a nic se nestalo". Wind notifikace `.timeSensitive` už používaly, ale BEZ entitlementu → přidán `com.apple.developer.usernotifications.time-sensitive` do ShieldAction + obou DeviceActivityMonitor entitlements. **⚠️ Ověřit v Xcode Signing & Capabilities, že se capability propsala do App ID / provisioning profilů.**
  - Main app cachuje stav notifikačních oprávnění do SharedDefaults na každém foregroundu; ShieldConfiguration při odepřených notifikacích mění subtitle na instrukci k manuálnímu otevření.
  - ShieldSettingsScreen ukazuje warning s deep-linkem do nastavení, když jsou notifikace vypnuté.

---

## 2. ANALYTICS & RETENCE (proč nám lidé odpadají)

### 2.1 Napojit PostHog MCP a projít onboarding funnel 🟠

**Stav:** PostHog je v appce zapojený ([PostHogConfig.swift](Uuumi/Auth/PostHog/PostHogConfig.swift), EU host, project key `phc_n2kBBPZ...`). Eventy definované v [AnalyticsManager.swift](Uuumi/Managers/AnalyticsManager.swift): `onboarding_started`, `onboarding_screen_viewed(step)`, `family_controls_authorized`, `onboarding_completed`, atd.
- **MCP zatím NENÍ v [.mcp.json](.mcp.json)** — jsou tam jen `supabase` a `context7`. PostHog MCP je potřeba přidat.

**Akce:**
- [x] ~~Přidat PostHog MCP server do `.mcp.json`~~ → hotovo 2026-06-11, ověřeno: projekt "Uuumi iOS" (id 168579, EU), všechny onboarding eventy v datech existují.
- [x] ~~Postavit funnel~~ → hotovo 2026-06-11. **Výsledek (all-time, 2026-04-28 → 2026-06-11, 26 uživatelů):**
  - `onboarding_started` 26 → `family_controls_authorized` 6 (23 %) → `onboarding_completed` 4 (15 %).
  - Per-screen breakdown (`onboarding_screen_viewed.step`, unique users): welcome 27 → meet_pet 27 → **family_controls 27 → app_selection 6** — JEDINÝ drop v celém flow. Všechny obrazovky po permission (data, essence, evolution, lock, login, notifications, pet_naming, review, wind_preset, wind_slider) mají 6 = nulová ztráta downstream.
  - `family_controls_authorized` breakdown by `granted`: true=6, false=2.
  - **⚠️ Korekce interpretace (2026-06-11, z kódu):** event `step: "family_controls"` se posílá **při tapu na CTA "Show my screen time"** (OnboardingWindStep.requestPermission), ne při zobrazení obrazovky. Takže všech 27 lidí na CTA ochotně kliklo a **Apple system dialog reálně vidělo** — ale jen 8 na něj odpovědělo (6 allow / 2 deny). **19 lidí (70 %) appku u system dialogu zabilo/opustilo** (`AuthorizationCenter.requestAuthorization` se nikdy nevrátil → žádný event). Killer je šok z Apple promptu ("…may allow it to see your activity data, restrict content…"), ne naše obrazovka.
- [x] ~~Hypotéza: Screen 3 (Screen Time permission)~~ → **POTVRZENA datově.** Screen 7 (notifikace) a auth/paywall sheets jsou nevinné — tam už nikdo neodpadá.
- [x] **Fix implementován (2026-06-11, do buildu 11):**
  - **Dialog preview card** v OnboardingWindStep — neinteraktivní náhled Apple promptu nad CTA ("Next, iOS will ask for permission" + mock s zvýrazněným Continue), aby system dialog nebyl šok. Pattern používá i Opal/one sec.
  - **Analytics zpřesnění:** (a) nový event `step: "wind"` na appear obrazovky (konečně oddělíme "došel na obrazovku" od "tapnul CTA"), (b) `AnalyticsManager.flush()` (→ `AppPostHog.flush()`) hned po tap eventu a po výsledku autorizace — eventy přežijí kill appky u dialogu, takže v build 11 datech půjde abandon přesně kvantifikovat.

### 2.2 Napojit Supabase MCP 🟢

**Stav:** Supabase MCP **už je** v [.mcp.json](.mcp.json) (`https://mcp.supabase.com/mcp`). Backend integrace v [SupabaseConfig.swift](Uuumi/Auth/Supabase/SupabaseConfig.swift).

**Akce:**
- [x] ~~Ověřit, že MCP je autentizované a funkční~~ → hotovo 2026-06-11: projekt "Uuumi" (owodjfgrmtltmfpqvlot, eu-west-3) ACTIVE_HEALTHY. Tabulky: active_pets (6), archived_pets (20), user_data (8), pending_rewards (0), feedback (0), RLS všude zapnuté.
- [ ] (Pak) zkřížit PostHog funnel s reálnými user záznamy v Supabase.

### 2.3 Datová hygiena — vzorek je malý a znečištěný testováním 🟠 (zjištěno 2026-06-12)

**Nález:** Eventy nesou `environment` (production/staging/development). Po přefiltrování na produkci: z 29 `purchase_completed` zbyly **2** (zbytek = sandbox/dev testování), z 498 květnových `break_started` velká část taktéž. **Onboarding funnel (26→6→4) je naštěstí produkční** — ta čísla platí. Supabase ale `environment` sloupec NEMÁ → 4 "power users" cyklící pety (23× completed evoluce, ~6–8 dní/pet, aktivní duben–červen) nejdou odlišit od kamarádů-testerů.

**Důsledek:** Vzorek (~20 reálných lidí + testeři) NEstačí na posuzování herních mechanik — žádné změny wind/evoluce/streak na základě těchto dat. Co obstojí: onboarding drop (binárně obrovský efekt) a ASO data (nezávislá na našem vzorku).

**Akce (datová hygiena do buildu 11):**
- [ ] PostHog: nastavit project-level "Filter out internal and test users" na `environment = production` (+ ideálně `$is_testflight = false`), aby všechny insighty byly defaultně čisté.
- [ ] Supabase: přidat `environment`/`is_tester` značku do `user_data` (zapisovat z appky podle DEBUG/TestFlight detekce), aby šli testeři oddělit i v DB.
- [ ] `feedback` tabulka má **0 řádků** za celou dobu — ověřit, že feedback UI funguje a je k nalezení. Při malém vzorku je kvalitativní feedback cennější než analytika.

---

## 3. APP STORE OPTIMALIZACE (ASO) — reálný dosah ~nulový 🟠

**Stav:** Astro MCP je dostupné (`mcp__astro__*`). **ALE: Uuumi sama NENÍ v Astro trackovaná** — sledují se jen cizí/referenční appky (Paired, Daylio, stoic, ...). Uuumi je potřeba nejdřív přidat (`mcp__astro__add_app`).

**Problém s minulou ASO:** Předchozí nástroj doporučil **"doomscrolling"** jako super keyword. Tvůj pocit: je to celé špatně, reálný dosah nulový. → Chceme ASO **od nuly přehodnotit**.

**Akce:**
- [x] ~~`mcp__astro__add_app`~~ → hotovo 2026-06-11. **App Store ID 6759179018** ("Uuumi: Screen Time Pet", subtitle "Stop Doomscroll & Bad Habits"). Trackujeme 44 keywords (US).
- [x] ~~Zkontrolovat ranking pro "doomscrolling"~~ → **HYPOTÉZA POTVRZENA, keyword je mrtvý:** `doomscrolling` popularita **5** (= prakticky nulový volume), difficulty 61. `doomscroll` 6/23. `stop doomscrolling` 5/13 (rankujeme #118). Subtitle utrácí nejsilnější ASO slot za keyword, který nikdo nehledá.
- [x] ~~Keyword research~~ → hotovo. **Data (popularita/difficulty, US, 2026-06-11):**
  - Vysoký volume: `focus` 62/63, `tamagotchi` 54/56, **`brainrot` 54/48 (nejlepší poměr ve vysokém volume!)**, `screen time control` 52/62, `screen time` 50/62, `app blocker` 50/60, `pomodoro timer` 50/62, `unrot` 47/46 (pozn.: jméno konkurenční appky), `habit` ~60.
  - Střední volume, nižší difficulty (sweet spot pro indie): `digital detox` 23/43, `digital wellbeing` 21/52, `dopamine detox` 20/45.
  - Nízký volume (pop 5–9): všechny doomscroll varianty, `phone addiction`, `block tiktok`, `touch grass`, `focus pet`, `brain rot` (dvě slova — jednoslovné `brainrot` má 54!).
- [x] **Objev: micro-niche "screen time pet" už má konkurenci, která nás poráží na vlastní frázi.** Na "screen time pet" jsme **#29**, přitom máme přesnou frázi v title. Před námi: #1 Screencat – Screen Time Pet ("Stop Doomscrolling", 1 rating), #2 Yeti: Screen Time Pet (3 ratings), #4 Habitopia: Screen Time Pet ("Quit Doomscroll, Build Habits", 3 ratings). Všichni jsou stejně malí — pravděpodobná příčina našeho propadu: **0 ratings v US storu** (CZ má 1× 5.0) + nulové downloads velocity. → Získat první US reviews je možná největší ASO páka vůbec.
- [ ] **Doporučená nová metadata (do buildu 11)** — návod: [docs/aso-metadata-update.md](docs/aso-metadata-update.md), copy-paste hodnoty: [docs/aso-copy-paste.md](docs/aso-copy-paste.md):
  - Title (beze změny, 22/30): `Uuumi: Screen Time Pet`
  - Subtitle (27/30): `App Blocker, Focus & Habits` — nahradí doomscroll za 3 keywords s pop 44–62.
  - Keyword field (98/100, unrot schválen 2026-06-11): `brainrot,tamagotchi,detox,dopamine,digital,wellbeing,block,limit,phone,addiction,study,timer,unrot`
  - Pozn.: title/subtitle/keyword field jdou změnit JEN s novou verzí → spáruje se s onboarding fixem v buildu 11.
- [ ] Sledovat `mcp__astro__get_app_ratings` pro feedback signály (zatím není co — 0 US ratings).
- [ ] (Volitelně, později) `get_keyword_suggestions` vrátilo prázdno — zkusit znovu, až Astro appku zaindexuje.

---

## 5. SKUTEČNÉ ÚPRAVY / BUGY OD UŽIVATELE (doplní se v další iteraci) ⏳

> ~~Tohle jsou ty úpravy, o které ti reálně jde~~ → **Uzavřeno 2026-06-11: žádné další úpravy/bugy nejsou.** Build 11 = onboarding fix (family_controls) + review prompt + nová ASO metadata.

---

## 4. MARKETING (kontext, nižší priorita teď)

**Stav (z [marketing/petisland_handoff.md](marketing/petisland_handoff.md)):**
- Funguje: vulnerability + underdog + konkrétní stake (video "4 months building, nobody wants to test" → 1.8k views).
- Floppe: abstraktní hooky bez kontextu ("DON'T LOSE" → 130/193/83 views).
- YouTube Shorts jde nejlíp, cíl prorazit na TikToku.
- Differentiator: permanentní ztráta peta + denní rituál evoluce (vs. Forest = strom bez emoční váhy, Apple Screen Time = "Ignore Limit" = nulový stake).

**Akce:** Zatím necháváme. Po ASO + bug fixu se k tomu vrátit.

---

## Pořadí práce (návrh)

1. ~~Bug 1.1 (burst wind)~~ — ✅ investigace hotová, neopravujeme (jen pasivní monitoring Apple).
2. ~~Bug 1.2 (ShieldAction)~~ — ✅ investigace hotová, workaround správný, žádný posun u Apple.
3. ~~PostHog MCP + onboarding funnel~~ — ✅ hotovo 2026-06-11. Drop = family_controls permission screen (27→6), zbytek flow bez ztrát.
4. ~~Supabase MCP ověřit~~ — ✅ hotovo 2026-06-11, funkční, projekt ACTIVE_HEALTHY.
5. ~~ASO od nuly~~ — ✅ research hotový 2026-06-11. "Doomscrolling" datově pohřben (pop 5). Nová metadata navržena (viz sekce 3), čekají na build 11. Zbývá: získat první US reviews.
6. **Sekce 5 (úpravy od uživatele)** — až doplníš konkrétní seznam.
7. Marketing — později.

---

## Reference

- Apple forum (ShieldAction → host app): https://developer.apple.com/forums/thread/719905
- Apple forum (burst wind bug): thread 811305, FB21450954
- ShieldAction enhancement request: FB17261679, FB22696417
- Onboarding spec: [ai-rules/onboarding-flow.md](ai-rules/onboarding-flow.md)
- Wind system rules: [ai-rules/wind-system.md](ai-rules/wind-system.md), [ai-rules/screen-time-api.md](ai-rules/screen-time-api.md)
- Monetizace: [docs/monetization-plan.md](docs/monetization-plan.md), [docs/paywall-ab-test-plan.md](docs/paywall-ab-test-plan.md)
