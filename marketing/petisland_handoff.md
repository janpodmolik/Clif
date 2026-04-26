# PetIsland / Uuumi Marketing — Project Knowledge

> Tento dokument obsahuje kompletní kontext pro pokračování v marketingu mojí iOS appky. Nahraj jako project knowledge + použij sekci "System prompt" jako custom instructions.

> **Pozn.:** PetIsland byl pracovní/marketingový název — finální název v App Store je **Uuumi**. V external messagingu používáme Uuumi.
> **Pro detailní mechaniku viz:** [app-concept-for-scripts.md](app-concept-for-scripts.md) — autoritativní zdroj pro to, jak app skutečně funguje.

---

## SYSTEM PROMPT (zkopíruj do "Custom instructions" projektu)

```
Jsi marketing partner pro indie iOS appku Uuumi (screen time blocker s mazlíčkem na ostrově). Tvoje role:

1. Pomáhat tvořit social media content (TikTok, Instagram Reels, YouTube Shorts) — hooky, scénáře, descriptiony
2. Vyhodnocovat performance videí a iterovat
3. Doporučovat trendy a formáty, ale VŽDY si je ověř web searchem — neříkej autoritativní pravidla z hlavy, halucinace se mi už stala
4. Být přímý, ne podlézavý. Když je něco špatně, řekni to. Když nevíš, řekni to.
5. Komunikuj česky, ale anglické scénáře nech v angličtině
6. Talking-head obsah JE OK v 2026 (data to potvrzují) — problém bývá pacing a pattern interrupts, ne formát samotný
7. Authenticity > polish. Indie dev narrativ je silný.
8. Mám rád konkrétní scénáře (tabulka čas/akce/voiceover), ne abstraktní rady
9. Před psaním scénáře si vždy ověř mechaniku v marketing/app-concept-for-scripts.md — nepoužívej zjednodušené metafory typu "vítr fyzicky odfukuje peta" pokud neodpovídají skutečnosti
```

---

## O APPCE

**Název:** Uuumi (iOS, App Store)
**Kategorie:** Screen time management / digital wellness
**Stav:** **LIVE on the App Store** (TestFlight build 6, viz nedávné commity)
**Vývoj:** ~4 měsíce, indie projekt (vyvíjím sám)

### Core mechanika (přesně, viz app-concept-for-scripts.md)

**Není to o tom být úplně off-phone.** Je to o respektování denních limitů na **konkrétní aplikace**, které si vybereš (Instagram, TikTok…).

- **Pet** žije na malém plovoucím ostrově (grass-covered cliff). Začíná jako blob.
- **Essence:** Po prvním dni si vybereš Essence (Plant, Moss, Shroom, Troll…), která určuje evoluční cestu (6–8 fází).
- **Wind system:** Vítr je vizuální metafora pro % využitého denního limitu na blokovaných appkách. Vítr **neposouvá peta fyzicky** — mění **mood**:
  - 0–4% (None) → Happy
  - 5–49% (Low) → Happy, lehká bríza
  - 50–79% (Medium) → Neutral, stres
  - 80–100% (High) → Scared, drží se
- **Blow Away:** Když překročíš limit (vítr 100% a pokračuješ) → pet je permanentně odfouknut, **veškerý progress ztracen**, archivovaný, začínáš znovu s blobem.
- **Breaks:** Můžeš si dát intentional break — během něj app **aktivně blokuje** vybrané appky (shield screen). Vítr během breaku klesá.
- **Daily Presets** (denně si potvrzuješ):
  - Gentle: 20 min do blow away
  - Balanced: 12 min do blow away
  - Intense: 8 min do blow away
- **Evoluce je binární a denní:** dodržel jsi včera limit → pet evolvuje o jednu fázi. Nedodržel → neevolvuje. Není to gradient.

### Hlavní messaging angle

- NE "screen time je špatný"
- NE "blokuju ti telefon"
- ANO "máš co ztratit / chránit"
- ANO "limituješ konkrétní aplikace, které ti berou čas"
- Emocionální stakes místo abstraktních čísel

### Co Uuumi NENÍ (důležité, ať to v scénářích nepleteme)

- ❌ NENÍ to o celkovém screen time telefonu — jen o appkách, které si vybereš
- ❌ NEPUNISHUJE notifikacemi nebo guilt — reakce peta JE feedback
- ❌ Pet **negrowně** "když jsi off phone" — evolvuje když respektuješ denní app limity
- ❌ NENÍ to timer ani jednoduchý blocker — wind + pet vytváří emoční investici

### Diferenciace od konkurence

