"""
user_segments.py
Behavioural user segments for the e-commerce funnel case study.

Each user is placed in ONE segment, based on the furthest stage reached between
1 Nov 2020 and 31 Jan 2021:
  Buyers                      at least one purchase
  Cart abandoners             added to cart, never purchased
  Browsers (viewed, no cart)  viewed a product, never added to cart
  No product view             none of the above

Run in Google Colab (or locally with BigQuery access):
  1. In Colab, authenticate first:  from google.colab import auth; auth.authenticate_user()
  2. Set the environment variable GCP_PROJECT_ID to your Google Cloud project ID.
  3. Run this script.

Needs: google-cloud-bigquery, pandas, numpy, matplotlib, db-dtypes
"""
import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from google.cloud import bigquery

PROJECT_ID = os.environ.get("GCP_PROJECT_ID")
if not PROJECT_ID:
    raise SystemExit("Set the environment variable GCP_PROJECT_ID to your Google Cloud project ID.")

client = bigquery.Client(project=PROJECT_ID)

# Same query as sql/06_user_level_counts.sql
QUERY = """
WITH e AS (
  SELECT user_pseudo_id, event_name,
         (SELECT value.int_value FROM UNNEST(event_params)
          WHERE key = 'ga_session_id') AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('session_start', 'view_item', 'add_to_cart', 'purchase')
)
SELECT user_pseudo_id,
  COUNT(DISTINCT IF(event_name = 'session_start', session_id, NULL)) AS sessions,
  COUNTIF(event_name = 'view_item')   AS item_views,
  COUNTIF(event_name = 'add_to_cart') AS cart_adds,
  COUNTIF(event_name = 'purchase')    AS purchases
FROM e
GROUP BY user_pseudo_id
"""

users = client.query(QUERY).to_dataframe()
print(f"Users loaded: {len(users):,}")

# Assign each user to the highest segment reached (order matters for np.select)
conditions = [
    users.purchases > 0,
    (users.cart_adds > 0) & (users.purchases == 0),
    (users.item_views > 0) & (users.cart_adds == 0) & (users.purchases == 0),
]
labels = ["Buyers", "Cart abandoners", "Browsers (viewed, no cart)"]
users["segment"] = np.select(conditions, labels, default="No product view")

summary = (
    users.groupby("segment")
    .agg(users=("user_pseudo_id", "count"), avg_sessions=("sessions", "mean"))
    .reset_index()
)
summary["share_pct"] = (summary.users / summary.users.sum() * 100).round(1)
summary["avg_sessions"] = summary.avg_sessions.round(2)
summary = summary.sort_values("users", ascending=False)
print(summary.to_string(index=False))

# Chart
order = ["No product view", "Browsers (viewed, no cart)", "Cart abandoners", "Buyers"]
plot_df = summary.set_index("segment").reindex(order)
ax = plot_df["users"].plot(kind="barh", figsize=(9, 4), color="#4c78a8")
for i, (v, s) in enumerate(zip(plot_df["users"], plot_df["share_pct"])):
    ax.text(v, i, f"  {int(v):,} ({s}%)", va="center")
ax.set_xlabel("Users")
ax.set_ylabel("")
ax.set_title("Users by behavioural segment, Nov 2020 to Jan 2021")
ax.set_xlim(0, plot_df["users"].max() * 1.25)
plt.tight_layout()
plt.savefig("segments.png", dpi=200)

# Sizing what-if (an assumption, not a forecast)
abandoners = int(summary.loc[summary.segment == "Cart abandoners", "users"].iloc[0])
buyers = int(summary.loc[summary.segment == "Buyers", "users"].iloc[0])
total = int(summary.users.sum())
print(f"Total users: {total:,}")
print(f"Buyers: {buyers:,} ({buyers / total:.2%} of users)")
print(f"Cart abandoners: {abandoners:,}")
print(f"If 10% of cart abandoners bought once: about {round(abandoners * 0.10):,} extra buyers")
