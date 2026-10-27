-- Project: Customer Intelligence for Agricultural Machinery Retail
-- View: vw_customer_master
-- Dependency: vw_sales_enriched
-- Scope: Current ERP, 2024-08-01 to 2026-07-07

CREATE OR REPLACE VIEW vw_customer_master AS
SELECT
    se.customer_key,
    se.customer_name,
    se.cpf_cnpj_normalized AS cpf_cnpj,

    SUM(se.revenue) AS revenue,
    SUM(se.profit) AS profit,

    SUM(se.profit) / NULLIF(SUM(se.revenue), 0)
        AS profit_margin,

    COUNT(DISTINCT se.sale_control) AS sales_qtt,
    SUM(se.quantity) AS items_qtt,

    COUNT(DISTINCT se.product_name)
        AS distinct_products,

    COUNT(DISTINCT UCASE(TRIM(se.product_subgroup)))
        AS distinct_product_subcategories,

    COUNT(DISTINCT se.product_group_id)
        AS distinct_product_groups,

    SUM(se.revenue)
        / NULLIF(COUNT(DISTINCT se.sale_control), 0)
        AS average_ticket,

    SUM(se.quantity)
        / NULLIF(COUNT(DISTINCT se.sale_control), 0)
        AS average_items_per_sale,

    SUM(se.profit)
        / NULLIF(COUNT(DISTINCT se.sale_control), 0)
        AS average_profit_per_sale,

    SUM(se.revenue)
        / NULLIF(SUM(se.quantity), 0)
        AS average_revenue_per_item,

    SUM(se.profit)
        / NULLIF(SUM(se.quantity), 0)
        AS average_profit_per_item,

    MAX(se.sale_date) AS last_purchase,

    TO_DAYS('2026-07-08')
        - TO_DAYS(MAX(se.sale_date))
        AS days_since_last_purchase

FROM vw_sales_enriched AS se

WHERE
    se.sale_date >= '2024-08-01'
    AND se.sale_date < '2026-07-08'
    AND se.customer_name IS NOT NULL
    AND UCASE(TRIM(se.customer_name)) NOT IN (
        '',
        '* CLIENTE NAO INFORMADO',
        'CLIENTE NAO INFORMADO',
        'CONSUMIDOR',
        'CLIENTE BALCAO'
    )

GROUP BY
    se.customer_key,
    se.customer_name,
    se.cpf_cnpj_normalized;
