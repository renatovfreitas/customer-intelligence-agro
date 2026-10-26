-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: RFM segmentation
-- Purpose: Assign R, F, and M scores (1 to 5) using fixed business thresholds.
-- Dependency: vw_customer_rfm_base_v2
-- Note: Thresholds are absolute, not quantile-based.

CREATE OR REPLACE VIEW vw_customer_rfm_scores_v2 AS
SELECT
    b.customer_identity_id,
    b.first_purchase_date,
    b.last_purchase_date,
    b.recency_days,
    b.total_purchases,
    b.lifetime_revenue,
    b.frequency_12m,
    b.monetary_12m,
    b.profit_12m,
    CASE
        WHEN b.recency_days <= 30 THEN 5
        WHEN b.recency_days <= 90 THEN 4
        WHEN b.recency_days <= 180 THEN 3
        WHEN b.recency_days <= 365 THEN 2
        ELSE 1
    END AS r_score,
    CASE
        WHEN b.frequency_12m >= 11 THEN 5
        WHEN b.frequency_12m >= 6 THEN 4
        WHEN b.frequency_12m >= 4 THEN 3
        WHEN b.frequency_12m >= 2 THEN 2
        ELSE 1
    END AS f_score,
    CASE
        WHEN b.monetary_12m >= 25000 THEN 5
        WHEN b.monetary_12m >= 5000 THEN 4
        WHEN b.monetary_12m >= 1000 THEN 3
        WHEN b.monetary_12m >= 500 THEN 2
        ELSE 1
    END AS m_score
FROM vw_customer_rfm_base_v2 AS b;
