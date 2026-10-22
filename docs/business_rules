# Analytical Business Rules — Versioned Reference

**Current analytical snapshot:** 03 September 2026  
**Current version:** Integrated Historical Customer Intelligence / RFM v2  
**Status:** The original sections 1–25 below document the project's development, including superseded v1 assumptions. **For the current model, follow the v2 rules in sections 26–35.** When an earlier rule conflicts with a v2 rule, the v2 rule takes precedence. Historical figures are not directly comparable unless their population, period and definitions match.

---

# Analytical Business Rules

This document describes the business and analytical rules adopted throughout the project. These rules were defined during the data understanding and preparation phases to ensure consistent, reliable and business-oriented analyses.

---

# 1. Project Scope

The current version of the project analyzes **completed product sales only**.

Only finalized sales are considered for all analytical views.

Open sales are excluded using the following business rule:

```sql
mv_vendas.em_aberto = 1
```

Service operations (mechanics, welding, lathe services and freight) are intentionally excluded from the current version of the Customer Intelligence analysis in order to maintain a well-defined project scope.

---

# 2. Analysis Period

All analyses are based on transactions between:

**01 August 2024** and **07 July 2026**

This period will remain fixed throughout the current version of the project to guarantee consistency between analyses.

---

# 3. Data Granularity

Each row in the raw sales dataset represents **one individual product sold**.

A single sales transaction may contain multiple products.

Therefore:

* One Sale Control Number = One Sale
* One Sale Item ID = One Product sold

---

# 4. Customer Identification

Customers are analytically identified using the combination of:

* Customer Name
* CPF/CNPJ

The customer registration ID is **not** used as the analytical identifier.

### Reason

During the exploratory analysis it was discovered that several customers possess multiple registration IDs in the operational system.

Using only the registration ID fragmented customer purchase histories and produced incorrect analytical conclusions regarding:

* Revenue
* Profit
* Purchase Frequency
* Customer Ranking
* Customer Inactivity

Consolidating customers using Customer Name + CPF/CNPJ generated significantly more reliable business insights.

---

# 5. Anonymous Customers

Sales without customer identification (for example "* Cliente Não Informado") are excluded from customer segmentation analyses.

### Reason

Without a unique customer identifier it is impossible to evaluate customer behavior, purchasing frequency, recency or profitability.

These transactions may still be considered in future product or sales performance analyses.

---

# 6. Sales Status

Only completed sales are included in this project.

The operational sales table (`mv_vendas`) contains the field `em_aberto`, which indicates whether a sales transaction has been finalized.

Business Rule:

* Include only records where `em_aberto = 1`.

### Reason

Open sales do not represent completed commercial transactions and therefore should not influence customer behavior analyses, profitability calculations or commercial performance indicators.

This filter is applied directly in the analytical base view (`vw_sales_enriched`) to guarantee consistency across all subsequent analytical views.

---

# 7. Revenue Calculation

Revenue is calculated as:

Revenue = Unit Sale Price × Quantity

---

# 8. Profit Calculation

Profit is calculated as:

Profit = (Unit Sale Price − Unit Cost) × Quantity

---

# 9. Sales Quantity

Sales Quantity represents the number of **distinct sales transactions**, not the number of sold items.

Calculation:

COUNT(DISTINCT Sale Control Number)

This prevents multiple products belonging to the same sale from being counted as separate sales.

---

# 10. Customer Master Table

The Customer Master Table is the primary analytical dataset of the project.

Each row represents one unique customer.

The table consolidates customer purchasing behavior into business metrics such as:

* Revenue
* Profit
* Sales Quantity
* Items Quantity
* Distinct Products
* Distinct Product Subgroups
* Distinct Product Groups
* Average Ticket
* Last Purchase
* Days Since Last Purchase

Additional metrics may be incorporated during future project iterations.

---

# 11. Product Hierarchy

The original product classification provided by the ERP system was considered too granular for strategic analysis.

