# Issue #16 — Design Bronze Layer and Define Bronze Loading Strategy

## Objective

Define the architecture, design decisions, loading strategy, validation strategy, and responsibilities of the Bronze layer before implementing Bronze data ingestion.

The source acquisition and landing process has already been implemented.

Source files are available in:

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

The Bronze layer will consume these landed source files and load them into the MySQL `dw_bronze` database.

---

## Bronze Layer Specifications

| Design Aspect | Decision |
|---|---|
| Definition | Raw, unprocessed data as-is from sources |
| Objective | Traceability & debugging |
| Object Type | Tables |
| Load Method | Full Load |
| Full Load Strategy | `TRUNCATE` + `INSERT` / Load |
| Data Transformation | None |
| Data Modeling | None |
| Target Audience | Data Engineers |

These decisions define the contract for the Bronze implementation.

---

## Architecture

```text
External Source Data
        |
        v
Python Source Acquisition
        |
        v
data/raw/
        |
        v
Bronze Data Ingestion
        |
        v
MySQL dw_bronze
```

The source acquisition mechanism is already implemented in Issue #14.

Therefore, Bronze ingestion begins from the landed files in `data/raw/`.

---

## Bronze Definition

The Bronze layer stores raw, unprocessed source data as-is from the source systems.

Its purpose is to establish a reliable warehouse copy of the incoming source data while maintaining traceability to the source.

Bronze is not responsible for making the data business-ready.

---

## Bronze Objective

The primary objectives are:

- Traceability
- Debugging
- Source-data preservation
- Reliable ingestion
- Completeness verification
- Providing a stable input for the Silver layer

If an issue occurs downstream, engineers should be able to inspect the Bronze data and compare it with the landed source data.

---

## Bronze Object Type

The Bronze layer will use physical database tables.

The current source inventory contains six datasets:

### CRM

```text
cust_info.csv
prd_info.csv
sales_details.csv
```

### ERP

```text
CUST_AZ12.csv
LOC_A101.csv
PX_CAT_G1V2.csv
```

The initial Bronze tables will therefore be:

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

The exact column definitions will be finalized through the Data Profiling issue.

---

## Load Method

Bronze will use a Full Load strategy.

The intended loading pattern is:

```text
Raw CSV
   |
   v
TRUNCATE Bronze Table
   |
   v
LOAD / INSERT Complete Source Data
   |
   v
Bronze Table
```

Each execution represents the complete current source snapshot.

The table is cleared before loading the source data so repeated full loads do not continuously append duplicate copies of the same source snapshot.

---

## Why Full Load?

The current project uses static source files and does not currently require incremental extraction.

Therefore, the initial Bronze implementation will use full loading.

This prioritizes:

- Simplicity
- Reproducibility
- Traceability
- Easy reruns
- Clear debugging

Incremental loading can be considered later if a source system provides reliable change tracking or watermark information.

---

## Data Transformation

Bronze will perform:

```text
NO BUSINESS TRANSFORMATION
```

Bronze should not:

- Calculate business metrics
- Apply business rules
- Standardize business values
- Create analytical aggregates
- Join unrelated datasets
- Create dimensions
- Create fact tables

Transformations belong to downstream layers.

---

## Data Modeling

Bronze will use:

```text
NO BUSINESS DATA MODELING
```

The Bronze tables will primarily represent the source datasets.

For example:

```text
cust_info.csv
      |
      v
crm_cust_info
```

The source structure will be preserved rather than immediately converted into a dimensional model.

---

## Source-to-Bronze Mapping

```text
source_crm/cust_info.csv
        ↓
dw_bronze.crm_cust_info

source_crm/prd_info.csv
        ↓
dw_bronze.crm_prd_info

source_crm/sales_details.csv
        ↓
dw_bronze.crm_sales_details

source_erp/CUST_AZ12.csv
        ↓
dw_bronze.erp_cust_az12

source_erp/LOC_A101.csv
        ↓
dw_bronze.erp_loc_a101

source_erp/PX_CAT_G1V2.csv
        ↓
dw_bronze.erp_px_cat_g1v2
```

