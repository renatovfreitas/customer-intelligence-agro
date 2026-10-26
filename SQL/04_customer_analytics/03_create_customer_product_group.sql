-- Project: Customer Intelligence for Agricultural Machinery Retail
-- View: vw_customer_product_group
-- Purpose: Aggregate revenue, profit and distinct sales by customer and product group.
-- Dependencies: vw_sales_enriched, vw_customer_master
-- Scope: 2025-07-08 inclusive through 2026-07-08 exclusive.
-- Note: Uses customer_key (prior/current ERP analytical layer), not consolidated customer_identity_id.
-- Note: Original DEFINER and SQL SECURITY DEFINER omitted for portability.

CREATE OR REPLACE VIEW vw_customer_product_group AS
SELECT
    se.customer_key AS customer_key,
    se.product_group AS product_group,
    SUM(se.revenue) AS group_revenue,
    SUM(se.profit) AS group_profit,
    COUNT(DISTINCT se.sale_control) AS group_sales_qtt
FROM vw_sales_enriched AS se
INNER JOIN vw_customer_master AS cm
    ON se.customer_key = cm.customer_key
WHERE se.sale_date >= '2025-07-08'
  AND se.sale_date < '2026-07-08'
GROUP BY
    se.customer_key,
    se.product_group;
