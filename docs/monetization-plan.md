# Uuumi Monetization Plan

## Přehled

| Pilíř | Popis |
|-------|-------|
| **Subscription (Uuumium)** | Premium features + vyšší coin earning rate |
| **Coin Packs** | Jednorázové nákupy coinů |
| **Coins** | Virtuální měna — vydělává se hraním, utrácí za esence |

---

## Subscription (Uuumium)

| | USD | EUR | CZK | Poznámka |
|--|-----|-----|-----|----------|
| Měsíční | $4.99 | €4.99 | 129 Kč | Bez trialu |
| Roční | $34.99 | €34.99 | 899 Kč | 7-day free trial |
| Roční/měsíc | $2.92 | €2.92 | ~75 Kč | Úspora 42% |

### Premium výhody
- Neomezený počet petů
- Dynamic mode
- Committed breaks (+ coin odměny za ně)
- 2× coin earning z evoluce (10 vs 5)
- 6 pozadí (den/noc varianty)
- Detailní statistiky

### Co zůstane po zrušení Premium

| Co | Stav |
|----|------|
| Odemčené esence (za coiny) | Zůstávají |
| Extra peti | Zamčou se (zůstane 1 aktivní) |
| Dynamic mode peti | Doběhnou, nový nejde vytvořit |
| Pozadí | Vrátí se default |
| Statistiky | Jen základní |

---

## Coin Economy

### Zdroje coinů

| Zdroj | Free | Premium |
|-------|------|---------|
| Evoluce peta (1×/den) | 5 coinů | 10 coinů |
| Committed break (1 coin/15 min, cap 10/break) | — | dostupné |
| **Celkem/týden** | **~35** | **~140-210** |

### Utrácení coinů

| Položka | Cena |
|---------|------|
| Esence (evoluční cesta) | 150 coinů |
| Plant esence | 0 (default unlocked) |

### Čas na 1 esenci

| Uživatel | Čas |
|----------|-----|
| Free | ~4.3 týdne |
| Premium | ~5-7 dní |

---

## Coin Packs (jednorázové)

| Pack | Coiny | USD | EUR | CZK | Esencí | USD/esence |
|------|-------|-----|-----|-----|--------|------------|
| Small | 100 | $1.99 | €1.99 | 49 Kč | 0.66 | $3.00 |
| Medium | 400 | $6.99 | €6.99 | 179 Kč | 2.66 | $2.63 |
| Large | 1000 | $14.99 | €14.99 | 379 Kč | 6.66 | $2.25 |

### Role coin packů
- **Small ($1.99)** — impulse buy, vstupní brána do monetizace, nestačí na celou esenci
- **Medium ($6.99)** — pro ty co chtějí konkrétní esenci teď, dražší než 1 měsíc Premiumu ale méně coinů
- **Large ($14.99)** — whale option, nejlepší per-coin value, ale stále horší deal než Premium

### Proč coin packy nekanibalizují subscription
- Small nestačí na esenci → nutí druhou akci
- Medium ($6.99) dá 400 coinů, ale měsíc Premiumu ($4.99) dá ~600-840 → subscription jasně vyhrává
- Large ($14.99) ≈ 3 měsíce ročního sub, ale Premium za tu dobu vydělá ~1800-2700 coinů

---

## Srovnání cest k 1 esenci (150 coinů)

| Cesta | Čas | Cena |
|-------|-----|------|
| Free grind | ~4.3 týdne | $0 |
| Small pack + free grind | ~2 týdny | $1.99 |
| Small pack × 2 | okamžitě | $3.98 |
| Medium pack | okamžitě (+ 250 zbytek) | $6.99 |
| Premium měsíční | ~5-7 dní | $4.99/měs |
| Premium roční | ~5-7 dní | $2.92/měs |

---

## Paywall strategie

### Principy
- Žádné descending price chains (3 paywally se snižující cenou)
- Žádné fake slevy — pokud není reálná akce (Black Friday, Nový rok), cena je cena
- Jeden čistý paywall, zobrazovaný ve správný moment
- Nikdy neblokovat pozitivní moment paywallem **po** tom co nastal — upsell **před** odměnou

### Paywall momenty

| Moment | Typ | Frekvence | Popis |
|--------|-----|-----------|-------|
| Po onboardingu | Soft paywall (sheet) | 1× | "Premium existuje", přeskočitelné |
| Evoluce | Blocking upsell **před** coin rewardem | Denně | "Evolvuješ → dostaneš 5 coinů, s Premium 10" |
| Zamčené nastavení | Paywall při tapu | User-initiated | Pozadí, statistiky — lock ikona → tap → paywall |
| Free break | Banner na committed break | User-initiated | "Committed Break = coins" → tap → paywall |
| Essence katalog | Unlock sheet zmíní Premium | User-initiated | Zamčené esence, unlock sheet ukazuje balance + earning rate |

### Slevy a promo
- Seasonal akce 1-2× ročně (Black Friday, Nový rok) — reálné, časově omezené
- Referral/promo kódy pro influencery, recenze, partnerství
- Vše komunikované transparentně (web, push notifikace)

---

## Konkurenční kontext

| App | Roční | Měsíční | Typ |
|-----|-------|---------|-----|
| Opal | $99.99 | ~$8 | Screen time blocker |
| Clearspace | $49.99 | ~$10/týden | Screen time blocker |
| Freedom | $39.99 | $3.33 | Website/app blocker |
| one sec | ~$30 | ~$3-4 | Mindful delay |
| AppBlock | $19.99 | $2.99 | App blocker |
| **Uuumi** | **$34.99** | **$4.99** | **Screen time + gamifikace** |

Uuumi se pozicuje nad utility blockery (AppBlock, one sec) díky gamifikaci, pod premium blockery (Opal, Clearspace).

---

## Esence (pro MVP)

| Esence | Dostupnost |
|--------|------------|
| Plant | Free (default) |
| Crystal | 150 coinů |
| Flame | 150 coinů |
| Water | 150 coinů |
| Shadow | 150 coinů |
| Stone | 150 coinů |
| Wind | 150 coinů |
| Electric | 150 coinů |
| Ice | 150 coinů |
| Void | 150 coinů |
