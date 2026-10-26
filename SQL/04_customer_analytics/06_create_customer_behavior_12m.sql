-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Summarize customer purchasing behavior over the original 12-month window.
-- Dependency: vw_sales_enriched
-- Scope: Original current-ERP analytical layer; customer_key, not customer_identity_id.
-- Window: 2025-07-08 inclusive to 2026-07-08 exclusive.

CREATE OR REPLACE VIEW vw_customer_behavior_12m AS
SELECT
    se.customer_key,
    COUNT(DISTINCT se.sale_control) AS frequency_12m,
    ROUND(SUM(se.revenue), 2) AS monetary_12m,
    ROUND(SUM(se.profit), 2) AS profit_12m,
    ROUND(
        SUM(se.profit) / NULLIF(SUM(se.revenue), 0),
        4
    ) AS profit_margin_12m,
    MAX(se.sale_date) AS last_purchase_12m
FROM vw_sales_enriched AS se
WHERE se.sale_date >= '2025-07-08'
  AND se.sale_date < '2026-07-08'
GROUP BY se.customer_key;