To improve readability and support business decision-making, original product subgroups were manually mapped into broader Product Groups.

Examples include:

* Parts
* Implements
* Tractors
* Oils & Lubricants
* Gardening
* Miscellaneous

This hierarchy is used exclusively for analytical purposes and does not modify the original ERP classification.

---

# 12. Product Diversity

Customer product diversity is measured using three different indicators:

* Distinct Products
* Distinct Product Subgroups
* Distinct Product Groups

These metrics allow the evaluation of customer purchasing breadth and support future customer segmentation analyses.

---

# 13. Business-Oriented Analysis

The project prioritizes answering business questions before developing dashboards.

Every analysis follows the same methodology:

1. Business Question
2. Hypothesis
3. SQL Analysis
4. Results
5. Business Insight
6. Recommendation

This approach ensures that the project focuses on generating business value rather than simply producing visualizations.

---

# 14. Current-Behavior Window

RFM Frequency and Monetary use a fixed 12-month window:

**08 July 2025 to 07 July 2026**

```sql
sale_date >= '2025-07-08'
AND sale_date < '2026-07-08'
```

Recency is calculated from the customer's last purchase in the full current
analytical history so inactive customers remain visible. The snapshot
reference date is **08 July 2026**.

---

# 15. RFM v1 Scoring

Revenue is the Monetary component. Profit and Profit Margin remain
complementary customer-value measures.

## Recency
* R5: 0–30 days
* R4: 31–90 days
* R3: 91–180 days
* R2: 181–365 days
* R1: more than 365 days

## Frequency — 12 Months
* F5: 11+ distinct sales
* F4: 4–10
* F3: 2–3
* F2: 1
* F1: 0

## Monetary — 12 Months
* M5: R$10,000+
* M4: R$3,000–9,999.99
* M3: R$500–2,999.99
* M2: R$0.01–499.99
* M1: R$0

These thresholds define RFM v1 and are versioned analytical rules rather
than permanent universal cutoffs.

---

# 16. Product Behavior

Product Behavior uses the same 12-month window as Frequency and Monetary.

Revenue is aggregated by Customer and Product Group. The dominant Product
Group is the group generating the highest 12-month revenue for that
customer. Product-group revenue share is:

`Product Group Revenue / Customer Total 12-Month Revenue`

Product Behavior provides commercial context for RFM and prevents customers
with different purchasing cycles from being interpreted uniformly.

---

# 17. After-Sales Behavior

After-sales analysis currently focuses on IMPLEMENTOS followed by PEÇAS.

* `first_implement_purchase` is the first observed IMPLEMENTOS purchase in
  the 12-month analytical window.
* A subsequent parts purchase must have Product Group = `PECAS` and a sale
  date strictly later than `first_implement_purchase`.
* Same-day parts activity is not counted as a subsequent after-sales
  purchase under the current rule.

Observed parts penetration by available follow-up time:

* <90 days: 18.18%.
* 90–179 days: 46.67%.
* 180+ days: 66.67%.

Commercial Segments v1 uses **180 days** as the operational maturity
threshold for AFTER-SALES OPPORTUNITY. The customer must have purchased
IMPLEMENTOS, have at least 180 days since the first observed implement
purchase, and have no subsequent PEÇAS purchase.

This identifies an opportunity for commercial review; it does not prove
unmet product need or a lost sale.

---

# 18. Commercial Segments v1

`vw_customer_commercial_segment` assigns exactly one segment to each of the
1,953 identified customers. Rules are evaluated in this precedence order:

1. **AFTER-SALES OPPORTUNITY**
   * Implement buyer.
   * 180+ days since first observed implement purchase.
   * No subsequent PEÇAS purchase.

2. **RECURRING COOLING DOWN**
   * Dominant Product Group = `PECAS`.
   * R <= 3 and F >= 4.

