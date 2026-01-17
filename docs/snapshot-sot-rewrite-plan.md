# Aggregate mechanika + snapshot analytics - kratky plan

## Cile
- Herni mechanika (Daily i Dynamic) ma agregatovy SoT.
- Snapshoty slouzi jen pro analytics/premium grafy, ne pro herni stav.
- Logovani je "thin": zapis pouze pri udalostech.

## 1) Mechanika (SoT)
- Daily SoT: `todayUsedMinutes`, `dailyStats`, `dailyLimitMinutes`.
- Dynamic SoT: `windPoints`, `lastThresholdMinutes`, `activeBreak`, `config`, `lastUpdatedAt`.
- `breakCountToday` se pocita ze snapshotu (Daily nema breaky, Dynamic je pocita z break eventu).
- Vsechny zmeny stavu jdou pres jeden update flow (zadne tiche mutace).

## 2) Snapshot schema (v1, analytics)
- Minimalni event set: `system.dayStart/dayEnd`, `usageThreshold(cumulativeMinutes)`,
  `breakStarted/breakEnded/breakFailed`, `dailyReset`, `blowAway`.
- `windPoints` v snapshotu = odvozeny stav (pro grafy), neni autoritativni.
- `schemaVersion` + `unknown` case pro forward-compat.
- `usageThreshold` je stejny event typ pro oba mody, ale s jinou frekvenci (viz thresholdy).
- Breaky se vzdy ukladaji jako snapshoty (pro timeline a grafy).

## 3) Snapshot store a transport
- `SnapshotStore` (append, load, group-by-day).
- Preferovany zapis: **FileManager append-only log** v App Group (JSONL).
- `SharedDefaults` jen pro metadata (offset, lastSync, currentDay), ne pro samotna data.
- Format JSONL (1 radek = 1 snapshot, kompatibilni se Supabase/Postgres).

**JSONL format (navrh):**
```json
{
  "id": "UUID",
  "pet_id": "UUID",
  "mode": "daily|dynamic",
  "date": "YYYY-MM-DD",
  "timestamp": "2026-01-20T12:34:56Z",
  "wind_points": 42,
  "schema_version": 1,
  "event_type": "usageThreshold|breakStarted|breakEnded|breakFailed|dailyReset|blowAway|systemDayStart|systemDayEnd",
  "event_payload": { "cumulative_minutes": 25, "break_type": "free", "planned_minutes": 30 }
}
```

**Event payload map (v1):**
- `usageThreshold` -> `{ "cumulative_minutes": Int }`
- `breakStarted` -> `{ "break_type": "free|committed|hardcore", "planned_minutes": Int? }`
  - `free` -> `planned_minutes = null`
  - `committed|hardcore` -> `planned_minutes` je povinne (Int)
- `breakEnded` -> `{ "actual_minutes": Int }`
- `breakFailed` -> `{ "actual_minutes": Int }`
- `dailyReset` / `blowAway` / `systemDayStart` / `systemDayEnd` -> `{}`

**DB validace (volitelne):**
- CHECK constraint: pokud `break_type IN ('committed','hardcore')` tak `planned_minutes IS NOT NULL`.

**Poznamka k `mode` a `date`:**
- `mode` je redundantni (pet ma mode), ale zjednodusuje BE dotazy a indexy.
- `date` je odvoditelny z `timestamp`, ale zjednodusuje group-by-day a indexaci.

**Supabase tabulka (navrh sloupcu):**
- `id` uuid (PK)
- `pet_id` uuid (FK)
- `mode` text
- `date` date
- `timestamp` timestamptz
- `wind_points` int
- `schema_version` int
- `event_type` text
- `event_payload` jsonb

## 4) Sync + retention
- Offline-first: snapshoty se ukladaji lokalne, sync pri otevreni appky / o pulnoci.
- BE je append-only, deduplikace podle `id` (UUID).
- Batch flush: kdyz `buffer >= 50` **nebo** `>= 5 minut` od posledniho flush (cokoliv nastane driv).
- High-priority eventy (blowAway, breakEnded, breakFailed, dailyReset) mohou vyvolat okamzity flush.
- Retention lokalne: napriklad 30 dni full snapshotu, starsi dny zkompaktovat na 1 snapshot/den.
- Summary tabulky: update po kazdem batch insertu (async) **nebo** scheduled job kazdych ~15 minut.
- Retention na BE: hard delete (zadny cold storage) + GDPR pravidla.

## 5) Update logika (mody)
**Daily update:**
- `usageThreshold` -> `todayUsedMinutes = cumulative_minutes`.
- `windPoints` pro UI = `min(100, cumulativeMinutes / dailyLimitMinutes * 100)`.
- `limitReached` je odvozeny stav (pri `cumulativeMinutes >= dailyLimitMinutes`).

**Dynamic update:**
- `usageThreshold` -> `delta = cumulativeMinutes - lastThresholdMinutes`,
  `windPoints += delta * riseRate`, `lastThresholdMinutes = cumulativeMinutes`.
- `breakStarted` -> nastavit `activeBreak` (bez zmeny windPoints).
- `breakEnded/Failed` -> `elapsedMinutes = now - activeBreak.startedAt`,
  `windPoints -= elapsedMinutes * breakDecreaseRate` (+ penalizace),
  `activeBreak = nil`.
- `dailyReset` -> aplikovat reset a ulozit novy `windPoints`.
- `blowAway` -> explicitni flag + snapshot.

## 6) Prepis modelu
- `DailyPet` zůstává agregatovy SoT (`todayUsedMinutes`, `dailyStats`).
- `DynamicPet` zůstává agregatovy SoT (`windPoints`, `activeBreak`, `lastThresholdMinutes`).
- Snapshoty se ukladaji pro oba mody (Daily i Dynamic). Premium odemyka UI pro grafy.
- `Archived*`: summary/cache z agregatu, detailni grafy jen pokud jsou snapshoty.

## 7) UI mapovani
- UI pro mechaniku bere data z agregatu (realtime).
- Analytics grafy berou data ze snapshotu (pokud dostupne/premium).

## 8) Migrace (volitelna)
- Pro analytics: backfill z `dailyStats` -> 1 snapshot per day (end-of-day).
- Pokud nechceme analytics pro stare dny, migrace neni nutna.

## 9) Thresholdy (aktualni navrh)
- Dynamic: threshold kazdou 1 min (fallback 2-5 min, pokud bude limit).
- Daily: pasma 0 → 25 → 50 → 75 → 100 + "1 minuta do limitu".
- Zamerne rozdilna frekvence: Dynamic bude mit hustsi snapshoty, Daily ridssi.
