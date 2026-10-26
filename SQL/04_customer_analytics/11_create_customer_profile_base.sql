-- Project: Customer Intelligence for Agricultural Machinery Retail
-- View: vw_customer_profile_base
-- Dependencies: vw_customer_master, vw_customer_behavior_12m
-- Scope: original current-ERP analytics, using customer_key.
-- Note: Date windows and recency are inherited from the upstream views.

CREATE OR REPLACE VIEW vw_customer_profile_base AS
SELECT
    cm.customer_key AS customer_key,
    cm.customer_name AS customer_name,
    cm.cpf_cnpj AS cpf_cnpj,
    cm.days_since_last_purchase AS recency,
    COALESCE(b.frequency_12m, 0) AS frequency_12m,
    COALESCE(b.monetary_12m, 0) AS monetary_12m,
    COALESCE(b.profit_12m, 0) AS profit_12m,
    b.profit_margin_12m AS profit_margin_12m,
    cm.revenue AS historical_revenue,
    cm.profit AS historical_profit,
    cm.sales_qtt AS historical_frequency,
    cm.last_purchase AS last_purchase
FROM vw_customer_master AS cm
LEFT JOIN vw_customer_behavior_12m AS b
    ON cm.customer_key = b.customer_key;
