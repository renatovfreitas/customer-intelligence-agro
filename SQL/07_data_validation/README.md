# Data Validation — Customer Intelligence

## Overview

This module validates the integrity, consistency, and reliability of the analytical datasets developed for the **Customer Intelligence — Agricultural Retail** project.

The project integrates historical transactions from a legacy Firebird ERP with data from a current ERP, consolidating customer identities, sales transactions, product classifications, RFM segmentation, and commercial cross-selling opportunities.

The validation framework ensures that analytical outputs can be reconciled with their underlying sources and that known data limitations are explicitly documented.

The validation process covers five areas:

1. Customer segmentation integrity
2. RFM financial reconciliation
3. Customer identity uniqueness
4. Sales and financial integrity
5. Cross-sell opportunity consistency

All validation scripts are written in SQL and designed for execution in MariaDB using HeidiSQL.

---

## 1. Validation Scope

| Component | Description |
|---|---|
| Legacy ERP | Historical Firebird sales data |
| Current ERP | Current sales and customer data |
| Unified sales | `vw_sales_unified_classified` |
| Customer master | `vw_customer_master` |
| RFM base | `vw_customer_rfm_base_v2` |
| RFM scores | `vw_customer_rfm_scores_v2` |
| Customer segments | `vw_customer_segments_v2` |
| Commercial analysis | Implement, parts, and services cross-selling |

### Analysis Periods

**Historical dataset**

- Start: January 1, 2018
- Latest recorded transaction: September 3, 2026

**RFM and commercial analysis**

- Start: September 4, 2025
- End: September 3, 2026
- Reference date: September 3, 2026

The commercial analysis uses a fixed 12-month observation window to ensure reproducibility.

---

## 2. Repository Structure

```text
07_data_validation/
│
├── 01_validate_customer_segments.sql
├── 02_validate_rfm_reconciliation.sql
├── 03_validate_customer_uniqueness.sql
├── 04_validate_sales_integrity.sql
├── 05_validate_cross_sell_consistency.sql
│
└── README.md
```

Each script addresses a specific validation objective and can be executed independently, provided that the required upstream tables and views have already been created.

---

## 3. Validation Summary

| # | Validation | Status |
|---|---|---|
| 01 | Customer Segments | PASS |
| 02 | RFM Reconciliation | PASS |
| 03 | Customer Uniqueness | PASS |
| 04 | Sales Integrity | PASS WITH WARNINGS |
| 05 | Cross-Sell Consistency | PASS |

**Overall assessment: PASS WITH DOCUMENTED LIMITATIONS**

The analytical datasets passed the principal reconciliation and consistency checks. Remaining issues are documented and should be considered when interpreting customer-level profitability and financial results.

---

## 4. Validation 01 — Customer Segments

**File:** `01_validate_customer_segments.sql`

### Objective

Verify the distribution of customers across RFM-based commercial segments and calculate the associated revenue contribution.

### Source

`vw_customer_segments_v2`

### Validation Approach

Customers are grouped by `customer_segment`, producing:

- Customer count per segment
- Total monetary value over the 12-month analysis period
- Segment-level revenue distribution

### Outcome

The query produced the customer segmentation summary used for subsequent commercial analysis.

The reconciliation of customer counts and revenue totals is independently verified in Validation 02.

**Status: PASS**

---

## 5. Validation 02 — RFM Reconciliation

**File:** `02_validate_rfm_reconciliation.sql`

### Objective

Confirm that the RFM segmentation process preserves the customer population and monetary values from the RFM base.

### Sources

- `vw_customer_rfm_base_v2`
- `vw_customer_segments_v2`

### Validated Results

| Metric | Result |
|---|---:|
| Total customers | 3,109 |
| Active customers (12 months) | 1,406 |
| Inactive customers (12 months) | 1,703 |
| Total monetary value (12 months) | R$ 4,194,807.91 |

### Validation Rules

The following values must reconcile between the base and segmented datasets:

- Total customer count
- Total `monetary_12m`

The reconciliation returned matching results.

