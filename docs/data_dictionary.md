# Data Dictionary

This document describes the main analytical objects and fields used in
the Customer Intelligence project.

The analytical model combines data from the current ERP and the legacy
ERP while preserving source-system registration IDs and resolving
customers through a shared analytical identity layer.

**Documentation status:** Sections 1–7 preserve the original integration-stage
dictionary. Sections 8 onward describe the subsequent unified analytical
model and RFM v2 snapshot. Historical control totals are not interchangeable
with the unified snapshot totals. Fields listed as confirmed reflect previously
used analytical SQL; exact physical definitions should be checked with
`SHOW CREATE VIEW` / `DESCRIBE` before treating this as a complete schema inventory.

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


---

## 8. Unified Classified Sales Layer (Current Analytical Base)

### `vw_sales_unified_classified`

Unified, classified sale-item dataset combining both ERPs, including **products
and services**. This is the main transaction-level source for the current
customer analysis, superseding the original product-only scope.

**Grain:** one row per sale item, uniquely identified within its source system.
Do not assume `sale_item_id` or `sale_control` is globally unique across ERPs.

| Column | Description | Notes |
|---|---|---|
| customer_identity_id | Cross-ERP analytical customer ID | May be NULL for anonymous/unmatched items; bridge-derived |
| source_system | Source ERP | `LEGACY_ERP`, `CURRENT_ERP` |
| sale_item_id | Sale-item identifier | Interpret with `source_system` |
| sale_control | Sale/transaction control | Interpret with `source_system` |
| sale_date | Analytical sale date | Used for RFM and period filters |
| customer_registration_id | Operational registration ID | Interpret with `source_system` |
| item_type | Item category | `PRODUCT` or `SERVICE` |
| product_id | Product identifier | Source-system specific; legacy 0 denotes service |
| product_name | Product or service description | Source-dependent fallback logic |
| transaction_type | Movement classification | May include `SALE` and `RETURN`; returns require separate audit for RFM |
| quantity | Analytical quantity | Signed for recognized legacy returns |
| unit_sale_price | Item unit sale price | Not always sufficient to reproduce current service revenue |
| unit_cost | Recorded unit cost | Can be missing/unreliable |
| revenue | Analytical item revenue | Use this field for aggregation |
| profit | Known analytical item profit | NULL where cost is not reliable, notably services |
| analytical_product_group | Normalized commercial group | Examples: `PECAS`, `IMPLEMENTOS`, `SERVICOS` |
| classification_source | Origin of group classification | Values require schema inspection |
| classification_status | Classification validation status | Observed: `CONFIRMED`, `PENDING`, `REVIEW` |

**Validated unified snapshot:** 2018-01-02 through 2026-09-03;
291,024 sale-item rows; R$35,875,034.95 total revenue.

| Source and item type | Items | Revenue (R$) |
|---|---:|---:|
| Legacy ERP — products | 206,187 | 23,903,897.93 |
| Legacy ERP — services | 21,894 | 2,909,677.57 |
| Current ERP — products | 56,762 | 7,701,076.27 |
| Current ERP — services | 6,181 | 1,360,383.18 |
| **Total** | **291,024** | **35,875,034.95** |

**Identity coverage:** 3,109 identifiable customers generated
R$34,791,961.29 in unified item-level revenue. Another 28,838 anonymous
*items* generated R$1,083,073.66. Anonymous item counts are not customer
counts. Customer-profile totals can differ by a few cents from item-level
revenue because of rounding (observed difference: R$0.07).

### Classification validation

| Status | Items | Revenue (R$) |
|---|---:|---:|
| `CONFIRMED` | 289,227 | 35,451,971.33 |
| `PENDING` | 1,546 | 385,418.51 |
| `REVIEW` | 251 | 37,645.11 |

Pending/review items remain a data-quality issue; do not silently treat all
groups as fully validated. The `REVIEW` group includes material classified
as `MATERIA PRIMA` requiring investigation.

---

## 9. Classification and Integration Supporting Objects

| Object | Role | Notes |
|---|---|---|
| `vw_legacy_sales_classified` | Classified legacy sale items | Feeds unified sales layer |
| `dim_legacy_product_group_mapping` | Legacy group-to-analytical-group mapping | Mapping table; exact columns require inspection |
| `dim_legacy_product_override` | Product-specific legacy classification corrections | Override precedence should be verified from view SQL |
| `dim_product_group_override` | Current product-level classification corrections | Earlier imported override table; exact columns require inspection |
| `bridge_customer_registration` | Maps source registrations to analytical identities | See Section 3 |

The unified layer uses analytical product groups for comparisons across
systems. Source ERP product IDs and subgroup IDs are not cross-system
identifiers. The current ERP's completed-sale filter uses
`mv_vendas.em_aberto = 1` in the implemented extraction logic; the
operational meaning of that flag warrants independent verification.

