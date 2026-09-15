from pathlib import Path
from decimal import Decimal
from getpass import getpass
import json

import pandas as pd
from sqlalchemy import create_engine, URL, MetaData


# --------------------------------------------------
# 1. File locations
# --------------------------------------------------

DATA_FOLDER = Path(
    "/Users/rohankhanna/Documents/datathon/cleaned_data"
)

FILES = {
    "mandi_master": "mandi_master_cleaned.csv",
    "arrivals": "mandi_arrivals_cleaned.csv",
    "prices": "price_and_msp_cleaned.csv",
    "transport": "transport_logistics_cleaned.csv",
    "weather": "weather_sensors_cleaned.csv"
}


# --------------------------------------------------
# 2. Columns expected by the MySQL tables
# --------------------------------------------------

COLUMNS = {
    "mandi_master": """
        mandi_id mandi_name district state mandi_type
        total_area_acres district_status area_status
    """.split(),

    "arrivals": """
        arrival_row_key arrival_id date mandi_id crop_name
        variety arrival_quantity_qtl farmer_count
        arrival_id_status date_status mandi_id_status
        quantity_status
    """.split(),

    "prices": """
        record_id date mandi_id district crop_name
        min_price max_price modal_price msp
        price_msp_gap below_supplied_msp date_status
        mandi_id_status district_status msp_comparison_status
    """.split(),

    "transport": """
        trip_id_clean mandi_id_clean destination_warehouse_clean
        distance_km transit_hours_clean transit_duration_source
    """.split(),

    "weather": """
        sensor_id timestamp_ist weather_date temperature_c
        rainfall_mm humidity_percent sensor_id_status
        timestamp_status date_format_assumed rainfall_status
        humidity_status sensor_timestamp_conflict
    """.split()
}

NUMERIC_COLUMNS = {
    "total_area_acres",
    "arrival_quantity_qtl",
    "min_price",
    "max_price",
    "modal_price",
    "msp",
    "price_msp_gap",
    "distance_km",
    "transit_hours_clean",
    "temperature_c",
    "rainfall_mm",
    "humidity_percent"
}

BOOLEAN_COLUMNS = {
    "below_supplied_msp",
    "date_format_assumed",
    "sensor_timestamp_conflict"
}

# Safe aliases if the transport export uses simplified names.
TRANSPORT_ALIASES = {
    "trip_id": "trip_id_clean",
    "mandi_id": "mandi_id_clean",
    "destination_warehouse": "destination_warehouse_clean",
    "transit_hours": "transit_hours_clean"
}

# --------------------------------------------------
# 3. Convert CSV values to database-compatible values
# --------------------------------------------------

def parse_value(column, value):
    if pd.isna(value):
        return None

    text = str(value).strip()

    if column in NUMERIC_COLUMNS:
        number = Decimal(text)

        if not number.is_finite():
            raise ValueError(
                f"Nonfinite numeric value in {column}: {text}"
            )

        return number

    if column == "farmer_count":
        number = Decimal(text)

        if (
            not number.is_finite()
            or number != number.to_integral_value()
        ):
            raise ValueError(f"Invalid farmer count: {text}")

        return int(number)

    if column in BOOLEAN_COLUMNS:
        boolean_mapping = {
            "true": 1,
            "false": 0,
            "1": 1,
            "0": 0
        }

        if text.lower() not in boolean_mapping:
            raise ValueError(
                f"Invalid Boolean value in {column}: {text}"
            )

        return boolean_mapping[text.lower()]

    if column in {"date", "weather_date"}:
        return pd.to_datetime(
            text,
            format="%Y-%m-%d",
            errors="raise"
        ).date()

    if column == "timestamp_ist":
        timestamp = pd.Timestamp(text)

        if timestamp.tzinfo is None:
            raise ValueError(
                f"Weather timestamp has no timezone offset: {text}"
            )

        # MySQL DATETIME stores local clock time without an offset.
        # Convert to IST first, then remove timezone metadata.
        return (
            timestamp
            .tz_convert("Asia/Kolkata")
            .tz_localize(None)
            .to_pydatetime()
        )

    return text


