# Issue #10 — Design Configurable Source Acquisition and Landing Strategy

## 1. Issue Overview

**Issue:** #10  
**Title:** Design Configurable Source Acquisition and Landing Strategy  
**Status:** Design completed  
**Branch:** `10-design-source-acquisition-and-landing-strategy`

### Objective

Design how source files from the CRM and ERP systems are acquired from an external source location and copied into the project's raw/landing area before Bronze ingestion.

The design must:

- Keep the source location configurable.
- Avoid hard-coded machine-specific paths in Python.
- Preserve source files and filenames.
- Keep external source data outside the Git repository.
- Provide a clear boundary between source acquisition and Bronze ingestion.
- Be generic enough to discover source files without creating one Python function per file.
- Establish a foundation for the implementation work planned in the next issue.

---

# 2. Project Context

This project is a portfolio Data Engineering project that implements a layered Data Warehouse ETL pipeline using:

- **Python** for orchestration/acquisition scripts.
- **MySQL** for the warehouse.
- **CSV** as the current source-file format.
- **Git/GitHub** for version control and collaboration workflow.
- **`.env` / environment variables** for machine-specific configuration.
- **Bronze / Silver / Gold** layers for the warehouse architecture.

The target warehouse architecture is:

```text
MySQL Server
├── dw_bronze
├── dw_silver
└── dw_gold
```

The source-acquisition flow designed in this issue is:

```text
External Source Data
        │
        ▼
Python Source Acquisition
        │
        ▼
Project Raw / Landing
        │
        ▼
Bronze Ingestion
        │
        ▼
MySQL dw_bronze
```

The important architectural boundary is:

> **Source acquisition gets the source data into the project's raw/landing area. Bronze ingestion loads that acquired data into the Bronze warehouse layer.**

These are separate responsibilities.

---

# 3. Relationship to the Source-System Analysis Work

Before designing acquisition, the source systems were analyzed conceptually.

The source-analysis approach followed the principle that data engineering should not begin by immediately writing code. The source system needs to be understood first.

The source-analysis work covered questions such as:

- What source systems exist?
- Who owns the source?
- What business process does the source support?
- What tables/files exist?
- What does each column mean?
- What technology does the source use?
- How can data be extracted?
- Is extraction full or incremental?
- How large are the extracts?
- How frequently does data change?
- What authentication is required?
- What source limitations exist?

The outcome of that analysis is converted into engineering decisions.

The resulting mental model is:

```text
Question
   ↓
Source-system answer
   ↓
Understanding
   ↓
Engineering decision
   ↓
Pipeline design
```

For this portfolio project, actual interviews with real source-system owners were not performed. The available CRM and ERP source files are therefore treated as the project's source-system input for design purposes rather than claiming that real external source interviews took place.

---

# 4. Actual Source Location

The source data currently exists outside the Git repository.

Current local source root:

```text
C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\DATA SOURCES
```

The source directory is a sibling of the project repository rather than being treated as project-controlled source data.

Current source structure:

```text
DATA SOURCES/
├── source_crm/
│   ├── cust_info.csv
│   ├── prd_info.csv
│   └── sales_details.csv
└── source_erp/
    ├── CUST_AZ12.csv
    ├── LOC_A101.csv
    └── PX_CAT_G1V2.csv
```

This distinction is intentional.

The project repository contains the ETL code, SQL, documentation, tests, and controlled project structure.

The source data is kept externally.

---

# 5. Source Inventory

The source inventory was inspected before finalizing the acquisition design.

## 5.1 File Inventory

| Source System | File | Size |
|---|---|---:|
| CRM | `cust_info.csv` | 835.35 KB |
| CRM | `prd_info.csv` | 26.30 KB |
| CRM | `sales_details.csv` | 3504.02 KB |
| ERP | `CUST_AZ12.csv` | 548.39 KB |
| ERP | `LOC_A101.csv` | 393.23 KB |
| ERP | `PX_CAT_G1V2.csv` | 1.14 KB |

