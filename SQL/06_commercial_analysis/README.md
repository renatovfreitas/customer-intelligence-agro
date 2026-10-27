# Commercial Analysis — Customer Intelligence

## Overview

This directory contains SQL analyses designed to identify cross-selling opportunities and support commercial decision-making in an agricultural machinery retail business.

The analyses focus on customers who purchased agricultural implements (`IMPLEMENTOS`) and evaluate whether they also purchased parts (`PECAS`) or services (`SERVICOS`) during the same analytical period.

The results are enriched with RFM v2 customer segmentation and rule-based commercial priorities.

**Business objectives:**

- Measure parts and services penetration among implement buyers.
- Identify customers with potential cross-selling opportunities.
- Classify opportunities according to missing purchase categories.
- Prioritize customers for commercial follow-up.
- Establish a foundation for future automated customer intelligence workflows.

The analyses identify observed purchasing gaps, not confirmed unmet customer needs.

---

## 1. Directory Structure

```text
06_commercial_analysis/
│
├── 01_implements_parts_services_penetration.sql
├── 02_implements_cross_sell_opportunities.sql
├── 03_cross_sell_priority.sql
└── README.md
```

All three SQL scripts were executed and their results validated against the project database.

---

## 2. Data Sources and Analytical Scope

| Parameter | Definition |
|---|---|
| Primary source | `vw_sales_unified_classified` |
| Customer segmentation | `vw_customer_segments_v2` |
| Customer identifier | `customer_identity_id` |
| ERP coverage | Legacy ERP + Current ERP |
| Analysis start date | 2025-09-04 |
| Analysis end date | 2026-09-03 |
| Reference date | 2026-09-03 |
| Currency | Brazilian Real (BRL) |
| SQL approach | Aggregation, conditional flags, derived tables, LEFT JOIN |

The analysis uses the same reference date and 12-month window as the RFM v2 model.

Customer identities are consolidated across the two ERP systems, reducing fragmentation caused by multiple registrations for the same customer.

### Product Groups

The analysis uses three values from `analytical_product_group`:

| Product Group | Interpretation |
|---|---|
| `IMPLEMENTOS` | Agricultural implements |
| `PECAS` | Replacement parts |
| `SERVICOS` | Services |

Purchase behavior is represented using binary indicators:

- `1`: At least one qualifying transaction exists.
- `0`: No qualifying transaction was identified.

These indicators describe purchasing behavior within the selected period.

They do not establish whether a customer purchased from another supplier or requires a particular product or service.

---

## 3. Parts and Services Penetration

### 01_implements_parts_services_penetration.sql

**Purpose:** Measure how frequently implement buyers also purchase parts and services.

**Source:** `vw_sales_unified_classified`

### Business Logic

The query groups transactions by `customer_identity_id` and creates three purchase indicators:

- `buys_implements`
- `buys_parts`
- `buys_services`

Only customers with `buys_implements = 1` are included in the final aggregation.

The analysis calculates:

| Metric | Definition |
|---|---|
| `implements_customers` | Customers who purchased implements |
| `customers_buying_parts` | Implement buyers who also purchased parts |
| `customers_buying_services` | Implement buyers who also purchased services |
| `customers_neither` | Implement buyers with neither parts nor services purchases |
| `parts_penetration_pct` | Percentage of implement buyers who purchased parts |
| `services_penetration_pct` | Percentage of implement buyers who purchased services |

### Penetration Formulas

**Parts penetration**

`customers_buying_parts / implements_customers * 100`

**Services penetration**

`customers_buying_services / implements_customers * 100`

### Validated Results

| Metric | Result |
|---|---:|
| Implement buyers | 49 |
| Implement buyers purchasing parts | 37 |
| Implement buyers purchasing services | 28 |
| Implement buyers purchasing neither | 11 |
| Parts penetration | 75.51% |
| Services penetration | 57.14% |

### Purchasing Behavior Breakdown

| Purchasing Behavior | Customers |
|---|---:|
| Parts and services | 27 |
| Parts only | 10 |
| Services only | 1 |
| Neither parts nor services | 11 |
| **Total implement buyers** | **49** |

### Business Interpretation

Parts penetration is higher than services penetration among implement buyers.

Eleven customers, representing 22.45% of implement buyers, did not purchase parts or services within the analyzed period.

These customers represent candidates for further commercial investigation.

However, purchase absence alone does not prove an immediate after-sales opportunity.

---

## 4. Cross-Selling Opportunity Identification

### 02_implements_cross_sell_opportunities.sql

**Purpose:** Identify individual implement buyers who have not purchased one or both complementary product categories.

