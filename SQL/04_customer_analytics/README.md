# Customer Analytics

## Overview

This directory contains the SQL views used to analyze customer purchasing behavior, financial performance, product preferences, after-sales opportunities, and commercial segmentation.

The analytics layer was developed in two stages:

1. **Original Customer Analytics (01–11):** Analysis based on the current ERP, using `customer_key` as the customer identifier.
2. **Unified Historical Analytics (12):** Analysis based on integrated sales data from the legacy and current ERPs, using `customer_identity_id` as the consolidated customer identifier.

The original views are preserved to document the evolution of the project. The unified customer identity model supports the newer RFM v2 segmentation methodology.

---

## 1. Directory Structure

```text
04_customer_analytics/
│
├── 01_create_customer_master.sql
├── 02_create_customer_behavior_12m.sql
├── 03_create_customer_profile_base.sql
├── 04_create_customer_profile.sql
│
├── 05_create_customer_product_group.sql
├── 06_create_customer_product_total.sql
├── 07_create_customer_product_mix.sql
├── 08_create_customer_product_behavior.sql
│
├── 09_create_customer_first_implement_purchase.sql
├── 10_create_customer_after_sales.sql
├── 11_create_customer_commercial_segment.sql
│
├── 12_create_customer_historical_profile.sql
│
└── README.md
```

The numbering reflects a valid dependency order for the documented views.

All views require their upstream data transformation and integration views to be available.

---

## 2. Analytical Scope

### Original Customer Analytics

**Source:** `vw_sales_enriched`

**Customer identifier:** `customer_key`

**ERP coverage:** Current ERP

The original analytics model uses several date ranges depending on the business question.

| Analysis | Start Date | End Date (Inclusive) |
|---|---|---|
| Customer master | 2024-08-01 | 2026-07-07 |
| Customer behavior (12 months) | 2025-07-08 | 2026-07-07 |
| Product mix | 2025-07-08 | 2026-07-07 |
| First implement purchase | 2025-07-08 | 2026-07-07 |
| After-sales analysis | Based on first implement purchase | 2026-07-07 |

**Reference date for original customer recency:** 2026-07-08.

These views are not directly comparable with the unified RFM v2 model because they use different customer identifiers, date windows, and data coverage.

### Unified Historical Analytics

**Source:** `vw_sales_unified_classified`

**Customer identifier:** `customer_identity_id`

**ERP coverage:** Legacy ERP and current ERP

**Historical period:** 2018-01-01 through 2026-09-03.

**Reference date:** 2026-09-03.

The unified model uses a customer identity dimension and registration bridge to associate records from different ERP systems with the same customer identity.

---

## 3. Customer Master and Behavioral Metrics

### 01 — vw_customer_master

**File:** `01_create_customer_master.sql`

**Dependency:** `vw_sales_enriched`

Creates the original customer-level analytical dataset.

The view aggregates transactions by:

- `customer_key`
- `customer_name`
- `cpf_cnpj_normalized`

**Main metrics:**

| Metric | Description |
|---|---|
| `revenue` | Total revenue |
| `profit` | Total known profit |
| `profit_margin` | Profit divided by revenue |
| `sales_qtt` | Number of distinct sales |
| `items_qtt` | Total item quantity |
| `distinct_products` | Number of distinct product names |
| `distinct_product_subcategories` | Number of normalized product subcategories |
| `distinct_product_groups` | Number of distinct product group IDs |
| `average_ticket` | Revenue per sale |
| `average_items_per_sale` | Item quantity per sale |
| `average_profit_per_sale` | Profit per sale |
| `average_revenue_per_item` | Revenue per item |
| `average_profit_per_item` | Profit per item |
| `last_purchase` | Most recent purchase date |
| `days_since_last_purchase` | Days since last purchase, using 2026-07-08 |

**Business rules:**

- Includes sales from 2024-08-01 through 2026-07-07.
- Excludes null customer names.
- Excludes specified unidentified or generic customer names.
- Counts distinct sales using `sale_control`.
- Uses `NULLIF` to prevent division by zero.

**Validation:** A duplicate-key check returned no customers with multiple rows for the same `customer_key` in the analyzed dataset.

This confirms the observed customer-level granularity, although the SQL groups by additional fields and future data changes could affect uniqueness.

### 02 — vw_customer_behavior_12m

**File:** `02_create_customer_behavior_12m.sql`

**Dependency:** `vw_sales_enriched`

Calculates customer purchasing behavior within the original 12-month analytical window.

**Period:** 2025-07-08 through 2026-07-07.

**Main metrics:**

- `frequency_12m`: Distinct sales.
- `monetary_12m`: Total revenue.
- `profit_12m`: Total profit.
- `profit_margin_12m`: Profit divided by revenue.
- `last_purchase_12m`: Latest purchase in the period.

