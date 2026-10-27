-- Commercial Analysis
-- Parts and Services Penetration Among Implement Buyers
--
-- Source: vw_sales_unified_classified
-- Customer ID: customer_identity_id
-- Period: 2025-09-04 to 2026-09-03 (inclusive)

SELECT
    COUNT(*) AS implements_customers,

    SUM(buys_parts) AS customers_buying_parts,

    SUM(buys_services) AS customers_buying_services,

    SUM(
        CASE
            WHEN buys_parts = 0
             AND buys_services = 0
            THEN 1 ELSE 0
        END
    ) AS customers_neither,

    ROUND(
        100.0 * SUM(buys_parts) / NULLIF(COUNT(*), 0),
        2
    ) AS parts_penetration_pct,

    ROUND(
        100.0 * SUM(buys_services) / NULLIF(COUNT(*), 0),
        2
    ) AS services_penetration_pct

FROM (
    SELECT
        customer_identity_id,

        MAX(
            CASE
                WHEN analytical_product_group = 'IMPLEMENTOS'
                THEN 1 ELSE 0
            END
        ) AS buys_implements,

        MAX(
            CASE
                WHEN analytical_product_group = 'PECAS'
                THEN 1 ELSE 0
            END
        ) AS buys_parts,

        MAX(
            CASE
                WHEN analytical_product_group = 'SERVICOS'
                THEN 1 ELSE 0
            END
        ) AS buys_services

    FROM vw_sales_unified_classified

    WHERE customer_identity_id IS NOT NULL
      AND sale_date >= '2025-09-04'
      AND sale_date < '2026-09-04'

    GROUP BY customer_identity_id
) AS customer_purchase_flags

WHERE buys_implements = 1;
