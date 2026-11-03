# OLX Used Goods Marketplace Database: DBMS Project

**Course:** Database Management Systems · **Year:** B.Tech 2nd year · **Team size:** 4
**Database:** PostgreSQL 15 or newer · **Final submission:** Mon 23 Nov 2026
**Topics used:** Data types & constraints · Keys & relationships · Normalization · Query execution plans · Indexing · Query optimization · VACUUM/ANALYZE · Partitioning & sharding

## Files in this folder


| Path                          | What it is                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `README.md`                   | This project brief                                                                   |
| `seed_data.zip`               | 11 CSV files (120,000 ads): the only input for Phase 2. Unzip it to get `seed_data/` |
| `queries/workload_30.sql`     | The 30 queries for Phase 3 (do not edit)                                             |
| `benchmarks/run_benchmark.sh` | Timing script: 3 runs per query, average, raw plans saved                            |
| `CHECKPOINTS.md`              | Checkpoint dates and the files each one needs (DE and AP repos)                      |


**Getting started:** **clone this repository and push it into your team's DE repo** (the DE repo you submitted in the form); the steps are in `[CHECKPOINTS.md](CHECKPOINTS.md)`. Keep the structure shown in [Repository structure](#repository-structure-submit-exactly-this). Unzip `seed_data.zip` inside your project folder, but don't commit the CSV files. Deadlines are in `[CHECKPOINTS.md](CHECKPOINTS.md)`. Then begin with Phase 1.

---



## Team details (fill in before you start)


| Role       | Name                            | Enrollment No.         | GitHub Username               |
| ---------- | ------------------------------- | ---------------------- | ----------------------------- |
| Group Lead | Aditya Choudhary    | 2501010616 | adityach474-pixel |
| Member 2   | Mihir Sahu          | 2501010666 | MihirSahu2710     |
| Member 3   | Yatharth Khandelwal | 2501010530 | Heyykrishnna      |
| Member 4   | Vansh Malik         | 2501010601 | vanshmalik303     |


**Team No.:** T0018 · **Section:** E · **Repository URL:** https://github.com/Heyykrishnna/DE_Project_2026

---



## How this project works


| Phase | What you do                                                                         | You submit                                                                                                              | Counts toward     | Marks  |
| ----- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------- | ------ |
| 1     | Understand the problem statements                                                   | `docs/01_problem_understanding.md`                                                                                      | Query Execution   | 2      |
| 2     | Work out the database schema **from the seed data** and load it                     | `sql/01_schema.sql`, `sql/02_load_data.sql`, `docs/02_schema_design.md`                                                 | Query Execution   | 5      |
| 3     | Run the **30 given SQL queries** and record their execution time                    | `docs/03_baseline_timings.md`, `benchmarks/results/baseline/`                                                           | Query Execution   | 3      |
| 4     | Optimize the queries and record the new times                                       | `sql/05_indexes.sql`, `sql/06_optimized_queries.sql`, `docs/04_optimization_report.md`, `benchmarks/results/optimized/` | Code Optimization | 16     |
| 5     | Scalability test on the **large dataset** (given later by faculty) and final report | `docs/05_scalability_report.md`, `benchmarks/results/large/`                                                            | Code Optimization | 14     |
|       | **Total**                                                                           |                                                                                                                         |                   | **40** |


---



## Phase 1: Problem statements

OLX is where people sell things they no longer need—cars, bikes, phones, laptops, furniture. A seller posts an **ad (listing)** in a **category** with a price, condition, photos, location and **category-specific details** (a car's fuel type and kilometres, a phone's storage …). Ads stay live for 30 days unless sold or removed, and sellers can pay for **boost packages**. Buyers **chat** with sellers, make **offers**, save ads to **favourites**, **report** suspicious ads, and rate sellers after a deal. You have joined the OLX India data team.

The current database was put together quickly by an earlier team. It has **no documented schema** (only data exports survive), and the product teams are complaining:


| #   | Problem reported                                                                                       | Team              | Related queries                             |
| --- | ------------------------------------------------------------------------------------------------------ | ----------------- | ------------------------------------------- |
| P1  | "**Browse and search** with filters (price, car details, "near me") is too slow."                      | Buyers            | R01, R02, R03, R09                          |
| P2  | "**Ad pages, My Ads** and posting/marking an ad sold lag."                                             | Sellers           | R04, R05, W01, W02                          |
| P3  | "The **chat inbox**, unread badge and sending messages are slow for active users."                     | Chat              | R06, R07, W03                               |
| P4  | "**Moderation**: report queues, spam bursts and duplicate ads must be found fast."                     | Trust & Safety    | R11, R12, R18, R22                          |
| P5  | "The monetisation team's "**boost packages nobody bought**" report is always **empty**."               | Monetisation      | R13, R17                                    |
| P6  | "**Category insights** (price guide, time to sell, offer acceptance, seller responsiveness) time out." | Category managers | R08, R14, R15, R25                          |
| P7  | "Growth reports, reminders and nightly jobs are slow, and ads will grow **20×**."                      | Growth / Platform | R10, R16, R19, R20, R21, R23, R24, W04, W05 |


**Your job:**

1. Rebuild a correct, well-constrained schema from the data exports (Phase 2).
2. Measure how the 30 most important queries perform today (Phase 3).
3. Make them fast **without changing their results** (Phase 4).
4. Prove the database will survive next year's growth (Phase 5).

