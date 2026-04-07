# Supabase Security

## Current State (April 2025)

### RLS (Row Level Security)

All tables have RLS enabled with per-user isolation (`auth.uid() = user_id`).

| Table | SELECT | INSERT | UPDATE | DELETE | Role |
|-------|--------|--------|--------|--------|------|
| `active_pets` | own | own | own | own | authenticated |
| `archived_pets` | own | own | — | own | authenticated |
| `user_data` | own | own | own | — | authenticated |
| `pending_rewards` | own | — | `claimed_at` only | — | authenticated |
| `feedback` | — | own (auth) / null user_id (anon) | — | — | authenticated + anon |
| `analytics_events` | — | any | — | — | authenticated + anon |
| `waitlist` | — | any | — | — | anon |
| `rate_limits` | — | — | — | — | no policies (locked) |

### What IS protected

- Users cannot see or modify other users' data
- Anonymous users cannot access pet/user data tables
- `pending_rewards` UPDATE is column-restricted to `claimed_at` only
- `delete_user()` RPC runs as SECURITY DEFINER on the backend
- **Feedback spam**: DB trigger limits to 10 inserts per user per 24h
- **Archive spam**: DB trigger limits to 5 inserts per user per 24h

### What is NOT protected (known trade-offs)

- **Coins inflation**: A user with a valid JWT token could theoretically call the Supabase API directly and set their `coinsBalance` to any value in `user_data.data`. This affects only their own account.
- **Essence unlock bypass**: Same as above — a user could add essence IDs to their own `unlockedEssences` array without paying coins.
- **Wind points manipulation**: A user could modify `wind_points` or `is_blown_away` on their own `active_pets` row.

**Accepted risk**: These all require reverse-engineering the API (extracting JWT from the app, understanding the schema). The user only affects their own data — there is no competitive/social feature where this would harm others.

## Architecture: Why client-side writes

The app uses an **offline-first** architecture:
1. All state changes happen locally (SharedDefaults)
2. SyncManager periodically upserts full state to Supabase
3. This means the client must have full write access to its own rows

Moving to server-side validation would break offline functionality and require a significant refactor.

## Future Improvements (when needed)

### Priority 1: Server-side IAP receipt validation
**When**: Before scaling to thousands of users, or if coin fraud becomes visible.

Instead of the client adding coins after purchase, the flow would be:
1. Client sends Apple receipt to a Supabase Edge Function
2. Edge Function validates receipt with Apple's API
3. On success, Edge Function adds coins server-side (bypassing RLS with service key)
4. Client refreshes its local state from the server

This is the standard approach for protecting IAP currency.

### Priority 2: Server-side RPC for sensitive operations
**When**: If adding PvP, leaderboards, or any feature where one user's coins/progress affects others.

Replace direct `user_data` UPDATE with RPC functions:
- `add_coins(amount, reason)` — only callable from Edge Functions
- `purchase_essence(essence_id)` — validates price, deducts coins, unlocks essence atomically
- `claim_rewards()` — claims pending rewards and adds coins in one transaction

### Priority 3: Advanced rate limiting
**When**: If abuse patterns emerge beyond current DB triggers.

Options:
- Supabase Edge Functions + Upstash Redis for IP-based rate limiting
- Tighter per-table triggers as needed

## Budget & Monitoring

- Enable **Spend Cap** in Supabase Dashboard → Settings → Billing
- Set up **usage alerts** for database size, API requests, and auth MAUs
- Monitor via Supabase Dashboard → Reports
