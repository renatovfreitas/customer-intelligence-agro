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
- `profit_
