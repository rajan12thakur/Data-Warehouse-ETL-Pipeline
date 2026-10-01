# Issue #18 — Implement Bronze Data Ingestion

## 1. Issue Overview

### Issue Title
**Implement Configurable Bronze Data Ingestion**

### Objective

Implement the first actual data-loading step of the warehouse pipeline:

```text
External Source CSV Files
        │
        ▼
data/raw/
        │
        ▼
MySQL Bronze Loading
        │
        ▼
dw_bronze
```

The implementation uses a **full-load strategy**:

```text
TRUNCATE existing Bronze table
            ↓
Load complete source CSV
            ↓
Validate loaded data
```

The Bronze layer intentionally preserves the source-oriented structure. This issue does **not** perform business transformations, dimensional modeling, Silver transformations, or Gold modeling.

---

# 2. Scope

## Included

- Loading all six CRM/ERP CSV files.
- Using MySQL `LOAD DATA LOCAL INFILE`.
- Truncating Bronze tables before each full load.
- Skipping CSV headers.
- Parsing comma-separated data.
- Supporting values optionally enclosed in double quotes.
- Converting required empty source values to `NULL`.
- Printing progress messages.
- Validating row counts.
- Inspecting sample records.
- Inspecting table structures with `DESCRIBE`.
- Checking MySQL warnings.
- Debugging and correcting loading issues.
- Performing an end-to-end Bronze load test.

## Not Included

- Silver transformations.
- Gold dimensions/facts.
- Business rules.
- Deduplication.
- Surrogate keys.
- Primary/foreign key modeling.
- Incremental loading.
- Scheduling/orchestration.
- Airflow.
- Spark.
- Production cloud deployment.

---

# 3. Architecture at This Stage

```text
                    External Source Data
                           │
                           ▼
                  Python Acquisition
                           │
                           ▼
                     data/raw/
                    /                             /                           CRM               ERP
                │                 │
                └────────┬────────┘
                         ▼
                 Bronze Loading SQL
                         │
                         ▼
                    MySQL Server
                         │
                         ▼
                     dw_bronze
```

The project databases are:

```text
dw_bronze
dw_silver
dw_gold
```

Only `dw_bronze` is populated in this issue.

---

# 4. Source Files

```text
data/raw/
├── crm/
│   ├── cust_info.csv
│   ├── prd_info.csv
│   └── sales_details.csv
│
└── erp/
    ├── CUST_AZ12.csv
    ├── LOC_A101.csv
    └── PX_CAT_G1V2.csv
```

Mapping:

| Source System | Source File | Bronze Table |
|---|---|---|
| CRM | `cust_info.csv` | `dw_bronze.crm_cust_info` |
| CRM | `prd_info.csv` | `dw_bronze.crm_prd_info` |
| CRM | `sales_details.csv` | `dw_bronze.crm_sales_details` |
| ERP | `CUST_AZ12.csv` | `dw_bronze.erp_cust_az12` |
| ERP | `LOC_A101.csv` | `dw_bronze.erp_loc_a101` |
| ERP | `PX_CAT_G1V2.csv` | `dw_bronze.erp_px_cat_g1v2` |

---

# 5. Source Inventory

| File | Size | Rows |
|---|---:|---:|
| `cust_info.csv` | 855,395 bytes | 18,494 |
| `prd_info.csv` | 26,934 bytes | 397 |
| `sales_details.csv` | 3,588,116 bytes | 60,398 |
| `CUST_AZ12.csv` | 561,549 bytes | 18,484 |
| `LOC_A101.csv` | 402,669 bytes | 18,484 |
| `PX_CAT_G1V2.csv` | 1,169 bytes | 37 |
| **Total** | **~5.3 MB** | **116,294** |

Expected final Bronze total:

```text
116,294 rows
```

---

# 6. Bronze Tables

The six tables are:

```text
dw_bronze.crm_cust_info
dw_bronze.crm_prd_info
dw_bronze.crm_sales_details

dw_bronze.erp_cust_az12
dw_bronze.erp_loc_a101
dw_bronze.erp_px_cat_g1v2
```

The Bronze layer keeps source-oriented names and columns.

---

# 7. Why `LOAD DATA LOCAL INFILE` Was Used

MySQL provides `LOAD DATA LOCAL INFILE` for bulk loading file data.

Conceptually:

