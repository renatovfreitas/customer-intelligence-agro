-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: 04_customer_analytics
-- Purpose: Summarize historical purchasing activity by consolidated customer identity.
-- Depends on: vw_sales_unified_classified
-- Reference date: 2026-09-03 (fixed for reproducibility).
-- Profit: SUM ignores NULL costs/profits; NULL if all rows have NULL profit.
-- Item counts: count sales line records, not quantities sold.
-- Note: Definition was formatted from existing database DDL; not execution-tested.

CREATE OR REPLACE VIEW vw_customer_historical_profile AS
SELECT
    s.customer_identity_id,
    MIN(s.sale_date) AS first_purchase_date,
    MAX(s.sale_date) AS last_purchase_date,
    TO_DAYS('2026-09-03') - TO_DAYS(MAX(s.sale_date)) AS recency_days,
    COUNT(DISTINCT CONCAT(CONVERT(s.source_system USING latin1), ':', s.sale_control)) AS total_purchases,
    ROUND(SUM(s.revenue), 2) AS lifetime_revenue,
    ROUND(SUM(s.profit), 2) AS known_lifetime_profit,
    SUM(CASE WHEN s.item_type = 'PRODUCT' THEN 1 ELSE 0 END) AS product_items,
    SUM(CASE WHEN s.item_type = 'SERVICE' THEN 1 ELSE 0 END) AS service_items
FROM vw_sales_unified_classified AS s
WHERE
    s.customer_identity_id IS NOT NULL
    AND s.sale_date >= '2018-01-01'
    AND s.sale_date <= '2026-09-03'
GROUP BY
    s.customer_identity_id;
