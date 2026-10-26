SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary_12m), 2) AS revenue_12m
FROM vw_customer_segments_v2
GROUP BY customer_segment
ORDER BY revenue_12m DESC;
