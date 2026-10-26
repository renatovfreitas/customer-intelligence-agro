-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Purpose: Insert current-ERP identity hashes
-- Dependencies: vw_current_customer_identity
-- Source: Original user-provided SQL (logic unchanged)
-- CAUTION: INSERT statements are intended for initial population;
--          do not rerun blindly on populated tables (duplicate key risk).

INSERT INTO dim_customer_identity (document_hash)
SELECT document_hash
FROM vw_current_customer_identity;
