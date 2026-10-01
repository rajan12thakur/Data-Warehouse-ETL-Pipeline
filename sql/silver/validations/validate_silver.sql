/*
===============================================================================
Silver Layer: Validation Script
===============================================================================
Purpose:
    Validate completeness and basic data quality of the Silver layer.

Important:
    This script does not modify any data.
===============================================================================
*/


/*
===============================================================================
1. ROW COUNT VALIDATION
===============================================================================
*/

SELECT
    'crm_cust_info' AS table_name,
    COUNT(*) AS row_count
FROM dw_silver.crm_cust_info

UNION ALL

SELECT
    'crm_prd_info',
    COUNT(*)
FROM dw_silver.crm_prd_info

UNION ALL

SELECT
    'crm_sales_details',
    COUNT(*)
FROM dw_silver.crm_sales_details

UNION ALL

SELECT
    'erp_cust_az12',
    COUNT(*)
FROM dw_silver.erp_cust_az12

UNION ALL

SELECT
    'erp_loc_a101',
    COUNT(*)
FROM dw_silver.erp_loc_a101

UNION ALL

SELECT
    'erp_px_cat_g1v2',
    COUNT(*)
FROM dw_silver.erp_px_cat_g1v2;


/*
===============================================================================
2. CUSTOMER VALIDATION
===============================================================================
*/

SELECT
    'Customer NULL IDs' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_cust_info
WHERE cst_id IS NULL;


SELECT
    'Customer duplicate IDs' AS validation,
    COUNT(*) AS issue_count
FROM
(
    SELECT
        cst_id
    FROM dw_silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1
) AS duplicates;


SELECT
    'Customer whitespace issues' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname)
   OR cst_key <> TRIM(cst_key);


SELECT
    cst_gndr,
    COUNT(*) AS row_count
FROM dw_silver.crm_cust_info
GROUP BY cst_gndr;


SELECT
    cst_marital_status,
    COUNT(*) AS row_count
FROM dw_silver.crm_cust_info
GROUP BY cst_marital_status;


/*
===============================================================================
3. PRODUCT VALIDATION
===============================================================================
*/

SELECT
    'Product NULL IDs' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_prd_info
WHERE prd_id IS NULL;


SELECT
    'Product duplicate IDs' AS validation,
    COUNT(*) AS issue_count
FROM
(
    SELECT
        prd_id
    FROM dw_silver.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1
) AS duplicates;


SELECT
    'Product invalid date ranges' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_start_dt > prd_end_dt;


SELECT
    'Product NULL category IDs' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_prd_info
WHERE cat_id IS NULL
   OR TRIM(cat_id) = '';


/*
===============================================================================
4. SALES VALIDATION
===============================================================================
*/

SELECT
    'Sales NULL order dates' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_sales_details
WHERE sls_order_dt IS NULL;


SELECT
    'Sales invalid order/ship date sequence' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND sls_ship_dt IS NOT NULL
  AND sls_order_dt > sls_ship_dt;


SELECT
    'Sales invalid ship/due date sequence' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_sales_details
WHERE sls_ship_dt IS NOT NULL
  AND sls_due_dt IS NOT NULL
  AND sls_ship_dt > sls_due_dt;


SELECT
    'Sales calculation mismatches' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_sales_details
WHERE sls_sales IS NOT NULL
  AND sls_quantity IS NOT NULL
  AND sls_price IS NOT NULL
  AND sls_sales <> sls_quantity * sls_price;


/*
===============================================================================
5. ERP CUSTOMER VALIDATION
===============================================================================
*/

SELECT
    'ERP customer future birth dates' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.erp_cust_az12
WHERE bdate > CURRENT_DATE;


SELECT
    'ERP customer invalid gender values' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.erp_cust_az12
WHERE gen NOT IN
(
    'Male',
    'Female',
    'Not Available'
);


/*
===============================================================================
6. ERP LOCATION VALIDATION
===============================================================================
*/

SELECT
    'ERP location IDs containing hyphen' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.erp_loc_a101
WHERE cid LIKE '%-%';


/*
===============================================================================
7. WAREHOUSE METADATA VALIDATION
===============================================================================
*/

SELECT
    'Customer missing warehouse timestamp' AS validation,
    COUNT(*) AS issue_count
FROM dw_silver.crm_cust_info
WHERE dwh_create_date IS NULL

UNION ALL

SELECT
    'Product missing warehouse timestamp',
    COUNT(*)
FROM dw_silver.crm_prd_info
WHERE dwh_create_date IS NULL

UNION ALL

SELECT
    'Sales missing warehouse timestamp',
    COUNT(*)
FROM dw_silver.crm_sales_details
WHERE dwh_create_date IS NULL

UNION ALL

SELECT
    'ERP customer missing warehouse timestamp',
    COUNT(*)
FROM dw_silver.erp_cust_az12
WHERE dwh_create_date IS NULL

UNION ALL

SELECT
    'ERP location missing warehouse timestamp',
    COUNT(*)
FROM dw_silver.erp_loc_a101
WHERE dwh_create_date IS NULL

UNION ALL

SELECT
    'ERP category missing warehouse timestamp',
    COUNT(*)
FROM dw_silver.erp_px_cat_g1v2
WHERE dwh_create_date IS NULL;


/*
===============================================================================
8. SILVER SAMPLE DATA
===============================================================================
*/

SELECT *
FROM dw_silver.crm_cust_info
LIMIT 5;


SELECT *
FROM dw_silver.crm_prd_info
LIMIT 5;


SELECT *
FROM dw_silver.crm_sales_details
LIMIT 5;


SELECT *
FROM dw_silver.erp_cust_az12
LIMIT 5;


SELECT *
FROM dw_silver.erp_loc_a101
LIMIT 5;


SELECT *
FROM dw_silver.erp_px_cat_g1v2
LIMIT 5;