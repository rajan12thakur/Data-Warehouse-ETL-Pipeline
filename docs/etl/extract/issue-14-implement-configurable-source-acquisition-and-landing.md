# Issue #14 — Implement Configurable Source Acquisition and Landing

## 1. Issue Overview

**Issue:** #14  
**Title:** Implement Configurable Source Acquisition and Landing  
**Branch:** `14-implement-configurable-source-acquisition-and-landing`  
**Status:** Implementation completed

### Objective

Implement the source acquisition and landing process designed in the previous source-acquisition design issue.

The objective is to build a Python-based acquisition script that:

- reads the external source location from environment configuration,
- discovers CRM and ERP CSV files,
- validates the expected source structure,
- creates the raw/landing destinations,
- copies source files into the project's raw area,
- preserves original filenames,
- leaves the original source files untouched,
- supports predictable reruns,
- and keeps source acquisition separate from Bronze ingestion.

The implemented flow is:

```text
.env
  |
  | SOURCE_DATA_PATH
  v
External Source Data
  |
  +-- source_crm/*.csv
  |
  +-- source_erp/*.csv
          |
          v
   Python Acquisition
          |
          v
      data/raw/
       +-- crm/
       +-- erp/
          |
          v
    Future Bronze Ingestion
```

---

# 2. Architectural Boundary

This issue implements only:

```text
Source -> Raw / Landing
```

It does not implement:

```text
Raw -> Bronze
Bronze -> Silver
Silver -> Gold
```

The separation is intentional.

The acquisition layer gets source files into the project's landing area.

The Bronze layer will later load those acquired files into MySQL and perform Bronze-specific validation.

---

# 3. Git Branch

Implementation was performed on:

```text
14-implement-configurable-source-acquisition-and-landing
```

The project workflow is:

```text
develop
   |
feature branch
   |
implementation
   |
testing
   |
commit
   |
push
   |
Pull Request
   |
develop
```

---

# 4. Repository State Before Implementation

Relevant repository structure:

```text
Data-Warehouse-ETL-Pipeline/
+-- data/
|   +-- raw/
|   |   +-- crm/
|   |   |   +-- .gitkeep
|   |   +-- erp/
|   |       +-- .gitkeep
|   +-- sample/
|       +-- .gitkeep
|
+-- docs/
+-- scripts/
|   +-- extract/
|   +-- load/
|   +-- transform/
|   +-- run_pipeline.py
|   +-- setup_database.py
|
+-- sql/
+-- tests/
+-- .env
+-- .env.example
+-- .gitignore
+-- README.md
+-- requirements.txt
```

The existing `scripts/extract/` directory was selected for source acquisition because acquisition is an extraction-side responsibility.

---

# 5. Actual External Source Location

The source data is kept outside the Git repository.

Local source root:

```text
C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\DATA SOURCES
```

Current source structure:

```text
DATA SOURCES/
+-- source_crm/
|   +-- cust_info.csv
|   +-- prd_info.csv
|   +-- sales_details.csv
|
+-- source_erp/
    +-- CUST_AZ12.csv
    +-- LOC_A101.csv
    +-- PX_CAT_G1V2.csv
```

Keeping the source data outside the repository preserves the distinction between external source data and engineering project code.

---

# 6. Source Inventory

The source files were inspected before implementation.

| Source | File | Size |
|---|---|---:|
| CRM | `cust_info.csv` | 835.35 KB |
| CRM | `prd_info.csv` | 26.30 KB |
| CRM | `sales_details.csv` | 3504.02 KB |
| ERP | `CUST_AZ12.csv` | 548.39 KB |
| ERP | `LOC_A101.csv` | 393.23 KB |
| ERP | `PX_CAT_G1V2.csv` | 1.14 KB |

Approximate total:

```text
~5.3 MB
```

This small source volume influenced the decision to use normal Python filesystem operations rather than Spark or other distributed infrastructure.

---

# 7. Source Row Counts

The following command was used during source inspection:

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

Observed counts:

| File | Source | Rows |
|---|---|---:|
| `cust_info.csv` | `source_crm` | 18,494 |
| `prd_info.csv` | `source_crm` | 397 |
| `sales_details.csv` | `source_crm` | 60,398 |
| `CUST_AZ12.csv` | `source_erp` | 18,484 |
| `LOC_A101.csv` | `source_erp` | 18,484 |
| `PX_CAT_G1V2.csv` | `source_erp` | 37 |

