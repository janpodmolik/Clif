# Brainrot - Case Study: $25,000 za 30 dní

## Shrnutí pro tým

Autor aplikace **Brainrot** (screen time app s vizualizací "rotujícího mozku") sdílel své zkušenosti z úspěšného launche. Zde jsou klíčové poznatky, které můžeme aplikovat na náš projekt.

---

## 1. Produkt

**Co je Brainrot:**
- Screen time aplikace pro iPhone
- Vizualizuje "rotující mozek" podle času stráveného na telefonu
- Řeší reálný problém autora - závislost na telefonu (10+ hodin denně)

**Tech stack:**
- Swift (pouze iOS, bez Androidu)
- **90%+ "vibe coded"** pomocí Cursor / Claude / Claude Code
- Autor je Staff Software Engineer, ale i tak využil AI code generation
- Superwall pro paywall (doporučuje)
- Vývoj: ~2.5 měsíce, 2x přepsal celou aplikaci, 6x odmítnut App Store

---

## 2. Strategie osobní značky

**Klíčový insight:**
> "Možná by mi pomohlo, kdyby lidé viděli MŮJ PŘÍBĚH. Podnikatele, který za scénami bojuje a vytrvává."

**Co dělal:**
- 400+ denních videí na sociálních sítích
- Vybudoval 200k+ followerů napříč platformami (IG, TikTok, X)
- Během vývoje sdílel:
  - Že pracuje na aplikaci (ale NE co to je)
  - Timelapsy kódování
  - Všechna odmítnutí App Store
- Záměrně držel nápad v tajnosti do launche

**Výsledek:** Osobní značka = distribuce zdarma

---

## 3. Launch strategie

### Den 1 - Launch pro followery
- Několik tisíc stažení
- ~$3,000 revenue

### Product Hunt Launch (HLAVNÍ ÚSPĚCH)
- Naplánoval launch večer předem
- Ráno v 7:00 už byl #4 na Product Hunt
- Skončil jako **#1 Product of the Day**
- **10,000+ stažení za jeden den**
- **~$5,000 revenue za jeden den**

**Proč to fungovalo:**
- Product Hunt poslal newsletter s předmětem "Cure your brainrot"
- První sekce emailu byla o Brainrot
- Tip: Můžete pitchnout na `editorial@producthunt.co`

---

## 4. Post-launch realita

**Baseline po spike:**
- ~300 stažení/den
- ~$200/den (po Apple cut)
- Hlavní zdroj: App Store Search (lidé hledají "brainrot")

**Aktuální výzvy:**
- Hledání udržitelné distribuce
- Zkouší UGC creators, meme pages, TikToks
- Přiznává, že "struggles"

---

## 5. Klíčové poučení pro nás

### Co funguje:
1. **Řešit vlastní problém** - autentická motivace
2. **AI code generation** - i senior engineer využívá 90%+ vibe coding
3. **Budovat publikum PŘED launchem** - denní content, i když trvá měsíce
4. **Product Hunt** - může být game changer, newsletter je klíč
5. **Držet nápad v tajnosti** - alespoň do prvního launche

### Co je těžké:
1. **Udržitelná distribuce** po initial spike
2. **App Store approval** - očekávat odmítnutí
3. **Konzistentní content creation** - 400+ dnů je commitment

---

## 6. Aplikovatelné na Clif

| Brainrot | Náš potenciální přístup |
|----------|------------------------|
| Screen time = reálný problém | Focus time / produktivita = reálný problém |
| 90% vibe coded | Můžeme podobně akcelerovat vývoj |
| Personal brand = distribuce | Máme nějakou audience? |
| Product Hunt #1 | Zvážit PH launch strategii |
| Superwall paywall | Zvážit pro monetizaci |

---

## Otázky k diskuzi

1. Máme kapacitu na content creation podobného rozsahu?
2. Jak se lišíme od Brainrot - co je náš unique angle?
3. Product Hunt launch - timing a příprava?
4. Jaká je naše post-launch distribution strategie?

---

## 7. Zajímavé komentáře z diskuze

### Kritické pohledy