**Status: PASS**

---

## 6. Validation 03 — Customer Uniqueness

**File:** `03_validate_customer_uniqueness.sql`

### Objective

Ensure that each consolidated customer identity appears only once in the customer-level RFM datasets.

### Sources

- `vw_customer_rfm_base_v2`
- `vw_customer_rfm_scores_v2`
- `vw_customer_segments_v2`

### Validation Rules

For each view:

- `customer_identity_id` must not be NULL.
- The number of rows must equal the number of distinct customer identities.
- Duplicate customer rows must not exist.

### Results

| Dataset | Result |
|---|---|
| RFM Base | PASS |
| RFM Scores | PASS |
| Customer Segments | PASS |

All three customer-level views passed the uniqueness validation.

**Status: PASS**

---

## 7. Validation 04 — Sales Integrity

**File:** `04_validate_sales_integrity.sql`

### Objective

Assess the structural and financial integrity of the unified sales dataset, including identifiers, dates, quantities, costs, revenues, profits, and transaction classifications.

### Source

`vw_sales_unified_classified`

### Dataset Overview

| Source | Sales item records |
|---|---:|
| Legacy ERP | 228,081 |
| Current ERP | 62,943 |
| **Total** | **291,024** |

### Structural Integrity Results

| Validation | Result | Status |
|---|---:|---|
| Missing source system, sale control, or sale item ID | 0 | PASS |
| Missing or malformed sale dates | 0 | PASS |
| NULL or zero quantities | 0 | PASS |
| Missing unit sale prices | 0 | PASS |
| Missing analytical product groups | 0 | PASS |
| Duplicate composite transaction keys | 0 | PASS |
| Missing customer identities | 28,838 | WARN |
| Negative quantities | 4,393 | EXPECTED |

The composite transaction key was evaluated using:

`source_system + sale_control + sale_item_id`

No duplicate combinations were found in the validated dataset.

### 7.1 Customer Identity Completeness

A total of 28,838 transaction records have no consolidated `customer_identity_id`.

| Source | Missing customer identities |
|---|---:|
| Legacy ERP | 28,451 |
| Current ERP | 387 |
| **Total** | **28,838** |

These records remain in the unified transactional dataset but cannot be reliably assigned to a consolidated customer identity.

Consequently, customer-level aggregations may exclude transactions that remain present in overall sales totals.

**Status: WARN**

### 7.2 Return Transaction Consistency

The legacy Firebird extraction applies negative signs to qualifying return transactions.

A dedicated validation confirmed that sales and returns follow the expected quantity sign convention.

| Metric | SALE | RETURN |
|---|---:|---:|
| Total records | 223,688 | 4,393 |
| Positive quantities | 223,688 | 0 |
| Negative quantities | 0 | 4,393 |
| Zero or NULL quantities | 0 | 0 |

All 4,393 negative-quantity records were classified as returns.

No inconsistencies were detected between transaction classification and quantity sign.

**Status: PASS**

### 7.3 Missing Profit — Legacy ERP

The legacy ERP contains 28,243 transaction records with missing profit values.

Investigation of the original Firebird extraction view, `vw_legacy_sales_enriched`, identified explicit business rules governing profit calculations.

The extraction applies the following logic:

- Service transactions (`vi.produto = 0`) receive `profit = NULL`.
- Transactions with movement type `SV` and zero unit cost receive `profit = NULL`.
- Qualifying returns reverse the sign of calculated profit.
- Other transactions calculate profit using the difference between unit sale price and unit cost, multiplied by quantity.

The observed distribution is:

| Transaction category | Missing profit |
|---|---:|
| Service sales | 21,881 |
| Service returns | 13 |
| Product sales | 6,349 |
| Product returns | 0 |
| **Total** | **28,243** |

The investigation traced these NULL values through the legacy extraction, raw staging, integrated staging, and analytical views.

These records represent documented financial limitations rather than unexpected errors introduced by the integration process.

Missing profit must not automatically be replaced with zero or recalculated using an assumed zero cost.

