
/*
============================================================
09 — DYNAMIC RFM
01 — CUSTOMER RFM BASE
============================================================

Purpose:
Calculate lifetime and rolling 12-month RFM metrics.

Grain:
One row per customer_identity_id.

Reference date:
CURDATE()

Business rules:
- SALE transactions only.
- Identified customers only.
- Historical data starts on 2018-01-01.
- Future-dated transactions are excluded.
- Rolling 12-month window includes today.
- Sales are counted distinctly across source systems.
- Missing profit is preserved as NULL where applicable.

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_rfm_base_dynamic AS

SELECT
    customer_identity_id,

    MIN(sale_date) AS first_purchase_date,
    MAX(sale_date) AS last_purchase_date,

    DATEDIFF(
        CURDATE(),
        MAX(sale_date)
    ) AS recency_days,

    COUNT(
        DISTINCT CONCAT(
            source_system,
            ':',
            sale_control
        )
    ) AS total_purchases,

    SUM(revenue) AS lifetime_revenue,

    COUNT(
        DISTINCT CASE
            WHEN sale_date >= DATE_SUB(
                CURDATE(), INTERVAL 12 MONTH
            )
            THEN CONCAT(
                source_system,
                ':',
                sale_control
            )
        END
    ) AS frequency_12m,

    SUM(
        CASE
            WHEN sale_date >= DATE_SUB(
                CURDATE(), INTERVAL 12 MONTH
            )
            THEN revenue
            ELSE 0
        END
    ) AS monetary_12m,

    SUM(
        CASE
            WHEN sale_date >= DATE_SUB(
                CURDATE(), INTERVAL 12 MONTH
            )
            THEN profit
            ELSE NULL
        END
    ) AS profit_12m

FROM vw_sales_unified_classified

WHERE customer_identity_id IS NOT NULL
  AND transaction_type = 'SALE'
  AND sale_date >= '2018-01-01'
  AND sale_date < DATE_ADD(CURDATE(), INTERVAL 1 DAY)

GROUP BY customer_identity_id;
