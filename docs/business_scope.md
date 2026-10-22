# Project Scope — Customer Intelligence for Agricultural Machinery Retail

## 1. Project Overview

**Project:** Customer Intelligence for Agricultural Machinery Retail  
**Industry:** Agricultural machinery, implements, replacement parts, lubricants and related services  
**Primary tools:** SQL (MariaDB/HeidiSQL), with Python and Power BI considered for subsequent stages  
**Project type:** End-to-end business intelligence and customer analytics portfolio project

The project transforms transactional data from a family-operated agricultural retail and service business into a consolidated customer intelligence layer. It aims to support evidence-based commercial decisions through customer identification, purchase-behavior analysis, segmentation and identification of opportunities for retention, reactivation and cross-selling.

## 2. Business Problem

Sales and customer information was fragmented across two ERP systems and multiple customer registrations. This made it difficult to reliably answer questions such as:

- Who are the most valuable customers, and how is value distributed across the portfolio?
- Which customers are active, becoming less active or historically valuable but inactive?
- How do purchasing patterns differ between parts, implements, tractors and services?
- Which customers buy equipment but do not purchase related parts or services within the observed period?
- Which customer groups deserve commercial follow-up, subject to business validation?

A single transaction-based revenue ranking cannot adequately describe customers with different purchasing cycles or incomplete cost information.

## 3. Objectives

### Primary objective

Build a reliable, reusable customer-level analytical foundation and segmentation framework that supports actionable commercial analysis.

### Supporting objectives

1. Integrate historical transactions from the legacy and current ERPs.
2. Resolve duplicate operational customer registrations into shared analytical identities.
3. Standardize analytical product groups across both systems, including services.
4. Calculate consistent revenue, known profit, transaction frequency, recency and product-mix metrics.
5. Develop and evaluate versioned RFM and commercial customer segments.
6. Identify and quantify potential reactivation and cross-selling audiences without equating observed inactivity with confirmed lost business.
7. Document data quality, analytical decisions and limitations so that results are reproducible.
8. Prepare a foundation for future reporting and dashboard development.

## 4. Data Sources and Coverage

| Source | System | Main coverage |
|---|---|---|
| Legacy ERP | Firebird | Historical product and service sale items, 2018–2024 |
| Current ERP | MariaDB | More recent product and service sale items, 2024–2026 |
| Customer identity bridge | Integrated analytical layer | Maps source-system registration IDs to a common `customer_identity_id` |
| Product classification mappings | Integrated analytical layer | Standardized analytical product groups and manual overrides |

**Validated integrated snapshot:** 2018-01-02 through 2026-09-03.  
**Integrated sale-item rows:** 291,024.  
**Integrated analytical revenue:** approximately R$35.88 million.  
**Identifiable customer identities:** 3,109.  
**Anonymous transactions:** retained for applicable sales and product analyses but excluded from customer-level segmentation.

The two source systems overlap in calendar coverage; migration-related duplicate transactions are excluded from the integrated analytical layer according to the documented integration rules. Figures refer to the validated snapshot and may change with subsequent refreshes or corrections.

## 5. Analytical Scope

### Included

- Historical product and service transactions in the integrated sales layer.
- Cross-ERP customer identity resolution using normalized CPF/CNPJ-derived document hashes and a registration bridge.
- Source-aware transaction identification and historical sales aggregation.
- Product group normalization, including mappings and overrides.
- Customer-level historical and trailing-12-month revenue and purchasing behavior.
- RFM v2 scoring and mutually exclusive customer segmentation.
- Product-group mix and observed co-purchasing of implements, parts and services.
- Exploratory investigation of after-sales and reactivation opportunities.
- Data-quality checks and reconciliation of analytical totals.

### Outside the current scope / not yet delivered

- Production CRM integration or automated marketing campaign execution.
- Causal attribution of sales to campaigns or after-sales actions.
- Predictive churn, customer lifetime value or recommendation models.
- Complete profitability accounting for service transactions without reliable cost data.
- Confirming purchases made from competitors or the customer's actual replacement/maintenance needs.
- A finished production Power BI dashboard; visualization is a planned next phase.

## 6. Core Analytical Model

| Object | Purpose |
|---|---|
| `dim_customer_identity` | Shared analytical customer identity |
| `bridge_customer_registration` | Connects ERP-specific registrations to customer identities |
| `vw_sales_unified_classified` | Unified item-level sales and services, with source and analytical group |
| `vw_customer_historical_profile` | Historical customer purchasing and value metrics |
| `vw_customer_rfm_base_v2` | Recency, frequency and monetary measures for the current snapshot |
| `vw_customer_rfm_scores_v2` | Versioned RFM scoring |
| `vw_customer_segments_v2` | Mutually exclusive commercial customer segments |

Supporting source-specific sales views, classification mapping tables and override tables are documented in `docs/data_dictionary.md` and `docs/business_rules.md`.