**Status: DOCUMENTED LIMITATION**

### 7.4 Missing Cost and Profit — Current ERP

The current ERP contains 6,181 records where both `unit_cost` and `profit` are NULL.

No records were identified where only one of these two fields was missing.

The underlying cause has not yet been established.

These records should remain excluded from calculations requiring known cost and profit values, while remaining available for other applicable analyses.

**Status: WARN**

### 7.5 Revenue Calculation Exceptions

Four current ERP service transactions do not reconcile with the standard formula:

`revenue = quantity * unit_sale_price`

All four share the following characteristics:

- Product ID: `922080`
- Item type: `SERVICE`
- Transaction type: `SALE`
- Quantity: `1`
- Unit sale price: `250`

Recorded revenue values are:

| Revenue | Expected revenue | Difference |
|---:|---:|---:|
| R$ 10 | R$ 250 | -R$ 240 |
| R$ 50 | R$ 250 | -R$ 200 |
| R$ 60 | R$ 250 | -R$ 190 |
| R$ 90 | R$ 250 | -R$ 160 |
| **R$ 210** | **R$ 1,000** | **-R$ 790** |

Possible explanations include adjustments, discounts, or ERP-specific pricing rules. None has been confirmed.

The original recorded values have been preserved.

**Status: WARN**

### 7.6 Profit Calculation Consistency

For records with the required financial components available, the profit reconciliation identified no mismatches.

This supports the internal consistency of profit calculations for the comparable subset of transactions.

**Status: PASS**

### Sales Integrity Conclusion

The unified sales dataset passed the structural integrity and transaction-sign consistency checks.

Financial limitations remain associated with missing cost and profit information, incomplete customer identities, and four unresolved revenue exceptions.

**Overall status: PASS WITH WARNINGS**

---

## 8. Validation 05 — Cross-Sell Consistency

**File:** `05_validate_cross_sell_consistency.sql`

### Objective

Validate the consistency of implement customer classification, cross-selling opportunity identification, commercial priority assignment, transaction filtering, and customer identity matching.

### Sources

- `vw_sales_unified_classified`
- `vw_customer_segments_v2`

### 8.1 Implement Customer Classification

The analysis identified 49 customers who purchased implements during the observation period.

| Purchase behavior | Customers |
|---|---:|
| Parts and services | 27 |
| Parts only | 10 |
| Services only | 1 |
| Neither parts nor services | 11 |
| **Total** | **49** |

The four groups are mutually exclusive and reconcile to the total implement customer population.

**Status: PASS**

### 8.2 Cross-Sell Opportunity Reconciliation

Customers with no observed purchases in one or both complementary categories were classified as potential cross-selling candidates.

| Opportunity type | Customers |
|---|---:|
| `PARTS_AND_SERVICES_OPPORTUNITY` | 11 |
| `SERVICES_OPPORTUNITY` | 10 |
| `PARTS_OPPORTUNITY` | 1 |
| **Total opportunities** | **22** |

The remaining 27 implement buyers purchased both parts and services during the observation period.

**Status: PASS**

### 8.3 Commercial Priority Reconciliation

Opportunities were prioritized using the absence of complementary-category purchases and the elapsed time since the most recent implement purchase.

**Priority definitions:**

- `P1_HIGH`: No parts or services purchases and at least 180 days since the last implement purchase.
- `P2_MEDIUM`: No services purchases and at least 90 days since the last implement purchase, excluding P1 cases.
- `P3_MONITOR`: Remaining identified opportunities.

| Priority | Customers |
|---|---:|
| `P1_HIGH` | 10 |
| `P2_MEDIUM` | 7 |
| `P3_MONITOR` | 5 |
| **Total** | **22** |

Additional checks confirmed:

- Unique customers: 22
- Duplicate rows: 0
- Invalid priority assignments: 0

**Status: PASS**

### 8.4 Transaction Filter Consistency

The original commercial prioritization query includes all transaction types, while the initial purchase classification validations consider only `SALE` transactions.

