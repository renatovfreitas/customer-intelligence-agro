-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: RFM segmentation
-- Purpose: Assign R, F, and M scores (1 to 5) using fixed business thresholds.
-- Dependency: vw_customer_rfm_base_v2
-- Note: Thresholds are absolute, not quantile-based.

CREATE OR REPLACE VIEW vw_customer_rfm_scores_v2 AS

SELECT
    customer_identity_id,

    first_purchase_date,
    last_purchase_date,
    recency_days,

    total_purchases,
    lifetime_revenue,

    frequency_12m,
    monetary_12m,
    profit_12m,

    -- RECENCY SCORE
    CASE
        WHEN recency_days <= 30 THEN 5
        WHEN recency_days <= 90 THEN 4
        WHEN recency_days <= 180 THEN 3
        WHEN recency_days <= 365 THEN 2
        ELSE 1
    END AS r_score,

    -- FREQUENCY SCORE
    CASE
        WHEN frequency_12m >= 11 THEN 5
        WHEN frequency_12m >= 6 THEN 4
        WHEN frequency_12m >= 4 THEN 3
        WHEN frequency_12m >= 2 THEN 2
        ELSE 1
    END AS f_score,

    -- MONETARY SCORE
    CASE
        WHEN monetary_12m >= 25000 THEN 5
        WHEN monetary_12m >= 5000 THEN 4
        WHEN monetary_12m >= 1000 THEN 3
        WHEN monetary_12m >= 500 THEN 2
        ELSE 1
    END AS m_score

FROM vw_customer_rfm_base_v2;
