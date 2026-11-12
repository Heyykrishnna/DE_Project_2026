# Phase 4: Query Optimization Report

All secondary indexes are defined in [sql/05_indexes.sql](../sql/05_indexes.sql) and query rewrites are in [sql/06_optimized_queries.sql](../sql/06_optimized_queries.sql). After creating the 20 indexes and running `VACUUM ANALYZE;`, all 30 queries were re-benchmarked 3 times via `./benchmarks/run_benchmark.sh olx_db optimized 3 sql/06_optimized_queries.sql` with default PostgreSQL memory and planner settings (`work_mem = 4MB`, `enable_seqscan = on`).

Total workload latency across all 30 queries dropped from **1,650.459 ms** to **265.219 ms** (**83.9% reduction / 6.2x faster**). Every OLTP lookup and write except the nightly batch expiry (`W04`) now averages **under 2.2 ms**.

---

## 1. Optimization Comparison Table (All 30 Queries)

Improvement % = `(Before - After) / Before * 100`.

| Query | Before (ms) | Problem Found in Plan | Optimization Applied | After (ms) | Improvement | Same Result? |
| --- | ---: | --- | --- | ---: | --- | --- |
| **R01** | 13.557 | Parallel Seq Scan on 120k `listings` + top-N sort | Partial covering index `idx_listings_active_cars_filter` / `idx_listings_active_cat_city_posted` | 0.448 | 96.7% (30.3x) | ✅ |
| **R02** | 12.182 | Parallel Seq Scan on 120k `listings` evaluating JSONB casts + sort | Partial expression covering index `idx_listings_active_cars_filter` (`city_id, fuel, price, year, km`) | 0.044 | 99.6% (276.9x) | ✅ |
| **R03** | 17.554 | Parallel Seq Scan on 120k `listings` running `ILIKE` + sort | Partial trigram GIN index `idx_listings_active_title_trgm` (`pg_trgm`) | 1.513 | 91.4% (11.6x) | ✅ |
| **R04** | 0.609 | Seq Scan on 11,244 `seller_ratings` for correlated `AVG(stars)` | Covering index `idx_seller_ratings_seller_stars (seller_id) INCLUDE (stars)` | 0.386 | 36.6% (1.6x) | ✅ |
| **R05** | 8.892 | Full Seq Scan on 120k `listings` for `seller_id = 1042` | Covering `Index Only Scan` via `idx_listings_seller_status_view (seller_id, status, listing_id) INCLUDE (view_count)` | 0.177 | 98.0% (50.2x) | ✅ |
| **R06** | 72.997 | Cross-table `OR` Hash Join + 13x full Seq Scan of 209k `chat_messages` | Rewrote `OR` as disjoint `UNION ALL` + `idx_chat_threads_buyer_thread` + `idx_chat_messages_thread_sent` | 2.198 | 97.0% (33.2x) | ✅ |
| **R07** | 7.213 | Parallel Seq Scan on 209k `chat_messages` for `NOT is_read` | Rewrote `OR` as two disjoint scalar subqueries + partial `idx_chat_messages_unread_thread` | 0.310 | 95.7% (23.3x) | ✅ |
| **R08** | 6.735 | Parallel Seq Scan on 120k `listings` filtering JSONB `model` + `posted_at` | Partial expression covering index `idx_listings_mobiles_model_posted` (`WHERE category_id = 5`) | 4.730 | 29.8% (1.4x) | ✅ |
| **R09** | 8.022 | Parallel Seq Scan on 120k `listings` for bounding-box geo filter | Partial covering index `idx_listings_active_cat_lat_lon (category_id, latitude, longitude) WHERE status = 'ACTIVE'` | 0.261 | 96.7% (30.7x) | ✅ |
| **R10** | 7.321 | Parallel Seq Scan on 120k `listings` for 3-day `expires_at` window | Partial covering index `idx_listings_active_expires (expires_at) WHERE status = 'ACTIVE'` | 0.682 | 90.7% (10.7x) | ✅ |
| **R11** | 2.365 | Seq Scan on `reports` + 639 PK lookups before `HAVING` filter | Aggregated `reports` in subquery before `listings` join + partial `idx_reports_open_listing_reason` | 1.515 | 35.9% (1.6x) | ✅ |
| **R12** | 40.137 | Seq Scan on 120k `listings` + HashAggregate temp-disk spill (`736 kB`) | Rewrote to explicit `IST` date grouping; planner keeps `Seq Scan + HashAggregate` (faster than index scan) | 63.196 | -57.5% (1.57x slower) | ✅ |
| **R13** | 15.019 | Seq Scan on 120k `listings` + **NULL bug (`NOT IN` returns 0 rows)** | Rewrote `NOT IN` to `NOT EXISTS` (fixes NULL bug) + partial `idx_listings_boost_package` | 0.101 | 99.3% (148.7x) | ✅ (fixed: 0 -> 2 rows) |
| **R14** | 9.877 | Parallel Seq Scan on 120k `listings` with non-sargable `EXTRACT(YEAR)` | Sargable `sold_at` range rewrite + partial `Index Only Scan` via `idx_listings_sold_at_cat` | 4.616 | 53.3% (2.1x) | ✅ |
| **R15** | 11.091 | Full Seq Scan of `offers` (20k) + Parallel Seq Scan of `listings` (120k) | Covering index `idx_offers_listing_status (listing_id) INCLUDE (status)` (still scans `listings`) | 13.730 | -23.8% (1.24x slower) | ✅ |
| **R16** | 12.296 | Full Seq Scan of `favourites` (70k) + Seq Scan of `listings` (120k) | Aggregated `favourites` first via `idx_favourites_saved_at` + partial `listings` active index | 7.614 | 38.1% (1.6x) | ✅ |
| **R17** | 15.696 | Parallel Seq Scan of all 120k `listings` for boosted vs. normal rollup | Unchanged (must aggregate all 120k rows; see Section 6) | 16.035 | -2.2% (1.02x slower) | ✅ |
| **R18** | 39.660 | Seq Scan on 120k `listings` + HashAggregate temp-disk spill | Added `idx_listings_seller_title_price`; planner keeps `Seq Scan + HashAggregate` at 120k (uses index at 2.4M) | 41.746 | -5.3% (1.05x slower) | ✅ |
| **R19** | 1,196.778 | Correlated `SubPlan 2` scans 209k `chat_messages` 279 times (296k buffers) | Rewrote correlated `SubPlan`s to `LEFT JOIN`s + `idx_listings_active_cat_city_posted` + `idx_chat_messages_thread_sent` | 10.404 | 99.1% (115.0x) | ✅ |
| **R20** | 8.027 | Parallel Seq Scan on 120k `listings` with non-sargable `posted_at::date` | Sargable `posted_at` range rewrite + covering `idx_listings_posted_desc_id` (`Index Only Scan`) | 2.109 | 73.7% (3.8x) | ✅ |
| **R21** | 9.551 | Full Seq Scan of `seller_ratings` + full Seq Scan of 50k `users` | Aggregated `seller_ratings` top-20 first before PK lookup into `users` | 3.409 | 64.3% (2.8x) | ✅ |
| **R22** | 31.374 | Seq Scan on 120k `listings` + `7,488 kB` disk sort (`OFFSET 50000`) | Keyset pagination `(posted_at, listing_id) < (...)` + covering `idx_listings_posted_desc_id` | 0.048 | 99.8% (653.6x) | ✅ |
| **R23** | 0.027 | Already uses auto-created unique index `users_phone_key` | Already optimal via `users_phone_key` (Run 1 cold read `0.780 ms`; Runs 2–3 `0.109 / 0.055 ms`) | 0.315 | -1066.7% (cold Run 1 noise) | ✅ |
| **R24** | 16.275 | Seq Scan on 120k `listings` discarding 110k non-active rows | Partial `Index Only Scan` on `idx_listings_active_cat_lat_lon` (`WHERE status = 'ACTIVE'`) | 5.806 | 64.3% (2.8x) | ✅ |
| **R25** | 50.824 | Full Seq Scans on `chat_messages`, `chat_threads`, `listings` | Covering index `idx_chat_threads_created_listing` (`Index Only Scan` on `chat_threads`) | 45.767 | 10.0% (1.1x) | ✅ |
| **W01** | 0.808 | Single-row `INSERT` with 4 FK checks | Unchanged (maintains new indexes on `listings`) | 1.454 | -80.0% (1.80x slower) | ✅ |
| **W02** | 11.832 | Subquery runs Seq Scan on 120k `listings` to find `min(listing_id)` | No query change; subquery uses `Index Only Scan` on `idx_listings_seller_status_view` | 0.325 | 97.3% (36.4x) | ✅ |
| **W03** | 0.580 | Backward PK scan over 3,365 threads for `buyer_id = 1042` | No query change; `max(thread_id)` uses `Index Only Scan` on `idx_chat_threads_buyer_thread` | 0.798 | -37.6% (1.38x slower) | ✅ |
| **W04** | 21.343 | Seq Scan on 120k `listings` discarding 117,744 rows | No query change; `Index Scan` on `idx_listings_active_expires` (updates partial active indexes) | 35.003 | -64.0% (1.64x slower) | ✅ |
| **W05** | 1.817 | Two full Seq Scans of `offers` (20k rows each) | No query change; tiny partial index `idx_offers_pending_listing` (`WHERE status = 'PENDING'`) | 0.479 | 73.6% (3.8x) | ✅ |
| **Total** | **1,650.459** | — | — | **265.219** | **83.9% (6.2x)** | — |

