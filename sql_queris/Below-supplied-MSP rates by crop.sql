WITH crop_summary AS (
    SELECT
        crop_name,
        COUNT(*) AS total_price_records,
        SUM(
            CASE
                WHEN modal_price > 0 AND msp > 0
                THEN 1 ELSE 0
            END
        ) AS eligible_records,
        SUM(
            CASE
                WHEN modal_price > 0
                 AND msp > 0
                 AND modal_price < msp
                THEN 1 ELSE 0
            END
        ) AS below_msp_records,
        AVG(
            CASE
                WHEN modal_price > 0 AND msp > 0
                THEN modal_price - msp
            END
        ) AS average_price_msp_gap
    FROM prices
    GROUP BY crop_name
)
SELECT
    crop_name,
    total_price_records,
    eligible_records,
    below_msp_records,
    ROUND(
        100.0 * below_msp_records / NULLIF(eligible_records, 0),
        2
    ) AS below_msp_rate_percent,
    ROUND(
        100.0 * eligible_records / NULLIF(total_price_records, 0),
        2
    ) AS comparison_coverage_percent,
    ROUND(average_price_msp_gap, 2) AS average_price_msp_gap
FROM crop_summary
ORDER BY
    below_msp_rate_percent DESC,
    crop_name;