**Dependencies:**

- `vw_sales_unified_classified`
- `vw_customer_segments_v2`

### Opportunity Classification

The query assigns one of three opportunity types to eligible implement buyers.

| Opportunity Type | Parts Purchased | Services Purchased |
|---|---|---|
| `PARTS_AND_SERVICES_OPPORTUNITY` | No | No |
| `SERVICES_OPPORTUNITY` | Yes | No |
| `PARTS_OPPORTUNITY` | No | Yes |

Customers who purchased both parts and services are excluded from the opportunity list.

### Validated Results

| Opportunity Type | Customers |
|---|---:|
| `PARTS_AND_SERVICES_OPPORTUNITY` | 11 |
| `SERVICES_OPPORTUNITY` | 10 |
| `PARTS_OPPORTUNITY` | 1 |
| **Total opportunities** | **22** |

Each qualifying customer appears once in the validated output.

### Customer-Level Attributes

The query combines opportunity classifications with:

- `customer_identity_id`
- `customer_segment`
- `recency_days`
- `frequency_12m`
- `monetary_12m`
- `lifetime_revenue`
- `first_implement_purchase`
- `last_implement_purchase`
- `days_since_last_implement_purchase`
- `buys_parts`
- `buys_services`

The first and last implement purchase dates are calculated within the selected 12-month window, not across the customer's entire recorded history.

### Commercial Interpretation

**Parts and services opportunity:** Potential candidates for broad after-sales engagement.

**Services opportunity:** Customers who already purchase parts but have no recorded service purchases within the analysis window.

**Parts opportunity:** Customers who purchase services but have no recorded parts purchases within the analysis window.

These categories describe observed purchasing gaps rather than confirmed customer demand.

---

## 5. Commercial Priority Classification

### 03_cross_sell_priority.sql

**Purpose:** Assign a rule-based commercial priority to identified cross-selling opportunities.

**Dependencies:**

- `vw_sales_unified_classified`
- `vw_customer_segments_v2`

The priority classification uses:

1. Parts purchase behavior.
2. Services purchase behavior.
3. Days since the customer's latest implement purchase within the analysis window.

### Priority Rules

The conditions are evaluated in order.

| Priority | Classification Rule |
|---|---|
| `P1_HIGH` | No parts or services purchases and at least 180 days since the latest implement purchase |
| `P2_MEDIUM` | No services purchases and at least 90 days since the latest implement purchase, excluding customers already assigned P1 |
| `P3_MONITOR` | All remaining identified opportunities |

### Validated Priority Distribution

| Priority | Customers | Share of Opportunities |
|---|---:|---:|
| `P1_HIGH` | 10 | 45.45% |
| `P2_MEDIUM` | 7 | 31.82% |
| `P3_MONITOR` | 5 | 22.73% |
| **Total** | **22** | **100.00%** |

### Commercial Interpretation

**P1 — High Priority**

Customers without recorded parts or services purchases whose latest implement purchase occurred at least 180 days before the reference date.

Suggested action: Investigate after-sales needs and initiate an appropriate customer relationship follow-up.

**P2 — Medium Priority**

Customers without recorded services purchases whose latest implement purchase occurred at least 90 days before the reference date, excluding P1 customers.

Suggested action: Evaluate maintenance and service-related engagement opportunities.

**P3 — Monitor**

Other customers with identified purchasing gaps who do not meet the earlier priority conditions.

Suggested action: Monitor purchasing behavior and evaluate future engagement opportunities.

### Important Considerations

These priority levels are preliminary business rules, not predictions of purchase probability.

They have not been validated against campaign outcomes, service requirements, or customer responses.

The model does not yet incorporate:

- Equipment maintenance intervals.
- Warranty conditions.
- Agricultural seasonality.
- Product compatibility.
- Customer contact history.
- Purchase behavior outside the selected window.
- Profitability of potential cross-selling actions.

The `PARTS_OPPORTUNITY` category currently falls into `P3_MONITOR` under the implemented rules, regardless of implement purchase age.

This may be refined in future versions.

---

## 6. Exploratory Findings

The 22 identified opportunity customers generated approximately **R$ 369,119.53** in revenue during the analyzed 12-month period.

This represents their observed revenue, not projected additional cross-selling revenue.

### Revenue by Opportunity Type

| Opportunity Type | Customers | Revenue (BRL) |
|---|---:|---:|
| Parts and services | 11 | R$ 124,522.00 |
| Services | 10 | R$ 234,405.53 |
| Parts | 1 | R$ 10,192.00 |
| **Total** | **22** | **R$ 369,119.53** |

