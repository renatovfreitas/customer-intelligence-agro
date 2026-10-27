-- Project: Customer Intelligence for Agricultural Machinery Retail
-- View: vw_customer_profile
-- Dependency: vw_customer_profile_base
-- Scope: Original customer_key-based analytics; not consolidated RFM v2.
-- Note: The original view exposes cpf_cnpj; do not publish customer-level results.

CREATE OR REPLACE VIEW vw_customer_profile AS
SELECT
    b.customer_key,
    b.customer_name,
    b.cpf_cnpj,
    b.recency,
    b.frequency_12m,
    b.monetary_12m,
    CASE
        WHEN b.recency <= 30 THEN 5
        WHEN b.recency <= 90 THEN 4
        WHEN b.recency <= 180 THEN 3
        WHEN b.recency <= 365 THEN 2
        ELSE 1
    END AS r_score,
    CASE
        WHEN b.frequency_12m >= 11 THEN 5
        WHEN b.frequency_12m >= 4 THEN 4
        WHEN b.frequency_12m >= 2 THEN 3
        WHEN b.frequency_12m = 1 THEN 2
        ELSE 1
    END AS f_score,
    CASE
        WHEN b.monetary_12m >= 10000 THEN 5
        WHEN b.monetary_12m >= 3000 THEN 4
        WHEN b.monetary_12m >= 500 THEN 3
        WHEN b.monetary_12m > 0 THEN 2
        ELSE 1
    END AS m_score,
    b.profit_12m,
    b.profit_margin_12m,
    b.historical_revenue,
    b.historical_profit,
    b.historical_frequency,
    b.last_purchase
FROM vw_customer_profile_base AS b;
