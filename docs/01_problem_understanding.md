# Phase 1: Problem Understanding

OLX India is a C2C used-goods marketplace where sellers list items across categories and sub-categories with city/GPS location, condition, pricing, category-specific attributes, and optional paid boost packages. Buyers browse, filter, search, save favourites, chat with sellers, make offers, report suspicious ads, and rate sellers after a purchase.

## Problems, Stakeholders, and Workload Classification

| # | Business Need | Primary Stakeholder(s) | Related Queries | Classification | Latency Target (at 20x scale) |
| --- | --- | --- | --- | --- | --- |
| **P1** | Fast multi-filter browsing (category, city, price range, JSON car specs), keyword search (`iPhone 13`), and 2 km radius geo-search sorted by recency, price, or distance. | **Buyers** | R01, R02, R03, R09 | Customer-facing / Real-time | < 5 ms |
| **P2** | Instant ad detail page (with seller profile & rating), seller "My Ads" summary by status, posting new ads, and marking ads sold. | **Sellers** (and **Buyers** viewing ad pages) | R04, R05, W01, W02 | Customer-facing / Real-time | < 5 ms |
| **P3** | Low-latency chat inbox showing each user's conversations with latest message, unread message badge count, and sending new chat messages. | **Buyers & Sellers** (Chat / Support) | R06, R07, W03 | Customer-facing / Real-time | < 5 ms |
| **P4** | Rapid moderation triage: ads with >=3 open reports, same-day spam bursts (>=5 ads/day), duplicate-ad detection, and paginated moderation console. | **Trust & Safety / Moderation** | R11, R12, R18, R22 | Interactive operational tool (R11, R22) & Analytical batch (R12, R18) | < 250 ms (R11, R22); < 5,000 ms (R12, R18) |
| **P5** | Accurate monetisation reporting on boost package adoption (identifying unsold packages) and boosted vs. organic listing view lift. | **Monetisation** | R13, R17 | Interactive tool (R13) & Reporting / Analytics (R17) | < 250 ms (R13); < 5,000 ms (R17) |
| **P6** | Category intelligence: median pricing by condition, average time-to-sell, offer acceptance rate, and seller chat responsiveness per category. | **Category Managers** | R08, R14, R15, R25 | Reporting / Analytics | < 5,000 ms |
| **P7** | Platform & growth reliability: login by phone, home-page category counts, expiry reminders, trending favourites, daily growth metrics, top-rated sellers, nightly ad expiry, and offer settlement at 20x volume. | **Growth, Platform Eng, Buyers, Sellers** | R10, R16, R19, R20, R21, R23, R24, W04, W05 | Mixed: Real-time (R23, W05), Interactive (R10, R16), Batch (W04), Analytics (R19–R21, R24) | < 5 ms (RT), < 250 ms (Interactive), < 1,000 ms (W04), < 5,000 ms (Analytics) |

## Key Assumptions

1. **Snapshot reference date:** The seed dataset spans 1 Jan 2025 to 30 Jun 2026; operational jobs (`R10`, `W04`, `W05`) treat `2026-07-01 00:00:00+05:30` as the current cutover timestamp.
2. **Exact result equivalence:** Query optimizations must return the exact same result sets as the baseline queries, except where a baseline query has a SQL correctness bug (specifically `R13`, where `NOT IN` over nullable `boost_package_id` produces an empty set).
3. **Time zone:** All timestamps carry explicit Indian Standard Time (`+05:30`) offsets and are stored in `TIMESTAMPTZ` (UTC internally).
4. **Currency & scale:** Prices are in INR with 2 decimal places (`NUMERIC`); seed data has 120,000 listings and 20x projected scale is ~2.4M listings (~4.2M chat messages).
5. **No application-layer caching or PostgreSQL config hacks:** All latency improvements must come from schema constraints, indexing, `VACUUM`/`ANALYZE`, query rewrites, and in-DB structures (e.g., materialized views for analytics where appropriate), keeping PostgreSQL planner/memory defaults intact.

