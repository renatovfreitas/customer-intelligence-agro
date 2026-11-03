# 08 — Customer Group Behavior

## 1. Overview

This module introduces a reusable analytical layer for evaluating customer purchasing behavior across product groups.

Unlike the initial commercial analysis, which focused on implement buyers and their purchases of parts and services, this layer supports **any analytical product group** without relying on hardcoded product identifiers.

The objective is to create a scalable foundation for:

- Customer purchase behavior analysis
- Product group revenue contribution
- Customer purchase frequency and recency
- Cross-selling and upselling analysis
- Integration with RFM segmentation
- Future Power BI reporting and automated refresh

The module uses the existing product classification and consolidated customer identity from the unified sales layer.

---

## 2. Data Source and Granularity

**Primary source:** `vw_sales_unified_classified`

**Granularity:** One row per `customer_identity_id` and `product_group`.

The current implementation uses the complete available transaction history rather than a fixed 12-month period.

### Business Rules

1. Only transactions classified as `SALE` are included.
2. Records without a consolidated `customer_identity_id` are excluded.
3. Product groups are obtained dynamically from `analytical_product_group`.
4. Product group IDs and names are not hardcoded.
5. Revenue and profit are aggregated independently.
6. Missing profit values are preserved rather than automatically replaced with zero.
7. Sales are identified using the combination of `source_system` and `sale_control`.

**Important:** Because returns are excluded, the revenue metric represents sales revenue before deducting returns, not net revenue.

---

## 3. Architecture

The implementation uses three interconnected SQL views.

This approach also avoids the SQL Error 1349 encountered when attempting to create a view containing derived tables in the `FROM` clause.

```text
vw_sales_unified_classified
          |
          |--------------------------|
          |                          |
          v                          v
vw_customer_group_aggregation   vw_customer_revenue_total
          |                          |
          |--------------------------|
                     |
                     v
        vw_customer_group_behavior
                     |
                     v
          Future analytical layers
                     |
                     v
                Power BI
```

### 3.1 `vw_customer_group_aggregation`

Aggregates transaction data by customer and analytical product group.

**Output fields:**

| Column | Description |
|---|---|
| `customer_identity_id` | Consolidated customer identifier |
| `product_group` | Analytical product group |
| `revenue` | Accumulated sales revenue |
| `profit` | Sum of available profit values |
| `sales_count` | Distinct sales transactions |
| `items_quantity` | Total quantity sold |
| `first_purchase` | First recorded sale in the group |
| `last_purchase` | Most recent recorded sale in the group |
| `missing_profit_rows` | Number of transactions without profit information |

The view uses the existing product classification and can accommodate new product groups as they become available in the source data.

### 3.2 `vw_customer_revenue_total`

Calculates the accumulated sales revenue for each identified customer across all product groups.

**Output fields:**

- `customer_identity_id`
- `customer_total_revenue`

This view provides the denominator used to calculate product group revenue contribution.

### 3.3 `vw_customer_group_behavior`

Combines customer-group metrics with total customer revenue.

The main derived indicator is:

**Group Revenue Share (%)**

`group_revenue_pct = 100 × group_revenue / customer_total_revenue`

The calculation uses `NULLIF` to avoid division by zero.

This final view is designed to serve as a reusable analytical dataset for customer intelligence reporting.

---

## 4. Validation Results

Five validation steps were performed to assess the structure, uniqueness, financial consistency, and customer population of the new analytical layer.

### Validation 1 — Structure and Sample Review

A sample of the 20 highest-revenue customer-group combinations was inspected.

The output contained the expected 11 columns and demonstrated that the view can represent different product groups, including:

- `PECAS`
- `IMPLEMENTOS`
- `TRATORES`
- `SERVICOS`

The sample also showed transactions dated after the original RFM reference date of September 3, 2026, demonstrating that the historical view can incorporate more recent source data.

Missing profit values remained visible in the output.

**Status: PASS**

### Validation 2 — Customer and Group Uniqueness

The following results were obtained:

| Metric | Result |
|---|---:|
| Total customer-group rows | 8,357 |
| Unique customers | 3,118 |
| Distinct product groups | 12 |

These results establish the initial population and coverage of the historical customer-group behavior layer.

**Status: PASS**

### Validation 3 — Duplicate Customer-Group Detection

The uniqueness rule requires each combination of `customer_identity_id` and `product_group` to appear only once.

The duplicate detection query returned zero rows.

| Metric | Result |
|---|---:|
| Duplicate customer-group combinations | 0 |

**Status: PASS**

### Validation 4 — Customer Revenue Reconciliation

The sum of product group revenues was compared against the total customer revenue.

| Metric | Result |
|---|---:|
| Customers checked | 3,118 |
| Customers with differences greater than R$ 0.01 | 0 |
| Aggregate revenue difference | R$ 0.29 |

No customer exceeded the defined reconciliation tolerance.

The small accumulated difference is consistent with intermediate rounding at the customer-group level.

**Status: PASS WITH ROUNDING OBSERVATION**

**Planned improvement:** Preserve greater numerical precision in intermediate financial aggregations and apply rounding primarily in the reporting layer.

### Validation 5 — Customer Population Reconciliation

The historical customer-group population was compared against `vw_customer_rfm_base_v2`.

| Dataset | Customers |
|---|---:|
| Customer Group Behavior | 3,118 |
| RFM v2 Base | 3,109 |
| Net difference | 9 |

