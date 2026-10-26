-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: RFM segmentation
-- Purpose: Assign a single commercial segment to each customer based on ordered business rules.
-- Dependency: vw_customer_rfm_scores_v2
-- Note: CASE order is intentional: the first matching condition wins.
-- Note: New Customers threshold is fixed at 2026-06-06.

CREATE OR REPLACE VIEW vw_customer_segments_v2 AS
SELECT
    r.customer_identity_id,
    r.first_purchase_date,
    r.last_purchase_date,
    r.recency_days,
    r.total_purchases,
    r.lifetime_revenue,
    r.frequency_12m,
    r.monetary_12m,
    r.profit_12m,
    r.r_score,
    r.f_score,
    r.m_score,
    CASE
        WHEN r.r_score >= 4 AND r.f_score >= 4 AND r.m_score >= 4
            THEN 'VIP'
        WHEN r.r_score >= 3 AND r.f_score >= 4
            THEN 'Loyal Customers'
        WHEN r.r_score >= 3 AND r.m_score >= 4
            THEN 'High-Value Occasional'
        WHEN r.first_purchase_date >= '2026-06-06'
            THEN 'New Customers'
        WHEN r.r_score >= 4
            THEN 'Promising'
        WHEN r.r_score = 2 AND (r.f_score >= 3 OR r.m_score >= 3)
            THEN 'At Risk'
        WHEN r.r_score >= 2
            THEN 'Active Occasional'
        WHEN r.r_score = 1 AND r.lifetime_revenue >= 50000
            THEN 'High-Value Lost'
        WHEN r.r_score = 1 AND r.lifetime_revenue >= 10000
            THEN 'Former Regular Customers'
        WHEN r.r_score = 1 AND r.recency_days <= 730
            THEN 'Recently Inactive'
        ELSE 'Long-Term Inactive'
    END AS customer_segment
FROM vw_customer_rfm_scores_v2 AS r;
