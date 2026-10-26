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


# vw_customer_after_sales

## Purpose
Measures parts sales and revenue after a customer's first implement purchase in the original current-ERP analytics layer.

## Dependencies
- `vw_customer_first_implement_purchase` (`customer_key`, `first_implement_purchase`)
- `vw_sales_enriched` (`customer_key`, `sale_date`, `sale_control`, `product_group`, `revenue`)

## Business rules
- One output row per `customer_key` and `first_implement_purchase`.
- Only `product_group = 'PECAS'` is counted for after-sales metrics.
- `sale_date > first_implement_purchase` excludes transactions on the same calendar date.
- Sales joined through `sale_date < '2026-07-08'` (exclusive upper bound).
- `LEFT JOIN` preserves customers without later parts sales, with zero metrics.
- Uses the original `customer_key` and is not directly aligned with the consolidated RFM v2 `customer_identity_id`.
- The start date and eligibility of the first implement purchase depend on the upstream view definition.

## Notes
The script removes the environment-specific DEFINER/SQL SECURITY DEFINER clause. It preserves the original query logic. Not executed against the database.


# vw_customer_first_implement_purchase

**Purpose:** Find each customer's earliest IMPLEMENTOS purchase **within** the analysis window, not necessarily their first purchase ever.

**Source:** `vw_sales_enriched` (current ERP), using `customer_key`.

**Window:** 2025-07-08 inclusive to 2026-07-08 exclusive.

**Output:** `customer_key`, `first_implement_purchase` = `MIN(sale_date)`.

**Downstream dependency:** `vw_customer_after_sales` uses this date to count subsequent PECAS sales and revenue, with `sale_date > first_implement_purchase`; same-day purchases are excluded.

**Limitations:** Does not use unified `customer_identity_id`; purchases before the window do not count toward the first date; no customer with zero IMPLEMENTOS purchases appears. Script not executed/tested against database.

**Build order:** Create this view before `vw_customer_after_sales`, despite the existing documentation numbering.


# Customer commercial segmentation (original ERP)

**File:** `sql/04_customer_analytics/09_create_customer_commercial_segment.sql`

## Purpose and scope

Combines `vw_customer_profile` (cp), `vw_customer_product_behavior` (pb) and `vw_customer_after_sales` (ca) by `customer_key`. This is the **original current-ERP layer**, not the consolidated `customer_identity_id` / RFM v2 layer. The reference date used for implement age is **2026-07-08**. Other date windows and metrics are inherited from upstream views.

## Ordered classification rules

The first matching condition wins:

1. `AFTER-SALES OPPORTUNITY`: implement first purchase exists, at least 180 days elapsed, zero subsequent parts sales.
2. `RECURRING COOLING DOWN`: dominant group PECAS, R <= 3, F >= 4.
3. `HIGH VALUE EQUIPMENT`: dominant group IMPLEMENTOS or TRATORES, M >= 4.
4. `CORE ACTIVE`: R >= 4, F >= 4, M >= 3.
5. `HIGH VALUE OCCASIONAL`: M >= 4.
6. `DORMANT HIGH POTENTIAL`: R = 1 and historical frequency >= 4 or historical revenue >= 3000.
7. `LOW ENGAGEMENT`: fallback.

## Important cautions

- `AFTER-SALES OPPORTUNITY` is a rule-based sales lead, **not proof of unmet maintenance need**. Same-day parts sales are excluded by the upstream after-sales view.
- `LEFT JOIN` retains customers with no product behavior or after-sales record.
- The view exposes `cpf_cnpj` and `customer_name`. Do not commit query results, exported personal data or customer identities to public GitHub repositories.
- Confirm that `vw_customer_profile` returns one row per `customer_key`. The upstream dominant-product view currently has no observed ties, but ties could duplicate rows later.
- `CREATE OR REPLACE VIEW` replaces an existing view. Execute only after checking permissions and downstream dependencies.
- This script is formatted from the supplied definition, not tested against the database.

## Read-only validation

```sql
SELECT commercial_segment, COUNT(*) AS customers,
       ROUND(SUM(monetary_12m), 2) AS revenue_12m
FROM vw_customer_commercial_segment
GROUP BY commercial_segment
ORDER BY customers DESC;
```


# vw_customer_profile

- Source: `vw_customer_profile_base`.
- Consumer: `vw_customer_commercial_segment`.
- Original analytical model using `customer_key`; not the consolidated `customer_identity_id` model.
- Preserves the exact R/F/M score thresholds of the supplied view.
- `recency`, `frequency_12m`, and `monetary_12m` are inherited; dates and filters must be verified in `vw_customer_profile_base`.
- The view includes `cpf_cnpj`: publish SQL definitions only, not customer records.
- The SQL removes environment-specific DEFINER and SQL SECURITY DEFINER clauses.
- Not executed or validated against the database.

## Score rules

- R: <=30:5; <=90:4; <=180:3; <=365:2; otherwise 1.
- F: >=11:5; >=4:4; >=2:3; =1:2; otherwise 1.
- M (BRL): >=10000:5; >=3000:4; >=500:3; >0:2; otherwise 1.

## Deployment

Create `vw_customer_profile_base` before this view; create `vw_customer_commercial_segment` afterward.


For further dependency documentation, inspect `SHOW CREATE VIEW vw_customer_profile;`.


# vw_customer_profile_base

## Purpose
Combine historical customer metrics from `vw_customer_master` with 12-month behavior from `vw_customer_behavior_12m` for the original RFM scoring model.

## Dependencies
- `vw_customer_master`: customer_key, customer_name, cpf_cnpj, days_since_last_purchase, revenue, profit, sales_qtt, last_purchase.
- `vw_customer_behavior_12m`: frequency_12m, monetary_12m, profit_12m, profit_margin_12m.

## Business rules
- LEFT JOIN retains all customers in `vw_customer_master`, including those with no 12-month behavior row.
- COALESCE sets missing frequency, monetary and profit metrics to 0.
- Missing `profit_margin_12m` stays NULL.
- `recency` is inherited from `vw_customer_master`, and is not recalculated here.
- The 12-month window is inherited from `vw_customer_behavior_12m` (2025-07-08 inclusive through 2026-07-08 exclusive).
- Uses `customer_key` and is not equivalent to the consolidated `customer_identity_id` in RFM v2.

## Privacy
The view exposes `cpf_cnpj`; do not publish actual query results with customer documents.

## Deployment
Execute after creating both upstream views. The original view used a database-specific DEFINER and SQL SECURITY DEFINER; the portable script omits both. SQL not executed against the database.
