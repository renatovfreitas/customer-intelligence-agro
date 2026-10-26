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
