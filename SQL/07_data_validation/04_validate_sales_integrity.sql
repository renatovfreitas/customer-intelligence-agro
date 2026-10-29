# 04 — Sales Integrity Validation

## Objective

Validate the structural and financial integrity of sales records in `vw_sales_unified_classified`, which combines transactions from the legacy Firebird ERP and the current ERP.

The validation identifies missing identifiers, invalid dates, quantity anomalies, financial inconsistencies, and incomplete cost or profit information.

It also distinguishes expected data limitations arising from documented business rules from potential data quality issues.

## Data Source

- **Primary view:** `vw_sales_unified_classified`
- **Source systems:** `LEGACY_ERP` and `CURRENT_ERP`
- **Historical coverage:** January 2018 – September 2026
- **Total records evaluated:** 291,024

## Validation Results

| Validation | Result | Status |
|---|---|---|
| Missing source system, sale control, or sale item ID | 0 | PASS |
| Missing or malformed sale dates | 0 | PASS |
| Null or zero quantities | 0 | PASS |
| Missing unit sale prices | 0 | PASS |
| Missing analytical product groups | 0 | PASS |
| Duplicate composite transaction keys | 0 | PASS |
| Missing customer identities | 28,838 | WARN |
| Negative quantities | 4,393 | EXPECTED |
| Missing unit costs | 6,181 | WARN |
| Missing profits | 34,424 | DOCUMENTED LIMITATION |
| Revenue calculation mismatches | 4 | WARN |
| Profit calculation mismatches in comparable records | 0 | PASS |

## Findings

### 1. Customer Identity Completeness

A total of 28,838 sales records have no consolidated `customer_identity_id`:

- Legacy ERP: 28,451 records
- Current ERP: 387 records

These transactions remain available for financial analysis but cannot be reliably attributed to a consolidated customer identity.

Customer-level analyses should account for this limitation.

### 2. Negative Quantities

The dataset contains 4,393 negative quantities, all originating from the legacy ERP.

The legacy extraction explicitly converts qualifying return transactions into negative quantities and revenues.

Negative quantities are therefore consistent with the documented treatment of returns and should not automatically be classified as invalid.

### 3. Missing Profit — Legacy ERP

The legacy ERP contains 28,243 records with missing profit values.

Investigation of the original Firebird extraction view, `vw_legacy_sales_enriched`, confirmed the following rules:

- Service transactions (`vi.produto = 0`) have `profit = NULL`.
- Transactions with movement type `SV` and zero unit cost have `profit = NULL`.
- Qualifying return transactions reverse the sign of calculated profit.
- Other transactions calculate profit as `(unit_sale_price - unit_cost) * quantity`.

The observed missing-profit distribution is:

| Transaction category | Missing profit |
|---|---:|
| Service sales | 21,881 |
| Service returns | 13 |
| Product sales | 6,349 |
| Product returns | 0 |
| **Total** | **28,243** |

These missing values originate from the legacy extraction logic and are preserved through the staging, integration, and classification layers.

They must not be replaced automatically with zero or calculated using an assumed zero cost.

### 4. Missing Cost and Profit — Current ERP

The current ERP contains 6,181 records where both `unit_cost` and `profit` are missing.

These records require separate investigation into the current ERP's financial data availability and transformation rules.

No cost or profit values should be imputed without an established business rule.

### 5. Revenue Calculation Exceptions

Four records from the current ERP do not reconcile with the standard calculation:

`revenue = quantity * unit_sale_price`

All four records share the following characteristics:

- `product_id = 922080`
- `item_type = SERVICE`
- `transaction_type = SALE`
- `quantity = 1`
- `unit_sale_price = 250`

Their recorded revenues are 10, 50, 60, and 90, resulting in a combined difference of -790 compared with the standard calculation.

These exceptions may reflect special pricing, adjustments, or other ERP-specific accounting behavior, but the cause has not been confirmed.

They remain flagged for investigation.

### 6. Transaction Key Integrity

The combination of:

`source_system + sale_control + sale_item_id`

was tested for duplicate records.

No duplicate combinations were found in the evaluated dataset.

This confirms uniqueness in the current analytical snapshot but does not establish a permanent uniqueness constraint in the underlying source systems.

## Conclusion

The validation confirms that the unified sales dataset has consistent transaction identifiers and that profit calculations reconcile for records with sufficient financial information.

The principal limitations concern incomplete customer identities, unavailable cost and profit information, and four unresolved revenue exceptions.

Missing profit in the legacy ERP is explained by documented extraction rules and should be treated as a known analytical limitation rather than an unexpected integration error.

**Overall assessment: PASS WITH WARNINGS**

The dataset is suitable for customer segmentation and commercial behavior analysis, subject to the documented limitations. Profitability analysis must explicitly account for records with missing financial information.
