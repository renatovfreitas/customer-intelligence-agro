
/*
============================================================
09 — DYNAMIC RFM
04 — CUSTOMER COMMERCIAL PROFILE
============================================================

Purpose:
Combine dynamic customer RFM segmentation with
historical and rolling 12-month product group behavior.

Grain:
One row per customer + product group.

Sources:
vw_customer_segments_dynamic
vw_customer_group_profile

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_commercial_profile AS

SELECT
    g.customer_identity_id,
    g.product_group,

    -- Customer segmentation
    r.customer_segment,
    r.r_score,
    r.f_score,
    r.m_score,

    r.recency_days AS customer_recency_days,

    r.frequency_12m AS customer_frequency_12m,
    r.monetary_12m AS customer_monetary_12m,

    -- Product group lifetime behavior
    g.lifetime_revenue,
    g.lifetime_profit,
    g.lifetime_sales_count,

    g.first_purchase,
    g.last_purchase,

    g.days_since_last_purchase
        AS group_recency_days,

    g.lifetime_revenue_pct,

    -- Product group rolling 12-month behavior
    g.revenue_12m,
    g.profit_12m,
    g.sales_count_12m,

    g.revenue_pct_12m,

    g.active_12m AS group_active_12m,

    -- Commercial activity status
    CASE
        WHEN g.active_12m = 1
        THEN 'ACTIVE_GROUP'

        WHEN g.active_12m = 0
         AND r.frequency_12m > 0
        THEN 'GROUP_INACTIVE_CUSTOMER_ACTIVE'

        ELSE 'CUSTOMER_INACTIVE'
    END AS commercial_status

FROM vw_customer_group_profile AS g

INNER JOIN vw_customer_segments_dynamic AS r
    ON g.customer_identity_id = r.customer_identity_id;