**Deliverable for Phase 1** (`docs/01_problem_understanding.md`, at most 1 page):

- For each problem P1–P7, write in your own words what the business needs and which **stakeholder** is affected (buyer, seller, moderation/trust & safety, monetisation (boosts), category managers, growth, support).
- Classify each problem as **customer-facing / real-time** or **reporting / analytics**. This decides your performance targets later.
- List any assumptions you make.

---



## Phase 2: Work out the schema from the seed data

You receive `seed_data.zip`. Unzip it to get a folder `seed_data/` with 11 CSV files, a real export of the production data:


| File                 | Rows    | What it contains                               |
| -------------------- | ------- | ---------------------------------------------- |
| `cities.csv`         | 10      | Cities                                         |
| `categories.csv`     | 12      | Categories and sub-categories                  |
| `boost_packages.csv` | 6       | Paid boost packages for ads                    |
| `users.csv`          | 50,000  | OLX users (buyers and sellers)                 |
| `listings.csv`       | 120,000 | Every ad posted from 1 Jan 2025 to 30 Jun 2026 |
| `chat_threads.csv`   | 59,855  | Buyer–seller conversations about an ad         |
| `chat_messages.csv`  | 209,529 | Messages in each conversation                  |
| `offers.csv`         | 19,943  | Price offers made by buyers                    |
| `favourites.csv`     | 70,000  | Ads saved by users                             |
| `reports.csv`        | 7,999   | Reports of suspicious ads                      |
| `seller_ratings.csv` | 11,244  | Ratings of sellers after a deal                |


The first line of every file is the header (column names). Here are the headers and the first rows of each file:

**cities.csv**

```
city_id,city_name,state
1,Bengaluru,Karnataka
2,Mumbai,Maharashtra
```

**categories.csv**

```
category_id,category_name,parent_id
1,Vehicles,
2,Cars,1
```

**boost_packages.csv**

```
package_id,package_name,price,duration_days
1,Featured 7 days,299.00,7
2,Featured 15 days,499.00,15
```

**users.csv**

```
user_id,full_name,phone,email,city_id,phone_verified,is_banned,joined_at
1,Vivaan Sharma,8100000001,,2,t,f,2018-07-08 02:17:53+05:30
2,Aditya Sharma,8100000002,,4,t,f,2015-10-08 07:25:05+05:30
```

**listings.csv**

```
listing_id,seller_id,category_id,title,description,price,is_negotiable,item_condition,attributes,city_id,locality,latitude,longitude,image_count,view_count,boost_package_id,status,posted_at,expires_at,sold_at
1,42770,6,HP Inspiron 15,"Well maintained, genuine buyers only. HP Inspiron 15. Price slightly negotiable.",32799.00,t,GOOD,"{""brand"": ""HP"", ""ram_gb"": 16, ""processor"": ""i7""}",5,Andheri,12.985292,80.218940,1,0,,EXPIRED,2025-01-01 00:00:00+05:30,2025-01-31 00:00:00+05:30,
2,265,5,OnePlus iPhone 13,"Well maintained, genuine buyers only. OnePlus iPhone 13. Price slightly negotiable.",17399.00,t,LIKE_NEW,"{""brand"": ""OnePlus"", ""model"": ""iPhone 13"", ""storage_gb"": 256}",2,Saket,19.041732,72.975319,6,145,,EXPIRED,2025-01-01 00:06:33+05:30,2025-01-31 00:06:33+05:30,
```

**chat_threads.csv**

```
thread_id,listing_id,buyer_id,created_at
1,93621,16166,2026-03-04 11:05:14+05:30
2,83580,38172,2026-01-16 11:54:36+05:30
```

**chat_messages.csv**

```
message_id,thread_id,sender_id,body,sent_at,is_read
1,1,16166,"Hi, what is the final price?",2026-03-04 11:05:14+05:30,t
2,1,18828,Little negotiable,2026-03-04 11:11:14+05:30,t
```

**offers.csv**

```
offer_id,listing_id,buyer_id,offer_price,status,created_at,responded_at
1,7028,36690,4880.00,REJECTED,2025-02-02 01:31:54+05:30,2025-02-02 22:38:54+05:30
2,30586,38078,357510.00,ACCEPTED,2025-05-20 14:59:55+05:30,2025-05-21 06:06:55+05:30
```

**favourites.csv**

```
user_id,listing_id,saved_at
1,9135,2025-02-13 15:03:58+05:30
2,48352,2025-08-10 18:39:45+05:30
```

**reports.csv**

```
report_id,listing_id,reporter_id,reason,created_at,status
1,104226,32976,OFFENSIVE,2026-04-21 05:22:12+05:30,DISMISSED
2,76225,26037,SPAM,2025-12-14 19:39:38+05:30,ACTIONED
```

**seller_ratings.csv**

```
rating_id,seller_id,rater_id,listing_id,stars,comment,created_at
1,43419,17608,64110,1,Product as described,2025-10-27 07:42:10+05:30
2,23231,36585,76985,5,Very cooperative,2025-12-18 13:39:10+05:30
```

Open the files yourself (a spreadsheet, `head`, or `SELECT` after a quick load into a scratch table) and study the data carefully. **Nobody will give you the CREATE TABLE statements.** Working them out *is* the task.

### 2.1 What you must identify (for every table)

