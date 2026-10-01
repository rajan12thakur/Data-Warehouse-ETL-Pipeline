# Issue #17 — Source Data Profiling for Bronze Schema Design

## 1. Issue Overview

### Issue

**#17 — Profile Source Data for Bronze Schema Design**

### Epic

**Build Bronze Layer**

### Purpose

This issue performs detailed profiling of the landed CRM and ERP source files before creating the Bronze table DDL.

The Bronze layer has already been designed in Issue #16. The next implementation step is to create Bronze tables and load the source data.

Before creating those tables, we need to understand the actual incoming source data.

The profiling activity answers:

- What columns are present?
- What is the source structure?
- What kind of data is contained in each column?
- What date formats are used?
- Which columns contain empty or missing values?
- What string lengths are observed?
- What numeric characteristics are observed?
- What MySQL datatype should represent each source column in Bronze?
- Are there any source characteristics that could affect ingestion?

The result of this issue will be used as the basis for the Bronze DDL and data-ingestion implementation in Issue #18.

---

# 2. Why Data Profiling Is Required

The Bronze layer is designed to store raw, unprocessed source data as-is from the source systems.

However, "as-is" does not mean that we can create database tables without understanding the incoming data.

Before creating the DDL, we need to understand the metadata, structure, and schema of the incoming source data.

The reference workflow provides two ways to obtain this information:

1. Ask technical experts from the source system.
2. Explore and inspect the incoming data directly.

For this portfolio project, the second approach is used because the project has supplied source CSV files that can be inspected directly.

The important distinction is:

```text
Data Profiling
    ↓
Understand the source
    ↓
Design the Bronze schema
```

not:

```text
Data Profiling
    ↓
Clean the source
    ↓
Transform the source
```

Profiling is an observation and understanding activity. It does not change the source data.

---

# 3. Relationship to the Bronze Workflow

The Bronze workflow is:

```text
Source System Analysis
        ↓
Source Acquisition
        ↓
Raw / Landing
        ↓
Data Profiling
        ↓
Bronze Schema / DDL
        ↓
Bronze Data Ingestion
        ↓
Bronze Validation
        ↓
Silver
        ↓
Gold
```

The source-analysis activity has already been completed.

The source-acquisition implementation has also been completed.

The source files have been copied into the project raw/landing area.

Therefore, this issue focuses specifically on:

```text
data/raw/
      ↓
Data Profiling
      ↓
Bronze Schema Decisions
```

---

# 4. Source Data Location

The external source data is organized as:

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

After source acquisition, the project raw/landing area contains:

```text
data/raw/
├── crm/
│   ├── cust_info.csv
│   ├── prd_info.csv
│   └── sales_details.csv
└── erp/
    ├── CUST_AZ12.csv
    ├── LOC_A101.csv
    └── PX_CAT_G1V2.csv
```

The profiling activity is performed against the landed files used by the Bronze pipeline.

---

# 5. Source Inventory

The current source inventory contains six CSV datasets.

| Source System | Source File | Expected Bronze Table |
|---|---|---|
| CRM | `cust_info.csv` | `crm_cust_info` |
| CRM | `prd_info.csv` | `crm_prd_info` |
| CRM | `sales_details.csv` | `crm_sales_details` |
| ERP | `CUST_AZ12.csv` | `erp_cust_az12` |
| ERP | `LOC_A101.csv` | `erp_loc_a101` |
| ERP | `PX_CAT_G1V2.csv` | `erp_px_cat_g1v2` |

These six datasets are the scope of the profiling activity.

---

# 6. Profiling Objectives

For every source file, the following characteristics should be inspected and documented.

## 6.1 Column Names

Identify the exact column names supplied by the source CSV header.

The source column names are important because Bronze is intended to remain close to the source structure.

Example:

```text
cust_info.csv

cst_id
cst_key
cst_firstname
cst_lastname
cst_marital_status
cst_gndr
cst_create_date
```

---

## 6.2 Number of Columns

Determine how many columns are present in each source file.

This provides the basic structural definition of the dataset.

For example:

```text
cust_info.csv
    ↓
7 columns
```

The number of columns should be recorded for all six files.

---

## 6.3 Number of Rows

Determine the number of data records in each source file.

The currently observed source inventory is:

