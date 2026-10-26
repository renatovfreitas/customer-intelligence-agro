# Customer Product Mix

Source view: `vw_customer_product_mix`.

## Dependencies
- `vw_customer_product_group` (`pg`): customer/group revenue, profit and sale count.
- `vw_customer_product_total` (`t`): customer total revenue.

## Business rule
`group_revenue_pct = group_revenue / NULLIF(total_revenue, 0)`.
The metric is a ratio, not a 0–100 percentage. Division by zero returns NULL.
The INNER JOIN omits customers without matching records in both dependencies.

## Cautions
- `customer_key` must not be assumed equivalent to the unified `customer_identity_id` without inspecting the upstream views.
- The source SQL contains no explicit date filter. Date scope depends on the upstream views.
- Values were reformatted from the supplied definition; not tested against the database.


# vw_customer_product_group

## Purpose
Aggregates revenue, profit, and number of distinct sales by `customer_key` and `product_group`.

## Dependencies
- `vw_sales_enriched` (`se`)
- `vw_customer_master` (`cm`)

## Original business rules
- Include sales from 2025-07-08 (inclusive) through 2026-07-08 (exclusive).
- INNER JOIN to customer master by `customer_key`.
- Group by `customer_key` and `product_group`.
- Revenue: `SUM(se.revenue)`.
- Profit: `SUM(se.profit)`.
- Sales count: `COUNT(DISTINCT se.sale_control)`.

## Caveats
- This view is not based on the consolidated two-ERP `customer_identity_id` and is not directly comparable with the RFM v2 window ending 2026-09-03.
- Source view scope and product/service coverage should be confirmed from its own definition.
- No data was altered or tested against the live database.
- Removed environment-specific `DEFINER` / `SQL SECURITY DEFINER` clauses.

## Downstream
- `vw_customer_product_mix` joins this view to `vw_customer_product_total`.


# vw_customer_product_total

Calculates total product revenue by `customer_key`, summing `group_revenue` from `vw_customer_product_group`.

- Source: `vw_customer_product_group`
- Output: `customer_key`, `total_revenue`
- Inherited date range: 2025-07-08 inclusive to 2026-07-08 exclusive
- Scope: current ERP analysis; does not use consolidated `customer_identity_id`
- Downstream: `vw_customer_product_mix`, where `total_revenue` is the denominator for `group_revenue_pct`
- SQL logic preserved; environment-specific DEFINER removed.
- Not executed against the database.

Suggested repository path: `sql/04_customer_analytics/04_create_customer_product_total.sql`.

# vw_customer_product_behavior

Identifies the product group(s) with the greatest revenue for each `customer_key` using an anti-join against `vw_customer_product_mix`.

## Dependencies
- `vw_customer_product_mix`
- Indirectly: `vw_customer_product_group`, `vw_customer_product_total`, `vw_sales_enriched`, `vw_customer_master`

## Business rules
- A group is returned when no other group for that customer has **strictly greater** revenue.
- Equal maximum revenues produce **multiple rows for the same customer**. No deterministic tie-breaker is present.
- Inherits the current-ERP scope and 2025-07-08 through 2026-07-07 window from upstream views.
- `dominant_group_revenue_pct` is a ratio, not a 0-100 percentage.
- Uses `customer_key`, not consolidated `customer_identity_id`; do not join directly to RFM v2 without a validated identity mapping.

## Suggested validation
```sql
SELECT customer_key, COUNT(*) AS dominant_groups
FROM vw_customer_product_behavior
GROUP BY customer_key
HAVING COUNT(*) > 1;
```

This script reproduces the supplied logic, removing environment-specific `DEFINER` and `SQL SECURITY DEFINER` clauses. Not executed against the database.


# vw_customer_behavior_12m

## Purpose
Summarizes purchases per `customer_key` in the original current-ERP 12-month analysis window.

## Dependencies
- `vw_sales_enriched`

## Business rules
- Date range: `2025-07-08` inclusive to `2026-07-08` exclusive (through 2026-07-07).
- One row per `customer_key` with sales during this period.
- `frequency_12m`: distinct `sale_control` values.
- `monetary_12m`: rounded sum of revenue.
- `profit_12m`: rounded sum of profit.
- `profit_margin_12m`: `SUM(profit) / NULLIF(SUM(revenue), 0)`, rounded to 4 decimals; may be NULL.
- `last_purchase_12m`: most recent sale in the window.

## Caveats
- This is **not** the integrated RFM v2 view: it uses `customer_key`, not `customer_identity_id`, and a different date window.
- The source query does not filter on `vw_customer_master`.
- The original `DEFINER` and `SQL SECURITY DEFINER` were omitted for portability. No calculation or filter was changed.
- Not executed against the source database.
