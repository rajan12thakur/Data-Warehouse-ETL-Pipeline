# Silver Layer — Analysis, Design and Transformation Decisions

## 1. Purpose

The Silver layer is responsible for transforming the source-preserving
Bronze data into clean, standardized and usable data for downstream
Gold-layer modeling.

The Silver layer is not the final business-facing analytical model.

Its responsibilities are:

- data cleansing
- data standardization
- missing-value handling
- invalid-value handling
- duplicate handling
- datatype standardization
- derived columns
- data enrichment
- source-system integration preparation
- metadata/audit information
- data-quality validation

The Gold layer will later handle business-oriented modeling, business
logic, dimensions, facts and analytical structures.

---

# 2. Silver Layer Engineering Workflow

The Silver implementation follows this workflow:

1. Analyze Bronze data
2. Understand table relationships
3. Identify Bronze data-quality issues
4. Define transformation rules
5. Design Silver table structures
6. Create Silver tables
7. Transform Bronze data
8. Insert transformed data into Silver
9. Validate Silver data
10. Revisit transformations if validation fails
11. Document lineage and design decisions
12. Commit and version the implementation in Git

The validation stage is iterative.

If a quality issue is discovered after transformation:

    Validation
        ↓
    Issue discovered
        ↓
    Return to transformation logic
        ↓
    Fix transformation
        ↓
    Validate again

---

# 3. Bronze vs Silver Responsibility

## Bronze

Bronze preserves source-oriented data.

Responsibilities:

- ingest source data
- preserve source column names
- preserve source structure as much as practical
- maintain traceability
- avoid business transformations

## Silver

Silver improves the usability and quality of Bronze data.

Responsibilities:

- clean
- standardize
- validate
- derive
- enrich
- normalize
- prepare data for integration

## Gold

Gold will later provide:

- business-oriented data structures
- dimensions
- facts
- business rules
- analytical aggregations
- reporting-oriented structures

---

# 4. Silver Loading Strategy

The Silver layer uses a FULL LOAD strategy.

Each Silver table is refreshed using:

    TRUNCATE
        ↓
    INSERT transformed data from Bronze

This prevents repeated execution from creating duplicate Silver records.

The Silver layer does not use incremental loading in this phase of the
project.

---

# 5. Source Systems

The warehouse currently receives data from two source systems.

## CRM

CRM source files:

- cust_info.csv
- prd_info.csv
- sales_details.csv

## ERP

ERP source files:

- CUST_AZ12.csv
- LOC_A101.csv
- PX_CAT_G1V2.csv

---

# 6. Bronze → Silver Mapping

| Source System | Bronze Table | Silver Table |
|---|---|---|
| CRM | dw_bronze.crm_cust_info | dw_silver.crm_cust_info |
| CRM | dw_bronze.crm_prd_info | dw_silver.crm_prd_info |
| CRM | dw_bronze.crm_sales_details | dw_silver.crm_sales_details |
| ERP | dw_bronze.erp_cust_az12 | dw_silver.erp_cust_az12 |
| ERP | dw_bronze.erp_loc_a101 | dw_silver.erp_loc_a101 |
| ERP | dw_bronze.erp_px_cat_g1v2 | dw_silver.erp_px_cat_g1v2 |

The initial Silver model maintains a one-to-one table mapping with Bronze.

Silver is not yet converted into a dimensional model.

---

# 7. Source Integration Model

## Customer integration

CRM customer information contains:

- customer ID
- customer key
- customer attributes

ERP customer and ERP location use the customer key rather than the
CRM technical customer ID.

Therefore the customer integration uses the customer key.

Conceptually:

CRM customer
    |
    | customer key
    |
    +---- ERP customer
    |
    +---- ERP location

---

# 8. Product integration

CRM product information contains:

- product ID
- product key
- product attributes
- product history

The product key contains information that can be used to derive a
category identifier.

The derived category identifier can then be matched with the ERP
product-category table.

Conceptually:

CRM product
    |
    | derived category ID
    |
    +---- ERP product category

---

# 9. Sales integration

CRM sales contains:

- order number
- product key
- customer ID
- dates
- sales
- quantity
- price

Sales therefore connects customers and products.

Conceptually:

Customer
    |
    | customer ID
    |
Sales
    |
    | product key
    |
Product

---

# 10. Silver Metadata Columns

Silver tables contain a warehouse metadata column:

    dwh_create_date

This column does not originate from the source system.

It records when the warehouse inserted the Silver record.

Purpose:

- auditability
- troubleshooting
- load tracking
- lineage support
- identifying when data entered the warehouse

The column is generated automatically by the database.

---

# 11. Customer Transformation Design

Potential quality checks:

- NULL customer IDs
- duplicate customer IDs
- unwanted spaces
- inconsistent gender values
- inconsistent marital-status values

Transformation categories:

- deduplication
- trimming
- standardization
- missing-value handling

Duplicate handling must be based on an explicit rule.

Where multiple records represent the same customer, the selected
surviving record must be justified using available source information,
such as creation/update dates.

---

# 12. Product Transformation Design

Potential quality checks:

- duplicate product IDs
- NULL product IDs
- unwanted spaces
- missing product cost
- invalid product cost
- inconsistent product-line values
- invalid date ranges
- overlapping historical records

Potential transformations:

- derive category ID from product key
- standardize category identifier format
- handle missing cost according to agreed business rule
- standardize product-line values
- convert dates to DATE
- correct historical date ranges using the next product version

Historical records may require window functions such as:

    LEAD()

to determine the next product version.

---

# 13. Sales Transformation Design

Potential quality checks:

- unwanted spaces
- invalid customer references
- invalid product references
- invalid dates
- invalid date relationships
- NULL sales
- zero sales
- negative sales
- NULL price
- zero price
- negative price
- quantity validation
- sales calculation consistency

The expected relationship is:

    sales = quantity × price

Date relationships should also be checked:

    order date <= ship date <= due date

Sales date fields are represented in Bronze as source-oriented values
and are converted into proper DATE values in Silver.

---

# 14. ERP Customer Transformation Design

Potential quality checks:

- customer identifier format
- invalid birth dates
- future birth dates
- inconsistent gender values
- NULL/empty gender values

Potential transformations:

- normalize ERP customer identifiers
- remove known source-system prefixes when required for integration
- standardize gender values
- handle invalid dates according to the agreed rule

---

# 15. ERP Location Transformation Design

Potential quality checks:

- customer identifier format
- country consistency
- NULL country
- empty country
- unwanted spaces

Potential transformations:

- remove identifier separators where required for CRM integration
- standardize country values
- trim whitespace
- convert missing values to the agreed representation

---

# 16. ERP Product Category Transformation Design

Quality checks:

- identifier relationship with Silver product category ID
- unwanted spaces
- category values
- subcategory values
- maintenance values
- NULL values

If the source data already satisfies the quality rules, no unnecessary
transformation should be introduced.

The table should still be loaded into Silver.

---

# 17. Transformation Principles

Transformations must be evidence-driven.

Do not introduce transformations simply because a transformation is
technically possible.

The process is:

    Observed data issue
          ↓
    Understand the cause
          ↓
    Define engineering/business rule
          ↓
    Implement transformation
          ↓
    Validate transformed result

---

# 18. Business Rule Principle

A data engineer should not invent business meaning for ambiguous source
values.

For example, if a source contains coded values such as:

    M
    R
    S
    T

the meaning should be confirmed from source/business documentation or
domain experts before converting them to descriptive values.

Similarly, correcting financial or transactional values requires an
explicit business rule.

---

# 19. Validation Principles

Validation will include:

## Completeness

Check expected row counts.

## Uniqueness

Check keys for duplicates.

## Null checks

Check required fields for NULL values.

## Formatting

Check unwanted spaces and inconsistent formats.

## Standardization

Check distinct values after transformation.

## Referential integrity

Check that customer/product references can be resolved.

## Date validity

Check invalid dates and invalid date relationships.

## Business/data rules

Check relationships such as:

    sales = quantity × price

and:

    order date <= ship date <= due date

---

# 20. Data Flow

The overall flow is:

Source Systems
    ↓
Source Acquisition
    ↓
Raw / Landing
    ↓
dw_bronze
    ↓
Bronze Quality
    ↓
Silver Transformations
    ↓
dw_silver
    ↓
Silver Validation
    ↓
Gold

---

# 21. Lineage

A Silver record should be traceable through the pipeline:

Source file
    ↓
Raw / Landing
    ↓
Bronze table
    ↓
Silver transformation
    ↓
Silver table

This allows engineers to investigate where data originated and how it
was transformed.

---

# 22. Scope of This Issue

Included:

- Silver analysis
- Bronze quality analysis
- Silver design
- Silver DDL
- Bronze-to-Silver transformations
- Silver validation
- Silver documentation
- Git versioning

Not included:

- Gold dimensional modeling
- Gold facts
- Gold dimensions
- orchestration
- scheduling
- advanced logging framework
- stored procedures
- production scheduling
- incremental loading

Those will be considered separately after the end-to-end pipeline is
working.

---

# 23. Engineering Outcome

At the completion of this issue:

    Source
       ↓
    Raw
       ↓
    Bronze
       ↓
    Clean / Standardize / Transform
       ↓
    Silver
       ↓
    Validate

will be operational.

The project can then proceed to Gold-layer analysis and modeling.