| Source File | Observed Rows |
|---|---:|
| `cust_info.csv` | 18,494 |
| `prd_info.csv` | 397 |
| `sales_details.csv` | 60,398 |
| `CUST_AZ12.csv` | 18,484 |
| `LOC_A101.csv` | 18,484 |
| `PX_CAT_G1V2.csv` | 37 |

These counts will later be useful for Bronze completeness validation.

The distinction is:

```text
Issue #17
    ↓
Observe/document source row counts

Later Bronze validation
    ↓
Compare source counts with Bronze table counts
```

---

# 7. CRM Source Profiling

## 7.1 `cust_info.csv`

### Source

```text
data/raw/crm/cust_info.csv
```

### Expected Bronze Table

```text
dw_bronze.crm_cust_info
```

### Observed Header

```text
cst_id
cst_key
cst_firstname
cst_lastname
cst_marital_status
cst_gndr
cst_create_date
```

### Observed Structure

```text
7 columns
18,494 data rows
```

### Example Observed Record

```text
11000,AW00011000,Jon,Yang,M,M,2025-10-06
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `cst_id` | `11000` | Integer-like identifier |
| `cst_key` | `AW00011000` | Alphanumeric string |
| `cst_firstname` | `Jon` | String |
| `cst_lastname` | `Yang` | String |
| `cst_marital_status` | `M` | Short categorical/string value |
| `cst_gndr` | `M` | Short categorical/string value |
| `cst_create_date` | `2025-10-06` | Date-like value |

### Profiling Still Required

The actual profiling process should verify:

- Maximum length of each string column
- Empty values
- Null-like values
- Numeric range of `cst_id`
- Date validity/format
- Whether all values conform to the observed patterns

No source values should be modified during this profiling activity.

---

# 8. `prd_info.csv`

### Source

```text
data/raw/crm/prd_info.csv
```

### Expected Bronze Table

```text
dw_bronze.crm_prd_info
```

### Observed Header

```text
prd_id
prd_key
prd_nm
prd_cost
prd_line
prd_start_dt
prd_end_dt
```

### Observed Structure

```text
7 columns
397 data rows
```

### Example Observed Record

```text
210,CO-RF-FR-R92B-58,HL Road Frame - Black- 58,,R ,2003-07-01,
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `prd_id` | `210` | Integer-like identifier |
| `prd_key` | `CO-RF-FR-R92B-58` | Alphanumeric string |
| `prd_nm` | `HL Road Frame - Black- 58` | String |
| `prd_cost` | empty in observed record | Numeric-like field; missing values must be profiled |
| `prd_line` | `R ` | Short string/categorical value |
| `prd_start_dt` | `2003-07-01` | Date-like value |
| `prd_end_dt` | empty in observed record | Date-like field; missing values must be profiled |

### Profiling Still Required

Verify:

- Maximum string lengths
- Numeric characteristics of `prd_cost`
- Frequency of empty values in `prd_cost`
- Frequency of empty values in `prd_end_dt`
- Date format consistency
- Numeric range of `prd_id`
- Actual patterns in `prd_key` and `prd_line`

Important:

An empty value observed in a source file is an observation, not a reason to clean or replace the value in Bronze.

---

# 9. `sales_details.csv`

### Source

```text
data/raw/crm/sales_details.csv
```

### Expected Bronze Table

```text
dw_bronze.crm_sales_details
```

### Observed Header

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

### Observed Structure

```text
9 columns
60,398 data rows
```

### Example Observed Record

```text
SO43697,BK-R93R-62,21768,20101229,20110105,20110110,3578,1,3578
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `sls_ord_num` | `SO43697` | String/order identifier |
| `sls_prd_key` | `BK-R93R-62` | Alphanumeric string |
| `sls_cust_id` | `21768` | Integer-like identifier |
| `sls_order_dt` | `20101229` | Date-like value represented numerically |
| `sls_ship_dt` | `20110105` | Date-like value represented numerically |
| `sls_due_dt` | `20110110` | Date-like value represented numerically |
| `sls_sales` | `3578` | Numeric-like measure |
| `sls_quantity` | `1` | Numeric-like quantity |
| `sls_price` | `3578` | Numeric-like measure |

### Important Observation

The date representation here differs from the `cust_info.csv` example.

`cust_info.csv` contains:

```text
2025-10-06
```

while `sales_details.csv` contains values such as:

```text
20101229
```

This difference must be documented before Bronze loading.

The Bronze layer should preserve the source meaning and representation as appropriate rather than silently assuming that every source date has the same format.

---

# 10. ERP Source Profiling

## 10.1 `CUST_AZ12.csv`

### Source

```text
data/raw/erp/CUST_AZ12.csv
```

### Expected Bronze Table

```text
dw_bronze.erp_cust_az12
```

### Observed Header

```text
CID
BDATE
GEN
```

### Observed Structure

```text
3 columns
18,484 data rows
```

### Example Observed Record

```text
NASAW00011000,1971-10-06,Male
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `CID` | `NASAW00011000` | Alphanumeric identifier |
| `BDATE` | `1971-10-06` | Date-like value |
| `GEN` | `Male` | String/categorical value |

