# Customer Intelligence for Agricultural Machinery Retail

**SQL · Data Integration · Customer Analytics · RFM Segmentation · Commercial Intelligence**

## Overview

This portfolio project transforms transactional data from a Brazilian agricultural machinery retailer into a consolidated customer intelligence model. It combines historical sales from two ERP systems to investigate customer value, retention, product purchasing behavior, and potential cross-selling opportunities.

The project follows a business-question-first approach: define a commercial problem, validate the underlying data, develop reusable SQL analyses, and translate results into actionable insights.

**Project status:** Historical integration, customer identity resolution, exploratory analysis, RFM v2, and customer segmentation completed. Power BI reporting and operational refresh are planned.

## Business Questions

- Who are the most valuable customers, and how does revenue differ from known profit?
- Which customers are currently active, inactive, or historically valuable?
- How do purchasing patterns differ between parts, implements, tractors, and services?
- Which implement buyers also purchase parts or services, and which warrant commercial follow-up?
- How can customer data support more targeted retention and sales initiatives?

## Data and Coverage

| Metric | Integrated analytical dataset |
|---|---:|
| Historical period | January 2, 2018 – September 3, 2026 |
| ERP systems | Legacy ERP + Current ERP |
| Sale-item records | 291,024 |
| Total analytical revenue | R$35,875,034.95 |
| Identifiable customers | 3,109 |
| Identified-customer revenue | R$34,791,961.29 |
| Anonymous sale-item records | 28,838 |

The analytical dataset includes **products and services**. One row represents a sale item, not necessarily a distinct transaction. Customer identities are consolidated across ERPs using normalized CPF/CNPJ-derived identity matching and a registration bridge. Anonymous transactions remain relevant to sales analysis but are excluded from customer-level segmentation.

**Privacy:** Operational customer identifiers and personally identifiable information should not be committed to this public repository. Source data is not included here.

## Analytical Architecture

```text
Legacy ERP (2018–2024)        Current ERP (2024–2026)
          |                              |
  Legacy sales staging          Current sales views
          |                              |
          +---------+--------------------+
                    |
       Customer identity dimension
       + registration bridge
                    |
       Unified, classified sales
       (vw_sales_unified_classified)
                    |
          Historical customer profile
                    |
             RFM base v2
                    |
            RFM scores v2
                    |
          Customer segments v2
                    |
      Product behavior / cross-selling
                    |
          Business insights and
          planned Power BI reports
```

The shared analytical identity (`customer_identity_id`) is separate from source ERP customer registration IDs. The unified sales layer retains `source_system` so transaction identifiers can be interpreted correctly across systems.

## Methods and Completed Work

### 1. Data preparation and integration

- Investigated duplicated customer registrations and inconsistent product classification.
- Consolidated customer identities across the two ERP systems.
- Standardized analytical product groups and introduced product-level classification overrides.
- Reconciled legacy sales totals and preserved explicit handling for returns.
- Integrated product and service sale items into a reusable analytical layer.

### 2. Customer value and RFM v2

The fixed RFM snapshot is **September 3, 2026**. Frequency and Monetary cover **September 4, 2025 – September 3, 2026**; Recency uses the most recent recorded purchase across the available history.

| Metric | Result |
|---|---:|
| Identifiable customers | 3,109 |
| Customers active in the 12-month window | 1,406 |
| Customers without purchases in the 12-month window | 1,703 |
| Identified-customer revenue in the 12-month window | R$4,194,807.91 |

The current RFM model scores Recency, Frequency, and Monetary on a 1–5 scale. Revenue is the Monetary input; profit is retained as a complementary metric where costs are reliable.

### 3. Customer segmentation

The current segmentation view (`vw_customer_segments_v2`) assigns customers to mutually exclusive behavioral groups:

| Segment | Customers | 12-month revenue |
|---|---:|---:|
| VIP | 120 | R$2,314,759.87 |
| Loyal Customers | 303 | R$825,249.29 |
| At Risk | 137 | R$439,692.39 |
| High-Value Occasional | 19 | R$281,269.99 |
| Active Occasional | 564 | R$183,748.61 |
| Promising | 223 | R$132,979.58 |
| New Customers | 43 | R$17,108.18 |
| Recently Inactive | 437 | R$0 |
| Long-Term Inactive | 1,040 | R$0 |
| Former Regular Customers | 196 | R$0 |
| High-Value Lost | 27 | R$0 |

