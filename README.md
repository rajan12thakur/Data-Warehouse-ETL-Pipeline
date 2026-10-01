# Data Warehouse ETL Pipeline

![alt text](<datawarehouse-etl (1).png>)


A professional end-to-end Data Warehouse ETL pipeline built with **Python, MySQL, SQL, and a Bronze-Silver-Gold architecture**.

The project demonstrates how source-system data can be acquired, loaded into a raw Bronze layer, cleaned and standardized in Silver, and transformed into business-oriented analytical objects in Gold.

---

## 1. Project Overview

This project implements a small-scale enterprise-style data warehouse using data originating from two source systems:

- CRM
- ERP

The source data is provided as CSV files.

The pipeline follows a layered architecture:

```text
Source Systems / CSV Files
          |
          v
   Source Acquisition
          |
          v
      Raw / Landing
          |
          v
      Bronze Layer
          |
          v
       Silver Layer
          |
          v
        Gold Layer
          |
          v
 Analytics / Reporting
```

The project is designed to demonstrate practical Data Engineering concepts including:

- Source-system analysis
- Data profiling
- Source acquisition
- Data ingestion
- ETL / ELT
- Data quality
- Data standardization
- Data integration
- Data warehouse modeling
- Star schema
- Dimension and fact design
- Surrogate keys
- Data lineage
- SQL validation
- Python automation
- Git and GitHub workflow

---

## 2. Technology Stack

| Technology | Purpose |
|---|---|
| Python 3.11 | Automation and source acquisition |
| MySQL 26.7 | Data warehouse database |
| SQL | DDL, ingestion, transformation, validation |
| Pandas | Python-based data processing where required |
| python-dotenv | Environment configuration |
| mysql-connector-python | Python-MySQL connectivity |
| Git | Version control |
| GitHub | Repository and collaboration workflow |

The current dataset is small enough that Python and MySQL are appropriate. Distributed processing with Spark is not required for this project.

---

## 3. Source Data

The project uses two source systems.

```text
DATA SOURCES/
├── source_crm/
│   ├── cust_info.csv
│   ├── prd_info.csv
│   └── sales_details.csv
│
└── source_erp/
    ├── CUST_AZ12.csv
    ├── LOC_A101.csv
    └── PX_CAT_G1V2.csv
```

### CRM

CRM provides:

- Customer information
- Product information
- Sales transactions

### ERP

ERP provides:

- Additional customer information
- Customer location information
- Product category information

---

![alt text](<datawarehouse-etl (3).png>)


## 4. Source Data Inventory

| Source File | Source System | Rows | Columns |
|---|---|---:|---:|
| `cust_info.csv` | CRM | 18,494 | 7 |
| `prd_info.csv` | CRM | 397 | 7 |
| `sales_details.csv` | CRM | 60,398 | 9 |
| `CUST_AZ12.csv` | ERP | 18,484 | 3 |
| `LOC_A101.csv` | ERP | 18,484 | 2 |
| `PX_CAT_G1V2.csv` | ERP | 37 | 4 |

Total source records inspected:

```text
116,294
```

Total source columns:

```text
32
```

---

## 5. Data Warehouse Architecture

The warehouse uses separate databases for each layer:

```text
MySQL Server
│
├── dw_bronze
│
├── dw_silver
│
└── dw_gold
```

### Bronze

Purpose:

- Preserve source-oriented data
- Maintain traceability
- Load source data with minimal transformation
- Provide a reliable starting point for downstream processing

### Silver

Purpose:

- Clean data
- Standardize values
- Correct data types
- Remove duplicates where defined
- Derive reusable attributes
- Integrate source-level information where appropriate

### Gold

Purpose:

- Represent business objects
- Provide analytical-friendly names
- Integrate CRM and ERP information
- Implement dimensions and facts
- Support analytical queries and reporting

---

## 6. Medallion Architecture

```text
                    ┌─────────────────────┐
                    │     Source Data     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Raw / Landing Data │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Bronze Layer      │
                    │ Source-oriented     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Silver Layer      │
                    │ Clean / Standardize │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Gold Layer       │
                    │ Business-oriented   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Analytics / BI      │
                    └─────────────────────┘
```

---

![alt text](<datawarehouse-etl (4).png>)

## 7. Project Structure

```text
Data-Warehouse-ETL-Pipeline/
│
├── data/
│   ├── raw/
│   │   ├── crm/
│   │   └── erp/
│   └── sample/
│
├── docs/
│   ├── architecture/
│   ├── data_dictionary/
│   ├── data_model/
│   ├── decisions/
│   ├── etl/
│   └── project_plan/
│
├── scripts/
│   ├── extract/
│   │   └── acquire_source_data.py
│   ├── load/
│   ├── transform/
│   ├── run_pipeline.py
│   └── setup_database.py
│
├── sql/
│   ├── bronze/
│   │   ├── loading/
│   │   ├── tables/
│   │   └── validations/
│   │
│   ├── silver/
│   │   ├── loading/
│   │   ├── transformations/
│   │   └── validations/
│   │
│   ├── gold/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   ├── views/
│   │   └── validations/
│   │
│   └── setup/
│       └── create_databases.sql
│
├── tests/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── .env.example
├── .gitignore
├── requirements.txt
└── README.md
```

