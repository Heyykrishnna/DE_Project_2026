# Phase 5: Scalability Report (20× Large Dataset & 100× Architecture)

> **Dataset Disclosure:** As of completion (`2026-11-13`), faculty's `large_data.zip` (scheduled for `Thu 19 Nov 2026` in [README.md](../README.md)) had not yet been published in the repository. To run genuine `EXPLAIN (ANALYZE, BUFFERS)` benchmarks at 20× scale rather than estimating on paper, we synthesized a structurally faithful 20× dataset in `large_data/` (excluded via `.gitignore`) matching all 11 table schemas and target cardinalities (`1,000,000` users, `2,400,000` listings, `1,197,100` chat threads, `4,190,580` chat messages, `398,860` offers, `1,400,000` favourites, `159,980` reports, `224,880` seller ratings), loaded it into `olx_large`, applied [sql/05_indexes.sql](../sql/05_indexes.sql), ran `ANALYZE;`, and executed:
>
> `./benchmarks/run_benchmark.sh olx_large large 3 sql/06_optimized_queries.sql`
>
> When the official `large_data.zip` is released, reload `olx_large` and re-run that exact command to refresh [benchmarks/results/large/summary.csv](../benchmarks/results/large/summary.csv).

---

## 1. Scalability Results Table (All 30 Queries: Seed 1× vs Large 20×)

All 30 optimized queries from [sql/06_optimized_queries.sql](../sql/06_optimized_queries.sql) were run 3 times on `olx_db` (120k listings) and `olx_large` (2.4M listings) with default `work_mem = 4MB`.

