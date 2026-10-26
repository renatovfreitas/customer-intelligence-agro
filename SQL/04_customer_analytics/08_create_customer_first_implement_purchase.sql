-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: First IMPLEMENTOS purchase per customer within the analysis window.
-- Dependency: vw_sales_enriched
-- Period: 2025-07-08 inclusive through 2026-07-08 exclusive.
-- Scope: Current ERP customer_key (not unified customer_identity_id).

CREATE OR REPLACE VIEW vw_customer_first_implement_purchase AS
SELECT
    se.customer_key,
    MIN(se.sale_date) AS first_implement_purchase
FROM vw_sales_enriched AS se
WHERE se.product_group = 'IMPLEMENTOS'
  AND se.sale_date >= '2025-07-08'
  AND se.sale_date < '2026-07-08'
GROUP BY se.customer_key;
