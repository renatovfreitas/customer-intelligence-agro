-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Link legacy ERP registrations to unified identities
-- Dependencies: stg_legacy_customer_identity, dim_customer_identity
-- Source: Original user-provided SQL (logic unchanged)
-- CAUTION: INSERT statements are intended for initial population;
--          do not rerun blindly on populated tables (duplicate key risk).

INSERT INTO bridge_customer_registration (
    customer_identity_id,
    source_system,
    customer_registration_id
)
SELECT
    d.customer_identity_id,
    'LEGACY_ERP',
    l.legacy_customer_registration_id

FROM stg_legacy_customer_identity l

INNER JOIN dim_customer_identity d
    ON l.document_hash = d.document_hash;