Approximate total:

```text
~116,294 data rows
```

These counts were used to understand the source scale. They are not transformation logic in the acquisition script.

---

# 8. Source Header Inspection

Command:

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        Write-Host "`n===== $($_.FullName) ====="
        Get-Content $_.FullName -TotalCount 1
    }
```

Observed headers:

### `cust_info.csv`

```text
cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date
```

### `prd_info.csv`

```text
prd_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
```

### `sales_details.csv`

```text
sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price
```

### `CUST_AZ12.csv`

```text
CID,BDATE,GEN
```

### `LOC_A101.csv`

```text
CID,CNTRY
```

### `PX_CAT_G1V2.csv`

```text
ID,CAT,SUBCAT,MAINTENANCE
```

This confirmed that the current source inputs are CSV files with header rows.

---

# 9. First-Record Inspection

Command:

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

Examples observed:

```text
cust_info.csv
cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date
11000,AW00011000, Jon,Yang ,M,M,2025-10-06
```

```text
prd_info.csv
prd_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
210,CO-RF-FR-R92B-58,HL Road Frame - Black- 58,,R ,2003-07-01,
```

```text
sales_details.csv
sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price
SO43697,BK-R93R-62,21768,20101229,20110105,20110110,3578,1,3578
```

```text
CUST_AZ12.csv
CID,BDATE,GEN
NASAW00011000,1971-10-06,Male
```

```text
LOC_A101.csv
CID,CNTRY
AW-00011000,Australia
```

```text
PX_CAT_G1V2.csv
ID,CAT,SUBCAT,MAINTENANCE
AC_BR,Accessories,Bike Racks,Yes
```

---

# 10. Configuration Design

The source location is configured through:

```env
SOURCE_DATA_PATH=<path-to-external-source-root>
```

The actual local `.env` contains the real machine-specific path.

The Python code does not contain the absolute local source path.

This makes the script portable across machines.

---

# 11. `.env.example`

The configuration template contains:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password

SOURCE_DATA_PATH=C:\path\to\DATA SOURCES
```

The actual `.env` is local and is not intended for Git because it can contain credentials and machine-specific configuration.

---

# 12. Why One Source Root Is Used

Only one source configuration variable is required:

```env
SOURCE_DATA_PATH=...
```

The source system directories are derived from that root:

```text
SOURCE_DATA_PATH/
+-- source_crm/
+-- source_erp/
```

Therefore Python constructs:

```text
SOURCE_DATA_PATH/source_crm
SOURCE_DATA_PATH/source_erp
```

Instead of requiring:

```env
CRM_SOURCE_PATH=...
ERP_SOURCE_PATH=...
```

This avoids duplicated configuration.

---

# 13. Why Hard-Coded Paths Were Rejected

The Python code does not contain:

```python
source_path = r"C:\Users\Rajan Thakur\..."
```

Hard-coded paths make the program machine-specific.

The selected configuration flow is:

```text
.env
  |
  | SOURCE_DATA_PATH
  v
Python
```

A different developer can therefore change the environment configuration without modifying Python source code.

---

# 14. Script Location

The implementation is:

```text
scripts/
+-- extract/
    +-- acquire_source_data.py
```

This follows the existing project organization.

Source acquisition belongs logically under extraction.

---

# 15. Technology Selection

The implementation uses:

- Python
- `python-dotenv`
- `pathlib`
- `shutil`

Main flow:

```text
python-dotenv
      |
      v
configuration
      |
      v
pathlib
      |
      v
path discovery
      |
      v
shutil
      |
      v
file copy
```

---

# 16. Why Pandas Is Not Used for Copying

Pandas is available in the environment but is not needed for the copy operation.

An unnecessary approach would be:

```python
df = pandas.read_csv(source_file)
df.to_csv(destination_file)
```

That creates:

```text
CSV
 |
 v
DataFrame
 |
 v
CSV
```

The actual requirement is:

```text
CSV
 |
 v
copy
 |
 v
CSV
```

Therefore the standard library is more appropriate.

Pandas can still be used later for profiling, exploratory analysis, or small-data validation.

---

# 17. Why PySpark Is Not Used

The source inventory is approximately:

```text
6 CSV files
~5.3 MB
~116K rows
```

This is small enough for Python filesystem operations.

Using Spark simply to copy these files would add unnecessary complexity.

Selected:

```text
CSV -> Python -> raw
```

