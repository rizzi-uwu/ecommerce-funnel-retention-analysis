-- 06_user_level_counts.sql
-- Purpose: one row per user with counts of sessions, product views, cart adds and
--          purchases. This is the input for python/user_segments.py, which assigns
--          each user to a behavioural segment.
-- Output:  user_pseudo_id, sessions, item_views, cart_adds, purchases
--          (about 268,000 rows for 1 Nov 2020 to 31 Jan 2021)

WITH e AS (
  SELECT
    user_pseudo_id,
    event_name,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('session_start', 'view_item', 'add_to_cart', 'purchase')
)
SELECT
  user_pseudo_id,
  COUNT(DISTINCT IF(event_name = 'session_start', session_id, NULL)) AS sessions,
  COUNTIF(event_name = 'view_item')   AS item_views,
  COUNTIF(event_name = 'add_to_cart') AS cart_adds,
  COUNTIF(event_name = 'purchase')    AS purchases
FROM e
GROUP BY user_pseudo_id;