```text
CSV file
   │
   ▼
LOAD DATA LOCAL INFILE
   │
   ▼
MySQL
   │
   ▼
Bronze table
```

This avoids generating an individual `INSERT` statement for every source row.

---

# 8. MySQL Client Configuration

MySQL executable:

```text
C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe
```

MySQL version used during testing:

```text
26.7.0
```

Client command:

```powershell
& "C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe" --local-infile=1 -u root -p dw_bronze
```

Explanation:

```text
&
```

PowerShell call operator.

```text
--local-infile=1
```

Enables local file loading for the client.

```text
-u root
```

Connect as the `root` user.

```text
-p
```

Prompt for the password.

```text
dw_bronze
```

Connect directly to the Bronze database.

Never put the real database password into Git, SQL files, documentation, or shell history when it can be avoided.

---

# 9. Working Directory Requirement

The loading script uses paths such as:

```sql
data/raw/crm/cust_info.csv
```

These are relative paths.

The MySQL client therefore needs to be started from the project root:

```text
C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\Data-Warehouse-ETL-Pipeline
```

Command:

```powershell
cd "C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\Data-Warehouse-ETL-Pipeline"
```

Then:

```powershell
& "C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe" --local-infile=1 -u root -p dw_bronze
```

## Error encountered

The client was initially started from the parent `DATA WAREHOUSE` directory.

The relative path:

```text
data/raw/crm/cust_info.csv
```

was therefore resolved from the wrong location, causing a file-not-found/load failure.

## Resolution

Change into the project root first:

```powershell
cd ".\Data-Warehouse-ETL-Pipeline"
```

Then reconnect.

---

# 10. Enabling `local_infile`

Check the server setting:

```sql
SHOW VARIABLES LIKE 'local_infile';
```

It was initially disabled.

Enable it:

```sql
SET GLOBAL local_infile = 1;
```

The client is also started with:

```powershell
--local-infile=1
```

So the setup is:

```text
MySQL Server
    local_infile = 1

        +

MySQL Client
    --local-infile=1
```

---

# 11. Full-Load Strategy

For every Bronze table:

```text
Existing data
      │
      ▼
TRUNCATE TABLE
      │
      ▼
Empty table
      │
      ▼
LOAD DATA LOCAL INFILE
      │
      ▼
Current complete source snapshot
```

Why?

If the source has 18,494 rows and the same file is loaded twice without clearing the target:

```text
First load = 18,494
Second load = another 18,494

Total = 36,988
```

Therefore:

```sql
TRUNCATE TABLE target_table;
```

is executed before every full load.

---

# 12. Loading Script

File:

```text
sql/bronze/loading/load_bronze.sql
```

Responsibilities:

1. Print progress.
2. Truncate the target.
3. Load the CSV.
4. Skip the header.
5. Preserve source column order.
6. Convert required empty values to `NULL`.
7. Print completion.

---

# 13. Final `load_bronze.sql`