Current-ERP service revenue is sourced from recorded total (`vr_total`)
where applicable rather than always multiplying quantity by unit price.
A previously identified service record with source date `1899-12-30`
was corrected analytically to `2025-12-17` (item ID 5141).
These are explicit transformation decisions, not generic ERP rules.

---

## 10. Historical Customer Profile

### `vw_customer_historical_profile`

**Grain:** one row per identifiable `customer_identity_id`.

The view summarizes the unified purchasing history, including customer
lifetime revenue, first and last purchase dates, and lifetime activity.
**Validated population:** 3,109 customers.

Previously confirmed concepts/fields used downstream include:

| Field / measure | Meaning |
|---|---|
| `customer_identity_id` | Unified customer key |
| `first_purchase_date` | First observed sale date in integrated history |
| `last_purchase_date` | Most recent observed sale date in integrated history |
| Lifetime revenue | Revenue accumulated over integrated history; exact view column name should be checked |
| Lifetime purchases | Distinct source-qualified transactions; exact view column name should be checked |

The historical customer-profile sum is approximately R$34.79m. A validated
profile-level total was R$34,791,961.22; it differs by R$0.07 from the
item-level identifiable-customer total because of rounding.

---

## 11. RFM v2 Base

### `vw_customer_rfm_base_v2`

**Grain:** one row per identifiable customer; includes inactive customers.
**Reference date:** `2026-09-03` (fixed snapshot).
**12-month window:** `2025-09-04` through `2026-09-03`, inclusive.

| Column | Description | Calculation / note |
|---|---|---|
| `customer_identity_id` | Unified customer identifier | One row per customer |
| `first_purchase_date` | First observed historical purchase | Integrated history |
| `last_purchase_date` | Last observed historical purchase | Integrated history |
| `recency_days` | Days since last observed purchase | Relative to fixed snapshot date |
| `total_purchases` | Lifetime distinct sales | Source-qualified transaction keys |
| `lifetime_revenue` | Lifetime customer revenue | Integrated history |
| `frequency_12m` | Distinct sales in 12-month window | `COUNT(DISTINCT CONCAT(source_system, ':', sale_control))` |
| `monetary_12m` | Customer revenue in 12-month window | Sum of analytical revenue |
| `profit_12m` | Known customer profit in 12-month window | May be NULL for service-only activity |

**Validation:** 3,109 customers; 1,406 with at least one transaction in the
12-month window; 1,703 without; total `monetary_12m` R$4,194,807.91.

**Important:** `recency_days <= 365` is not identical to activity in the
specified 12-month window: the cutoff includes 2025-09-03, while the
window begins on 2025-09-04. Also, `profit_12m` is *known* profit and
should not be described as complete economic profit.

---

## 12. RFM v2 Scores

### `vw_customer_rfm_scores_v2`

Builds on the RFM base. The following score columns have been confirmed
in downstream analysis:

| Column | Description |
|---|---|
| `r_score` | Recency score, integer 1–5 |
| `f_score` | Frequency score, integer 1–5 |
| `m_score` | Monetary score, integer 1–5 |

| Score | Recency (`recency_days`) | Frequency (`frequency_12m`) | Monetary (`monetary_12m`, R$) |
|---|---|---|---|
| 5 | 0–30 | 11+ | 25,000+ |
| 4 | 31–90 | 6–10 | 5,000–24,999.99 |
| 3 | 91–180 | 4–5 | 1,000–4,999.99 |
| 2 | 181–365 | 2–3 | 500–999.99 |
| 1 | >365 | 0–1 | <500 |

These are **v2 thresholds**, not the v1 thresholds retained in historical
project documentation. In the v2 validation, 1,700 customers had R1/F1/M1.

---

## 13. RFM-Based Customer Segments v2

### `vw_customer_segments_v2`

**Grain:** one row per identifiable customer, with one mutually exclusive
segment assigned by ordered `CASE` precedence.

| Priority | Segment | Condition (first matching rule wins) |
|---|---|---|
| 1 | `VIP` | R >= 4 AND F >= 4 AND M >= 4 |
| 2 | `Loyal Customers` | R >= 3 AND F >= 4 |
| 3 | `High-Value Occasional` | R >= 3 AND M >= 4 |
| 4 | `New Customers` | `first_purchase_date >= '2026-06-06'` |
| 5 | `Promising` | R >= 4 |
| 6 | `At Risk` | R = 2 AND (F >= 3 OR M >= 3) |
| 7 | `Active Occasional` | R >= 2 |
| 8 | `High-Value Lost` | R = 1 AND lifetime revenue >= R$50,000 |
| 9 | `Former Regular Customers` | R = 1 AND lifetime revenue >= R$10,000 |
| 10 | `Recently Inactive` | R = 1 AND recency <= 730 |
| 11 | `Long-Term Inactive` | Remaining customers |

