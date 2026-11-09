SET search_path TO olx;
BEGIN;

-- @R01
SELECT listing_id, title, price, attributes ->> 'km_driven' AS km, posted_at
FROM listings
WHERE category_id = 2 AND city_id = 1 AND status = 'ACTIVE'
  AND price BETWEEN 300000 AND 600000
ORDER BY posted_at DESC
LIMIT 40;

-- @R02
SELECT listing_id, title, price, attributes
FROM listings
WHERE category_id = 2 AND city_id = 6 AND status = 'ACTIVE'
  AND attributes ->> 'fuel' = 'Diesel'
  AND (attributes ->> 'year')::int >= 2018
  AND (attributes ->> 'km_driven')::int <= 60000
ORDER BY price;

-- @R03
SELECT listing_id, title, price, city_id, item_condition
FROM listings
WHERE status = 'ACTIVE' AND title ILIKE '%iphone 13%'
ORDER BY price
LIMIT 40;

-- @R04
SELECT l.listing_id, l.title, l.price, l.description, u.full_name AS seller, u.phone_verified,
       (SELECT round(avg(r.stars), 1) FROM seller_ratings r WHERE r.seller_id = l.seller_id) AS seller_rating
FROM listings l
JOIN users u ON u.user_id = l.seller_id
WHERE l.listing_id = 100871;

-- @R05
SELECT status, count(*) AS ads, sum(view_count) AS views
FROM listings
WHERE seller_id = 1042
GROUP BY status;

-- @R06
SELECT u.thread_id, u.title, last_msg.body, last_msg.sent_at
FROM (
    SELECT t.thread_id, l.title
    FROM chat_threads t
    JOIN listings l ON l.listing_id = t.listing_id
    WHERE t.buyer_id = 1042
    UNION ALL
    SELECT t.thread_id, l.title
    FROM listings l
    JOIN chat_threads t ON t.listing_id = l.listing_id
    WHERE l.seller_id = 1042
) u
CROSS JOIN LATERAL (
    SELECT m.body, m.sent_at
    FROM chat_messages m
    WHERE m.thread_id = u.thread_id
    ORDER BY m.sent_at DESC
    LIMIT 1
) last_msg
ORDER BY last_msg.sent_at DESC;

-- @R07
SELECT (
    (SELECT count(*)
     FROM chat_threads t
     JOIN chat_messages m ON m.thread_id = t.thread_id
     WHERE t.buyer_id = 1042 AND NOT m.is_read AND m.sender_id <> 1042)
    +
    (SELECT count(*)
     FROM listings l
     JOIN chat_threads t ON t.listing_id = l.listing_id
     JOIN chat_messages m ON m.thread_id = t.thread_id
     WHERE l.seller_id = 1042 AND NOT m.is_read AND m.sender_id <> 1042)
) AS unread;

-- @R08
SELECT item_condition, count(*) AS ads,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM listings
WHERE category_id = 5 AND attributes ->> 'model' = 'iPhone 13'
  AND posted_at >= '2026-01-01'
GROUP BY item_condition
ORDER BY median_price DESC;

-- @R09
SELECT listing_id, title, price,
       round((6371 * acos(least(1, cos(radians(12.9716)) * cos(radians(latitude)) * cos(radians(longitude) - radians(77.5946))
                                  + sin(radians(12.9716)) * sin(radians(latitude)))))::numeric, 2) AS km
FROM listings
WHERE category_id = 9 AND status = 'ACTIVE'
  AND latitude  BETWEEN 12.9716 - 0.018 AND 12.9716 + 0.018
  AND longitude BETWEEN 77.5946 - 0.0185 AND 77.5946 + 0.0185
ORDER BY km;

-- @R10
SELECT listing_id, seller_id, title, expires_at
FROM listings
WHERE status = 'ACTIVE'
  AND expires_at >= '2026-07-01' AND expires_at < '2026-07-04'
ORDER BY expires_at;

-- @R11
SELECT q.listing_id, l.title, q.open_reports, q.reasons
FROM (
    SELECT r.listing_id, count(*) AS open_reports, array_agg(DISTINCT r.reason) AS reasons
    FROM reports r
    WHERE r.status = 'OPEN'
    GROUP BY r.listing_id
    HAVING count(*) >= 3
) q
JOIN listings l ON l.listing_id = q.listing_id
ORDER BY q.open_reports DESC;

-- @R12
SELECT seller_id, (posted_at AT TIME ZONE 'Asia/Kolkata')::date AS day, count(*) AS ads
FROM listings
GROUP BY seller_id, (posted_at AT TIME ZONE 'Asia/Kolkata')::date
HAVING count(*) >= 5
ORDER BY ads DESC, day;

-- @R13
SELECT b.package_id, b.package_name, b.price
FROM boost_packages b
WHERE NOT EXISTS (
    SELECT 1
    FROM listings l
    WHERE l.boost_package_id = b.package_id
);

-- @R14
SELECT c.category_name, count(*) AS sold,
       round(avg(EXTRACT(EPOCH FROM (l.sold_at - l.posted_at)) / 86400), 1) AS avg_days_to_sell
FROM listings l
JOIN categories c ON c.category_id = l.category_id
WHERE l.status = 'SOLD'
  AND l.sold_at >= '2026-01-01 00:00:00+05:30'
  AND l.sold_at <  '2027-01-01 00:00:00+05:30'
GROUP BY c.category_name
ORDER BY avg_days_to_sell;