Only customers with transactions in the specified window appear in this view.

### 03 — vw_customer_profile_base

**File:** `03_create_customer_profile_base.sql`

**Dependencies:**

- `vw_customer_master`
- `vw_customer_behavior_12m`

Combines historical customer metrics with recent purchasing behavior.

A `LEFT JOIN` preserves customers from the master dataset even when they have no transactions in the 12-month window.

**Null-handling rules:**

- Missing frequency becomes zero.
- Missing monetary value becomes zero.
- Missing profit becomes zero.
- Missing profit margin remains `NULL`.

The resulting dataset serves as the foundation for the original RFM scoring model.

### 04 — vw_customer_profile

**File:** `04_create_customer_profile.sql`

**Dependency:** `vw_customer_profile_base`

Assigns customer RFM scores using fixed business thresholds.

#### Recency Score

| Days Since Last Purchase | R Score |
|---|---|
| 0–30 | 5 |
| 31–90 | 4 |
| 91–180 | 3 |
| 181–365 | 2 |
| More than 365 | 1 |

#### Frequency Score

| Purchases in 12 Months | F Score |
|---|---|
| 11 or more | 5 |
| 4–10 | 4 |
| 2–3 | 3 |
| 1 | 2 |
| 0 | 1 |

#### Monetary Score

| Revenue in 12 Months (BRL) | M Score |
|---|---|
| 10,000 or more | 5 |
| 3,000–9,999.99 | 4 |
| 500–2,999.99 | 3 |
| Greater than 0 and below 500 | 2 |
| Zero or negative | 1 |

These are fixed business thresholds rather than statistical quintiles.

The original scoring methodology differs from the newer RFM v2 model.

---

## 4. Product Mix and Purchasing Preferences

### 05 — vw_customer_product_group

**File:** `05_create_customer_product_group.sql`

**Dependencies:**

- `vw_sales_enriched`
- `vw_customer_master`

Aggregates financial and sales metrics by customer and product group.

**Main metrics:**

- `group_revenue`
- `group_profit`
- `group_sales_qtt`

**Period:** 2025-07-08 through 2026-07-07.

Only customers matching the customer master are included.

### 06 — vw_customer_product_total

**File:** `06_create_customer_product_total.sql`

**Dependency:** `vw_customer_product_group`

Calculates total revenue across product groups for each customer.

**Calculation:**

`total_revenue = SUM(group_revenue)`

This value is used as the denominator in the product mix analysis.

### 07 — vw_customer_product_mix

**File:** `07_create_customer_product_mix.sql`

**Dependencies:**

- `vw_customer_product_group`
- `vw_customer_product_total`

Calculates the contribution of each product group to a customer's total revenue.

**Calculation:**

`group_revenue_pct = group_revenue / NULLIF(total_revenue, 0)`

The result is a ratio rather than a percentage already multiplied by 100.

For example, a result of `0.65` represents 65% of the customer's revenue.

The `INNER JOIN` includes only customers with matching records in both source views.

### 08 — vw_customer_product_behavior

**File:** `08_create_customer_product_behavior.sql`

**Dependency:** `vw_customer_product_mix`

Identifies the highest-revenue product group for each customer.

**Output metrics:**

- `dominant_product_group`
- `dominant_group_revenue`
- `dominant_group_revenue_pct`
- `dominant_group_profit`
- `dominant_group_sales_qtt`

The view uses an anti-join to identify groups for which no other group has strictly greater revenue.

**Tie limitation:** If two product groups have identical maximum revenue for the same customer, both can be returned.

**Validation:** A query checking customers with multiple dominant groups returned zero rows in the analyzed dataset.

---

## 5. After-Sales Analysis

### 09 — vw_customer_first_implement_purchase

**File:** `09_create_customer_first_implement_purchase.sql`

**Dependency:** `vw_sales_enriched`

Identifies the earliest purchase of products classified as `IMPLEMENTOS` for each customer within the original analytical window.

**Period:** 2025-07-08 through 2026-07-07.

**Calculation:**

`first_implement_purchase = MIN(sale_date)`

This is the first implement purchase **within the selected window**, not necessarily the customer's first historical implement purchase.

### 10 — vw_customer_after_sales

**File:** `10_create_customer_after_sales.sql`

**Dependencies:**

- `vw_customer_first_implement_purchase`
- `vw_sales_enriched`

Measures purchases of parts following the first identified implement purchase.

**Main metrics:**

- `parts_sales_after_implement`
- `parts_revenue_after_implement`

Only parts transactions with a sale date strictly later than the first implement purchase are counted.

Transactions occurring on the same calendar date are excluded.

A `LEFT JOIN` retains customers without subsequent parts purchases.

#### Validation Results

