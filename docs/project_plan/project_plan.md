# Data Warehouse ETL Pipeline — Project Plan

## 1. Project Objective

Build an end-to-end Data Warehouse ETL Pipeline using CRM and ERP source data.

The project will demonstrate a professional Data Engineering workflow from source-system analysis through analytical Gold-layer modeling.

The target architecture is:

```text
Source
  ↓
Raw / Landing
  ↓
Bronze
  ↓
Silver
  ↓
Gold
  ↓
Analytics
```

---

# 2. Project Scope

## In Scope

- Source-system analysis
- Source data profiling
- Source acquisition
- Raw/landing management
- MySQL warehouse setup
- Bronze ingestion
- Silver transformations
- Gold dimensional modeling
- Data quality checks
- SQL testing
- Data lineage
- Data dictionary
- Architecture documentation
- Git/GitHub workflow
- Python automation

## Out of Scope

- Power BI dashboard development
- Production cloud deployment
- Enterprise orchestration platform
- Real-time streaming
- Large-scale distributed processing
- Source-system modification
- Production infrastructure
- Full CI/CD deployment

---

# 3. Architecture Plan

```text
                   SOURCE SYSTEMS
                  /              \
                CRM              ERP
                 \                /
                  \              /
                   v            v
                  SOURCE ACQUISITION
                         |
                         v
                     RAW DATA
                         |
                         v
                    DW_BRONZE
                         |
                         v
                    DW_SILVER
                         |
                         v
                     DW_GOLD
                         |
                         v
                  ANALYTICS / BI
```

---

# 4. Technology Plan

| Technology | Planned Usage |
|---|---|
| Python | Automation and source acquisition |
| MySQL | Data warehouse |
| SQL | DDL, loading, transformation, validation |
| Pandas | Local tabular processing when appropriate |
| python-dotenv | Configuration |
| mysql-connector-python | Python database connectivity |
| Git | Version control |
| GitHub | Repository management |

---

# 5. Project Phases

## Phase 1 — Project Initialization

### Objective

Create the repository foundation and development environment.

### Tasks

- [x] Create GitHub repository
- [x] Initialize local repository
- [x] Create `main`
- [x] Create `develop`
- [x] Create feature-branch workflow
- [x] Create `.gitignore`
- [x] Create `.env.example`
- [x] Create `requirements.txt`
- [x] Create Python virtual environment
- [x] Install dependencies
- [x] Document setup

### Deliverables

```text
.gitignore
.env.example
requirements.txt
project structure
development environment
```

---

# 6. Phase 2 — Warehouse Foundation

## Objective

Create the MySQL database foundation.

### Tasks

- [x] Define database naming convention
- [x] Create `dw_bronze`
- [x] Create `dw_silver`
- [x] Create `dw_gold`
- [x] Create database initialization SQL
- [x] Create Python database setup script
- [x] Verify database creation
- [x] Document the foundation

### Databases

```text
dw_bronze
dw_silver
dw_gold
```

---

# 7. Phase 3 — Source Analysis

## Objective

Understand the source systems before implementing ingestion.

The Data Engineer should first understand:

- Who owns the source?
- What does the source represent?
- What does each file/table represent?
- What are the keys?
- What are the relationships?
- What is the update frequency?
- What is the historical scope?
- What is the expected volume?
- How are changes identified?
- What are the data-quality issues?
- How is the source accessed?

### Tasks

- [x] Identify CRM source files
- [x] Identify ERP source files
- [x] Inventory files
- [x] Inspect columns
- [x] Inspect data types
- [x] Inspect row counts
- [x] Profile nulls
- [x] Profile duplicates
- [x] Identify relationships
- [x] Document source questions
- [x] Document source analysis

---

# 8. Phase 4 — Source Acquisition Design

## Objective

Design how external source files enter the project.

### Architecture

```text
External Source
      |
      v
Python Acquisition
      |
      v
data/raw/
      |
      v
Bronze
```

### Decisions

- Source files remain outside Git
- Source root is configured through `.env`
- Python discovers CSV files
- Source files are copied
- Original filenames are preserved
- CRM and ERP are stored separately
- Raw files are not transformed during acquisition

### Tasks

- [x] Define `SOURCE_DATA_PATH`
- [x] Design raw directory structure
- [x] Define acquisition rules
- [x] Implement acquisition script
- [x] Test acquisition
- [x] Verify copied files
- [x] Document acquisition

---

# 9. Phase 5 — Bronze Layer

## Objective

Load source-oriented data into the Bronze database with minimal transformation.

### Bronze Tables

```text
dw_bronze.crm_cust_info
dw_bronze.crm_prd_info
dw_bronze.crm_sales_details

dw_bronze.erp_cust_az12
dw_bronze.erp_loc_a101
dw_bronze.erp_px_cat_g1v2
```

### Tasks

- [x] Profile source metadata
- [x] Design Bronze DDL
- [x] Create Bronze tables
- [x] Configure local file loading
- [x] Implement Bronze loading
- [x] Handle empty source values safely
- [x] Validate row counts
- [x] Validate load warnings
- [x] Document Bronze ingestion

### Bronze Strategy