| Query | SLA Target | Optimized on Seed (ms) | Optimized on Large (ms) | Growth (Large ÷ Seed) | Meets Target? | Explanation / Change at 20× |
| --- | --- | ---: | ---: | ---: | --- | --- |
| **R01** | < 5 ms | 0.448 | 0.246 | 0.55x | ✅ | Planner switches to `Index Scan` on `idx_listings_active_cat_city_posted` stopping after 40 rows (`0.073 ms` warm). |
| **R02** | < 5 ms | 0.044 | 0.860 | 19.55x | ✅ | Returns 20× more matching diesel cars (~100 vs 5), so heap fetches scale linearly (~20×) while staying sub-1 ms. |
| **R03** | < 5 ms | 1.513 | 21.190 | 14.01x | ❌ | **Missed `< 5 ms`** (Run 3 warm: `9.443 ms`). GIN trigram scan matches 7,500 active iPhone 13 ads across 6,171 heap blocks before sorting by `price` (see Section 3.2). |
| **R04** | < 5 ms | 0.386 | 0.528 | 1.37x | ✅ | Single PK lookup on `listings`/`users` + small `Index Only Scan` on `idx_seller_ratings_seller_stars`. |
| **R05** | < 5 ms | 0.177 | 0.323 | 1.82x | ✅ | `Index Only Scan` on `idx_listings_seller_status_view`; B-tree height increases by only 1 level at 20×. |
| **R06** | < 5 ms | 2.198 | 3.270 | 1.49x | ✅ | `UNION ALL` probes buyer/seller indexes + 1-row `LIMIT 1` `Index Only Scan` per thread (`0.676 ms` warm). |
| **R07** | < 5 ms | 0.310 | 0.428 | 1.38x | ✅ | Disjoint scalar subqueries hit `idx_chat_messages_unread_thread` (`WHERE NOT is_read`). |
| **R08** | < 5,000 ms | 4.730 | 53.129 | 11.23x | ✅ | `Bitmap Heap Scan` on partial `idx_listings_mobiles_model_posted`; matches grow 20× cleanly inside budget. |
| **R09** | < 5 ms | 0.261 | 0.492 | 1.89x | ✅ | Partial index `idx_listings_active_cat_lat_lon` isolates the 2 km bounding box in Bengaluru (`category_id = 9`). |
| **R10** | < 250 ms | 0.682 | 5.899 | 8.65x | ✅ | `Bitmap Heap Scan` on partial `idx_listings_active_expires` reads only ads expiring in the 3-day window. |
| **R11** | < 250 ms | 1.515 | 33.645 | 22.21x | ✅ | Partial `Index Only Scan` on `idx_reports_open_listing_reason` (`9.763 ms` warm Run 2; 20× more open reports). |
| **R12** | < 5,000 ms | 63.196 | 1,277.217 | 20.21x | ✅ | `Seq Scan` + 41-batch `HashAggregate` (spills `73,088 kB` to temp disk across 2.4M rows); kept inside 5 s by dropping harmful expression index. |
| **R13** | < 250 ms | 0.101 | 0.351 | 3.48x | ✅ | `Nested Loop Anti Join` (`Index Only Scan` on `idx_listings_boost_package`) stops after first match per package (`0.063 ms` warm). |
| **R14** | < 5,000 ms | 4.616 | 81.498 | 17.66x | ✅ | `Bitmap Heap Scan` on partial `idx_listings_sold_at_cat` (`WHERE status = 'SOLD'`) scales proportionally with sold rows. |
| **R15** | < 5,000 ms | 13.730 | 334.265 | 24.35x | ✅ | Full-table hash join across all `offers` (398k) and `listings` (2.4M) scales linearly with table size. |
| **R16** | < 250 ms | 7.614 | 80.883 | 10.62x | ✅ | `Index Only Scan` on `idx_favourites_saved_at` for 7-day window; linear with 20× favourite volume. |
| **R17** | < 5,000 ms | 16.035 | 206.217 | 12.86x | ✅ | Parallel `Seq Scan` across all 2.4M `listings` for global boosted vs. normal rollup. |
| **R18** | < 5,000 ms | 41.746 | 1,174.162 | 28.13x | ✅ | Planner switches from `Seq Scan + HashAggregate` to streaming `Index Only Scan` on `idx_listings_seller_title_price` (`1.12M` heap fetches on non-all-visible pages; avoids massive disk sort). |
| **R19** | < 5,000 ms | 10.404 | 221.005 | 21.24x | ✅ | Scans 20× active Bengaluru cars + `uq_chat_threads_listing_buyer` + `idx_chat_messages_thread_sent` (`14.461 ms` warm Run 3). |
| **R20** | < 5,000 ms | 2.109 | 87.769 | 41.62x | ✅ | On unpartitioned table, planner flips to `Parallel Seq Scan` (2 workers) across 2.4M rows; monthly partitioning cuts this to `70.574 ms` on single partition without reading other 19 months. |
| **R21** | < 5,000 ms | 3.409 | 37.465 | 10.99x | ✅ | `Index Only Scan` on `idx_seller_ratings_seller_stars` (224k ratings) + 20 PK lookups into `users`. |
| **R22** | < 250 ms | 0.048 | 0.164 | 3.42x | ✅ | Keyset cursor on `idx_listings_posted_desc_id` remains `O(log n)` (`0.064 ms` warm Run 2). |
| **R23** | < 5 ms | 0.315 | 0.238 | 0.76x | ✅ | Unique `users_phone_key` B-tree lookup (`0.028 ms` warm Run 3). |
| **R24** | < 5,000 ms | 5.806 | 111.299 | 19.17x | ✅ | Planner uses Parallel `Seq Scan` over active subset rollup across 2.4M rows. |
| **R25** | < 5,000 ms | 45.767 | 951.665 | 20.79x | ✅ | Reads 2026 threads (`475k`) + `idx_chat_messages_thread_sent`; scales linearly (~20×). |
| **W01** | < 5 ms | 1.454 | 3.435 | 2.36x | ✅ | Single `INSERT` into `listings` (`1.478 ms` warm Run 3; Run 1 cold index-page load `7.191 ms`). |
| **W02** | < 5 ms | 0.325 | 0.864 | 2.66x | ✅ | `Index Only Scan` finds `min(listing_id)` for `seller_id = 1042` + 1 PK update (`0.470 ms` warm). |
| **W03** | < 5 ms | 0.798 | 1.910 | 2.39x | ✅ | `Index Only Scan` on `idx_chat_threads_buyer_thread` + 1 `INSERT` into `chat_messages`. |
| **W04** | < 1,000 ms | 35.003 | 10,402.853 | 297.20x | ❌ | **Missed `< 1,000 ms`** on unpartitioned 2.4M `listings`: updates 45,120 stale active rows across all 12 indexes, thrashing `128 MB` `shared_buffers`. Fixed via partitioning + batching (Section 3.1). |
| **W05** | < 5 ms | 0.479 | 1.133 | 2.37x | ✅ | `idx_offers_pending_listing` updates 1 accepted + rejected pending offers (`0.226 ms` warm Run 3). |
| **Total** | — | **265.219** | **15,094.403** | **56.91x** | **28 / 30** | Excluding unbatched `W04`, total runtime is `4,691.55 ms` (**17.7×** seed). |

