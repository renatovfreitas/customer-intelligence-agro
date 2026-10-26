-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Object: bridge_customer_registration
-- Type: Physical table
-- Purpose: Map ERP-specific customer registration IDs to consolidated customer identities.
-- Dependencies: customer_identity_id values must be generated and mapped by a separate identity-resolution process.
-- Note: This DDL creates an EMPTY table; it does not populate customer mappings.
-- Source: Existing MariaDB schema (MyISAM, latin1).

CREATE TABLE `bridge_customer_registration` (
    `customer_identity_id` INT(11) NOT NULL,
    `source_system` VARCHAR(20) NOT NULL,
    `customer_registration_id` INT(11) NOT NULL,
    PRIMARY KEY (`source_system`, `customer_registration_id`),
    KEY `idx_bridge_identity` (`customer_identity_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
