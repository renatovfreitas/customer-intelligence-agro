-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: Customer identity integration
-- Purpose: Store one consolidated customer identity per unique document hash.
-- Dependencies: None for table creation.
-- Note: The hash-generation and population process is not defined here.
-- Security: Do not commit actual document hashes or customer records.
-- Source: Existing MariaDB table DDL (environment-specific AUTO_INCREMENT=5592 omitted).

CREATE TABLE `dim_customer_identity` (
    `customer_identity_id` INT(11) NOT NULL AUTO_INCREMENT,
    `document_hash` CHAR(64)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    PRIMARY KEY (`customer_identity_id`),
    UNIQUE KEY `uk_customer_identity_document` (`document_hash`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
