# Bronze Layer — Source CSV Metadata Analysis for DDL / Table Design

## 1. Why We Are Doing This Before Writing the DDL

Before writing a single `CREATE TABLE` statement for the Bronze layer, we first understand the incoming source files.

The sequence is:

```text
Source files
    ↓
Open / inspect the files
    ↓
Understand metadata
    ↓
Understand structure
    ↓
Understand columns
    ↓
Look at actual values
    ↓
Understand data types
    ↓
Notice empty / missing values
    ↓
Understand date formats
    ↓
Decide Bronze table names
    ↓
Decide Bronze column names
    ↓
Decide MySQL data types
    ↓
Decide nullability / constraints
    ↓
Write Bronze DDL
    ↓
Create empty Bronze tables
    ↓
Later: load the data
```

The important point is:

> **We do not write the DDL first and then try to understand the source. We understand the source first and then design the DDL.**

This follows the speaker's workflow: before creating the Bronze DDL, understand the metadata, structure, and schema of the incoming data. The information can come from source-system technical experts or by exploring the incoming files ourselves. For this portfolio project, we use the second approach.

---

# 2. Where We Are in the Pipeline

Source analysis and source acquisition have already been completed.

```text
External DATA SOURCES
        ↓
Source System Analysis
        ↓
Source Acquisition
        ↓
data/raw/
        ↓
Metadata / Data Profiling
        ↓
Bronze Table Design
        ↓
Bronze DDL
        ↓
Empty Bronze Tables
        ↓
Bronze Data Ingestion
        ↓
Bronze Validation
```

This document focuses on:

```text
Metadata / Data Profiling
        ↓
Bronze Table Design
        ↓
Bronze DDL
```

---

# 3. Bronze Design We Already Decided

| Design Aspect | Decision |
|---|---|
| Definition | Raw, unprocessed source data |
| Objective | Traceability and debugging |
| Object type | Tables |
| Load method | Full load |
| Full-load pattern | Truncate + load |
| Data transformation | None |
| Data modeling | None |
| Main audience | Data Engineers |

Therefore, our DDL creates **source-oriented empty tables**.

We are not creating:

```text
dim_customer
dim_product
fact_sales
```

at this stage.

We are creating tables representing the source datasets.

---

# 4. What We Are Trying to Learn From the CSV Files

When opening each CSV, we ask:

### Structural questions

- What is the file name?
- Which source system does it belong to?
- What are the column names?
- How many columns exist?
- What is the column order?
- Is there a header?
- What delimiter is used?

### Data questions

- What does each column contain?
- Is it numeric, text, date-like, or categorical?
- Is it an identifier or a measure?
- Are values empty?
- Are there spaces?
- Are values consistently formatted?
- What string lengths occur?
- What numeric ranges occur?
- What date format is used?

### DDL questions

- What should the Bronze table be called?
- What should each Bronze column be called?
- What MySQL datatype should each column use?
- What length should a string have?
- Should it allow `NULL`?
- Is a primary key actually supported by source evidence?
- Is a foreign key actually required?
- Should defaults be avoided?

The overall pattern is:

```text
Observed source
      ↓
Understanding
      ↓
Engineering decision
      ↓
DDL definition
```

---

# 5. Observation vs Engineering Decision

Keep these separate.

### Observation

Something actually seen in the source.

Example:

```text
cst_id contains values such as 11000.
```

### Decision

What we decide based on the observation.

Example:

```text
Represent cst_id using an integer-compatible MySQL datatype.
```

So:

```text
OBSERVATION
    ↓
UNDERSTANDING
    ↓
ENGINEERING DECISION
    ↓
DDL
```

This is also why our SQL comments should explain **why** a table name, datatype, length, or constraint was selected.

---

# 6. Source Files

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

There are:

```text
CRM → 3 files
ERP → 3 files
Total → 6 source files
```

Therefore, the initial Bronze layer will contain six tables.

---

# 7. Bronze Naming Convention

The speaker follows:

```text
<source_system>_<source_table>
```

We apply the same concept.

## CRM

```text
cust_info.csv
      ↓
crm_cust_info

prd_info.csv
      ↓
crm_prd_info

sales_details.csv
      ↓
crm_sales_details
```