### Profiling Still Required

Verify:

- Maximum `CID` length
- Maximum `GEN` length
- Empty values
- Date validity and format
- Identifier patterns

---

# 11. `LOC_A101.csv`

### Source

```text
data/raw/erp/LOC_A101.csv
```

### Expected Bronze Table

```text
dw_bronze.erp_loc_a101
```

### Observed Header

```text
CID
CNTRY
```

### Observed Structure

```text
2 columns
18,484 data rows
```

### Example Observed Record

```text
AW-00011000,Australia
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `CID` | `AW-00011000` | Alphanumeric identifier |
| `CNTRY` | `Australia` | String/country value |

### Profiling Still Required

Verify:

- Maximum identifier length
- Maximum country-name length
- Empty values
- Identifier patterns
- Distinct country values if useful for understanding the source

No country standardization should be performed in Bronze.

---

# 12. `PX_CAT_G1V2.csv`

### Source

```text
data/raw/erp/PX_CAT_G1V2.csv
```

### Expected Bronze Table

```text
dw_bronze.erp_px_cat_g1v2
```

### Observed Header

```text
ID
CAT
SUBCAT
MAINTENANCE
```

### Observed Structure

```text
4 columns
37 data rows
```

### Example Observed Record

```text
AC_BR,Accessories,Bike Racks,Yes
```

### Initial Observations

| Column | Example | Initial Observation |
|---|---|---|
| `ID` | `AC_BR` | String/code |
| `CAT` | `Accessories` | String/category |
| `SUBCAT` | `Bike Racks` | String/subcategory |
| `MAINTENANCE` | `Yes` | String/categorical value |

### Profiling Still Required

Verify:

- Maximum lengths
- Empty values
- Distinct categorical values
- Identifier patterns

No categorical standardization should be performed in Bronze.

---

# 13. Consolidated Source Profiling Inventory

The current observed source structure is:

| Source | Columns | Observed Rows | Bronze Table |
|---|---:|---:|---|
| `cust_info.csv` | 7 | 18,494 | `crm_cust_info` |
| `prd_info.csv` | 7 | 397 | `crm_prd_info` |
| `sales_details.csv` | 9 | 60,398 | `crm_sales_details` |
| `CUST_AZ12.csv` | 3 | 18,484 | `erp_cust_az12` |
| `LOC_A101.csv` | 2 | 18,484 | `erp_loc_a101` |
| `PX_CAT_G1V2.csv` | 4 | 37 | `erp_px_cat_g1v2` |
| **Total** | **32** | **116,294** | **6 tables** |

The total row count is the sum of the observed source dataset row counts.

---

# 14. Source-to-Bronze Schema Mapping Principle

The Bronze schema should remain close to the source schema.

The mapping principle is:

```text
Source Column
      ↓
Bronze Column
```

rather than:

```text
Source Column
      ↓
Business Transformation
      ↓
New Business Column
```

For example:

```text
cust_info.csv
     |
     +-- cst_id
     +-- cst_key
     +-- cst_firstname
     +-- cst_lastname
     +-- cst_marital_status
     +-- cst_gndr
     +-- cst_create_date
     |
     v
crm_cust_info
```

This maintains source traceability.

---

# 15. Data Type Decision Process

The profiling results should be used to select MySQL datatypes.

The decision process is:

```text
Observed Source Values
        ↓
Understand Data Pattern
        ↓
Determine Appropriate MySQL Type
        ↓
Document Decision
        ↓