```text
TRUNCATE
   ↓
LOAD DATA
   ↓
VALIDATE
```

---

# 10. Phase 6 — Silver Layer

## Objective

Clean, standardize, enrich, and integrate data for downstream analytical modeling.

### Customer

Tasks:

- [x] Analyze duplicates
- [x] Analyze NULL IDs
- [x] Select latest duplicate record
- [x] Trim strings
- [x] Standardize gender
- [x] Standardize marital status
- [x] Add warehouse metadata

### Product

Tasks:

- [x] Derive category ID
- [x] Trim attributes
- [x] Handle missing cost
- [x] Standardize product line
- [x] Correct product date ranges
- [x] Add warehouse metadata

### Sales

Tasks:

- [x] Analyze source sales fields
- [x] Define date conversion
- [x] Validate order/ship/due dates
- [x] Validate sales measures
- [ ] Complete Silver sales population
- [ ] Complete fact-level downstream validation

### ERP Customer

Tasks:

- [x] Standardize customer IDs
- [x] Validate birth dates
- [x] Standardize gender

### ERP Location

Tasks:

- [x] Standardize customer IDs
- [x] Standardize country values

### ERP Category

Tasks:

- [x] Trim values
- [x] Standardize missing values

---

# 11. Phase 7 — Gold Architecture

## Objective

Create a business-oriented analytical model.

### Business Objects

```text
dim_customer
dim_product
fact_sales
```

### Model

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

### Tasks

- [x] Define Gold architecture
- [x] Define star schema
- [x] Classify dimensions and facts
- [x] Define business objects
- [x] Define Gold naming convention
- [x] Define business rules
- [x] Define data lineage
- [x] Document design decisions

---

# 12. Phase 8 — Gold Implementation

## Customer Dimension

Source:

```text
dw_silver.crm_cust_info
dw_silver.erp_cust_az12
dw_silver.erp_loc_a101
```

Tasks:

- [x] Create customer view
- [x] Integrate ERP customer
- [x] Integrate ERP location
- [x] Apply CRM gender priority
- [x] Generate customer surrogate key
- [x] Apply business-friendly names

## Product Dimension

Source:

```text
dw_silver.crm_prd_info
dw_silver.erp_px_cat_g1v2
```

Tasks:

- [x] Create product view
- [x] Integrate ERP category
- [x] Filter current products
- [x] Generate product surrogate key
- [x] Apply business-friendly names

## Sales Fact

Source:

```text
dw_silver.crm_sales_details
```

Tasks:

- [x] Create fact view
- [x] Lookup customer surrogate key
- [x] Lookup product surrogate key
- [x] Organize keys/dates/measures
- [x] Apply business-friendly names
- [ ] Validate using populated Silver sales records

---

# 13. Phase 9 — Gold Validation

## Customer Tests

- [x] Customer row count
- [x] Customer key uniqueness
- [x] Customer ID uniqueness
- [x] NULL customer keys
- [x] Gender values

## Product Tests

- [x] Product row count
- [x] Product key uniqueness
- [x] Product number uniqueness
- [x] NULL product keys
- [x] Current product completeness

## Sales Tests

- [x] Fact row count
- [x] Customer key validation
- [x] Product key validation
- [x] Fact-to-dimension connectivity
- [x] Sales calculation validation
- [ ] Re-run meaningful fact tests after Silver sales is populated

---

# 14. Phase 10 — Documentation

## Architecture

```text
docs/architecture/
```

Document:

- Overall architecture
- Bronze architecture
- Silver architecture
- Gold architecture
- Data flow

## Data Model

```text
docs/data_model/
```

Document:

- Logical model
- Relationships
- Dimensions
- Facts
- Grain
- Keys

## Data Dictionary

```text
docs/data_dictionary/
```

Document:

- Column definitions
- Source mappings
- Transformations
- Business meanings

## ETL

```text
docs/etl/
```

Document:

- Acquisition
- Loading
- Transformation
- Validation
- Lineage

## Decisions

```text
docs/decisions/
```

Document:

- Architectural decisions
- Modeling decisions
- Naming decisions
- Loading strategy
- Business rules

---

# 15. Git/GitHub Plan

## Branch Workflow

```text
main
  ↑
develop
  ↑
issue branch
```

## Standard Workflow

```text
Create Issue
     ↓
Create Branch
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
Create PR
     ↓
Review
     ↓
Merge → develop
```

## Branch Naming

```text
<issue-number>-<short-description>
```

Examples:

```text
1-initialize-data-warehouse-etl-pipeline-project
5-source-data-inspection-profiling
6-initialize-warehouse-foundation
8-automate-warehouse-initialization-with-python
10-analyze-crm-and-erp-source-systems
12-design-configurable-source-acquisition-and-landing-strategy
14-implement-configurable-source-acquisition-and-landing
16-design-bronze-layer-and-define-bronze-loading-strategy
18-coding-bronze-data-ingestion
20-implement-gold-layer
```

## Commit Convention

```text
feat(...)
fix(...)
test(...)
docs(...)
refactor(...)
```

---

# 16. Issue / Epic Plan

## Epic 1 — Project Foundation

