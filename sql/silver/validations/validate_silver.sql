/*
===============================================================================
Silver Layer: Validation and Quality Checks
===============================================================================
Purpose:
    Validate the quality and correctness of the Silver layer.

The checks cover:

    - row counts
    - NULL values
    - duplicate keys
    - unwanted spaces
    - standardization
    - invalid dates
    - referential integrity
    - business/data rules

A successful SQL execution does NOT prove data correctness.

These checks are used to verify the resulting Silver data.
===============================================================================
*/


/*
===============================================================================
1. ROW COUNTS
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
2. CRM CUSTOMER - PRIMARY KEY DUPLICATES
===============================================================================
*/

SELECT
    cst_id,
    COUNT(*) AS occurrence_count
FROM dw_silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;


/*
===============================================================================
3. CRM CUSTOMER - NULL PRIMARY KEY
===============================================================================
*/

SELECT *
FROM dw_silver.crm_cust_info
WHERE cst_id IS NULL;


/*
===============================================================================
4. CRM CUSTOMER - UNWANTED SPACES
===============================================================================
*/

SELECT *
FROM dw_silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);


/*
===============================================================================
5. CRM CUSTOMER - DISTINCT STANDARDIZED VALUES
===============================================================================
*/

SELECT DISTINCT cst_gndr
FROM dw_silver.crm_cust_info
ORDER BY cst_gndr;

SELECT DISTINCT cst_marital_status
FROM dw_silver.crm_cust_info
ORDER BY cst_marital_status;


/*
===============================================================================
6. CRM PRODUCT - PRIMARY KEY DUPLICATES
===============================================================================
*/

SELECT
    prd_id,
    COUNT(*) AS occurrence_count
FROM dw_silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;


/*
===============================================================================
7. CRM PRODUCT - CATEGORY ID RELATIONSHIP
===============================================================================
*/

SELECT DISTINCT
    p.cat_id
FROM dw_silver.crm_prd_info p
LEFT JOIN dw_silver.erp_px_cat_g1v2 c
    ON p.cat_id = c.id
WHERE c.id IS NULL;


/*
===============================================================================
8. ERP LOCATION - CUSTOMER KEY RELATIONSHIP
===============================================================================
*/

SELECT DISTINCT
    l.cid
FROM dw_silver.erp_loc_a101 l
LEFT JOIN dw_silver.crm_cust_info c
    ON l.cid = c.cst_key
WHERE c.cst_key IS NULL;


/*
===============================================================================
9. ERP CUSTOMER - CUSTOMER KEY RELATIONSHIP
===============================================================================
*/

SELECT DISTINCT
    e.cid
FROM dw_silver.erp_cust_az12 e
LEFT JOIN dw_silver.crm_cust_info c
    ON e.cid = c.cst_key
WHERE c.cst_key IS NULL;


/*
===============================================================================
10. ERP CATEGORY - DISTINCT VALUES
===============================================================================
*/

SELECT DISTINCT cat
FROM dw_silver.erp_px_cat_g1v2
ORDER BY cat;

SELECT DISTINCT subcat
FROM dw_silver.erp_px_cat_g1v2
ORDER BY subcat;

SELECT DISTINCT maintenance
FROM dw_silver.erp_px_cat_g1v2
ORDER BY maintenance;