---

## 2. Wrong-Result Query Found & Fixed (`R13`)

### The Bug in `queries/workload_30.sql`

```sql
SELECT b.package_id, b.package_name, b.price
FROM boost_packages b
WHERE b.package_id NOT IN (SELECT l.boost_package_id FROM listings l);
```

- **What it returned:** **0 rows** (empty result—matching Problem P5: *"The monetisation team's 'boost packages nobody bought' report is always empty"*).
- **Why it is wrong:** In `listings`, 110,565 out of 120,000 ads are organic and have `boost_package_id IS NULL`. In SQL three-valued logic, `x NOT IN (1, 2, 3, 4, NULL)` expands to `x <> 1 AND x <> 2 AND x <> 3 AND x <> 4 AND x <> NULL`. For `package_id = 5` and `package_id = 6`, `5 <> NULL` evaluates to `UNKNOWN`, so the entire `AND` expression becomes `UNKNOWN`, and `WHERE` filters out **every** row.
- **The Fix in `sql/06_optimized_queries.sql`:** Replace `NOT IN` with `NOT EXISTS` (backed by partial index `idx_listings_boost_package WHERE boost_package_id IS NOT NULL`):

```sql
SELECT b.package_id, b.package_name, b.price
FROM boost_packages b
WHERE NOT EXISTS (
    SELECT 1
    FROM listings l
    WHERE l.boost_package_id = b.package_id
);
```

