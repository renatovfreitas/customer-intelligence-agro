-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Insert legacy hashes not already in the identity dimension
-- Dependencies: stg_legacy_customer_identity, dim_customer_identity
-- Source: Original user-provided SQL (logic unchanged)
-- CAUTION: INSERT statements are intended for initial population;
--          do not rerun blindly on populated tables (duplicate key risk).

INSERT INTO dim_customer_identity (document_hash)

SELECT DISTINCT
    l.document_hash

FROM stg_legacy_customer_identity l

LEFT JOIN dim_customer_identity d
    ON l.document_hash = d.document_hash

WHERE d.customer_identity_id IS NULL;
