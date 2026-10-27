# RFM Segmentation v2 — Customer Intelligence

## Overview

This directory contains the SQL views responsible for customer segmentation using the **Recency, Frequency, and Monetary (RFM)** methodology.

The RFM v2 model builds on the unified sales dataset, integrating historical transactions from the legacy and current ERP systems through a consolidated customer identity.

Its objective is to identify valuable customers, recognize purchasing patterns, detect retention risks, and support data-driven commercial decisions.

Unlike the original RFM implementation, this model uses `customer_identity_id` rather than the original ERP-specific `customer_key`.

---

## 1. Directory Structure

```text
05_rfm_segmentation/
│
├── 01_create_customer_rfm_base_v2.sql
├── 02_create_customer_rfm_scores_v2.sql
├── 03_create_customer_segments_v2.sql
└── README.md
```

### Execution Order

The scripts must be executed in numerical order after the upstream unified sales view has been created.

```text
vw_sales_unified_classified
          |
          v
vw_customer_rfm_base_v2
          |
          v
vw_customer_rfm_scores_v2
          |
          v
vw_customer_segments_v2
```

Each view depends on the preceding analytical layer.

---

## 2. Analytical Scope

| Parameter | Definition |
|---|---|
| Source view | `vw_sales_unified_classified` |
| Customer identifier | `customer_identity_id` |
| ERP coverage | Legacy ERP + Current ERP |
| Historical start date | 2018-01-01 |
| Reference date | 2026-09-03 |
| RFM window start | 2025-09-04 |
| RFM window end | 2026-09-03 |
| Currency | Brazilian Real (BRL) |
| Scoring methodology | Fixed business thresholds |

The model uses a fixed reference date instead of `CURDATE()` to ensure that the analytical period remains reproducible.

All date boundaries are inclusive.

---

## 3. RFM Base — Customer Metrics

### 01_create_customer_rfm_base_v2.sql

**Creates:** `vw_customer_rfm_base_v2`

**Dependency:** `vw_sales_unified_classified`

This view aggregates historical and recent purchasing behavior for each consolidated customer identity.

### Main Metrics

| Column | Description |
|---|---|
| `customer_identity_id` | Unified customer identifier |
| `first_purchase_date` | Earliest recorded purchase |
| `last_purchase_date` | Most recent recorded purchase |
| `recency_days` | Days since the last purchase |
| `total_purchases` | Total distinct historical purchases |
| `lifetime_revenue` | Historical revenue since 2018 |
| `frequency_12m` | Distinct purchases during the RFM window |
| `monetary_12m` | Revenue during the RFM window |
| `profit_12m` | Known profit during the RFM window |

### Business Rules

**Customer identity**

Only transactions associated with a non-null `customer_identity_id` are included.

**Distinct purchases**

Sales are counted using the combination of:

`source_system + ':' + sale_control`

This prevents transactions from different ERP systems with identical control numbers from being counted as the same purchase.

**Recency**

Recency is calculated as the difference between the fixed reference date and the customer's latest recorded purchase.

**Frequency**

Frequency counts distinct transactions during the 12-month analytical window.

**Monetary value**

Monetary value is calculated as the sum of revenue during the same window.

**Profit**

Profit is calculated from available transaction-level profit values.

When no non-null profit values exist in the selected period, `profit_12m` may return `NULL`.

### Inactive Customers

Customers with historical purchases but no transactions during the RFM window remain in the dataset.

They receive:

- `frequency_12m = 0`
- `monetary_12m = 0`

This allows the model to identify inactive customers and assess their historical commercial importance.

---

## 4. RFM Scoring Methodology

### 02_create_customer_rfm_scores_v2.sql

**Creates:** `vw_customer_rfm_scores_v2`

**Dependency:** `vw_customer_rfm_base_v2`

The view assigns scores from 1 to 5 across three dimensions.

Higher scores represent more favorable purchasing behavior.

### Recency (R)

Measures how recently the customer made a purchase.

| Days Since Last Purchase | R Score |
|---|---|
| 0–30 | 5 |
| 31–90 | 4 |
| 91–180 | 3 |
| 181–365 | 2 |
| More than 365 | 1 |

### Frequency (F)

Measures how often the customer purchased during the 12-month window.

| Distinct Purchases | F Score |
|---|---|
| 11 or more | 5 |
| 6–10 | 4 |
| 4–5 | 3 |
| 2–3 | 2 |
| 0–1 | 1 |

