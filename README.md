# E-commerce Funnel, Retention and Experiment Design

A personal product analytics case study on public data. It finds where users drop off before buying, sizes the opportunity, and designs an A/B test for the top idea.

This is an independent learning project on the public Google Analytics 4 sample dataset for the Google Merchandise Store. It is not client or employer work and is not affiliated with Google. The recommendations are my own analysis of that data.

Author: Sumbul Rizvi

## Business question

Where do users drop off before buying, and which fix should the team test first?

## Data

- Source: `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` (BigQuery public dataset, event level, obfuscated)
- Period: 1 November 2020 to 31 January 2021 (retention stops on 30 January so every week shown is complete)
- Session: unique combination of `user_pseudo_id` and `ga_session_id`
- Funnel events: `session_start`, `view_item`, `add_to_cart`, `begin_checkout`, `purchase`

## What is in this repository

| Path | Content |
|---|---|
| `sql/01_event_overview.sql` | Event types and volumes |
| `sql/02_funnel_by_device.sql` | Funnel counts by device |
| `sql/03_funnel_by_channel.sql` | Funnel counts by acquisition channel |
| `sql/04_checkout_steps.sql` | Checkout split into shipping, payment and purchase |
| `sql/05_retention_cohorts.sql` | Weekly retention of new users |
| `sql/06_user_level_counts.sql` | One row per user, input for the segments |
| `python/user_segments.py` | Behavioural segments and chart (Pandas, Matplotlib) |
| `data/product_analytics_dashboard_data.xlsx` | The result tables behind the dashboard |

## Key findings

- 354,857 sessions, 4,848 of them with a purchase: 1.37% overall conversion.
- 80.3% of sessions that viewed a product did not add it to the cart. 56.4% of sessions that began checkout did not purchase.
- Inside checkout, the biggest loss is between shipping info and payment info: 4,290 sessions (38.6%), about two thirds of all checkout losses.
- No device differs from the total by more than 2 percentage points. Channels differ: referral converts at 1.70%, organic at 1.11%, paid search at 0.98%. Every named channel loses more than half of its checkout starts.
- Few new users return: 3.8% in week 1 and 0.9% in week 4.
- At the user level, 77.1% of users never viewed a product, and 9,630 users added to cart and never bought (68.5% of everyone who added to cart).

## Recommendation

A/B test guest checkout plus a shorter shipping form first. It targets the loss measured most clearly, among users who already want to buy. This is a test design only. No experiment was run, and the dataset cannot show results.

- Primary metric: checkout-to-purchase rate (baseline 43.65%)
- Minimum detectable effect: +5 percentage points
- Sample size: about 1,560 checkout starts per variant (5% significance, 80% power), roughly 26 days at the observed pace
- Guardrails: revenue per checkout start, payment error rate, repeat purchases within 30 days

The what-if sizing (about 555 extra purchases per three months) is an illustration based on the assumed +5 points, not a forecast.

## How to rerun

1. Open the BigQuery console (the free sandbox is enough) and create a project. Set the query location to US, because the dataset is stored there.
2. Run the SQL files in `sql/` and save the results to Google Sheets. Rates and retention percentages were calculated there from the counts.
3. For the segments, open Google Colab, authenticate with `from google.colab import auth; auth.authenticate_user()`, set the environment variable `GCP_PROJECT_ID` to your project ID, and run `python/user_segments.py`.

## Limitations

- Sample data from one store and one season that includes the holiday period.
- Users are identified by browser or device ID, so one person on two devices counts twice. Segments and retention have the same limit.
- Each funnel step counts sessions that contain the event, not only sessions that passed through the earlier steps in order.
- The shipping event appears to fire on arrival at the step, not on completion.
- The channel field is the user's first acquisition medium, not the channel of each session. The masked "(data deleted)" and "Other" groups cannot be read as real channels.
- Retained means any event in that week, not a purchase.
- Differences between channels are descriptive. No significance test was run.

## Dashboard


## Full write-up and dashboard

- [Case study on Notion](https://animated-party-b31.notion.site/E-commerce-Funnel-Case-Study-3ef77fb4a1d980458c3fc34cbcb4eba5) (decision memo, results, RICE prioritisation, A/B test design)
- [Looker Studio dashboard](https://datastudio.google.com/reporting/efc98fa2-de21-40ff-9615-ab30915636c5)

## Tools

BigQuery (SQL), Google Sheets, Python (Pandas, NumPy, Matplotlib), Google Colab, Looker Studio, Notion.
