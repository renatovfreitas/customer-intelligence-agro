Customer identity integration — SQL execution guide
These scripts document the original supplied SQL for identity consolidation across the current and legacy ERPs. The file numbering is a suggested first-time population sequence, not proof that the database was originally populated in this exact order.
Suggested order
1. 01_create_bridge_customer_registration.sql and 02_create_dim_customer_identity.sql: table definitions already documented. Create the identity dimension before populating it, and create the bridge before its inserts. The numeric names of the two DDL files are not the exact execution order.
2. 03_insert_current_customer_identities.sql: load hashes from vw_current_customer_identity.
3. 04_insert_current_customer_bridge.sql: link current ERP registrations using normalized-document SHA-256 hashes.
4. 05_insert_legacy_only_customer_identities.sql: add hashes not already in the dimension.
5. 06_insert_legacy_customer_bridge.sql: link legacy registrations.
Upstream dependencies
- vw_current_customer_identity
- vw_current_customers
- stg_legacy_customer_identity
The SQL defining these upstream objects and the legacy hash-generation process still need to be documented. The current bridge uses UPPER(SHA2(c.cpf_cnpj_normalized, 256)) and ascii_bin; matching hash casing and document normalization across systems is essential.
Cautions
- Do not rerun the INSERT scripts on populated production tables: primary/unique keys may reject duplicates. A repeatable migration requires additional safeguards and validation.
- The supplied legacy-only insertion does not filter NULL hashes; validate staging input against the destination's NOT NULL constraint.
- MyISAM does not enforce foreign keys or transactions; validate referential integrity with queries.
- No real CPF/CNPJ, hashes, credentials, or customer-level data should be committed to the public repository.
- The alternate uploaded bridge_customer_registration.sql DDL is not included because the database's SHOW CREATE TABLE is the canonical schema.