## ERP

```text
CUST_AZ12.csv
      ↓
erp_cust_az12

LOC_A101.csv
      ↓
erp_loc_a101

PX_CAT_G1V2.csv
      ↓
erp_px_cat_g1v2
```

### Why include the source system?

If we see:

```text
crm_cust_info
```

we immediately know:

```text
Source system = CRM
Source dataset = cust_info
```

Likewise:

```text
erp_cust_az12
```

immediately identifies ERP.

So the table name itself contributes to source traceability.

---

# 8. Why Bronze Column Names Stay Close to the Source

The speaker's approach is one-to-one source-to-Bronze columns.

For example:

```text
Source                  Bronze

cst_id          →       cst_id
cst_key         →       cst_key
cst_firstname   →       cst_firstname
cst_lastname    →       cst_lastname
```

We do not immediately rename:

```text
cst_firstname
```

to:

```text
customer_first_name
```

because Bronze is source-oriented.

The idea is:

```text
SOURCE STRUCTURE
      ↓
BRONZE STRUCTURE
```

not:

```text
SOURCE
      ↓
Business Model
      ↓
Bronze
```

---

# 9. CRM — `cust_info.csv`

## Source

```text
data/raw/crm/cust_info.csv
```

## Bronze table

```text
dw_bronze.crm_cust_info
```

## Header observed

```text
cst_id
cst_key
cst_firstname
cst_lastname
cst_marital_status
cst_gndr
cst_create_date
```

There are:

```text
7 columns
18,494 observed data rows
```

Example record:

```text
11000,AW00011000,Jon,Yang,M,M,2025-10-06
```

---

# 10. `cust_info.csv` — Column Decisions

## `cst_id`

Observed:

```text
11000
```

Observation:

- Numeric-looking
- Identifier-oriented

Potential Bronze type:

```sql
cst_id INT
```

Reason:

- Values are integer-like.
- The source field is an ID.
- The source column name is preserved.

Do not automatically declare it a primary key unless profiling/source requirements establish uniqueness and non-nullability.

---

## `cst_key`

Observed:

```text
AW00011000
```

Observation:

- Alphanumeric
- Identifier/key
- Cannot be represented as a normal integer

Potential:

```sql
cst_key VARCHAR(50)
```

Reason:

- The source value contains letters and digits.
- `VARCHAR` preserves the identifier format.
- The length should ultimately be based on actual profiling.

Example DDL comment:

```sql
-- Source field: cst_key
-- Observed as an alphanumeric customer key such as AW00011000.
-- VARCHAR is used because the source value contains letters and digits.
cst_key VARCHAR(50)
```

---

## `cst_firstname`

Observed:

```text
Jon
```

Observation:

- Text

Potential:

```sql
cst_firstname VARCHAR(...)
```

The exact length should be selected after measuring the source.

---

## `cst_lastname`

Observed:

```text
Yang
```

Observation:

- Text

Potential:

```sql
cst_lastname VARCHAR(...)
```

Again, use profiling to determine an appropriate length.

---

## `cst_marital_status`

Observed example:

```text
M
```

Observation:

- Short source code/category

Potential:

```sql
cst_marital_status VARCHAR(...)
```

Do not convert the value to another business representation in Bronze.

---

## `cst_gndr`

Observed example:

```text
M
```

Observation:

- Short categorical/source value

Potential:

```sql
cst_gndr VARCHAR(...)
```

Do not standardize it during Bronze.

---

## `cst_create_date`

Observed:

```text
2025-10-06
```

Observation:

```text
YYYY-MM-DD
```

Potential:

```sql
cst_create_date DATE
```

The actual column should be finalized after checking all records.

---

# 11. First Bronze Table — Design Concept

The first table conceptually becomes:

```sql
CREATE TABLE dw_bronze.crm_cust_info (

    -- Source column: cst_id.
    -- Observed as an integer-like customer identifier.
    -- Source name is preserved for Bronze traceability.
    cst_id INT,

    -- Source column: cst_key.
    -- Observed as an alphanumeric customer key.
    -- VARCHAR preserves letters and digits.
    cst_key VARCHAR(50),

    -- Source descriptive text.
    cst_firstname VARCHAR(...),

    -- Source descriptive text.
    cst_lastname VARCHAR(...),

    -- Source categorical value; no Bronze standardization.
    cst_marital_status VARCHAR(...),

    -- Source categorical value; no Bronze standardization.
    cst_gndr VARCHAR(...),

    -- Source date observed in YYYY-MM-DD format.
    cst_create_date DATE
);
```

The `...` values must come from actual profiling.

---

# 12. CRM — `prd_info.csv`

## Source

```text
data/raw/crm/prd_info.csv
```

## Bronze

```text
dw_bronze.crm_prd_info
```

## Header

```text
prd_id
prd_key
prd_nm
prd_cost
prd_line
prd_start_dt
prd_end_dt
```

There are:

```text
7 columns
397 observed data rows
```

Example:

```text
210,CO-RF-FR-R92B-58,HL Road Frame - Black- 58,,R ,2003-07-01,
```

---

# 13. `prd_info.csv` — Important Observations

## `prd_id`

Observed:

```text
210
```

Looks integer-like and identifier-oriented.

Potential:

```sql
prd_id INT
```

But confirm the range.

---

## `prd_key`

Observed:

```text
CO-RF-FR-R92B-58
```

Alphanumeric product key.

Potential:

```sql
prd_key VARCHAR(...)
```

Length should be based on profiling.

---

## `prd_nm`

Observed:

```text
HL Road Frame - Black- 58
```

Descriptive text.

Potential:

```sql
prd_nm VARCHAR(...)
```

---

## `prd_cost`

Observed example is empty.

This is important.

We should **not** automatically replace an empty source value with `0`.

Instead ask:

```text
How many rows are empty?
Are non-empty values integers or decimals?
What is the range?
Does the source use empty string or another null marker?
```

Then choose the numeric datatype and nullability.

---

## `prd_line`

Observed:

```text
R 
```

Notice the possible trailing space.

That is a source observation.

Do not automatically trim it in Bronze.

---

## `prd_start_dt`

Observed:

```text
2003-07-01
```

Potential:

```sql
prd_start_dt DATE
```

---

## `prd_end_dt`

Observed example is empty.

We need to determine:

- How many are empty?
- Is an empty value meaningful?
- Does the source guarantee this field?
- How is the absence represented?

Do not invent a business default such as `9999-12-31`.

---

# 14. CRM — `sales_details.csv`

## Source

```text
data/raw/crm/sales_details.csv
```

## Bronze

```text
dw_bronze.crm_sales_details
```

## Header

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

There are:

```text
9 columns
60,398 observed data rows
```

Example:

```text
SO43697,BK-R93R-62,21768,20101229,20110105,20110110,3578,1,3578
```

---

# 15. `sales_details.csv` — Important Observations

## `sls_ord_num`

```text
SO43697
```

Alphanumeric order identifier.

Potential:

```sql
sls_ord_num VARCHAR(...)
```

---

## `sls_prd_key`

```text
BK-R93R-62
```

Alphanumeric product key.

Potential:

```sql
sls_prd_key VARCHAR(...)
```

---

## `sls_cust_id`

```text
21768
```

Integer-like customer identifier.

Potential:

```sql
sls_cust_id INT
```

This does not mean we should immediately create a foreign key in Bronze.

---

## `sls_order_dt`

Observed:

```text
20101229
```

This is date-like but uses:

```text
YYYYMMDD
```

rather than:

```text
YYYY-MM-DD
```

This difference must be understood before deciding how the Bronze loader will represent the field.

---

## `sls_ship_dt`

Observed:

```text
20110105
```

Same `YYYYMMDD` style needs to be profiled.

---

## `sls_due_dt`

Observed:

```text
20110110
```

Again, profile the complete column.

---

## `sls_sales`

Observed:

```text
3578
```

This is numeric-looking and appears to be a measure.

Before choosing `INT` or `DECIMAL`, check:

- Are decimals present?
- Minimum
- Maximum
- Negative values
- Empty values

---

## `sls_quantity`

Observed:

```text
1
```

Integer-like quantity.

Potential:

```sql
sls_quantity INT
```

after checking the range.

---

## `sls_price`

Observed:

```text
3578
```

Do not automatically assume `INT`.

Check whether decimal prices exist.

If monetary values can contain decimals, an appropriate `DECIMAL` type may be more suitable.

---

# 16. ERP — `CUST_AZ12.csv`

## Source

```text
data/raw/erp/CUST_AZ12.csv
```

## Bronze

```text
dw_bronze.erp_cust_az12
```

## Header

```text
CID
BDATE
GEN
```

There are:

```text
3 columns
18,484 observed rows
```

Example:

```text
NASAW00011000,1971-10-06,Male
```

### `CID`

Alphanumeric identifier.

Potential:

```sql
CID VARCHAR(...)
```

### `BDATE`

Date-like:

```text
1971-10-06
```

Potential:

```sql
BDATE DATE
```

### `GEN`

String/categorical source value:

```text
Male
```

Potential:

```sql
GEN VARCHAR(...)
```

Do not convert `Male` to `M` in Bronze.

---

# 17. ERP — `LOC_A101.csv`

## Source

```text
data/raw/erp/LOC_A101.csv
```

## Bronze

```text
dw_bronze.erp_loc_a101
```

## Header

```text
CID
CNTRY
```

There are:

```text
2 columns
18,484 observed rows
```

Example:

```text
AW-00011000,Australia
```

### `CID`

Alphanumeric identifier.

Potential:

```sql
CID VARCHAR(...)
```

### `CNTRY`

Text/country value.

Potential:

```sql
CNTRY VARCHAR(...)
```

Do not convert:

```text
Australia → AU
```

during Bronze.

---

# 18. ERP — `PX_CAT_G1V2.csv`

## Source

```text
data/raw/erp/PX_CAT_G1V2.csv
```

## Bronze

```text
dw_bronze.erp_px_cat_g1v2
```

## Header

```text
ID
CAT
SUBCAT
MAINTENANCE
```

There are:

```text
4 columns
37 observed rows
```

Example:

```text
AC_BR,Accessories,Bike Racks,Yes
```

### `ID`

Alphanumeric code:

```text
AC_BR
```

Potential:

```sql
ID VARCHAR(...)
```

### `CAT`

Category text:

```text
Accessories
```

Potential:

```sql
CAT VARCHAR(...)
```

### `SUBCAT`

Subcategory text:

```text
Bike Racks
```

Potential:

```sql
SUBCAT VARCHAR(...)
```

### `MAINTENANCE`

Categorical text:

```text
Yes
```

Potential:

```sql
MAINTENANCE VARCHAR(...)
```

Do not convert:

```text
Yes → 1
No → 0
```

in Bronze.

---

# 19. Consolidated Source Inventory

| Source File | Columns | Observed Rows | Bronze Table |
|---|---:|---:|---|
| `cust_info.csv` | 7 | 18,494 | `crm_cust_info` |
| `prd_info.csv` | 7 | 397 | `crm_prd_info` |
| `sales_details.csv` | 9 | 60,398 | `crm_sales_details` |
| `CUST_AZ12.csv` | 3 | 18,484 | `erp_cust_az12` |
| `LOC_A101.csv` | 2 | 18,484 | `erp_loc_a101` |
| `PX_CAT_G1V2.csv` | 4 | 37 | `erp_px_cat_g1v2` |
| **Total** | **32** | **116,294** | **6 tables** |

These are source observations and become useful later for Bronze completeness validation.

---

# 20. Why We Do Not Automatically Add Primary Keys

A numeric field named `id` is not automatically a primary key.

Before writing:

```sql
PRIMARY KEY (cst_id)
```

we should establish:

- Is it unique?
- Is it always present?
- Does the source guarantee uniqueness?
- Can duplicate source records occur?

If we do not know, we should not invent the constraint.

This matters because a strict primary key can cause Bronze ingestion to reject source records.

Bronze's job is to preserve and make source data traceable, not to enforce an unverified business model.

---

# 21. Why We Do Not Automatically Add Foreign Keys

For example:

```text
sls_cust_id
```

