-- 04_checkout_steps.sql
-- Purpose: split checkout into its sub-steps to see where users leave.
-- Note: add_shipping_info fires for almost every checkout start (99.99% in this
--       sample), so it most likely fires when users arrive at the shipping step,
--       not when they finish it. The drop between shipping info and payment info
--       is therefore read as "reached the shipping form, never entered payment details".
-- Output (one row): began_checkout, added_shipping, added_payment, purchased
-- Expected values for 1 Nov 2020 to 31 Jan 2021: 11106, 11105, 6815, 4848.
-- Check: began_checkout and purchased must match the totals from 02_funnel_by_device.sql.

WITH s AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('begin_checkout', 'add_shipping_info',
                       'add_payment_info', 'purchase')
)
SELECT
  COUNT(DISTINCT IF(event_name = 'begin_checkout',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS began_checkout,
  COUNT(DISTINCT IF(event_name = 'add_shipping_info',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS added_shipping,
  COUNT(DISTINCT IF(event_name = 'add_payment_info',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS added_payment,
  COUNT(DISTINCT IF(event_name = 'purchase',
        CONCAT(user_pseudo_id, CAST(session_id AS STRING)), NULL)) AS purchased
FROM s;
