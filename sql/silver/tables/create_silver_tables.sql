/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates the six Silver-layer tables in the MySQL
    'dw_silver' database.

Silver Layer Responsibilities:
    - Clean Bronze data
    - Standardize inconsistent values
    - Handle data-quality issues
    - Derive required attributes
    - Convert source-specific data formats
    - Support CRM and ERP data integration
    - Add warehouse metadata

Important:
    This script defines table structures only.

    It does NOT:
        - load data
        - perform transformations
        - perform data-quality validation

    Bronze-to-Silver transformations are handled separately by the
    Silver loading/transformation script.

Development Strategy:
    Existing Silver tables are dropped and recreated so that the DDL
    structure can be redefined during development.

===============================================================================
*/


/*
===============================================================================
CRM CUSTOMER
===============================================================================
Source:
    dw_bronze.crm_cust_info

Purpose:
    Store cleaned and standardized CRM customer information.

Silver transformations:
    - duplicate customer handling
    - whitespace trimming
    - marital-status standardization
    - gender standardization
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.crm_cust_info;

CREATE TABLE dw_silver.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
CRM PRODUCT
===============================================================================
Source:
    dw_bronze.crm_prd_info

Purpose:
    Store cleaned, standardized and enriched CRM product information.

Silver transformations:
    - derive category ID from product key
    - product-key/category standardization
    - whitespace trimming
    - product-line standardization
    - handling missing product cost
    - product date-range correction
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.crm_prd_info;

CREATE TABLE dw_silver.crm_prd_info (
    prd_id              INT,
    cat_id              VARCHAR(50),
    prd_key             VARCHAR(50),
    prd_nm              VARCHAR(50),
    prd_cost            INT,
    prd_line            VARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
CRM SALES
===============================================================================
Source:
    dw_bronze.crm_sales_details

Purpose:
    Store cleaned and standardized CRM sales transaction information.

Silver transformations:
    - trim order and product keys
    - convert source integer dates to DATE
    - handle invalid date values
    - standardize price
    - correct inconsistent sales values
    - protect calculations from NULL and zero values
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.crm_sales_details;

CREATE TABLE dw_silver.crm_sales_details (
    sls_ord_num         VARCHAR(50),
    sls_prd_key         VARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        DATE,
    sls_ship_dt         DATE,
    sls_due_dt          DATE,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           INT,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
ERP CUSTOMER
===============================================================================
Source:
    dw_bronze.erp_cust_az12

Purpose:
    Store standardized ERP customer attributes.

Silver transformations:
    - remove ERP-specific customer ID prefix
    - standardize customer identifier
    - handle invalid birth dates
    - standardize gender
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.erp_cust_az12;

CREATE TABLE dw_silver.erp_cust_az12 (
    cid                 VARCHAR(50),
    bdate               DATE,
    gen                 VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
ERP LOCATION
===============================================================================
Source:
    dw_bronze.erp_loc_a101

Purpose:
    Store standardized ERP customer-location information.

Silver transformations:
    - remove separators from customer identifiers
    - standardize country values
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.erp_loc_a101;

CREATE TABLE dw_silver.erp_loc_a101 (
    cid                 VARCHAR(50),
    cntry               VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
ERP PRODUCT CATEGORY
===============================================================================
Source:
    dw_bronze.erp_px_cat_g1v2

Purpose:
    Store standardized ERP product-category information.

Silver transformations:
    - whitespace trimming
    - basic standardization
===============================================================================
*/

DROP TABLE IF EXISTS dw_silver.erp_px_cat_g1v2;

CREATE TABLE dw_silver.erp_px_cat_g1v2 (
    id                  VARCHAR(50),
    cat                 VARCHAR(50),
    subcat              VARCHAR(50),
    maintenance         VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);