---

## 8. Source Acquisition

Source files remain outside the Git repository.

The source root is configured through:

```env
SOURCE_DATA_PATH=<path-to-source-data>
```

The Python acquisition script discovers CSV files under:

```text
source_crm/
source_erp/
```

and copies them into:

```text
data/raw/crm/
data/raw/erp/
```

The source files are copied rather than moved.

Original filenames are preserved.

---

## 9. Bronze Layer

Bronze contains six source-oriented tables:

```text
dw_bronze.crm_cust_info
dw_bronze.crm_prd_info
dw_bronze.crm_sales_details

dw_bronze.erp_cust_az12
dw_bronze.erp_loc_a101
dw_bronze.erp_px_cat_g1v2
```

The Bronze layer follows the source structure closely.

The Bronze loading process uses MySQL `LOAD DATA LOCAL INFILE`.

The load strategy is a full load:

```text
TRUNCATE
   ↓
LOAD SOURCE DATA
   ↓
VALIDATE
```

The Bronze load preserves the source information without applying business transformations.

---

## 10. Silver Layer

Silver performs cleaning and standardization.

### Customer

Examples:

- Remove invalid NULL customer IDs
- Resolve duplicate customer records
- Keep the latest customer record
- Trim names and keys
- Standardize marital status
- Standardize gender

### Product

Examples:

- Derive `cat_id`
- Trim product values
- Handle missing product cost
- Standardize product line
- Correct product date ranges

### ERP Customer

Examples:

- Standardize customer IDs
- Validate birth dates
- Standardize gender

### ERP Location

Examples:

- Standardize customer IDs
- Standardize country values

### ERP Category

Examples:

- Trim category values
- Standardize missing values

Silver tables also include:

```text
dwh_create_date
```

to provide warehouse-load metadata.

---

## 11. Gold Layer

![alt text](<datawarehouse-etl (2).png>)



Gold is the final business-facing analytical layer.

It uses a star-schema design.

```text
                 dim_customer
                      |
                      | 1
                      |
                      | *
                  fact_sales
                      |
                      | *
                      |
                      | 1
                 dim_product
```

### Customer Dimension

```text
dw_gold.dim_customer
```

Combines:

```text
CRM Customer
+
ERP Customer
+
ERP Location
```

CRM is the master customer source.

CRM gender has priority, with ERP gender used as a fallback when CRM contains `Not Available`.

### Product Dimension

```text
dw_gold.dim_product
```

Combines:

```text
CRM Product
+
ERP Category
```

Only current products are exposed:

```sql
prd_end_dt IS NULL
```

### Sales Fact

```text
dw_gold.fact_sales
```

Combines Silver sales with the Gold dimensions.

The fact uses:

```text
customer_key
product_key
```

instead of directly exposing the source-system customer/product identifiers as its dimensional relationships.

Gold objects are implemented as MySQL views in the current project design.

---

## 12. Current Gold Validation State

Current validated dimensions:

```text
dim_customer = 18,484 rows
dim_product  = 295 rows
```

The source Silver product table contains 397 records, but Gold intentionally exposes only current products.

Current-product completeness validation:

```text
missing_current_products = 0
```

Customer and product surrogate-key uniqueness checks pass.

The current Silver sales table contains:

```text
0 rows
```

Therefore:

```text
fact_sales = 0 rows
```

This is a current pipeline-state limitation rather than a Gold view creation failure. Fact-level relationship and measure validation become meaningful once Silver sales data is populated.

---

## 13. Data Quality

Quality checks are maintained separately from transformation logic.

Examples:

- Row-count validation
- Duplicate detection
- NULL detection
- Business-key uniqueness
- Surrogate-key uniqueness
- Current-product completeness
- Fact-to-dimension connectivity
- Measure consistency

Validation files are stored under:

```text
sql/*/validations/
```

Tests are stored under:

```text
tests/
```

---

## 14. Configuration

Sensitive values are stored in `.env`.

