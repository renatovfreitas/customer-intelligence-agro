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

# Customer Segments v2

Source: original `SHOW CREATE VIEW vw_customer_segments_v2` supplied by the project owner. The SQL preserves all thresholds, labels, output columns and **CASE precedence** while removing the environment-specific DEFINER.

Dependency: `vw_customer_rfm_scores_v2` (itself dependent on `vw_customer_rfm_base_v2` and `vw_sales_unified_classified`).

## Ordered rules (first match wins)

1. VIP: R >= 4, F >= 4, M >= 4.
2. Loyal Customers: R >= 3, F >= 4.
3. High-Value Occasional: R >= 3, M >= 4.
4. New Customers: first_purchase_date >= 2026-06-06.
5. Promising: R >= 4.
6. At Risk: R = 2 and (F >= 3 or M >= 3).
7. Active Occasional: R >= 2.
8. High-Value Lost: R = 1 and lifetime_revenue >= 50000.
9. Former Regular Customers: R = 1 and lifetime_revenue >= 10000.
10. Recently Inactive: R = 1 and recency_days <= 730.
11. Long-Term Inactive: all remaining customers.

## Interpretation and caveats

- Segments are mutually exclusive because the CASE assigns only the first matching label.
- The fixed `2026-06-06` New Customers cutoff is evaluated **after** three RFM conditions; a recent first-time buyer can therefore receive a higher-priority label.
- 'Active Occasional' is a business segment label, not necessarily proof of purchase in the last 12 months: R = 2 includes recency up to 365 days.
- `lifetime_revenue` is used for inactive high-value tiers, not `monetary_12m`.
- RFM reference dates and scoring thresholds live in upstream views. Revisit all fixed dates together when refreshing the analysis.
- Not executed against the production database.

## Suggested read-only validation

```sql
SELECT customer_segment, COUNT(*) AS customers,
       ROUND(SUM(monetary_12m), 2) AS revenue_12m
FROM vw_customer_segments_v2
GROUP BY customer_segment
ORDER BY revenue_12m DESC;
```