The exact segment-output column name should be checked against the deployed
view definition before writing new downstream SQL. The segment labels and
precedence above reflect the implemented analytical rules.

| Segment | Customers | 12-month revenue (R$) |
|---|---:|---:|
| VIP | 120 | 2,314,759.87 |
| Loyal Customers | 303 | 825,249.29 |
| At Risk | 137 | 439,692.39 |
| High-Value Occasional | 19 | 281,269.99 |
| Active Occasional | 564 | 183,748.61 |
| Promising | 223 | 132,979.58 |
| New Customers | 43 | 17,108.18 |
| Recently Inactive | 437 | 0.00 |
| Long-Term Inactive | 1,040 | 0.00 |
| Former Regular Customers | 196 | 0.00 |
| High-Value Lost | 27 | 0.00 |
| **Total** | **3,109** | **4,194,807.91** |

**Interpretation caveats:** `At Risk` is a rule-based label, not a measured
probability of churn; implement buyers can have naturally long purchasing
cycles. `Former Regular Customers` is based on historical revenue, not
necessarily on frequent historical purchases. This RFM v2 segmentation
is distinct from the older `vw_customer_commercial_segment` v1 model.

---

## 14. Product Group Purchase Behavior (12-Month Snapshot)

Aggregations from `vw_sales_unified_classified` group customers and sale
items by `analytical_product_group` within the RFM v2 window.

| Product group | Distinct buyers | Revenue (R$) |
|---|---:|---:|
| `PECAS` | 1,286 | 1,756,883.24 |
| `IMPLEMENTOS` | 49 | 998,078.00 |
| `SERVICOS` | 611 | 603,880.40 |
| `DIVERSOS` | 661 | 296,829.08 |
| `OLEOS E LUBRIFICANTES` | 405 | 270,084.11 |
| `TRATORES` | 1 | 188,000.00 |

Additional smaller groups complete the 11-group snapshot. Group customer
counts **overlap**: one customer may buy multiple groups. Item-level
product-group revenue totals R$4,194,807.94, a R$0.03 rounding difference
from the customer RFM base.

### Observed implement / parts / services overlap

Among 49 identified customers who bought `IMPLEMENTOS` in the window:

- 37 also bought `PECAS` (75.51%).
- 28 also bought `SERVICOS` (57.14%).
- 27 bought both `PECAS` and `SERVICOS`.
- 10 bought `PECAS` but not `SERVICOS`.
- 1 bought `SERVICOS` but not `PECAS`.
- 11 bought neither `PECAS` nor `SERVICOS` in the window.

These are **co-purchase** measures; they do **not** establish that a parts
or services transaction occurred *after* an implement purchase. The earlier
Commercial Segments v1 after-sales analysis used different dates and
sequence-based criteria and must not be conflated with this result.

For the 11 implement buyers with no current-window parts/services purchases:
6 had purchased at least one of those groups historically; 5 had no
recorded historical purchases in either group. Among the 6, four had at
least four distinct historical parts transactions. These are possible
commercial-review candidates, not proven missed sales.

---

## 15. Data Quality, Interpretation and Verification Checklist

- **Returns:** Legacy returns are represented with signed amounts, but
  whether `transaction_type='RETURN'` should contribute to customer
  purchase frequency or last-purchase recency needs a separate audit.
- **Missing cost:** `profit` can be NULL for services and unreliable-cost
  products. `SUM(profit)` is known profit, not complete profit.
- **Anonymous activity:** Retain anonymous items for overall product and
  revenue reporting; exclude them from identified-customer RFM.
- **Identity matching:** Shared document-backed customer identity is
  analytical, not equivalent to source ERP registration ID.
- **Snapshot consistency:** Apply the same fixed date and 12-month window
  to RFM and co-purchase analysis. Historical v1 snapshots should remain
  explicitly labeled as such.
- **Classification:** Investigate `PENDING` and `REVIEW` items; preserve
  classification provenance.
- **Schema validation:** Confirm actual columns, data types, primary keys,
  indexes and view SQL in MariaDB before declaring this a physical schema
  specification. In particular, verify exact output column names of
  `vw_customer_historical_profile` and `vw_customer_segments_v2`.

### Suggested MariaDB / HeidiSQL verification commands

```sql
DESCRIBE vw_sales_unified_classified;
DESCRIBE vw_customer_historical_profile;
DESCRIBE vw_customer_rfm_base_v2;
DESCRIBE vw_customer_rfm_scores_v2;
DESCRIBE vw_customer_segments_v2;
SHOW CREATE VIEW vw_customer_segments_v2;
```

**Documentation convention:** Retain historical models as versioned
artifacts. The RFM v2 snapshot is the current customer-analysis reference;
the original Sections 1–7 remain as source and migration documentation.