### Monetary (M)

Measures the customer's revenue contribution during the 12-month window.

| Revenue (BRL) | M Score |
|---|---|
| R$ 25,000 or more | 5 |
| R$ 5,000–24,999.99 | 4 |
| R$ 1,000–4,999.99 | 3 |
| R$ 500–999.99 | 2 |
| Below R$ 500 | 1 |

### Methodological Notes

The model uses fixed business thresholds rather than statistical quintiles.

This makes the scores interpretable against consistent monetary and purchasing criteria.

However, the thresholds are business assumptions and should be reviewed as the customer base, prices, and market conditions change.

Profit is retained as an analytical metric but does not influence the RFM scores.

---

## 5. Customer Segmentation

### 03_create_customer_segments_v2.sql

**Creates:** `vw_customer_segments_v2`

**Dependency:** `vw_customer_rfm_scores_v2`

This view transforms RFM scores and historical purchasing indicators into 11 customer segments.

The classification uses an ordered SQL `CASE` statement.

**The first matching condition determines the final segment.**

### Segmentation Rules

| Priority | Segment | Classification Criteria |
|---|---|---|
| 1 | VIP | R ≥ 4, F ≥ 4, M ≥ 4 |
| 2 | Loyal Customers | R ≥ 3, F ≥ 4 |
| 3 | High-Value Occasional | R ≥ 3, M ≥ 4 |
| 4 | New Customers | First purchase on or after 2026-06-06 |
| 5 | Promising | R ≥ 4 |
| 6 | At Risk | R = 2 and (F ≥ 3 or M ≥ 3) |
| 7 | Active Occasional | R ≥ 2 |
| 8 | High-Value Lost | R = 1 and lifetime revenue ≥ R$ 50,000 |
| 9 | Former Regular Customers | R = 1 and lifetime revenue ≥ R$ 10,000 |
| 10 | Recently Inactive | R = 1 and recency ≤ 730 days |
| 11 | Long-Term Inactive | Remaining customers |

### Commercial Interpretation

**VIP:** Recently active customers with high purchasing frequency and monetary contribution. Priorities include retention, personalized relationships, and high-quality service.

**Loyal Customers:** Frequent customers with relatively favorable recency. Opportunities include loyalty initiatives and complementary product recommendations.

**High-Value Occasional:** Customers generating substantial revenue without meeting the frequency criteria of the higher-priority segments.

**New Customers:** Recently acquired customers who do not satisfy earlier segmentation conditions. Priorities include onboarding and relationship development.

**Promising:** Recently active customers who may develop into more frequent or valuable buyers.

**At Risk:** Customers with declining recency but meaningful purchasing frequency or monetary contribution.

**Active Occasional:** Customers who remain within the model's recency criteria but do not qualify for earlier segments.

**High-Value Lost:** Inactive customers with substantial historical revenue, potentially relevant for targeted recovery efforts.

**Former Regular Customers:** Inactive customers with meaningful historical purchasing activity as represented by the model's revenue threshold.

**Recently Inactive:** Customers whose most recent purchase occurred more than 365 but no more than 730 days before the reference date, provided they do not meet higher-priority conditions.

**Long-Term Inactive:** Customers not covered by the preceding conditions, generally representing prolonged inactivity.

### Important Classification Limitations

- Segment labels are mutually exclusive because the first matching rule takes precedence.
- A recently acquired customer may be classified as VIP, Loyal, or High-Value Occasional before reaching the New Customers condition.
- Active Occasional does not necessarily imply a purchase within the 12-month window.
- High-Value Lost and Former Regular Customers use historical revenue, not 12-month monetary value.
- Commercial labels describe rule-based analytical categories and do not independently establish customer intentions or future purchasing behavior.

---

## 6. Validation Results

The model was validated using read-only SQL aggregation queries against the existing database views.

### Customer Population

| Metric | Result |
|---|---:|
| Total customers | 3,109 |
| Active customers | 1,406 |
| Inactive customers | 1,703 |
| Active customer share | 45.22% |
| Inactive customer share | 54.78% |

An active customer is defined as having:

`frequency_12m > 0`

An inactive customer has:

`frequency_12m = 0`

### Revenue Validation

