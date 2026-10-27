-- Data Validation
-- RFM Population and Revenue Reconciliation
--
-- Compares the RFM base with the final segmentation.
-- Expected result: PASS

SELECT
    base.total_customers AS base_customers,
    seg.total_customers AS segmented_customers,

    base.total_customers
        - seg.total_customers AS customer_difference,

    base.total_revenue AS base_revenue,
    seg.total_revenue AS segmented_revenue,

    ROUND(
        base.total_revenue - seg.total_revenue,
        2
    ) AS revenue_difference,

    CASE
        WHEN base.total_customers = seg.total_customers
         AND ABS(
             base.total_revenue - seg.total_revenue
         ) < 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM (
    SELECT
        COUNT(*) AS total_customers,
        COALESCE(SUM(monetary_12m), 0)
            AS total_revenue
    FROM vw_customer_rfm_base_v2
) AS base

CROSS JOIN (
    SELECT
        COUNT(*) AS total_customers,
        COALESCE(SUM(monetary_12m), 0)
            AS total_revenue
    FROM vw_customer_segments_v2
) AS seg;