3. **HIGH VALUE EQUIPMENT**
   * Dominant Product Group = `IMPLEMENTOS` or `TRATORES`.
   * M >= 4.

4. **CORE ACTIVE**
   * R >= 4, F >= 4 and M >= 3.

5. **HIGH VALUE OCCASIONAL**
   * M >= 4 and not captured above.

6. **DORMANT HIGH POTENTIAL**
   * R = 1.
   * Historical Frequency >= 4 OR Historical Revenue >= R$3,000.

7. **LOW ENGAGEMENT**
   * Remaining identified customers.

Precedence is part of the rule because a customer may satisfy
characteristics associated with more than one profile.

`LOW ENGAGEMENT` is descriptive. It must not automatically be interpreted
as low lifetime value, low commercial priority or a recommendation not to
contact the customer.

---

# 19. Snapshot vs. Operational Logic

The current project is a fixed analytical snapshot ending on 07 July 2026.
Date-sensitive rules therefore use 08 July 2026 as the reference date.

When operationalized, snapshot-specific logic should be replaced
consistently with dynamic dates such as `CURDATE()` where appropriate.
RFM, after-sales and other time-dependent rules must use the same reference
date to avoid inconsistent classifications.

# 20. Legacy ERP Integration

### Customer Identity

Customer identity across ERP systems is primarily resolved using
normalized CPF/CNPJ.

For privacy-preserving cross-system matching, normalized documents are
converted to SHA-256 hashes before being transferred between systems.

Operational customer registration IDs are not treated as customer
identities because the same CPF/CNPJ may be associated with multiple
registrations.

The analytical model therefore separates:

- customer identity
- ERP source system
- customer registration ID

A bridge table maps ERP registrations to a common analytical customer
identity.

# 21. Legacy Customer Matching

Among legacy customer registrations associated with sales since 2018:

- 2,498 registration IDs were identified.
- 2,494 retain a customer-master record.
- 2,478 have a structurally valid CPF/CNPJ.
- These represent 2,471 distinct document identities.
- 2,465 of those identities were found in the current ERP.
- 6 document identities exist only in the legacy ERP.

Therefore, 99.76% of distinct document-identifiable legacy buyer
identities were matched to the current ERP.

Duplicate ERP registrations are not automatically treated as different
customers when they share the same document identity.

# 22. Legacy Item Classification

Legacy sale items are classified as:

- `SERVICE` when `VENDAS_ITENS.PRODUTO = 0`
- `PRODUCT` otherwise

`VENDAS_ITENS.TV` is treated as a movement type and not as an
indicator of whether an item is a service.

Legacy service descriptions are preserved from the sale item
description because services were commonly recorded using product ID 0.

# 23. Legacy Returns

A legacy item is classified as a return when:

`VENDAS.USUARIO LIKE 'Dev.%' AND VENDAS_ITENS.TV = 'EN'`

Return quantities and revenue are represented with negative signs in
the analytical layer.

# 24. Legacy Revenue

Legacy item revenue is calculated as:

`quantity × PRVENDIDO`

Returns receive a negative sign according to the return rule above.

This rule was reconciled against `VENDAS.TOTAL` for 90,815 sales since
2018.

- 90,795 sales reconciled within R$0.01.
- 20 sales remained as reconciliation exceptions.
- Reconciliation rate: 99.978%.
- Header revenue: R$26,813,680.27.
- Calculated analytical revenue: R$26,813,612.49.
- Net difference: R$67.78.

`VENDAS_ITENS.TOTAL` is not used as analytical item revenue because
tests showed that it can represent values before sale-level adjustments
such as discounts.

# 25. Legacy Cost and Profit

`VENDAS_ITENS.CUSTOA` is used as the historical unit-cost field.

CUSTOA and CUSTOM were equal in 214,163 of 214,208 analyzed product
items, with only 45 differences. CUSTOA also had slightly better
coverage.

For services (`PRODUTO = 0`), profit is NULL because reliable historical
cost is unavailable.

