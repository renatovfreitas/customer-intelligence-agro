# RFM segmentation — SQL

## 01_create_customer_rfm_base_v2.sql

Creates `vw_customer_rfm_base_v2` from `vw_sales_unified_classified`.

- Snapshot date: **2026-09-03**.
- Historical period: **2018-01-01** to **2026-09-03**, inclusive.
- 12-month window: **2025-09-04** to **2026-09-03**, inclusive.
- One row per non-null `customer_identity_id` with at least one qualifying historical sale.
- `total_purchases` and `frequency_12m` count distinct `source_system:sale_control` combinations.
- `monetary_12m` is the 12-month sum of revenue, including zero for historical customers without 12-month activity.
- `profit_12m` is the sum of *known* profit in the 12-month window; it can be NULL if no non-NULL profit is available.
- The view uses a fixed reference date, not `CURDATE()`.

The SQL preserves the provided business logic and removes environment-specific `DEFINER`. It has **not been executed** against the database.

# RFM scores v2

`vw_customer_rfm_scores_v2` assigns fixed, rule-based scores from 1 to 5 to each customer identity based on `vw_customer_rfm_base_v2`.

- **Recency (days):** <=30: 5; 31–90: 4; 91–180: 3; 181–365: 2; >365: 1.
- **Frequency (distinct sales in 12 months):** >=11: 5; 6–10: 4; 4–5: 3; 2–3: 2; 0–1: 1.
- **Monetary (12-month revenue in BRL):** >=25000: 5; 5000–24999.99: 4; 1000–4999.99: 3; 500–999.99: 2; <500: 1.

The base view uses a fixed reference date of 2026-09-03 and a 12-month window of 2025-09-04 to 2026-09-03. Profit is passed through but is not part of scoring. No quantiles or statistical ranking are used. SQL is formatted from existing database DDL and has not been run against the database.
