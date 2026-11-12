# Phase 3: Baseline Query Timings (Untuned Schema)

Measured on PostgreSQL 18.6 (`aarch64-apple-darwin`, MacBook Pro M4) against database `olx_db` with only Phase 2 PK/UNIQUE constraint indexes present (`ANALYZE` completed after `\copy`). Each query was executed **3 times** using `./benchmarks/run_benchmark.sh olx_db baseline` with `EXPLAIN (ANALYZE, BUFFERS)`; write queries (`W01`–`W05`) ran inside `BEGIN; ... ROLLBACK;`.

## Summary Timing Table (All 30 Queries)

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
| --- | --- | ---: | ---: | ---: | ---: |
| R01: Browse: active cars in Bengaluru priced ₹3–6 lakh, newest first | READ | 18.682 | 12.536 | 9.453 | 13.557 |
| R02: Car filters: diesel cars from 2018 or later with at most 60,000 km, in Pune | READ | 10.424 | 9.480 | 16.643 | 12.182 |
| R03: Search: active "iPhone 13" ads anywhere, cheapest first | READ | 19.694 | 16.861 | 16.108 | 17.554 |
| R04: Ad page: listing 100871 with its seller and the seller's average rating | READ | 0.485 | 0.571 | 0.770 | 0.609 |
| R05: "My Ads": user 1042's listings grouped by status | READ | 8.938 | 8.891 | 8.847 | 8.892 |
| R06: Chat inbox: every conversation of user 1042 (as buyer or seller) with its latest message | READ | 81.660 | 68.576 | 68.756 | 72.997 |
| R07: Chat badge: unread messages sent to user 1042 | READ | 7.235 | 7.211 | 7.193 | 7.213 |
| R08: Price guide: median asking price of iPhone 13 ads by condition (2026) | READ | 6.402 | 6.628 | 7.176 | 6.735 |
| R09: "Near me": active furniture within ~2 km of central Bengaluru (12.9716, 77.5946) | READ | 8.502 | 7.909 | 7.655 | 8.022 |
| R10: Reminder job: active ads that expire in the first 3 days of July 2026 | READ | 7.621 | 7.076 | 7.267 | 7.321 |
| R11: Moderation queue: ads with 3 or more open reports | READ | 2.554 | 2.367 | 2.173 | 2.365 |
| R12: Spam detection: users who posted 5 or more ads on the same day | READ | 42.335 | 38.920 | 39.155 | 40.137 |
| R13: Monetisation: boost packages that no ad has ever bought | READ | 14.862 | 15.121 | 15.074 | 15.019 |
| R14: Category insights: average days to sell per category for ads sold in 2026 | READ | 10.236 | 9.951 | 9.444 | 9.877 |
| R15: Marketplace health: share of offers accepted, per category | READ | 11.711 | 10.704 | 10.857 | 11.091 |
| R16: Trending: active ads saved to favourites most in the last 7 days of June 2026 | READ | 12.378 | 12.341 | 12.168 | 12.296 |
| R17: Monetisation: average views of boosted vs normal ads per category | READ | 19.761 | 13.528 | 13.798 | 15.696 |
| R18: Quality: the same seller posting the same title at the same price more than once | READ | 40.361 | 37.131 | 41.488 | 39.660 |
| R19: City report: chats and latest chat time for every active car ad in Bengaluru | READ | 1196.912 | 1193.979 | 1199.444 | 1196.778 |
| R20: Growth: new ads per day and running total, June 2026 | READ | 7.862 | 8.234 | 7.984 | 8.027 |
| R21: Trust: best-rated sellers (at least 5 ratings) | READ | 9.755 | 9.680 | 9.218 | 9.551 |
| R22: Moderation console: all ads, newest first, page 2,001 (25 per page) | READ | 31.965 | 31.676 | 30.480 | 31.374 |
| R23: Login with mobile number | READ | 0.028 | 0.029 | 0.023 | 0.027 |
| R24: Home page: active ads per top-level category (sub-categories rolled up) | READ | 14.658 | 13.496 | 20.670 | 16.275 |
| R25: Seller responsiveness: average minutes from a buyer's first message to the seller's first reply, per category (2026) | READ | 46.183 | 41.921 | 64.368 | 50.824 |
| W01: Post an ad: user 1042 sells a study table in Bengaluru | WRITE | 0.935 | 0.734 | 0.754 | 0.808 |
| W02: Mark as sold: user 1042's oldest active ad | WRITE | 12.830 | 11.558 | 11.108 | 11.832 |
| W03: Chat: user 1042 sends a message in their most recent conversation as a buyer | WRITE | 0.691 | 0.614 | 0.435 | 0.580 |
| W04: Nightly job: expire every active ad whose expiry date has passed (run at 00:00 on 1 July 2026) | WRITE | 23.637 | 21.724 | 18.669 | 21.343 |
| W05: Seller accepts the highest pending offer on listing 118642 and rejects the others | WRITE | 1.849 | 1.809 | 1.794 | 1.817 |
| **Total (sum of all 30)** | — | **1671.146** | **1621.256** | **1658.972** | **1650.458** |