The total source size is approximately **5.3 MB**.

The source data is therefore small enough for a Python standard-library based acquisition process.

---

# 6. Source Row Counts

The following row-count inspection was performed:

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        $rowCount = (Get-Content $_.FullName | Measure-Object -Line).Lines - 1

        [PSCustomObject]@{
            File     = $_.Name
            Source   = $_.Directory.Name
            Size_KB  = [math]::Round($_.Length / 1KB, 2)
            Rows     = $rowCount
        }
    }
```

Observed result:

| File | Source | Size (KB) | Rows |
|---|---|---:|---:|
| `cust_info.csv` | `source_crm` | 835.35 | 18,494 |
| `prd_info.csv` | `source_crm` | 26.30 | 397 |
| `sales_details.csv` | `source_crm` | 3504.02 | 60,398 |
| `CUST_AZ12.csv` | `source_erp` | 548.39 | 18,484 |
| `LOC_A101.csv` | `source_erp` | 393.23 | 18,484 |
| `PX_CAT_G1V2.csv` | `source_erp` | 1.14 | 37 |

Approximate total:

```text
~116,294 data rows
~5.3 MB
```

### Important

The different row counts between CRM and ERP customer-related files were observed during source inspection.

This issue is about **source acquisition and landing design**, not source-data quality analysis.

Therefore, the acquisition layer should not silently modify, reconcile, deduplicate, or "fix" these differences.

Those questions belong to later data-quality / transformation work.

---

# 7. Source Header and Schema Inspection

The following command was used to inspect the first line of every CSV:

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        Write-Host "`n===== $($_.FullName) ====="
        Get-Content $_.FullName -TotalCount 1
    }
```

Observed headers:

### CRM — `cust_info.csv`

```text
cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date
```

### CRM — `prd_info.csv`

```text
prd_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
```

### CRM — `sales_details.csv`

```text
sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price
```

### ERP — `CUST_AZ12.csv`

```text
CID,BDATE,GEN
```

### ERP — `LOC_A101.csv`

```text
CID,CNTRY
```

### ERP — `PX_CAT_G1V2.csv`

```text
ID,CAT,SUBCAT,MAINTENANCE
```

This inspection confirmed that the current source files are CSV files with header rows.

---

# 8. First-Record Inspection

The following command was used to inspect both the header and first data record:

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        $firstTwoLines = Get-Content $_.FullName -TotalCount 2

        [PSCustomObject]@{
            File        = $_.Name
            Source      = $_.Directory.Name
            Size_KB     = [math]::Round($_.Length / 1KB, 2)
            FirstLine   = $firstTwoLines[0]
            SecondLine  = $firstTwoLines[1]
        }
    }
```

Observed examples:

### `cust_info.csv`

```text
Header:
cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date

First record:
11000,AW00011000, Jon,Yang ,M,M,2025-10-06
```

### `prd_info.csv`

```text
Header:
prd_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt

First record:
210,CO-RF-FR-R92B-58,HL Road Frame - Black- 58,,R ,2003-07-01,
```

### `sales_details.csv`

```text
Header:
sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price

First record:
SO43697,BK-R93R-62,21768,20101229,20110105,20110110,3578,1,3578
```

### `CUST_AZ12.csv`

```text
Header:
CID,BDATE,GEN

First record:
NASAW00011000,1971-10-06,Male
```

### `LOC_A101.csv`

```text
Header:
CID,CNTRY

First record:
AW-00011000,Australia
```

### `PX_CAT_G1V2.csv`

```text
Header:
ID,CAT,SUBCAT,MAINTENANCE

First record:
AC_BR,Accessories,Bike Racks,Yes
```

This inspection was used to confirm that the source files contain actual tabular data and that the source filenames and structures should be preserved during acquisition.

---

# 9. Important Source Naming Observation

The CRM and ERP sources use different naming conventions.

CRM files have descriptive names:

```text
cust_info.csv
prd_info.csv
sales_details.csv
```

ERP files have coded names:

```text
CUST_AZ12.csv
LOC_A101.csv
PX_CAT_G1V2.csv
```

### Design decision

The acquisition process will **preserve the original source filenames**.

It will not rename:

```text
CUST_AZ12.csv
```

into something like:

```text
customer.csv
```

during source acquisition.

Likewise:

```text
cust_info.csv
```

will remain:

```text
cust_info.csv
```

### Why?

Source acquisition should preserve source identity and traceability.

Renaming based on assumptions about business meaning would introduce transformation logic into the acquisition layer.

Naming interpretation and business modeling belong later.

---

# 10. Chosen Source Configuration Strategy

The source location will be configured through an environment variable.

The chosen configuration is:

```env
SOURCE_DATA_PATH=<path-to-external-source-root>
```

For the local machine, `.env` will contain the actual path:

```env
SOURCE_DATA_PATH=C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\DATA SOURCES
```

The exact local path is machine-specific and therefore must not be committed to Git.

---

# 11. Why Only One Source Root Variable?

The design deliberately uses:

```env
SOURCE_DATA_PATH
```

instead of separate configuration values such as:

```env
CRM_SOURCE_PATH=...
ERP_SOURCE_PATH=...
```

The source hierarchy already provides the separation:

```text
SOURCE_DATA_PATH/
├── source_crm/
└── source_erp/
```

Therefore Python can derive the individual source directories:

```text
SOURCE_DATA_PATH/source_crm
SOURCE_DATA_PATH/source_erp
```

This avoids unnecessary duplication in configuration.

### Chosen design

```text
SOURCE_DATA_PATH
        │
        ├── source_crm
        │     ├── cust_info.csv
        │     ├── prd_info.csv
        │     └── sales_details.csv
        │
        └── source_erp
              ├── CUST_AZ12.csv
              ├── LOC_A101.csv
              └── PX_CAT_G1V2.csv
```

---

# 12. `.env` and `.env.example`

The project already uses environment-based configuration for database connectivity.

The source acquisition design extends this principle to source location.

## `.env`

The local `.env` contains machine-specific configuration.

Example:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password

SOURCE_DATA_PATH=C:\path\to\DATA SOURCES
```

The actual local database password is never committed.

## `.env.example`

The repository should contain a safe template:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password

SOURCE_DATA_PATH=C:\path\to\DATA SOURCES
```

The `.env.example` communicates the required configuration without exposing machine-specific secrets or paths.

---

# 13. Why Hard-Coded Paths Are Rejected

The Python code must NOT contain:

```python
source_path = r"C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\DATA SOURCES"
```

This is rejected because it makes the code machine-specific.

If another developer clones the repository, the path may be completely different.

For example:

```text
C:\Projects\Data-Warehouse\DATA SOURCES
```

would require source-code modification.

That violates the desired configuration principle.

Instead:

```text
Python
  ↓
read SOURCE_DATA_PATH
  ↓
construct source directories
```

Changing the environment should change the source location without changing Python code.

---

# 14. External Source Data vs Git Repository

The source data will remain outside the Git repository.

The intended separation is:

```text
DATA WAREHOUSE/
├── DATA SOURCES/                 ← external source data
│   ├── source_crm/
│   └── source_erp/
│
└── DATA-WAREHOUSE-ETL-PIPELINE/  ← Git repository
    ├── data/
    ├── docs/
    ├── scripts/
    ├── sql/
    ├── tests/
    └── ...
```

This is deliberate.

The repository should contain the engineering solution, not the complete external source system.

---

# 15. Raw / Landing Destination

The project already has:

```text
data/
└── raw/
    ├── crm/
    └── erp/
```

These directories represent the project's raw/landing area.

The acquisition process will copy files into:

```text
data/raw/crm/
data/raw/erp/
```

Therefore:

```text
External Source
       │
       │ copy
       ▼
data/raw/
```

The expected result is:

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

