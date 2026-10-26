-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Measure parts purchases after each customer's first implement purchase.
-- Dependencies: vw_customer_first_implement_purchase, vw_sales_enriched
-- Scope: Original current-ERP customer_key analysis; cutoff 2026-07-08 (exclusive).
-- Note: Purchases on the first implement purchase date are excluded from parts metrics.

CREATE OR REPLACE VIEW vw_customer_after_sales AS
SELECT
    fi.customer_key AS customer_key,
    fi.first_implement_purchase AS first_implement_purchase,
    COUNT(DISTINCT CASE
        WHEN se.product_group = 'PECAS'
         AND se.sale_date > fi.first_implement_purchase
        THEN se.sale_control
    END) AS parts_sales_after_implement,
    SUM(CASE
        WHEN se.product_group = 'PECAS'
         AND se.sale_date > fi.first_implement_purchase
        THEN se.revenue
        ELSE 0
    END) AS parts_revenue_after_implement
FROM vw_customer_first_implement_purchase AS fi
LEFT JOIN vw_sales_enriched AS se
    ON fi.customer_key = se.customer_key
   AND se.sale_date >= fi.first_implement_purchase
   AND se.sale_date < '2026-07-08'
GROUP BY
    fi.customer_key,
    fi.first_implement_purchase;
