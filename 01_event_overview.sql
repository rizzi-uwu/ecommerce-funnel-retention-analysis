-- 01_event_overview.sql
-- Purpose: list every event type in the dataset with its volume, to confirm which
--          events exist before defining the funnel.
-- Dataset: GA4 obfuscated sample e-commerce (Google Merchandise Store), BigQuery public data.
-- Note:    set the query location to US in BigQuery (More > Query settings).
-- Output:  event_name, events, users

SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;