looks like it could reference:

```text
crm_cust_info.cst_id
```

But we should not immediately create:

```sql
FOREIGN KEY (sls_cust_id)
REFERENCES crm_cust_info(cst_id)
```

because:

- CRM and ERP are separate source systems.
- Source relationships may not be formally guaranteed.
- Missing references may exist.
- Bronze should not reject source data simply because an assumed business relationship fails.

The integrated business model belongs downstream.

---

# 22. Why We Do Not Make Every Column `NOT NULL`

Do not automatically write:

```sql
NOT NULL
```

for every source column.

We already observed an empty value in:

```text
prd_cost
prd_end_dt
```

Therefore, we need to understand actual source nullability first.

Otherwise the loader could fail because the DDL is stricter than the source.

---

# 23. Why We Avoid Artificial Defaults

Do not automatically add:

```sql
DEFAULT 0
```

or:

```sql
DEFAULT 'UNKNOWN'
```

or:

```sql
DEFAULT '1900-01-01'
```

unless the source/system requirements explicitly require it.

A default changes the data that arrived from the source.

Bronze should preserve source meaning.

---

# 24. DDL Comment Philosophy

Our DDL should explain the engineering reasoning.

Instead of:

```sql
CREATE TABLE dw_bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50)
);
```

we can write:

```sql
-- Bronze table for CRM cust_info source dataset.
-- Naming convention:
-- <source_system>_<source_table>
-- This makes source lineage visible from the Bronze table name.

CREATE TABLE dw_bronze.crm_cust_info (

    -- Source column: cst_id.
    -- Observed as an integer-like customer identifier.
    -- Source column name is preserved for traceability.
    cst_id INT,

    -- Source column: cst_key.
    -- Observed as an alphanumeric customer key.
    -- VARCHAR is used because the source contains letters and digits.
    cst_key VARCHAR(50)
);
```

The comments answer:

```text
WHY THIS TABLE NAME?
WHY THIS COLUMN NAME?
WHY THIS DATATYPE?
WHY THIS LENGTH?
WHY THIS CONSTRAINT?
```

That makes the DDL understandable to another engineer.

---

# 25. DDL Header Documentation

At the top of the SQL file we can document the overall design:

```sql
-- ============================================================
-- Bronze Layer DDL
-- ============================================================
--
-- Purpose:
-- Create empty Bronze tables representing the source datasets.
--
-- Bronze principles:
-- 1. Preserve source-oriented structure.
-- 2. Keep source column names aligned with the source.
-- 3. Do not apply business transformations.
-- 4. Do not create dimensional models.
-- 5. Use source-system prefixes in Bronze table names.
--
-- The DDL defines table structure only.
-- Data loading is handled separately.
-- ============================================================
```

---

# 26. DDL and Data Loading Are Different

This is very important.

### DDL

Defines the destination structure:

```text
CREATE TABLE
      ↓
Empty Bronze table
```

### Loading

Puts source data into the table:

```text
TRUNCATE
      ↓
LOAD / INSERT
      ↓
Bronze data
```

So:

```text
DDL
=
"What should the table look like?"
```

while:

```text
Loader
=
"How do we put the source data into the table?"
```

The speaker first creates the six empty tables and only afterward moves to loading the data.

---

# 27. Expected Result After DDL

After executing the DDL:

```text
dw_bronze
│
├── crm_cust_info
├── crm_prd_info
├── crm_sales_details
├── erp_cust_az12
├── erp_loc_a101
└── erp_px_cat_g1v2
```

At this stage:

```text
Tables = YES
Rows = 0
```

This is intentional.

The tables are the destination structures for the next ingestion step.

---

# 28. What We Are NOT Doing During Bronze DDL

We are not:

```text
❌ cleaning names
❌ trimming business values
❌ standardizing gender
❌ standardizing country names
❌ removing duplicates
❌ joining CRM and ERP
❌ creating dimensions
❌ creating facts
❌ calculating metrics
❌ creating surrogate keys
❌ applying business rules
```

We are:

```text
✅ understanding the source
✅ preserving source column names
✅ designing source-oriented Bronze tables
✅ choosing evidence-based datatypes
✅ documenting nullability
✅ avoiding unsupported constraints
✅ creating empty Bronze structures
```