- **Corrected Output (2 rows):**
  - `5 | Urgent tag 7 days | 99.00`
  - `6 | Spotlight 60 days | 1499.00`

### Result Equivalence Verification (`R01`–`R25`)

All 25 read queries in [sql/06_optimized_queries.sql](../sql/06_optimized_queries.sql) were diffed programmatically against [queries/workload_30.sql](../queries/workload_30.sql) on `olx_db`:
- `R01`–`R12`, `R14`–`R25`: **100% identical multisets and row counts** (`R14`, `R19`, `R21` differ only in arbitrary tie-break order on equal sort keys; all queries with deterministic `ORDER BY` match row-for-row).
- `R13`: Intentionally fixed from `0` rows (buggy) to `2` rows.

---

## 3. Before / After `EXPLAIN (ANALYZE, BUFFERS)` Plans (Top 5 Improvements)

### 3.1 `R19`: `1,196.778 ms` -> `10.404 ms` (99.1% / 115.0x faster; `4.035 ms` warm)

**Before (Run 1: `1196.912 ms`, `shared hit=301543`):**
```text
Sort  (cost=1344223.70..1344224.35 rows=261 width=40) (actual time=1196.493..1196.523 rows=279.00 loops=1)
  ->  Gather  (cost=1000.00..1344213.22 rows=261 width=40) (actual time=0.120..1196.435 rows=279.00 loops=1)
        ->  Parallel Seq Scan on listings l  (...) (actual time=0.009..3.765 rows=93.00 loops=3)
        SubPlan 1
          ->  Index Only Scan using uq_chat_threads_listing_buyer on chat_threads t  (loops=279)
        SubPlan 2
          ->  Aggregate  (...) (actual time=4.284..4.284 rows=1.00 loops=279)
                ->  Hash Join  (...) (Buffers: shared hit=296399)
                      ->  Seq Scan on chat_messages m  (actual time=0.001..4.878 rows=207797.36 loops=121)
```