Not:

```text
CSV -> Spark -> raw
```

PySpark remains relevant to other Data Engineering processing scenarios but is not required for this acquisition stage.

---

# 18. Why Airflow Is Not Used

Airflow is not part of this implementation.

Airflow would be appropriate later for orchestration such as:

```text
Schedule
   |
   v
Acquire
   |
   v
Bronze
   |
   v
Silver
   |
   v
Gold
```

Issue #14 only implements acquisition logic.

Therefore:

```text
Python = acquisition logic
Airflow = future orchestration possibility
```

---

# 19. Why MySQL Is Not Used for Acquisition

The current source is represented by external CSV files.

Therefore acquisition does not connect to MySQL.

The architecture is:

```text
External CSV
    |
    v
Python acquisition
    |
    v
data/raw
    |
    v
Future Bronze ingestion
    |
    v
MySQL dw_bronze
```

MySQL belongs to the warehouse loading stage.

---

# 20. Why Files Are Copied Rather Than Moved

The implementation copies files.

It does not move them.

Selected behavior:

```text
External source
      |
      +----------> raw
      |
      +----------> source remains available
```

Not:

```text
External source
      |
      +----------> raw
                   source removed
```

The acquisition process should not destroy or relocate source-system files.

---

# 21. Why Original Filenames Are Preserved

The acquisition process preserves source filenames.

For example:

```text
cust_info.csv
```

remains:

```text
cust_info.csv
```

and:

```text
PX_CAT_G1V2.csv
```

remains:

```text
PX_CAT_G1V2.csv
```

The acquisition layer does not try to interpret or rename coded ERP filenames.

This preserves source traceability.

---

# 22. Generic File Discovery

The script does not contain separate hard-coded functions for each of the six files.

Instead it discovers:

```text
*.csv
```

inside each source-system directory.

Conceptually:

```text
source_crm
    |
    +-- discover *.csv
    |
    +-- copy all discovered files

source_erp
    |
    +-- discover *.csv
    |
    +-- copy all discovered files
```

This makes the acquisition logic reusable if another CSV is later added to one of the source directories.

---

# 23. Current File-Type Scope

The current source inventory contains CSV files.

Therefore the implementation currently discovers:

```text
*.csv
```

Other formats such as:

```text
JSON
Parquet
XML
Excel
```

are not implemented because they are not part of the current source requirement.

---

# 24. Implementation — Load Configuration

The script begins with:

```python
from pathlib import Path
import shutil

from dotenv import load_dotenv
import os


load_dotenv()

source_root = os.getenv("SOURCE_DATA_PATH")
```

The flow is:

```text
.env
 |
 v
load_dotenv()
 |
 v
os.getenv("SOURCE_DATA_PATH")
 |
 v
source_root
```

---

# 25. Validate Configuration

The script checks:

```python
if not source_root:
    raise ValueError("SOURCE_DATA_PATH is not configured in the .env file.")
```

This handles a missing source configuration before filesystem operations begin.

---

# 26. Convert Configuration to a Path

The configuration value is converted:

```python
source_root = Path(source_root)
```

This enables clean path construction such as:

```python
source_root / "source_crm"
```

instead of manual string concatenation.

---

# 27. Validate Source Root

The script checks:

```python
if not source_root.is_dir():
    raise FileNotFoundError(
        f"Source directory does not exist: {source_root}"
    )
```

This is separate from the configuration check.

The two checks mean:

```text
not source_root
    |
    +-- Was a path configured?

not source_root.is_dir()
    |
    +-- Does the configured path actually exist?
```

---

# 28. Locate CRM and ERP

The script derives:

```python
crm_source = source_root / "source_crm"
erp_source = source_root / "source_erp"
```

Result:

```text
SOURCE_DATA_PATH
      |
      +-- source_crm
      |
      +-- source_erp
```

---

# 29. Validate CRM and ERP Directories

The script checks:

```python
if not crm_source.is_dir():
    raise FileNotFoundError(
        f"CRM source directory does not exist: {crm_source}"
    )

if not erp_source.is_dir():
    raise FileNotFoundError(
        f"ERP source directory does not exist: {erp_source}"
    )
```

This prevents silent success when one expected source-system directory is missing.

---

# 30. Discover CSV Files

The implementation uses:

```python
crm_files = sorted(crm_source.glob("*.csv"))
erp_files = sorted(erp_source.glob("*.csv"))
```