| Metric | Result |
|---|---:|
| Implement customers | 50 |
| Customers buying parts afterward | 25 |
| Customers without subsequent parts purchases | 25 |
| Subsequent parts purchase rate | 50.0% |
| Subsequent parts revenue | R$ 51,600.85 |

**Business interpretation:**

Half of the identified implement buyers had no subsequent parts purchases within the analyzed period.

This represents a potential opportunity for customer follow-up and after-sales engagement.

However, it does not prove that these customers have unmet maintenance needs or stopped purchasing parts permanently.

---

## 6. Commercial Segmentation

### 11 — vw_customer_commercial_segment

**File:** `11_create_customer_commercial_segment.sql`

**Dependencies:**

- `vw_customer_profile`
- `vw_customer_product_behavior`
- `vw_customer_after_sales`

Combines customer RFM scores, dominant product groups, historical purchasing behavior, and after-sales metrics into commercial segments.

The classification follows an ordered `CASE` statement.

The first matching rule determines the customer's segment.

| Priority | Segment | Main Rule |
|---|---|---|
| 1 | AFTER-SALES OPPORTUNITY | Implement purchase at least 180 days earlier, with no subsequent parts sales |
| 2 | RECURRING COOLING DOWN | Dominant group PEÇAS, R ≤ 3, F ≥ 4 |
| 3 | HIGH VALUE EQUIPMENT | Dominant group IMPLEMENTOS or TRATORES, M ≥ 4 |
| 4 | CORE ACTIVE | R ≥ 4, F ≥ 4, M ≥ 3 |
| 5 | HIGH VALUE OCCASIONAL | M ≥ 4 |
| 6 | DORMANT HIGH POTENTIAL | R = 1 and historical frequency ≥ 4 or historical revenue ≥ R$ 3,000 |
| 7 | LOW ENGAGEMENT | Remaining customers |

#### Commercial Interpretation

**AFTER-SALES OPPORTUNITY:** Customers who may benefit from follow-up after an implement purchase.

**RECURRING COOLING DOWN:** Previously frequent parts buyers showing weaker recency.

**HIGH VALUE EQUIPMENT:** Customers with substantial monetary value and an equipment-oriented purchasing profile.

**CORE ACTIVE:** Recently active, frequent, and commercially valuable customers.

**HIGH VALUE OCCASIONAL:** High-spending customers who do not meet earlier classification rules.

**DORMANT HIGH POTENTIAL:** Inactive customers with meaningful historical purchasing activity or revenue.

**LOW ENGAGEMENT:** Customers not covered by the preceding rules.

#### Validation Results

The commercial segmentation query returned:

- 1,953 classified customers.
- Seven commercial segments.
- Approximately R$ 3.57 million in revenue within the original analytical model.

The CORE ACTIVE and HIGH VALUE EQUIPMENT segments represented a substantial share of the observed revenue.

These results must not be directly compared with unified RFM v2 totals because the customer population and analytical windows differ.

---

## 7. Unified Historical Customer Profile

### 12 — vw_customer_historical_profile

**File:** `12_create_customer_historical_profile.sql`

**Dependency:** `vw_sales_unified_classified`

Creates a customer-level historical profile using integrated sales from both ERP systems.

Unlike the original customer analytics views, this view uses `customer_identity_id`.

**Period:** 2018-01-01 through 2026-09-03.

**Reference date:** 2026-09-03.

#### Main Metrics

| Metric | Description |
|---|---|
| `customer_identity_id` | Consolidated customer identifier |
| `first_purchase_date` | Earliest recorded purchase |
| `last_purchase_date` | Latest recorded purchase |
| `recency_days` | Days since the latest purchase |
| `total_purchases` | Distinct purchases across both ERPs |
| `lifetime_revenue` | Total revenue in the historical window |
| `known_lifetime_profit` | Sum of recorded profit values |
| `product_items` | Number of product transaction rows |
| `service_items` | Number of service transaction rows |

Distinct purchases are counted using the combination of `source_system` and `sale_control`.

This prevents sale control numbers from different ERP systems from being treated as the same transaction.

**Important limitations:**

- Lifetime metrics represent the available historical period beginning in 2018, not necessarily the customer's entire lifetime.
- Known profit may be incomplete where historical cost information is unavailable.
- Product and service item metrics count transaction rows, not necessarily total physical quantities.
- Customers without a consolidated identity are excluded.

This view provides a historical customer perspective complementary to the RFM v2 segmentation layer.

It is not a direct upstream dependency of `vw_customer_rfm_base_v2`; both views use `vw_sales_unified_classified`.

---

## 8. Relationship with RFM v2

The newer RFM model is documented separately under:

`sql/05_rfm_segmentation/`

Its main views are:

