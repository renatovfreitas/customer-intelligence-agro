
/*
============================================================
05 — CROSS-SELL CONSISTENCY VALIDATION
============================================================

Project: Customer Intelligence — Agricultural Retail

Objective:
Validate implement customer classification, cross-sell
opportunity identification, commercial prioritization,
transaction filtering, and customer identity consistency.

Primary source:
vw_sales_unified_classified

RFM source:
vw_customer_segments_v2

Analysis period:
2025-09-04 to 2026-09-03

Reference date:
2026-09-03

------------------------------------------------------------
VALIDATION RESULTS
------------------------------------------------------------

1. Customer Purchase Classification
   Implement customers: 49
   Parts and services: 27
   Parts only: 10
   Services only: 1
   Neither parts nor services: 11
   Status: PASS

2. Cross-Sell Opportunity Reconciliation
   Parts and services opportunity: 11
   Services opportunity: 10
   Parts opportunity: 1
   No identified gap: 27
   Total opportunities: 22
   Status: PASS

3. Cross-Sell Priority Reconciliation
   P1_HIGH: 10
   P2_MEDIUM: 7
   P3_MONITOR: 5
   Total opportunity rows: 22
   Duplicate rows: 0
   Invalid priorities: 0
   Status: PASS

4. Transaction Filter Consistency
   Implement buyers (all transactions): 49
   Implement buyers (SALE only): 49
   Opportunities (all transactions): 22
   Opportunities (SALE only): 22
   Status: PASS

5. Customer Identity Consistency
   Opportunities in both approaches: 22
   Only in all transactions: 0
   Only in SALE transactions: 0
   Status: PASS

------------------------------------------------------------
OVERALL STATUS: PASS
------------------------------------------------------------

Business interpretation:
Cross-sell opportunities represent observed gaps in
purchase categories during the analysis period.

They do not establish unmet customer demand, product
compatibility, or guaranteed incremental revenue.

Validation results refer to the analyzed data snapshot.
============================================================
*/


/*
============================================================
VALIDATION 1 — CUSTOMER PURCHASE CLASSIFICATION
============================================================

Objective:
Classify implement buyers into mutually exclusive groups
according to purchases of parts and services.

Expected:
49 implement buyers:
- Both parts and services: 27
- Parts only: 10
- Services only: 1
- Neither: 11

Status: PASS
============================================================
*/

SELECT
    COUNT(*) AS implements_customers,

    SUM(
        CASE
            WHEN buys_parts = 1 AND buys_services = 1
            THEN 1 ELSE 0
        END
    ) AS parts_and_services,

    SUM(
        CASE
            WHEN buys_parts = 1 AND buys_services = 0
            THEN 1 ELSE 0
        END
    ) AS parts_only,

    SUM(
        CASE
            WHEN buys_parts = 0 AND buys_services = 1
            THEN 1 ELSE 0
        END
    ) AS services_only,

    SUM(
        CASE
            WHEN buys_parts = 0 AND buys_services = 0
            THEN 1 ELSE 0
        END
    ) AS neither_parts_nor_services

FROM (
    SELECT
        customer_identity_id,

        MAX(
            CASE
                WHEN analytical_product_group = 'PECAS'
                THEN 1 ELSE 0
            END
        ) AS buys_parts,

        MAX(
            CASE
                WHEN analytical_product_group = 'SERVICOS'
                THEN 1 ELSE 0
            END
        ) AS buys_services

    FROM vw_sales_unified_classified

    WHERE sale_date >= '2025-09-04'
      AND sale_date < '2026-09-04'
      AND transaction_type = 'SALE'
      AND customer_identity_id IS NOT NULL

      AND customer_identity_id IN (
          SELECT DISTINCT customer_identity_id
          FROM vw_sales_unified_classified
          WHERE analytical_product_group = 'IMPLEMENTOS'
            AND sale_date >= '2025-09-04'
            AND sale_date < '2026-09-04'
            AND transaction_type = 'SALE'
            AND customer_identity_id IS NOT NULL
      )

    GROUP BY customer_identity_id

) AS customer_flags;


/*
============================================================
VALIDATION 2 — CROSS-SELL OPPORTUNITY RECONCILIATION
============================================================

Objective:
Verify mutually exclusive opportunity classifications.

Expected:
- NO_OPPORTUNITY: 27
- PARTS_AND_SERVICES_OPPORTUNITY: 11
- SERVICES_OPPORTUNITY: 10
- PARTS_OPPORTUNITY: 1

Total identified opportunities: 22

Status: PASS
============================================================
*/

SELECT
    opportunity_type,
    COUNT(*) AS customers

