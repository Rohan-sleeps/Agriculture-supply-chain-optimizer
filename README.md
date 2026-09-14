# Mandi-to-Market Supply Chain Optimizer

### TransOrg AgentIQ Datathon · Track 3: AgriTech

Turning messy agricultural supply-chain data into reliable insights on crop arrivals, price risk, and transport performance.

> All datasets are synthetic and provided for educational use. Findings describe the supplied data, not real agricultural markets.

## Business Problem

Agricultural supply-chain decisions depend on consistent information across mandis, prices, transport, and weather. The supplied datasets contain multilingual crop names, mixed units, inconsistent identifiers, missing values, and conflicting records.

Our project addresses three core requirements:

1. **Data Rescue:** clean and standardize the five datasets while preserving traceability.
2. **Analytics Layer:** prepare relational data and clearly defined metrics for SQL.
3. **Executive Dashboard:** enable interactive exploration in Power BI.

The optional AI chatbot is deferred until the core solution is complete.

## Technology Stack

**Python · pandas · NumPy · Matplotlib · Seaborn · SQL · Excel · Power BI**

Python handles cleaning and validation. SQL provides the analytical model, and Power BI is the planned reporting interface.

## Datasets

| Dataset | Original records | Purpose |
|---|---:|---|
| Mandi master | 60 | Mandi identifiers, locations, types, and areas |
| Crop arrivals | 25,750 | Crop quantities, varieties, and farmer counts |
| Prices and MSP | 12,000 | Wholesale prices and supplied benchmarks |
| Transport logistics | 10,400 | Trips, distances, timestamps, and vehicles |
| Weather sensors | 15,000 | Temperature, rainfall, humidity, and timestamps |

## Data Rescue Results

| Dataset | Completed cleaning and validation |
|---|---|
| Mandi master | Removed 3 exact duplicates; retained 57 unique mandis; recovered 4 missing states from consistent master relationships |
| Arrivals | Removed 750 exact duplicates; standardized crop names and IDs; converted quantities to quintals; flagged negative quantities |
| Prices | Parsed currency strings; validated price ordering; standardized crops and IDs; preserved district conflicts and missing benchmarks |
| Transport | Removed 400 exact duplicates; converted distances to kilometres; reconciled reported and calculated durations; standardized identifiers |
| Weather | Converted temperature and rainfall units; handled UTC/IST timestamps; flagged invalid measurements and conflicting readings |

### Important quality decisions

- Preserved original values alongside cleaned fields.
- Kept missing values distinct from zero.
- Retained invalid records with flags instead of silently deleting them.
- Used the mandi master as the documented reporting-location reference.
- Preserved date-format and timezone assumptions.
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
