/*
===============================================================================
Bronze Layer: Full Load Script
===============================================================================
Purpose:
    Load all CRM and ERP CSV files from the raw data directory into the
    corresponding Bronze tables.

Loading Strategy:
    1. Truncate the existing Bronze table.
    2. Bulk load the complete CSV file.
    3. Repeat for all six source tables.

This is a FULL LOAD strategy.

Important:
    - No business transformations are performed.
    - Source column order is preserved.
    - CSV headers are skipped.
    - Comma is used as the field delimiter.
    - CSV values may optionally be enclosed by double quotes.
    - Empty source values are loaded as NULL where required.
===============================================================================
*/


/*
===============================================================================
CRM TABLES
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Loading CRM tables' AS message;
SELECT '============================================================' AS message;


/*
===============================================================================
CRM CUSTOMER
Source:
    data/raw/crm/cust_info.csv

Target:
    dw_bronze.crm_cust_info

Important:
    The source contains empty values in cst_id and cst_create_date.

    Therefore, those fields are first captured into user variables:
        @cst_id
        @cst_create_date

    NULLIF(..., '') converts an empty source value into NULL.
===============================================================================
*/

SELECT '>> Truncating dw_bronze.crm_cust_info' AS message;

TRUNCATE TABLE dw_bronze.crm_cust_info;

SELECT '>> Loading data into dw_bronze.crm_cust_info' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/cust_info.csv'
INTO TABLE dw_bronze.crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    @cst_create_date
)
SET
    cst_id = NULLIF(@cst_id, ''),
    cst_create_date = NULLIF(@cst_create_date, '');

SELECT '>> crm_cust_info load completed' AS message;


/*
===============================================================================
CRM PRODUCT
Source:
    data/raw/crm/prd_info.csv

Target:
    dw_bronze.crm_prd_info

Important:
    The source contains empty values in prd_cost and prd_end_dt.

    Therefore, those two fields are first captured into user variables:
        @prd_cost
        @prd_end_dt

    NULLIF(..., '') converts an empty source value into NULL.

    This prevents MySQL from attempting to convert:
        '' -> INT
        '' -> DATE

    and avoids the warnings observed during the initial load.
===============================================================================
*/

SELECT '>> Truncating dw_bronze.crm_prd_info' AS message;

TRUNCATE TABLE dw_bronze.crm_prd_info;

SELECT '>> Loading data into dw_bronze.crm_prd_info' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/prd_info.csv'
INTO TABLE dw_bronze.crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    prd_id,
    prd_key,
    prd_nm,
    @prd_cost,
    prd_line,
    prd_start_dt,
    @prd_end_dt
)
SET
    prd_cost = NULLIF(@prd_cost, ''),
    prd_end_dt = NULLIF(@prd_end_dt, '');

SELECT '>> crm_prd_info load completed' AS message;


/*
===============================================================================
CRM SALES
Source:
    data/raw/crm/sales_details.csv

Target:
    dw_bronze.crm_sales_details

Important:
    The source contains empty values in sls_sales and sls_price.

    Therefore, those two fields are first captured into user variables:
        @sls_sales
        @sls_price

    NULLIF(..., '') converts an empty source value into NULL.
===============================================================================
*/

SELECT '>> Truncating dw_bronze.crm_sales_details' AS message;

TRUNCATE TABLE dw_bronze.crm_sales_details;

SELECT '>> Loading data into dw_bronze.crm_sales_details' AS message;

LOAD DATA LOCAL INFILE 'data/raw/crm/sales_details.csv'
INTO TABLE dw_bronze.crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    @sls_sales,
    sls_quantity,
    @sls_price
)
SET
    sls_sales = NULLIF(@sls_sales, ''),
    sls_price = NULLIF(@sls_price, '');

SELECT '>> crm_sales_details load completed' AS message;


/*
===============================================================================
ERP TABLES
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Loading ERP tables' AS message;
SELECT '============================================================' AS message;


/*
===============================================================================
ERP CUSTOMER
Source:
    data/raw/erp/CUST_AZ12.csv

Target:
    dw_bronze.erp_cust_az12

Important:
    The source contains an empty value in gen.

    Therefore, gen is first captured into the user variable:
        @gen

    NULLIF(..., '') converts an empty source value into NULL.
===============================================================================
*/

SELECT '>> Truncating dw_bronze.erp_cust_az12' AS message;

TRUNCATE TABLE dw_bronze.erp_cust_az12;

SELECT '>> Loading data into dw_bronze.erp_cust_az12' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/CUST_AZ12.csv'
INTO TABLE dw_bronze.erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    cid,
    bdate,
    @gen
)
SET
    gen = NULLIF(@gen, '');

SELECT '>> erp_cust_az12 load completed' AS message;


/*
===============================================================================
ERP LOCATION
Source:
    data/raw/erp/LOC_A101.csv

Target:
    dw_bronze.erp_loc_a101
===============================================================================
*/

SELECT '>> Truncating dw_bronze.erp_loc_a101' AS message;

TRUNCATE TABLE dw_bronze.erp_loc_a101;

SELECT '>> Loading data into dw_bronze.erp_loc_a101' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/LOC_A101.csv'
INTO TABLE dw_bronze.erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT '>> erp_loc_a101 load completed' AS message;


/*
===============================================================================
ERP PRODUCT CATEGORY
Source:
    data/raw/erp/PX_CAT_G1V2.csv

Target:
    dw_bronze.erp_px_cat_g1v2
===============================================================================
*/

SELECT '>> Truncating dw_bronze.erp_px_cat_g1v2' AS message;

TRUNCATE TABLE dw_bronze.erp_px_cat_g1v2;

SELECT '>> Loading data into dw_bronze.erp_px_cat_g1v2' AS message;

LOAD DATA LOCAL INFILE 'data/raw/erp/PX_CAT_G1V2.csv'
INTO TABLE dw_bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT '>> erp_px_cat_g1v2 load completed' AS message;


/*
===============================================================================
COMPLETION MESSAGE
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Bronze layer full load completed' AS message;
SELECT '============================================================' AS message;