For `TV = 'SV'` product records with zero cost, profit is also NULL
rather than assuming zero cost.

Therefore, historical `SUM(profit)` represents known historical profit,
not necessarily complete historical profit.



---

# Current Integrated Model — Rules v2

## 26. Integrated Scope and Snapshot

- The current analytical sales layer is `vw_sales_unified_classified`, combining `LEGACY_ERP` and `CURRENT_ERP`.
- The observed unified history runs from **2018-01-02 through 2026-09-03**; the fixed reference date is **2026-09-03**.
- The integrated scope includes **PRODUCT** and **SERVICE** items. Earlier statements restricting scope to products or excluding services describe prior project versions only.
- The unified classified layer contains **291,024 sale-item rows** and approximately **R$35,875,034.95** in analytical revenue, including transactions without identified customers.
- Do not silently apply the old 2024–2026 window or the v1 RFM reference date to v2 analyses.
- For the current ERP, the implemented filter is `v.em_aberto = 1`. Its exact business interpretation as finalized/completed status has **not yet been independently confirmed**; retain it as an implemented source rule, not as an externally verified semantic claim.

## 27. Unified Customer Identity and Anonymous Sales

- Analytical customer grain is **one `customer_identity_id`**, not one operational registration ID and not simply a name.
- `bridge_customer_registration` maps `(source_system, customer_registration_id)` to the unified `customer_identity_id`.
- Cross-system matching is primarily based on normalized CPF/CNPJ; the earlier SHA-256 matching approach and validation findings remain documented in sections 20–21.
- A customer may have several ERP registrations. The bridge must be used before aggregating customer history across systems.
- Sales without a reliable identity have `customer_identity_id IS NULL`. They remain relevant for overall sales/product analysis but are excluded from customer-level RFM and segmentation.
- Validated identified population: **3,109 customer identities**. Historical identified-customer revenue is approximately **R$34,791,961.29** before customer-level rounding.
- The customer historical profile sums to **R$34,791,961.22** because of aggregation/rounding; do not interpret the R$0.07 difference as a missing sale.

## 28. Unified Transaction Grain and Sales Counting

- One row in `vw_sales_unified_classified` represents one sale item, either PRODUCT or SERVICE.
- A transaction may contain multiple items and both item types.
- Within the integrated data, a sale is identified for counting by the **combination of `source_system` and `sale_control`**, not by `sale_control` alone.
- RFM frequency uses `COUNT(DISTINCT CONCAT(source_system, ':', sale_control))` in the defined 12-month window; this avoids double-counting item rows while keeping transactions from different source systems distinct.
- `COUNT(*)` counts item rows, not transactions. Product-group customer counts may overlap because one customer can purchase multiple groups.
- A known duplicated migrated transaction was excluded from the unified analytical layer to avoid double-counting.

## 29. Revenue, Returns, Costs and Profit Coverage

- Use the unified view's validated `revenue` and `profit` fields as the analytical source, respecting source-specific calculation rules.
- Legacy product/service classification, return sign conventions, and historical cost limitations remain described in sections 22–25.
- Current ERP service revenue uses the recorded `vr_total` field in the validated analytical logic, rather than assuming quantity times unit price in every case.
- For historical services without reliable cost, `profit` is **NULL**. Known profit totals must be labeled **known profit**, not total or fully comparable profitability.
- Revenue and profit should not be assumed to have identical data coverage. A `NULL` cost/profit is not equivalent to zero cost/profit.
- Do not infer margin for service-only customers from incomplete cost records.

## 30. Analytical Product Classification and Quality

