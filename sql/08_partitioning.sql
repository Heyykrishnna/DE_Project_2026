SET search_path TO olx;

DROP TABLE IF EXISTS listings_partitioned CASCADE;

CREATE TABLE listings_partitioned (
    listing_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL REFERENCES users (user_id) ON DELETE RESTRICT,
    category_id SMALLINT NOT NULL REFERENCES categories (category_id) ON DELETE RESTRICT,
    title VARCHAR(150) NOT NULL CHECK (length(btrim(title)) > 0),
    description TEXT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price > 0),
    is_negotiable BOOLEAN NOT NULL DEFAULT TRUE,
    item_condition VARCHAR(20) NOT NULL CHECK (item_condition IN ('NEW', 'LIKE_NEW', 'GOOD', 'FAIR')),
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(attributes) = 'object'),
    city_id SMALLINT NOT NULL REFERENCES cities (city_id) ON DELETE RESTRICT,
    locality VARCHAR(100) NOT NULL CHECK (length(btrim(locality)) > 0),
    latitude NUMERIC(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude NUMERIC(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    image_count SMALLINT NOT NULL DEFAULT 0 CHECK (image_count BETWEEN 0 AND 20),
    view_count INTEGER NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    boost_package_id SMALLINT NULL REFERENCES boost_packages (package_id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'SOLD', 'EXPIRED', 'REMOVED')),
    posted_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sold_at TIMESTAMPTZ NULL,
    PRIMARY KEY (listing_id, posted_at),
    CONSTRAINT chk_lp_expiry_after_post CHECK (expires_at > posted_at),
    CONSTRAINT chk_lp_sold_consistency CHECK (
        (status = 'SOLD' AND sold_at IS NOT NULL AND sold_at >= posted_at)
        OR (status <> 'SOLD' AND sold_at IS NULL)
    )
) PARTITION BY RANGE (posted_at);

CREATE TABLE listings_p_2025_01 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-01-01 00:00:00+05:30') TO ('2025-02-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_02 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-02-01 00:00:00+05:30') TO ('2025-03-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_03 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-03-01 00:00:00+05:30') TO ('2025-04-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_04 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-04-01 00:00:00+05:30') TO ('2025-05-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_05 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-05-01 00:00:00+05:30') TO ('2025-06-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_06 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-06-01 00:00:00+05:30') TO ('2025-07-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_07 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-07-01 00:00:00+05:30') TO ('2025-08-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_08 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-08-01 00:00:00+05:30') TO ('2025-09-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_09 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-09-01 00:00:00+05:30') TO ('2025-10-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_10 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-10-01 00:00:00+05:30') TO ('2025-11-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_11 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-11-01 00:00:00+05:30') TO ('2025-12-01 00:00:00+05:30');
CREATE TABLE listings_p_2025_12 PARTITION OF listings_partitioned FOR VALUES FROM ('2025-12-01 00:00:00+05:30') TO ('2026-01-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_01 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-01-01 00:00:00+05:30') TO ('2026-02-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_02 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-02-01 00:00:00+05:30') TO ('2026-03-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_03 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-03-01 00:00:00+05:30') TO ('2026-04-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_04 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-04-01 00:00:00+05:30') TO ('2026-05-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_05 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-05-01 00:00:00+05:30') TO ('2026-06-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_06 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-06-01 00:00:00+05:30') TO ('2026-07-01 00:00:00+05:30');
CREATE TABLE listings_p_2026_07 PARTITION OF listings_partitioned FOR VALUES FROM ('2026-07-01 00:00:00+05:30') TO ('2026-08-01 00:00:00+05:30');
CREATE TABLE listings_p_default PARTITION OF listings_partitioned DEFAULT;

CREATE INDEX idx_lp_active_cat_city_posted
    ON listings_partitioned (category_id, city_id, posted_at DESC)
    INCLUDE (price, title, attributes)
    WHERE status = 'ACTIVE';

CREATE INDEX idx_lp_posted_desc_id
    ON listings_partitioned (posted_at DESC, listing_id DESC)
    INCLUDE (seller_id, category_id, title, status);

CREATE INDEX idx_lp_seller_status
    ON listings_partitioned (seller_id, status, listing_id)
    INCLUDE (view_count);

INSERT INTO listings_partitioned
SELECT * FROM listings;

ANALYZE listings_partitioned;