```sql
/*
===============================================================================
Bronze Layer: Full Load Script
===============================================================================
Purpose:
    Load all CRM and ERP CSV files from the raw data directory into the
    corresponding Bronze tables.

Loading Strategy:
    1. Truncate the existing Bronze table.
    2. Bulk load the complete CSV file.
    3. Repeat for all six source tables.

This is a FULL LOAD strategy.

Important:
    - No business transformations are performed.
    - Source column order is preserved.
    - CSV headers are skipped.
    - Comma is used as the field delimiter.
    - CSV values may optionally be enclosed by double quotes.
    - Empty source values are loaded as NULL where required.
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Loading CRM tables' AS message;
SELECT '============================================================' AS message;

SELECT '>> Truncating dw_bronze.crm_cust_info' AS message;
TRUNCATE TABLE dw_bronze.crm_cust_info;
SELECT '>> Loading data into dw_bronze.crm_cust_info' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/cust_info.csv'
INTO TABLE dw_bronze.crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES
(
    @cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    @cst_create_date
)
SET
    cst_id = NULLIF(@cst_id, ''),
    cst_create_date = NULLIF(@cst_create_date, '');

SELECT '>> crm_cust_info load completed' AS message;

SELECT '>> Truncating dw_bronze.crm_prd_info' AS message;
TRUNCATE TABLE dw_bronze.crm_prd_info;
SELECT '>> Loading data into dw_bronze.crm_prd_info' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/prd_info.csv'
INTO TABLE dw_bronze.crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES
(
    prd_id,
    prd_key,
    prd_nm,
    @prd_cost,
    prd_line,
    prd_start_dt,
    @prd_end_dt
)
SET
    prd_cost = NULLIF(@prd_cost, ''),
    prd_end_dt = NULLIF(@prd_end_dt, '');

SELECT '>> crm_prd_info load completed' AS message;

SELECT '>> Truncating dw_bronze.crm_sales_details' AS message;
TRUNCATE TABLE dw_bronze.crm_sales_details;
SELECT '>> Loading data into dw_bronze.crm_sales_details' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/sales_details.csv'
INTO TABLE dw_bronze.crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    @sls_sales,
    sls_quantity,
    @sls_price
)
SET
    sls_sales = NULLIF(@sls_sales, ''),
    sls_price = NULLIF(@sls_price, '');

SELECT '>> crm_sales_details load completed' AS message;

SELECT '============================================================' AS message;
SELECT 'Loading ERP tables' AS message;
SELECT '============================================================' AS message;

SELECT '>> Truncating dw_bronze.erp_cust_az12' AS message;
TRUNCATE TABLE dw_bronze.erp_cust_az12;
SELECT '>> Loading data into dw_bronze.erp_cust_az12' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/CUST_AZ12.csv'
INTO TABLE dw_bronze.erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES
(
    cid,
    bdate,
    @gen
)
SET
    gen = NULLIF(@gen, '');

SELECT '>> erp_cust_az12 load completed' AS message;

SELECT '>> Truncating dw_bronze.erp_loc_a101' AS message;
TRUNCATE TABLE dw_bronze.erp_loc_a101;
SELECT '>> Loading data into dw_bronze.erp_loc_a101' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/LOC_A101.csv'
INTO TABLE dw_bronze.erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES;

SELECT '>> erp_loc_a101 load completed' AS message;

SELECT '>> Truncating dw_bronze.erp_px_cat_g1v2' AS message;
TRUNCATE TABLE dw_bronze.erp_px_cat_g1v2;
SELECT '>> Loading data into dw_bronze.erp_px_cat_g1v2' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/PX_CAT_G1V2.csv'
INTO TABLE dw_bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES;

SELECT '>> erp_px_cat_g1v2 load completed' AS message;

SELECT '============================================================' AS message;
SELECT 'Bronze layer full load completed' AS message;
SELECT '============================================================' AS message;
```

---

# 14. Meaning of the `LOAD DATA` Options

General form:

```sql
LOAD DATA LOCAL INFILE 'file_path'
INTO TABLE target_table
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES;
```

### `LOAD DATA LOCAL INFILE`

Reads a local file through the client and loads it into MySQL.

### `INTO TABLE`

Defines the destination.

Example:

```sql
INTO TABLE dw_bronze.crm_cust_info
```

### `FIELDS TERMINATED BY ','`

The source is comma-separated.

### `OPTIONALLY ENCLOSED BY '"'`

Supports values enclosed in double quotes.

### `LINES TERMINATED BY '
'`

Matches the Windows line-ending format of the source files.

### `IGNORE 1 LINES`

Skips the CSV header.

For example:

```text
cst_id,cst_key,cst_firstname,...
11000,AW00011000,Jon,...
```

The first line is metadata, not a data record.

---

# 15. Why User Variables Were Added

The first implementation attempted direct loading into typed columns.

Some source values were empty:

```text
''
```

The target column might be:

```sql
INT
```

or:

```sql
DATE
```

Direct conversion produced warnings.

The improved pattern is:

```sql
@value
```

followed by:

```sql
NULLIF(@value, '')
```

Conceptually:

```text
source
  │
  ▼
@value
  │
  ▼
NULLIF(@value, '')
  │
  ├── ''       → NULL
  │
  └── nonempty → original value
  │
  ▼
target column
```

This keeps legitimate missing source values instead of forcing invalid conversions.

---

# 16. Errors and Warnings From the First Load

The initial load produced:

```text
crm_cust_info       18,494 rows   8 warnings
crm_prd_info           397 rows 199 warnings
crm_sales_details   60,398 rows  15 warnings
erp_cust_az12       18,484 rows   1 warning
erp_loc_a101        18,484 rows   0 warnings
erp_px_cat_g1v2         37 rows   0 warnings
```

The row counts were correct, but the warnings showed that some source values were being converted improperly.