The naming convention follows:

```text
<source_system>_<source_table>
```

This provides source lineage directly through the Bronze table name.

---

## Technology Decision

The reference implementation uses SQL Server.

This project implements the same Bronze-layer concepts using:

- MySQL
- Python
- SQL
- `mysql-connector-python`

SQL Server-specific commands and features will be replaced with their MySQL equivalents.

The architecture remains the same even though the database technology differs.

---

## Python vs MySQL Responsibilities

### Python

Python will control pipeline execution:

- Discover source files
- Determine loading sequence
- Connect to MySQL
- Execute Bronze operations
- Handle errors
- Log execution information
- Control the overall load process

### MySQL

MySQL will perform database operations:

- Create Bronze tables
- Truncate Bronze tables
- Load/insert source records
- Store Bronze data
- Execute SQL validations

The detailed implementation will be handled in the Bronze ingestion issue.

---

## Bronze Validation Strategy

Bronze validation will focus on ingestion correctness.

The planned checks include:

### Source row count vs Bronze row count

```text
Source CSV row count
        =
Bronze table row count
```

### Schema validation

```text
Source columns
        ↕
Bronze columns
```

### Column placement

Source values must be loaded into the correct Bronze columns.

### Load completeness

All expected source datasets must be successfully loaded.

### Error handling

A failed load must not silently appear as a successful pipeline execution.

Detailed cleansing, standardization, business rules, and other data-quality processing belong to later layers.

---

## Rerun Strategy

Bronze loads must be safely rerunnable.

The intended behavior is:

```text
Existing Bronze Data
        |
        v
     TRUNCATE
        |
        v
Load Current Source Snapshot
```

This prevents repeated full-load executions from continuously appending duplicate source snapshots.

---

## Traceability

The intended data lineage is:

```text
Source System
     ↓
Source File
     ↓
Raw / Landing
     ↓
Bronze Table
     ↓
Silver
     ↓
Gold
```

Example:

```text
source_crm/cust_info.csv
          ↓
data/raw/crm/cust_info.csv
          ↓
dw_bronze.crm_cust_info
          ↓
Silver customer data
          ↓
Gold customer dimension
```

---

## Scope Exclusions

This issue does not implement:

- Bronze table DDL
- Bronze loading code
- Bronze validation scripts
- Silver transformations
- Gold transformations
- Dimensional modeling
- Fact tables
- Dimension tables
- Business transformations
- Incremental loading
- Airflow orchestration
- PySpark processing

These will be handled in subsequent issues.

---

## Reference Architecture Alignment

The Bronze design follows these reference principles:

- Raw/unprocessed source data
- Traceability
- Debugging
- Tables
- Full loading
- Truncate before reload
- No transformations
- No data modeling
- Data Engineers as the primary audience

The reference implementation uses SQL Server, while this project adapts the same architectural concepts to MySQL and Python.

---

## Acceptance Criteria

- [ ] Bronze definition documented
- [ ] Bronze objective documented
- [ ] Bronze object type finalized as tables
- [ ] Full-load strategy finalized
- [ ] `TRUNCATE + INSERT/LOAD` rerun strategy finalized
- [ ] No-transformation rule documented
- [ ] No-data-modeling rule documented
- [ ] Six initial Bronze datasets identified
- [ ] Source-to-Bronze mappings documented
- [ ] MySQL implementation approach documented
- [ ] Python vs MySQL responsibilities documented
- [ ] Bronze validation strategy documented
- [ ] Traceability approach documented
- [ ] Bronze implementation scope separated from downstream layers

---

## Expected Outcome

The Bronze layer design is sufficiently defined to begin implementation without making major architectural decisions during coding.

Next:

```text
Bronze Design
      ↓
Data Profiling
      ↓
Bronze DDL / Table Creation
      ↓
Bronze Data Ingestion
      ↓
Bronze Validation
```
