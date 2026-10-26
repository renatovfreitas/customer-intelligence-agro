-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Calculate each product group's share of customer revenue.
-- Dependencies: vw_customer_product_group, vw_customer_product_total
-- Note: customer_key is not assumed equivalent to customer_identity_id.
-- Note: group_revenue_pct is a ratio (not multiplied by 100).

CREATE OR REPLACE VIEW vw_customer_product_mix AS
SELECT
    pg.customer_key AS customer_key,
    pg.product_group AS product_group,
    pg.group_revenue AS group_revenue,
    pg.group_profit AS group_profit,
    pg.group_sales_qtt AS group_sales_qtt,
    (pg.group_revenue / NULLIF(t.total_revenue, 0)) AS group_revenue_pct
FROM vw_customer_product_group AS pg
INNER JOIN vw_customer_product_total AS t
    ON pg.customer_key = t.customer_key;
