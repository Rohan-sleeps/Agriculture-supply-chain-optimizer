WITH mandi_totals AS (
    SELECT
        mandi_id,
        SUM(arrival_quantity_qtl) AS total_qtl
    FROM arrivals
    WHERE quantity_status = 'Valid'
      AND arrival_quantity_qtl >= 0
    GROUP BY mandi_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY total_qtl DESC, mandi_id
        ) AS rank_position,
        SUM(total_qtl) OVER () AS all_mandi_qtl
    FROM mandi_totals
),
top_five AS (
    SELECT *
    FROM ranked
    WHERE rank_position <= 5
)
SELECT
    t.rank_position,
    t.mandi_id,
    m.mandi_name,
    m.district,
    m.state,
    ROUND(t.total_qtl, 2) AS total_arrivals_qtl,
    ROUND(
        100.0 * t.total_qtl / NULLIF(t.all_mandi_qtl, 0),
        2
    ) AS share_of_total_percent,
    ROUND(
        100.0 * SUM(t.total_qtl) OVER ()
        / NULLIF(t.all_mandi_qtl, 0),
        2
    ) AS top_five_combined_share_percent
FROM top_five t
LEFT JOIN mandi_master m
    ON m.mandi_id = t.mandi_id
ORDER BY t.rank_position;