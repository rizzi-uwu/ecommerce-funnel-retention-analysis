-- 03_funnel_by_channel.sql
-- Purpose: the same funnel as 02, split by acquisition channel.
-- Note: traffic_source.medium is the medium that FIRST brought the user to the store,
--       not the channel of each individual session.
-- Note: the sample data contains masked groups ("(data deleted)" and "<Other>").
--       "(data deleted)" is excluded from the dashboard because it cannot be read
--       as a real channel.
-- Output: channel, sessions, viewed_item, added_to_cart, began_checkout, purchased

WITH s AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    event_name,
    traffic_source.medium AS channel
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('session_start', 'view_item', 'add_to_cart',
                       'begin_checkout', 'purchase')
)
SELECT
  channel,
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
GROUP BY channel
ORDER BY sessions DESC;
