
The SQL uses CTEs for readable transformations, `LAG` for month comparisons, and `ROW_NUMBER` with group counts to calculate medians from the middle observation(s). Primary keys, foreign keys, check constraints, and indexes are defined in the supplied schema.

SQL code and complete result tables are maintained separately from the PDF; the report presents interpretations and selected ranking rows.

## Implemented Database Model

Database: **`agritech`**.

| Table | Grain | Primary key |
|---|---|---|
| `mandi_master` | One mandi | `mandi_id` |
| `arrivals` | One retained arrival observation | `arrival_row_key` |
| `prices` | One price observation | `record_id` |
| `transport` | One trip | `trip_id_clean` |
| `weather` | One retained weather reading | Generated `reading_id` |

Arrivals, prices, and transport reference the mandi master using standardized IDs. Nullable relationships preserve unresolved records. Each table includes a `source_record` JSON field for the original imported CSV row.

Fact tables are not directly joined in ways that multiply observations. Weather has **no verified district or mandi relationship**. Separate crop, date, and warehouse dimension tables are not claimed as implemented in the supplied SQL schema.

## Power BI and the Six Report Graphs
## Interactive Power BI Dashboard

[Open the interactive dashboard](https://mandi-58a3be.netlify.app/)

> The dashboard opens in Power BI. Availability depends on the sharing permissions configured for the report.

The Power BI dashboard is complete. The report focuses on these six graph topics:

| Graph | Purpose |
|---|---|
| Arrival volume by crop | Compare valid volume and crop mix |
| Monthly arrivals by crop | Show changes over time with partial September labelled |
| Top five mandis by arrivals | Show volume concentration |
| Below supplied MSP rate by crop | Compare eligible-observation price exposure |
| Monthly Wheat modal price versus supplied MSP | Compare averages on the same eligible population |
| Average transit duration by warehouse | Compare destinations with distance and coverage context |

The PDF recreates these six charts from the supplied SQL result tables so that figures and captions use consistent populations. They are not a claim that every supplied dashboard screenshot shows the same measure or filters. Every report graph includes **Finding, Meaning, and Limitation**. The date-sensitivity chart is excluded.

## Metric Definitions

**Arrival volume:** sum valid `arrival_quantity_qtl`. There are **23,767 valid quantity records** out of 25,000 retained arrivals.

**Below supplied MSP rate:** observations with `modal_price < msp` divided by observations with both positive values. The overall denominator is **9,131**, not all price records or unique mandis. Missing comparisons are excluded, not counted as `False`.

**Price–MSP gap:** `modal_price - msp` for eligible records. Mean prices and mean supplied MSP in the monthly comparison use the same observations and are not arrival-weighted.

**Transit duration:** positive timestamp-derived duration where available, followed by a positive reported fallback when calculation is unavailable. Of 10,000 trips, **7,359** use calculated durations, **2,356** use reported fallbacks, and **285** remain unavailable or invalid.

**Route and warehouse comparisons:** retain trip counts, distance context, and duration-source coverage. Long duration does not establish a missed delivery commitment.

## Assumptions and Limitations

- **Dates:** separator conventions were inferred from observed formats; 4,703 arrival dates and 2,262 price dates retain assumption flags. September coverage ends on 9 September for the arrival/price analyses and is not a full-month comparison.
- **Prices:** currency is INR, but the quantity basis is unspecified. Comparisons use the common basis implied by the challenge; prices are not labelled INR per quintal, and supplied benchmarks are not independently verified official rates.
- **Locations:** 8,366 price records conflict with the master district. Reporting uses the master; 2,004 price records still have no reporting district. Synthetic mandi names must not be used to infer real geography.
- **Crop groups:** broad labels, especially Rice/Paddy/Basmati, support reporting but do not establish product or variety equivalence.
- **Transport:** no SLA or promised arrival is supplied. The report ranks durations, not confirmed delays. Reported fallbacks remain identifiable.
- **Weather:** sensor-to-district mapping and rainfall measurement intervals are unresolved. District rainfall totals and rainfall–arrival causal claims are not supported.
- **Unavailable business measures:** shipment quantities, realized sales, investment costs, and customer histories are absent; warehouse crop volume, revenue, ROI, and churn are not inferred.
- **Precision:** the small arrival SQL/Python total difference is disclosed above and still requires reconciliation.

## Running the Project

1. Install the notebook and database-loader dependencies used by your local environment.
2. Configure raw-data, cleaned-data, and database connection paths; do not commit passwords.
3. Run mandi master cleaning first, followed by the remaining dataset notebooks.
4. Execute the supplied MySQL `schema.sql` to create the `agritech` database and five tables.
5. Run the MySQL-compatible loader, loading the master before dependent records.
6. Run the database validation checks, then the eight analytical queries.
7. Export query results and refresh the Power BI report using the same metric definitions.

Typical notebook setup:

```bash
python -m pip install pandas numpy matplotlib seaborn openpyxl jupyterlab
python -m jupyterlab
```

Use the MySQL driver required by the actual loader; earlier PostgreSQL connection examples are not interchangeable with the final MySQL schema.

### Import and export conventions

- Cleaned CSVs use UTF-8 with BOM and `NA` for missing values.
- Convert exact `NA` markers to SQL `NULL` or Power BI `null` before assigning data types.
- Keep identifiers as text, measurements as decimal values, and farmer counts as nullable integers.
- Weather CSV timestamps retain the IST offset. The MySQL `DATETIME` field is timezone-naive, so the loader must retain the intended IST local time; the schema alone does not preserve an offset.
- Use cleaned analytical columns for metrics and `source_*`/`source_record` for traceability.
- Count records with SQL `COUNT(*)`, not a nullable source ID.

Notebook restart-and-run-all reproducibility across a fresh machine has not been independently verified; local paths may need updating.

## Deliverables and Status

- **Data preparation:** cleaning and validation completed for the five datasets; schema and query outputs demonstrate downstream loading and analysis.
- **MySQL:** database creation, table imports, validation, and eight analyses completed by the team; SQL and CSV results supplied for review.
- **Power BI:** dashboard completion confirmed by the team and screenshots provided.
- **Report:** 10-page PDF created with eight analyses, six SQL-derived charts, selected ranking tables, and documented limitations.
- **Remaining quality issue:** reconcile the 131.86-qtl arrival total difference before claiming exact Python/SQL agreement.

The source queries and CSV results were inspected for documentation and reporting; the live database and interactive Power BI model were not independently re-executed during report preparation.

## Main Takeaway

The project creates a traceable analytical foundation rather than hiding imperfect data. Balanced crop volumes, widespread below-benchmark price observations, and route-level duration differences can be explored with explicit denominators, source flags, and limitations.- Preserved date-format and timezone assumptions.
- Avoided unsupported corrections based on synthetic location names.
- Kept observation tables separate to prevent joins from multiplying totals.

## Validated Results

| Measure | Result |
|---|---:|
| Unique mandis | **57** |
| Arrival records after exact duplicate removal | **25,000** |
| Arrival records with valid quantities | **23,767** |
| Total valid arrivals | **6,077,460.14 quintals** |
| Price observations eligible for supplied-MSP comparison | **9,131** |
| Price observations below supplied MSP | **3,667** |
| Below supplied MSP rate | **40.16%** |
| Transport trips after exact duplicate removal | **10,000** |
| Trips with usable transit duration | **9,715** |
| Known weather sensors | **50** |

These are validated preparation-stage results. SQL and Power BI outputs should reconcile to the same definitions and eligibility filters.

## Analytical Definitions

### Crop arrivals

Arrival quantities are standardized using:

- 1 tonne = 10 quintals.
- 1 quintal = 100 kilograms.

The 1,233 negative-quantity records remain available for quality reporting but do not contribute to cleaned arrival totals.

Crop labels are grouped into Wheat, Rice, Maize, Mustard, Cotton, and Sugarcane. Original labels are retained because broad reporting groups do not establish product or variety equivalence.

### Prices versus supplied MSP

**Below supplied MSP rate = observations below supplied MSP ÷ observations with both modal price and MSP.**

The denominator is 9,131 eligible price observations—not all records or unique mandis.

Currency is identified as INR, but the quantity basis is unspecified. Modal price and supplied MSP are compared on the common basis implied by the challenge. We do not label prices as INR per quintal or present supplied benchmarks as externally verified official rates.

### Transit duration

The final duration uses:

1. A positive elapsed duration from complete timestamps.
2. A positive reported duration when timestamp calculation is unavailable.
3. A missing value when neither is usable.

| Source | Trips |
|---|---:|
| Calculated from timestamps | 7,359 |
| Reported fallback | 2,356 |
| Unavailable or invalid | 285 |

Across 6,603 comparable positive-duration pairs, the largest difference was approximately 59 seconds, consistent with rounding and timestamp precision.

Reported fallbacks remain separately identifiable.

### Weather measurements

- Fahrenheit is converted using `(F − 32) × 5/9`.
- Inches of rainfall are converted using `inches × 25.4`.
- Negative rainfall is excluded from cleaned rainfall measurements.
- Humidity must fall within 0–100%.
- Explicit UTC timestamps are converted to IST before deriving the reporting date.

Two readings share the same sensor and timestamp but contain conflicting measurements. Both are retained and excluded from weather aggregates.

## Assumptions and Limitations

### Ambiguous dates

Numeric date formats were interpreted using conventions supported by the observed data. Ambiguous cases remain flagged:

- Arrivals: **4,703 records**.
- Prices: **2,262 records**.

A sensitivity check showed similar broad monthly Wheat price trends with and without ambiguous-date observations. This does not verify individual dates or establish stability for other analytical slices.

September is a partial reporting month and must be labelled accordingly.

### Missing and conflicting locations

Price records contain substantial district disagreement with the master. Reporting districts use the matched master, while original districts and conflict flags are preserved.

- Prices without a reporting district: **2,004**.
- Master mandis with unresolved districts: **4**.

### Weather mapping and aggregation

No explicit sensor-to-district mapping is supplied. Weather remains at sensor level until a mapping is established or explicitly documented as synthetic.

The rainfall measurement interval is unspecified. We do not claim daily rainfall totals or district-level rainfall–arrival relationships without resolving these issues.

### Unsupported metrics

- Confirmed transport delay requires an SLA or promised arrival time, which is absent.
- Warehouse crop volume requires shipment quantities, which are absent.
- Revenue, ROI, and customer churn are not established by the supplied data.

A proposed route-percentile “long transit” flag is an exploratory measure, not a confirmed delay metric. Because it identifies roughly a quarter of each route’s observations by construction, it should not rank routes by delay frequency.

## Planned SQL Model

The model separates dimensions from observation tables:

| Table | Grain |
|---|---|
| Mandi dimension | One record per mandi |
| Crop dimension | One record per reporting crop |
| Date dimension | One record per date |
| Warehouse dimension | One record per warehouse |
| Arrivals fact | One retained arrival observation |
| Prices fact | One price observation |
| Transport fact | One trip |
| Weather fact | One retained sensor reading |

Standardized mandi IDs connect arrivals, prices, and transport to the master. Facts are aggregated to compatible levels before comparison.

Weather has no assumed location relationship.

## Power BI Dashboard Scope

### Executive overview
Arrival volume, price-risk coverage, transit performance, and data-quality indicators.

### Arrivals and prices
Crop trends, top mandis, modal prices versus supplied MSP, and below-MSP observations.

### Logistics
Warehouse trip counts, route durations, and calculated-versus-reported duration coverage.

### Weather and quality
Sensor-level measurements, invalid readings, missing coverage, and assumption filters.

Quality flags are available for filtering and drill-through rather than hidden from the analytical model.

## Reproducibility

The workflow uses a separate notebook for each source dataset.

1. Install the Python dependencies.
2. Configure source and output paths.
3. Run mandi master cleaning first.
4. Run the remaining cleaning notebooks.
5. Validate exported CSVs.
6. Load SQL tables and reconcile analytical totals.
7. Refresh and validate the Power BI report.

```bash
python -m pip install -r requirements.txt
python -m jupyterlab