The warnings were investigated rather than ignored.

---

# 17. `SHOW WARNINGS` Must Be Run Immediately

After:

```sql
LOAD DATA ...
```

run:

```sql
SHOW WARNINGS;
```

immediately.

Correct:

```sql
LOAD DATA LOCAL INFILE ...;

SHOW WARNINGS;
```

Do not insert unrelated statements before `SHOW WARNINGS` when investigating a load.

Later statements can replace the warning context.

---

# 18. CRM Customer Warning

Affected fields:

```text
cst_id
cst_create_date
```

Examples found in the source:

```text
,SF566,,,,,
,PO25,,,,,
,13451235,,,,,
,A01Ass,,,,,
```

These are valid rows with empty fields.

The correct representation in Bronze is:

```text
empty source field
        ↓
NULL
```

The fix was:

```sql
(
    @cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    @cst_create_date
)
SET
    cst_id = NULLIF(@cst_id, ''),
    cst_create_date = NULLIF(@cst_create_date, '');
```

---

# 19. CRM Product Warnings

Affected fields:

```text
prd_cost
prd_end_dt
```

The source contains empty values.

Direct loading attempted conversions such as:

```text
'' → INT
'' → DATE
```

and generated warnings.

Fix:

```sql
(
    prd_id,
    prd_key,
    prd_nm,
    @prd_cost,
    prd_line,
    prd_start_dt,
    @prd_end_dt
)
SET
    prd_cost = NULLIF(@prd_cost, ''),
    prd_end_dt = NULLIF(@prd_end_dt, '');
```

---

# 20. CRM Sales Warnings

Affected fields:

```text
sls_sales
sls_price
```

Some source records contain empty values.

Fix:

```sql
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    @sls_sales,
    sls_quantity,
    @sls_price
)
SET
    sls_sales = NULLIF(@sls_sales, ''),
    sls_price = NULLIF(@sls_price, '');
```

---

# 21. ERP Customer Warning

Affected field:

```text
gen
```

Source examples:

```text
AW00029481,1965-07-04,
AW00029482,1964-09-01,
AW00029483,1965-06-06,
```

The third field exists but is empty.

Fix:

```sql
(
    cid,
    bdate,
    @gen
)
SET
    gen = NULLIF(@gen, '');
```

---

# 22. Why the Warnings Were Fixed

A correct row count does not automatically mean a correct load.

Example:

```text
Expected = 397
Loaded   = 397
```

There could still be:

```text
conversion warnings
truncated values
unexpected NULLs
incorrect parsing
```

Therefore Bronze validation considers:

```text
Row count
+
Schema
+
Sample records
+
Warnings
```

---

# 23. Validation Script

File:

```text
sql/bronze/validations/validate_bronze.sql
```

A reproducible validation script is:

```sql
/*
===============================================================================
Bronze Layer: Validation Script
===============================================================================
Purpose:
    Validate the six Bronze tables after loading.

Checks:
    1. Row counts.
    2. Sample records.
    3. Table structures.
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Bronze row counts' AS message;
SELECT '============================================================' AS message;

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.crm_cust_info;

SELECT 'crm_prd_info' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.crm_prd_info;

SELECT 'crm_sales_details' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.crm_sales_details;

SELECT 'erp_cust_az12' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.erp_cust_az12;

SELECT 'erp_loc_a101' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.erp_loc_a101;

SELECT 'erp_px_cat_g1v2' AS table_name, COUNT(*) AS row_count
FROM dw_bronze.erp_px_cat_g1v2;


SELECT '============================================================' AS message;
SELECT 'Bronze sample records' AS message;
SELECT '============================================================' AS message;

SELECT * FROM dw_bronze.crm_cust_info LIMIT 5;

SELECT * FROM dw_bronze.crm_prd_info LIMIT 5;

SELECT * FROM dw_bronze.crm_sales_details LIMIT 5;

SELECT * FROM dw_bronze.erp_cust_az12 LIMIT 5;

SELECT * FROM dw_bronze.erp_loc_a101 LIMIT 5;

SELECT * FROM dw_bronze.erp_px_cat_g1v2 LIMIT 5;


SELECT '============================================================' AS message;
SELECT 'Bronze table structures' AS message;
SELECT '============================================================' AS message;

DESCRIBE dw_bronze.crm_cust_info;

DESCRIBE dw_bronze.crm_prd_info;

DESCRIBE dw_bronze.crm_sales_details;

DESCRIBE dw_bronze.erp_cust_az12;

DESCRIBE dw_bronze.erp_loc_a101;

DESCRIBE dw_bronze.erp_px_cat_g1v2;
```

