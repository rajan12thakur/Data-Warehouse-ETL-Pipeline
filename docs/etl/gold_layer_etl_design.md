# Gold Layer ETL Design

## 1. Purpose

This document describes how Silver-layer data is transformed into the Gold business model.

Gold transformation follows:

```text
Analyze
   ↓
Build Business Objects
   ↓
Classify Dimensions / Facts
   ↓
Rename Columns
   ↓
Integrate Related Sources
   ↓
Generate Surrogate Keys
   ↓
Validate
   ↓
Document
```

## 2. Input Layer

Gold reads from Silver only.

Customer inputs:

```text
dw_silver.crm_cust_info
dw_silver.erp_cust_az12
dw_silver.erp_loc_a101
```

Product inputs:

```text
dw_silver.crm_prd_info
dw_silver.erp_px_cat_g1v2
```

Sales input:

```text
dw_silver.crm_sales_details
```

Gold dimensions are also used as lookup sources for the Sales fact.

## 3. Customer Transformation

### Inputs

```text
CRM Customer
ERP Customer
ERP Location
```

### Process

```text
crm_cust_info
      |
      +---- LEFT JOIN ---- erp_cust_az12
      |
      +---- LEFT JOIN ---- erp_loc_a101
      |
      v
dim_customer
```

### Join Rules

CRM customer:

```text
ci.cst_key
```

joins to ERP customer:

```text
ca.cid
```

CRM customer:

```text
ci.cst_key
```

joins to ERP location:

```text
la.cid
```

### Master Source

CRM is the master source.

This means CRM customers should remain in the Gold dimension even if ERP enrichment is missing.

Therefore:

```sql
LEFT JOIN
```

is used.

### Gender Rule

```text
CRM gender available
       |
       +--> use CRM
       |
       +--> Not Available
                |
                v
           use ERP gender
                |
                v
          fallback Not Available
```

### Surrogate Key

A Gold customer surrogate key is generated for the business object.

The current view-based implementation uses:

```sql
ROW_NUMBER() OVER (ORDER BY ci.cst_id)
```

## 4. Product Transformation

### Inputs

```text
CRM Product
ERP Category
```

### Process

```text
crm_prd_info
      |
      +---- LEFT JOIN ---- erp_px_cat_g1v2
      |
      v
dim_product
```

### Join Rule

CRM product category identifier:

```text
pn.cat_id
```

joins to ERP category:

```text
pc.id
```

### Current Product Rule

Only current products are included:

```sql
WHERE pn.prd_end_dt IS NULL
```

### Surrogate Key

The current implementation generates:

```sql
ROW_NUMBER() OVER (
    ORDER BY pn.prd_start_dt, pn.prd_key
)
```

## 5. Sales Transformation

### Input

```text
dw_silver.crm_sales_details
```

### Dimension Lookups

Sales looks up:

```text
product_key
customer_key
```

from the Gold dimensions.

Process:

```text
crm_sales_details
       |
       +----> dim_product
       |
       +----> dim_customer
       |
       v
   fact_sales
```

### Product Lookup

```text
sd.sls_prd_key
        =
pr.product_number
```

### Customer Lookup

```text
sd.sls_cust_id
        =
cu.customer_id
```

### Fact Output

The fact contains:

1. business transaction identifier
2. dimension surrogate keys
3. dates
4. measures

Ordering:

```text
Keys
↓
Dates
↓
Measures
```

## 6. Why LEFT JOIN Is Used

The Gold design uses `LEFT JOIN` when integrating master/enrichment data.

This avoids silently dropping the primary business record when an enrichment record is unavailable.

For example:

```text
CRM customer exists
ERP customer missing
        ↓
customer still appears in dim_customer
```

The missing enrichment can then be identified during validation.

## 7. Gold Views

The current implementation creates:

```text
dw_gold.dim_customer
dw_gold.dim_product
dw_gold.fact_sales
```

using MySQL views.

The views read from Silver and expose the business model.

## 8. Validation Strategy

Validation should cover:

### Dimensions

- row counts
- business-key uniqueness
- surrogate-key uniqueness
- null surrogate keys
- expected categorical values

### Product

- current product completeness
- product-key uniqueness
- category lookup completeness

### Fact

- fact row count
- missing customer keys
- missing product keys
- dimension connectivity
- sales arithmetic consistency

## 9. Data Lineage

```text
CRM Customer ──────┐
                   ├──> dim_customer ───┐
ERP Customer ──────┤                    |
                   │                    |
ERP Location ──────┘                    |
                                        ├──> fact_sales
CRM Sales ──────────────────────────────┤
                                        |
CRM Product ──────┐                     |
                  ├──> dim_product ─────┘
ERP Category ─────┘
```

## 10. Gold Layer Responsibility

Gold performs business-oriented integration and presentation.

It should not become a second Bronze or Silver layer.

Raw preservation and primary data-quality correction belong earlier in the pipeline.