## 7. Snapshot and Measurement Rules

**RFM reference date:** 2026-09-03.  
**Trailing 12-month window:** 2025-09-04 to 2026-09-03, inclusive.  
**Recency:** Days between the reference date and the customer's last observed purchase in the historical analytical dataset.  
**Frequency:** Distinct sales in the 12-month window, using a source-aware transaction key.  
**Monetary:** Customer revenue in the same 12-month window.  
**Profit:** Known item-level profit; missing or unreliable service costs are not silently assumed to be zero.

The snapshot contains **1,406 customers active within the 12-month window** and **1,703 without a recorded purchase in that window**. Segmentation labels are analytical heuristics, not validated predictions of customer churn.

## 8. Key Findings to Date

### Customer segmentation

The current RFM v2 framework assigns all 3,109 identified customers to 11 mutually exclusive segments. The **120 VIP customers** generated approximately **R$2.31 million**, or **55.2%**, of identified-customer revenue during the 12-month window. These results suggest that a relatively small active segment contributes a large share of recent revenue.

### Product mix

During the same window, **PEÇAS** generated approximately **R$1.76 million** in revenue, **IMPLEMENTOS** approximately **R$998 thousand**, and **SERVIÇOS** approximately **R$604 thousand**. The groups exhibit different purchase frequencies and ticket sizes, so recency and frequency must be interpreted in the context of the products and services purchased.

### Potential cross-selling opportunities

Of **49 customers** who purchased IMPLEMENTOS during the window:

- 37 also purchased PEÇAS.
- 28 also purchased SERVIÇOS.
- 27 purchased both PEÇAS and SERVIÇOS.
- 11 purchased neither PEÇAS nor SERVIÇOS during that window.

Among those 11 customers, **six had previously purchased parts and/or services** in the available historical data, while **five had no recorded purchases in those categories**. Four of the six historically engaged customers had at least four distinct parts transactions. This provides a reviewable audience for commercial investigation, not proof of unmet demand or lost sales.

**Important distinction:** Same-window co-purchasing does not establish that parts or services were purchased *after* an implement. A temporal after-sales conversion analysis requires explicit transaction ordering and comparable follow-up periods.

## 9. Data Quality and Analytical Limitations

- Operational customer registration IDs do not reliably represent unique customers; analytical identities depend on available and valid documents.
- Anonymous purchases cannot be assigned to identified customer profiles.
- Some analytical product classifications remain pending or require review.
- Missing or unreliable service cost prevents complete profit measurement; `SUM(profit)` represents known profit only.
- Returns and their treatment in frequency/recency metrics require continued validation.
- RFM thresholds and commercial segment definitions are versioned business rules rather than universal benchmarks.
- Equipment purchases often have longer cycles than parts purchases; an apparently inactive equipment customer is not necessarily lost.
- The observed dataset cannot reveal competitor purchases, service requirements or the outcome of commercial contact.

See `docs/business_rules.md` for the implemented rules and `docs/data_dictionary.md` for field-level definitions.

## 10. Deliverables and Status

| Deliverable | Status |
|---|---|
| Historical ERP integration and customer identity bridge | Completed for the validated snapshot |
| Unified classified sales layer | Completed, with remaining classification checks |
| Historical customer profile | Completed |
| RFM v2 measures, scores and customer segments | Completed |
| Initial product-mix and cross-selling analysis | Completed |
| Business insights and methodological documentation | In progress / periodically updated |
| Reusable product-group behavior and commercial opportunity layer | Planned / to be refined |
| Power BI dashboard and executive presentation | Planned |

## 11. Success Criteria

The project will be considered analytically successful when it can:

1. Reconcile core integrated sales totals and clearly identify exceptions.
2. Produce one consistent profile for each identifiable customer across both ERPs.
3. Reproduce RFM metrics and segmentation from documented SQL rules.
4. Explain why customer groups differ in revenue, activity and product mix.
5. Generate actionable, reviewable customer lists with clear limitations.
6. Present the analysis through understandable documentation and, in a later stage, a dashboard.

## 12. Repository Documentation

- `README.md` — project introduction and navigation.
- `docs/project_scope.md` — objectives, scope, deliverables and limitations (this document).
- `docs/business_questions.md` — business questions guiding analysis.
- `docs/business_rules.md` — analytical assumptions, filters and scoring rules.
- `docs/data_dictionary.md` — tables, views, fields and metric definitions.
- `docs/insights.md` — evidence-based findings and recommendations.
- `docs/project_journal.md` — chronology of decisions, issues and progress.
- `sql/` — version-controlled SQL scripts (to be populated and maintained).

## 13. Guiding Principle

**Business question → Data validation → SQL analysis → Evidence → Business interpretation → Recommendation.**

The goal is not merely to build dashboards, but to establish a trustworthy analytical foundation that helps the business understand customers and prioritize commercial decisions.
