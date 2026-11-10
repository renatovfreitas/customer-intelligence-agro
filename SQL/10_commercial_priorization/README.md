# 10 — Commercial Prioritization

## 1. Overview

This module transforms customer purchasing behavior, dynamic RFM segmentation, and equipment ownership history into actionable commercial opportunities.

The objective is to help the sales team identify customers who may benefit from category reactivation, equipment after-sales engagement, or complementary product offerings.

The module consolidates different commercial signals into a unified opportunity dataset, designed for future integration with Power BI.

**Current status:** Implemented and validated.

**Next phase:** Power BI integration and operational prioritization enhancements.

---

## 2. Business Objectives

The commercial prioritization framework aims to:

- Identify active customers who have stopped purchasing from previously relevant product groups.
- Distinguish recurring purchase categories from long-cycle equipment categories.
- Identify equipment buyers with potential after-sales opportunities.
- Combine overlapping commercial signals into a single actionable opportunity.
- Support targeted sales campaigns and customer relationship management.
- Establish a foundation for future opportunity scoring and operational ranking.

The framework is rule-based and does not currently estimate conversion probabilities or expected future revenue.

## 3. Commercial Classification

Product groups are classified according to their expected purchasing behavior.

| Purchase Cycle | Product Groups | Commercial Interpretation |
|---|---|---|
| RECURRING | PECAS, SERVICOS, OLEOS E LUBRIFICANTES | Potential category reactivation |
| LONG_CYCLE | TRATORES, IMPLEMENTOS | Equipment relationship and complementary sales |
| OTHER | Selected additional product groups | Requires category-specific evaluation |
| UNCLASSIFIED | Unmapped or undefined groups | Requires business review |

These classifications are initial business assumptions and may be refined with sales team input.

The classification operates at the analytical product group level and does not require hardcoded product or subgroup IDs.

### Classification limitations

Certain groups, including PNEUS, GERADOR, MATERIA PRIMA, USO E CONSUMO, and NAO CLASSIFICADO, were initially identified as requiring further review.

Their commercial treatment should be validated before expanding automated prioritization.

---

## 4. Module Architecture

The module contains the following main components.

| Object | Purpose |
|---|---|
| `vw_product_group_commercial_policy` | Classifies product groups by purchasing cycle |
| `vw_customer_commercial_priorities` | Identifies category reactivation opportunities |
| `dim_equipment_complementary_group` | Configures complementary product groups |
| `vw_equipment_customer_base` | Identifies equipment purchasing history |
| `vw_equipment_after_sales_base` | Measures complementary purchasing behavior |
| `vw_equipment_after_sales_opportunities` | Identifies equipment after-sales opportunities |
| `vw_customer_opportunity_signals` | Combines opportunity signals |
| `vw_customer_actionable_opportunities` | Consolidates opportunities into an actionable dataset |

The final opportunity view integrates customer-level dynamic RFM segmentation with category-specific commercial signals.

### Data grain

`vw_customer_actionable_opportunities` contains one row per:

`customer_identity_id + target_product_group`

This prevents the same customer-category opportunity from being counted multiple times when identified by different analytical models.

---

## 5. Category Reactivation Prioritization

Category reactivation focuses on customers who remain active in the company but have not purchased from a previously used recurring product group during the rolling 12-month period.

The prioritization model considers:

- Historical purchase frequency.
- Historical category revenue.
- Current customer activity.
- Product group purchasing cycle.

### Priority Rules — Version 2

| Priority | Rule | Suggested Treatment |
|---|---|---|
| P1_HIGH | At least 11 historical purchases AND historical revenue ≥ R$5,000 | Priority commercial contact |
| P2_MEDIUM | At least 5 historical purchases OR historical revenue ≥ R$1,000 | Targeted reactivation |
| P3_MONITOR | Remaining inactive recurring categories | Monitoring or lower-cost campaigns |
| LONG_CYCLE_REVIEW | Inactive long-cycle equipment categories | Complementary sales review |
| NOT_PRIORITIZED | Other or unclassified categories | Business review required |

These thresholds are initial business heuristics, not statistically optimized decision boundaries.

### Validated Category Prioritization Results

| Priority | Opportunities |
|---|---:|
| P1_HIGH | 38 |
| P2_MEDIUM | 295 |
| P3_MONITOR | 467 |
| LONG_CYCLE_REVIEW | 279 |
| NOT_PRIORITIZED | 716 |
| **Total** | **1,795** |

The 1,795 records represent customer-product-group combinations, not necessarily unique customers.

---

## 6. Equipment After-Sales Opportunities

Equipment after-sales analysis focuses on customers with historical purchases of:

- TRATORES
- IMPLEMENTOS

The model evaluates complementary purchasing behavior in:

- PECAS
- SERVICOS
- OLEOS E LUBRIFICANTES

For each customer and equipment group, the analysis considers:

- Last equipment purchase date.
- Days since the last equipment purchase.
- Historical equipment revenue.
- Complementary purchases after the latest equipment purchase.
- Complementary purchases during the rolling 12-month period.
- Most recent complementary purchase.

### Initial After-Sales Rules

| Priority | Interpretation |
|---|---|
| P1_HIGH | Equipment purchased at least 180 days ago, with no recorded subsequent purchases in the target complementary category |
| P2_MEDIUM | Equipment purchased 90–179 days ago, without subsequent complementary purchases |
| P2_REACTIVATION | Complementary category purchased after the equipment, but not during the last 12 months |
| P3_EARLY_STAGE | Equipment purchased less than 90 days ago, without subsequent complementary purchases |
| EXISTING_RELATIONSHIP | Complementary category purchased within the last 12 months |

These rules indicate commercial contact opportunities, not confirmed maintenance requirements.

A complementary purchase cannot necessarily be attributed to a specific tractor or implement.

### Validated After-Sales Distribution

| Classification | Customer-Equipment-Category Combinations |
|---|---:|
| P1_HIGH | 623 |
| P2_REACTIVATION | 448 |
| P2_MEDIUM | 15 |
| P3_EARLY_STAGE | 18 |
| EXISTING_RELATIONSHIP | 663 |
| **Total** | **1,767** |

No duplicate customer-equipment-category combinations were detected.

---

## 7. Unified Commercial Opportunities

The final model combines two commercial signals:

**Category Reactivation**

A customer previously purchased from a recurring product group but has not purchased from that group during the rolling 12-month period.

**Equipment After-Sales**

A customer purchased tractors or implements and presents a potential opportunity for complementary product or service engagement.

When both signals refer to the same customer and target product group, they are consolidated into one opportunity.

### Consolidation Rules

- One record per customer and target product group.
- The strongest available priority determines the consolidated priority.
- Both signal indicators are preserved.
- Historical category revenue and purchasing frequency are retained when available.
- Equipment purchasing history is retained as supporting context.
- Suggested commercial actions are generated according to the detected signals.

### Validated Overlap

| Target Category | Combined Opportunities |
|---|---:|
| OLEOS E LUBRIFICANTES | 116 |
| SERVICOS | 104 |
| PECAS | 14 |
| **Total** | **234** |

All 234 overlapping customer-category combinations were successfully consolidated.

### Final Opportunity Distribution

| Opportunity Type | P1_HIGH | P2_MEDIUM | P3_MONITOR | Total |
|---|---:|---:|---:|---:|
| Category Reactivation | 18 | 198 | 345 | 561 |
| Equipment After-Sales | 561 | 294 | 0 | 855 |
| Combined Signals | 80 | 154 | 0 | 234 |
| **Total** | **659** | **646** | **345** | **1,650** |

### Validation Results

- Total consolidated opportunities: **1,650**
- Customer-category duplicates: **0**
- Overlapping opportunities successfully reconciled: **234**
- Consolidation grain: customer × target product group

The model is ready for initial Power BI integration.

These results represent the validated dataset at the time of analysis. Counts may change as source data and rolling reporting windows are updated.

---

## 8. Known Limitations

### 8.1 Rule-Based Prioritization

The current model uses manually defined thresholds and business assumptions.

It does not calculate the statistical probability of a customer purchasing again.

### 8.2 Broad High-Priority Population

The unified opportunity list contains 659 P1_HIGH opportunities, representing approximately 40% of all identified opportunities.

This is too broad to be considered a fully optimized sales execution queue.

The current priority should therefore be interpreted as an initial commercial classification rather than a final operational ranking.

### 8.3 Long Equipment Replacement Cycles

Tractors and implements have longer replacement cycles than recurring categories.

The absence of recent equipment purchases does not necessarily indicate customer churn.

### 8.4 Incomplete After-Sales Attribution

The available transaction data does not establish whether a purchased part, lubricant, or service was associated with a specific equipment unit.

### 8.5 Historical Revenue Is Not Recoverable Revenue

Historical purchasing value helps characterize customer relationships but does not represent guaranteed future revenue or opportunity value.

### 8.6 Data Quality and Transaction Scope

The model inherits data quality limitations from the unified sales layer, including incomplete historical profit information and product classification issues.

Current opportunity calculations primarily use SALE transactions. Returns are not systematically deducted from these commercial indicators.

---

## 9. Planned Enhancement — Operational Opportunity Ranking

**Status: Planned — Not Yet Implemented**

A future development phase will introduce an operational ranking system to prioritize customers within the existing commercial priority groups, especially P1_HIGH.

The objective is to transform a broad list of commercially relevant opportunities into a more focused and manageable sales execution queue.

Rather than relying exclusively on fixed rules, the ranking will combine four dimensions.

### 9.1 Customer RFM Segment and Current Activity

The ranking will incorporate:

- Current RFM segment.
- Recency score.
- Frequency score.
- Monetary score.
- Days since the customer's most recent purchase.
- Purchase frequency and revenue during the rolling 12-month period.