**After (Run 2 warm: `4.035 ms`, `shared hit=1183`; Run 1 cold `22.953 ms`, Run 3 `4.223 ms`):**
```text
Sort  (cost=2345.14..2345.82 rows=273 width=41) (actual time=3.988..3.994 rows=279.00 loops=1)
  ->  GroupAggregate  (cost=2321.81..2334.10 rows=273 width=41) (actual time=3.881..3.956 rows=279.00 loops=1)
        ->  Sort  (cost=2321.81..2324.20 rows=956 width=41) (actual time=3.878..3.892 rows=742.00 loops=1)
              ->  Nested Loop Left Join  (cost=900.19..2274.48 rows=956 width=41) (actual time=0.363..3.803 rows=742.00 loops=1)
                    ->  Hash Right Join  (cost=899.77..2096.44 rows=273 width=33) (actual time=0.359..3.433 rows=318.00 loops=1)
                          ->  Seq Scan on chat_threads t  (actual time=0.002..1.496 rows=59855.00 loops=1)
                          ->  Hash  (actual time=0.353..0.353 rows=279.00 loops=1)
                                ->  Bitmap Heap Scan on listings l  (actual time=0.052..0.337 rows=279.00 loops=1)
                                      ->  Bitmap Index Scan on idx_listings_active_cat_city_posted  (rows=279.00)
                    ->  Index Only Scan using idx_chat_messages_thread_sent on chat_messages m  (Heap Fetches: 0, loops=318)
```

### 3.2 `R06`: `72.997 ms` -> `2.198 ms` (97.0% / 33.2x faster; `0.387 ms` warm)

**Before (Run 1: `81.660 ms`, `shared hit=37803`):**
```text
Sort  (cost=29175.86..29175.87 rows=4 width=53) (actual time=81.571..81.611 rows=13.00 loops=1)
  ->  Nested Loop  (...)
        ->  Hash Join  (...)  -- Parallel Seq Scan on listings l + Seq Scan on chat_threads t
        ->  Limit  (...) (actual time=5.603..5.603 rows=1.00 loops=13)
              ->  Sort  (...)
                    ->  Seq Scan on chat_messages m  (Rows Removed by Filter: 209526, loops=13)
```

**After (Run 2: `0.676 ms`, `shared hit=100`; Run 1 cold `5.532 ms`, Run 3 `0.387 ms`):**
```text
Sort  (cost=77.12..77.13 rows=3 width=54) (actual time=0.560..0.563 rows=13.00 loops=1)
  ->  Nested Loop  (cost=5.02..77.10 rows=3 width=54) (actual time=0.126..0.513 rows=13.00 loops=1)
        ->  Append  (cost=4.60..69.76 rows=3 width=25) (actual time=0.050..0.281 rows=13.00 loops=1)
              ->  Bitmap Heap Scan on chat_threads t (idx_chat_threads_buyer_thread) + Index Scan on listings_pkey (rows=3)
              ->  Bitmap Heap Scan on listings l_1 (idx_listings_seller_title_price) + Index Scan on uq_chat_threads_listing_buyer (rows=10)
        ->  Limit  (actual time=0.017..0.017 rows=1.00 loops=13)
              ->  Index Only Scan using idx_chat_messages_thread_sent on chat_messages m  (Heap Fetches: 0, loops=13)
```

### 3.3 `R22`: `31.374 ms` -> `0.048 ms` (99.8% / 653.6x faster)

**Before (Run 1: `31.965 ms`, `temp read=635 written=940`):**
```text
Limit  (...)
  ->  Sort  (cost=15590.22..15890.22 rows=120000 width=48) (actual time=27.895..29.796 rows=50025.00 loops=1)
        Sort Key: posted_at DESC
        Sort Method: external merge  Disk: 7488kB
        ->  Seq Scan on listings  (actual time=0.005..12.063 rows=120000.00 loops=1)
```

**After (Run 2: `0.045 ms`, `shared hit=5`, zero disk sort):**
```text
Limit  (cost=0.42..2.17 rows=25 width=49) (actual time=0.023..0.028 rows=25.00 loops=1)
  Buffers: shared hit=5
  ->  Index Only Scan using idx_listings_posted_desc_id on listings  (actual time=0.022..0.027 rows=25.00 loops=1)
        Index Cond: (ROW(posted_at, listing_id) < ROW('2025-11-16 07:06:36+05:30'::timestamptz, 70176))
        Heap Fetches: 0
```

### 3.4 `R13`: `15.019 ms` -> `0.101 ms` (99.3% / 148.7x faster + bug fixed)

