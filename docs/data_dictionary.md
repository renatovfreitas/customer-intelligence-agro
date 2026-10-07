# Data Dictionary

This document describes the main analytical objects and fields used in
the Customer Intelligence project.

The analytical model combines data from the current ERP and the legacy
ERP while preserving source-system registration IDs and resolving
customers through a shared analytical identity layer.

---

## 1. Current Sales Layer

### `vw_sales_enriched`

Analytical sales view from the current ERP.

**Grain:** one row per sale item.

| Column | Description | Notes |
|---|---|---|
| sale_item_id | Unique identifier of the sale item | Source-system item ID |
| sale_control | Sale transaction identifier | Multiple items may belong to the same sale |
| sale_date | Date of the sale | Used for temporal analysis |
| customer_registration_id | Customer registration ID in the current ERP | Operational ID; not treated as unique customer identity |
| customer_name | Customer name | Source-system customer name |
| cpf_cnpj | Customer CPF/CNPJ | Sensitive source identifier |
| cpf_cnpj_normalized | Normalized CPF/CNPJ | Used for customer identity resolution |
| customer_key | Existing analytical customer key | Based on current-model customer rules |
| product_id | Product identifier | Current ERP product ID |
| product_name | Product description | Product master description |
| product_subgroup_id | Product subgroup identifier | Source ERP classification |
| product_subgroup | Product subgroup description | More granular than analytical product group |
| product_group_id | Analytical product group identifier | Derived from default mapping and product-level overrides |
| product_group | Analytical macro product group | Examples: PEÇAS, IMPLEMENTOS, TRATORES |
| quantity | Quantity sold | Item-level measure |
| unit_sale_price | Unit selling price | Used in revenue calculation |
| unit_cost | Unit historical cost | Used in profit calculation |
| revenue | Item revenue | Analytical revenue measure |
| profit | Item profit | Analytical profit measure |

---

## 2. Current Customer Layer

### `vw_current_customers`

Normalized customer-registration view from the current ERP.

**Grain:** one row per current ERP customer registration.

| Column | Description | Notes |
|---|---|---|
| customer_registration_id | Customer registration ID | `cad_clientes.id` |
| customer_name | Customer name | Source-system value |
| cpf_cnpj_original | Original CPF/CNPJ value | May contain formatting |
| cpf_cnpj_normalized | CPF/CNPJ after formatting removal and structural validation | Accepts 11-digit CPF or 14-digit CNPJ |
| document_type | Document type | CPF, CNPJ or NULL |
| city | Customer city | Supporting identity attribute |
| state | Customer state | Supporting identity attribute |
| phone | Customer phone | Supporting identity attribute |
| mobile_phone | Customer mobile phone | Supporting identity attribute |
| email | Customer email | Supporting identity attribute |

Structural document validation checks format/length only and does not
validate CPF/CNPJ check digits.

---

## 3. Customer Identity Layer

### `dim_customer_identity`

Cross-system analytical customer identity dimension.

**Grain:** one row per distinct document-backed customer identity.

| Column | Description | Notes |
|---|---|---|
| customer_identity_id | Analytical customer identity ID | Surrogate primary key |
| document_hash | SHA-256 hash of normalized CPF/CNPJ | Used for deterministic cross-system matching |

The document hash is used as an integration identifier. ERP customer
registration IDs are not assumed to uniquely identify customers.

### `bridge_customer_registration`

Maps operational customer registrations from each ERP to the shared
analytical customer identity.

**Grain:** one row per source-system customer registration.

| Column | Description | Notes |
|---|---|---|
| customer_identity_id | Analytical customer identity ID | References `dim_customer_identity` |
| source_system | ERP from which the registration originates | `CURRENT_ERP` or `LEGACY_ERP` |
| customer_registration_id | Customer registration ID within the source ERP | Unique together with `source_system` |

Multiple ERP registration IDs may map to the same
`customer_identity_id`.

---

## 4. Legacy Customer Layer

### `vw_legacy_customers`

Normalized customer-registration view from the legacy ERP.