FROM (
    SELECT
        customer_identity_id,

        CASE
            WHEN buys_parts = 0 AND buys_services = 0
            THEN 'PARTS_AND_SERVICES_OPPORTUNITY'

            WHEN buys_parts = 1 AND buys_services = 0
            THEN 'SERVICES_OPPORTUNITY'

            WHEN buys_parts = 0 AND buys_services = 1
            THEN 'PARTS_OPPORTUNITY'

            ELSE 'NO_OPPORTUNITY'
        END AS opportunity_type

    FROM (
        SELECT
            customer_identity_id,

            MAX(
                CASE
                    WHEN analytical_product_group = 'IMPLEMENTOS'
                    THEN 1 ELSE 0
                END
            ) AS buys_implements,

            MAX(
                CASE
                    WHEN analytical_product_group = 'PECAS'
                    THEN 1 ELSE 0
                END
            ) AS buys_parts,

            MAX(
                CASE
                    WHEN analytical_product_group = 'SERVICOS'
                    THEN 1 ELSE 0
                END
            ) AS buys_services

        FROM vw_sales_unified_classified

        WHERE sale_date >= '2025-09-04'
          AND sale_date < '2026-09-04'
          AND transaction_type = 'SALE'
          AND customer_identity_id IS NOT NULL

        GROUP BY customer_identity_id

    ) AS customer_flags

    WHERE buys_implements = 1

) AS opportunity_classification

GROUP BY opportunity_type

ORDER BY customers DESC;


/*
============================================================
VALIDATION 3 — CROSS-SELL PRIORITY RECONCILIATION
============================================================

Objective:
Validate priority distribution and customer uniqueness
using the original commercial prioritization rules.

Priority rules:

P1_HIGH:
No parts or services purchases and at least 180 days
since the last implement purchase.

P2_MEDIUM:
No services purchases and at least 90 days since the
last implement purchase, excluding P1_HIGH.

P3_MONITOR:
Remaining identified opportunities.

Expected:
- Total opportunity rows: 22
- Unique customers: 22
- Duplicate rows: 0
- P1_HIGH: 10
- P2_MEDIUM: 7
- P3_MONITOR: 5
- Invalid priorities: 0

Status: PASS
============================================================
*/

SELECT
    COUNT(*) AS total_opportunity_rows,

    COUNT(DISTINCT customer_identity_id)
        AS unique_customers,

    COUNT(*) - COUNT(DISTINCT customer_identity_id)
        AS duplicate_rows,

    SUM(
        CASE WHEN commercial_priority = 'P1_HIGH'
        THEN 1 ELSE 0 END
    ) AS p1_high,

    SUM(
        CASE WHEN commercial_priority = 'P2_MEDIUM'
        THEN 1 ELSE 0 END
    ) AS p2_medium,

    SUM(
        CASE WHEN commercial_priority = 'P3_MONITOR'
        THEN 1 ELSE 0 END
    ) AS p3_monitor,

    SUM(
        CASE
            WHEN commercial_priority IS NULL
              OR commercial_priority NOT IN (
                  'P1_HIGH',
                  'P2_MEDIUM',
                  'P3_MONITOR'
              )
            THEN 1 ELSE 0
        END
    ) AS invalid_priority_rows

FROM (
    SELECT
        flags.customer_identity_id,

        CASE
            WHEN flags.buys_parts = 0
             AND flags.buys_services = 0
             AND DATEDIFF(
                 '2026-09-03',
                 flags.last_implement_purchase
             ) >= 180
            THEN 'P1_HIGH'

            WHEN flags.buys_services = 0
             AND DATEDIFF(
                 '2026-09-03',
                 flags.last_implement_purchase
             ) >= 90
            THEN 'P2_MEDIUM'

            ELSE 'P3_MONITOR'
        END AS commercial_priority

    FROM (
        SELECT
            customer_identity_id,

            MAX(
                CASE
                    WHEN analytical_product_group = 'IMPLEMENTOS'
                    THEN 1 ELSE 0
                END
            ) AS buys_implements,

            MAX(
                CASE
                    WHEN analytical_product_group = 'PECAS'
                    THEN 1 ELSE 0
                END
            ) AS buys_parts,

            MAX(
                CASE
                    WHEN analytical_product_group = 'SERVICOS'
                    THEN 1 ELSE 0
                END
            ) AS buys_services,

            MAX(
                CASE
                    WHEN analytical_product_group = 'IMPLEMENTOS'
                    THEN sale_date
                END
            ) AS last_implement_purchase

        FROM vw_sales_unified_classified

        WHERE customer_identity_id IS NOT NULL
          AND sale_date >= '2025-09-04'
          AND sale_date < '2026-09-04'

        GROUP BY customer_identity_id

    ) AS flags

    LEFT JOIN vw_customer_segments_v2 AS rfm
        ON flags.customer_identity_id = rfm.customer_identity_id

    WHERE flags.buys_implements = 1
      AND (
          flags.buys_parts = 0
          OR flags.buys_services = 0
      )

) AS priority_results;