---

# 29. The Complete Engineering Sequence

Keep this sequence in mind:

```text
STEP 1
Source System Analysis
        ↓
What is this source system?

STEP 2
Source Acquisition
        ↓
How do we bring the source files into our environment?

STEP 3
Data Profiling
        ↓
What exactly is inside these files?

STEP 4
Metadata Analysis
        ↓
What are the columns, values, formats and types?

STEP 5
Bronze Schema Decision
        ↓
What should each Bronze table/column look like?

STEP 6
DDL
        ↓
Create the empty Bronze tables.

STEP 7
Data Ingestion
        ↓
TRUNCATE + load the complete source data.

STEP 8
Validation
        ↓
Did everything arrive correctly?

STEP 9
Silver
        ↓
Now we can clean, standardize and transform.
```

---

# 30. Final Source-to-DDL Decision Chain

For every column:

```text
Open CSV
   ↓
See column name
   ↓
Look at actual values
   ↓
Understand the pattern/meaning
   ↓
Check length/range/format/nulls
   ↓
Choose MySQL datatype
   ↓
Decide nullability
   ↓
Consider constraints
   ↓
Write a comment explaining the decision
   ↓
Write DDL
```

Example:

```text
cst_key
   ↓
AW00011000
   ↓
alphanumeric identifier
   ↓
string
   ↓
measure maximum observed length
   ↓
choose VARCHAR(...)
   ↓
preserve source name
   ↓
document reason
   ↓
DDL
```

---

# 31. What This Analysis Gives Us

The DDL writer now has a checklist.

## Table level

```text
Source system?
Source file?
Bronze table name?
Why this name?
```

## Column level

```text
Source column?
Observed values?
Observed pattern?
Data type?
Maximum length?
Nullability?
Constraint?
Why this decision?
```

Therefore the DDL is not:

> "I guessed the schema."

It becomes:

> "I inspected the source, documented what I found, and created the Bronze structure based on those observations."

---

# 32. Final Bronze Design Target

The final DDL should create:

```text
dw_bronze
│
├── crm_cust_info
├── crm_prd_info
├── crm_sales_details
├── erp_cust_az12
├── erp_loc_a101
└── erp_px_cat_g1v2
```

with:

```text
Source-oriented table names
        +
Source-oriented column names
        +
Evidence-based MySQL datatypes
        +
Justified nullability
        +
Only justified constraints
        +
Comments explaining design decisions
```

Initially:

```text
6 tables
0 rows
```

Then:

```text
CSV files
    ↓
Bronze loading script
    ↓
TRUNCATE
    ↓
LOAD / INSERT
    ↓
6 Bronze tables populated
```

---

# 33. Short Interview Explanation

If asked:

> How do you design Bronze tables from source files?

A good answer is:

> "First I inspect and profile the source files to understand their metadata, structure, column names, actual values, data types, formats, nulls, and relevant length or range characteristics. Then I define source-oriented Bronze table names using the source system and source table name. I keep the Bronze column names aligned with the source columns and choose MySQL datatypes based on the observed source data. I avoid unnecessary business constraints and transformations because Bronze is meant to preserve the source data. Once the schema decisions are documented, I create the DDL for the six empty Bronze tables. The actual full data load is handled separately."

---

# 34. Next Step

This document is the bridge between:

```text
DATA PROFILING
       ↓
BRONZE SCHEMA DESIGN
       ↓
DDL
```

The next implementation sequence is:

```text
1. Finish/verify actual profiling measurements
             ↓
2. Finalize datatype and nullability decisions
             ↓
3. Write MySQL Bronze DDL
             ↓
4. Execute DDL
             ↓
5. Verify six empty Bronze tables
             ↓
6. Build Bronze loading code
             ↓
7. TRUNCATE + LOAD
             ↓
8. Validate source vs Bronze
```

**Important:** the observed examples in this document are based on the source files we inspected. Exact `VARCHAR` lengths, numeric precision/scale, nullability, and constraints should be finalized from the complete profiling results rather than guessed from one sample record.