Create Bronze DDL
```

Examples of questions to answer:

### Integer-like column

- Are all values numeric?
- Are decimal values possible?
- What is the observed range?
- Is the field actually an identifier?

### String column

- What is the maximum observed length?
- Are spaces present?
- Are values alphanumeric?
- Are special characters present?

### Date-like column

- What is the source format?
- Are empty values present?
- Are all values valid dates?
- Does the format differ between source files?

### Numeric measure

- Are values integers?
- Are decimal values present?
- What is the observed range?
- Are empty values present?

The final MySQL type should be documented rather than guessed.

---

# 16. Important Distinction: Identifier vs Business Measure

Profiling should not automatically assume that every numeric-looking value should be treated as a numeric business measure.

For example:

```text
cst_id = 11000
```

is numeric-looking, but semantically it is an identifier.

Similarly:

```text
sls_cust_id = 21768
```

is an identifier linking a sales record to a customer.

Therefore, profiling should consider both:

```text
Physical representation
+
Observed/known source meaning
```

The Bronze layer still preserves the source field rather than converting it into a new business model.

---

# 17. Null and Empty-Value Profiling

An important part of profiling is identifying missing values.

For example, the observed `prd_info.csv` record contains:

```text
...,HL Road Frame - Black- 58,,R ,2003-07-01,
```

This indicates empty source fields in the observed record.

The profiling task is to determine:

- Which columns can be empty?
- How frequently are they empty?
- Are they represented as empty strings?
- Are there actual textual null markers?
- Does the source use a consistent representation?

The Bronze layer should not silently replace these values with business defaults during this issue.

---

# 18. Date Profiling

The six source files should be checked for date-like columns.

Known examples include:

```text
cust_info.csv
cst_create_date
2025-10-06
```

```text
prd_info.csv
prd_start_dt
2003-07-01
```

```text
sales_details.csv
sls_order_dt
20101229
```

```text
CUST_AZ12.csv
BDATE
1971-10-06
```

The important observation is that date representations are not necessarily identical across source files.

Therefore, the Bronze implementation must account for the actual source representation.

Any required parsing/conversion for database loading should be explicitly designed and documented rather than being an accidental transformation.

---

# 19. Profiling vs Transformation

This distinction is critical.

## Profiling

```text
"What is in the source?"
```

Examples:

- What values occur?
- What lengths occur?
- What data type does the value resemble?
- How many records exist?
- Are values empty?
- What date format is used?

## Transformation

```text
"How should we change the source?"
```

Examples:

- Standardize gender
- Clean names
- Convert business codes
- Remove duplicates
- Apply business rules
- Join datasets
- Calculate metrics

Issue #17 performs the first category only.

---

# 20. What Profiling Must NOT Do

The profiling process must not:

- Modify source CSV files
- Modify files in `data/raw/`
- Clean source values
- Standardize source values
- Remove duplicates
- Join CRM and ERP datasets
- Create dimensions
- Create facts
- Apply business rules
- Perform Silver transformations
- Perform Gold transformations

The purpose is observation and schema understanding.

---

# 21. Recommended Profiling Implementation

For this project, the profiling can be performed using Python.

A profiling script may use:

```text
Python
├── pathlib
├── csv
├── collections
└── optionally pandas
```

The current project contains relatively small source files, so a simple Python profiling implementation is sufficient.

The profiling script should be reusable rather than creating six unrelated scripts.

Conceptually:

```text
scripts/
└── extract/
    └── profile_source_data.py
```

The script can:

1. Discover the six CSV files.
2. Read their headers.
3. Count rows.
4. Inspect values.
5. Calculate relevant string lengths.
6. Identify empty values.
7. Report date-like patterns.
8. Produce profiling output.

The profiling script should not load data into MySQL.

---

# 22. Profiling Output Design

The output should make schema decisions easy to review.

A useful format is:

```text
Source File
    ↓
Column
    ↓
Observed Type
    ↓
Max Length
    ↓
Null/Empty Count
    ↓
Sample Value
    ↓
Format/Pattern
    ↓