Both approaches were compared.

| Metric | All transactions | SALE only |
|---|---:|---:|
| Implement buyers | 49 | 49 |
| Cross-sell opportunities | 22 | 22 |

No differences were found in the aggregate counts.

**Status: PASS**

### 8.5 Customer Identity Consistency

A final validation compared customer identities across both transaction-filter approaches.

| Metric | Result |
|---|---:|
| Opportunities identified by both approaches | 22 |
| Only in all-transactions approach | 0 |
| Only in SALE-only approach | 0 |

The same 22 customers were identified by both methods.

**Status: PASS**

### Cross-Sell Validation Conclusion

All five commercial consistency checks passed.

The identified opportunities and priorities are internally consistent with the implemented analytical rules.

**Overall status: PASS**

**Interpretation limitation:** Cross-sell opportunities represent observed purchase-category gaps. They do not establish unmet customer demand, equipment compatibility, or guaranteed incremental revenue.

---

## 9. Data Quality Status Definitions

| Status | Meaning |
|---|---|
| `PASS` | The validation meets the defined consistency requirements. |
| `WARN` | A data quality issue or unresolved limitation requires attention. |
| `EXPECTED` | The observed behavior is consistent with a documented business rule. |
| `DOCUMENTED LIMITATION` | A known restriction affects analytical interpretation but is not necessarily a processing error. |
| `FAIL` | A required integrity condition is violated. |

A `PASS` result applies to the tested rules and data snapshot. It does not guarantee that the source data is free from all possible errors.

---

## 10. Known Limitations

The following limitations should be considered when interpreting analytical results:

**Customer identity coverage**

Some historical transactions cannot be associated with a consolidated customer identity. Customer-level financial totals may therefore differ from complete transactional totals.

**Legacy ERP profitability**

Profit is unavailable for services and certain product transactions with zero recorded cost, according to the original extraction rules.

**Current ERP financial completeness**

Some current ERP records have missing cost and profit information. Their underlying cause remains unresolved.

**Revenue exceptions**

Four current ERP service records do not reconcile with the standard quantity-times-price calculation.

**Cross-sell interpretation**

Cross-sell opportunities identify category-purchase gaps within a defined period. They are commercial hypotheses requiring further customer and product-level validation.

**Historical and fixed-period analysis**

The documented results reflect the validated dataset and fixed analysis period. Re-running the queries after source data changes may produce different results.

---

## 11. Reproducing the Validations

### Prerequisites

The following analytical layers must already be available:

- Legacy and current ERP staging and transformation layers
- Consolidated customer identity mapping
- Unified sales classification view
- Customer-level analytical views
- RFM v2 views
- Commercial analysis logic

### Execution

Open the SQL scripts in HeidiSQL and execute them in numerical order:

```text
01_validate_customer_segments.sql
02_validate_rfm_reconciliation.sql
03_validate_customer_uniqueness.sql
04_validate_sales_integrity.sql
05_validate_cross_sell_consistency.sql
```

Compare the query outputs with the documented expected results.

Investigate unexpected differences before updating the validation status.

The scripts are designed for analytical verification and should not modify source records.

---

## 12. Final Assessment

The validation framework demonstrates that the project's principal analytical transformations produce consistent and reconcilable results.

Key outcomes include:

- **3,109** consolidated customer profiles validated through RFM reconciliation.
- **R$ 4,194,807.91** in reconciled 12-month monetary value.
- **291,024** unified sales item records evaluated.
- **4,393** legacy return records with consistent quantity signs.
- **22** cross-sell opportunities validated across classification, prioritization, and customer identity checks.
- No duplicate customer records in the validated RFM views.
- No duplicate composite transaction keys in the unified sales dataset.

Remaining financial and customer-identity limitations are explicitly documented to support responsible interpretation.

**Final validation assessment: PASS WITH DOCUMENTED LIMITATIONS**

The analytical foundation is suitable for subsequent customer intelligence reporting, commercial opportunity analysis, and dashboard development, provided that the identified limitations are respected.