---

# 24. Running the Loader

From MySQL:

```sql
SOURCE sql/bronze/loading/load_bronze.sql;
```

Then:

```sql
SOURCE sql/bronze/validations/validate_bronze.sql;
```

`SOURCE` is a MySQL client command that reads and executes the SQL file.

---

# 25. Final Successful Results

| Bronze Table | Final Rows | Warnings |
|---|---:|---:|
| `crm_cust_info` | 18,494 | 0 |
| `crm_prd_info` | 397 | 0 |
| `crm_sales_details` | 60,398 | 0 |
| `erp_cust_az12` | 18,484 | 0 |
| `erp_loc_a101` | 18,484 | 0 |
| `erp_px_cat_g1v2` | 37 | 0 |
| **Total** | **116,294** | **0** |

Final state:

```text
116,294 Bronze records
0 load warnings
```

---

# 26. Final Row-Count Calculation

```text
18,494
+   397
+60,398
+18,484
+18,484
+    37
-------
116,294
```

The Bronze total matched the expected source total.

---

# 27. Sample Data Verification

Samples were checked from all six tables.

The CRM customer table contains:

```text
cst_id
cst_key
cst_firstname
cst_lastname
cst_marital_status
cst_gndr
cst_create_date
```

The CRM product table contains:

```text
prd_id
prd_key
prd_nm
prd_cost
prd_line
prd_start_dt
prd_end_dt
```

The sales table contains:

```text
sls_ord_num
sls_prd_key
sls_cust_id
sls_order_dt
sls_ship_dt
sls_due_dt
sls_sales
sls_quantity
sls_price
```

The ERP tables were also sampled.

This matters because row counts alone cannot prove that columns were mapped correctly.

---

# 28. Schema Verification

Commands:

```sql
DESCRIBE dw_bronze.crm_cust_info;
DESCRIBE dw_bronze.crm_prd_info;
DESCRIBE dw_bronze.crm_sales_details;
DESCRIBE dw_bronze.erp_cust_az12;
DESCRIBE dw_bronze.erp_loc_a101;
DESCRIBE dw_bronze.erp_px_cat_g1v2;
```

The final structures matched the intended Bronze definitions.

---

# 29. DDL vs Loading

Two separate responsibilities exist.

## DDL

File:

```text
sql/bronze/tables/create_bronze_tables.sql
```

Purpose:

```text
Define/redefine table structure
```

Development pattern:

```sql
DROP TABLE IF EXISTS ...
CREATE TABLE ...
```

## Loading

File:

```text
sql/bronze/loading/load_bronze.sql
```

Purpose:

```text
Put source data into existing tables
```

Full-load pattern:

```sql
TRUNCATE TABLE ...
LOAD DATA ...
```

Simple mental model:

```text
DDL
=
What does the table look like?

Loading
=
What data goes into the table?
```

---

# 30. Why Loading Does Not Drop and Recreate Tables

The loader should not do:

```sql
DROP TABLE
CREATE TABLE
LOAD DATA
```

on every execution.

Instead:

```sql
TRUNCATE TABLE
LOAD DATA
```

The table definition remains intact while its contents are replaced by the current source snapshot.

---

# 31. Bronze Is Not the Place for Business Transformations

This issue deliberately does not:

```text
rename business fields
join source systems
calculate business metrics
deduplicate records
create surrogate keys
apply dimensional modeling
create facts/dimensions
```

The goal is to establish a reliable source-preserving layer first.

The `NULLIF` handling is different: it is required to correctly represent empty source fields in typed MySQL columns during ingestion.

---

# 32. Debugging Workflow

The actual debugging pattern was:

```text
Run load
   ↓
Observe warnings
   ↓
SHOW WARNINGS
   ↓
Identify affected column
   ↓
Inspect source records
   ↓
Understand the source condition
   ↓
Modify loading mapping
   ↓
TRUNCATE
   ↓
Reload
   ↓
SHOW WARNINGS
   ↓
Validate row counts
   ↓
Validate sample records
   ↓
Validate schema
```

This is a useful general data-engineering workflow because the source data, not assumptions, determines the loading behavior.