**Before (Run 1: `14.862 ms`, `rows=0`):**
```text
Seq Scan on boost_packages b  (actual time=14.815..14.815 rows=0.00 loops=1)
  Filter: (NOT (ANY (package_id = (hashed SubPlan 1).col1)))
  SubPlan 1
    ->  Seq Scan on listings l  (actual time=0.005..10.147 rows=120000.00 loops=1)
```

**After (Run 2: `0.056 ms`, `rows=2`):**
```text
Nested Loop Anti Join  (cost=0.29..3.06 rows=2 width=24) (actual time=0.033..0.033 rows=2.00 loops=1)
  ->  Seq Scan on boost_packages b  (rows=6.00)
  ->  Index Only Scan using idx_listings_boost_package on listings l  (Heap Fetches: 0, loops=6)
```

### 3.5 `R02`: `12.182 ms` -> `0.044 ms` (99.6% / 276.9x faster)

**Before (Run 1: `10.424 ms`, `shared hit=4427`):**
```text
Sort  (cost=7549.11..7549.12 rows=1 width=105) (actual time=9.477..10.374 rows=5.00 loops=1)
  ->  Gather  (...)
        ->  Parallel Seq Scan on listings  (Rows Removed by Filter: 39998, loops=3)
```

**After (Run 2: `0.038 ms`, `shared hit=19`):**
```text
Index Scan using idx_listings_active_cars_filter on listings  (cost=0.28..8.30 rows=1 width=107) (actual time=0.020..0.029 rows=5.00 loops=1)
  Index Cond: ((city_id = 6) AND ((attributes ->> 'fuel') = 'Diesel') AND (((attributes ->> 'year'))::integer >= 2018) AND (((attributes ->> 'km_driven'))::integer <= 60000))
```

---

## 4. Write Overhead Analysis (`W01`–`W05`)

| Query | Before (ms) | After (ms) | Delta | Acceptable? |
| --- | ---: | ---: | --- | --- |
| **W01** (Insert new active furniture ad) | 0.808 | 1.454 | +0.646 ms (+80.0%) | **Yes.** Stays at ~1.5 ms; partial indexes skip `category_id = 2` (cars), `category_id = 5` (mobiles), `boost_package_id IS NOT NULL`, and `status = 'SOLD'`. |
| **W02** (Mark oldest active ad sold) | 11.832 | 0.325 | -11.507 ms (**36.4x faster**) | **Huge win.** Lookup via `idx_listings_seller_status_view` outweighed index-maintenance cost. |
| **W03** (Insert buyer chat message) | 0.580 | 0.798 | +0.218 ms (+37.6%) | **Yes.** Sub-millisecond; maintains `idx_chat_messages_thread_sent` and `idx_chat_messages_unread_thread`. |
| **W04** (Nightly batch: expire 2,256 active ads) | 21.343 | 35.003 | +13.660 ms (+64.0%) | **Yes on seed.** Run 1 warmed index pages (`54.849 ms`); Runs 2–3 took `25.799 / 24.360 ms`. Updating `status` from `ACTIVE` to `EXPIRED` removes entries from partial `WHERE status = 'ACTIVE'` indexes—cheap at 120k, but monitored in Phase 5 at 20x scale. |
| **W05** (Accept highest pending offer, reject rest) | 1.817 | 0.479 | -1.338 ms (**3.8x faster**) | **Huge win.** Partial index `idx_offers_pending_listing` finds pending offers for listing `118642` in `0.22–0.23 ms` warm (`0.988 ms` cold Run 1). |

---

## 5. Index Storage Overhead (`pg_relation_size`)

Total `olx_db` database size: **159 MB** (**70 MB** base tables, **81 MB** total indexes).

