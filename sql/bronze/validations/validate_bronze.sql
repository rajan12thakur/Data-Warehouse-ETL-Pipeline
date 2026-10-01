/*
===============================================================================
Bronze Layer: Validation Script
===============================================================================
Purpose:
    Validate that the Bronze tables contain data after the full load.

Validation checks:
    1. Row counts.
    2. Sample records.
    3. Basic source-to-Bronze completeness.

Important:
    Bronze validation is separate from the loading script.
===============================================================================
*/


/*
===============================================================================
1. ROW COUNTS
===============================================================================
*/

SELECT 'CRM - Customer' AS table_name,
       COUNT(*) AS row_count
FROM dw_bronze.crm_cust_info

UNION ALL

SELECT 'CRM - Product',
       COUNT(*)
FROM dw_bronze.crm_prd_info

UNION ALL

SELECT 'CRM - Sales',
       COUNT(*)
FROM dw_bronze.crm_sales_details

UNION ALL

SELECT 'ERP - Customer',
       COUNT(*)
FROM dw_bronze.erp_cust_az12

UNION ALL

SELECT 'ERP - Location',
       COUNT(*)
FROM dw_bronze.erp_loc_a101

UNION ALL

SELECT 'ERP - Product Category',
       COUNT(*)
FROM dw_bronze.erp_px_cat_g1v2;


/*
===============================================================================
2. CRM CUSTOMER SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.crm_cust_info
LIMIT 10;


/*
===============================================================================
3. CRM PRODUCT SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.crm_prd_info
LIMIT 10;


/*
===============================================================================
4. CRM SALES SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.crm_sales_details
LIMIT 10;


/*
===============================================================================
5. ERP CUSTOMER SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.erp_cust_az12
LIMIT 10;


/*
===============================================================================
6. ERP LOCATION SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.erp_loc_a101
LIMIT 10;


/*
===============================================================================
7. ERP PRODUCT CATEGORY SAMPLE
===============================================================================
*/

SELECT *
FROM dw_bronze.erp_px_cat_g1v2
LIMIT 10;


/*
===============================================================================
8. BRONZE TABLE STRUCTURES
===============================================================================
*/

DESCRIBE dw_bronze.crm_cust_info;

DESCRIBE dw_bronze.crm_prd_info;

DESCRIBE dw_bronze.crm_sales_details;

DESCRIBE dw_bronze.erp_cust_az12;

DESCRIBE dw_bronze.erp_loc_a101;

DESCRIBE dw_bronze.erp_px_cat_g1v2;