---

# 33. MySQL Screen-Clearing Issue

These were attempted:

```text
\! clear
```

and:

```text
\! cls
```

The MySQL client reported that system-command execution was disabled.

This was unrelated to the data pipeline.

The practical solution:

```sql
exit
```

Then in PowerShell:

```powershell
cls
```

---

# 34. Complete Reproducible Test

## Step 1 — Go to project root

```powershell
cd "C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\Data-Warehouse-ETL-Pipeline"
```

## Step 2 — Activate environment if required

```powershell
.\.venv\Scripts\Activate.ps1
```

## Step 3 — Start MySQL

```powershell
& "C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe" --local-infile=1 -u root -p dw_bronze
```

## Step 4 — Confirm database

```sql
SELECT DATABASE();
```

Expected:

```text
dw_bronze
```

## Step 5 — Load Bronze

```sql
SOURCE sql/bronze/loading/load_bronze.sql;
```

## Step 6 — Validate

```sql
SOURCE sql/bronze/validations/validate_bronze.sql;
```

## Step 7 — Calculate total

```sql
SELECT
    (SELECT COUNT(*) FROM dw_bronze.crm_cust_info)
  + (SELECT COUNT(*) FROM dw_bronze.crm_prd_info)
  + (SELECT COUNT(*) FROM dw_bronze.crm_sales_details)
  + (SELECT COUNT(*) FROM dw_bronze.erp_cust_az12)
  + (SELECT COUNT(*) FROM dw_bronze.erp_loc_a101)
  + (SELECT COUNT(*) FROM dw_bronze.erp_px_cat_g1v2)
  AS total_bronze_rows;
```

Expected:

```text
116294
```

---

# 35. Useful Manual Validation Queries

## Count one table

```sql
SELECT COUNT(*)
FROM dw_bronze.crm_cust_info;
```

## Inspect data

```sql
SELECT *
FROM dw_bronze.crm_cust_info
LIMIT 10;
```

## Check missing customer IDs

```sql
SELECT COUNT(*)
FROM dw_bronze.crm_cust_info
WHERE cst_id IS NULL;
```

## Inspect missing product values

```sql
SELECT *
FROM dw_bronze.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_end_dt IS NULL
LIMIT 20;
```

## Inspect missing sales values

```sql
SELECT *
FROM dw_bronze.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_price IS NULL
LIMIT 20;
```

## Inspect missing ERP gender

```sql
SELECT *
FROM dw_bronze.erp_cust_az12
WHERE gen IS NULL
LIMIT 20;
```

---

# 36. Repository Files for This Issue

```text
sql/
└── bronze/
    ├── tables/
    │   └── create_bronze_tables.sql
    │
    ├── loading/
    │   └── load_bronze.sql
    │
    └── validations/
        └── validate_bronze.sql
```

Responsibilities:

```text
tables/
    table definitions

loading/
    ingestion

validations/
    post-load verification
```

---

# 37. Git Workflow

After implementation and testing:

```powershell
git status
```

Review the SQL changes:

```powershell
git diff -- sql/bronze/tables/create_bronze_tables.sql sql/bronze/loading/load_bronze.sql sql/bronze/validations/validate_bronze.sql
```

Check that generated/raw CSV files are not unexpectedly staged.

Then:

```powershell
git status
```

---

# 38. Stage the Implementation

```powershell
git add sql/bronze/tables/create_bronze_tables.sql
git add sql/bronze/loading/load_bronze.sql
git add sql/bronze/validations/validate_bronze.sql
```

Then:

```powershell
git status
```

Review exactly what will be committed.

---

# 39. Commit

Recommended commit:

```powershell
git commit -m "feat(bronze): implement full source data ingestion"
```

Meaning:

```text
feat
```

A functional feature was added.

```text
(bronze)
```

The feature belongs to the Bronze layer.

```text
implement full source data ingestion
```

Describes the change.

---

# 40. Push

Feature branch:

```text
18-coding-bronze-data-ingestion
```

Push:

```powershell
git push -u origin 18-coding-bronze-data-ingestion
```

Future pushes can then use:

```powershell
git push
```

---

# 41. Pull Request

The project workflow is:

```text
feature branch
      ↓
Pull Request
      ↓
develop
      ↓
later integration
      ↓
main
```

Issue #18 should therefore target:

```text
develop
```

Suggested PR title:

```text
feat(bronze): implement full source data ingestion
```

Suggested PR description:

```markdown
## Summary

Implemented full Bronze-layer ingestion for the six CRM and ERP source CSV files.

## What was implemented

- Added full-load Bronze ingestion using MySQL LOAD DATA LOCAL INFILE.
- Added TRUNCATE-before-load behavior.
- Added CSV header skipping.
- Added CSV delimiter and quoting configuration.
- Added NULL handling for empty source values.
- Added progress messages.
- Added Bronze validation queries.
- Verified row counts, sample records, schemas, and load warnings.

## Source-to-target mappings

- cust_info.csv -> dw_bronze.crm_cust_info
- prd_info.csv -> dw_bronze.crm_prd_info
- sales_details.csv -> dw_bronze.crm_sales_details
- CUST_AZ12.csv -> dw_bronze.erp_cust_az12
- LOC_A101.csv -> dw_bronze.erp_loc_a101
- PX_CAT_G1V2.csv -> dw_bronze.erp_px_cat_g1v2

## Validation

Final Bronze row count:

116,294

Final load warnings:

0

All six source files loaded successfully.
```

---

# 42. Acceptance Criteria

- [x] Six source CSV files can be loaded.
- [x] Six corresponding Bronze tables exist.
- [x] Full-load behavior is implemented.
- [x] Existing Bronze data is truncated before reload.
- [x] CSV headers are ignored.
- [x] CSV fields use comma delimiters.
- [x] Quoted CSV values are supported.
- [x] Empty source values requiring special handling are converted to `NULL`.
- [x] No business transformations are performed.
- [x] Progress messages are printed.
- [x] Row counts are validated.
- [x] Sample records are inspected.
- [x] Bronze schemas are inspected.
- [x] Initial warnings were investigated.
- [x] Initial warnings were resolved.
- [x] Final load completed with zero warnings.
- [x] Total Bronze row count is 116,294.

---

# 43. Final Data Flow

```text
                    SOURCE SYSTEMS
                         │
             ┌───────────┴───────────┐
             │                       │
            CRM                     ERP
             │                       │
             ▼                       ▼
       source_crm/              source_erp/
             │                       │
             └───────────┬───────────┘
                         │
                         ▼
                Python Acquisition
                         │
                         ▼
                     data/raw/
                    /                             /                            crm              erp
                 │                │
                 └───────┬────────┘
                         │
                         ▼
              MySQL LOAD DATA LOCAL INFILE
                         │
                         ▼
                    dw_bronze
                         │
                         ▼
                 Bronze Validation
```

---

# 44. Engineering Outcome

Before this issue:

```text
Source files
    ↓
Raw files
    ↓
Empty Bronze tables
```

After this issue:

```text
Source files
    ↓
Raw files
    ↓
Bronze ingestion
    ↓
Populated dw_bronze
    ↓
Validation
```

Final state:

```text
6 source files
6 Bronze tables
116,294 Bronze records
0 final load warnings
```

---

# 45. Key Engineering Lessons

## 1. Loading is more than writing one SQL statement

A reliable ingestion process requires:

```text
source understanding
+
file path handling
+
database configuration
+
load logic
+
warning investigation
+
validation
```

## 2. Row count alone is insufficient

A load can have the expected row count and still have conversion problems.

Therefore check:

```text
row count
+
schema
+
sample data
+
warnings
```

## 3. Source data determines the loading logic

The initial warnings revealed actual missing values in the source.

The loader was then adapted to represent those values correctly.

## 4. Full loading requires duplicate protection

Because the complete source snapshot is loaded each time:

```text
TRUNCATE
+
LOAD
```

prevents duplicate accumulation.

## 5. Debugging is part of data engineering

The final clean load came from:

```text
run
→ observe
→ investigate
→ understand
→ modify
→ rerun
→ validate
```

---

# 46. Final Issue Status

```text
Issue: #18
Implementation: Completed
Integration test: Completed

Source files:        6
Bronze tables:       6
Bronze rows:         116,294
Final load warnings: 0

Loading strategy:
    Full load

Load mechanism:
    MySQL LOAD DATA LOCAL INFILE

Validation:
    Row counts
    Sample records
    Table structures
    Warning inspection

Result:
    Successful Bronze ingestion
```

The next stage should build on this validated Bronze layer rather than mixing downstream transformations into the ingestion implementation.
