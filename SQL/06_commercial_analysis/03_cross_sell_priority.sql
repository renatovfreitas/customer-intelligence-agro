-- Commercial Analysis
-- Cross-Selling Opportunity Prioritization
--
-- Source: vw_sales_unified_classified
-- RFM: vw_customer_segments_v2
-- Period: 2025-09-04 to 2026-09-03
-- Reference date: 2026-09-03

SELECT
    flags.customer_identity_id,

    -- Opportunity classification
    CASE
        WHEN flags.buys_parts = 0
         AND flags.buys_services = 0
        THEN 'PARTS_AND_SERVICES_OPPORTUNITY'

        WHEN flags.buys_parts = 1
         AND flags.buys_services = 0
        THEN 'SERVICES_OPPORTUNITY'

        WHEN flags.buys_parts = 0
         AND flags.buys_services = 1
        THEN 'PARTS_OPPORTUNITY'

        ELSE 'NO_IDENTIFIED_GAP'
    END AS opportunity_type,

    -- Commercial priority
    CASE
        WHEN flags.buys_parts = 0
         AND flags.buys_services = 0
         AND DATEDIFF(
             '2026-09-03',
             flags.last_implement_purchase
         ) >= 180
        THEN 'P1_HIGH'

        WHEN flags.buys_services = 0
         AND DATEDIFF(
             '2026-09-03',
             flags.last_implement_purchase
         ) >= 90
        THEN 'P2_MEDIUM'

        ELSE 'P3_MONITOR'
    END AS commercial_priority,

    -- RFM information
    rfm.customer_segment,
    rfm.recency_days,
    rfm.frequency_12m,
    rfm.monetary_12m,
    rfm.lifetime_revenue,

    -- Implement purchase history
    flags.first_implement_purchase,
    flags.last_implement_purchase,

    DATEDIFF(
        '2026-09-03',
        flags.last_implement_purchase
    ) AS days_since_last_implement_purchase,

    -- Purchase flags
    flags.buys_parts,
    flags.buys_services

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
        ) AS buys_services,

        MIN(
            CASE
                WHEN analytical_product_group = 'IMPLEMENTOS'
                THEN sale_date
            END
        ) AS first_implement_purchase,

        MAX(
            CASE
                WHEN analytical_product_group = 'IMPLEMENTOS'
                THEN sale_date
            END
        ) AS last_implement_purchase

    FROM vw_sales_unified_classified

    WHERE customer_identity_id IS NOT NULL
      AND sale_date >= '2025-09-04'
      AND sale_date < '2026-09-04'

    GROUP BY customer_identity_id
) AS flags

LEFT JOIN vw_customer_segments_v2 AS rfm
    ON flags.customer_identity_id = rfm.customer_identity_id

WHERE flags.buys_implements = 1
  AND (
      flags.buys_parts = 0
      OR flags.buys_services = 0
  )

ORDER BY
    CASE
        WHEN flags.buys_parts = 0
         AND flags.buys_services = 0
         AND DATEDIFF(
             '2026-09-03',
             flags.last_implement_purchase
         ) >= 180
        THEN 1

        WHEN flags.buys_services = 0
         AND DATEDIFF(
             '2026-09-03',
             flags.last_implement_purchase
         ) >= 90
        THEN 2

        ELSE 3
    END,

    rfm.monetary_12m DESC,
    rfm.recency_days ASC;