- The reporting group is `analytical_product_group`; `item_type` (PRODUCT/SERVICE) is a distinct dimension and must not be conflated with the group label.
- The legacy mapping layer uses `dim_legacy_product_group_mapping` and `dim_legacy_product_override`; the current ERP has its own group mapping/override logic.
- Legacy group 10 (IMPLEMENTOS) was validated and its classification status changed to CONFIRMED.
- The integrated classification quality check recorded **289,227 CONFIRMED** item rows (R$35,451,971.33), **1,546 PENDING** (R$385,418.51), and **251 REVIEW** (R$37,645.11). These are snapshot diagnostics, not timeless rules.
- Preserve `classification_source` and `classification_status` for audits. Do not automatically treat pending/review items as fully validated categories.

## 31. Historical Customer Profile and RFM v2 Base

- `vw_customer_historical_profile` summarizes all available identified-customer history.
- `vw_customer_rfm_base_v2` provides `customer_identity_id`, `first_purchase_date`, `last_purchase_date`, `recency_days`, `total_purchases`, `lifetime_revenue`, `frequency_12m`, `monetary_12m`, and `profit_12m`.
- Fixed reference date: **2026-09-03**.
- Frequency and Monetary window: **2025-09-04 through 2026-09-03**, inclusive; equivalent half-open filter: `sale_date >= '2025-09-04' AND sale_date < '2026-09-04'`.
- Recency is the number of days between the reference date and the last observed purchase in the historical profile; customers with no purchases in the recent window remain in the RFM population.
- `frequency_12m` counts distinct source-qualified sale controls; `monetary_12m` sums recent revenue.
- Validated counts: **3,109 identified customers**, of whom **1,406** have `frequency_12m > 0` and **1,703** have no transaction in the defined recent window.
- Validated 12-month revenue: **R$4,194,807.91** in the RFM customer base. Aggregation directly from sale-item rows may differ by a few cents due to rounding.
- Profit remains a complementary measure and may be incomplete because of service-cost coverage.
- **Open methodological check:** verify whether return-only transactions should count as purchases for Recency/Frequency; the currently implemented base uses the source-qualified transaction count and historical last-purchase logic as constructed. This has not been separately audited for return-only cases.

## 32. RFM v2 Scoring Rules

`vw_customer_rfm_scores_v2` assigns integer scores from 1 to 5 using these fixed, business-interpretable thresholds (not statistical quintiles):

| Score | Recency (`recency_days`) | Frequency (`frequency_12m`) | Monetary (`monetary_12m`) |
|---|---|---|---|
| 5 | 0–30 days | 11+ purchases | R$25,000+ |
| 4 | 31–90 days | 6–10 purchases | R$5,000–24,999.99 |
| 3 | 91–180 days | 4–5 purchases | R$1,000–4,999.99 |
| 2 | 181–365 days | 2–3 purchases | R$500–999.99 |
| 1 | >365 days | 0–1 purchases | <R$500 |

- The scoring view contains **3,109 customers**; each score ranges from 1 to 5.
- **1,700 customers** are `R=1, F=1, M=1`. This differs from the **1,703** customers with zero frequency in the strict 12-month window because the 365-day Recency cutoff and the inclusive 12-month window have a one-day boundary difference.
- Among the 1,406 active customers, no zero or negative `monetary_12m` was observed in the validated snapshot (minimum R$2.10, maximum R$193,736.21).
- Older v1 Frequency and Monetary thresholds in section 15 remain historical, not current.

## 33. Customer Segments v2 — Mutually Exclusive Precedence

`vw_customer_segments_v2` assigns exactly one segment per customer by evaluating the following rules **in order**:

1. **VIP** — `r_score >= 4 AND f_score >= 4 AND m_score >= 4`.
2. **Loyal Customers** — `r_score >= 3 AND f_score >= 4`.
3. **High-Value Occasional** — `r_score >= 3 AND m_score >= 4`.
4. **New Customers** — `first_purchase_date >= '2026-06-06'` (fixed 90-day snapshot rule).
5. **Promising** — `r_score >= 4`.
6. **At Risk** — `r_score = 2 AND (f_score >= 3 OR m_score >= 3)`.
7. **Active Occasional** — remaining customers with `r_score >= 2`.
8. **High-Value Lost** — `r_score = 1 AND lifetime_revenue >= 50000`.
9. **Former Regular Customers** — `r_score = 1 AND lifetime_revenue >= 10000`.
10. **Recently Inactive** — `r_score = 1 AND recency_days <= 730`.
11. **Long-Term Inactive** — all remaining customers.