-- @R15
SELECT c.category_name, count(*) AS offers,
       round(100.0 * count(*) FILTER (WHERE o.status = 'ACCEPTED') / count(*), 1) AS accepted_pct
FROM offers o
JOIN listings l   ON l.listing_id = o.listing_id
JOIN categories c ON c.category_id = l.category_id
GROUP BY c.category_name
ORDER BY accepted_pct DESC;

-- @R16
SELECT f_agg.listing_id, l.title, f_agg.saves
FROM (
    SELECT listing_id, count(*) AS saves
    FROM favourites
    WHERE saved_at >= '2026-06-24'
    GROUP BY listing_id
) f_agg
JOIN listings l ON l.listing_id = f_agg.listing_id
WHERE l.status = 'ACTIVE'
ORDER BY f_agg.saves DESC
LIMIT 20;

-- @R17
SELECT c.category_name, (l.boost_package_id IS NOT NULL) AS boosted, count(*) AS ads, round(avg(l.view_count), 0) AS avg_views
FROM listings l
JOIN categories c ON c.category_id = l.category_id
GROUP BY c.category_name, (l.boost_package_id IS NOT NULL)
ORDER BY c.category_name, boosted;

-- @R18
SELECT seller_id, title, price, count(*) AS copies
FROM listings
GROUP BY seller_id, title, price
HAVING count(*) > 1
ORDER BY copies DESC, seller_id;

-- @R19
SELECT l.listing_id, l.title,
       count(DISTINCT t.thread_id) AS chats,
       max(m.sent_at) AS last_chat_at
FROM listings l
LEFT JOIN chat_threads t  ON t.listing_id = l.listing_id
LEFT JOIN chat_messages m ON m.thread_id = t.thread_id
WHERE l.category_id = 2 AND l.city_id = 1 AND l.status = 'ACTIVE'
GROUP BY l.listing_id, l.title
ORDER BY chats DESC;

-- @R20
SELECT day, ads, sum(ads) OVER (ORDER BY day) AS running_total
FROM (
    SELECT (posted_at AT TIME ZONE 'Asia/Kolkata')::date AS day, count(*) AS ads
    FROM listings
    WHERE posted_at >= '2026-06-01 00:00:00+05:30'
      AND posted_at <  '2026-07-01 00:00:00+05:30'
    GROUP BY 1
) d
ORDER BY day;

-- @R21
SELECT agg.seller_id, u.full_name, agg.avg_stars, agg.ratings
FROM (
    SELECT r.seller_id, round(avg(r.stars), 2) AS avg_stars, count(*) AS ratings
    FROM seller_ratings r
    GROUP BY r.seller_id
    HAVING count(*) >= 5
    ORDER BY avg_stars DESC, ratings DESC
    LIMIT 20
) agg
JOIN users u ON u.user_id = agg.seller_id
ORDER BY agg.avg_stars DESC, agg.ratings DESC;

-- @R22
SELECT listing_id, seller_id, category_id, title, status, posted_at
FROM listings
WHERE (posted_at, listing_id) < ('2025-11-16 07:06:36+05:30'::timestamptz, 70176)
ORDER BY posted_at DESC, listing_id DESC
LIMIT 25;

-- @R23
SELECT user_id, full_name, city_id, is_banned
FROM users
WHERE phone = '8100001042';

-- @R24
SELECT coalesce(p.category_name, c.category_name) AS top_category, count(*) AS active_ads
FROM listings l
JOIN categories c      ON c.category_id = l.category_id
LEFT JOIN categories p ON p.category_id = c.parent_id
WHERE l.status = 'ACTIVE'
GROUP BY 1
ORDER BY active_ads DESC;

-- @R25
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

-- @W01
INSERT INTO listings (listing_id, seller_id, category_id, title, price, item_condition, attributes, city_id, locality,
                      latitude, longitude, image_count, status, posted_at, expires_at)
VALUES (90000001, 1042, 9, 'Wooden Study Table', 4500, 'GOOD', '{"type": "Study Table", "material": "Wood"}', 1, 'Koramangala',
        12.935200, 77.624500, 4, 'ACTIVE', '2026-07-01 10:00:00+05:30', '2026-07-31 10:00:00+05:30');

-- @W02
UPDATE listings
SET status = 'SOLD', sold_at = '2026-07-01 11:00:00+05:30'
WHERE listing_id = (SELECT min(listing_id) FROM listings WHERE seller_id = 1042 AND status = 'ACTIVE');

-- @W03
INSERT INTO chat_messages (message_id, thread_id, sender_id, body, sent_at)
SELECT 90000001, max(thread_id), 1042, 'Is this still available?', '2026-07-01 11:05:00+05:30'
FROM chat_threads
WHERE buyer_id = 1042;

-- @W04
UPDATE listings
SET status = 'EXPIRED'
WHERE status = 'ACTIVE' AND expires_at < '2026-07-01 00:00:00+05:30';

-- @W05
UPDATE offers
SET status = CASE WHEN offer_id = (SELECT offer_id FROM offers WHERE listing_id = 118642 AND status = 'PENDING'
                                   ORDER BY offer_price DESC, offer_id LIMIT 1)
                  THEN 'ACCEPTED' ELSE 'REJECTED' END,
    responded_at = '2026-07-01 12:00:00+05:30'
WHERE listing_id = 118642 AND status = 'PENDING';

-- @END
ROLLBACK;
