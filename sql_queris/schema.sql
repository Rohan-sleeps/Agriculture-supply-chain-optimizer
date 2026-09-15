CREATE DATABASE IF NOT EXISTS agritech
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE agritech;

CREATE TABLE IF NOT EXISTS mandi_master (
    mandi_id VARCHAR(8) PRIMARY KEY,
    mandi_name VARCHAR(150) NOT NULL,
    district VARCHAR(100),
    state VARCHAR(100) NOT NULL,
    mandi_type VARCHAR(30),
    total_area_acres DECIMAL(18, 4),
    district_status VARCHAR(150),
    area_status VARCHAR(100),
    source_record JSON NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS arrivals (
    arrival_row_key VARCHAR(30) PRIMARY KEY,
    arrival_id VARCHAR(30),
    `date` DATE,
    mandi_id VARCHAR(8),
    crop_name VARCHAR(50) NOT NULL,
    variety VARCHAR(100),
    arrival_quantity_qtl DECIMAL(20, 8),
    farmer_count INT,
    arrival_id_status VARCHAR(100),
    date_status VARCHAR(150),
    mandi_id_status VARCHAR(100),
    quantity_status VARCHAR(100) NOT NULL,
    source_record JSON NOT NULL,

    CONSTRAINT fk_arrivals_mandi
        FOREIGN KEY (mandi_id)
        REFERENCES mandi_master(mandi_id),

    CONSTRAINT chk_arrivals_quantity
        CHECK (
            arrival_quantity_qtl IS NULL
            OR arrival_quantity_qtl >= 0
        ),

    CONSTRAINT chk_arrivals_farmer_count
        CHECK (
            farmer_count IS NULL
            OR farmer_count >= 0
        ),

    INDEX idx_arrivals_mandi_date (mandi_id, `date`)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS prices (
    record_id VARCHAR(30) PRIMARY KEY,
    `date` DATE,
    mandi_id VARCHAR(8),
    district VARCHAR(100),
    crop_name VARCHAR(50) NOT NULL,
    min_price DECIMAL(20, 8),
    max_price DECIMAL(20, 8),
    modal_price DECIMAL(20, 8),
    msp DECIMAL(20, 8),
    price_msp_gap DECIMAL(20, 8),
    below_supplied_msp BOOLEAN,
    date_status VARCHAR(150),
    mandi_id_status VARCHAR(100),
    district_status VARCHAR(150),
    msp_comparison_status VARCHAR(150),
    source_record JSON NOT NULL,

    CONSTRAINT fk_prices_mandi
        FOREIGN KEY (mandi_id)
        REFERENCES mandi_master(mandi_id),

    CONSTRAINT chk_prices_min
        CHECK (min_price IS NULL OR min_price > 0),

    CONSTRAINT chk_prices_max
        CHECK (max_price IS NULL OR max_price > 0),

    CONSTRAINT chk_prices_modal
        CHECK (modal_price IS NULL OR modal_price > 0),

    CONSTRAINT chk_prices_msp
        CHECK (msp IS NULL OR msp > 0),

    CONSTRAINT chk_prices_below_flag
        CHECK (
            below_supplied_msp IS NULL
            OR below_supplied_msp IN (0, 1)
        ),

    INDEX idx_prices_mandi_date (mandi_id, `date`)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS transport (
    trip_id_clean VARCHAR(30) PRIMARY KEY,
    mandi_id_clean VARCHAR(8),
    destination_warehouse_clean VARCHAR(50) NOT NULL,
    distance_km DECIMAL(20, 8),
    transit_hours_clean DECIMAL(20, 8),
    transit_duration_source VARCHAR(150) NOT NULL,
    source_record JSON NOT NULL,

    CONSTRAINT fk_transport_mandi
        FOREIGN KEY (mandi_id_clean)
        REFERENCES mandi_master(mandi_id),

    CONSTRAINT chk_transport_distance
        CHECK (
            distance_km IS NULL
            OR distance_km > 0
        ),

    CONSTRAINT chk_transport_duration
        CHECK (
            transit_hours_clean IS NULL
            OR transit_hours_clean > 0
        ),

    INDEX idx_transport_route (
        mandi_id_clean,
        destination_warehouse_clean
    )
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS weather (
    reading_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sensor_id VARCHAR(20),
    timestamp_ist DATETIME,
    weather_date DATE,
    temperature_c DECIMAL(18, 8),
    rainfall_mm DECIMAL(18, 8),
    humidity_percent DECIMAL(10, 4),
    sensor_id_status VARCHAR(100),
    timestamp_status VARCHAR(150),
    date_format_assumed BOOLEAN,
    rainfall_status VARCHAR(100),
    humidity_status VARCHAR(100),
    sensor_timestamp_conflict BOOLEAN NOT NULL,
    source_record JSON NOT NULL,

    CONSTRAINT chk_weather_rainfall
        CHECK (
            rainfall_mm IS NULL
            OR rainfall_mm >= 0
        ),

    CONSTRAINT chk_weather_humidity
        CHECK (
            humidity_percent IS NULL
            OR humidity_percent BETWEEN 0 AND 100
        ),

    CONSTRAINT chk_weather_date_assumed
        CHECK (
            date_format_assumed IS NULL
            OR date_format_assumed IN (0, 1)
        ),

    CONSTRAINT chk_weather_conflict
        CHECK (sensor_timestamp_conflict IN (0, 1)),

    INDEX idx_weather_sensor_date (sensor_id, weather_date)
) ENGINE = InnoDB;

SHOW TABLES;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    cc.CHECK_CLAUSE
FROM information_schema.TABLE_CONSTRAINTS AS tc
JOIN information_schema.CHECK_CONSTRAINTS AS cc
    ON tc.CONSTRAINT_SCHEMA = cc.CONSTRAINT_SCHEMA
   AND tc.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = DATABASE()
  AND tc.CONSTRAINT_TYPE = 'CHECK'
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_NAME;