| Metric | Result |
|---|---:|
| Total revenue in RFM window | R$ 4,194,807.91 |
| Revenue reconciliation difference | R$ 0.00 |

The sum of revenue across the customer segments matched the consolidated RFM revenue total.

### VIP Concentration

| Metric | Result |
|---|---:|
| VIP customers | 120 |
| VIP share of customer base | 3.86% |
| VIP revenue | R$ 2,314,759.87 |
| VIP share of 12-month revenue | 55.18% |

### Key Finding

A relatively small group of VIP customers contributes more than half of the revenue generated during the analyzed 12-month period.

This indicates a significant concentration of revenue among high-value customers.

From a commercial perspective, the finding supports the importance of customer retention and relationship management for this segment.

However, revenue concentration alone does not measure profitability, churn probability, or future customer lifetime value.

---

## 7. Validation Queries

### Customer Population and Revenue

```sql
SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN frequency_12m > 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    SUM(
        CASE
            WHEN frequency_12m = 0 THEN 1
            ELSE 0
        END
    ) AS inactive_customers,

    ROUND(SUM(monetary_12m), 2)
        AS total_revenue_12m

FROM vw_customer_segments_v2;
```

### Segment Distribution and Financial Reconciliation

```sql
SELECT
    customer_segment,

    COUNT(*) AS customers,

    SUM(
        CASE
            WHEN frequency_12m > 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    ROUND(SUM(monetary_12m), 2)
        AS revenue_12m

FROM vw_customer_segments_v2

GROUP BY
    customer_segment

ORDER BY
    revenue_12m DESC;
```

These queries were used to verify population totals, activity classification, and revenue consistency.

---

## 8. Relationship with Original Customer Analytics

The project also contains an earlier analytical implementation under:

`sql/04_customer_analytics/`

That implementation uses the current ERP and the `customer_key` identifier.

The RFM v2 model introduces broader historical coverage and a unified customer identity.

| Dimension | Original Model | RFM v2 |
|---|---|---|
| ERP coverage | Current ERP | Legacy + Current ERP |
| Customer identifier | `customer_key` | `customer_identity_id` |
| Reference date | 2026-07-08 | 2026-09-03 |
| Recent behavior period | 2025-07-08 to 2026-07-07 | 2025-09-04 to 2026-09-03 |
| Highest monetary threshold | R$ 10,000 | R$ 25,000 |
| Segmentation | 7 commercial segments | 11 RFM segments |

The original model is preserved for traceability and to demonstrate the development of the analytical methodology.

Results from the two versions should not be directly compared without accounting for differences in data coverage, customer identity, dates, and scoring thresholds.

---

## 9. Data Quality, Privacy, and Reproducibility

### Data Quality

The validation process confirmed that the aggregated customer counts and revenue totals were internally consistent at the time of analysis.

However, these checks do not independently verify every underlying transaction, customer identity match, or business classification.

### Privacy

The public repository should contain SQL definitions, methodology, and aggregated results only.

It must not expose:

- Customer names or personal contact information.
- CPF/CNPJ values.
- Customer document hashes or private identity mappings.
- Confidential transaction-level customer records.

### Reproducibility

The SQL views use fixed reference dates and fixed scoring thresholds.

This allows the same analytical logic to be reproduced for the specified historical snapshot, assuming equivalent source data.

The SQL files were formatted from existing database view definitions. They were not independently deployed and tested in a new database environment.

---

## 10. Future Improvements

Potential future developments include:

- Parameterizing the reference date and RFM window.
- Evaluating alternative RFM thresholds based on customer purchasing distributions.
- Integrating product preferences and after-sales indicators with unified customer identities.
- Developing segment-specific commercial action lists.
- Measuring customer retention and reactivation over successive periods.
- Incorporating profit and margin into customer prioritization.
- Creating Power BI dashboards to communicate customer segmentation and revenue concentration.
- Automating data quality and financial reconciliation checks.

These improvements represent future development opportunities rather than completed functionality.

---

## Conclusion

The RFM v2 segmentation layer transforms integrated historical sales data into actionable customer intelligence.

By combining unified customer identities, consistent analytical periods, rule-based scoring, and commercial segmentation, the model supports customer retention analysis, revenue concentration assessment, and targeted commercial planning.

The validated results highlight the strategic importance of a relatively small high-value customer segment while also identifying a substantial population of inactive customers who may warrant further investigation.