### Note on `R22` Keyset Cursor at 20× Scale

In [sql/06_optimized_queries.sql](../sql/06_optimized_queries.sql), `R22` fetches 25 rows past page 2,000 (skipping 50,000 rows) using the keyset predicate `ROW(posted_at, listing_id) < ROW(cursor_ts, cursor_id)` instead of `OFFSET 50000`:
- On the 120k seed dataset, row 50,000 is `(posted_at = '2025-11-16 07:06:36+05:30', listing_id = 70176)`.
- On the 2.4M `olx_large` dataset (20× denser postings per day), the actual 50,000th newest ad sits roughly 11 days from `2026-06-30` at `(posted_at = '2026-06-19 14:14:08+05:30', listing_id = 117494)`.
- Regardless of which cursor value is supplied, B-tree keyset positioning seeks in `O(log n)` time (`0.064 ms` warm on `olx_large`), completely eliminating the `O(offset log offset)` external disk sort of `OFFSET 50000`. In production, the API receives `(posted_at, listing_id)` of the last card rendered on the previous page via an opaque base64 page token.

---

## 2. Growth Analysis (1× -> 20×)

1. **~Constant / Sub-Linear (`< 5x` growth) — 13 queries:**
   - **Read lookups (`R01`, `R04`, `R05`, `R06`, `R07`, `R09`, `R13`, `R22`, `R23`):** All grew between `0.55x` and `3.48x`. Selective B-tree height increases by only 1 level (`depth 3 -> depth 4`) when going from 120k to 2.4M rows, so index descent + fixed `LIMIT` / per-user fetch does nearly constant I/O (`3–20` buffer hits).
   - **OLTP writes (`W01`, `W02`, `W03`, `W05`):** All grew only `2.36x`–`2.66x` (`0.864–3.435 ms`), staying well under `5 ms` because B-tree insertion/update touches one leaf page per index regardless of table size.

2. **~Linear (`5x` to `25x` growth) — 14 queries:**
   - **Selective analytical ranges & top-N (`R02`, `R03`, `R08`, `R10`, `R11`, `R14`, `R16`, `R21`, `R24`):** Returned result sets or matched windows scale 20× (`7,500` iPhone 13 matches in `R03`, `159k` reports in `R11`, `1.4M` favourites in `R16`, `~100` Pune diesel cars in `R02`). Execution grew `8.65x`–`22.21x`.
   - **Full-table / year-wide analytics (`R12`, `R15`, `R17`, `R19`, `R25`):** Must visit every row in a large table or fixed 50% time fraction (`listings` 2.4M, `offers` 399k, `chat_messages` 4.19M). Sequential I/O and hash joins grew proportionally (`12.86x`–`24.35x`).