CRM discovery returns:

```text
cust_info.csv
prd_info.csv
sales_details.csv
```

ERP discovery returns:

```text
CUST_AZ12.csv
LOC_A101.csv
PX_CAT_G1V2.csv
```

`sorted()` gives deterministic ordering for predictable execution and testing.

---

# 31. Validate CSV Discovery

The script checks:

```python
if not crm_files:
    raise FileNotFoundError(
        f"No CSV files found in CRM source directory: {crm_source}"
    )

if not erp_files:
    raise FileNotFoundError(
        f"No CSV files found in ERP source directory: {erp_source}"
    )
```

Therefore an empty source directory is treated as an error instead of an apparently successful acquisition.

---

# 32. Determine Project Root

The script is located at:

```text
project/
+-- scripts/
    +-- extract/
        +-- acquire_source_data.py
```

The project root is found with:

```python
project_root = Path(__file__).resolve().parents[2]
```

Hierarchy:

```text
parents[0] -> extract
parents[1] -> scripts
parents[2] -> project root
```

This avoids hard-coding the project path.

---

# 33. Define Raw Destinations

The script builds:

```python
raw_root = project_root / "data" / "raw"

crm_destination = raw_root / "crm"
erp_destination = raw_root / "erp"
```

Result:

```text
data/raw/crm
data/raw/erp
```

---

# 34. Create Raw Destinations

The implementation uses:

```python
crm_destination.mkdir(parents=True, exist_ok=True)
erp_destination.mkdir(parents=True, exist_ok=True)
```

### `parents=True`

Allows missing parent directories to be created.

### `exist_ok=True`

Allows the script to run again when directories already exist.

This supports predictable reruns.

---

# 35. Destination Verification

The script printed:

```text
CRM destination: C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\Data-Warehouse-ETL-Pipeline\data\raw\crm
ERP destination: C:\Users\Rajan Thakur\OneDrive\Desktop\DATA ENGINEERING\DATA WAREHOUSE\Data-Warehouse-ETL-Pipeline\data\raw\erp
```

This verified that project-root detection and destination construction worked correctly.

---

# 36. Copy CRM Files

The implementation uses:

```python
for source_file in crm_files:
    destination_file = crm_destination / source_file.name
    shutil.copy2(source_file, destination_file)
```

Example:

```text
DATA SOURCES/source_crm/cust_info.csv
              |
              | copy2()
              v
data/raw/crm/cust_info.csv
```

The original file remains in the source location.

---

# 37. Copy ERP Files

The same generic pattern is used:

```python
for source_file in erp_files:
    destination_file = erp_destination / source_file.name
    shutil.copy2(source_file, destination_file)
```

Example:

```text
DATA SOURCES/source_erp/CUST_AZ12.csv
              |
              | copy2()
              v
data/raw/erp/CUST_AZ12.csv
```

---

# 38. Why `shutil.copy2()` Is Used

The implementation uses:

```python
shutil.copy2(source_file, destination_file)
```

This performs a file-level copy rather than reading and rewriting the CSV as tabular data.

The desired behavior is:

```text
source file
     |
     | copy
     v
raw file
```

not:

```text
source CSV
     |
     v
DataFrame
     |
     v
new CSV
```

This helps preserve the raw representation.

---

# 39. Final Raw Structure

After successful execution:

```text
data/raw/
+-- crm/
|   +-- .gitkeep
|   +-- cust_info.csv
|   +-- prd_info.csv
|   +-- sales_details.csv
|
+-- erp/
    +-- .gitkeep
    +-- CUST_AZ12.csv
    +-- LOC_A101.csv
    +-- PX_CAT_G1V2.csv
```

All six expected source files were successfully copied.

---

# 40. Observed Raw File Sizes

The copied files had the same observed byte sizes as the source files:

| File | Source bytes | Raw bytes |
|---|---:|---:|
| `cust_info.csv` | 855395 | 855395 |
| `prd_info.csv` | 26934 | 26934 |
| `sales_details.csv` | 3588116 | 3588116 |
| `CUST_AZ12.csv` | 561549 | 561549 |
| `LOC_A101.csv` | 402669 | 402669 |
| `PX_CAT_G1V2.csv` | 1169 | 1169 |

This is useful evidence that the expected files were copied without size differences.

---

# 41. File Integrity Validation Discussion

A SHA-256 source-vs-raw comparison was considered during implementation.

The concept was:

```text
Source file
    |
    v
SHA-256
    |
    +-------- compare --------+
                              |
Raw file                      |
    |                         |
    v                         |
SHA-256                       |
    +-------------------------+
              |
              v
            Match
```

A PowerShell test was also attempted:

```powershell
Get-ChildItem ".\DATA SOURCES" -Recurse -Filter *.csv |
    ForEach-Object {
        $sourceFile = $_

        if ($sourceFile.Directory.Name -eq "source_crm") {
            $rawFile = Join-Path ".\data\raw\crm" $sourceFile.Name
        }
        else {
            $rawFile = Join-Path ".\data\raw\erp" $sourceFile.Name
        }

        $sourceHash = (Get-FileHash $sourceFile.FullName -Algorithm SHA256).Hash
        $rawHash = (Get-FileHash $rawFile -Algorithm SHA256).Hash

        [PSCustomObject]@{
            File        = $sourceFile.Name
            SourceHash  = $sourceHash
            RawHash     = $rawHash
            Match       = $sourceHash -eq $rawHash
        }
    }
```

However, SHA-256 checking was not added to the acquisition script.

The decision was to keep Issue #14 focused on acquisition rather than turning it into a complete data-quality/audit framework.

---

# 42. Acquisition Validation vs Bronze Validation

This distinction is important.

## Acquisition validation

The acquisition layer validates:

```text
SOURCE_DATA_PATH exists
CRM directory exists
ERP directory exists
CSV files exist
Destination directories can be created
Files can be copied
```

These checks answer:

> Can the source files be acquired successfully?

## Bronze validation

Bronze should later validate:

```text
source row count
Bronze row count
source schema
Bronze schema
column mapping
loaded records
load completeness
load errors
```

These checks answer:

> Did the source data get loaded correctly into the Bronze warehouse?

## Silver/data-quality validation

Later stages may handle:

```text
NULL handling
standardization
duplicate handling
business rules
data cleansing
```

Therefore the acquisition script intentionally does not perform all downstream validation.

---

# 43. Rerun Behavior

The design supports rerunning:

```powershell
python .\scripts\extract\acquire_source_data.py
```

Because destination directories use:

```python
mkdir(parents=True, exist_ok=True)
```

they do not fail simply because they already exist.

The destination filenames are the same as the source filenames.

Therefore a rerun does not create:

```text
cust_info_1.csv
cust_info_2.csv
```

Instead, the destination copy is replaced with the current source copy.

This represents a current-source-snapshot model.

Historical source versioning is not implemented.

---

# 44. Historical Source Snapshots Are Out of Scope

The project does not currently implement:

- source file version history,
- archive folders,
- timestamped filenames,
- snapshot IDs,
- object-storage versioning,
- retention policies.

These may be future enhancements if the project later requires historical source snapshots.

---

# 45. What the Acquisition Layer Does Not Do

The script does not:

- rename source files,
- rename columns,
- change data types,
- parse CSVs into DataFrames,
- trim values,
- replace NULLs,
- remove duplicates,
- join CRM and ERP,
- filter business records,
- calculate metrics,
- connect to MySQL,
- create Bronze tables,
- load Bronze tables,
- perform Silver transformations,
- perform Gold transformations.

The acquisition layer is intentionally lightweight.

---

# 46. Technology Decision Summary

| Technology / Approach | Decision | Reason |
|---|---|---|
| Python | **Use** | Acquisition implementation |
| `python-dotenv` | **Use** | Environment configuration |
| `pathlib` | **Use** | Portable path handling |
| `shutil.copy2()` | **Use** | File-level copying |
| CSV | **Use** | Current source format |
| Pandas for copying | **Do not use** | No DataFrame transformation needed |
| PySpark | **Do not use here** | Current source volume is small |
| Airflow | **Do not use here** | Orchestration is outside scope |
| MySQL for acquisition | **Do not use** | MySQL is downstream warehouse storage |
| Hard-coded source paths | **Reject** | Not portable |
| Separate CRM/ERP path variables | **Reject** | One source root is sufficient |
| File renaming | **Reject** | Preserve source identity |
| File moving | **Reject** | Do not modify/remove source files |
| Transformation during acquisition | **Reject** | Preserve source representation |
| SHA-256 in core script | **Not required** | Useful integrity check but outside core scope |

---

# 47. Acceptance Criteria

