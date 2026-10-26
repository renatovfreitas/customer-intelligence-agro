-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: Customer identity integration
-- Purpose: Generate a distinct SHA-256 document hash for each normalized
--          CPF/CNPJ and count source ERP registrations per hash.
-- Depends on: vw_current_customers (cpf_cnpj_normalized)
-- Output: vw_current_customer_identity
-- Compatibility: MySQL / MariaDB (validate against target server)
-- Security: No customer document values are stored in this script.
-- Note: Omitted environment-specific DEFINER and SQL SECURITY DEFINER.

CREATE OR REPLACE VIEW vw_current_customer_identity AS
SELECT
    CAST(
        UPPER(SHA2(c.cpf_cnpj_normalized, 256))
        AS CHAR(64) CHARACTER SET ascii
    ) COLLATE ascii_bin AS document_hash,
    COUNT(*) AS current_registration_count
FROM vw_current_customers AS c
WHERE c.cpf_cnpj_normalized IS NOT NULL
GROUP BY
    CAST(
        UPPER(SHA2(c.cpf_cnpj_normalized, 256))
        AS CHAR(64) CHARACTER SET ascii
    ) COLLATE ascii_bin;