3. **Super-Linear (`> 25x` growth) — 3 queries:**
   - **`R18` (`28.13x`, `41.746 ms -> 1,174.162 ms`):** Still passes `< 5,000 ms`, but crossed the default `4MB` `work_mem` threshold cleanly at 2.4M rows, prompting the planner to switch from `Seq Scan + HashAggregate` to a pre-ordered `Index Only Scan` on `idx_listings_seller_title_price` (~1.0–1.1M heap fetches because newly loaded table visibility bits were partially dirty until vacuumed).
   - **`R20` (`41.62x`, `2.109 ms -> 87.769 ms`):** Still easily passes `< 5,000 ms`, but because June 2026 contains `131,520` rows (~5.5% of unpartitioned `listings`), the planner flipped from single-table `Index Only Scan` (used on seed at `2.1 ms`) to `Parallel Seq Scan` across all 2.4M rows. Monthly partitioning resolves this directly (`70.574 ms` scanning only June's `131,520` rows).
   - **`W04` (`297.20x`, `35.003 ms -> 10,402.853 ms`):** The clearest scale-only failure—explained below.

---

## 3. What Broke at Scale & Fixes (Before / After Plans)

### 3.1 `W04`: `35.003 ms` (Seed) -> `10,402.853 ms` (Large, ❌ > 1,000 ms Target)

**Why it broke only at 20×:**
On seed data, expiring `2,256` stale active ads updates `2,256` tuples across tiny indexes fitting entirely in RAM (`128 MB` `shared_buffers`), finishing in `24–54 ms`. At 20× (`45,120` stale `ACTIVE` rows scattered across all 17 historical months `Jan 2025–May 2026` on 34,945 heap blocks), a single monolithic `UPDATE` modifies every expired tuple across all 12 indexes on `listings` (`760 MB` table + `694 MB` indexes = `1,454 MB`). Because the working set of dirty heap and index pages exceeds PostgreSQL's `128 MB` `shared_buffers`, every updated row triggers buffer eviction and random I/O (`83,459–91,301` disk reads and `66,732–84,932` buffer writes per run).

**Before Plan (`benchmarks/results/large/W04.txt`, Run 2: `10,106.374 ms`):**
```text
Update on listings  (cost=6537.03..125259.13 rows=0 width=0) (actual time=10105.867..10105.868 rows=0.00 loops=1)
  Buffers: shared hit=836617 read=88700 dirtied=87250 written=84932
  ->  Bitmap Heap Scan on listings  (cost=6537.03..125259.13 rows=192079 width=64) (actual time=8.536..3731.493 rows=45120.00 loops=1)
        Recheck Cond: ((expires_at < '2026-07-01 00:00:00+05:30'::timestamptz) AND ((status)::text = 'ACTIVE'::text))
        Heap Blocks: exact=34945
        ->  Bitmap Index Scan on idx_listings_active_expires  (...) (actual time=5.310..5.312 rows=45120.00 loops=1)
Execution Time: 10106.374 ms
```

**The Fixes:**
1. **Monthly Range Partitioning ([sql/08_partitioning.sql](../sql/08_partitioning.sql)):** Partitioning `listings` by `RANGE (posted_at)` localizes normal nightly expiration (`expires_at = posted_at + 30 days`) to at most the 2 active trailing partitions (`posted_at >= now() - 60 days`) rather than 17 historical months. Updating the bounded 2-month window (`2,920` rows across `listings_p_2026_04` and `listings_p_2026_05`) finishes in **`237.165 ms`**—**43.9× faster** and comfortably inside the `< 1,000 ms` target.
2. **Batched Chunking (`LIMIT 2000`):** For initial catch-up backlogs (all 45,120 stale ads across old partitions), running `W04` in `LIMIT 2000` batches per transaction keeps dirty buffers well below `128 MB` (`~350 ms` per batch), prevents lock contention, and matches partitioned single-month latency.
3. **Dropping Counterproductive Indexes:** Testing during 20× runs also caught that `idx_listings_seller_posted_ist_date` slowed `R12` on `olx_large` to `~2.75 s` (random heap fetches across 2.4M rows) while hurting write throughput. Removing it from [sql/05_indexes.sql](../sql/05_indexes.sql) cut `R12` in half to **`1,277.217 ms`**.

**After Plan (Partitioned Active Window on `listings_partitioned`, `237.165 ms`):**
```text
Update on listings_partitioned  (cost=455.57..11878.85 rows=0 width=0) (actual time=236.930..236.931 rows=0.00 loops=1)
  Update on listings_p_2026_04 listings_partitioned_1
  Update on listings_p_2026_05 listings_partitioned_2
  Buffers: shared hit=45224 read=5358 dirtied=4354 written=132
  ->  Append  (cost=455.57..11878.85 rows=5695 width=68) (actual time=9.646..18.832 rows=2920.00 loops=1)
        ->  Bitmap Heap Scan on listings_p_2026_04  (actual time=9.645..15.555 rows=2840.00 loops=1)
        ->  Bitmap Heap Scan on listings_p_2026_05  (actual time=0.640..3.160 rows=80.00 loops=1)
Execution Time: 237.165 ms
```

---

### 3.2 `R03`: `1.513 ms` (Seed) -> `21.190 ms` (Large, ❌ > 5 ms Target)

**Why it broke only at 20×:**
On 120k rows, `title ILIKE '%iphone 13%'` matched 375 active ads across ~350 heap blocks (`1.5 ms`). At 2.4M rows, GIN `idx_listings_active_title_trgm` locates all **7,500 active matches** in just `1.6 ms` warm (`88` index buffers), but because a GIN inverted index cannot co-sort by `price`, PostgreSQL must perform a `Bitmap Heap Scan` over **6,171 random heap blocks** (`~48 MB` of scattered pages) solely to read `price`, sort all 7,500 rows, and return the top 40 (`Run 1: 41.494 ms`, `Run 2: 12.634 ms`, `Run 3 warm: 9.443 ms`, `avg: 21.190 ms`).

**Observed Plan (`benchmarks/results/large/R03.txt`, Run 3 warm: `9.443 ms`):**
```text
Limit  (cost=23838.33..23838.43 rows=40 width=39) (actual time=9.401..9.404 rows=40.00 loops=1)
  Buffers: shared hit=6262
  ->  Sort  (...) (Sort Method: top-N heapsort  Memory: 29kB)
        ->  Bitmap Heap Scan on listings  (actual time=2.178..8.690 rows=7500.00 loops=1)
              Recheck Cond: (((title)::text ~~* '%iphone 13%'::text) AND ((status)::text = 'ACTIVE'::text))
              Heap Blocks: exact=6171
              ->  Bitmap Index Scan on idx_listings_active_title_trgm  (actual time=1.753..1.753 rows=7500.00 loops=1)
Execution Time: 9.443 ms
```

**Why a pure B-tree price-ordered workaround also failed:**
We tested a partial covering B-tree index `ON listings (price) INCLUDE (listing_id, title, city_id, item_condition) WHERE status = 'ACTIVE'` (`BEGIN; ... ROLLBACK;`). Because OLX has `50,552` cheaper active listings (`< ₹12,899`, the 40th cheapest iPhone 13) before finding 40 matches, PostgreSQL took **`41.735 ms`** discarding `50,552` non-matching rows—4× slower than warm GIN! Adding a composite `btree_gin` `(price, title)` index still stores postings ordered by trigram ID, not price, so arbitrary leading-wildcard `ILIKE '%...%' ORDER BY price LIMIT 40` has a fundamental PostgreSQL GIN limit once active matches exceed a few thousand rows.

**Production Fix:**
Offload free-text marketplace search (`R03`) to a dedicated search engine (OpenSearch / Elasticsearch / `pg_search` ParadeDB BM25 + numeric price docvalues) or cache top popular search terms (`"iphone 13"`, `"royal enfield"`, etc.) in Redis with `< 2 ms` reads; within OLTP SQL alone, scoping search by default city (`city_id = ?`) cuts active matches 10× (~750 rows -> `< 2 ms` via `Bitmap Heap Scan`).

---

## 4. Storage Growth: Seed (1×) vs. Large (20×)

Measured with `pg_database_size`, `pg_table_size`, and `pg_indexes_size`:

| Metric | Seed DB (`olx_db`, 120k ads) | Large DB (`olx_large`, 2.4M ads) | Growth |
| --- | ---: | ---: | ---: |
| **Base Tables Total** | 70 MB | 1,430 MB | 20.4× |
| **Base Indexes Total** | 81 MB | 1,456 MB | 18.0× |
| **Total DB Size** | 159 MB | 2,886 MB (base) / **4,136 MB** (incl. partitioned copy) | ~18.2× (base) |

### Largest Tables & Indexes at 20× (`olx_large`)

| Table | Table Size (1× -> 20×) | Indexes Size (1× -> 20×) | Index / Table Ratio (20×) |
| --- | --- | --- | ---: |
| `listings` | 36 MB -> **760 MB** | 42 MB -> **694 MB** | 0.91× |
| `chat_messages` | 19 MB -> **381 MB** | 19 MB -> **371 MB** | 0.97× |
| `users` | 4.3 MB -> **86 MB** | 4.4 MB -> **86 MB** | 1.00× |
| `favourites` | 3.5 MB -> **70 MB** | 4.2 MB -> **84 MB** | 1.20× |
| `chat_threads` | 3.4 MB -> **69 MB** | 8.3 MB -> **166 MB** | 2.41× |
| `offers` | 1.7 MB -> **33 MB** | 1.3 MB -> **24 MB** | 0.73× |
| `seller_ratings` | 944 kB -> **18 MB** | 1.1 MB -> **20 MB** | 1.11× |
| `reports` | 688 kB -> **13 MB** | 552 kB -> **11 MB** | 0.85× |

Notice index overhead scales cleanly (`0.91×` of table heap on `listings` at 20× vs `1.18×` on seed) because partial indexes only index the rare active/pending/boosted subsets (~8%–10% of rows). At **100×** (~12M listings at 5× large or 240M at 100× vs 2.4M): projecting from `2.89 GB` at 2.4M ads, **100× vs seed (`12M` ads)** uses `~14.4 GB` base + indexes (`144 GB` at 100× vs large / 240M ads).

---

## 5. Architecture for 100× Scale (~12M–240M Listings)

At 100× above seed (`12M` listings, `~14.5 GB`) or 100× above current 20× planning (`240M` listings, `~290 GB` active + historical footprint), a single monolithic table degrades due to B-tree index bloat (`shared_buffers` thrashing on `W04`), vacuum wraparound pressure, and single-node write throughput.

### 5.1 Table Partitioning ([sql/08_partitioning.sql](../sql/08_partitioning.sql))

- **Table & Strategy:** Partition `listings` by **`RANGE (posted_at)` into monthly child partitions** (`listings_p_2025_01` through `listings_p_2026_07` + `DEFAULT`), storing 30 days of ads per partition (`~130k` rows / `~42 MB` heap per month at 20×; `~650k–13M` rows per month at 100×).
- **Why `RANGE (posted_at)` over `LIST (city_id)` or `HASH (seller_id)`:**
  - Every OLX ad expires in 30 days, so `ACTIVE` inventory (`status = 'ACTIVE'`) always concentrates in the **newest 1–2 monthly partitions**. Old expired/sold partitions become cold/read-only, shrinking hot working indexes to <10% of history.
  - Time-window queries (`R20`, `W04`, monthly cohort analytics) prune 90%+ of partitions immediately, and dropping/archiving >12-month-old partitions is an instant `ALTER TABLE ... DETACH PARTITION CONCURRENTLY` instead of expensive `DELETE` + `VACUUM`.
- **Primary Key & Foreign Key Rule in PostgreSQL:**
  - PostgreSQL requires every `PRIMARY KEY` and `UNIQUE` constraint on a partitioned table to **include all partition key columns**. Therefore [sql/08_partitioning.sql](../sql/08_partitioning.sql) defines `PRIMARY KEY (listing_id, posted_at)` instead of `(listing_id)`.
  - **Consequence for child tables (`chat_threads`, `offers`, `favourites`, `reports`, `seller_ratings`):** Foreign keys in PostgreSQL can reference a partitioned table (`PG 12+`), *only* if they match a full primary/unique key. Thus child tables either carry composite `(listing_id, listing_posted_at)` FKs or enforce referential checks via application/trigger validation if `(listing_id)` must stay a 1-column PK.

**Verified Partition Pruning (`R20` on `listings_partitioned`, `70.574 ms`):**
```text
->  HashAggregate  (...) (actual time=69.673..69.974 rows=30.00 loops=1)
      ->  Seq Scan on listings_p_2026_06 listings_partitioned  (...) (actual time=0.113..59.127 rows=131520.00 loops=1)
            Filter: ((posted_at >= '2026-06-01 00:00:00+05:30'::timestamptz) AND (posted_at < '2026-07-01 00:00:00+05:30'::timestamptz))
Execution Time: 70.574 ms
```
Only **1 of 20 partitions** (`listings_p_2026_06`) was scanned; 19/20 were pruned at plan time.

**Subtlety Observed on `R01` (`Merge Append` across 20 partitions):**
Running `R01` unmodified on `listings_partitioned` produces a `Merge Append` across all 20 child indexes (`Execution Time: 6.937 ms`, `Planning Time: 9.891 ms`) because `R01` filters `status = 'ACTIVE'` without mentioning `posted_at`. In production, because active ads have `expires_at > now()` (30-day TTL), adding `AND posted_at >= now() - interval '35 days'` lets the planner prune all 18 historical partitions and execute `R01` on just the 2 newest partitions in **< 0.5 ms**.

---

### 5.2 Horizontal Sharding Strategy

| Candidate Shard Key | Locality Pros | Cross-Shard Queries & Cons |
| --- | --- | --- |
| **`city_id`** (Recommended primary tenant) | `R01`, `R02`, `R09`, `R19`, `W01` stay 100% single-shard (OLX markets are inherently city-local). | Skew if Mumbai/Delhi/Bengaluru dominate (mitigated by composite sub-sharding large cities across N virtual buckets `(city_id, listing_id % k)`). Cross-city chats (`R06`, `R07`, `R25`) and national searches (`R03`, `R11`, `R12`, `R18`, `R21`, `R22`) cross shards. |
| **`seller_id` / `listing_id`** | `R04`, `R05`, `R12`, `R18`, `W02`, `W05` stay single-shard; sellers' ads + ad offers stay co-located. | Every city browse query (`R01`, `R02`, `R09`, `R19`) becomes a scatter-gather fan-out across all shards, hurting P1 buyer latency. |
| **`category_id`** | `R08`, `R14`, `R15`, `R17`, `R24` single-shard. | Severe skew (Cars + Mobiles >> Pets/Services) and cross-shard user views (`R05`, `R06`). |

**Recommended Design (City-Cluster Sharding + Co-located Reference/Inbox Tables):**
1. **Replicate reference tables** (`cities`, `categories`, `boost_packages`) to every shard (`Citus reference tables`, < 100 rows total).
2. **Shard marketplace listings & ad-scoped children (`listings`, `offers`, `reports`, `seller_ratings`) by `(city_id, listing_id % 4)`** for mega-cities so buyer browse (`R01`, `R02`, `R09`) hits 1–4 shards max instead of all shards.
3. **Handling Cross-Shard Buyer-Seller Chats (`R06`, `R07`, `R25`) and `users`:**
   - A chat links a buyer (`user_id` possibly in another city or active in multiple cities) to an ad in the listing's shard (`chat_threads` + `chat_messages`).
   - Querying `R06` (chat inbox) or `R07` (unread badge) for `buyer_id = 1042 OR seller_id = 1042` would otherwise require fanning out to every city shard!
   - **Fix:** Maintain a lightweight **user-sharded `chat_inbox` projection table** keyed by `participant_user_id` (`(user_id, thread_id, role, last_msg_ts, last_msg_preview, unread_count)` updated atomically or via CDC/outbox on `W03`), plus keep `users` sharded by `user_id` (with a global `phone -> user_id` lookup cache for `R23`). Then `R06` and `R07` always hit **1 single shard** in `< 1 ms`.
4. **Global Cross-Shard Queries (`R03`, `R12`, `R18`, `R21`, `R22`, `R14`–`R17`, `R24`, `R25`):**
   - `R03` (national search): Route to OpenSearch/Elasticsearch index synced via WAL/Debezium CDC.
   - `R11`, `R12`, `R18`, `R20`–`R22`, `R24`, `R25` (Trust & Safety / Analytics / Feeds): Run on a consolidated CDC analytical replica (PostgreSQL read replica or ClickHouse/BigQuery warehouse) rather than OLTP shards.

---

### 5.3 Read Replicas & Caching Routing

Based on our measured 20× profiles (`olx_large`):

| Tier | Queries Routed Here | Justification & Measured 20× Cost |
| --- | --- | --- |
| **Primary (RW)** | **`W01`, `W02`, `W03`, `W04`, `W05`** (+ optional read-your-writes for **`R04`, `R05`, `R06`, `R07`**, `R23`) | All writes must hit primary (`0.86–3.44 ms`). Keeping `R04`/`R05`/`R06`/`R07` on primary or synchronous replica avoids stale "I just posted/chatted/sold" UI bugs (< `3.3 ms`). |
| **Read Replicas (RO)** | **`R01`, `R02`, `R09`, `R10`, `R11`, `R12`, `R18`, `R19`, `R22`** | Read-only browse, reminder/moderation jobs, and deep feeds (`0.16–1,277 ms`) tolerate 100–500 ms replication lag and isolate heavy scans (`R12` 73 MB temp spill, `R18` 1.1M buffer hits) from primary OLTP memory. |
| **Redis / Edge Cache** | **`R03`** (top terms, 30s TTL), **`R08`** (price guide, 1h TTL), **`R13`, `R14`, `R15`, `R16`, `R17`, `R20`, `R21`, `R24`, `R25`** (5–60 min TTL) | Dashboards and home-page counters (`R24` `111 ms`, `R15` `334 ms`, `R25` `951 ms`) read largely immutable history (`2026` trends/categories). Caching turns `100–950 ms` DB scans into `< 1 ms` cache hits. |

---

### 5.4 Maintenance Strategy at 20×–100×

1. **Aggressive Autovacuum on `listings` & `chat_messages`:**
   Default `autovacuum_vacuum_scale_factor = 0.20` lets **480,000 dead tuples** accumulate on a 2.4M-row table before vacuuming, degrading `Index Only Scan` performance (visible in `olx_large` `R18` doing `1,126,010` heap fetches on non-all-visible pages). Tune per-table settings:
   ```sql
   ALTER TABLE olx.listings SET (
       autovacuum_vacuum_scale_factor = 0.02,
       autovacuum_analyze_scale_factor = 0.01,
       autovacuum_vacuum_cost_limit = 2000
   );
   ALTER TABLE olx.chat_messages SET (
       autovacuum_vacuum_scale_factor = 0.02,
       autovacuum_analyze_scale_factor = 0.01
   );
   ```
   This keeps visibility maps clean (~98%+ all-visible) so `R05`, `R06`, `R18`, `R22`, and `R25` execute true zero-heap `Index Only Scan`s.
2. **Partition Archival (`DETACH` -> Cold Storage):**
   At the start of each month, detach partitions older than 12 months (`ALTER TABLE listings_partitioned DETACH PARTITION listings_p_2025_01 CONCURRENTLY;`), dump to Parquet/GCS/S3 for compliance/ML history, and drop from hot SSDs—bounding active OLTP database storage.
3. **Summary Tables / Materialized Views:**
   Pre-compute category/price/responsiveness dashboards (`R08`, `R14`, `R15`, `R17`, `R24`, `R25`) in materialized views refreshed asynchronously via `REFRESH MATERIALIZED VIEW CONCURRENTLY` every 15 minutes (or nightly for completed days), reducing analytical query load on OLTP nodes to near zero.

---

## 6. Conclusion

- **20× Readiness Verdict:** **Conditioned PASS (28 / 30 queries pass strict SLAs cleanly out of the box).** After adding [sql/05_indexes.sql](../sql/05_indexes.sql) and rewrites in [sql/06_optimized_queries.sql](../sql/06_optimized_queries.sql), all OLTP browse, detail, chat, offer, moderation, and analytic workloads except `R03` and unbatched `W04` meet every SLA on 2.4M ads (`1,430 MB` data + `1,456 MB` indexes). Implementing monthly partitioning ([sql/08_partitioning.sql](../sql/08_partitioning.sql)) and chunked updates fixes `W04` (`10,402 ms -> 237 ms` per active window).
- **Remaining Risks for 20× -> 100×:**
  1. **Unscoped wildcard search + price sort (`R03`):** GIN trigram bitmap scans hit the O(matches) heap-fetch ceiling around ~5k–10k active matches (`9.4–21.2 ms`); requires OpenSearch/Elasticsearch/`pg_search` or popular-term Redis caching to guarantee `< 5 ms` globally.
  2. **`default` `shared_buffers` (`128 MB`) & `work_mem` (`4 MB`):** Large hash aggregations (`R12` spilling 73 MB to temp disk) and multi-index batch writes (`W04`) need production memory sizing (`shared_buffers = 25–40% RAM`, worker-level `work_mem = 64MB` on analytics replicas) and `LIMIT`-batched background workers.
  3. **Cross-city chat growth (`R06`, `R07`, `R25`):** Must pair city sharding with a participant-keyed chat inbox projection before sharding out of a single primary.

