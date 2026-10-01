# Gold Layer Architecture

## 1. Purpose

The Gold layer is the final business-facing layer of the Data Warehouse ETL Pipeline.

Its purpose is to transform integrated and standardized Silver-layer data into business-oriented analytical objects that can be consumed by reporting, analytics, and downstream applications.

The Gold layer follows a star-schema approach.

## 2. Position in the Architecture

```text
Source Systems / Source Files
            |
            v
        Raw / Landing
            |
            v
       Bronze Layer
   Source-oriented / Raw
            |
            v
        Silver Layer
 Cleaned / Standardized
            |
            v
         Gold Layer
 Business-oriented
            |
            v
 Analytics / Reporting
```

Gold must read from Silver rather than directly from Bronze.

## 3. Gold Objects

The Gold layer contains three business objects:

- `dw_gold.dim_customer`
- `dw_gold.dim_product`
- `dw_gold.fact_sales`

The dimensions provide descriptive context, while the fact represents transactional activity.

## 4. Star Schema

The Gold model follows a star schema:

```text
                  +------------------+
                  |   dim_customer   |
                  +------------------+
                           |
                           | 1
                           |
                           | *
                    +-------------+
                    |  fact_sales |
                    +-------------+
                           |
                           | *
                           |
                           | 1
                  +------------------+
                  |   dim_product    |
                  +------------------+
```

`fact_sales` connects to the customer and product dimensions through surrogate keys.

## 5. Customer Integration

The customer business object combines:

- CRM customer information
- ERP customer information
- ERP location information

Source objects:

```text
dw_silver.crm_cust_info
dw_silver.erp_cust_az12
dw_silver.erp_loc_a101
```

CRM is treated as the master customer source.

A `LEFT JOIN` is used so that CRM customers remain present even when matching ERP information is unavailable.

CRM gender has priority. ERP gender is used as a fallback when CRM gender is `Not Available`.

Target:

```text
dw_gold.dim_customer
```

## 6. Product Integration

The product business object combines:

- CRM product information
- ERP product-category information

Source objects:

```text
dw_silver.crm_prd_info
dw_silver.erp_px_cat_g1v2
```

Only current products are included. A current product is identified by:

```sql
prd_end_dt IS NULL
```

Target:

```text
dw_gold.dim_product
```

## 7. Sales Fact

Sales represents transactional business activity.

The fact combines:

```text
dw_silver.crm_sales_details
        |
        +----> dim_product
        |
        +----> dim_customer
        |
        v
    fact_sales
```

The source customer and product identifiers are translated into Gold surrogate keys.

Target:

```text
dw_gold.fact_sales
```

## 8. View-Based Gold Layer

Gold objects are implemented as MySQL views.

This means the Gold layer does not create separate physical tables for these business objects. The views query Silver data and expose the final business-facing structure.

Advantages for this project:

- clear business logic
- direct lineage to Silver
- no duplicate Gold storage
- easy inspection of transformations
- close alignment with the source design being implemented

## 9. Naming

Gold uses business-friendly names rather than source-system technical names.

Examples:

```text
cst_firstname  -> first_name
cst_lastname   -> last_name
cst_gndr       -> gender
sls_ord_num    -> order_number
sls_sales      -> sales_amount
```

The Gold naming convention is lowercase snake_case.

## 10. Data Lineage

```text
CRM customer --------------------+
                                  |
ERP customer --------------------+--> dim_customer
                                  |
ERP location --------------------+

CRM product ---------------------+
                                  +--> dim_product
ERP category --------------------+

CRM sales -----------------------+
                                  |
dim_customer --------------------+--> fact_sales
                                  |
dim_product ---------------------+
```

## 11. Architectural Boundary

Gold is responsible for:

- business integration
- business-friendly naming
- dimension/fact classification
- surrogate-key exposure
- analytical relationships
- business-oriented presentation

Gold is not responsible for:

- raw source acquisition
- source-system changes
- raw data preservation
- primary data cleaning
- source-file ingestion
- BI dashboard development

Those responsibilities belong to earlier layers or downstream consumers.

## 12. Expected Outcome

After implementation, analysts should be able to work with:

```text
dw_gold.dim_customer
dw_gold.dim_product
dw_gold.fact_sales
```

without needing to understand the original CRM and ERP source-system structures.