### RFM Distribution

| RFM Segment | Customers |
|---|---:|
| At Risk | 12 |
| High-Value Occasional | 6 |
| Loyal Customers | 1 |
| VIP | 1 |
| New Customers | 1 |
| Promising | 1 |
| **Total** | **22** |

### Key Findings

**Finding 1 — Retention and after-sales opportunities overlap.**

Ten of the eleven customers without parts or services purchases belong to the At Risk segment.

This suggests that commercial follow-up may address both relationship retention and potential complementary product needs.

**Finding 2 — Services opportunities include valuable customers.**

The services opportunity group represents approximately R$ 234.4 thousand in observed 12-month revenue.

Some customers in this group belong to commercially valuable RFM segments.

**Finding 3 — Purchase timing matters.**

The time elapsed since the latest implement purchase differs across opportunity types.

A customer who purchased an implement recently should not automatically receive the same commercial urgency as a customer with a much older purchase.

### Interpretation Limitation

These findings are descriptive and exploratory.

They do not establish causal relationships, predict future purchases, or quantify incremental revenue from commercial campaigns.

---

## 7. Validation and Quality Checks

The following checks were completed during development.

| Validation | Result |
|---|---|
| Implement buyer population | 49 customers |
| Parts penetration | 75.51% |
| Services penetration | 57.14% |
| Opportunity identification | 22 customers |
| Priority P1 | 10 customers |
| Priority P2 | 7 customers |
| Priority P3 | 5 customers |
| Opportunity and priority totals | Consistent |

The analyses were executed in HeidiSQL against the project database.

The validated results correspond to the fixed analytical snapshot ending on 2026-09-03.

Future source-data updates may change the results even when the SQL logic remains unchanged.

---

## 8. Analytical Architecture

The commercial analysis follows this logical process:

```text
Unified Sales Data
vw_sales_unified_classified
          |
          v
Customer Purchase Flags
IMPLEMENTOS / PECAS / SERVICOS
          |
          +----------------------+
          |                      |
          v                      v
Penetration Analysis       Opportunity Identification
Script 01                  Script 02
                                 |
                                 v
                         RFM v2 Enrichment
                         vw_customer_segments_v2
                                 |
                                 v
                         Commercial Prioritization
                         Script 03
                                 |
                                 v
                         Potential Commercial Actions
```

The three SQL files are standalone analytical queries rather than database views that directly depend on one another.

Scripts 02 and 03 reuse the same customer purchase classification logic.

This duplication preserves their independent execution but may be refactored into reusable analytical views during future development.

---

## 9. Data Privacy

The project uses real business data.

Only SQL definitions, methodological documentation, and aggregated analytical results should be published in the public repository.

Customer-level outputs containing real identities, documents, or sensitive business information must remain private.

The consolidated `customer_identity_id` should be treated as an internal identifier rather than a guarantee of anonymization.

---

## 10. Future Improvements

### Reusable Analytical Views

Move repeated purchase flag calculations into a reusable customer-level view.

This would reduce duplicated SQL logic and simplify future maintenance.

### Dynamic Reference Dates

Replace hard-coded analytical dates with configurable reference periods.

This would support automated monthly or quarterly updates.

### Enhanced Commercial Prioritization

Consider incorporating:

- RFM segment and score.
- Customer profitability.
- Implement purchase age.
- Product and equipment characteristics.
- Expected maintenance cycles.
- Historical after-sales engagement.
- Customer relationship status.

### Campaign Performance Measurement

Track commercial actions and outcomes to assess:

- Customer contact rate.
- Response rate.
- Conversion rate.
- Incremental revenue.
- Incremental profit.
- Customer reactivation.

### Dashboard Integration

Create interactive dashboards for:

- Parts and services penetration.
- Cross-selling opportunity distribution.
- RFM segment composition.
- Commercial priority monitoring.
- Customer relationship follow-up.

These are proposed enhancements and are not implemented in the current SQL scripts.

---

## Conclusion

The Commercial Analysis layer extends the Customer Intelligence project beyond descriptive customer segmentation.

By integrating purchasing behavior, product group relationships, customer RFM profiles, and rule-based priorities, the analyses identify potential opportunities for after-sales engagement and cross-selling.

The validated analytical snapshot identified:

- **49 implement buyers**
- **22 customers with potential cross-selling opportunities**
- **10 high-priority customers**
- **7 medium-priority customers**
- **5 customers requiring monitoring**

The results provide an initial, transparent foundation for commercial decision support.

Further validation with operational and campaign data is required before treating these opportunities as confirmed sales potential.