---

# 16. Copy, Do Not Move

The selected acquisition behavior is:

> **Copy source files into the raw/landing area.**

The source files will not be moved.

Conceptually:

```text
SOURCE
  │
  ├──────────────► RAW
  │
  └── remains available
```

Not:

```text
SOURCE
  │
  └── move ──────► RAW
                   source disappears
```

### Why?

The external source represents the source system.

The raw directory is the pipeline's working landing area.

The acquisition process should not modify or destroy the source system's files.

---

# 17. Preserve Source Files

The acquisition layer should perform a minimal operation:

```text
discover
   ↓
validate existence
   ↓
copy
```

It should not perform transformations such as:

- changing column names
- changing data types
- trimming values
- converting dates
- removing duplicates
- filtering rows
- joining CRM and ERP
- changing business meanings
- renaming source columns
- calculating business metrics

Those are later pipeline responsibilities.

---

# 18. Re-run Behavior

The current design assumes the raw/landing copy represents the latest source snapshot.

Therefore, when the acquisition script is run again, an existing destination file can be replaced by the latest source copy.

Conceptually:

```text
Run 1
SOURCE → RAW

Run 2
SOURCE → RAW
        ↓
existing raw copy replaced
```

This avoids accumulating duplicate copies such as:

```text
cust_info.csv
cust_info_1.csv
cust_info_2.csv
```

The acquisition process is therefore designed around a current source snapshot rather than an uncontrolled archive.

### Important scope boundary

Historical source-file versioning is not part of Issue #10.

If the project later needs:

- source snapshot history
- file versioning
- ingestion timestamps
- archive retention
- slowly changing source snapshots

that can be designed separately.

---

# 19. Generic File Discovery

The acquisition implementation should not contain six separate hard-coded file operations such as:

```python
copy_customer()
copy_product()
copy_sales()
copy_customer_erp()
copy_location()
copy_category()
```

Instead, the design uses generic discovery.

Conceptually:

```python
for source_file in source_directory.glob("*.csv"):
    ...
```

This allows the pipeline to discover files based on the source directory rather than requiring a new function for every file.

---

# 20. Current File-Type Scope

The current source system contains CSV files.

Therefore Issue #10 intentionally defines:

```text
*.csv
```

as the current discovery pattern.

The current pipeline does not need generic handling for:

```text
*.json
*.parquet
*.xml
*.xlsx
```

Those formats are not part of the current source inventory.

Future support can be added when the project actually requires it.

---

# 21. Technology Selection

## Selected: Python Standard Library

The acquisition implementation will use Python standard-library modules such as:

```python
pathlib
shutil
os
```

The main responsibilities are:

- environment/configuration handling
- path construction
- directory validation
- file discovery
- file copying
- error handling

The design particularly favors:

```python
pathlib
```

for path handling and:

```python
shutil
```

for file copying.

---

# 22. Why Pandas Is Not Used for File Copying

Pandas is already part of the project's environment.

However, Pandas is **not** selected for the acquisition operation itself.

Incorrect approach for simple acquisition:

```python
df = pandas.read_csv(source_file)
df.to_csv(destination_file)
```

That would unnecessarily:

```text
CSV
 ↓
Pandas DataFrame
 ↓
CSV
```

The requirement is simply:

```text
CSV
 ↓
copy
 ↓
CSV
```

No tabular transformation is required.

Therefore the standard library is more appropriate for the acquisition layer.

---

# 23. Pandas Is Still Useful Later

Rejecting Pandas for file copying does not mean Pandas is rejected from the entire project.

Pandas can still be useful for:

- exploratory data analysis
- profiling
- small-data validation
- transformation experiments
- data-quality checks
- understanding source data

But those responsibilities belong to later stages rather than the basic file-copy operation.

---

# 24. Why PySpark Is Not Used for Acquisition

The source inventory is approximately:

```text
~5.3 MB
~116K rows
6 CSV files
```

This is small enough for local Python file operations.

