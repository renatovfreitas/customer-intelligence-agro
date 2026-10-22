# Project Journal

This journal documents the evolution of the project from its initial planning to the final business solution.

---

# Sprint 1 — Project Definition

## Objective

Define the project scope and establish a structured Business Intelligence workflow.

## Activities

* Defined the business problem.
* Selected Customer Intelligence as the main project objective.
* Created the GitHub repository.
* Organized the project structure.
* Defined the initial documentation.
* Identified available datasets.
* Defined the initial business questions.

## Deliverables

* GitHub repository
* README
* Project Scope
* Data Dictionary
* Business Questions
* Business Rules
* Project Journal

---

# Sprint 2 — Data Understanding

## Objective

Understand the available sales data and prepare the first analytical dataset.

## Activities

* Extracted product sales from the transactional database.
* Identified dataset granularity.
* Confirmed that each row represents one sold product.
* Validated available customer, product and sales information.
* Investigated relationships between sales, customers, products and product subgroups.
* Identified limitations in the available historical data.

## Main Findings

* The sales dataset contains approximately 24,000 product-level records.
* One sales transaction may contain multiple products.
* Counting transaction rows does not represent the actual number of sales; sales must be counted using distinct sale controls.
* The current ERP contains transaction history only from August 2024 onward due to a previous system migration.
* Customers whose first recorded transaction occurs during the analyzed period cannot necessarily be classified as new customers.

---

# Sprint 3 — Exploratory Analysis

## Objective

Perform the first customer analyses and identify relevant customer-level metrics.

## Activities

* Calculated revenue by customer.
* Calculated profit by customer.
* Calculated purchase frequency.
* Calculated customer recency.
* Identified customers with long periods without purchases.
* Compared revenue and profitability rankings.
* Investigated differences between customer registration IDs and actual customers.

## Main Findings

* Initial analyses were affected by duplicate customer registrations.
* The same customer could exist under multiple ERP registration IDs.
* Customer rankings changed after customer consolidation.
* Data quality was identified as a critical requirement before performing customer segmentation.

---

# Sprint 4 — Data Preparation and Analytical Layer

## Objective

Improve data quality and create a reusable analytical foundation for customer analysis and segmentation.

## Activities

* Consolidated duplicate customer registrations.
* Changed analytical customer identification from Customer ID to Customer Name + CPF/CNPJ.
* Created a standardized customer key.
* Investigated duplicate product subgroup registrations.
* Reorganized detailed ERP product subgroups into broader Product Groups.
* Created a Product Group mapping dimension.
* Created a product-level override mechanism for products requiring manual classification.
* Created the `vw_sales_enriched` analytical view.
* Created the `vw_customer_master` customer-level analytical view.
* Validated SQL results against the previous Excel-based Customer Master analysis.
* Corrected the Distinct Product Subcategories metric to represent business categories rather than duplicated technical ERP IDs.

## Deliverables

### `vw_sales_enriched`

Analytical sales-level view containing:

* Customer identification
* Sale information
* Product information
* Product subgroup
* Product group
* Quantity
* Revenue
* Cost
* Profit

### `vw_customer_master`

Customer-level analytical view containing:

* Revenue
* Profit
* Profit Margin
* Sales Quantity
* Items Quantity
* Distinct Products
* Distinct Product Subcategories
* Distinct Product Groups
* Average Ticket
* Average Items per Sale
* Average Revenue per Item
* Average Profit per Sale
* Average Profit per Item
* Last Purchase
* Days Since Last Purchase

## Main Findings

* Customer consolidation significantly improved analytical accuracy.
* ERP technical identifiers do not always represent unique business entities.
* Product hierarchy significantly simplified commercial analysis.
* Analytical views provide a more reliable and reusable foundation than repeatedly querying operational ERP tables.
* Business definitions must be validated before building dashboards or segmentation models.

---

# Sprint 5 — Customer Exploratory Data Analysis

## Objective

Understand customer behavior, value concentration, purchase frequency, recency, profitability and average ticket before defining customer segmentation rules.