/*
============================================================
VALIDATION 4 — TRANSACTION FILTER CONSISTENCY
============================================================

Objective:
Compare purchase classifications using all transactions
versus SALE-only transactions.

Expected:
- Implement buyers (all): 49
- Implement buyers (SALE only): 49
- Opportunities (all): 22
- Opportunities (SALE only): 22

Status: PASS
============================================================
*/

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE WHEN all_implements = 1
        THEN 1 ELSE 0 END
    ) AS implements_all_transactions,

    SUM(
        CASE
            WHEN all_implements = 1
             AND (all_parts = 0 OR all_services = 0)
            THEN 1 ELSE 0
        END
    ) AS opportunities_all_transactions,

    SUM(
        CASE WHEN sale_implements = 1
        THEN 1 ELSE 0 END
    ) AS implements_sales_only,

    SUM(
        CASE
            WHEN sale_implements = 1
             AND (sale_parts = 0 OR sale_services = 0)
            THEN 1 ELSE 0
        END
    ) AS opportunities_sales_only

FROM (
    SELECT
        customer_identity_id,

        MAX(
            CASE
                WHEN analytical_product_group = 'IMPLEMENTOS'
                THEN 1 ELSE 0
            END
        ) AS all_implements,

        MAX(
            CASE
                WHEN analytical_product_group = 'PECAS'
                THEN 1 ELSE 0
            END
        ) AS all_parts,

        MAX(
            CASE
                WHEN analytical_product_group = 'SERVICOS'
                THEN 1 ELSE 0
            END
        ) AS all_services,

        MAX(
            CASE
                WHEN transaction_type = 'SALE'
                 AND analytical_product_group = 'IMPLEMENTOS'
                THEN 1 ELSE 0
            END
        ) AS sale_implements,

        MAX(
            CASE
                WHEN transaction_type = 'SALE'
                 AND analytical_product_group = 'PECAS'
                THEN 1 ELSE 0
            END
        ) AS sale_parts,

        MAX(
            CASE
                WHEN transaction_type = 'SALE'
                 AND analytical_product_group = 'SERVICOS'
                THEN 1 ELSE 0
            END
        ) AS sale_services

    FROM vw_sales_unified_classified

    WHERE customer_identity_id IS NOT NULL
      AND sale_date >= '2025-09-04'
      AND sale_date < '2026-09-04'

    GROUP BY customer_identity_id

) AS customer_flags;


/*
============================================================
VALIDATION 5 — CUSTOMER IDENTITY CONSISTENCY
============================================================

Objective:
Verify that both transaction-filter approaches identify
exactly the same cross-sell opportunity customers.

Expected:
- Opportunities in both approaches: 22
- Only in all transactions: 0
- Only in SALE transactions: 0

Status: PASS
============================================================
*/

SELECT
    SUM(
        CASE
            WHEN opportunity_all = 1
             AND opportunity_sale = 1
            THEN 1 ELSE 0
        END
    ) AS opportunities_in_both,

    SUM(
        CASE
            WHEN opportunity_all = 1
             AND opportunity_sale = 0
            THEN 1 ELSE 0
        END
    ) AS only_all_transactions,

    SUM(
        CASE
            WHEN opportunity_all = 0
             AND opportunity_sale = 1
            THEN 1 ELSE 0
        END
    ) AS only_sale_transactions

FROM (
    SELECT
        customer_identity_id,

        CASE
            WHEN all_implements = 1
             AND (all_parts = 0 OR all_services = 0)
            THEN 1 ELSE 0
        END AS opportunity_all,

        CASE
            WHEN sale_implements = 1
             AND (sale_parts = 0 OR sale_services = 0)
            THEN 1 ELSE 0
        END AS opportunity_sale

    FROM (
        SELECT
            customer_identity_id,

            MAX(
                CASE
                    WHEN analytical_product_group = 'IMPLEMENTOS'
                    THEN 1 ELSE 0
                END
            ) AS all_implements,

            MAX(
                CASE
                    WHEN analytical_product_group = 'PECAS'
                    THEN 1 ELSE 0
                END
            ) AS all_parts,

            MAX(
                CASE
                    WHEN analytical_product_group = 'SERVICOS'
                    THEN 1 ELSE 0
                END
            ) AS all_services,

            MAX(
                CASE
                    WHEN transaction_type = 'SALE'
                     AND analytical_product_group = 'IMPLEMENTOS'
                    THEN 1 ELSE 0
                END
            ) AS sale_implements,

            MAX(
                CASE
                    WHEN transaction_type = 'SALE'
                     AND analytical_product_group = 'PECAS'
                    THEN 1 ELSE 0
                END
            ) AS sale_parts,

            MAX(
                CASE
                    WHEN transaction_type = 'SALE'
                     AND analytical_product_group = 'SERVICOS'
                    THEN 1 ELSE 0
                END
            ) AS sale_services

        FROM vw_sales_unified_classified

        WHERE customer_identity_id IS NOT NULL
          AND sale_date >= '2025-09-04'
          AND sale_date < '2026-09-04'

        GROUP BY customer_identity_id

    ) AS customer_flags

) AS opportunity_comparison;
