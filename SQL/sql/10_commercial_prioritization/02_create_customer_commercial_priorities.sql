
/*
============================================================
10 — COMMERCIAL PRIORITIZATION
02 — CUSTOMER COMMERCIAL PRIORITIES
============================================================

Purpose:
Identify potential commercial opportunities among
customers who remain active in the company.

Grain:
Customer + historical product group.

Prioritization:
- Recurring products: category reactivation.
- Long-cycle products: complementary sales review.
- Other groups: not automatically prioritized.

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_commercial_priorities AS

SELECT
    c.customer_identity_id,
    c.product_group,

    p.purchase_cycle,

    c.customer_segment,
    c.r_score,
    c.f_score,
    c.m_score,

    c.customer_recency_days,
    c.customer_frequency_12m,
    c.customer_monetary_12m,

    c.lifetime_revenue,
    c.lifetime_profit,
    c.lifetime_sales_count,

    c.revenue_12m,
    c.sales_count_12m,

    c.last_purchase,
    c.group_recency_days,

    c.commercial_status,

    
/*
Commercial priority v2

Recurring groups:
- P1: strong historical frequency and value
- P2: meaningful frequency or value
- P3: remaining inactive recurring groups

Long-cycle groups:
- Review complementary sales opportunities
*/

CASE
    WHEN p.purchase_cycle = 'RECURRING'
     AND c.lifetime_sales_count >= 11
     AND c.lifetime_revenue >= 5000
    THEN 'P1_HIGH'

    WHEN p.purchase_cycle = 'RECURRING'
     AND (
         c.lifetime_sales_count >= 5
         OR c.lifetime_revenue >= 1000
     )
    THEN 'P2_MEDIUM'

    WHEN p.purchase_cycle = 'RECURRING'
    THEN 'P3_MONITOR'

    WHEN p.purchase_cycle = 'LONG_CYCLE'
    THEN 'LONG_CYCLE_REVIEW'

    ELSE 'NOT_PRIORITIZED'
END AS commercial_priority,

    CASE
        WHEN p.purchase_cycle = 'RECURRING'
        THEN 'CATEGORY_REACTIVATION'

        WHEN p.purchase_cycle = 'LONG_CYCLE'
        THEN 'COMPLEMENTARY_SALES_REVIEW'

        ELSE 'BUSINESS_REVIEW'
    END AS opportunity_type

FROM vw_customer_commercial_profile AS c

INNER JOIN vw_product_group_commercial_policy AS p
    ON c.product_group = p.product_group

WHERE c.commercial_status =
    'GROUP_INACTIVE_CUSTOMER_ACTIVE';
