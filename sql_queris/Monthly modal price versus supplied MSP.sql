WITH coverage AS (
    SELECT
        MIN(`date`) AS first_date,
        MAX(`date`) AS last_date
    FROM prices
),
monthly AS (
    SELECT
        CAST(DATE_FORMAT(`date`, '%Y-%m-01') AS DATE) AS month_start,
        crop_name,
        COUNT(*) AS eligible_records,
        AVG(modal_price) AS average_modal_price,
        AVG(msp) AS average_supplied_msp,
        SUM(
            CASE
                WHEN modal_price < msp
                THEN 1 ELSE 0
            END
        ) AS below_msp_records
    FROM prices
    WHERE modal_price > 0
      AND msp > 0
      AND `date` IS NOT NULL
    GROUP BY
        CAST(DATE_FORMAT(`date`, '%Y-%m-01') AS DATE),
        crop_name
)
SELECT
    m.month_start,
    m.crop_name,
    m.eligible_records,
    ROUND(m.average_modal_price, 2) AS average_modal_price,
    ROUND(m.average_supplied_msp, 2) AS average_supplied_msp,
    ROUND(
        100.0 * m.below_msp_records / m.eligible_records,
        2
    ) AS below_msp_rate_percent,
    CASE
        WHEN c.first_date > m.month_start
          OR c.last_date < LAST_DAY(m.month_start)
        THEN 'Partial calendar coverage'
        ELSE 'Within dataset date range'
    END AS period_status
FROM monthly m
CROSS JOIN coverage c
ORDER BY m.crop_name, m.month_start;