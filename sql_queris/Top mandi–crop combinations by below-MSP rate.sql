WITH grouped AS (
    SELECT
        p.mandi_id,
        m.mandi_name,
        p.crop_name,
        COUNT(*) AS eligible_records,
        SUM(
            CASE
                WHEN p.modal_price < p.msp
                THEN 1 ELSE 0
            END
        ) AS below_msp_records,
        AVG(
            CASE
                WHEN p.modal_price < p.msp
                THEN p.msp - p.modal_price
            END
        ) AS average_shortfall_when_below
    FROM prices p
    JOIN mandi_master m
        ON m.mandi_id = p.mandi_id
    WHERE p.modal_price > 0
      AND p.msp > 0
    GROUP BY
        p.mandi_id,
        m.mandi_name,
        p.crop_name
    HAVING COUNT(*) >= 20
)
SELECT
    mandi_id,
    mandi_name,
    crop_name,
    eligible_records,
    below_msp_records,
    ROUND(
        100.0 * below_msp_records / eligible_records,
        2
    ) AS below_msp_rate_percent,
    ROUND(
        average_shortfall_when_below,
        2
    ) AS average_shortfall_when_below
FROM grouped
ORDER BY
    1.0 * below_msp_records / eligible_records DESC,
    eligible_records DESC,
    mandi_id,
    crop_name
LIMIT 10;