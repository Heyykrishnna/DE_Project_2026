SET search_path TO olx;

\copy cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true)
\copy categories FROM 'seed_data/categories.csv' WITH (FORMAT csv, HEADER true)
\copy boost_packages FROM 'seed_data/boost_packages.csv' WITH (FORMAT csv, HEADER true)
\copy users FROM 'seed_data/users.csv' WITH (FORMAT csv, HEADER true)
\copy listings FROM 'seed_data/listings.csv' WITH (FORMAT csv, HEADER true)
\copy chat_threads FROM 'seed_data/chat_threads.csv' WITH (FORMAT csv, HEADER true)
\copy chat_messages FROM 'seed_data/chat_messages.csv' WITH (FORMAT csv, HEADER true)
\copy offers FROM 'seed_data/offers.csv' WITH (FORMAT csv, HEADER true)
\copy favourites FROM 'seed_data/favourites.csv' WITH (FORMAT csv, HEADER true)
\copy reports FROM 'seed_data/reports.csv' WITH (FORMAT csv, HEADER true)
\copy seller_ratings FROM 'seed_data/seller_ratings.csv' WITH (FORMAT csv, HEADER true)

SELECT setval(pg_get_serial_sequence('olx.cities', 'city_id'), COALESCE((SELECT max(city_id) FROM olx.cities), 1));
SELECT setval(pg_get_serial_sequence('olx.categories', 'category_id'), COALESCE((SELECT max(category_id) FROM olx.categories), 1));
SELECT setval(pg_get_serial_sequence('olx.boost_packages', 'package_id'), COALESCE((SELECT max(package_id) FROM olx.boost_packages), 1));
SELECT setval(pg_get_serial_sequence('olx.users', 'user_id'), COALESCE((SELECT max(user_id) FROM olx.users), 1));
SELECT setval(pg_get_serial_sequence('olx.listings', 'listing_id'), COALESCE((SELECT max(listing_id) FROM olx.listings), 1));
SELECT setval(pg_get_serial_sequence('olx.chat_threads', 'thread_id'), COALESCE((SELECT max(thread_id) FROM olx.chat_threads), 1));
SELECT setval(pg_get_serial_sequence('olx.chat_messages', 'message_id'), COALESCE((SELECT max(message_id) FROM olx.chat_messages), 1));
SELECT setval(pg_get_serial_sequence('olx.offers', 'offer_id'), COALESCE((SELECT max(offer_id) FROM olx.offers), 1));
SELECT setval(pg_get_serial_sequence('olx.reports', 'report_id'), COALESCE((SELECT max(report_id) FROM olx.reports), 1));
SELECT setval(pg_get_serial_sequence('olx.seller_ratings', 'rating_id'), COALESCE((SELECT max(rating_id) FROM olx.seller_ratings), 1));

ANALYZE;

