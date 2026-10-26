-- Project: Customer Intelligence for Agricultural Machinery Retail
-- Layer: 02_data_integration
-- Purpose: Normalize current ERP customer registration documents and expose
--          customer registration attributes for downstream identity matching.
-- Source table: cad_clientes
-- Output view: vw_current_customers
-- Dependencies: cad_clientes
-- Note: Length checks do not validate CPF/CNPJ check digits.
-- Privacy: This view exposes personal data. Do not export its rows to GitHub.
-- Compatibility: MariaDB 5.5

CREATE OR REPLACE VIEW vw_current_customers AS
SELECT
    c.id AS customer_registration_id,
    c.nome_cliente AS customer_name,
    c.cpf_cnpj AS cpf_cnpj_original,
    CASE
        WHEN CHAR_LENGTH(
            REPLACE(REPLACE(REPLACE(REPLACE(TRIM(c.cpf_cnpj), '.', ''), '/', ''), '-', ''), ' ', '')
        ) IN (11, 14)
        THEN REPLACE(REPLACE(REPLACE(REPLACE(TRIM(c.cpf_cnpj), '.', ''), '/', ''), '-', ''), ' ', '')
        ELSE NULL
    END AS cpf_cnpj_normalized,
    CASE
        WHEN CHAR_LENGTH(
            REPLACE(REPLACE(REPLACE(REPLACE(TRIM(c.cpf_cnpj), '.', ''), '/', ''), '-', ''), ' ', '')
        ) = 11 THEN 'CPF'
        WHEN CHAR_LENGTH(
            REPLACE(REPLACE(REPLACE(REPLACE(TRIM(c.cpf_cnpj), '.', ''), '/', ''), '-', ''), ' ', '')
        ) = 14 THEN 'CNPJ'
        ELSE NULL
    END AS document_type,
    c.cidade AS city,
    c.uf AS state,
    c.telefone AS phone,
    c.celular AS mobile_phone,
    c.email AS email
FROM cad_clientes AS c;
