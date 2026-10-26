-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Identify each customer's highest-revenue product group(s).
-- Dependencies: vw_customer_product_mix
-- Scope: Inherited from vw_customer_product_mix (current ERP, 2025-07-08 to 2026-07-07).
-- Important: Revenue ties return multiple rows per customer; no tie-breaker is applied.

CREATE OR REPLACE VIEW vw_customer_product_behavior AS
SELECT
    pm.customer_key,
    pm.product_group AS dominant_product_group,
    pm.group_revenue AS dominant_group_revenue,
    pm.group_revenue_pct AS dominant_group_revenue_pct,
    pm.group_profit AS dominant_group_profit,
    pm.group_sales_qtt AS dominant_group_sales_qtt
FROM vw_customer_product_mix AS pm
LEFT JOIN vw_customer_product_mix AS pm2
    ON pm.customer_key = pm2.customer_key
   AND pm2.group_revenue > pm.group_revenue
WHERE pm2.customer_key IS NULL;
