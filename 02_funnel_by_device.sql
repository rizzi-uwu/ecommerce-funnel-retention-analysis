-- 02_funnel_by_device.sql
-- Purpose: count sessions that reach each funnel step, split by device category.
-- Session definition: unique combination of user_pseudo_id and ga_session_id.
-- Each step counts sessions that CONTAIN the event, not only sessions that passed
-- through the earlier steps in order (stated as a limitation in the README).
-- Output: device, sessions, viewed_item, added_to_cart, began_checkout, purchased
-- Rates (view-to-cart, cart-to-checkout, checkout-to-purchase, overall conversion)
-- were calculated in Google Sheets from these counts.

WITH s AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    event_name,
    device.category AS device
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('session_start', 'view_item', 'add_to_cart',
                       'begin_checkout', 'purchase')
)
SELECT
  device,
  COUNT(DISTINCT IF(event_name = 'session_start',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS sessions,
  COUNT(DISTINCT IF(event_name = 'view_item',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS viewed_item,
  COUNT(DISTINCT IF(event_name = 'add_to_cart',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS added_to_cart,
  COUNT(DISTINCT IF(event_name = 'begin_checkout',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS began_checkout,
  COUNT(DISTINCT IF(event_name = 'purchase',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS purchased
FROM s
GROUP BY device;