- Issue 1 — Initialize Data Warehouse ETL Pipeline
- Issue 6 — Initialize Warehouse Foundation
- Issue 8 — Automate Warehouse Initialization

## Epic 2 — Source Understanding

- Issue 5 — Source Data Inspection and Profiling
- Issue 9 — Analyze CRM and ERP Source Systems

## Epic 3 — Source Acquisition

- Issue 12 — Design Configurable Source Acquisition and Landing
- Issue 14 — Implement Configurable Source Acquisition and Landing

## Epic 4 — Bronze

- Issue 16 — Design Bronze Layer and Define Bronze Loading Strategy
- Issue 18 — Coding Bronze Data Ingestion

## Epic 5 — Silver

- Silver design
- Silver transformation implementation
- Silver validation
- Silver documentation

## Epic 6 — Gold

- Issue 20 — Implement Gold Layer Business Model and Analytical Views
- Gold validation
- Gold testing
- Gold documentation

---

# 17. Naming Conventions

## Database

```text
dw_bronze
dw_silver
dw_gold
```

## Tables

Bronze/Silver:

```text
<source>_<entity>
```

Examples:

```text
crm_cust_info
erp_cust_az12
```

## Gold

```text
dim_<entity>
fact_<business_process>
```

Examples:

```text
dim_customer
dim_product
fact_sales
```

## Columns

Use lowercase snake_case:

```text
customer_id
customer_number
product_key
sales_amount
shipping_date
```

## Surrogate Keys

```text
<entity>_key
```

Examples:

```text
customer_key
product_key
```

---

# 18. Testing Strategy

Testing is performed at multiple levels.

## Source Level

- File existence
- File count
- Row counts
- Schema inspection

## Bronze

- Table existence
- Load row counts
- Warning checks
- Source-to-Bronze comparison

## Silver

- NULL checks
- Duplicate checks
- Standardization checks
- Date validation
- Relationship checks

## Gold

- Dimension uniqueness
- Surrogate-key validation
- Business-key validation
- Current-product completeness
- Fact-to-dimension connectivity
- Measure consistency

---

# 19. Data Lineage Plan

The project should be able to trace analytical data back to its origin.

Example:

```text
CRM cust_info.csv
      ↓
data/raw/crm/cust_info.csv
      ↓
dw_bronze.crm_cust_info
      ↓
dw_silver.crm_cust_info
      ↓
dw_gold.dim_customer
```

Product:

```text
CRM prd_info.csv
      ↓
dw_bronze.crm_prd_info
      ↓
dw_silver.crm_prd_info
      ↓
dw_gold.dim_product
```

Sales:

```text
CRM sales_details.csv
      ↓
dw_bronze.crm_sales_details
      ↓
dw_silver.crm_sales_details
      ↓
dw_gold.fact_sales
```

ERP sources enrich the relevant Gold business objects.

---

# 20. Project Completion Criteria

The project is considered functionally complete when:

- [x] Source systems are understood
- [x] Source data is profiled
- [x] Acquisition strategy is documented
- [x] Source data is acquired
- [x] Warehouse databases exist
- [x] Bronze tables exist
- [x] Bronze ingestion works
- [x] Bronze validation works
- [x] Silver tables exist
- [x] Silver transformations are documented
- [x] Gold architecture is documented
- [x] Gold dimensions are implemented
- [x] Gold fact is implemented
- [x] Gold validation scripts exist
- [x] Gold test script exists
- [x] Data model is documented
- [x] Data dictionary is documented
- [x] Data lineage is documented
- [ ] Silver sales contains usable records for complete fact-level testing
- [ ] Final project documentation is committed
- [ ] Final PR is merged into `develop`

---

# 21. Future Roadmap

After the current warehouse is stable, possible extensions are:

```text
Current Project
      |
      +--> Automated orchestration
      |
      +--> Incremental loading
      |
      +--> Logging
      |
      +--> Monitoring
      |
      +--> Automated testing
      |
      +--> Docker
      |
      +--> Cloud storage
      |
      +--> Spark / PySpark
      |
      +--> BI / Power BI
```

These extensions should be treated as separate phases rather than mixing production-scale concerns into the initial implementation.

---

# 22. Final Project Workflow

The complete engineering workflow is:

```text
1. Understand the business
          ↓
2. Understand source systems
          ↓
3. Profile source data
          ↓
4. Design architecture
          ↓
5. Design acquisition
          ↓
6. Acquire source data
          ↓
7. Build Bronze
          ↓
8. Validate Bronze
          ↓
9. Build Silver
          ↓
10. Validate Silver
          ↓
11. Design Gold
          ↓
12. Build Gold
          ↓
13. Validate Gold
          ↓
14. Test
          ↓
15. Document
          ↓
16. Git commit
          ↓
17. Pull Request
          ↓
18. Merge to develop
```

---

# 23. Key Engineering Principle

The project follows this principle throughout:

> **Do not start by writing transformation code. First understand the source, define the requirements, design the data flow, establish the business rules, and then implement and validate the pipeline.**

This makes the project represent a Data Engineering workflow rather than simply a collection of SQL scripts.