Proposed MySQL Type
```

Example:

| Source File | Column | Sample | Observed Type | Empty Count | Max Length | Proposed MySQL Type |
|---|---|---|---|---:|---:|---|
| `cust_info.csv` | `cst_id` | `11000` | Integer-like | To profile | N/A | To decide |
| `cust_info.csv` | `cst_key` | `AW00011000` | String | To profile | To profile | To decide |
| `cust_info.csv` | `cst_create_date` | `2025-10-06` | Date-like | To profile | N/A | To decide |

The final table should contain actual measured values from the profiling run.

---

# 23. Bronze Schema Decision Record

After profiling, every column should have a documented decision.

Recommended structure:

| Source System | Source File | Source Column | Observed Characteristics | Bronze Column | MySQL Type | Decision / Reason |
|---|---|---|---|---|---|---|
| CRM | `cust_info.csv` | `cst_id` | Integer-like identifier | `cst_id` | TBD | Based on observed source values |
| CRM | `cust_info.csv` | `cst_key` | Alphanumeric identifier | `cst_key` | TBD | Preserve source key |
| CRM | `cust_info.csv` | `cst_create_date` | `YYYY-MM-DD` | `cst_create_date` | TBD | Based on source date format |

The `TBD` values should be replaced after the actual profiling run.

---

# 24. Expected Profiling Deliverables

Issue #17 should produce:

### Deliverable 1 — Profiling Script

```text
scripts/extract/profile_source_data.py
```

if the profiling is automated.

### Deliverable 2 — Profiling Results

A documented output containing:

- File inventory
- Column inventory
- Row counts
- Observed data types
- Empty/null counts
- Maximum string lengths
- Date formats
- Sample values
- Relevant value patterns

### Deliverable 3 — Bronze Schema Decisions

A mapping from:

```text
Source Column
      ↓
Bronze Column
      ↓
MySQL Data Type
```

These deliverables become the input to Issue #18.

---

# 25. Relationship to Issue #18

Issue #17 should finish with enough information to answer:

> "What should the six Bronze tables look like?"

Issue #18 will then answer:

> "How do we create and populate those six Bronze tables?"

The workflow is therefore:

```text
Issue #17
Data Profiling
       |
       v
Understand source schema
       |
       v
Choose Bronze MySQL datatypes
       |
       v
Issue #18
Bronze Data Ingestion
       |
       +--> CREATE TABLE
       |
       +--> TRUNCATE
       |
       +--> LOAD / INSERT
       |
       +--> Six Bronze tables
```

---

# 26. Acceptance Criteria

- [ ] `cust_info.csv` profiled
- [ ] `prd_info.csv` profiled
- [ ] `sales_details.csv` profiled
- [ ] `CUST_AZ12.csv` profiled
- [ ] `LOC_A101.csv` profiled
- [ ] `PX_CAT_G1V2.csv` profiled
- [ ] Exact source column names documented
- [ ] Number of columns documented
- [ ] Source row counts documented
- [ ] Observed data types documented
- [ ] Sample values documented
- [ ] Empty/null-like values profiled
- [ ] Relevant string lengths profiled
- [ ] Relevant numeric ranges profiled
- [ ] Date representations documented
- [ ] Source patterns/anomalies documented
- [ ] Bronze MySQL datatype decisions documented
- [ ] Source-to-Bronze mapping documented
- [ ] Profiling does not modify source data
- [ ] Profiling results are sufficient for Bronze DDL creation

---

# 27. Expected Outcome

At the end of Issue #17, we should have a clear, evidence-based understanding of all six incoming source datasets.

The final result should allow us to move from:

```text
"We have six CSV files."
```

to:

```text
"We understand the schema and observed characteristics
of the six source datasets and can now define the
six Bronze MySQL tables."
```

The next issue will be:

```text
Issue #18
Coding: Bronze Data Ingestion
```

with the implementation flow:

```text
Profiled Source Data
        ↓
Bronze DDL
        ↓
Create Tables
        ↓
TRUNCATE
        ↓
Load Source Data
        ↓
Bronze Tables
```

---

# 28. Final Issue Flow

```text
SOURCE SYSTEMS
       ↓
Source Analysis
       ↓
Source Acquisition
       ↓
data/raw/
       ↓
┌─────────────────────────┐
│ Issue #17               │
│ DATA PROFILING          │
│                         │
│ Columns                 │
│ Types                   │
│ Values                  │
│ Nulls/Empty             │
│ Dates                   │
│ Lengths/Ranges          │
└─────────────────────────┘
       ↓
Bronze Schema Decisions
       ↓
┌─────────────────────────┐
│ Issue #18               │
│ BRONZE DATA INGESTION   │
│                         │
│ DDL                     │
│ Tables                  │
│ Full Load               │
│ TRUNCATE + LOAD         │
└─────────────────────────┘
       ↓
Bronze Validation
       ↓
Silver
```
