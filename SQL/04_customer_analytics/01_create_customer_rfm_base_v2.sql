-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: RFM segmentation
-- Purpose: Customer lifetime and trailing-12-month RFM metrics.
-- Dependency: vw_sales_unified_classified
-- Snapshot date: 2026-09-03; 12-month window: 2025-09-04 through 2026-09-03 (inclusive).
-- Note: Profit may be NULL where no known costs/profit are available.

CREATE OR REPLACE VIEW vw_customer_rfm_base_v2 AS
SELECT
    s.customer_identity_id,
    MIN(s.sale_date) AS first_purchase_date,
    MAX(s.sale_date) AS last_purchase_date,
    TO_DAYS('2026-09-03') - TO_DAYS(MAX(s.sale_date)) AS recency_days,
    COUNT(DISTINCT CONCAT(CONVERT(s.source_system USING latin1), ':', s.sale_control)) AS total_purchases,
    ROUND(SUM(s.revenue), 2) AS lifetime_revenue,
    COUNT(DISTINCT CASE
        WHEN s.sale_date >= '2025-09-04' AND s.sale_date <= '2026-09-03'
        THEN CONCAT(CONVERT(s.source_system USING latin1), ':', s.sale_control)
        ELSE NULL
    END) AS frequency_12m,
    ROUND(SUM(CASE
        WHEN s.sale_date >= '2025-09-04' AND s.sale_date <= '2026-09-03'
        THEN s.revenue ELSE 0
    END), 2) AS monetary_12m,
    ROUND(SUM(CASE
        WHEN s.sale_date >= '2025-09-04' AND s.sale_date <= '2026-09-03'
        THEN s.profit ELSE NULL
    END), 2) AS profit_12m
FROM vw_sales_unified_classified AS s
WHERE s.customer_identity_id IS NOT NULL
  AND s.sale_date >= '2018-01-01'
  AND s.sale_date <= '2026-09-03'
GROUP BY s.customer_identity_id;