- The labels are descriptive **versioned rules**, not proof of churn, loyalty, customer lifetime value, or recoverable revenue.
- `Former Regular Customers` is currently defined by historical revenue, **not** a minimum historical purchase count; its name must not be treated as proof of recurrence.
- The `At Risk` rule does not identify all customers whose purchase frequency has declined; customer risk should eventually be a separate indicator.
- Different product groups have different purchase cycles, so long recency among implement/tractor buyers should not automatically imply abandonment.
- Snapshot results: VIP **120**, Loyal **303**, High-Value Occasional **19**, New **43**, Promising **223**, At Risk **137**, Active Occasional **564**, and inactive segments together **1,700**; total **3,109**.
- This RFM v2 segmentation is distinct from the earlier seven-segment Commercial Segments v1 in section 18. Do not combine the two as though they were the same model.

## 34. Product Co-Purchase and Cross-Selling Definitions

- The recent cross-selling exploratory analysis uses the same fixed window as RFM v2: **2025-09-04 through 2026-09-03**.
- `buys_implements`, `buys_parts`, and `buys_services` are customer-level presence flags (1 if any item exists in the corresponding `analytical_product_group` during the window, otherwise 0).
- **Co-purchase** means a customer purchased both groups within the observation window; it does **not** establish order, causal conversion, or a purchase after an equipment sale.
- Validated implement-buyer cohort: **49** customers. Of these, **37** also purchased PEÇAS, **28** SERVICOS, and **11** purchased neither group during the same window.
- The mutually exclusive breakdown is **27 both PEÇAS and SERVICOS**, **10 PEÇAS only**, **1 SERVICOS only**, and **11 neither**. “Only” is relative to PEÇAS/SERVICOS within the implement cohort; it does not exclude purchases from other product groups.
- Among the 11 with neither group in the recent window, **6** had historical PEÇAS/SERVICOS activity and **5** had none recorded in the integrated history.
- Of the six with history, four customers had at least four distinct PEÇAS transactions; historical item counts must not be mistaken for distinct sales.
- Absence of observed parts/services purchases does not prove missed revenue or demand. Review the date of implement purchase, equipment needs, external purchasing and available follow-up time before operational targeting.
- The earlier v1 **temporal** after-sales rule (sections 17 and 18) answers a different question and must not be directly compared to the v2 same-window co-purchase rate.

## 35. Reproducibility and Documentation Controls

- Keep the source system, reporting grain, inclusion/exclusion rules, observation window, snapshot date and rounding level explicit in each analysis.
- Treat all validated numbers above as **snapshot results**, not permanent business constants.
- When changing score thresholds, segment precedence, mappings or dates, version the logic and rerun reconciliations.
- Reconcile identified-customer totals separately from all-sale totals, and sale-item counts separately from distinct transaction counts.
- Document outstanding issues instead of silently resolving them: incomplete service profit, unconfirmed `em_aberto` semantics, return-only effects on RFM, and unconfirmed commercial meaning of risk labels.
- For future operationalization, replace fixed dates with a single consistent parameterized reference date and recompute all dependent windows together.

# Future Rules

This document will be continuously updated as new business rules and analytical decisions emerge throughout the project.


## Guiding Principle

Business rules are applied as early as possible in the analytical pipeline.

Whenever feasible, data cleaning, filtering and business logic are implemented in the base analytical view (`vw_sales_enriched`) so that all subsequent analyses inherit the same validated dataset.

This approach improves consistency, reduces duplicated logic and minimizes the risk of contradictory business results.
