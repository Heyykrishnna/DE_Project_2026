# Phase 1: Problem Understanding

OLX India is a consumer-to-consumer marketplace for pre-owned goods. Sellers list items across various categories and sub-categories, providing details such as condition, price, location, and category-specific attributes, along with optional paid boost packages. Buyers browse listings, apply filters, search keywords, save favourites, chat with sellers, make offers, report issues, and leave ratings once a deal is completed.

## Problems, Stakeholders, and Workload Classification

| # | Business Need | Primary Stakeholder(s) | Related Queries | Classification | Latency Target (at 20x scale) |
| --- | --- | --- | --- | --- | --- |
| **P1** | Fast multi-filter browsing (category, city, price range, JSON car specs), keyword search (`iPhone 13`), and 2 km radius geo-search sorted by recency, price, or distance. | **Buyers** | R01, R02, R03, R09 | Customer-facing (real-time) | < 5 ms |
| **P2** | Instant ad detail page (with seller profile & rating), seller "My Ads" summary by status, posting new ads, and marking ads sold. | **Sellers** (and **Buyers** viewing ad pages) | R04, R05, W01, W02 | Customer-facing (real-time) | < 5 ms |
| **P3** | Low-latency chat inbox showing each user's conversations with latest message, unread message badge count, and sending new chat messages. | **Buyers & Sellers** (Chat / Support) | R06, R07, W03 | Customer-facing (real-time) | < 5 ms |
| **P4** | Rapid moderation triage: ads with >=3 open reports, same-day spam bursts (>=5 ads/day), duplicate-ad detection, and paginated moderation console. | **Trust & Safety / Moderation** | R11, R12, R18, R22 | Interactive operational tool (R11, R22) & Analytical batch (R12, R18) | < 250 ms (R11, R22); < 5,000 ms (R12, R18) |
| **P5** | Accurate monetisation reporting on boost package adoption (identifying unsold packages) and boosted vs. organic listing view lift. | **Monetisation** | R13, R17 | Interactive tool (R13) & Reporting & analytics (R17) | < 250 ms (R13); < 5,000 ms (R17) |
| **P6** | Category intelligence: median pricing by condition, average time-to-sell, offer acceptance rate, and seller chat responsiveness per category. | **Category Managers** | R08, R14, R15, R25 | Reporting & analytics | < 5,000 ms |
| **P7** | Platform & growth reliability: login by phone, home-page category counts, expiry reminders, trending favourites, daily growth metrics, top-rated sellers, nightly ad expiry, and offer settlement at 20x volume. | **Growth, Platform Eng, Buyers, Sellers** | R10, R16, R19, R20, R21, R23, R24, W04, W05 | Mixed (real-time R23/W05, interactive R10/R16, batch W04, analytics R19-R21/R24) | < 5 ms (RT), < 250 ms (Interactive), < 1,000 ms (W04), < 5,000 ms (Analytics) |

## Key Assumptions

1. **Snapshot reference date:** The seed dataset spans 1 Jan 2025 to 30 Jun 2026; operational jobs (`R10`, `W04`, `W05`) treat `2026-07-01 00:00:00+05:30` as the current cutover timestamp.
2. **Result equivalence:** Every optimized query must produce the identical multiset of rows as the baseline workload. The only justified deviation is R13, where the baseline query contains a logical bug (NOT IN over a nullable column evaluating to UNKNOWN and returning zero rows); our rewrite fixes this behavior.
3. **Time zone:** All timestamps carry explicit Indian Standard Time (`+05:30`) offsets and are stored in `TIMESTAMPTZ` (UTC internally).
4. **Currency & scale:** Prices are in INR with 2 decimal places (`NUMERIC`); seed data has 120,000 listings and 20x projected scale is ~2.4M listings (~4.2M chat messages).
5. **Standard runtime constraints:** All performance improvements rely strictly on indexing, query restructuring, and database maintenance (VACUUM and ANALYZE). Server-level memory limits and planner switches remain at PostgreSQL defaults without artificial tuning.

