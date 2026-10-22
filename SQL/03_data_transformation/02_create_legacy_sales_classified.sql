-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Classify historical ERP sales and services into analytical product groups.
-- Output: vw_legacy_sales_classified
-- Dependencies:
--   vw_legacy_sales_integrated
--   dim_legacy_product_override
--   dim_legacy_product_group_mapping
-- Classification precedence: SERVICE > product override > group mapping > unclassified.
-- Exclusion: legacy sale_control 104340 on 2024-07-15 (migration-control exclusion).
-- Note: Original DEFINER and SQL SECURITY DEFINER removed for portability.

CREATE OR REPLACE VIEW vw_legacy_sales_classified AS
SELECT
    l.customer_identity_id,
    l.sale_item_id,
    l.sale_control,
    l.sale_date,
    l.customer_registration_id,
    l.customer_name,
    l.item_type,
    l.product_id,
    l.product_name,
    l.product_master_missing,
    l.legacy_product_group_id,
    l.legacy_product_group,
    l.transaction_type,
    l.quantity,
    l.unit_sale_price,
    l.unit_cost,
    l.revenue,
    l.profit,
    l.movement_type,
    l.source_user,
    l.source_system,
    CASE
        WHEN l.item_type = 'SERVICE' THEN 'SERVICOS'
        WHEN o.product_group IS NOT NULL THEN o.product_group
        WHEN m.product_group IS NOT NULL THEN m.product_group
        ELSE 'NAO CLASSIFICADO'
    END AS analytical_product_group,
    CASE
        WHEN l.item_type = 'SERVICE' THEN 'ITEM_TYPE'
        WHEN o.product_group IS NOT NULL THEN 'PRODUCT_OVERRIDE'
        WHEN m.product_group IS NOT NULL THEN 'GROUP_MAPPING'
        ELSE 'UNCLASSIFIED'
    END AS classification_source,
    CASE
        WHEN l.item_type = 'SERVICE' THEN 'CONFIRMED'
        WHEN o.product_group IS NOT NULL THEN 'CONFIRMED'
        WHEN m.product_group IS NOT NULL THEN m.mapping_status
        ELSE 'PENDING'
    END AS classification_status
FROM vw_legacy_sales_integrated AS l
LEFT JOIN dim_legacy_product_override AS o
    ON l.product_id = o.product_id
   AND l.item_type = 'PRODUCT'
LEFT JOIN dim_legacy_product_group_mapping AS m
    ON l.legacy_product_group_id = m.legacy_product_group_id
WHERE l.sale_date <> '2024-07-15'
   OR l.sale_control <> 104340;