1. **Table name and column names.** Use exactly the file names and CSV headers. The 30 queries depend on them.
2. **Data type** of every column. Choose the *right* type, not just `TEXT` everywhere. Think about money, timestamps with a time-zone offset, yes/no columns, small whole numbers, decimals and short codes.
3. **Primary key.** Is it one column, or a combination? (Look closely at `favourites`, and at what stops a buyer opening two chats about the same ad, reporting the same ad twice, or rating the same deal twice.)
4. **Foreign keys.** Which column points to which table? What should happen **ON DELETE** (CASCADE, RESTRICT or SET NULL), and why?
5. **NOT NULL vs NULL.** Some columns are empty in some rows. Find out **when** and **why**, and decide which columns must never be empty. Why do most ads have no `boost_package_id`? When are `sold_at`, `responded_at`, `description`, `email`, `comment` and `parent_id` empty?
6. **UNIQUE** columns (natural candidate keys such as emails, phone numbers, codes and handles).
7. **CHECK constraints.** Write at least **12** that the data obeys and the business needs. Look for allowed values (conditions, statuses, reasons), what kind of data `attributes` holds and what it must always be, ranges (images, coordinates), and rules tying columns together (sold ⇔ sold time, expiry after posting, pending ⇔ not responded, a seller can't rate themselves).
8. **Relationships and cardinalities** (1:1, 1:N, M:N). Draw the **ER diagram** (image + Mermaid code).
9. **Normal form.** Show that each table is in 3NF/BCNF (list its functional dependencies). Point out any column that is *derived or redundant* (hint: `listings.view_count`; `seller_ratings.seller_id` vs the listing's seller; `chat_threads` vs the listing's seller) and say whether keeping it is justified.



### 2.2 Rules for your schema

- Create every table in a schema named `olx`: `CREATE SCHEMA olx;` and `SET search_path TO olx;`
- In this phase create **only constraints**: PK, FK, UNIQUE, NOT NULL, CHECK. **Do not create any other index yet.** (PostgreSQL automatically indexes PRIMARY KEY and UNIQUE columns; that's allowed. Note which indexes exist.) Your baseline in Phase 3 must reflect a database *without* tuning.
- Your constraints must accept **all** rows of the seed data. If a load fails, either your constraint is wrong or you found a data problem. Explain which in your design doc.



### 2.3 Load the data

Write `sql/02_load_data.sql` using `\copy`, loading tables in the right order (parents before children):

```sql
SET search_path TO olx;
\copy cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true)
-- ... the other tables, in an order that satisfies your foreign keys
ANALYZE;
```

Then verify the row counts match the table above, and run at least **3 integrity checks** of your own (e.g. "a buyer never chats about their own ad", "every message sender is either the thread's buyer or the ad's seller", "no ad was sold before it was posted"). Paste the results into `docs/02_schema_design.md`.

### Phase 2 deliverables

- `sql/01_schema.sql`: runs top-to-bottom on an empty database without errors
- `sql/02_load_data.sql`: loads all 11 files without errors
- `docs/02_schema_design.md`: data dictionary (table · column · type · constraint · *why*), ER diagram, FDs and normal form per table, integrity-check results, and every data problem you found

---



## Phase 3: Run the 30 queries and record the time

The file `queries/workload_30.sql` contains **30 queries**: 25 reads (`R01`–`R25`) and 5 writes (`W01`–`W05`). They're also listed in the [Appendix](#appendix-the-30-queries). **Do not modify them.** If a query fails, your schema doesn't match the seed data; fix the schema, not the query.

### 3.1 How to measure (everyone must use the same method)

- Run each query with `EXPLAIN (ANALYZE, BUFFERS)` and read the `Execution Time` at the bottom.
- Run each query **3 times** and record the **average** of the three `Execution Time` values. Keep all three runs in the raw plan file.
- Write queries (`W01`–`W05`) must be measured inside `BEGIN; … ROLLBACK;` so the data does not change.
- Close other heavy applications while measuring, and use the **same laptop** for Phase 3 and Phase 4.

The helper script does all of this for you:

```bash
./benchmarks/run_benchmark.sh <your_database> baseline
# → benchmarks/results/baseline/summary.csv   (avg, median, min, max, scan types)
# → benchmarks/results/baseline/R01.txt …     (full plans of all 3 runs)
```

> ⚠️ One of the 30 queries takes **noticeably longer** than the others on the seed data. That's intentional. Let it finish, and don't skip it.



### 3.2 Deliverable: the timing table

In `docs/03_baseline_timings.md`, fill this table for **all 30** queries:


| SQL Query                                                                                                                 | Type  | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
| ------------------------------------------------------------------------------------------------------------------------- | ----- | ---------- | ---------- | ---------- | ------------ |
| R01: Browse: active cars in Bengaluru priced ₹3–6 lakh, newest first                                                      | READ  |            |            |            |              |
| R02: Car filters: diesel cars from 2018 or later with at most 60,000 km, in Pune                                          | READ  |            |            |            |              |
| R03: Search: active "iPhone 13" ads anywhere, cheapest first                                                              | READ  |            |            |            |              |
| R04: Ad page: listing 100871 with its seller and the seller's average rating                                              | READ  |            |            |            |              |
| R05: "My Ads": user 1042's listings grouped by status                                                                     | READ  |            |            |            |              |
| R06: Chat inbox: every conversation of user 1042 (as buyer or seller) with its latest message                             | READ  |            |            |            |              |
| R07: Chat badge: unread messages sent to user 1042                                                                        | READ  |            |            |            |              |
| R08: Price guide: median asking price of iPhone 13 ads by condition (2026)                                                | READ  |            |            |            |              |
| R09: "Near me": active furniture within ~2 km of central Bengaluru (12.9716, 77.5946)                                     | READ  |            |            |            |              |
| R10: Reminder job: active ads that expire in the first 3 days of July 2026                                                | READ  |            |            |            |              |
| R11: Moderation queue: ads with 3 or more open reports                                                                    | READ  |            |            |            |              |
| R12: Spam detection: users who posted 5 or more ads on the same day                                                       | READ  |            |            |            |              |
| R13: Monetisation: boost packages that no ad has ever bought                                                              | READ  |            |            |            |              |
| R14: Category insights: average days to sell per category for ads sold in 2026                                            | READ  |            |            |            |              |
| R15: Marketplace health: share of offers accepted, per category                                                           | READ  |            |            |            |              |
| R16: Trending: active ads saved to favourites most in the last 7 days of June 2026                                        | READ  |            |            |            |              |
| R17: Monetisation: average views of boosted vs normal ads per category                                                    | READ  |            |            |            |              |
| R18: Quality: the same seller posting the same title at the same price more than once                                     | READ  |            |            |            |              |
| R19: City report: chats and latest chat time for every active car ad in Bengaluru                                         | READ  |            |            |            |              |
| R20: Growth: new ads per day and running total, June 2026                                                                 | READ  |            |            |            |              |
| R21: Trust: best-rated sellers (at least 5 ratings)                                                                       | READ  |            |            |            |              |
| R22: Moderation console: all ads, newest first, page 2,001 (25 per page)                                                  | READ  |            |            |            |              |
| R23: Login with mobile number                                                                                             | READ  |            |            |            |              |
| R24: Home page: active ads per top-level category (sub-categories rolled up)                                              | READ  |            |            |            |              |
| R25: Seller responsiveness: average minutes from a buyer's first message to the seller's first reply, per category (2026) | READ  |            |            |            |              |
| W01: Post an ad: user 1042 sells a study table in Bengaluru                                                               | WRITE |            |            |            |              |
| W02: Mark as sold: user 1042's oldest active ad                                                                           | WRITE |            |            |            |              |
| W03: Chat: user 1042 sends a message in their most recent conversation as a buyer                                         | WRITE |            |            |            |              |
| W04: Nightly job: expire every active ad whose expiry date has passed (run at 00:00 on 1 July 2026)                       | WRITE |            |            |            |              |
| W05: Seller accepts the highest pending offer on listing 118642 and rejects the others                                    | WRITE |            |            |            |              |
| **Total (sum of all 30)**                                                                                                 |       |            |            |            |              |


Below the table, add for each query the **scan type** from the plan (Seq Scan, Index Scan, …) and one line on **why** it is slow or fast.

---



## Phase 4: Optimize the queries

Make the queries faster. **The results must stay the same** (same rows; order matters only where the query has an `ORDER BY`).

### 4.1 Techniques you may use


| Technique                         | Example                                                                                                                                                                                                           |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B-tree index (single / composite) | the right column **order** matters: equality columns first, then range/sort                                                                                                                                       |
| Partial index                     | index only the rows a query needs (e.g. a rare status)                                                                                                                                                            |
| Covering index                    | `INCLUDE (...)` so the table is never visited (Index Only Scan)                                                                                                                                                   |
| Expression index                  | index the exact expression used in `WHERE`                                                                                                                                                                        |
| GIN index                         | for `ILIKE '%text%'` (extension `pg_trgm`), arrays or full-text search                                                                                                                                            |
| BRIN index                        | for huge tables stored in time order                                                                                                                                                                              |
| Query rewrite                     | sargable date ranges instead of functions on columns; `NOT EXISTS` instead of `NOT IN`; joins instead of correlated subqueries; keyset instead of `OFFSET` pagination; `UNION ALL` instead of `OR` across columns |
| VACUUM / ANALYZE                  | fresh statistics and visibility maps                                                                                                                                                                              |
| Summary table / materialized view | for heavy reports that don't need live data (state how it's refreshed)                                                                                                                                            |


**Not allowed:** changing the data, deleting rows, changing PostgreSQL server settings to hide the problem (e.g. huge `work_mem`, `enable_seqscan = off`), or caching results outside the database.

### 4.2 How to work

1. Put every index in `sql/05_indexes.sql`, each with a comment: **which queries it serves and why this type and column order**.
2. Put rewritten queries in `sql/06_optimized_queries.sql`. Copy `queries/workload_30.sql` and change **only** the queries you rewrite, keeping the `-- @R01` markers.
3. **Prove the results are unchanged** for every rewritten query (compare row counts, plus a checksum or an `EXCEPT` query). Put the proof in your report.
4. Benchmark again with the same method:

```bash
./benchmarks/run_benchmark.sh <your_database> optimized 5 sql/06_optimized_queries.sql
```

> 🔎 **Read the results, not just the timings.** At least one of the 30 original queries returns a **wrong answer** because of a subtle SQL rule about NULLs. Find it, explain it, and fix it. This is worth marks.



### 4.3 Deliverable: the optimization table

In `docs/04_optimization_report.md`:


| Query      | Before (ms) | Problem found in the plan      | Optimization applied                                                                  | After (ms) | Improvement    | Same result? |
| ---------- | ----------- | ------------------------------ | ------------------------------------------------------------------------------------- | ---------- | -------------- | ------------ |
| R01        |             | e.g. Seq Scan on 120k listings | e.g. partial index on `listings(category_id, city_id, price) WHERE status = 'ACTIVE'` |            | e.g. 98% (60×) | ✅            |
| … all 30 … |             |                                |                                                                                       |            |                |              |
| **Total**  |             |                                |                                                                                       |            |                |              |


Improvement % = (before − after) / before × 100

Also include:

- **Before/after** `EXPLAIN` **plans** for your 5 biggest improvements
- **Write overhead:** which write queries got **slower** because of your indexes, by how much, and whether that's acceptable
- **Index storage:** the size of each index you created (`pg_relation_size`) compared with its table
- **Queries you could not speed up**, and why (an honest "this query must read most of the table" earns marks)

---



## Phase 5: Scalability report (large dataset round)

Your optimizations worked on 120,000 ads. Next year the business expects **20× the volume**.

By **Thu 19 Nov 2026**, faculty will release `large_data.zip`: the same 11 CSV files with about **20× the rows** (≈ 2,400,000 listings, ≈ 4,191,000 chat messages, ≈ 1,197,000 chat threads, ≈ 1,400,000 favourites, ≈ 1,000,000 users). Until then, work on the design part of the report.

### 5.1 What to do with the large dataset

1. Create a new database. Run **your** `01_schema.sql`, load `large_data/` with your load script (change the folder name only), then run **your** `05_indexes.sql` and `ANALYZE`.
2. Run your **optimized** queries (`sql/06_optimized_queries.sql`). **Do not run the original 30 on the large data.** Some of them could run for a very long time.
  - R22 pages with `OFFSET`; if you replaced it with keyset pagination, explain how the "last seen" value is chosen for the large data.
3. Record the times and compare with your Phase 4 results on the seed data.


| Query      | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
| ---------- | ---------------------- | ----------------------- | --------------------- | ------------- | ------------------------ |
| R01        |                        |                         |                       |               |                          |
| … all 30 … |                        |                         |                       |               |                          |




### 5.2 Performance targets on the large dataset


| Query group             | Queries                                                         | Target (average of 3 runs) |
| ----------------------- | --------------------------------------------------------------- | -------------------------- |
| Real-time / user-facing | R01, R02, R03, R04, R05, R06, R07, R09, R23, W01, W02, W03, W05 | **under 5 ms**             |
| Interactive tools       | R10, R11, R13, R16, R22                                         | **under 250 ms**           |
| Reports and analytics   | R08, R12, R14, R15, R17, R18, R19, R20, R21, R24, R25           | **under 5,000 ms**         |
| Batch jobs              | W04                                                             | **under 1,000 ms**         |


If a query misses its target, **find out why from the plan and fix it.** A query that was fast on the seed data can become slow on large data for reasons that only appear at scale. Show the before/after plans for every fix.

### 5.3 Deliverable: `docs/05_scalability_report.md`

1. **Results table** (above), with every target met or explained.
2. **Growth analysis.** Group your queries by how their time grew when the data grew 20×:
  - *stayed about the same* (why? e.g. index lookups grow with log n)
  - *grew about 20×* (why? e.g. they read a fixed *share* of the table)
  - *grew more than 20×* (why, and what you did about it)
3. **What broke at scale** and how you fixed it (plans before/after).
4. **Storage:** total database size, table vs index size, on seed and large data.
5. **Architecture for 100×:** explain with numbers from your own measurements:
  - **Partitioning:** which table, by which column (RANGE / LIST / HASH), and why. Write the DDL for `listings`, show partition pruning with `EXPLAIN`, and note the primary-key rule for partitioned tables.
  - **Sharding:** Would you shard by city, by category, or by seller? A chat links a buyer and a seller who may be in different shards. Which queries become cross-shard, and how would you handle them?
  - **Read replicas and caching:** which of the 30 queries you would send to a replica or cache, and which must hit the primary.
  - **Maintenance:** VACUUM/autovacuum settings for `listings`, archiving old data, refreshing summary tables.
6. **Conclusion:** is your database ready for next year? What are the remaining risks?

---



## Repository structure (submit exactly this)

```
olx-dbms-<team-no>/
├── README.md                          # team table, how to run, headline numbers
├── team.json                          # group lead, members, enrollment numbers
├── docs/
│   ├── 01_problem_understanding.md
│   ├── 02_schema_design.md
│   ├── 03_baseline_timings.md
│   ├── 04_optimization_report.md
│   └── 05_scalability_report.md
├── diagrams/
│   └── er_diagram.png
├── sql/
│   ├── 01_schema.sql
│   ├── 02_load_data.sql
│   ├── 05_indexes.sql
│   ├── 06_optimized_queries.sql
│   └── 08_partitioning.sql
├── queries/
│   └── workload_30.sql                # given; do not edit
└── benchmarks/
    ├── run_benchmark.sh               # given
    └── results/
        ├── baseline/                  # Phase 3: summary.csv + raw plans
        ├── optimized/                 # Phase 4
        └── large/                     # Phase 5
```

`team.json`:

```json
{
  "team_number": "",
  "group_lead": { "name": "", "enrollment_no": "", "github": "" },
  "members": [
    { "name": "", "enrollment_no": "", "github": "" },
    { "name": "", "enrollment_no": "", "github": "" },
    { "name": "", "enrollment_no": "", "github": "" }
  ],
  "postgres_version": "",
  "laptop_used_for_benchmarks": ""
}
```

**Do not commit the CSV files** (`seed_data/`, `large_data/`); add them to `.gitignore`. They are too large and we already have them.

---



## Timeline


| Due                      | Work                                                                      | Checkpoint                                                  |
| ------------------------ | ------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Tue 3 Nov 2026           | Clone this repo into your team's DE repo, add members, commit `team.json` | **CP0** Setup                                               |
| Mon 16 Nov 2026          | Phase 1 + Phase 2 (schema, load, ER, data dictionary)                     | **CP1** Schema loads all seed data with no errors           |
| Tue 17 Nov 2026          | Phase 3 (baseline, 3 runs, average) + start Phase 4                       | **CP2** Baseline table for all 30 queries committed         |
| Thu 19 Nov 2026          | Phase 4 (indexes, rewrites, wrong-result query)                           | **CP3** Optimization table committed                        |
| Mon 23 Nov 2026          | Phase 5 on the large dataset + final report                               | **CP4 Final submission:** last commit on the default branch |
| Wed 25 – Thu 26 Nov 2026 | Individual analysis, in class time                                        | **CP5** Individual analysis                                 |


Full list of files per checkpoint, including the AP repo: `[CHECKPOINTS.md](CHECKPOINTS.md)`.

---



## Evaluation (40 marks)

These 40 marks are the DE part of the project: **Query Execution (10)** and **Code Optimization (30)**.
The AP project (20) and your Individual analysis (40) make up the rest of the 100.


| Phase | Criteria                                                                                                                                                                                                                  | Marks  |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
|       | **Query Execution**                                                                                                                                                                                                       | **10** |
| 1     | Problems understood, stakeholders and query groups correctly identified                                                                                                                                                   | 2      |
| 2     | Correct data types (1), keys and foreign keys with justified delete rules (1), ≥12 meaningful CHECK / NOT NULL / UNIQUE constraints (1), ER diagram + normal-form analysis (1), data loads cleanly + integrity checks (1) | 5      |
| 3     | All 30 queries measured with the required method: 3 runs, average (1), raw plans committed (1), scan type and reason for each query (1)                                                                                   | 3      |
|       | **Code Optimization**                                                                                                                                                                                                     | **30** |
| 4     | Speed-up achieved with appropriate techniques (6), every index justified (3), results proven unchanged (2), wrong-result query found and explained (2), write overhead and index storage reported (3)                     | 16     |
| 5     | Large-dataset results with all targets met or explained (4), growth analysis (3), scale-only problems found and fixed (3), partitioning DDL + sharding/replica design backed by your numbers (4)                          | 14     |
|       | **Total**                                                                                                                                                                                                                 | **40** |


**Integrity rules**

- Every number in your reports must match the raw plan files in `benchmarks/results/`. Copied or invented timings make the whole phase score 0.
- Every member must have commits; the commit history is checked.
- You may use AI tools to learn, but you must be able to explain every index and rewrite in your individual analysis.

---



## Appendix: the 30 queries

These are identical to `queries/workload_30.sql`. Use the file, not copy-paste from this page.

**R01: Browse: active cars in Bengaluru priced ₹3–6 lakh, newest first**

```sql
SELECT listing_id, title, price, attributes ->> 'km_driven' AS km, posted_at
FROM listings
WHERE category_id = 2 AND city_id = 1 AND status = 'ACTIVE'
  AND price BETWEEN 300000 AND 600000
ORDER BY posted_at DESC
LIMIT 40;
```

**R02: Car filters: diesel cars from 2018 or later with at most 60,000 km, in Pune**

```sql
SELECT listing_id, title, price, attributes
FROM listings
WHERE category_id = 2 AND city_id = 6 AND status = 'ACTIVE'
  AND attributes ->> 'fuel' = 'Diesel'
  AND (attributes ->> 'year')::int >= 2018
  AND (attributes ->> 'km_driven')::int <= 60000
ORDER BY price;
```

**R03: Search: active "iPhone 13" ads anywhere, cheapest first**

```sql
SELECT listing_id, title, price, city_id, item_condition
FROM listings
WHERE status = 'ACTIVE' AND title ILIKE '%iphone 13%'
ORDER BY price
LIMIT 40;
```

**R04: Ad page: listing 100871 with its seller and the seller's average rating**

```sql
SELECT l.listing_id, l.title, l.price, l.description, u.full_name AS seller, u.phone_verified,
       (SELECT round(avg(r.stars), 1) FROM seller_ratings r WHERE r.seller_id = l.seller_id) AS seller_rating
FROM listings l
JOIN users u ON u.user_id = l.seller_id
WHERE l.listing_id = 100871;
```

**R05: "My Ads": user 1042's listings grouped by status**

```sql
SELECT status, count(*) AS ads, sum(view_count) AS views
FROM listings
WHERE seller_id = 1042
GROUP BY status;
```

**R06: Chat inbox: every conversation of user 1042 (as buyer or seller) with its latest message**

```sql
SELECT t.thread_id, l.title, last_msg.body, last_msg.sent_at
FROM chat_threads t
JOIN listings l ON l.listing_id = t.listing_id
CROSS JOIN LATERAL (SELECT m.body, m.sent_at FROM chat_messages m
                    WHERE m.thread_id = t.thread_id ORDER BY m.sent_at DESC LIMIT 1) last_msg
WHERE t.buyer_id = 1042 OR l.seller_id = 1042
ORDER BY last_msg.sent_at DESC;
```

**R07: Chat badge: unread messages sent to user 1042**

```sql
SELECT count(*) AS unread
FROM chat_messages m
JOIN chat_threads t ON t.thread_id = m.thread_id
JOIN listings l     ON l.listing_id = t.listing_id
WHERE NOT m.is_read
  AND m.sender_id <> 1042
  AND (t.buyer_id = 1042 OR l.seller_id = 1042);
```

**R08: Price guide: median asking price of iPhone 13 ads by condition (2026)**

```sql
SELECT item_condition, count(*) AS ads,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM listings
WHERE category_id = 5 AND attributes ->> 'model' = 'iPhone 13'
  AND posted_at >= '2026-01-01'
GROUP BY item_condition
ORDER BY median_price DESC;
```

**R09: "Near me": active furniture within ~2 km of central Bengaluru (12.9716, 77.5946)**

```sql
SELECT listing_id, title, price,
       round((6371 * acos(least(1, cos(radians(12.9716)) * cos(radians(latitude)) * cos(radians(longitude) - radians(77.5946))
                                  + sin(radians(12.9716)) * sin(radians(latitude)))))::numeric, 2) AS km
FROM listings
WHERE category_id = 9 AND status = 'ACTIVE'
  AND latitude  BETWEEN 12.9716 - 0.018 AND 12.9716 + 0.018
  AND longitude BETWEEN 77.5946 - 0.0185 AND 77.5946 + 0.0185
ORDER BY km;
```

**R10: Reminder job: active ads that expire in the first 3 days of July 2026**

```sql
SELECT listing_id, seller_id, title, expires_at
FROM listings
WHERE status = 'ACTIVE'
  AND expires_at >= '2026-07-01' AND expires_at < '2026-07-04'
ORDER BY expires_at;
```

**R11: Moderation queue: ads with 3 or more open reports**

```sql
SELECT r.listing_id, l.title, count(*) AS open_reports, array_agg(DISTINCT r.reason) AS reasons
FROM reports r
JOIN listings l ON l.listing_id = r.listing_id
WHERE r.status = 'OPEN'
GROUP BY r.listing_id, l.title
HAVING count(*) >= 3
ORDER BY open_reports DESC;
```

**R12: Spam detection: users who posted 5 or more ads on the same day**

```sql
SELECT seller_id, posted_at::date AS day, count(*) AS ads
FROM listings
GROUP BY seller_id, posted_at::date
HAVING count(*) >= 5
ORDER BY ads DESC, day;
```

**R13: Monetisation: boost packages that no ad has ever bought**

```sql
SELECT b.package_id, b.package_name, b.price
FROM boost_packages b
WHERE b.package_id NOT IN (SELECT l.boost_package_id FROM listings l);
```

**R14: Category insights: average days to sell per category for ads sold in 2026**

```sql
SELECT c.category_name, count(*) AS sold,
       round(avg(EXTRACT(EPOCH FROM (l.sold_at - l.posted_at)) / 86400), 1) AS avg_days_to_sell
FROM listings l
JOIN categories c ON c.category_id = l.category_id
WHERE l.status = 'SOLD'
  AND EXTRACT(YEAR FROM l.sold_at) = 2026
GROUP BY c.category_name
ORDER BY avg_days_to_sell;
```

**R15: Marketplace health: share of offers accepted, per category**

```sql
SELECT c.category_name, count(*) AS offers,
       round(100.0 * count(*) FILTER (WHERE o.status = 'ACCEPTED') / count(*), 1) AS accepted_pct
FROM offers o
JOIN listings l   ON l.listing_id = o.listing_id
JOIN categories c ON c.category_id = l.category_id
GROUP BY c.category_name
ORDER BY accepted_pct DESC;
```

**R16: Trending: active ads saved to favourites most in the last 7 days of June 2026**

```sql
SELECT f.listing_id, l.title, count(*) AS saves
FROM favourites f
JOIN listings l ON l.listing_id = f.listing_id AND l.status = 'ACTIVE'
WHERE f.saved_at >= '2026-06-24'
GROUP BY f.listing_id, l.title
ORDER BY saves DESC
LIMIT 20;
```

**R17: Monetisation: average views of boosted vs normal ads per category**

```sql
SELECT c.category_name, (l.boost_package_id IS NOT NULL) AS boosted, count(*) AS ads, round(avg(l.view_count), 0) AS avg_views
FROM listings l
JOIN categories c ON c.category_id = l.category_id
GROUP BY c.category_name, (l.boost_package_id IS NOT NULL)
ORDER BY c.category_name, boosted;
```

**R18: Quality: the same seller posting the same title at the same price more than once**

```sql
SELECT seller_id, title, price, count(*) AS copies
FROM listings
GROUP BY seller_id, title, price
HAVING count(*) > 1
ORDER BY copies DESC, seller_id;
```

**R19: City report: chats and latest chat time for every active car ad in Bengaluru**

```sql
SELECT l.listing_id, l.title,
       (SELECT count(*) FROM chat_threads t WHERE t.listing_id = l.listing_id) AS chats,
       (SELECT max(m.sent_at) FROM chat_messages m JOIN chat_threads t ON t.thread_id = m.thread_id
         WHERE t.listing_id = l.listing_id) AS last_chat_at
FROM listings l
WHERE l.category_id = 2 AND l.city_id = 1 AND l.status = 'ACTIVE'
ORDER BY chats DESC;
```

**R20: Growth: new ads per day and running total, June 2026**

```sql
SELECT day, ads, sum(ads) OVER (ORDER BY day) AS running_total
FROM (
    SELECT posted_at::date AS day, count(*) AS ads
    FROM listings
    WHERE posted_at::date BETWEEN '2026-06-01' AND '2026-06-30'
    GROUP BY 1
) d
ORDER BY day;
```

**R21: Trust: best-rated sellers (at least 5 ratings)**

```sql
SELECT r.seller_id, u.full_name, round(avg(r.stars), 2) AS avg_stars, count(*) AS ratings
FROM seller_ratings r
JOIN users u ON u.user_id = r.seller_id
GROUP BY r.seller_id, u.full_name
HAVING count(*) >= 5
ORDER BY avg_stars DESC, ratings DESC
LIMIT 20;
```

**R22: Moderation console: all ads, newest first, page 2,001 (25 per page)**

```sql
SELECT listing_id, seller_id, category_id, title, status, posted_at
FROM listings
ORDER BY posted_at DESC
OFFSET 50000
LIMIT 25;
```

**R23: Login with mobile number**

```sql
SELECT user_id, full_name, city_id, is_banned
FROM users
WHERE phone = '8100001042';
```

**R24: Home page: active ads per top-level category (sub-categories rolled up)**

```sql
SELECT coalesce(p.category_name, c.category_name) AS top_category, count(*) AS active_ads
FROM listings l
JOIN categories c      ON c.category_id = l.category_id
LEFT JOIN categories p ON p.category_id = c.parent_id
WHERE l.status = 'ACTIVE'
GROUP BY 1
ORDER BY active_ads DESC;
```

**R25: Seller responsiveness: average minutes from a buyer's first message to the seller's first reply, per category (2026)**

```sql
SELECT c.category_name, round(avg(EXTRACT(EPOCH FROM (x.first_reply - x.first_msg)) / 60), 1) AS avg_reply_min, count(*) AS chats
FROM (
    SELECT t.thread_id, l.category_id,
           min(m.sent_at) FILTER (WHERE m.sender_id = t.buyer_id)  AS first_msg,
           min(m.sent_at) FILTER (WHERE m.sender_id = l.seller_id) AS first_reply
    FROM chat_threads t
    JOIN listings l      ON l.listing_id = t.listing_id
    JOIN chat_messages m ON m.thread_id = t.thread_id
    WHERE t.created_at >= '2026-01-01'
    GROUP BY t.thread_id, l.category_id
) x
JOIN categories c ON c.category_id = x.category_id
WHERE x.first_reply IS NOT NULL
GROUP BY c.category_name
ORDER BY avg_reply_min;
```



**W01: Post an ad: user 1042 sells a study table in Bengaluru**

```sql
INSERT INTO listings (listing_id, seller_id, category_id, title, price, item_condition, attributes, city_id, locality,
                      latitude, longitude, image_count, status, posted_at, expires_at)
VALUES (90000001, 1042, 9, 'Wooden Study Table', 4500, 'GOOD', '{"type": "Study Table", "material": "Wood"}', 1, 'Koramangala',
        12.935200, 77.624500, 4, 'ACTIVE', '2026-07-01 10:00:00+05:30', '2026-07-31 10:00:00+05:30');
```

**W02: Mark as sold: user 1042's oldest active ad**

```sql
UPDATE listings
SET status = 'SOLD', sold_at = '2026-07-01 11:00:00+05:30'
WHERE listing_id = (SELECT min(listing_id) FROM listings WHERE seller_id = 1042 AND status = 'ACTIVE');
```

**W03: Chat: user 1042 sends a message in their most recent conversation as a buyer**

```sql
INSERT INTO chat_messages (message_id, thread_id, sender_id, body, sent_at)
SELECT 90000001, max(thread_id), 1042, 'Is this still available?', '2026-07-01 11:05:00+05:30'
FROM chat_threads
WHERE buyer_id = 1042;
```

**W04: Nightly job: expire every active ad whose expiry date has passed (run at 00:00 on 1 July 2026)**

```sql
UPDATE listings
SET status = 'EXPIRED'
WHERE status = 'ACTIVE' AND expires_at < '2026-07-01 00:00:00+05:30';
```

**W05: Seller accepts the highest pending offer on listing 118642 and rejects the others**

```sql
UPDATE offers
SET status = CASE WHEN offer_id = (SELECT offer_id FROM offers WHERE listing_id = 118642 AND status = 'PENDING'
                                   ORDER BY offer_price DESC, offer_id LIMIT 1)
                  THEN 'ACCEPTED' ELSE 'REJECTED' END,
    responded_at = '2026-07-01 12:00:00+05:30'
WHERE listing_id = 118642 AND status = 'PENDING';
```

