-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Assign commercial action segments using the original current-ERP customer profile,
-- product behavior and after-sales metrics.
-- Dependencies: vw_customer_profile, vw_customer_product_behavior, vw_customer_after_sales
-- Scope: Original current-ERP analytical layer (customer_key), not unified RFM v2.
-- Reference date for days_since_first_implement: 2026-07-08.
-- Warning: Includes customer_name and cpf_cnpj; publish SQL definition only, never result rows.

CREATE OR REPLACE VIEW vw_customer_commercial_segment AS
SELECT
    cp.customer_key,
    cp.customer_name,
    cp.cpf_cnpj,
    cp.recency,
    cp.frequency_12m,
    cp.monetary_12m,
    cp.r_score,
    cp.f_score,
    cp.m_score,
    cp.profit_12m,
    cp.profit_margin_12m,
    cp.historical_revenue,
    cp.historical_profit,
    cp.historical_frequency,
    cp.last_purchase,
    pb.dominant_product_group,
    pb.dominant_group_revenue,
    pb.dominant_group_revenue_pct,
    pb.dominant_group_profit,
    pb.dominant_group_sales_qtt,
    ca.first_implement_purchase,
    CASE
        WHEN ca.first_implement_purchase IS NOT NULL
        THEN TO_DAYS('2026-07-08') - TO_DAYS(ca.first_implement_purchase)
        ELSE NULL
    END AS days_since_first_implement,
    ca.parts_sales_after_implement,
    ca.parts_revenue_after_implement,
    CASE
        WHEN ca.first_implement_purchase IS NOT NULL
             AND TO_DAYS('2026-07-08') - TO_DAYS(ca.first_implement_purchase) >= 180
             AND ca.parts_sales_after_implement = 0
        THEN 'AFTER-SALES OPPORTUNITY'
        WHEN pb.dominant_product_group = 'PECAS'
             AND cp.r_score <= 3
             AND cp.f_score >= 4
        THEN 'RECURRING COOLING DOWN'
        WHEN pb.dominant_product_group IN ('IMPLEMENTOS', 'TRATORES')
             AND cp.m_score >= 4
        THEN 'HIGH VALUE EQUIPMENT'
        WHEN cp.r_score >= 4
             AND cp.f_score >= 4
             AND cp.m_score >= 3
        THEN 'CORE ACTIVE'
        WHEN cp.m_score >= 4
        THEN 'HIGH VALUE OCCASIONAL'
        WHEN cp.r_score = 1
             AND (cp.historical_frequency >= 4 OR cp.historical_revenue >= 3000)
        THEN 'DORMANT HIGH POTENTIAL'
        ELSE 'LOW ENGAGEMENT'
    END AS commercial_segment
FROM vw_customer_profile AS cp
LEFT JOIN vw_customer_product_behavior AS pb
    ON cp.customer_key = pb.customer_key
LEFT JOIN vw_customer_after_sales AS ca
    ON cp.customer_key = ca.customer_key;