**Business rationale:** customers who maintain an active commercial relationship may be easier to engage than customers who have been inactive for extended periods.

RFM activity should not be treated as a direct measure of conversion probability.

### 9.2 Historical Relationship With the Target Category

The ranking will consider:

- Historical category revenue.
- Historical category purchase frequency.
- Last purchase in the category.
- Share of the category in the customer's purchasing history.
- Changes in category purchasing behavior.

**Business rationale:** repeated historical purchases provide stronger evidence of an established category relationship than isolated transactions.

### 9.3 Equipment Purchase Age

For equipment-related opportunities, the ranking will consider:

- Days since the latest tractor or implement purchase.
- Equipment group.
- Complementary purchasing activity after equipment acquisition.
- Complementary category purchase recency.

**Business rationale:** after-sales engagement should reflect the equipment ownership timeline rather than relying exclusively on generic inactivity thresholds.

Equipment age alone does not establish maintenance requirements.

### 9.4 Estimated Commercial Potential

The ranking will eventually incorporate an estimate of the potential commercial value of each opportunity.

Possible inputs include:

- Historical category purchasing value.
- Historical purchasing frequency.
- Typical customer spending in the target category.
- Comparable customer purchasing patterns.
- Estimated contribution margin where reliable cost data is available.

**Business rationale:** prioritize opportunities based on potential business impact rather than historical revenue alone.

Estimated commercial potential must be distinguished from historical revenue and validated before being presented as a forecast.

### Proposed Ranking Architecture

A future scoring model may use:

`operational_score = RFM_component + category_relationship_component + equipment_component + commercial_potential_component`

The exact weights, scales, normalization methods, and eligibility rules have not yet been defined.

The model should distinguish category reactivation from equipment after-sales opportunities, since the commercial drivers are not identical.

### Expected Deliverables

The planned enhancement should produce:

- An operational score for each actionable opportunity.
- A ranking within each commercial priority group.
- Explainable scoring components.
- A recommended contact sequence.
- Commercial potential indicators.
- Configurable prioritization thresholds.
- A structure suitable for Power BI reporting.

### Validation Requirements

Before operational deployment, the ranking should be evaluated using:

- Historical purchasing patterns.
- Sales team feedback.
- Customer-level opportunity reviews.
- Comparison of alternative scoring weights.
- Future campaign outcomes and conversion results.

The initial implementation may be rule-based. A predictive model should only be considered after sufficient outcome data becomes available.

---

## 10. Power BI Integration — Next Phase

The next development phase will connect the MariaDB analytical database to Power BI.

The initial reporting model will use:

| View | Reporting Purpose |
|---|---|
| `vw_customer_segments_dynamic` | Customer segmentation and RFM metrics |
| `vw_customer_group_profile` | Lifetime and rolling 12-month category behavior |
| `vw_customer_commercial_profile` | Customer segmentation combined with category behavior |
| `vw_customer_actionable_opportunities` | Consolidated commercial opportunities |

### Initial Dashboard Scope

**Executive Overview**
- Total customers.
- Active and inactive customers.
- Revenue and profitability indicators.
- Customer segment distribution.

**Customer Intelligence**
- RFM segmentation.
- Customer purchase frequency and recency.
- Customer value and category relationships.

**Commercial Opportunities**
- Opportunities by priority.
- Opportunities by target product group.
- Category reactivation and after-sales opportunities.
- Customer-level actionable opportunity lists.

**Future Sales Execution**
- Operational opportunity ranking.
- Contact assignments.
- Campaign tracking.
- Conversion monitoring.
- Estimated versus realized commercial results.

### Data Modeling Considerations

Customer-level financial measures must not be summed directly across tables containing multiple rows per customer.

The Power BI model should preserve the grain of each analytical view and use appropriate relationships and DAX measures.

Dynamic SQL views do not automatically refresh Power BI datasets. Refresh configuration and source-data update procedures will be addressed during deployment.

---

## 11. Project Status

| Component | Status |
|---|---|
| Product group commercial classification | Completed |
| Category reactivation priorities | Completed |
| Equipment after-sales opportunities | Completed |
| Unified opportunity signals | Completed |
| Opportunity deduplication | Validated |
| Unified commercial opportunity list | Validated |
| Operational ranking | Planned |
| Commercial potential estimation | Planned |
| Power BI data model | Next Phase |
| Dashboard development | Pending |
| Campaign outcome tracking | Future Enhancement |

### Conclusion

The Commercial Prioritization module establishes a reusable analytical foundation for customer reactivation and equipment after-sales strategies.

The final unified dataset contains 1,650 actionable customer-category opportunities, including 659 high-priority opportunities.

The next objective is to connect this analytical layer to Power BI and develop an operational dashboard.

A future ranking model will improve the ordering of opportunities by combining RFM behavior, category relationships, equipment purchase age, and estimated commercial potential.

This enhancement is intentionally deferred until the initial reporting model is operational and business users can evaluate the quality of the current opportunity recommendations.
