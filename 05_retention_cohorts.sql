-- 05_retention_cohorts.sql
-- Purpose: weekly retention of NEW users. Users are grouped by the week of their
--          first_visit event, then counted in each later week in which they had any event.
-- Window:  1 Nov 2020 to 30 Jan 2021. The window stops on 30 Jan so that the last week
--          of each cohort is complete (the data ends on Sunday 31 Jan).
-- Note:    "retained" means any event in that week, not a purchase.
-- Note:    a few users have activity before their first_visit event (a tracking quirk).
--          The filter active_date >= first_date removes those rows (they appeared as
--          negative weeks in an earlier version of this query).
-- Output:  cohort_week, weeks_since_first, users
--          weeks_since_first = 0 is the cohort size.
-- Retention % = users in week N divided by users in week 0 (calculated in Google Sheets).
-- Weeks with no complete follow-up are left out of the dashboard.

WITH first_seen AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210130'
    AND event_name = 'first_visit'
  GROUP BY user_pseudo_id
),
activity AS (
  SELECT DISTINCT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS active_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210130'
)
SELECT
  DATE_TRUNC(f.first_date, WEEK) AS cohort_week,
  DATE_DIFF(DATE_TRUNC(a.active_date, WEEK),
            DATE_TRUNC(f.first_date, WEEK), WEEK) AS weeks_since_first,
  COUNT(DISTINCT a.user_pseudo_id) AS users
FROM first_seen f
JOIN activity a USING (user_pseudo_id)
WHERE a.active_date >= f.first_date
GROUP BY cohort_week, weeks_since_first
ORDER BY cohort_week, weeks_since_first;
