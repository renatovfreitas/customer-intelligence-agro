-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Calculate total product revenue per customer.
-- Dependencies: vw_customer_product_group
-- Scope: Current ERP, inherited from upstream views.

CREATE OR REPLACE VIEW vw_customer_product_total AS
SELECT
    pg.customer_key,
    SUM(pg.group_revenue) AS total_revenue
FROM vw_customer_product_group AS pg
GROUP BY
    pg.customer_key;
