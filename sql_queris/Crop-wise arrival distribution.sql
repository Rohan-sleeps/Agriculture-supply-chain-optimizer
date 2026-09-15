WITH crop_totals AS (
    SELECT
        crop_name,
        SUM(arrival_quantity_qtl) AS total_qtl,
        COUNT(*) AS valid_quantity_records
    FROM arrivals
    WHERE quantity_status = 'Valid'
      AND arrival_quantity_qtl >= 0
    GROUP BY crop_name
)
SELECT
    crop_name,
    ROUND(total_qtl, 2) AS total_arrivals_qtl,
    ROUND(
        100.0 * total_qtl
        / NULLIF(SUM(total_qtl) OVER (), 0),
        2
    ) AS share_of_total_percent,
    valid_quantity_records
FROM crop_totals
ORDER BY total_qtl DESC;