-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Validate the legacy customer identity staging table after a private import.
-- Dependencies: stg_legacy_customer_identity
-- Read-only: does not modify data.
-- Note: This checks hash length, not document validity or matching correctness.

SELECT
    COUNT(*) AS total,
    COUNT(DISTINCT legacy_customer_registration_id) AS distinct_ids,
    COUNT(DISTINCT document_hash) AS distinct_documents,
    SUM(CHAR_LENGTH(document_hash) <> 64) AS invalid_hash_length
FROM stg_legacy_customer_identity;