**Grain:** one row per legacy customer registration.

| Column | Description | Notes |
|---|---|---|
| customer_registration_id | Legacy customer registration ID | `CLIENTES.CODIGO` |
| customer_name | Customer name | Legacy master value |
| cpf | Original CPF | NULL when unavailable |
| cnpj | Original CNPJ | NULL when unavailable |
| cpf_cnpj_normalized | Structurally valid normalized document | Used for identity matching |
| document_type | Document type | CPF, CNPJ or NULL |
| city | Customer city | Supporting identity attribute |
| state | Customer state | Supporting identity attribute |
| phone | Customer phone | Supporting identity attribute |
| mobile_phone | Customer mobile phone | Supporting identity attribute |
| email | Customer email | Supporting identity attribute |

---

## 5. Legacy Identity Staging

### `stg_legacy_customer_identity`

Temporary integration table containing privacy-preserving identifiers
exported from the legacy ERP.

**Grain:** one row per legacy customer registration with a structurally
valid document.

| Column | Description | Notes |
|---|---|---|
| legacy_customer_registration_id | Customer registration ID from legacy ERP | Used to map legacy transactions |
| document_hash | SHA-256 hash of normalized CPF/CNPJ | Used for cross-system identity matching |

Plaintext CPF/CNPJ is not transferred through this staging process.

---

## 6. Legacy Sales Layer

### `vw_legacy_sales_enriched`

Validated analytical sales view from the legacy ERP.

**Grain:** one row per legacy sale item.

**Validated period:** 2018-01-02 to 2024-07-15.

| Column | Description | Notes |
|---|---|---|
| sale_item_id | Legacy sale-item identifier | `VENDAS_ITENS.CONTROLE` |
| sale_control | Legacy sale transaction identifier | `VENDAS.CTRVENDA` |
| sale_date | Sale date | Legacy transaction date |
| customer_registration_id | Legacy customer registration ID | Operational ID; resolved through identity bridge where possible |
| customer_name | Legacy customer name | May be NULL when customer master no longer exists |
| cpf | Customer CPF | Source master value |
| cnpj | Customer CNPJ | Source master value |
| cpf_cnpj | Available CPF or CNPJ | Used during legacy identity preparation |
| item_type | Analytical item type | `SERVICE` when product ID = 0; otherwise `PRODUCT` |
| product_id | Legacy product identifier | Product 0 represents legacy service entries |
| product_name | Product or service description | Service descriptions come from sale-item free text |
| product_master_missing | Missing-product-master flag | 1 when a product item no longer exists in product master |
| legacy_product_group_id | Original legacy product group ID | Source-system classification |
| legacy_product_group | Original legacy product group description | Not yet equivalent to current analytical product groups |
| transaction_type | SALE or RETURN | Returns identified using validated legacy rule |
| quantity | Signed analytical quantity | Negative for identified returns |
| unit_sale_price | Historical unit selling price | `PRVENDIDO` |
| unit_cost | Historical unit cost | `CUSTOA` |
| revenue | Signed item revenue | Quantity × unit sale price, with returns negative |
| profit | Known item profit | NULL where historical cost is unavailable/unreliable |
| movement_type | Legacy movement type | Original `VENDAS_ITENS.TV` value |
| source_user | Legacy ERP user | Used in return identification |
| source_system | Source ERP | `LEGACY_ERP` |

`SUM(profit)` from this view represents known historical profit rather
than guaranteed complete historical profit.

---

## 7. Legacy Migration Control Totals

The following values were recorded before transferring legacy sales to
the integrated MariaDB layer and should be used for migration
reconciliation.

| Metric | Expected value |
|---|---:|
| Sale-item rows | 228,083 |
| Distinct sales | 90,815 |
| First sale date | 2018-01-02 |
| Last sale date | 2024-07-15 |
| Revenue | R$ 26,813,612.493 |
| Known profit | R$ 7,701,172.490 |

These values should remain unchanged after staging unless an explicitly
documented transformation requires otherwise.