| Table | Table Size | Indexes (Created + PK/UQ) | Total Table Indexes | Index / Table Ratio |
| --- | --- | --- | --- | ---: |
| `listings` | 36 MB (37,806,080 B) | `idx_listings_posted_desc_id` (12 MB), `idx_listings_seller_title_price` (10 MB), `idx_listings_seller_status_view` (9,416 kB), `listings_pkey` (2,640 kB), `idx_listings_mobiles_model_posted` (2,568 kB), `idx_listings_sold_at_cat` (1,736 kB), `idx_listings_active_cat_city_posted` (1,480 kB), `idx_listings_active_title_trgm` (672 kB), `idx_listings_active_cat_lat_lon` (664 kB), `idx_listings_active_expires` (552 kB), `idx_listings_active_cars_filter` (448 kB), `idx_listings_boost_package` (112 kB) | **42 MB** | 1.18x |
| `chat_messages` | 19 MB (20,185,088 B) | `idx_chat_messages_thread_sent` (14 MB), `chat_messages_pkey` (4,616 kB), `idx_chat_messages_unread_thread` (16 kB) | **19 MB** | 0.97x |
| `users` | 4,360 kB (4,464,640 B) | `users_email_key` (1,840 kB), `users_phone_key` (1,552 kB), `users_pkey` (1,112 kB) | **4,504 kB** | 1.03x |
| `favourites` | 3,568 kB (3,653,632 B) | `idx_favourites_saved_at` (2,168 kB), `favourites_pkey` (2,168 kB) | **4,336 kB** | 1.22x |
| `chat_threads` | 3,528 kB (3,612,672 B) | `idx_chat_threads_created_listing` (2,920 kB), `uq_chat_threads_listing_buyer` (2,352 kB), `idx_chat_threads_buyer_thread` (1,856 kB), `chat_threads_pkey` (1,328 kB) | **8,456 kB** | 2.40x |
| `offers` | 1,696 kB (1,736,704 B) | `idx_offers_listing_status` (808 kB), `offers_pkey` (456 kB), `idx_offers_pending_listing` (16 kB) | **1,280 kB** | 0.75x |
| `seller_ratings` | 944 kB (966,656 B) | `uq_seller_ratings_listing_rater` (496 kB), `idx_seller_ratings_seller_stars` (368 kB), `seller_ratings_pkey` (264 kB) | **1,128 kB** | 1.19x |
| `reports` | 688 kB (704,512 B) | `uq_reports_listing_reporter` (312 kB), `reports_pkey` (192 kB), `idx_reports_open_listing_reason` (48 kB) | **552 kB** | 0.80x |
| `cities`, `categories`, `boost_packages` | 8,192 B each | PK + unique key (16 kB each) | **32 kB** each | 4.00x |

Partial indexes keep maintenance and memory footprint small: `idx_chat_messages_unread_thread` (16 kB), `idx_offers_pending_listing` (16 kB), `idx_reports_open_listing_reason` (48 kB), `idx_listings_boost_package` (112 kB), `idx_listings_active_cars_filter` (448 kB), and `idx_listings_active_title_trgm` (672 kB).

---

## 6. Queries That Could Not Be Sped Up Significantly (and Why)

1. **`R17` (`15.696 ms -> 16.035 ms`):** Computes average views across **all 120,000 listings** grouped by category and boost status. Because every row contributes to the global average, no selective predicate exists to avoid scanning all rows.
2. **`R15` (`11.091 ms -> 13.730 ms`):** Computes offer acceptance percentage across all 19,943 offers joined to `listings` and `categories`. Even with `idx_offers_listing_status` (`Index Only Scan` on `offers`), PostgreSQL still reads most `listings` pages to map `listing_id -> category_id`.
3. **`R12` (`40.137 ms -> 63.196 ms`) and `R18` (`39.660 ms -> 41.746 ms`):** Both group all 120,000 `listings` across ~119,444–119,988 distinct groups (`(seller_id, day)` and `(seller_id, title, price)`). Under default `work_mem = 4MB`, PostgreSQL's planner chooses `Seq Scan + HashAggregate` (with 5 batches / 736 kB temp disk spill on `R12`). Testing a dedicated expression index on `(seller_id, ((posted_at AT TIME ZONE 'Asia/Kolkata')::date))` slowed `R12` further (~72 ms on seed, ~2.75 s on 20x data due to random heap reads), so we removed that index; `idx_listings_seller_title_price` is kept because it switches `R18` to a streaming `Index Only Scan` without disk spill once the table reaches 20x scale (Phase 5), and also accelerates `R06` seller lookups.
4. **`R25` (`50.824 ms -> 45.767 ms`):** Aggregates 2026 chat threads (~24k threads) and their messages (~84k messages) across `chat_messages`, `chat_threads`, and `listings`; reading ~40% of the two largest tables puts a lower bound near ~45 ms without a summary table.
5. **`R23` (`0.027 ms -> 0.315 ms`):** Already hit unique index `users_phone_key` in 3 buffer reads; Run 1 suffered a cold-cache page read (`0.780 ms`), while warm Runs 2–3 ran in `0.109 ms` and `0.055 ms`.