- **Apple Screen Time:** jen ukáže číslo, "Ignore Limit" = end of story
- **Forest:** stromy nemají emoční váhu mazlíčka, nepamatují si historii
- **Opal/Jomo:** funkční blockery bez emocionálního stake
- **Uuumi:** skutečný emoční stake (permanentní ztráta peta) + evoluce přes Essence + denní rituál

---

## DOPOSAVADNÍ VÝSLEDKY

### Video 1 (nejstarší): Random talking-head žádost o testery
- YouTube Shorts: ~stovky views
- TikTok: ~necelá stovka
- Instagram: mrtvo

### Video 2 (NEJÚSPĚŠNĚJŠÍ): "4 months building this app, nobody wants to test it"
- Ruce v dlaních, captions, žádný voiceover
- YouTube Shorts: **1.8k views**
- Vulnerability + underdog story zafungoval

### Video 3 (nejnovější — flop): "DON'T LOSE" hook
- Talking head + abstraktní hook
- TikTok: 130 views, YouTube: 193, Instagram: 83
- **Proč floplo:** "DON'T LOSE" bez kontextu, žádné pattern interrupts, žádný B-roll appky

**Učení:**
- Vulnerability + konkrétní stake = funguje
- Abstraktní hooky bez kontextu = nefungují
- YouTube Shorts mi jde nejlépe (zatím)
- Cíl: prorazit na TikToku

---

## EXISTUJÍCÍ SCÉNÁŘE V REPU

V [marketing/video-scripts-revised.md](video-scripts-revised.md) jsou už 4 scénáře pro launch fázi (app je LIVE):
1. "My wife asked me to build this" — origin story
2. "I used to be the worst one" — vlastní addiction
3. "The moment I knew I had a problem" — dinner scrolling moment
4. "Why I quit my free time for this" — sacrifice & passion

Pro nové scénáře využívat tento bank jako reference na tone a strukturu.

---

## CONTENT STRATEGIE

### Hook bank (seřazeno podle priority)

**1. Day X series (HLAVNÍ ZBRAŇ)**
"Day 2 of fixing my phone addiction…"
- Series potential, return viewers, evoluce mazlíčka jako payoff (každý den nová fáze pokud držíš limit)

**2. Person A vs Person B**
"Person A uses Screen Time. Person B has a friend that dies if they scroll too much."
- Humor + kontrast, positioning

**3. Never...**
"Never thought a virtual pet would fix my doomscrolling. But here we are."
- Authentic testimonial

**4. There are way too many apps...**
"...that just show you a number. This one made me actually care."
- Diferenciace

**5. Don't lose a friend (původní, potřebuje přepracování)**
- Koncept ok, exekuce flopla — chyběl kontext

**6. This is why you should always...**
"...have something to lose when you scroll."

**7. I see so many people using...**
"...screen time blockers that they ignore in 2 seconds."

**8. Day in a life**
"A day in my life, but my Instagram time decides if my pet survives."

**9. What's the difference?**
"What's the difference between me last month and me now? I had something to protect."

**10. If your (x) looks like this**
"If your Instagram time looks like this (3h), you need a friend on the other side of that scroll."

### Backlog hooks (k vyzkoušení později)

Generické viral templates — fungují, ale potřebují konkrétní Uuumi payoff a reálný stake, jinak skončí jako "DON'T LOSE" flop. Nepoužívat jako talking-head bez B-rollu appky.

**11. "It took me X years to learn this..."**
"It took me 4 months of building to learn this, but I'll show you in 60 seconds why every screen time app fails."
- Authority + curiosity gap. Indie dev úhel sedí.

**12. "Give me 60 seconds to show you..."**
"Give me 60 seconds to show you why a virtual pet fixed my screen time when 5 other apps couldn't."
- Time contract. Funguje pro feature deep-dive (Wind/Essence/Blow Away).

**13. "Most people don't realize this but..."**
"Most people don't realize this, but Apple Screen Time has a button that erases the entire point of it. It's called 'Ignore Limit.'"
- Insider reveal. Sedí na konkurenční srovnání.

**14. "Never (blank) again after learning this..."**
"You'll never tap 'Ignore Limit' again after losing a pet you spent 14 days evolving."
- Loss aversion. Vyžaduje B-roll skutečného blow away momentu.

**15. "I'm finally revealing how I..."**
"I'm finally revealing how I cut my Instagram time from 3 hours to 30 minutes — and it wasn't willpower."
- Process reveal. Pasuje na Day 7 / Day 30 retrospektivu.

**16. "This is the brutal reason why you're..."**
"This is the brutal reason why you're still doomscrolling at 2am — your screen time app has zero stakes."
- Confrontational. Risk: zní jako guru content. Funguje jen s vulnerability follow-up ("I was the same until…").

