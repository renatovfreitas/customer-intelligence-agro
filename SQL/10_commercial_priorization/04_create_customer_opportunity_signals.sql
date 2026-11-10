
/*
============================================================
10 — COMMERCIAL PRIORITIZATION
04 — CUSTOMER OPPORTUNITY SIGNALS
============================================================

Purpose:
Combine category reactivation and equipment after-sales
signals into a common structure.

Grain:
One row per source opportunity signal.

Priority rank:
1 = High
2 = Medium
3 = Monitor

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_opportunity_signals AS

SELECT
    customer_identity_id,
    product_group AS target_product_group,

    'CATEGORY_REACTIVATION' AS signal_type,

    CASE commercial_priority
        WHEN 'P1_HIGH' THEN 1
        WHEN 'P2_MEDIUM' THEN 2
        ELSE 3
    END AS priority_rank,

    lifetime_revenue AS historical_category_revenue,
    lifetime_sales_count AS historical_category_sales,

    CAST(NULL AS CHAR(100)) AS equipment_group,
    CAST(NULL AS SIGNED) AS equipment_age_days

FROM vw_customer_commercial_priorities

WHERE purchase_cycle = 'RECURRING'
  AND commercial_priority IN (
      'P1_HIGH',
      'P2_MEDIUM',
      'P3_MONITOR'
  )

UNION ALL

SELECT
    customer_identity_id,
    complementary_group AS target_product_group,

    'EQUIPMENT_AFTER_SALES' AS signal_type,

    CASE after_sales_priority
        WHEN 'P1_HIGH' THEN 1
        WHEN 'P2_MEDIUM' THEN 2
        WHEN 'P2_REACTIVATION' THEN 2
        ELSE 3
    END AS priority_rank,

    NULL AS historical_category_revenue,
    NULL AS historical_category_sales,

    equipment_group,
    equipment_age_days

FROM vw_equipment_after_sales_opportunities

WHERE after_sales_priority IN (
    'P1_HIGH',
    'P2_MEDIUM',
    'P2_REACTIVATION'
);
