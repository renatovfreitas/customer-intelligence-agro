-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Link current ERP registrations to unified identities
-- Dependencies: vw_current_customers, dim_customer_identity
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
    'CURRENT_ERP',
    c.customer_registration_id
FROM vw_current_customers c

INNER JOIN dim_customer_identity d
    ON d.document_hash =
       CAST(
           UPPER(SHA2(c.cpf_cnpj_normalized, 256))
           AS CHAR(64) CHARACTER SET ascii
       ) COLLATE ascii_bin

WHERE c.cpf_cnpj_normalized IS NOT NULL;