**Interpretation caveat:** These are rule-based analytical labels, not churn predictions. Equipment buyers can have naturally long purchase cycles, so recency and frequency must be interpreted alongside product mix.

### 4. Product behavior and cross-selling

Within the 12-month window, **49 identified customers purchased IMPLEMENTOS**:

- 37 also purchased PEÇAS (75.51%).
- 28 also purchased SERVICOS (57.14%).
- 11 purchased neither PEÇAS nor SERVICOS in that window.
- Of those 11, six had previously purchased parts and/or services in the historical dataset; five had no recorded history in those categories.

This is a **same-period category-overlap analysis**, not evidence that parts or services were purchased *after* the implement sale. The earlier project phase also tested purchase sequence separately; its findings and historical assumptions are retained in the documentation. Potential commercial opportunities require review of timing, product needs, and customer context.

## Selected Business Insights

- Reliable customer identity resolution materially changes revenue rankings, purchasing frequency, and inactivity calculations.
- Customer revenue is concentrated: the **120 VIP customers** generated approximately **55%** of identified-customer revenue in the latest 12-month window.
- Customer value cannot be explained by purchase frequency alone: recurring parts buyers and high-ticket equipment buyers have different purchasing cycles.
- Profit is not complete for all transactions because some service costs are unavailable; `SUM(profit)` must be interpreted as **known profit**, not total profit.
- Cross-category behavior reveals commercially reviewable opportunities without assuming that every missing parts or service purchase is a lost sale.

Detailed analyses and qualifications are documented in [`docs/insights.md`](docs/insights.md).

## Technologies

- **SQL / MariaDB (MySQL-compatible):** extraction, transformation, analytical views, reconciliation, and customer segmentation
- **Firebird:** historical ERP data source
- **HeidiSQL:** database exploration and SQL development
- **Git & GitHub:** version control and project documentation
- **Power BI:** planned reporting and interactive dashboards
- **Python:** potential future extension; not a dependency of the completed SQL analyses

## Repository Structure

```text
customer-intelligence-agro/
├── README.md
├── docs/
│   ├── project_scope.md
│   ├── business_questions.md
│   ├── business_rules.md
│   ├── data_dictionary.md
│   ├── insights.md
│   └── project_journal.md
├── sql/
├── data/
│   ├── raw/
│   └── processed/
├── python/
├── powerbi/
├── reports/
└── images/
```

*Folders shown represent the intended repository organization; some may currently contain only `.gitkeep` placeholders. The `sql/` folder should be populated with sanitized, version-controlled SQL scripts as the project is packaged for public review.*

## Documentation

- [`Project Scope`](docs/project_scope.md) — goals, scope, limitations, and deliverables
- [`Business Questions`](docs/business_questions.md) — questions driving the analysis
- [`Business Rules`](docs/business_rules.md) — source filters, integration logic, calculations, and segmentation criteria
- [`Data Dictionary`](docs/data_dictionary.md) — analytical tables, views, fields, and grains
- [`Business Insights`](docs/insights.md) — findings and commercial implications
- [`Project Journal`](docs/project_journal.md) — chronological technical and analytical progress

## Roadmap

**Completed:** initial customer EDA; product classification; historical ERP integration; cross-system identity resolution; unified analytical sales layer; RFM v2; customer segmentation; initial product-group and cross-selling analysis.

**Next:** publish and organize reusable SQL scripts; validate outstanding data-quality and returns questions; develop the Power BI semantic model and dashboards; create actionable customer lists; reconcile reporting metrics against SQL.

**Longer term:** dynamic snapshot dates, automated refresh, additional after-sales cohorts, and more advanced customer-value models.

## Analytical Limitations

1. This is a fixed analytical snapshot ending September 3, 2026, not a live reporting system.
2. Product and service cost availability differs; profit totals can be incomplete.
3. Some product classifications remain pending review.
4. Historical customer identity matching relies on available document identifiers; anonymous sales cannot be attributed reliably to individual customers.
5. RFM and cross-selling labels describe observed behavior, not proven causality or guaranteed commercial demand.
6. Return treatment and source-system sales-status conventions warrant ongoing validation.

## Author

Developed by **Renato Viveiros Freitas** as a Business Intelligence portfolio project focused on applying data analysis to real commercial decisions.
