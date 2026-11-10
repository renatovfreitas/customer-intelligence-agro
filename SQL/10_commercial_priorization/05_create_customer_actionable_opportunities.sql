
/*
============================================================
10 — COMMERCIAL PRIORITIZATION
05 — CUSTOMER ACTIONABLE OPPORTUNITIES
============================================================

Purpose:
Consolidate commercial opportunity signals into one
actionable record per customer and target product group.

Priority:
The highest-priority signal determines the final rank.

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_actionable_opportunities AS

SELECT
    s.customer_identity_id,
    s.target_product_group,

    r.customer_segment,
    r.r_score,
    r.f_score,
    r.m_score,

    r.recency_days AS customer_recency_days,
    r.frequency_12m AS customer_frequency_12m,
    r.monetary_12m AS customer_revenue_12m,

    CASE MIN(s.priority_rank)
        WHEN 1 THEN 'P1_HIGH'
        WHEN 2 THEN 'P2_MEDIUM'
        ELSE 'P3_MONITOR'
    END AS final_priority,

    MAX(
        CASE
            WHEN s.signal_type = 'CATEGORY_REACTIVATION'
            THEN 1 ELSE 0
        END
    ) AS has_reactivation_signal,

    MAX(
        CASE
            WHEN s.signal_type = 'EQUIPMENT_AFTER_SALES'
            THEN 1 ELSE 0
        END
    ) AS has_after_sales_signal,

    MAX(s.historical_category_revenue)
        AS historical_category_revenue,

    MAX(s.historical_category_sales)
        AS historical_category_sales,

    MAX(s.equipment_age_days)
        AS max_equipment_age_days,

    MAX(
        CASE
            WHEN s.equipment_group = 'TRATORES'
            THEN 1 ELSE 0
        END
    ) AS has_tractor_history,

    MAX(
        CASE
            WHEN s.equipment_group = 'IMPLEMENTOS'
            THEN 1 ELSE 0
        END
    ) AS has_implements_history,

    CASE
        WHEN MAX(
            CASE
                WHEN s.signal_type = 'CATEGORY_REACTIVATION'
                THEN 1 ELSE 0
            END
        ) = 1
        AND MAX(
            CASE
                WHEN s.signal_type = 'EQUIPMENT_AFTER_SALES'
                THEN 1 ELSE 0
            END
        ) = 1
        THEN 'REACTIVATION_AND_AFTER_SALES'

        WHEN MAX(
            CASE
                WHEN s.signal_type = 'CATEGORY_REACTIVATION'
                THEN 1 ELSE 0
            END
        ) = 1
        THEN 'CATEGORY_REACTIVATION'

        ELSE 'EQUIPMENT_AFTER_SALES'
    END AS opportunity_type,

    CASE
        WHEN MAX(
            CASE
                WHEN s.signal_type = 'CATEGORY_REACTIVATION'
                THEN 1 ELSE 0
            END
        ) = 1
        AND MAX(
            CASE
                WHEN s.signal_type = 'EQUIPMENT_AFTER_SALES'
                THEN 1 ELSE 0
            END
        ) = 1
        THEN 'Review category repurchase and equipment support'

        WHEN MAX(
            CASE
                WHEN s.signal_type = 'CATEGORY_REACTIVATION'
                THEN 1 ELSE 0
            END
        ) = 1
        THEN 'Contact customer about category repurchase'

        ELSE 'Review equipment after-sales needs'
    END AS suggested_action

FROM vw_customer_opportunity_signals AS s

INNER JOIN vw_customer_segments_dynamic AS r
    ON s.customer_identity_id = r.customer_identity_id

GROUP BY
    s.customer_identity_id,
    s.target_product_group,

    r.customer_segment,
    r.r_score,
    r.f_score,
    r.m_score,
    r.recency_days,
    r.frequency_12m,
    r.monetary_12m;
