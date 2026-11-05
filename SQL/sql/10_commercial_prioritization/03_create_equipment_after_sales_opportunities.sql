
/*
============================================================
10 — COMMERCIAL PRIORITIZATION
03A — EQUIPMENT CUSTOMER BASE
============================================================

Grain:
Customer + equipment product group.

Only completed SALE transactions are considered.
Future-dated transactions are excluded.

============================================================
*/

CREATE OR REPLACE VIEW vw_equipment_customer_base AS

SELECT
    s.customer_identity_id,

    s.analytical_product_group
        AS equipment_group,

    MIN(s.sale_date)
        AS first_equipment_purchase,

    MAX(s.sale_date)
        AS last_equipment_purchase,

    DATEDIFF(
        CURDATE(),
        MAX(s.sale_date)
    ) AS equipment_age_days,

    COUNT(
        DISTINCT CONCAT(
            s.source_system,
            ':',
            s.sale_control
        )
    ) AS equipment_sales_count,

    SUM(s.revenue)
        AS equipment_lifetime_revenue

FROM vw_sales_unified_classified AS s

WHERE s.customer_identity_id IS NOT NULL
  AND s.transaction_type = 'SALE'
  AND s.analytical_product_group IN (
      'TRATORES',
      'IMPLEMENTOS'
  )
  AND s.sale_date <= CURDATE()

GROUP BY
    s.customer_identity_id,
    s.analytical_product_group;

/*
Commercial configuration:
Complementary product groups for equipment after-sales.
*/

CREATE TABLE IF NOT EXISTS
dim_equipment_complementary_group (
    product_group VARCHAR(100) PRIMARY KEY
);

INSERT IGNORE INTO dim_equipment_complementary_group
    (product_group)
VALUES
    ('PECAS'),
    ('SERVICOS'),
    ('OLEOS E LUBRIFICANTES');



/*
============================================================
10 — COMMERCIAL PRIORITIZATION
03B — EQUIPMENT AFTER-SALES BASE
============================================================

Grain:
Customer + equipment group + complementary group.

Measures:
- Complementary purchases after latest equipment sale
- Complementary purchases in rolling 12 months
- Last complementary purchase

============================================================
*/

CREATE OR REPLACE VIEW vw_equipment_after_sales_base AS

SELECT
    e.customer_identity_id,
    e.equipment_group,

    e.first_equipment_purchase,
    e.last_equipment_purchase,
    e.equipment_age_days,
    e.equipment_sales_count,
    e.equipment_lifetime_revenue,

    p.product_group
        AS complementary_group,

    COUNT(
        DISTINCT CASE
            WHEN s.sale_date >= e.last_equipment_purchase
            THEN CONCAT(
                s.source_system,
                ':',
                s.sale_control
            )
        END
    ) AS purchases_after_equipment,

    COUNT(
        DISTINCT CASE
            WHEN s.sale_date >= DATE_SUB(
                CURDATE(), INTERVAL 12 MONTH
            )
            THEN CONCAT(
                s.source_system,
                ':',
                s.sale_control
            )
        END
    ) AS complementary_purchases_12m,

    SUM(
        CASE
            WHEN s.sale_date >= e.last_equipment_purchase
            THEN s.revenue
            ELSE 0
        END
    ) AS revenue_after_equipment,

    MAX(s.sale_date)
        AS last_complementary_purchase

FROM vw_equipment_customer_base AS e

CROSS JOIN dim_equipment_complementary_group AS p

LEFT JOIN vw_sales_unified_classified AS s
    ON s.customer_identity_id = e.customer_identity_id
   AND s.analytical_product_group = p.product_group
   AND s.transaction_type = 'SALE'
   AND s.sale_date <= CURDATE()

GROUP BY
    e.customer_identity_id,
    e.equipment_group,
    e.first_equipment_purchase,
    e.last_equipment_purchase,
    e.equipment_age_days,
    e.equipment_sales_count,
    e.equipment_lifetime_revenue,
    p.product_group;

/*
============================================================
10 — COMMERCIAL PRIORITIZATION
03C — EQUIPMENT AFTER-SALES OPPORTUNITIES
============================================================

Purpose:
Prioritize complementary sales and after-sales
relationship opportunities for equipment buyers.

============================================================
*/

CREATE OR REPLACE VIEW vw_equipment_after_sales_opportunities AS

SELECT
    a.customer_identity_id,

    r.customer_segment,
    r.r_score,
    r.f_score,
    r.m_score,

    r.recency_days AS customer_recency_days,
    r.frequency_12m AS customer_frequency_12m,

    a.equipment_group,
    a.complementary_group,

    a.first_equipment_purchase,
    a.last_equipment_purchase,
    a.equipment_age_days,

    a.equipment_sales_count,
    a.equipment_lifetime_revenue,

    a.purchases_after_equipment,
    a.complementary_purchases_12m,

    a.revenue_after_equipment,
    a.last_complementary_purchase,

    CASE
        WHEN a.complementary_purchases_12m > 0
        THEN 'EXISTING_RELATIONSHIP'

        WHEN a.purchases_after_equipment > 0
        THEN 'P2_REACTIVATION'

        WHEN a.equipment_age_days >= 180
        THEN 'P1_HIGH'

        WHEN a.equipment_age_days >= 90
        THEN 'P2_MEDIUM'

        ELSE 'P3_EARLY_STAGE'
    END AS after_sales_priority

FROM vw_equipment_after_sales_base AS a

INNER JOIN vw_customer_segments_dynamic AS r
    ON a.customer_identity_id = r.customer_identity_id;