- [x] `SOURCE_DATA_PATH` is configured through `.env`.
- [x] `.env.example` documents the required source configuration.
- [x] No hard-coded machine-specific source path exists in the Python implementation.
- [x] CRM and ERP directories are derived from the configured source root.
- [x] Source root is validated.
- [x] CRM source directory is validated.
- [x] ERP source directory is validated.
- [x] CSV files are discovered generically.
- [x] Empty CRM/ERP source directories are handled with clear errors.
- [x] Raw CRM directory is created automatically.
- [x] Raw ERP directory is created automatically.
- [x] CRM files are copied successfully.
- [x] ERP files are copied successfully.
- [x] Original filenames are preserved.
- [x] Original source files are not moved.
- [x] Existing destination directories do not cause failure.
- [x] Six expected source files appear under `data/raw`.
- [x] Observed source and raw file sizes match.
- [x] Acquisition is separate from Bronze ingestion.
- [x] Pandas is not unnecessarily used for copying.
- [x] PySpark is not unnecessarily introduced.
- [x] Airflow is not unnecessarily introduced.
- [x] MySQL is not involved in source acquisition.

---

# 48. Final Architecture

```text
                         .env
                           |
                           | SOURCE_DATA_PATH
                           v
                External Source Root
                +------------------+
                | DATA SOURCES     |
                |                  |
                | source_crm/      |
                | source_erp/      |
                +--------+---------+
                         |
                         | discover *.csv
                         v
                 Python Acquisition
                 +-----------------+
                 | pathlib         |
                 | shutil          |
                 | python-dotenv   |
                 +--------+--------+
                          |
                          | copy
                          v
                    data/raw/
                   +------+------+
                   v             v
                  crm            erp
                   \             /
                    \           /
                     +----+----+
                          |
                          v
                   Future Bronze
                          |
                          v
                   MySQL dw_bronze
                          |
                          v
                       Silver
                          |
                          v
                        Gold
```

---

# 49. Final Decision Statement

Issue #14 implements a **configuration-driven Python source-acquisition stage**.

The source data remains outside the Git repository. The source root is configured through `SOURCE_DATA_PATH`. The Python script derives the CRM and ERP source directories, discovers CSV files generically, validates the expected input structure, creates the raw/landing destinations, and copies source files while preserving their original names.

The source files are copied rather than moved, and no business transformation is performed during acquisition.

The implementation deliberately uses lightweight Python filesystem operations (`pathlib` and `shutil`) instead of introducing Pandas for copying, PySpark, Airflow, database connectivity, or cloud infrastructure for a small local source dataset.

The final responsibility boundary is:

```text
Acquire -> Land -> Bronze -> Silver -> Gold
```

This issue implements only:

```text
Acquire -> Land
```

Bronze loading and Bronze validation are deliberately deferred to the next design/implementation stages.

---

# 50. Next Issue — Bronze Layer Design

The next issue should be design-first.

The next architectural boundary is:

```text
data/raw
    |
    v
dw_bronze
```

The Bronze design should determine:

- Bronze database/schema
- Bronze table naming
- source-to-Bronze mapping
- column preservation
- MySQL data types
- table structure
- full vs incremental loading
- rerun strategy
- truncate/reload strategy
- load order
- source-to-Bronze row-count validation
- schema validation
- load errors
- logging
- load duration
- metadata
- source traceability
- Python vs SQL responsibilities
- what is deliberately excluded from Bronze

Only after these decisions are documented should Bronze implementation begin.

---

# 51. Issue Closure Summary

### Issue

**#14 — Implement Configurable Source Acquisition and Landing**

### Completed

A working Python source-acquisition process now copies the external CRM and ERP CSV source files into the project's raw/landing area without modifying or moving the source files.

### Source

```text
DATA SOURCES/
+-- source_crm/
+-- source_erp/
```

### Destination

```text
data/raw/
+-- crm/
+-- erp/
```

### Implementation

```text
scripts/extract/acquire_source_data.py
```

### Configuration

```env
SOURCE_DATA_PATH=...
```

### Technologies used

```text
Python
python-dotenv
pathlib
shutil
```

### Technologies intentionally not used

```text
Pandas for copying
PySpark
Airflow
MySQL for acquisition
Cloud storage
Business transformations
```

### Final result

```text
External Source
      |
      v
Python Acquisition
      |
      v
Raw/Landing
      |
      v
NEXT: Bronze Layer Design
```

The source-acquisition stage is complete and ready for the Bronze design phase.
