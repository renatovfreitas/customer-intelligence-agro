# Legacy customer identity staging — import notes

## Source and scope

The original private import file contained 2,478 `(legacy_customer_registration_id, document_hash)` pairs. A comment in that file states that thousands separators were removed from legacy IDs (e.g., `1.007` became `1007`). The file does not show the upstream extraction or hash-generation process.

## Original loading behavior

The original script first executed `TRUNCATE TABLE stg_legacy_customer_identity`, then inserted the 2,478 explicit pairs, and finally ran a validation query checking row count, distinct registration IDs, distinct document hashes, and hash lengths. This is a destructive full replacement, not an incremental upsert. Do not execute it against a populated database without an approved backup and recovery plan.

## Schema evolution

A separate historical `ALTER TABLE` script set `document_hash` to `CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL`. The current `CREATE TABLE` definition already includes this specification, so the ALTER is not needed when creating the table from the current DDL.

## Public repository policy

Do not commit the original import SQL, its actual hash values, customer registration IDs, plaintext CPF/CNPJ, or extracts derived from them. Keep the original file in a restricted, private location. This public documentation and the companion read-only validation query contain no customer records.

## Remaining reproducibility gap

The legacy ERP extraction, CPF/CNPJ normalization, SHA-256 generation, and transfer procedure are not documented by the two supplied files. They must be documented from the actual process rather than inferred.