## Activities

* Analyzed the distribution of customer revenue.
* Analyzed purchase frequency.
* Analyzed customer recency.
* Analyzed average ticket.
* Performed Pareto analysis of customer revenue.
* Compared revenue concentration with profit concentration.
* Analyzed profitability among high-revenue customers.
* Investigated one-purchase and low-frequency customers.
* Cross-analyzed Recency and Frequency.
* Identified historically frequent customers with high current recency.
* Analyzed Average Ticket by customer behavior.
* Compared Product Groups by revenue, ticket and profitability.
* Investigated the relationship between low frequency and high-value implement purchases.
* Identified potential customer reactivation opportunities.
* Identified a potential post-sale cross-selling hypothesis.

## Dataset Profile

The analyzed customer base contains:

* 1,953 customers
* Minimum customer revenue: R$0.50
* Maximum customer revenue: approximately R$227,430
* Average customer revenue: approximately R$3,643
* Minimum purchase frequency: 1
* Maximum purchase frequency: 498
* Average purchase frequency: approximately 9.7
* Minimum recency: 1 day
* Maximum recency: 706 days
* Average recency: approximately 246 days
* Overall average ticket: approximately R$590

## Main Findings

### Customer Value Concentration

* The top 20 customers account for approximately 21% of total revenue.
* Approximately 80% of total revenue is generated by 334 customers, representing about 17% of the customer base.
* Customers generating R$10,000 or more account for nearly 70% of total revenue.

### Revenue vs Profit

* The top 334 customers by revenue generate approximately 80% of revenue and 75.15% of total profit.
* The top 391 customers by profit generate 80% of total profit and 82.47% of total revenue.
* Revenue and profit are strongly related but are not equivalent measures of customer value.
* Most high-revenue customers maintain healthy profit margins.
* Revenue was therefore retained as the future RFM Monetary metric, while Profit and Profit Margin will be used as complementary customer-value indicators.

### Purchase Frequency

* 627 customers, approximately 32% of the customer base, recorded only one purchase during the available period.
* These customers account for approximately 7% of total revenue.
* Customers with four or more purchases generate approximately 85% of total revenue.
* Customers with more than 21 purchases generate nearly 50% of total revenue.
* Purchase frequency is strongly associated with customer economic value.

### Recency

* Customers purchasing within the last 90 days represent approximately 30% of the customer base but generate more than 61% of historical revenue.
* Customers purchasing within the last 30 days represent approximately 14.4% of customers and 40.4% of revenue.
* 573 customers, approximately 29.3% of the customer base, have more than 365 days of recency and account for approximately 10.1% of historical revenue.
* Recency is an important customer-value indicator but should not be interpreted independently from historical frequency and product behavior.

### Reactivation Opportunities

* 79 customers with more than 365 days of recency had previously completed at least four purchases during the analyzed period.
* These customers generated approximately R$198,000 in historical revenue and R$79,000 in profit.
* Their average historical frequency was approximately 7.9 purchases.
* Previously frequent customers with high current recency represent stronger reactivation candidates than customers selected using recency alone.

### Low-Frequency / High-Value Customers

* 36 customers with three or fewer purchases generated approximately R$573,000 in revenue.
* Most high-value, low-frequency customers purchased implements.
* Low purchase frequency may therefore reflect long product replacement cycles rather than customer disengagement.

### Average Ticket

* The overall average ticket of approximately R$590 hides substantially different customer purchasing patterns.
* Customers with average tickets of R$10,000 or more averaged approximately 1.5 purchases.
* Customers with average tickets between R$500 and R$999 averaged approximately 14.3 purchases.
* High ticket does not necessarily indicate high customer engagement or purchase frequency.

### Product Behavior

Product Groups demonstrate substantially different economic behaviors.

For example:

* Parts generated approximately R$3.59 million in revenue with an average group ticket of approximately R$218 and a profit margin of approximately 44.9%.
* Implements generated approximately R$2.01 million in revenue with an average group ticket of approximately R$14,183 and a profit margin of approximately 18.7%.