Example configuration:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password
SOURCE_DATA_PATH=path_to_source_data
```

The real `.env` file is excluded from Git.

`.env.example` contains placeholders only.

---

## 15. Setup

### Create Virtual Environment

```powershell
python -m venv .venv
```

Activate:

```powershell
.\.venv\Scripts\Activate.ps1
```

### Install Dependencies

```powershell
pip install -r requirements.txt
```

### Initialize Databases

```powershell
python .\scripts\setup_database.py
```

This creates:

```text
dw_bronze
dw_silver
dw_gold
```

### Acquire Source Data

```powershell
python .\scripts\extract\acquire_source_data.py
```

### Execute Layer SQL

Run the SQL scripts from the project root using the MySQL client.

Example:

```sql
SOURCE sql/bronze/tables/create_bronze_tables.sql;
SOURCE sql/bronze/loading/load_bronze.sql;
```

Then execute the corresponding Silver and Gold scripts.

---

## 16. Git Workflow

The project uses a feature-branch workflow.

```text
main
  ↑
develop
  ↑
feature / issue branch
```

Typical workflow:

```text
GitHub Issue
     ↓
Create feature branch
     ↓
Implement
     ↓
Test
     ↓
Document
     ↓
Commit
     ↓
Push
     ↓
Pull Request
     ↓
Merge into develop
     ↓
Later release develop → main
```

Branch naming convention:

```text
<issue-number>-<short-description>
```

Examples:

```text
14-implement-configurable-source-acquisition-and-landing
16-design-bronze-layer-and-define-bronze-loading-strategy
18-coding-bronze-data-ingestion
20-implement-gold-layer
```

Commit convention:

```text
feat(...)
fix(...)
test(...)
docs(...)
refactor(...)
```

---

## 17. Project Documentation

The `docs/` directory contains design and engineering documentation covering:

- Architecture
- Data model
- Data dictionary
- ETL design
- Design decisions
- Project plan
- Data lineage
- Layer-specific decisions

The documentation is intended to explain not only **what** was implemented, but also **why** the implementation was designed that way.

---

## 18. Learning Objectives Demonstrated

This project demonstrates practical understanding of:

### Data Engineering

- Source analysis
- Data acquisition
- ETL
- Data ingestion
- Data transformation
- Data validation
- Data lineage

### SQL

- DDL
- DML
- CTEs
- Window functions
- `ROW_NUMBER()`
- `LEAD()`
- Joins
- Aggregations
- Validation queries
- Views
- `LOAD DATA LOCAL INFILE`

### Data Warehousing

- Bronze / Silver / Gold
- Dimensions
- Facts
- Star schema
- Business keys
- Surrogate keys
- Source-to-target mapping

### Engineering Practices

- Environment variables
- Python automation
- Modular project structure
- Git branching
- Pull requests
- Documentation
- Testing

---

![alt text](<etl (1).png>)


## 19. Project Status

| Area | Status |
|---|---|
| Repository setup | Complete |
| Python environment | Complete |
| MySQL environment | Complete |
| Database initialization | Complete |
| Source inspection | Complete |
| Source profiling | Complete |
| Source acquisition | Complete |
| Bronze design | Complete |
| Bronze ingestion | Complete |
| Bronze validation | Complete |
| Silver design | Complete |
| Silver transformations | Complete |
| Gold architecture | Complete |
| Gold views | Complete |
| Gold quality checks | Complete |
| Gold tests | Implemented |
| Sales fact validation with actual sales records | Complete |
| Final project documentation | Complete |
| Production orchestration | Out of scope |

---

## 20. Future Enhancements

Potential future improvements include:

- Pipeline orchestration
- Incremental loading
- Scheduling
- Automated data-quality reporting
- Persistent Gold dimension tables
- More robust surrogate-key management
- Unit/integration test automation
- Logging and monitoring
- Dockerization
- Cloud deployment
- Spark/PySpark implementation for larger datasets
- BI integration

These are outside the scope of the current implementation.

---

## 21. Final Architecture

![alt text](<etl (2).png>)


```text
                       SOURCE SYSTEMS
                              |
                 +------------+------------+
                 |                         |
                CRM                       ERP
                 |                         |
                 +------------+------------+
                              |
                              v
                    PYTHON SOURCE ACQUISITION
                              |
                              v
                         DATA/RAW
                              |
                              v
                    +------------------+
                    |   DW_BRONZE      |
                    | Source-oriented  |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    |   DW_SILVER      |
                    | Clean / Standard |
                    +--------+---------+
                             |
                             v
                    +------------------+
                    |    DW_GOLD       |
                    | Business Model   |
                    +--------+---------+
                             |
                 +-----------+-----------+
                 |                       |
                 v                       v
          dim_customer              dim_product
                 \                       /
                  \                     /
                   +------ fact_sales --+
                             |
                             v
                   ANALYTICS / REPORTING
```

---

## 22. Project Goal

The goal of this project is to demonstrate an end-to-end Data Engineering workflow in which raw source-system data is systematically converted into a structured analytical data warehouse.

The implementation emphasizes:

> **Understand the source → design the architecture → acquire the data → ingest → clean → transform → model → validate → document.**