Therefore PySpark is not selected for source acquisition.

Using Spark here would introduce unnecessary infrastructure and processing overhead.

The design intentionally avoids:

```text
CSV
 ↓
Spark
 ↓
copy CSV
```

when the actual requirement is simply:

```text
CSV
 ↓
Python file copy
 ↓
raw/
```

PySpark remains relevant to the broader Data Engineering learning path and may be used in separate large-scale processing scenarios, but it is not required for this acquisition stage.

---

# 25. Why Airflow Is Not Used Here

Airflow is also not used for the actual file-copy logic.

Airflow's primary responsibility would be orchestration and scheduling.

For example:

```text
Schedule
   ↓
Run acquisition
   ↓
Run Bronze load
   ↓
Run Silver transformation
   ↓
Run Gold load
```

That may be a future enhancement.

For the current portfolio project, Issue #10 only designs the acquisition component.

The actual Python script will be invoked directly during development/testing.

Therefore:

```text
Python = acquisition logic
Airflow = not currently required
```

This is a deliberate scope decision rather than a statement that Airflow is unsuitable for production orchestration.

---

# 26. Why Database Access Is Not Used for Acquisition

The current source data is represented as external CSV files.

Therefore the acquisition layer does not directly connect to MySQL to acquire the source.

The flow is:

```text
External CSV source
        ↓
Python acquisition
        ↓
data/raw
        ↓
Bronze ingestion
        ↓
MySQL dw_bronze
```

MySQL becomes relevant to the Bronze warehouse ingestion stage.

---

# 27. Source Acquisition vs Bronze Ingestion

These are two separate pipeline stages.

## Source acquisition

Responsibility:

```text
External source
      ↓
data/raw
```

Example:

```text
DATA SOURCES/source_crm/cust_info.csv
      ↓
data/raw/crm/cust_info.csv
```

## Bronze ingestion

Responsibility:

```text
data/raw
    ↓
dw_bronze
```

Example:

```text
data/raw/crm/cust_info.csv
      ↓
MySQL dw_bronze
```

The acquisition process should not create Bronze tables or load MySQL.

---

# 28. Bronze Design Boundary

Bronze work belongs to a later issue.

The Bronze layer will eventually deal with:

- Bronze table creation
- source-to-Bronze loading
- raw/source-preserving representation
- row-count validation
- schema validation
- load errors
- load timing
- rerun behavior
- logging

The source-acquisition issue intentionally stops before these responsibilities.

---

# 29. No Transformation During Acquisition

The acquisition layer will not perform:

```text
CRM + ERP joins
```

or:

```text
customer matching
```

or:

```text
date conversion
```

or:

```text
NULL replacement
```

or:

```text
whitespace cleanup
```

or:

```text
duplicate removal
```

or:

```text
business-rule filtering
```

The source data should arrive in raw/landing as close as possible to the source representation.

This preserves traceability.

---

# 30. No Source Filename Renaming

The acquisition layer does not attempt to interpret coded ERP filenames.

For example:

```text
PX_CAT_G1V2.csv
```

remains:

```text
PX_CAT_G1V2.csv
```

The meaning of:

```text
PX
CAT
G1V2
```

should not be guessed during acquisition.

Business interpretation and mapping can be handled during source modeling and transformation design.

---

# 31. Proposed Acquisition Logic

The implementation planned for the next issue follows this conceptual flow:

```text
Read .env
   ↓
Read SOURCE_DATA_PATH
   ↓
Validate source root
   ↓
Locate source_crm
   ↓
Locate source_erp
   ↓
Discover *.csv
   ↓
Validate files/directories
   ↓
Create data/raw/crm
   ↓
Create data/raw/erp
   ↓
Copy CRM files
   ↓
Copy ERP files
   ↓
Report results
```

A more complete conceptual architecture is:

```text
                    .env
                      │
                      ▼
             SOURCE_DATA_PATH
                      │
                      ▼
          ┌─────────────────────┐
          │ Python Acquisition  │
          └─────────────────────┘
             │             │
             ▼             ▼
       source_crm      source_erp
             │             │
             ▼             ▼
          discover       discover
             │             │
             └──────┬──────┘
                    ▼
              copy files
                    │
                    ▼
              data/raw/
             ┌──────┴──────┐
             ▼             ▼
            crm            erp
```

---

# 32. Expected Raw Structure After Implementation

After the acquisition script is implemented and successfully executed, the expected structure is:

```text
data/
└── raw/
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

The source filenames remain unchanged.

---

# 33. Git Treatment of Raw Data

The raw files are local acquired data and are not intended to become normal source-controlled project artifacts.

The repository should retain the directories through:

```text
data/raw/crm/.gitkeep
data/raw/erp/.gitkeep
```

while the acquired CSV files themselves should be excluded from Git.

The design intention is:

```text
data/raw/
    ├── crm/
    │   ├── .gitkeep
    │   └── *.csv       ← local, ignored
    │
    └── erp/
        ├── .gitkeep
        └── *.csv       ← local, ignored
```

This prevents local source extracts from unnecessarily entering version control.

---

# 34. What Is Included in Issue #10

Issue #10 includes:

- source acquisition architecture
- external source location strategy
- `.env` configuration strategy
- raw/landing destination design
- source directory convention
- source file discovery strategy
- source filename preservation
- copy-vs-move decision
- rerun behavior design
- current CSV scope
- technology selection
- rejected technology/options
- boundaries between acquisition and Bronze
- Git treatment of acquired raw files
- implementation plan for the next issue
- source inventory and validation evidence

---

# 35. What Is Explicitly Out of Scope

The following are not implemented in Issue #10:

### Bronze database loading

```text
CSV → MySQL dw_bronze
```

### Bronze table DDL

Not implemented here.

### Bronze validation

Not implemented here.

### Silver transformations

Not implemented here.

### Gold dimensional modeling

Not implemented here.

### Airflow orchestration

Not implemented here.

### Spark processing

Not implemented here.

### Incremental loading

Not implemented here.

### Source historical snapshots

Not implemented here.

### Source API ingestion

Not implemented here.

### Cloud object storage

Not implemented here.

### Data-quality remediation

Not implemented here.

### Business transformations

Not implemented here.

---

# 36. Technology Decision Summary

| Technology / Approach | Decision | Reason |
|---|---|---|
| Python | **Use** | Main acquisition/orchestration language |
| `pathlib` | **Use** | Portable path handling |
| `shutil` | **Use** | File copying |
| `python-dotenv` | **Use** | Load `.env` configuration |
| Pandas | **Not for copying** | No DataFrame transformation is required |
| PySpark | **Do not use here** | Current source volume is small |
| Airflow | **Do not use here** | Scheduling/orchestration is outside current issue scope |
| MySQL | **Not for acquisition** | Used later for warehouse/Bronze storage |
| CSV | **Use** | Current source format |
| Hard-coded source path | **Reject** | Machine-specific and not portable |
| Separate CRM/ERP path variables | **Reject** | One root path is sufficient |
| File renaming | **Reject** | Preserve source traceability |
| File moving | **Reject** | Do not modify/remove source files |
| Per-file hard-coded functions | **Reject** | Generic discovery is simpler and extensible |
| Transform during copy | **Reject** | Acquisition should preserve source data |

---

# 37. Why This Design Is Appropriate for the Current Project

The current source inventory is:

```text
6 CSV files
~5.3 MB
~116K rows
```

Therefore a lightweight acquisition architecture is appropriate:

```text
.env
  ↓
Python
  ↓
pathlib + shutil
  ↓
data/raw
```

There is no technical need to introduce Spark, Airflow, APIs, cloud object storage, or other infrastructure simply to copy approximately 5.3 MB of local source files.

The design intentionally chooses the simplest technology that satisfies the current requirement while leaving room for future extension.

---

# 38. Future Evolution

The current design can evolve without changing the fundamental separation of responsibilities.

For example:

### Current

```text
Local source files
      ↓
