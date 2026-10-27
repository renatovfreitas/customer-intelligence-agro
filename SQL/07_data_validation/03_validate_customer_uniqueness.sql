-- Data Validation
-- Customer Uniqueness Validation
--
-- Checks duplicate customer identities across
-- the three RFM v2 analytical layers.
--
-- Expected result: PASS for all three layers.

SELECT
    validation.layer_name,
    validation.total_rows,
    validation.distinct_customers,
    validation.null_customer_ids,
    validation.duplicate_rows,

    CASE
        WHEN validation.null_customer_ids = 0
         AND validation.duplicate_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM (
    SELECT
        'RFM_BASE_V2' AS layer_name,
        COUNT(*) AS total_rows,
        COUNT(DISTINCT customer_identity_id)
            AS distinct_customers,

        SUM(
            CASE
                WHEN customer_identity_id IS NULL
                THEN 1 ELSE 0
            END
        ) AS null_customer_ids,

        COUNT(*)
          - COUNT(DISTINCT customer_identity_id)
          - SUM(
              CASE
                  WHEN customer_identity_id IS NULL
                  THEN 1 ELSE 0
              END
            ) AS duplicate_rows

    FROM vw_customer_rfm_base_v2

    UNION ALL

    SELECT
        'RFM_SCORES_V2',
        COUNT(*),
        COUNT(DISTINCT customer_identity_id),

        SUM(
            CASE
                WHEN customer_identity_id IS NULL
                THEN 1 ELSE 0
            END
        ),

        COUNT(*)
          - COUNT(DISTINCT customer_identity_id)
          - SUM(
              CASE
                  WHEN customer_identity_id IS NULL
                  THEN 1 ELSE 0
              END
            )

    FROM vw_customer_rfm_scores_v2

    UNION ALL

    SELECT
        'RFM_SEGMENTS_V2',
        COUNT(*),
        COUNT(DISTINCT customer_identity_id),

        SUM(
            CASE
                WHEN customer_identity_id IS NULL
                THEN 1 ELSE 0
            END
        ),

        COUNT(*)
          - COUNT(DISTINCT customer_identity_id)
          - SUM(
              CASE
                  WHEN customer_identity_id IS NULL
                  THEN 1 ELSE 0
              END
            )

    FROM vw_customer_segments_v2
) AS validation

ORDER BY validation.layer_name;