These differences demonstrate that customer Recency, Frequency and Average Ticket must be interpreted within the context of the products purchased.

## Business Hypothesis Identified

Implement buyers may represent post-sale cross-selling opportunities for recurring categories such as:

* Parts
* Lubricants
* Related recurring products

Future analysis should determine whether implement buyers subsequently purchase these categories and identify customers whose recurring-product potential is not currently being captured.

## Analytical Decision

The initial plan was to use a traditional RFM model:

`Recency + Frequency + Monetary`

Customer EDA demonstrated that RFM remains useful but requires additional business context.

The future customer segmentation approach will therefore consider:

`RFM + Profitability + Product Behavior`

Revenue will remain the Monetary component, while Profit, Profit Margin, Average Ticket and Product Mix will provide complementary information for customer profiling and commercial prioritization.

## Sprint Status

**Completed**

---

# Sprint 6 — Customer Profiling and Commercial Segmentation

## Objective

Transform the findings from Customer EDA into customer-level behavioral features and commercially meaningful customer segments.

## Activities

* Defined the 12-month current-behavior window (08 July 2025 to 07 July 2026).
* Created `vw_customer_behavior_12m`, `vw_customer_profile_base` and `vw_customer_profile`.
* Defined and validated RFM v1 scoring rules.
* Retained Revenue as Monetary and Profitability as complementary customer-value information.
* Created Product Behavior views and identified each active customer's dominant Product Group.
* Validated that similar RFM profiles can represent different commercial behaviors by Product Group.
* Tested after-sales behavior using purchase sequence rather than product co-occurrence.
* Evaluated parts purchases after implement purchases by elapsed observation time.
* Defined, tested and validated Commercial Segments v1.
* Created `vw_customer_commercial_segment`.
* Confirmed exactly one segment for each of the 1,953 identified customers.

## RFM v1

### Recency
* R5: 0–30 days
* R4: 31–90 days
* R3: 91–180 days
* R2: 181–365 days
* R1: more than 365 days

### Frequency — 12 months
* F5: 11+ sales
* F4: 4–10 sales
* F3: 2–3 sales
* F2: 1 sale
* F1: 0 sales

### Monetary — 12 months
* M5: R$10,000+
* M4: R$3,000–9,999.99
* M3: R$500–2,999.99
* M2: R$0.01–499.99
* M1: R$0

## Product Behavior Findings

Among the 1,380 identified customers active in the 12-month window:

* 985 customers generated at least 80% of revenue from one dominant Product Group.
* 239 additional customers generated between 60% and 80% from one dominant Product Group.
* 88.70% therefore generated at least 60% of revenue from one dominant Product Group.
* PEÇAS was dominant for 1,104 customers, IMPLEMENTOS for 47 and TRATORES for one.

Product Behavior proved necessary for interpreting RFM because similar recency can represent a normal equipment purchasing cycle or a meaningful decline in recurring parts activity.

## After-Sales Findings

Fifty identified customers purchased IMPLEMENTOS during the 12-month analytical window. Twenty-five recorded at least one subsequent PEÇAS purchase, generating approximately R$51,600.85 in subsequent parts revenue.

Observed parts penetration increased with available follow-up time:

* <90 days: 2 of 11 customers (18.18%).
* 90–179 days: 7 of 15 customers (46.67%).
* 180+ days: 16 of 24 customers (66.67%).

Commercial Segments v1 therefore uses 180 days as an operational maturity threshold for an After-Sales Opportunity. This is a versioned analytical rule supported by the observed pattern, not a proven causal conversion threshold.

## Commercial Segments v1

Rules are evaluated in precedence order:

1. **AFTER-SALES OPPORTUNITY** — Implement buyer with at least 180 days since the first observed implement purchase and no subsequent PEÇAS purchase.
2. **RECURRING COOLING DOWN** — PEÇAS-dominant customer with R <= 3 and F >= 4.
3. **HIGH VALUE EQUIPMENT** — IMPLEMENTOS- or TRATORES-dominant customer with M >= 4.
4. **CORE ACTIVE** — R >= 4, F >= 4 and M >= 3.
5. **HIGH VALUE OCCASIONAL** — M >= 4 and not captured above.
6. **DORMANT HIGH POTENTIAL** — R = 1 and historical frequency >= 4 or historical revenue >= R$3,000.
7. **LOW ENGAGEMENT** — Remaining customer base.

## Segment Validation

| Commercial Segment | Customers | Customer % | Revenue 12m | Profit 12m | Avg. Recency | Avg. Frequency 12m |
|---|---:|---:|---:|---:|---:|---:|
| CORE ACTIVE | 307 | 15.72% | R$1,558,485 | R$624,656 | 32.6 | 18.19 |
| HIGH VALUE EQUIPMENT | 38 | 1.95% | R$1,144,674 | R$236,132 | 77.5 | 11.71 |
| RECURRING COOLING DOWN | 136 | 6.96% | R$336,072 | R$134,968 | 151.4 | 9.52 |
| LOW ENGAGEMENT | 1,329 | 68.05% | R$310,936 | R$127,092 | 291.2 | 1.29 |
| AFTER-SALES OPPORTUNITY | 8 | 0.41% | R$113,742 | R$21,974 | 239.0 | 1.38 |
| HIGH VALUE OCCASIONAL | 22 | 1.13% | R$109,944 | R$40,295 | 139.7 | 2.82 |
| DORMANT HIGH POTENTIAL | 113 | 5.79% | R$0 | R$0 | 491.6 | 0.00 |

CORE ACTIVE, HIGH VALUE EQUIPMENT and RECURRING COOLING DOWN together represent 481 customers (approximately 24.6% of the portfolio) and about 85% of identified-customer 12-month revenue.

`LOW ENGAGEMENT` is descriptive, not a recommendation to ignore or deprioritize every customer in the segment.

## Deliverables

* `vw_customer_behavior_12m`
* `vw_customer_profile_base`
* `vw_customer_profile`
* `vw_customer_product_group`
* `vw_customer_product_total`
* `vw_customer_product_mix`
* `vw_customer_product_behavior`
* `vw_customer_first_implement_purchase`
* `vw_customer_after_sales`
* `vw_customer_commercial_segment`
* RFM v1 scoring logic
* Product Behavior analysis
* After-sales analysis
* Commercial Segments v1
* Updated Business Rules and Business Insights

## Sprint Status

**Completed**

---

# Sprint 7 — Historical Data Assessment and Integration

## Objective

Assess whether legacy ERP data dating back to 2018 can be reliably integrated with the current analytical model and extend the available customer history where sufficient matching confidence exists.

## Planned Activities

* Profile legacy ERP sales and customer data.
* Evaluate differences between legacy and current customer identifiers.
* Develop customer entity-resolution rules using attributes available in both systems.
* Define confidence levels for customer matches.
* Manually validate ambiguous high-value matches.
* Determine which historical metrics can be integrated reliably.
* Preserve aggregate historical analysis where customer-level matching is not sufficiently reliable.

The legacy ERP database was assessed before historical data was merged
with the current analytical model.

Initial investigation identified several differences between the legacy
and current ERP structures, including customer duplication, historical
service representation, inventory movement types, returns and historical
cost behavior.

Customer matching was performed using normalized CPF/CNPJ. To avoid
transferring plaintext customer documents between databases, documents
were converted locally to SHA-256 hashes before cross-system matching.

The legacy buyer population contained 2,471 distinct identifiable
document identities, of which 2,465 were found in the current ERP
(99.76%).

The analysis also revealed substantial duplication of operational
customer registrations. A separate customer identity dimension and
registration bridge were therefore introduced instead of using ERP
customer IDs as analytical customer identifiers.