The identity-level comparison identified:

- 12 customers present only in Customer Group Behavior.
- 3 customers present only in RFM v2.

#### Investigation Findings

The 12 customers exclusive to Customer Group Behavior had their first recorded sales after September 3, 2026, the reference date of the RFM v2 snapshot.

The three customers exclusive to RFM v2 had only return transactions in the available history and therefore did not satisfy the `SALE` requirement of the new view.

The difference can be reconciled as follows:

```text
RFM v2 customers                         3,109
+ New buyers after the RFM snapshot         12
- Return-only customers                      3
----------------------------------------------
Customer Group Behavior customers        3,118
```

The population difference is explained by the observation periods and transaction eligibility rules.

**Status: PASS — EXPLAINED POPULATION DIFFERENCE**

---

## 5. Data Quality Considerations

### 5.1 Financial Precision

The initial implementation rounds revenue and profit at the aggregation level.

Although no customer exceeded the reconciliation tolerance, an accumulated difference of R$ 0.29 was observed.

Future improvements should minimize intermediate rounding and preserve appropriate financial precision.

### 5.2 Missing Profit

Some transactions contain NULL profit values due to documented limitations in the legacy and current ERP systems.

The view includes `missing_profit_rows` to make this limitation visible.

A NULL profit value must not be interpreted as zero profit.

### 5.3 Return Transactions

The current customer-group behavior view considers only `SALE` transactions.

This is appropriate for identifying observed purchases but does not represent net financial performance after returns.

A separate net-revenue metric may be introduced for financial reporting.

### 5.4 Customer Population

The historical customer-group population is not expected to match the fixed RFM v2 snapshot exactly.

The two datasets currently differ in their reference periods and treatment of return-only customers.

Future integration must establish consistent eligibility rules without discarding legitimate historical information.

### 5.5 Sales Identification

The sales count uses a composite identifier based on `source_system` and `sale_control`.

This rule should be maintained consistently across analytical layers and verified against source-system transaction definitions.

---

## 6. Dynamic Data Refresh

The three views are standard SQL views rather than materialized snapshots.

They can reflect changes in their underlying tables when queried.

For example, when a new customer purchase is successfully imported into the unified sales dataset:

1. The customer-group aggregation can include the new transaction.
2. Customer total revenue can be recalculated.
3. Product group revenue share can change.
4. The updated results can be retrieved by downstream reporting tools.

However, SQL views alone do not provide an automated end-to-end refresh process.

Production deployment will require:

- Reliable ERP-to-database ingestion
- Refresh scheduling and monitoring
- Data quality checks after ingestion
- Power BI semantic model refresh
- Appropriate database and dashboard access controls

Historical trend analysis will also require periodic snapshots or an equivalent historical storage strategy.

---

## 7. Future Development

### Phase 1 — Financial Precision Improvements

Review intermediate rounding and confirm reconciliation using higher-precision financial aggregations.

### Phase 2 — Rolling 12-Month Customer Behavior

Develop a dynamic analytical layer using a moving 12-month observation window.

Planned metrics include:

- Revenue over the last 12 months
- Profit over the last 12 months
- Purchase frequency
- First and last purchase by group
- Days since last purchase
- Product group revenue contribution

### Phase 3 — Dynamic RFM Integration

Adapt the existing RFM v2 logic to support an updated reference date and consistent customer eligibility rules.

Preserve the historical RFM v2 snapshot for reproducibility and comparison.

### Phase 4 — Generalized Cross-Selling Analysis

Develop reusable logic to identify complementary product group opportunities.

The implementation should support multiple source and target groups without embedding fixed product IDs in analytical queries.

### Phase 5 — Power BI Integration

Build a reporting model capable of supporting:

- Customer segmentation dashboards
- Revenue and profitability analysis
- Product group purchase behavior
- Customer inactivity monitoring
- Cross-selling opportunities
- Commercial prioritization

### Phase 6 — Operational Refresh and Historical Tracking

Implement a reliable data refresh workflow and periodic snapshots to support ongoing monitoring.

---

## 8. Current Implementation Status

| Component | Status |
|---|---|
| Customer-group aggregation view | Implemented |
| Customer total revenue view | Implemented |
| Final customer-group behavior view | Implemented |
| Structure validation | PASS |
| Customer-group uniqueness | PASS |
| Revenue reconciliation | PASS WITH ROUNDING OBSERVATION |
| Customer population reconciliation | PASS |
| Rolling 12-month metrics | Planned |
| Dynamic RFM integration | Planned |
| Generalized cross-selling | Planned |
| Power BI dashboard | Planned |
| Automated production refresh | Planned |

---

## 9. Conclusion

The Customer Group Behavior module establishes a reusable analytical foundation for examining customer purchases across product groups.

The implementation successfully:

- Eliminates the need for fixed product group ID lists.
- Supports multiple product groups through existing classification logic.
- Preserves one row per customer-group combination.
- Reconciles customer-level sales revenue within the defined tolerance.
- Explains differences between historical and fixed-snapshot customer populations.
- Provides a foundation for rolling metrics, dynamic RFM segmentation, and commercial dashboards.

**Overall assessment: VALIDATED WITH DOCUMENTED IMPROVEMENTS**

The next development step is to improve financial precision and implement rolling 12-month customer behavior metrics before connecting the analytical layer to operational Power BI reporting.
