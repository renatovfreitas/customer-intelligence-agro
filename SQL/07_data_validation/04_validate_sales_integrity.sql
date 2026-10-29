
/*
============================================================
VALIDATION: LEGACY ERP RETURN CONSISTENCY
============================================================

Objective:
Verify that sales and returns follow the expected quantity
sign convention in the unified analytical dataset.

Business Rules:
- SALE transactions must have positive quantities.
- RETURN transactions must have negative quantities.
- Zero or NULL quantities are not expected.

Validation Results:
- Total legacy records: 228,081
- SALE records: 223,688
- RETURN records: 4,393
- Negative quantities in SALE: 0
- Positive quantities in RETURN: 0
- Zero or NULL quantities: 0
- Classification exceptions: 0

Findings:
All negative quantities are associated with RETURN transactions.
All SALE transactions have positive quantities.

The original Firebird extraction reverses quantity and revenue
signs for qualifying return transactions.

Status: PASS

Note:
Results refer to the validated analytical snapshot.
Movement type and source user conditions were not directly
revalidated in this query.
============================================================
*/

-- 1. Sales and returns quantity distribution

SELECT
    source_system,
    transaction_type,

    COUNT(*) AS total_rows,

    SUM(
        CASE WHEN quantity < 0
        THEN 1 ELSE 0 END
    ) AS negative_quantity_rows,

    SUM(
        CASE WHEN quantity > 0
        THEN 1 ELSE 0 END
    ) AS positive_quantity_rows,

    SUM(
        CASE WHEN quantity = 0 OR quantity IS NULL
        THEN 1 ELSE 0 END
    ) AS zero_or_null_quantity_rows,

    ROUND(SUM(quantity), 2) AS net_quantity,

    ROUND(SUM(revenue), 2) AS net_revenue

FROM vw_sales_unified_classified

WHERE source_system = 'LEGACY_ERP'

GROUP BY
    source_system,
    transaction_type

ORDER BY
    transaction_type;


-- 2. Identify inconsistencies between transaction type
--    and quantity sign.
-- Expected result: 0 rows.

SELECT
    sale_control,
    sale_item_id,
    sale_date,
    transaction_type,
    quantity,
    revenue,
    profit

FROM vw_sales_unified_classified

WHERE source_system = 'LEGACY_ERP'
  AND (
        (quantity < 0 AND transaction_type = 'SALE')
        OR
        (quantity >= 0 AND transaction_type = 'RETURN')
        OR
        quantity IS NULL
      )

ORDER BY sale_date DESC;
