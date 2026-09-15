WITH usable AS (
    SELECT *
    FROM transport
    WHERE transit_hours_clean > 0
),
ranked_all AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY mandi_id_clean, destination_warehouse_clean
            ORDER BY transit_hours_clean, trip_id_clean
        ) AS row_position,
        COUNT(*) OVER (
            PARTITION BY mandi_id_clean, destination_warehouse_clean
        ) AS group_size
    FROM usable
),
route_medians AS (
    SELECT
        mandi_id_clean,
        destination_warehouse_clean,
        AVG(transit_hours_clean) AS median_transit_hours
    FROM ranked_all
    WHERE row_position IN (
        FLOOR((group_size + 1) / 2),
        FLOOR((group_size + 2) / 2)
    )
    GROUP BY
        mandi_id_clean,
        destination_warehouse_clean
),
ranked_calculated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY mandi_id_clean, destination_warehouse_clean
            ORDER BY transit_hours_clean, trip_id_clean
        ) AS row_position,
        COUNT(*) OVER (
            PARTITION BY mandi_id_clean, destination_warehouse_clean
        ) AS group_size
    FROM usable
    WHERE transit_duration_source = 'Calculated from timestamps'
),
calculated_medians AS (
    SELECT
        mandi_id_clean,
        destination_warehouse_clean,
        AVG(transit_hours_clean) AS calculated_only_median_hours
    FROM ranked_calculated
    WHERE row_position IN (
        FLOOR((group_size + 1) / 2),
        FLOOR((group_size + 2) / 2)
    )
    GROUP BY
        mandi_id_clean,
        destination_warehouse_clean
),
route_summary AS (
    SELECT
        mandi_id_clean,
        destination_warehouse_clean,
        COUNT(*) AS usable_duration_trips,
        AVG(transit_hours_clean) AS average_transit_hours,
        AVG(distance_km) AS average_distance_km,
        SUM(
            CASE
                WHEN transit_duration_source = 'Reported: timestamps incomplete'
                THEN 1 ELSE 0
            END
        ) AS reported_fallback_trips,
        SUM(
            CASE
                WHEN transit_duration_source = 'Calculated from timestamps'
                THEN 1 ELSE 0
            END
        ) AS calculated_duration_trips
    FROM usable
    GROUP BY
        mandi_id_clean,
        destination_warehouse_clean
    HAVING COUNT(*) >= 15
)
SELECT
    r.mandi_id_clean AS mandi_id,
    m.mandi_name,
    r.destination_warehouse_clean AS warehouse,
    r.usable_duration_trips,
    ROUND(r.average_transit_hours, 2) AS average_transit_hours,
    ROUND(rm.median_transit_hours, 2) AS median_transit_hours,
    ROUND(r.average_distance_km, 2) AS average_distance_km,
    ROUND(
        100.0 * r.reported_fallback_trips / r.usable_duration_trips,
        2
    ) AS reported_fallback_share_percent,
    r.calculated_duration_trips,
    ROUND(
        cm.calculated_only_median_hours,
        2
    ) AS calculated_only_median_hours
FROM route_summary r
LEFT JOIN mandi_master m
    ON m.mandi_id = r.mandi_id_clean
JOIN route_medians rm
    ON rm.mandi_id_clean = r.mandi_id_clean
   AND rm.destination_warehouse_clean = r.destination_warehouse_clean
LEFT JOIN calculated_medians cm
    ON cm.mandi_id_clean = r.mandi_id_clean
   AND cm.destination_warehouse_clean = r.destination_warehouse_clean
ORDER BY
    rm.median_transit_hours DESC,
    r.usable_duration_trips DESC,
    r.mandi_id_clean,
    r.destination_warehouse_clean
LIMIT 10;