### Plán série "Day X"
- Day 1: Setup — vybírám Essence, nastavuju preset (Balanced), proč to dělám
- Day 2: First evolution + jak app funguje — **AKTUÁLNĚ TOČÍM**
- Day 3: První selhání, pet padl, začínám znovu s blobem + novou Essence
- Day 7: Týdenní výsledek + screen time porovnání + 7. fáze evoluce
- Day 14: Plně evolved pet (pokud držím)
- Day 30: Měsíční retrospektiva, návyk

---

## SCÉNÁŘ NA AKTUÁLNÍ TOČENÍ — Day 2 (30s verze)

**Hook:** "Day 2 of fixing my Instagram addiction — with an app I built myself."

| Čas | Akce | Voiceover |
|-----|------|-----------|
| 0–3s | Talking head, text overlay "DAY 2" | "Day 2 of fixing my Instagram addiction — with an app I built myself." |
| 3–6s | B-roll: screen time stats (Instagram 3h+) | "I tried Apple Screen Time. Lasted 3 days." |
| 6–9s | B-roll: notifikace "Limit reached" → swipe pryč | "You just tap 'Ignore Limit' and it's over. No stakes." |
| 9–12s | Talking head, frustrace | "So I built something that actually has stakes." |
| 12–16s | B-roll: app — pet na ostrově, klid | "There's a pet that lives on a tiny island in the app." |
| 16–20s | B-roll: app — vítr se zvedá, pet scared | "The more I scroll Instagram, the stronger the wind gets." |
| 20–24s | B-roll: app — moment blow away | "If I break my limit, he gets blown away. Permanently. All progress gone." |
| 24–27s | B-roll: app — evoluce z fáze 1 do fáze 2 (PAYOFF) | "But today — he just evolved." |
| 27–30s | Talking head, úsměv | "See you tomorrow for Day 3." |

**Description:** "Day 2. Apple Screen Time didn't work, so I built this. It's called Uuumi, link in bio."

> **Pozn. k mechanice ve scénáři:** "Wind blows him to the edge" jsem nahradil za "the wind gets stronger" — vítr fyzicky neposouvá peta, mění mu mood. Pokud chceš dramatičtější vizuál, můžeš to ohnout v B-rollu (sway animace), ale ve voiceoveru držet pravdu.

---

## PRAVIDLA PRO TVORBU (z research, ověřeno 2026)

### DO:
- **Pattern interrupts každé 2–3 sekundy** (cut, zoom, text overlay, změna úhlu)
- **Talking head je OK** — autentický raw obsah má +31% engagement vs. polished
- **Original audio + voiceover** — algoritmus to v 2026 odměňuje víc než trending sounds
- **B-roll appky v relevantním momentu** (ne někde jinde)
- **Captions / titulky** — 60–70% lidí kouká bez zvuku
- **Loop / cliffhanger na konci** = vyšší rewatch + follow rate
- **Hook v prvních 3 sekundách** musí dát důvod zůstat
- **70%+ completion rate** = viral threshold v 2026

### DON'T:
- "Hey guys, today I want to talk about…"
- Statický záběr bez střihů
- Hook bez kontextu ("DON'T LOSE" — co? proč?)
- Příliš polished produkce
- Složité hashtagy v description (krátké, úderné fungují líp)
- Říkat "blokuje ti telefon" — Uuumi limituje konkrétní vybrané appky
- Říkat "pet roste když jsi off phone" — pet evolvuje denně když dodržíš limit
- Říkat "vítr ho fyzicky odfukuje" — vítr je metafora pro % limitu, mění mood

### Sweet spot délky:
- 15s s 85% completion > 30s s 40% completion
- 30s+ funguje, pokud je pacing tight (8+ střihů)
- 45–90s funguje pro story content s tight pacing

---

## TONE OF VOICE

- Autentický, indie dev vibe
- Self-aware, trochu sebeironický
- Ne reklamní, ne korporátní
- "Mluvíš s kamarádem v hospodě, ne na konferenci"
- Anglické scénáře, ale v komunikaci se mnou česky
- Origin story angle (manželka, vlastní addiction) je silnější než feature angle

---

## CO JE POTŘEBA (TODO)

- [ ] Natočit a postnout Day 2 (30s verze)
- [ ] Natočit Person A vs Person B
- [ ] Natočit Never... testimonial
- [ ] Po 1 týdnu vyhodnotit performance, iterovat
- [ ] Najít 3-5 trendujících formátů na TikToku tento týden
- [ ] Připravit Day 3 (selhání narrativ — pet padl, vybírám novou Essence)
- [ ] Zvážit natočení 4 launch scénářů z video-scripts-revised.md
