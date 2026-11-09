SET search_path TO olx;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Serves R01, R19: partial covering index for active listings by (category_id, city_id, posted_at DESC) to avoid sorting in R01 and narrow active Bengaluru cars in R19
CREATE INDEX idx_listings_active_cat_city_posted
    ON listings (category_id, city_id, posted_at DESC)
    INCLUDE (price, title, attributes)
    WHERE status = 'ACTIVE';

-- Serves R02: partial expression covering index for active cars filtered by city_id, fuel, year, km_driven and pre-sorted by price
CREATE INDEX idx_listings_active_cars_filter
    ON listings (
        city_id,
        (attributes ->> 'fuel'),
        price,
        ((attributes ->> 'year')::int),
        ((attributes ->> 'km_driven')::int)
    )
    INCLUDE (title, attributes)
    WHERE status = 'ACTIVE' AND category_id = 2;

-- Serves R03: partial trigram GIN index for ILIKE '%...%' title search on active listings only
CREATE INDEX idx_listings_active_title_trgm
    ON listings USING GIN (title gin_trgm_ops)
    WHERE status = 'ACTIVE';

-- Serves R05, R06, R07, W02: seller_id leading key with status and listing_id for My Ads, seller chat lookup, and oldest active ad lookup
CREATE INDEX idx_listings_seller_status_view
    ON listings (seller_id, status, listing_id)
    INCLUDE (view_count);

-- Serves R09, R24: partial covering index on active listings for 2 km bounding-box geo lookup and active category rollups
CREATE INDEX idx_listings_active_cat_lat_lon
    ON listings (category_id, latitude, longitude)
    INCLUDE (title, price)
    WHERE status = 'ACTIVE';

-- Serves R10, W04: partial index on active expiry timestamps for reminder window scans and nightly expiry updates
CREATE INDEX idx_listings_active_expires
    ON listings (expires_at)
    INCLUDE (seller_id, title)
    WHERE status = 'ACTIVE';

-- Serves R08: partial expression covering index for Mobiles (category_id = 5) model + posted_at price-guide aggregations
CREATE INDEX idx_listings_mobiles_model_posted
    ON listings ((attributes ->> 'model'), posted_at)
    INCLUDE (item_condition, price)
    WHERE category_id = 5;

-- Serves R13: partial index on non-null boost_package_id (~7.9% of rows) for fast NOT EXISTS package adoption checks
CREATE INDEX idx_listings_boost_package
    ON listings (boost_package_id)
    WHERE boost_package_id IS NOT NULL;

-- Serves R14: partial covering index on sold listings by sold_at and category_id for average days-to-sell reporting
CREATE INDEX idx_listings_sold_at_cat
    ON listings (sold_at, category_id)
    INCLUDE (posted_at)
    WHERE status = 'SOLD';

-- Serves R18: composite index pre-ordering (seller_id, title, price) for streaming duplicate-ad detection
CREATE INDEX idx_listings_seller_title_price
    ON listings (seller_id, title, price);

-- Serves R20, R22: descending (posted_at, listing_id) covering index for June growth range scan and keyset/offset moderation pagination
CREATE INDEX idx_listings_posted_desc_id
    ON listings (posted_at DESC, listing_id DESC)
    INCLUDE (seller_id, category_id, title, status);

-- Serves R04, R21: seller_id covering index on seller_ratings for Index Only Scan rating averages
CREATE INDEX idx_seller_ratings_seller_stars
    ON seller_ratings (seller_id)
    INCLUDE (stars);

-- Serves R06, R07, W03: buyer_id with thread_id DESC for buyer chat inbox, unread counts, and latest buyer thread
CREATE INDEX idx_chat_threads_buyer_thread
    ON chat_threads (buyer_id, thread_id DESC);

-- Serves R25: covering index on chat_threads(created_at) for 2026 thread responsiveness analytics
CREATE INDEX idx_chat_threads_created_listing
    ON chat_threads (created_at, thread_id, listing_id, buyer_id);

-- Serves R06, R19, R25: thread_id with sent_at DESC covering sender_id and body for Index Only Scan latest/first-reply lookups
CREATE INDEX idx_chat_messages_thread_sent
    ON chat_messages (thread_id, sent_at DESC)
    INCLUDE (sender_id, body);

-- Serves R07: tiny partial index covering only unread messages (is_read = false)
CREATE INDEX idx_chat_messages_unread_thread
    ON chat_messages (thread_id, sender_id)
    WHERE NOT is_read;

-- Serves R11: partial index on OPEN reports ordered by listing_id for moderation queue aggregation
CREATE INDEX idx_reports_open_listing_reason
    ON reports (listing_id, reason)
    WHERE status = 'OPEN';

-- Serves R16: time-ordered covering index on favourites(saved_at, listing_id) for trending saves
CREATE INDEX idx_favourites_saved_at
    ON favourites (saved_at, listing_id);

-- Serves W05: tiny partial index on PENDING offers ordered by (listing_id, offer_price DESC, offer_id)
CREATE INDEX idx_offers_pending_listing
    ON offers (listing_id, offer_price DESC, offer_id)
    WHERE status = 'PENDING';

-- Serves R15: narrow covering index on offers(listing_id) INCLUDE (status) for category offer acceptance ratio
CREATE INDEX idx_offers_listing_status
    ON offers (listing_id)
    INCLUDE (status);

