-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: RFM segmentation
-- Purpose: Customer lifetime and trailing-12-month RFM metrics.
-- Dependency: vw_sales_unified_classified
-- Snapshot date: 2026-09-03; 12-month window: 2025-09-04 through 2026-09-03 (inclusive).
-- Note: Profit may be NULL where no known costs/profit are available.

CREATE OR REPLACE VIEW vw_customer_rfm_base_v2 AS

SELECT
    customer_identity_id,

    MIN(sale_date) AS first_purchase_date,
    MAX(sale_date) AS last_purchase_date,

    DATEDIFF(
        '2026-09-03',
        MAX(sale_date)
    ) AS recency_days,

    COUNT(
        DISTINCT CONCAT(
            source_system,
            ':',
            sale_control
        )
    ) AS total_purchases,

    ROUND(SUM(revenue), 2) AS lifetime_revenue,

    COUNT(
        DISTINCT CASE
            WHEN sale_date >= '2025-09-04'
             AND sale_date <= '2026-09-03'
            THEN CONCAT(
                source_system,
                ':',
                sale_control
            )
            ELSE NULL
        END
    ) AS frequency_12m,

    ROUND(
        SUM(
            CASE
                WHEN sale_date >= '2025-09-04'
                 AND sale_date <= '2026-09-03'
                THEN revenue
                ELSE 0
            END
        ), 2
    ) AS monetary_12m,

    ROUND(
        SUM(
            CASE
                WHEN sale_date >= '2025-09-04'
                 AND sale_date <= '2026-09-03'
                THEN profit
                ELSE NULL
            END
        ), 2
    ) AS profit_12m

FROM vw_sales_unified_classified

WHERE customer_identity_id IS NOT NULL
  AND sale_date >= '2018-01-01'
  AND sale_date <= '2026-09-03'

GROUP BY customer_identity_id;