Python
      ↓
data/raw
```

### Future API source

```text
REST API
      ↓
Python/API client
      ↓
data/raw
```

### Future cloud source

```text
S3 / Azure Blob / ADLS
      ↓
Acquisition process
      ↓
raw/landing
```

### Future orchestration

```text
Airflow
   ↓
Python acquisition
   ↓
Bronze
   ↓
Silver
   ↓
Gold
```

The core principle remains:

> Source acquisition and downstream transformation/loading are separate concerns.

---

# 39. Commands Used During Issue #10

## 39.1 Inspect source files

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse |
    Select-Object FullName, Length, LastWriteTime
```

Purpose:

- list all source files
- inspect file sizes
- inspect modification timestamps
- understand source directory structure

---

## 39.2 Inspect CSV headers

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        Write-Host "`n===== $($_.FullName) ====="
        Get-Content $_.FullName -TotalCount 1
    }
```

Purpose:

- inspect CSV headers
- verify source columns
- understand source file structures

---

## 39.3 Count source rows

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        $rowCount = (Get-Content $_.FullName | Measure-Object -Line).Lines - 1

        [PSCustomObject]@{
            File     = $_.Name
            Source   = $_.Directory.Name
            Size_KB  = [math]::Round($_.Length / 1KB, 2)
            Rows     = $rowCount
        }
    }
```

Purpose:

- estimate source volume
- compare source files
- understand the scale of the acquisition problem

The `- 1` subtracts the header row from the total line count.

---

## 39.4 Inspect first two lines

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        $firstTwoLines = Get-Content $_.FullName -TotalCount 2

        [PSCustomObject]@{
            File        = $_.Name
            Source      = $_.Directory.Name
            Size_KB     = [math]::Round($_.Length / 1KB, 2)
            FirstLine   = $firstTwoLines[0]
            SecondLine  = $firstTwoLines[1]
        }
    }
```

Purpose:

- inspect header
- inspect one actual data record
- verify the delimiter/data shape
- confirm the source contains tabular records

---

# 40. Existing Project Structure Relevant to This Issue

The project structure entering this issue includes:

```text
Data-warehouse-ETL-Pipeline/
├── data/
│   ├── raw/
│   │   ├── crm/
│   │   │   └── .gitkeep
│   │   └── erp/
│   │       └── .gitkeep
│   └── sample/
│       └── .gitkeep
│
├── docs/
│   ├── architecture/
│   │   └── README.md
│   ├── data_dictionary/
│   │   └── README.md
│   ├── data_model/
│   │   └── README.md
│   ├── decisions/
│   │   └── README.md
│   ├── etl/
│   │   └── README.md
│   └── project_plan/
│       └── README.md
│
├── sql/
│   ├── bronze/
│   │   ├── loading/
│   │   ├── tables/
│   │   └── validations/
│   ├── silver/
│   │   ├── loading/
│   │   ├── transformations/
│   │   └── validations/
│   ├── gold/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   ├── views/
│   │   └── validations/
│   └── setup/
│       └── create_databases.sql
│
├── scripts/
│   └── setup_database.py
│
├── tests/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── .env.example
├── .gitignore
└── requirements.txt
```

Issue #10 adds the design for source acquisition without prematurely adding implementation code.

---

# 41. Implementation Boundary for Issue #11

The next implementation issue should implement the acquisition behavior designed here.

Expected responsibilities:

```text
scripts/
└── acquisition/
    └── acquire_source_data.py
