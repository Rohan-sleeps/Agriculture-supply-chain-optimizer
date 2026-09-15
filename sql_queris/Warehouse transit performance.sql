WITH ranked_durations AS (
    SELECT
        destination_warehouse_clean AS warehouse,
        transit_hours_clean,
        ROW_NUMBER() OVER (
            PARTITION BY destination_warehouse_clean
            ORDER BY transit_hours_clean, trip_id_clean
        ) AS row_position,
        COUNT(*) OVER (
            PARTITION BY destination_warehouse_clean
        ) AS group_size
    FROM transport
    WHERE transit_hours_clean > 0
),
medians AS (
    SELECT
        warehouse,
        AVG(transit_hours_clean) AS median_transit_hours
    FROM ranked_durations
    WHERE row_position IN (
        FLOOR((group_size + 1) / 2),
        FLOOR((group_size + 2) / 2)
    )
    GROUP BY warehouse
),
summary AS (
    SELECT
        destination_warehouse_clean AS warehouse,
        COUNT(*) AS total_trips,
        SUM(
            CASE WHEN transit_hours_clean > 0
                 THEN 1 ELSE 0 END
        ) AS usable_duration_trips,
        AVG(
            CASE WHEN transit_hours_clean > 0
                 THEN transit_hours_clean END
        ) AS average_transit_hours,
        AVG(
            CASE WHEN transit_hours_clean > 0
                 THEN distance_km END
        ) AS average_distance_km,
        SUM(
            CASE
                WHEN transit_hours_clean > 0
                 AND transit_duration_source = 'Calculated from timestamps'
                THEN 1 ELSE 0
            END
        ) AS calculated_duration_trips,
        SUM(
            CASE
                WHEN transit_hours_clean > 0
                 AND transit_duration_source = 'Reported: timestamps incomplete'
                THEN 1 ELSE 0
            END
        ) AS reported_fallback_trips,
        SUM(
            CASE
                WHEN transit_hours_clean IS NULL
                  OR transit_hours_clean <= 0
                THEN 1 ELSE 0
            END
        ) AS unavailable_duration_trips
    FROM transport
    GROUP BY destination_warehouse_clean
)
SELECT
    s.warehouse,
    s.total_trips,
    s.usable_duration_trips,
    ROUND(s.average_transit_hours, 2) AS average_transit_hours,
    ROUND(m.median_transit_hours, 2) AS median_transit_hours,
    ROUND(s.average_distance_km, 2) AS average_distance_km,
    s.calculated_duration_trips,
    s.reported_fallback_trips,
    s.unavailable_duration_trips
FROM summary s
LEFT JOIN medians m
    ON m.warehouse = s.warehouse
ORDER BY
    m.median_transit_hours DESC,
    s.warehouse;