1. `vw_customer_rfm_base_v2`
2. `vw_customer_rfm_scores_v2`
3. `vw_customer_segments_v2`

### Main Differences

| Dimension | Original Analytics | RFM v2 |
|---|---|---|
| ERP coverage | Current ERP | Legacy + Current ERP |
| Customer identifier | `customer_key` | `customer_identity_id` |
| Reference date | 2026-07-08 | 2026-09-03 |
| Recent behavior window | 2025-07-08 to 2026-07-07 | 2025-09-04 to 2026-09-03 |
| Highest monetary score threshold | R$ 10,000 | R$ 25,000 |
| Commercial segmentation | 7 segments | 11 segments |

The models should be treated as different analytical versions rather than directly interchangeable datasets.

---

## 9. Data Quality and Validation

The following read-only validations were performed during project development.

| Validation | Observed Result |
|---|---|
| Duplicate `customer_key` in `vw_customer_master` | No duplicate keys returned |
| Multiple dominant product groups per customer | No ties returned |
| Original after-sales analysis | 50 implement customers; 25 with subsequent parts purchases |
| Original commercial segmentation | 1,953 customers classified |
| Unified RFM v2 population | 3,109 customers |
| Unified RFM v2 active customers | 1,406 |
| Unified RFM v2 inactive customers | 1,703 |

The unified RFM v2 summary query returned R$ 4,194,807.91 in 12-month revenue.

A previously captured segment-level aggregation produced a different total. Therefore, the segment-level revenue reconciliation remains an open validation item and should be resolved before treating those figures as fully reconciled.

These validations describe the observed data at the time of analysis. They do not guarantee that future imports or data changes will preserve the same results.

---

## 10. Dependency and Execution Order

The original analytics views should be created in the following order:

```text
vw_sales_enriched
    |
    +-- vw_customer_master
    |      |
    |      +-- vw_customer_profile_base
    |      |      |
    |      |      +-- vw_customer_profile
    |      |              |
    |      |              +-- vw_customer_commercial_segment
    |      |
    |      +-- vw_customer_product_group
    |              |
    |              +-- vw_customer_product_total
    |              |       |
    |              +-------+-- vw_customer_product_mix
    |                              |
    |                              +-- vw_customer_product_behavior
    |                                      |
    |                                      +-- vw_customer_commercial_segment
    |
    +-- vw_customer_behavior_12m
    |       |
    |       +-- vw_customer_profile_base
    |
    +-- vw_customer_first_implement_purchase
            |
            +-- vw_customer_after_sales
                    |
                    +-- vw_customer_commercial_segment
```

The unified historical view follows a separate dependency path:

```text
vw_sales_unified_classified
    |
    +-- vw_customer_historical_profile
    |
    +-- vw_customer_rfm_base_v2
            |
            +-- vw_customer_rfm_scores_v2
                    |
                    +-- vw_customer_segments_v2
```

The SQL files are organized in dependency-compatible order within this directory. Upstream integration and transformation views must be created first.

---

## 11. Privacy and Reproducibility

This project analyzes real business transactions. Public repository content must avoid exposing confidential or personally identifiable customer information.

**Repository guidelines:**

- Publish SQL definitions and methodological documentation.
- Do not publish customer names, CPF/CNPJ values, phone numbers, email addresses, or transaction-level personal data.
- Do not publish private identity mapping files or customer document hashes.
- Use aggregated or anonymized examples when presenting analytical results.
- Remove environment-specific database `DEFINER` clauses from version-controlled SQL.
- Preserve original business logic when formatting or documenting views.

The SQL definitions were formatted from the original database view definitions. Formatting and documentation do not imply that every script has been independently executed or tested in a fresh database environment.

Some analytical windows and score thresholds are intentionally fixed to preserve the historical methodology and reproducibility of the project.

---

## 12. Future Improvements

Potential enhancements include:

- Developing unified product-mix analytics using `customer_identity_id`.
- Extending after-sales analysis across both ERP systems.
- Aligning product behavior and commercial segmentation with the unified RFM v2 reference period.
- Adding automated data quality checks for customer identity uniqueness, transaction counts, and financial reconciliation.
- Introducing parameterized reporting periods for future recurring analysis.
- Building dashboards and prioritized commercial action lists from validated analytical outputs.

These enhancements are future development opportunities and are not represented as completed functionality in the current repository.

---

## Summary

The Customer Analytics layer demonstrates the progression from basic customer-level financial aggregation to behavioral analysis, product preferences, after-sales opportunity identification, and commercial segmentation.

The original analytics model documents the development of business rules and actionable customer insights within the current ERP.

The unified historical profile extends the analytical foundation across legacy and current systems, supporting the more comprehensive RFM v2 methodology.

Together, these components provide a traceable foundation for customer intelligence, retention analysis, and data-driven commercial decision-making.
