# Paywall A/B Test — To-Do List

## Decisions locked in

- Variant A (control): Monthly $4.99 + Yearly $34.99 / 7-day trial
- Variant B (weekly_trial): Weekly $4.99 / 3-day trial + Yearly $34.99 / no trial
- Variant B savings headline: **"Save 87%"** ($34.99 vs $259.48 annualized)
- Weekly-equivalent on yearly card: **"~$0.67/week"**
- Experiment unit: **StableID** (not userID — paywall fires pre-signup)

---

## iOS code

### App Store Connect
- [ ] Create product `com.janpodmolik.Uuumi.premium.weekly` — 1 week, $4.99, 3-day free intro offer
- [ ] Create product `com.janpodmolik.Uuumi.premium.yearly.notrial` — 1 year, $34.99, no intro offer
- [ ] Submit both for review

### `Products.storekit`
- [ ] Add weekly entry with `introductoryOffer` (3 days, free, `P3D`) mirroring yearly block at lines 111–117
- [ ] Add yearly-no-trial entry with `introductoryOffer: null`

### `StoreManager.swift`
- [ ] Add `static let weeklyID = "com.janpodmolik.Uuumi.premium.weekly"` at line 48–49
- [ ] Add `static let yearlyNoTrialID = "com.janpodmolik.Uuumi.premium.yearly.notrial"`
- [ ] Include both in product fetch array
- [ ] Verify `isPremium` logic still works (no change needed — any active entitlement grants premium)

### `PremiumSheet.swift`
- [ ] In `.onAppear`, read `Statsig.getExperiment("paywall_products_v1").getValue(forKey: "variant", defaultValue: "control")`
- [ ] Branch displayed products: `control` → monthly + yearly-with-trial, `weekly_trial` → weekly + yearly-no-trial
- [ ] Update savings % calc to reference the active short-period product (monthly in A, weekly in B)
- [ ] Set CTA button text: Weekly → `"Try 3 Days Free"`, Yearly-no-trial → `"Continue"`

### `AnalyticsManager.swift`
- [ ] Add `paywall_variant` to metadata on `paywallShown`, `purchaseCompleted`, `purchaseFailed`
- [ ] Add `is_trial: Bool` to `purchaseCompleted` (derive from `transaction.offer?.type == .introductory`)
- [ ] Add `product_id` to all three events if not already present
- [ ] Add new event `purchaseRefunded` — log from `Transaction.updates` listener in StoreManager

### `StatsigConfig.swift` (lines 25–35)
- [ ] Add `paywall_variant` to user custom attributes alongside `premium_plan`

### Testing
- [ ] Sandbox test: both variants show correct products
- [ ] Sandbox test: trial starts fire `is_trial=true`, renewals fire `is_trial=false`
- [ ] Sandbox test: refund event fires `purchaseRefunded`
- [ ] Verify events land in Statsig Diagnostics tab with all new fields populated

### Release
- [ ] Ship to TestFlight (`tf/<version>-<build>` tag)
- [ ] Confirm event schema in Statsig before starting experiment

---

## Statsig dashboard — úkoly (česky)

### Vytvoření experimentu

- [ ] V Statsigu jít do **Experiments** → **+ New Experiment**
- [ ] **Name**: `paywall_products_v1`
- [ ] **Hypothesis**: "Weekly subscription s 3-day trialem + yearly bez trialu vygeneruje vyšší revenue per impression než current monthly + yearly-with-trial setup"
- [ ] **ID Type**: **StableID** (NE userID — paywall se zobrazuje i anonymním uživatelům)
- [ ] **Groups**: `control` 50% + `weekly_trial` 50%
- [ ] Přidat **parameter** `variant` (String) — hodnoty `"control"` a `"weekly_trial"`
- [ ] **Targeting**: zatím bez, všichni uživatelé
- [ ] **Primary Metric**: Revenue per paywall impression (vytvořit níž)
- [ ] Experiment zatím **neaktivovat** — nejdřív musí být v TestFlightu iOS build s `getExperiment()` voláním

### Vytvoření metrik (v **Metrics** → **+ New Metric**)

- [ ] **Trial Start Rate**
  - Numerator: count of `purchase_completed` WHERE `is_trial = true`
  - Denominator: count of `paywall_shown`
- [ ] **Trial-to-Paid Conversion**
  - Numerator: count of `purchase_completed` WHERE `is_trial = false` AND user má předchozí `purchase_completed` s `is_trial = true` během 30 dní
  - Denominator: count of `purchase_completed` WHERE `is_trial = true`
- [ ] **Revenue per Paywall Impression (PRIMARY)**
  - Numerator: sum `revenue` z `purchase_completed` WHERE `is_trial = false`
  - Denominator: count of `paywall_shown`
  - Time window: 30 dní (a druhá verze s 60 dní)
- [ ] **Refund Rate**
  - Numerator: count of `purchase_refunded`
  - Denominator: count of `purchase_completed` WHERE `is_trial = false`

### Guard metriky (sleduj, ale nejsou primary)

- [ ] 7-day retention
- [ ] 30-day retention
- [ ] DAU

### Spuštění experimentu

- [ ] Ověřit v Statsig **Diagnostics**, že eventy chodí s `paywall_variant`, `is_trial`, `product_id`
- [ ] Teprv **Start**nout experiment v dashboardu
- [ ] Poznamenat si datum startu

### Ukončení experimentu

- [ ] Neukončovat dřív než:
  - Statsig hlásí **statistical significance** (p < 0.05) na primary metric, A
  - Uběhlo minimálně 14 dní, A
  - Alespoň 2 full payment cycles dat (ideálně 30 dní)
- [ ] Nenechat se zmást brzy vysokým trial start rate u variant B — revenue přijde až po trialu

### Po skončení

- [ ] Pokud vyhrál **weekly_trial**: rollout na 100% přes Statsig, v dalším release cleanup `control` kódu
- [ ] Pokud vyhrál **control**: rollout `control` na 100%, v dalším release odstranit weekly produkt z App Store Connect + cleanup kódu
- [ ] Pokud **inconclusive**: nechat běžet déle, nebo se vrátit k control a zkusit jinou hypotézu

---

## Rejected options (proč ne)

- **RevenueCat** — vyžadovalo by přepsat entitlement layer a `SharedDefaults.isPremiumCached` cache pro extensions. Pro iOS-only app se StoreKit 2 bez benefitu.
- **Superwall** — řeší remote paywall UI; UI nemění.
- **Víc price pointů weekly v jednom experimentu** — ředí statistickou sílu. Nejdřív $4.99/wk vs control, follow-up experiment může testovat $4.99 vs $6.99.