Legacy revenue logic was independently reconciled against sale-header
totals. After accounting for returns, 90,795 of 90,815 sales reconciled
within R$0.01 (99.978%), with only R$67.78 net difference across the
entire analyzed period.

Following validation, the legacy analytical layer was frozen with the
following migration-control totals:

- Rows: 228,083
- Sales: 90,815
- First sale: 2018-01-02
- Last sale: 2024-07-15
- Revenue: R$26,813,612.49
- Known profit: R$7,701,172.49

These totals served as reconciliation checkpoints for the subsequent
legacy-to-MariaDB integration. The figures above describe the legacy
source extract, not the entire unified analytical dataset.



## Integration Completion — Unified Historical Sales

**Status: Completed (supersedes the initial planned integration activities above).**

The validated legacy and current ERP sales were combined into
`vw_sales_unified_classified`, with source-specific customer registrations
resolved through `bridge_customer_registration` and a common
`customer_identity_id`. Products and services are both represented in the
unified analytical layer.

### Validated unified dataset (snapshot ending 2026-09-03)

| Source / item type | Sale-item rows | Revenue |
|---|---:|---:|
| Legacy ERP — products | 206,187 | R$23,903,897.93 |
| Legacy ERP — services | 21,894 | R$2,909,677.57 |
| Current ERP — products | 56,762 | R$7,701,076.27 |
| Current ERP — services | 6,181 | R$1,360,383.18 |
| **Unified total** | **291,024** | **R$35,875,034.95** |

- Unified transaction-date coverage: **2018-01-02 to 2026-09-03**.
- **3,109 identifiable customers** in the unified customer population.
- Identifiable-customer revenue: **R$34,791,961.29** in the sales layer.
- Anonymous sales: **28,838 sale-item rows**, totaling **R$1,083,073.66**;
  excluded from customer-level segmentation, not from total sales reporting.
- Historical and current services are included in revenue, but service cost
  coverage is incomplete. `profit = NULL` where cost is unavailable; known
  profit must not be presented as total profit.
- Classification audit: **289,227 CONFIRMED** items (R$35,451,971.33),
  **1,546 PENDING** (R$385,418.51), and **251 REVIEW** (R$37,645.11).
- Current ERP service date anomaly (1899-12-30, item 5141) was corrected in
  the analytical layer to 2025-12-17. Four current-service rows required
  `vr_total` rather than quantity × unit price (R$790 aggregate difference).
- Legacy migrated duplicates were excluded to avoid double counting.

**Caveat:** Transaction-type handling, particularly the influence of returns
on customer purchase frequency and recency, merits a separate audit before
operational deployment.

---

# Sprint 8 — Unified Customer Behavior and Segmentation v2

## Objective

Rebuild customer behavior and segmentation using the integrated 2018–2026
history, while retaining a fixed and reproducible 12-month current-behavior
window.

## Activities Completed

- Created and validated `vw_customer_historical_profile`.
- Created `vw_customer_rfm_base_v2`, `vw_customer_rfm_scores_v2`, and
  `vw_customer_segments_v2`.
- Separated full-history customer attributes from 12-month Frequency and
  Monetary metrics.
- Recalibrated RFM scores for the expanded historical population.
- Tested the segmentation for coverage and mutually exclusive assignment.
- Analyzed revenue distribution by analytical product group.
- Evaluated PEÇAS and SERVICOS cross-purchasing among IMPLEMENTOS buyers.
- Investigated historical category relationships for implement buyers who
  had no parts or service purchases in the 12-month window.

## Fixed Analysis Dates

- Reference date: **2026-09-03**.
- 12-month window: **2025-09-04 through 2026-09-03**, inclusive.
- Historical profile: all available valid history from **2018-01-02**.

## RFM v2 Rules

**Recency** (days since last observed purchase at reference date):
R5 = 0–30; R4 = 31–90; R3 = 91–180; R2 = 181–365; R1 = >365.

**Frequency** (distinct transactions in the 12-month window):
F5 = 11+; F4 = 6–10; F3 = 4–5; F2 = 2–3; F1 = 0–1.
A distinct transaction is identified by source system plus sale control,
not sale-item row count.

