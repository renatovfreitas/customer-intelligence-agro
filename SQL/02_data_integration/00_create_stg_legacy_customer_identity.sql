-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: Customer identity integration / legacy staging
-- Purpose: Store hashed legacy customer documents by legacy registration ID.
-- Source: Original SHOW CREATE TABLE statement (schema preserved).
-- Dependencies: None for table creation; population logic is separate.
-- Note: No raw CPF/CNPJ values should be committed to this repository.

CREATE TABLE `stg_legacy_customer_identity` (
    `legacy_customer_registration_id` INT(11) NOT NULL,
    `document_hash` CHAR(64)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    PRIMARY KEY (`legacy_customer_registration_id`),
    KEY `idx_legacy_document_hash` (`document_hash`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