**@Lexs_07** - Realita App Store:
> "Most of the revenue is not from my personal brand" nezní úplně správně. Tenhle segment je extrémně konkurenční a je téměř nemožné rankovat na App Store a získat 300 denních stažení bez významných ad spendů nebo, jako v tvém případě, silné osobní značky. Bez úspěšného launche by byla appka prakticky neviditelná."

**@leafeternal** - Kritika:
> "Už jsi měl audience čtvrt milionu lidí. Samozřejmě že jsi vydělal $25K. Morál příběhu je vybudovat obrovský following. To je doslova celé. Jsou tu stovky founderů s výbornými appkami a nikam je poslat."

**@heartingale** - Skeptický pohled:
> "V podstatě dostal zaplaceno za promo Product Hunt a na oplátku si udržel pozici."

**@BossDue9503** - Faktická korekce:
> "Tvůj launch byl naplánován dva týdny předem, ne večer předtím."

### Technické dotazy

**@pauramon** a **@jree42343** - Screen Time API:
> "Technicky, jak přistupuješ k informacím o využití obrazovky? Myslel jsem, že API neexistují."
> *(Autor neodpověděl - zajímavé pro náš výzkum)*

**@Klaud10z**:
> "Použil jsi nějaký konkrétní CLAUDE.MD template?"

**@DaGarbageCollector** (SDE 2 @ big tech):
> "Zajímá mě tvůj vibe coding setup s Claude. Učím se SwiftUI..."

### Monetizace a UX

**@No-Pollution9824**:
> "Má subscription za cca 4 eura měsíčně."

**@mcgerin** (před 2 hodinami) - Kritika paywallu:
> "Upgrade flow je fakt hrozný. Existuje free verze nebo ne? Protože způsob, jak je upgrade flow nastaven, v podstatě brání uživateli NEKOUPIT, což je trochu shit move."

### App Store zkušenosti

**@FunDiscount2496**:
> "Doslova rok jsem čekal na schválení appky v Apple marketplace. Už nikdy."

**@etherswim** - Vysvětlení App Store review:
> "Požadavky jsou jasné, ale review může být nekonzistentní. Revieweři se mohou zaseknout na ne-problémech... jednou mi appku odmítli z jednoho důvodu, opravili jsme to, a při dalším review ji odmítli z jiného důvodu, který byl ale dříve v user journey. Pro většinu appek to trvá pár pokusů, ale čím víc to děláš, tím je to snazší."

### Build in Public filosofie

**@MerdeInFrance** - Shrnutí:
> "Jeho rada je budovat veřejně i když opakovaně selháváš, protože mít audience se stává nesmírně cenným, když konečně spustíš něco, co funguje."

**@100DaysOfDiscipline**:
> "Tohle je cenné, protože to dává všem smysl pro realitu. Nemůžeš uspět, pokud nevíš, jak selhat. Lidé musí pochopit, že selhávat je naprosto v pořádku. Plánuji také začít sdílet svůj příběh a budovat veřejně."

### Distribuce a růst

**@Shoddy_Survey3432** - Nápad:
> "Zkoušel jsi listing na Whop, aby ostatní creators dělali virální content? Mohlo by to fungovat v business, motivational a hopecore/nature niche."

**@Any-Worldliness-5151**:
> "Jak jsi přiměl lidi stahovat a používat appku? Není těžké budovat důvěru jako malá appka?"

---

## 8. Meta-poznatky z komentářů

### Co komunita potvrzuje:
1. **Personal brand je klíčový** - bez něj by appka byla neviditelná
2. **App Store review je bolest** - nekonzistentní, může trvat měsíce
3. **Vibe coding funguje** - více lidí to potvrzuje (90%+ AI generated)
4. **Build in public inspiruje** - komunita to oceňuje

### Co komunita kritizuje:
1. **"Revenue není z personal brand"** - to je zavádějící, brand = distribuce
2. **Agresivní paywall** - upgrade flow neumožňuje neplatit
3. **Timing launche** - možná nebyl tak spontánní jak tvrdí

### Nezodpovězené otázky (příležitost pro nás):
1. Jak přesně přistupovat k Screen Time API na iOS?
2. Jaký CLAUDE.MD template použil?
3. Jak řešit důvěru u nové appky bez personal brand?

---

*Zdroj: Reddit/Twitter post od @yonismolyar, prosinec 2024 + komentáře z diskuze*