# --------------------------------------------------
# 4. Read and validate all CSVs
# --------------------------------------------------

def prepare_files():
    prepared = {}

    for table_name, filename in FILES.items():
        path = DATA_FOLDER / filename

        if not path.is_file():
            raise FileNotFoundError(
                f"File not found: {path}\n"
                "Check its filename and update FILES if necessary."
            )

        original = pd.read_csv(
            path,
            dtype="string",
            keep_default_na=False,
            na_values=["NA", ""],
            encoding="utf-8-sig"
        )

        frame = original.copy()

        if table_name == "transport":
            renames = {
                old: new
                for old, new in TRANSPORT_ALIASES.items()
                if old in frame.columns and new not in frame.columns
            }

            frame = frame.rename(columns=renames)

        missing_columns = (
            set(COLUMNS[table_name]) - set(frame.columns)
        )

        if missing_columns:
            raise ValueError(
                f"{filename} is missing required columns:\n"
                f"{sorted(missing_columns)}\n"
                "Check the cleaned export; do not substitute raw values."
            )

        if frame.empty:
            raise ValueError(f"{filename} contains no records.")

        # Preserve the full original CSV row, including audit flags.
        # JSON null is used for missing source values.
        audit_rows = json.loads(
            original.to_json(
                orient="records",
                force_ascii=False
            )
        )

        rows = []

        for position, values in enumerate(
            frame[COLUMNS[table_name]].to_dict(orient="records")
        ):
            try:
                record = {
                    column: parse_value(column, value)
                    for column, value in values.items()
                }
            except Exception as error:
                raise ValueError(
                    f"{filename}, data row {position + 1}: {error}"
                ) from error

            record["source_record"] = audit_rows[position]
            rows.append(record)

        prepared[table_name] = rows
        print(f"Prepared {filename}: {len(rows):,} records")

    return prepared


# --------------------------------------------------
# 5. Connect to MySQL and import
# --------------------------------------------------

def main():
    prepared = prepare_files()

    print("\nEnter your MySQL Workbench connection details.")

    host = input("MySQL host [localhost]: ").strip() or "localhost"
    port = int(input("MySQL port [3306]: ").strip() or "3306")
    username = input("MySQL username [root]: ").strip() or "root"
    database = input("Database [agritech]: ").strip() or "agritech"
    password = getpass("MySQL password: ")

    connection_url = URL.create(
        drivername="mysql+pymysql",
        username=username,
        password=password,
        host=host,
        port=port,
        database=database,
        query={"charset": "utf8mb4"}
    )

    engine = create_engine(
        connection_url,
        pool_pre_ping=True
    )

    try:
        metadata = MetaData()
        metadata.reflect(
            bind=engine,
            only=list(FILES)
        )

        # Fail clearly if an existing table has the wrong columns.
        for table_name, required_columns in COLUMNS.items():
            table = metadata.tables[table_name]

            missing = (
                set(required_columns + ["source_record"])
                - set(table.columns.keys())
            )

            if missing:
                raise ValueError(
                    f"MySQL table '{table_name}' is missing columns: "
                    f"{sorted(missing)}. Check its schema."
                )

        # With InnoDB tables, all inserts commit together.
        # An error rolls the transaction back.
        with engine.begin() as connection:
            for table_name in FILES:
                table = metadata.tables[table_name]

                existing = connection.execute(
                    table.select().limit(1)
                ).first()

                if existing is not None:
                    raise RuntimeError(
                        f"Table '{table_name}' already contains data. "
                        "Import stopped to prevent duplicate loading. "
                        "No existing data was deleted."
                    )

            # Dictionary order loads the master first.
            for table_name, rows in prepared.items():
                table = metadata.tables[table_name]

                for start in range(0, len(rows), 1000):
                    connection.execute(
                        table.insert(),
                        rows[start:start + 1000]
                    )

        print("\nImport committed successfully.")

        for table_name, rows in prepared.items():
            print(f"{table_name}: {len(rows):,} records")

    finally:
        engine.dispose()


if __name__ == "__main__":
    main()