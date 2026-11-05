
/*
============================================================
09 — DYNAMIC RFM
03 — CUSTOMER SEGMENTS
============================================================

Purpose:
Apply the validated RFM v2 segmentation rules
using a dynamic reference date.

New customer definition:
First purchase within the last 90 days.

============================================================
*/

CREATE OR REPLACE VIEW vw_customer_segments_dynamic AS

SELECT
    r.*,

    CASE
        WHEN r.r_score >= 4
         AND r.f_score >= 4
         AND r.m_score >= 4
        THEN 'VIP'

        WHEN r.r_score >= 3
         AND r.f_score >= 4
        THEN 'Loyal Customers'

        WHEN r.r_score >= 3
         AND r.m_score >= 4
        THEN 'High-Value Occasional'

        WHEN r.first_purchase_date >= DATE_SUB(
            CURDATE(), INTERVAL 90 DAY
        )
        THEN 'New Customers'

        WHEN r.r_score >= 4
        THEN 'Promising'

        WHEN r.r_score = 2
         AND (r.f_score >= 3 OR r.m_score >= 3)
        THEN 'At Risk'

        WHEN r.r_score >= 2
        THEN 'Active Occasional'

        WHEN r.r_score = 1
         AND r.lifetime_revenue >= 50000
        THEN 'High-Value Lost'

        WHEN r.r_score = 1
         AND r.lifetime_revenue >= 10000
        THEN 'Former Regular Customers'

        WHEN r.r_score = 1
         AND r.recency_days <= 730
        THEN 'Recently Inactive'

        ELSE 'Long-Term Inactive'
    END AS customer_segment

FROM vw_customer_rfm_scores_dynamic AS r;
