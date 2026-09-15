WITH coverage AS (
    SELECT
        MIN(`date`) AS first_date,
        MAX(`date`) AS last_date
    FROM arrivals
),
monthly AS (
    SELECT
        CAST(DATE_FORMAT(`date`, '%Y-%m-01') AS DATE) AS month_start,
        crop_name,
        SUM(arrival_quantity_qtl) AS total_qtl,
        COUNT(*) AS valid_quantity_records
    FROM arrivals
    WHERE quantity_status = 'Valid'
      AND arrival_quantity_qtl >= 0
      AND `date` IS NOT NULL
    GROUP BY
        CAST(DATE_FORMAT(`date`, '%Y-%m-01') AS DATE),
        crop_name
),
labelled AS (
    SELECT
        m.*,
        CASE
            WHEN c.first_date > m.month_start
              OR c.last_date < LAST_DAY(m.month_start)
            THEN 'Partial calendar coverage'
            ELSE 'Within dataset date range'
        END AS period_status
    FROM monthly m
    CROSS JOIN coverage c
),
compared AS (
    SELECT
        *,
        LAG(month_start) OVER (
            PARTITION BY crop_name ORDER BY month_start
        ) AS previous_month,
        LAG(total_qtl) OVER (
            PARTITION BY crop_name ORDER BY month_start
        ) AS previous_qtl,
        LAG(period_status) OVER (
            PARTITION BY crop_name ORDER BY month_start
        ) AS previous_status
    FROM labelled
)
SELECT
    month_start,
    crop_name,
    ROUND(total_qtl, 2) AS total_arrivals_qtl,
    valid_quantity_records,
    period_status,
    CASE
        WHEN period_status = 'Within dataset date range'
         AND previous_status = 'Within dataset date range'
         AND previous_month = DATE_SUB(month_start, INTERVAL 1 MONTH)
        THEN ROUND(
            100.0 * (total_qtl - previous_qtl)
            / NULLIF(previous_qtl, 0),
            2
        )
        ELSE NULL
    END AS month_on_month_change_percent
FROM compared
ORDER BY crop_name, month_start;