```

or another agreed project-specific location.

The implementation should:

1. Load environment configuration.
2. Read `SOURCE_DATA_PATH`.
3. Validate that the source root exists.
4. Locate:
   - `source_crm`
   - `source_erp`
5. Discover CSV files.
6. Validate that source files exist.
7. Create raw destination directories if required.
8. Copy CRM files into `data/raw/crm`.
9. Copy ERP files into `data/raw/erp`.
10. Preserve filenames.
11. Handle reruns predictably.
12. Report what was copied.
13. Fail clearly when configuration or source files are invalid.

The implementation should not introduce Bronze loading.

---

# 42. Acceptance Criteria

Issue #10 is considered designed when the following decisions are documented:

- [x] External source data location is defined.
- [x] Source CRM and ERP directory structure is known.
- [x] Current source files are inventoried.
- [x] Current source file sizes are known.
- [x] Current source row counts are known.
- [x] Current source headers are inspected.
- [x] Example records are inspected.
- [x] Source location is configurable.
- [x] Hard-coded paths are rejected.
- [x] One root source configuration variable is selected.
- [x] CRM/ERP directories are derived from the root.
- [x] Source data remains outside Git.
- [x] Copy rather than move is selected.
- [x] Original source filenames are preserved.
- [x] Generic CSV discovery is selected.
- [x] Current scope is CSV.
- [x] Python standard library is selected for file acquisition.
- [x] Pandas is not required for file copying.
- [x] PySpark is not required for this acquisition stage.
- [x] Airflow is not required for this acquisition stage.
- [x] MySQL is not used for acquisition.
- [x] Transformation is excluded from acquisition.
- [x] Bronze ingestion is kept as a separate stage.
- [x] Raw data Git treatment is defined.
- [x] Next implementation issue is clearly defined.

---

# 43. Final Architecture Decision

The final Issue #10 design is:

```text
                     .env
                       │
                       │ SOURCE_DATA_PATH
                       ▼
          External Source Root
          ┌──────────────────────┐
          │ DATA SOURCES         │
          │                      │
          │ source_crm/          │
          │ source_erp/          │
          └──────────┬───────────┘
                     │
                     │ discover *.csv
                     ▼
             Python Acquisition
              pathlib + shutil
                     │
                     │ copy
                     ▼
              Project Raw/Landing
              ┌────────────────┐
              │ data/raw/      │
              │                │
              │ crm/           │
              │ erp/           │
              └───────┬────────┘
                      │
                      │ later
                      ▼
                Bronze Ingestion
                      │
                      ▼
                MySQL dw_bronze
                      │
                      ▼
                 Silver Layer
                      │
                      ▼
                  Gold Layer
```

---

# 44. Final Decision Statement

For this project, source acquisition is designed as a **configuration-driven Python file-copy stage**.

The source data remains outside the Git repository. The source root is supplied through `SOURCE_DATA_PATH` in `.env`. The acquisition process derives the CRM and ERP directories from that root, discovers CSV files generically, preserves their original names, and copies them into the project's `data/raw/crm` and `data/raw/erp` landing directories.

The acquisition layer performs no business transformation and does not load MySQL. Bronze ingestion remains a separate downstream responsibility.

The implementation deliberately uses lightweight Python standard-library file operations rather than introducing Pandas, PySpark, Airflow, database connectivity, or cloud infrastructure for a small local source dataset.

This creates a clear and extensible boundary:

```text
Acquire → Land → Bronze → Silver → Gold
```

with each stage having a distinct responsibility.

---

# 45. Issue Closure Summary

### Issue

**#10 — Design Configurable Source Acquisition and Landing Strategy**

### Result

A complete source-acquisition and landing design has been established based on the actual CRM and ERP source files available in the project environment.

### Core decisions

```text
Source location:
    .env → SOURCE_DATA_PATH

Source structure:
    source_crm/
    source_erp/

File type:
    CSV

Discovery:
    generic *.csv discovery

Acquisition technology:
    Python + pathlib + shutil

Destination:
    data/raw/crm/
    data/raw/erp/

Behavior:
    copy, don't move

Filename:
    preserve original

Transformation:
    none

Warehouse loading:
    not part of acquisition

Git:
    source files external/ignored

Next stage:
    Bronze ingestion
```

The design is now ready for implementation in the next issue.