## Scan Types & Bottleneck Analysis

| Query | Scan Node(s) in Plan | Why It Is Slow or Fast |
| --- | --- | --- |
| **R01** | `Seq Scan on listings` | Slow: Parallel Seq Scan over all 120,000 `listings` rows (discards ~119,821) + top-N sort because no composite/partial index covers `(category_id, city_id, price, posted_at)` for active ads. |
| **R02** | `Seq Scan on listings` | Slow: Parallel Seq Scan on all 120,000 `listings` evaluating JSONB `->>` casts on every row; no partial/expression/GIN index on `category_id`, `city_id`, or `attributes`. |
| **R03** | `Seq Scan on listings` | Slow: Parallel Seq Scan over 120,000 `listings` running `ILIKE '%iphone 13%'` on every row + sort by `price`; no trigram GIN index on `title`. |
| **R04** | `Index Scan using listings_pkey on listings | Index Scan using users_pkey on users | Seq Scan on seller_ratings` | Moderately fast: `listings_pkey` and `users_pkey` do instant PK lookups, but the correlated subquery on `seller_ratings` falls back to a Seq Scan over all 11,244 rows (`seller_id` is unindexed). |
| **R05** | `Seq Scan on listings` | Slow: Full Seq Scan of 120,000 `listings` discarding 119,991 rows to find user 1042's 9 ads because `seller_id` is unindexed. |
| **R06** | `Seq Scan on listings | Seq Scan on chat_threads | Seq Scan on chat_messages` | Very slow: Hash Join scans all 120k `listings` + 59.8k `chat_threads` for an `OR` across tables, then the `CROSS JOIN LATERAL` runs a full Seq Scan of 209,529 `chat_messages` **13 times** (32,032 buffer hits in `chat_messages` alone). |
| **R07** | `Seq Scan on chat_messages | Index Scan using chat_threads_pkey on chat_threads | Index Scan using listings_pkey on listings` | Slow: Parallel Seq Scan across all 209,529 `chat_messages` looking for `NOT is_read` before joining `chat_threads` and `listings` by PK. |
| **R08** | `Seq Scan on listings` | Slow: Parallel Seq Scan over 120,000 `listings` filtering `category_id = 5`, JSONB `model`, and `posted_at >= 2026-01-01`, plus sorting 1,500 rows for `percentile_cont`. |
| **R09** | `Seq Scan on listings` | Slow: Parallel Seq Scan over 120,000 `listings` checking `category_id`, `status`, `latitude`, and `longitude` bounding box (discards 119,995 rows). |
| **R10** | `Seq Scan on listings` | Slow: Parallel Seq Scan over 120,000 `listings` to locate 625 active listings expiring in a 3-day window; no index on `expires_at`. |
| **R11** | `Seq Scan on reports | Index Scan using listings_pkey on listings` | Moderate: Seq Scan over all 7,999 `reports` filtering `status = 'OPEN'` (816 rows), then PK Index Scan on `listings`; will degrade 20x as reports grow. |
| **R12** | `Seq Scan on listings` | Slow: Full Seq Scan of 120,000 `listings` + HashAggregate spilling to temp disk (150 temp blocks written) because `(seller_id, posted_at::date)` is unindexed. |
| **R13** | `Seq Scan on boost_packages | Seq Scan on listings` | Slow AND wrong result: Full Seq Scan of 120,000 `listings` into a hashed SubPlan; additionally returns **0 rows** instead of 2 because `listings.boost_package_id` contains `NULL`s (`NOT IN` evaluates to `UNKNOWN`). |
| **R14** | `Seq Scan on listings | Seq Scan on categories` | Slow: Parallel Seq Scan of 120,000 `listings` evaluating `EXTRACT(YEAR FROM sold_at) = 2026` on every row; no partial/range index on `sold_at`. |
| **R15** | `Seq Scan on listings | Seq Scan on offers | Seq Scan on categories` | Analytical scan: Full Seq Scan of `offers` (19,943) + Parallel Seq Scan of `listings` (120,000) + `categories` via Hash Join. |
| **R16** | `Seq Scan on listings | Seq Scan on favourites` | Slow: Full Seq Scan of 70,000 `favourites` (`saved_at >= 2026-06-24` has no index) joined against a Seq Scan of 120,000 `listings` (`status = 'ACTIVE'`). |
| **R17** | `Seq Scan on listings | Seq Scan on categories` | Analytical scan: Parallel Seq Scan over all 120,000 `listings` hash-joined with `categories` to aggregate view counts across boosted vs. organic ads. |
| **R18** | `Seq Scan on listings` | Slow: Full Seq Scan of 120,000 `listings` + HashAggregate over `(seller_id, title, price)` spilling to temp disk (386 temp blocks written). |
| **R19** | `Seq Scan on listings | Index Only Scan using uq_chat_threads_listing_buyer on chat_threads | Seq Scan on chat_messages | Index Scan using uq_chat_threads_listing_buyer on chat_threads` | Bottleneck (1.2 s): Parallel Seq Scan on `listings` finds 279 active Bengaluru cars, then correlated `SubPlan 2` executes a **full Seq Scan of 209,529 `chat_messages` inside a loop for all 279 listings** (~296k shared buffer hits). |
| **R20** | `Seq Scan on listings` | Slow: Parallel Seq Scan over all 120,000 `listings` applying non-sargable `posted_at::date BETWEEN ...` instead of an index range scan on `posted_at`. |
| **R21** | `Seq Scan on seller_ratings | Seq Scan on users` | Analytical scan: Full Seq Scan of `seller_ratings` (11,244) and `users` (50,000) for global top-rated seller aggregation. |
| **R22** | `Seq Scan on listings` | Slow: Full Seq Scan of 120,000 `listings` + **external disk merge sort (`7,488 kB` temp disk)** to discard 50,000 rows via `OFFSET 50000` because `posted_at` is unindexed. |
| **R23** | `Index Scan using users_phone_key on users` | Fast (0.027 ms): Uses auto-created unique B-tree index `users_phone_key` (3 shared buffer hits). |
| **R24** | `Seq Scan on listings | Seq Scan on categories` | Slow: Full Seq Scan of 120,000 `listings` discarding 110,040 non-active rows just to count active ads per top-level category. |
| **R25** | `Seq Scan on chat_messages | Seq Scan on chat_threads | Seq Scan on listings | Seq Scan on categories` | Analytical scan: Seq/Parallel Seq Scans on 209,529 `chat_messages`, 59,855 `chat_threads`, and 120,000 `listings` with `t.created_at >= 2026-01-01` unindexed. |
| **W01** | `(no scan)` | Fast (0.808 ms): Single-row `INSERT` into `listings` with FK validations via PK indexes (`users_pkey`, `categories_pkey`, `cities_pkey`). |
| **W02** | `Seq Scan on listings | Index Scan using listings_pkey on listings` | Slow for an OLTP write: Subquery runs a full Seq Scan over 120,000 `listings` to find `min(listing_id)` for `seller_id = 1042` before PK `UPDATE`. |
| **W03** | `Index Scan using chat_threads_pkey on chat_threads` | Moderate: Uses `Index Scan Backward using chat_threads_pkey` scanning 3,365 threads until finding `buyer_id = 1042` (`buyer_id` has no index). |
| **W04** | `Seq Scan on listings` | Slow: Full Seq Scan of 120,000 `listings` discarding 117,744 rows to update 2,256 expired active ads (`(status, expires_at)` unindexed). |
| **W05** | `Seq Scan on offers` | Degrades with scale: Runs **two** full Seq Scans of `offers` (19,943 rows each) to locate `listing_id = 118642 AND status = 'PENDING'` because `offers(listing_id)` is unindexed. |

## Key Takeaways for Phase 4

1. **Correlated SubPlan N+1 disaster (`R19`, `1,196.778 ms`):** `R19` accounts for **72.5%** of the entire 30-query workload runtime (`1,196.78 ms` out of `1,650.46 ms`) because `SubPlan 2` scans all 209,529 `chat_messages` repeatedly for active Bengaluru cars.
2. **Repeated lateral `Seq Scan` (`R06`, `72.997 ms`):** `chat_messages(thread_id)` is unindexed, forcing 13 full table scans of 209,529 messages plus an unindexed `OR` across `chat_threads` and `listings`.
3. **Disk spills (`R22`, `31.374 ms`; `R12`, `40.137 ms`; `R18`, `39.660 ms`):** Sorting 120k listings (`R22`, `7,488 kB` external merge) and hashing high-cardinality `(seller_id, ...)` groups already spill to temp disk on 120k rows and will worsen sharply at 20x scale.
4. **Correctness bug (`R13`):** Original `R13` returns **0 rows** (empty) because `listings.boost_package_id` contains `NULL`s in a `NOT IN (...)` subquery.
5. **Only 1 query (`R23`, `0.027 ms`) is truly fast** in the baseline because `users.phone` has an automatic `UNIQUE` index.
