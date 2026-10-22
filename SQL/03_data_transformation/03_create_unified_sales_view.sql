-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Object: vw_sales_unified_classified
-- Purpose: Combine classified legacy ERP sales, current ERP product sales,
--          and current ERP service sales into one item-level analytical view.
-- Database: MariaDB 5.5-compatible SQL
-- Dependencies:
--   vw_legacy_sales_classified
--   vw_sales_enriched
--   vw_current_services_enriched
--   bridge_customer_registration
-- Grain: One row per sale item per source system.
-- Note: UNION ALL retains all source rows. Identity mapping uses LEFT JOIN,
--       so unmatched registrations retain NULL customer_identity_id.
-- Note: The source-specific DEFINER was intentionally omitted for portability.

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vw_sales_unified_classified AS
SELECT
    l.customer_identity_id AS customer_identity_id,
    'LEGACY_ERP' AS source_system,
    l.sale_item_id AS sale_item_id,
    l.sale_control AS sale_control,
    l.sale_date AS sale_date,
    l.customer_registration_id AS customer_registration_id,
    l.item_type AS item_type,
    l.product_id AS product_id,
    l.product_name AS product_name,
    l.transaction_type AS transaction_type,
    l.quantity AS quantity,
    l.unit_sale_price AS unit_sale_price,
    l.unit_cost AS unit_cost,
    l.revenue AS revenue,
    l.profit AS profit,
    l.analytical_product_group AS analytical_product_group,
    l.classification_source AS classification_source,
    l.classification_status AS classification_status
FROM vw_legacy_sales_classified AS l

UNION ALL

SELECT
    b.customer_identity_id AS customer_identity_id,
    'CURRENT_ERP' AS source_system,
    s.sale_item_id AS sale_item_id,
    s.sale_control AS sale_control,
    s.sale_date AS sale_date,
    s.customer_registration_id AS customer_registration_id,
    'PRODUCT' AS item_type,
    s.product_id AS product_id,
    s.product_name AS product_name,
    'SALE' AS transaction_type,
    s.quantity AS quantity,
    s.unit_sale_price AS unit_sale_price,
    s.unit_cost AS unit_cost,
    s.revenue AS revenue,
    s.profit AS profit,
    COALESCE(s.product_group, 'NAO CLASSIFICADO') AS analytical_product_group,
    'CURRENT_ERP_GROUP' AS classification_source,
    CASE
        WHEN s.product_group IS NULL
          OR s.product_group = 'NAO CLASSIFICADO'
        THEN 'PENDING'
        ELSE 'CONFIRMED'
    END AS classification_status
FROM vw_sales_enriched AS s
LEFT JOIN bridge_customer_registration AS b
    ON b.source_system = 'CURRENT_ERP'
   AND b.customer_registration_id = s.customer_registration_id

UNION ALL

SELECT
    b.customer_identity_id AS customer_identity_id,
    'CURRENT_ERP' AS source_system,
    s.sale_item_id AS sale_item_id,
    s.sale_control AS sale_control,
    s.sale_date AS sale_date,
    s.customer_registration_id AS customer_registration_id,
    s.item_type AS item_type,
    s.product_id AS product_id,
    s.service_description AS product_name,
    s.transaction_type AS transaction_type,
    s.quantity AS quantity,
    s.unit_sale_price AS unit_sale_price,
    s.unit_cost AS unit_cost,
    s.revenue AS revenue,
    s.profit AS profit,
    'SERVICOS' AS analytical_product_group,
    'ITEM_TYPE' AS classification_source,
    'CONFIRMED' AS classification_status
FROM vw_current_services_enriched AS s
LEFT JOIN bridge_customer_registration AS b
    ON b.source_system = 'CURRENT_ERP'
   AND b.customer_registration_id = s.customer_registration_id;