**Monetary** (12-month revenue):
M5 = R$25,000+; M4 = R$5,000–24,999.99;
M3 = R$1,000–4,999.99; M2 = R$500–999.99; M1 = below R$500.

Revenue is the Monetary measure. Profit is complementary and may be
incomplete when service costs are unavailable.

## RFM Base Validation

| Metric | Result |
|---|---:|
| Identifiable customers | 3,109 |
| Active in the fixed 12-month window | 1,406 |
| No transactions in that window | 1,703 |
| Identified-customer 12-month revenue | R$4,194,807.91 |
| Maximum 12-month distinct purchases | 237 |
| Maximum 12-month customer revenue | R$193,736.21 |

The historical-profile aggregate of customer revenue was R$34,791,961.22;
the R$0.07 difference from identifiable sales-layer revenue is attributable
to aggregation/rounding and should remain visible in reconciliation checks.

## Customer Segments v2

`vw_customer_segments_v2` assigns exactly one segment per identified
customer using ordered rules: VIP; Loyal Customers; High-Value Occasional;
New Customers; Promising; At Risk; Active Occasional; High-Value Lost;
Former Regular Customers; Recently Inactive; Long-Term Inactive.

| Segment | Customers | Revenue in 12 months |
|---|---:|---:|
| VIP | 120 | R$2,314,759.87 |
| Loyal Customers | 303 | R$825,249.29 |
| At Risk | 137 | R$439,692.39 |
| High-Value Occasional | 19 | R$281,269.99 |
| Active Occasional | 564 | R$183,748.61 |
| Promising | 223 | R$132,979.58 |
| New Customers | 43 | R$17,108.18 |
| Recently Inactive | 437 | R$0.00 |
| Long-Term Inactive | 1,040 | R$0.00 |
| Former Regular Customers | 196 | R$0.00 |
| High-Value Lost | 27 | R$0.00 |
| **Total** | **3,109** | **R$4,194,807.91** |

The **120 VIP customers generated approximately 55.2%** of identified
customer revenue during the 12-month window. Segment labels are analytical
heuristics, not verified churn outcomes. In particular, a low-frequency
implement buyer may be labeled At Risk even when their buying cycle is normal.

## Inactive Customer Reactivation Finding

- **1,700 customers** received RFM score 111.
- Of these, **223** had lifetime revenue of at least R$10,000, totaling
  approximately **R$6.64 million** in historical revenue.
- This supports prioritizing dormant relationships by historical value and
  frequency rather than treating all inactive customers as equivalent.

## Product-Group Behavior — 12-Month Snapshot

The 12-month product-group aggregation covered 27,347 sale-item rows and
R$4,194,807.94 in item-level revenue (R$0.03 difference from customer RFM
aggregate due to rounding).

- PEÇAS: **1,286 customers**, **R$1,756,883.24** (41.88%).
- IMPLEMENTOS: **49 customers**, **R$998,078.00** (23.79%).
- SERVICOS: **611 customers**, **R$603,880.40** (14.40%).
- ÓLEOS E LUBRIFICANTES: **405 customers**, **R$270,084.11** (6.44%).
- TRATORES: **1 customer**, **R$188,000.00** (4.48%).

Customer counts overlap between product groups and must not be added.

## Implement Cross-Selling Investigation

Among the **49** identified customers purchasing IMPLEMENTOS during the
12-month window:

| Co-purchase behavior during the window | Customers |
|---|---:|
| PEÇAS and SERVICOS | 27 |
| PEÇAS, but not SERVICOS | 10 |
| SERVICOS, but not PEÇAS | 1 |
| Neither PEÇAS nor SERVICOS | 11 |
| **Total** | **49** |

- **37/49 (75.51%)** bought PEÇAS in the same window.
- **28/49 (57.14%)** bought SERVICOS in the same window.
- The **11** customers with neither category generated **R$115,832** in
  IMPLEMENTOS revenue during the 12-month window.
- Of these 11, **six** had historical purchases of PEÇAS and/or SERVICOS;
  **five** had no such purchase recorded in the available 2018–2026 history.
- Four of the six historically engaged customers had **at least four
  distinct PEÇAS transactions**.
- Customer 4118: 10 historical PEÇAS transactions, 37 items, last PEÇAS
  purchase on 2024-04-29; R$29,500 in recent IMPLEMENTOS revenue.
- Customer 1182: 10 historical PEÇAS transactions and one service
  transaction; last category purchase on 2024-10-29.

**Interpretation:** These are potential category reactivation and
cross-selling leads for commercial review, **not demonstrated lost sales**.
Co-purchase within a 12-month window does not establish purchase order or
causality. The prior Sprint 6 temporal after-sales findings belong to the
older, differently scoped snapshot and must not be merged numerically with
these v2 co-purchase figures.

## Deliverables

- `vw_sales_unified_classified` (unified sales layer).
- `vw_customer_historical_profile`.
- `vw_customer_rfm_base_v2`.
- `vw_customer_rfm_scores_v2`.
- `vw_customer_segments_v2`.
- Product-group behavior and implement cross-selling SQL analyses.
- Updated `docs/insights.md`, `docs/business_rules.md`, and
  `docs/data_dictionary.md`; newly created `docs/project_scope.md`.

## Outstanding Validation and Future Improvements

- Audit returns and their effects on purchase frequency/recency.
- Validate remaining PENDING/REVIEW product classifications.
- Distinguish normal equipment purchase cycles from genuine customer risk.
- Develop reusable category-level customer behavior views rather than
  manually maintained lists of customer IDs.
- Add purchase-sequence and comparable observation-window analysis to the
  integrated after-sales dataset.
- Validate customer-level profit coverage before complete profitability
  rankings or margin-based operational decisions.

## Sprint Status

**Completed for the fixed v2 analytical snapshot; operationalization pending.**

---

# Sprint 9 — Power BI and Operational Integration

## Objective

Transform the analytical model into a continuously updated Business Intelligence solution.

## Planned Activities

* Connect the analytical model to the operational ERP database.
* Replace snapshot-specific logic with dynamic date calculations where appropriate.
* Configure automated data refresh.
* Build the Power BI data model.
* Create customer and commercial dashboards.
* Create actionable customer lists.
* Monitor data quality and unclassified products.
* Validate dashboard metrics against the SQL analytical layer.

## Potential Dashboard Outputs

* Customer Portfolio Overview
* High-Value Customers
* High-Value Customers at Risk
* Customers to Reactivate
* Customer Segments
* Product Mix by Customer
* Revenue and Profit Concentration
* Cross-Selling Opportunities
* Data Quality Monitoring

## Long-Term Goal

Evolve the project from a static portfolio analysis into a continuously updated Customer Intelligence solution capable of supporting commercial decision-making.

---

# Current Status

## Completed

- Sprints 1–6: project definition, current ERP exploration, customer EDA,
  initial RFM and Commercial Segments v1 (historical project milestones).
- Sprint 7: legacy ERP assessment, reconciliation and unified integration.
- Sprint 8: historical customer profile, RFM v2, Customer Segments v2,
  product-group analysis and implement cross-selling investigation.
- Project documentation refresh: insights, business rules, data dictionary,
  and project scope.

## Next

- Prepare reusable customer/product-group behavioral views.
- Complete outstanding data-quality and transaction-type validation.
- Start Sprint 9 — Power BI and Operational Integration.

## Planned

- Power BI semantic model, customer dashboards and actionable customer lists.
- Automated refresh and consistent dynamic reference-date logic.
- SQL-to-dashboard metric reconciliation and executive reporting.

## Future Opportunities

- Comparable 90/180/365-day after-sales cohorts on the unified dataset.
- Lubricants and other recurring-product after-sales analysis.
- Customer lifetime value and reactivation monitoring.
- Predictive customer models once data and business definitions are validated.
