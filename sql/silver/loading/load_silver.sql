/*
===============================================================================
Silver Layer: Full Load and Transformation Script
===============================================================================
Purpose:
    Transform and load data from the Bronze layer into the Silver layer.

Loading Strategy:
    1. Truncate the existing Silver table.
    2. Read data from Bronze.
    3. Apply cleaning, standardization, derivation and enrichment.
    4. Insert transformed data into Silver.
    5. Repeat for all six source tables.

Important:
    - Bronze data is never modified.
    - Silver does not read CSV files directly.
    - Silver reads from dw_bronze.
    - This is a FULL LOAD strategy.
===============================================================================
*/


/*
===============================================================================
CRM TABLES
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Loading CRM Silver tables' AS message;
SELECT '============================================================' AS message;


/*
===============================================================================
CRM CUSTOMER
===============================================================================

Transformations:
    - Remove records with NULL customer ID.
    - Deduplicate customers.
    - Keep the latest customer record.
    - Trim customer values.
    - Standardize marital status.
    - Standardize gender.
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.crm_cust_info' AS message;

TRUNCATE TABLE dw_silver.crm_cust_info;

SELECT '>> Transforming and loading dw_silver.crm_cust_info' AS message;

INSERT INTO dw_silver.crm_cust_info
(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date,
    dwh_create_date
)
WITH customer_ranked AS
(
    SELECT
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,

        ROW_NUMBER() OVER
        (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS row_num

    FROM dw_bronze.crm_cust_info

    WHERE cst_id IS NOT NULL
)
SELECT
    cst_id,

    TRIM(cst_key),

    TRIM(cst_firstname),

    TRIM(cst_lastname),

    CASE
        WHEN TRIM(cst_marital_status) = 'M'
            THEN 'Married'
        WHEN TRIM(cst_marital_status) = 'S'
            THEN 'Single'
        ELSE 'Not Available'
    END,

    CASE
        WHEN TRIM(cst_gndr) = 'M'
            THEN 'Male'
        WHEN TRIM(cst_gndr) = 'F'
            THEN 'Female'
        ELSE 'Not Available'
    END,

    cst_create_date,

    CURRENT_TIMESTAMP

FROM customer_ranked
WHERE row_num = 1;

SELECT '>> crm_cust_info Silver load completed' AS message;


/*
===============================================================================
CRM PRODUCT
===============================================================================

Transformations:
    - Trim product values.
    - Derive category ID from product key.
    - Standardize product line.
    - Handle missing product cost.
    - Calculate historical product end dates using LEAD().
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.crm_prd_info' AS message;

TRUNCATE TABLE dw_silver.crm_prd_info;

SELECT '>> Transforming and loading dw_silver.crm_prd_info' AS message;

INSERT INTO dw_silver.crm_prd_info
(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt,
    dwh_create_date
)
WITH product_prepared AS
(
    SELECT
        prd_id,

        REPLACE(
            SUBSTRING(TRIM(prd_key), 1, 5),
            '-',
            '_'
        ) AS cat_id,

        TRIM(prd_key) AS prd_key,

        TRIM(prd_nm) AS prd_nm,

        COALESCE(prd_cost, 0) AS prd_cost,

        TRIM(prd_line) AS prd_line,

        prd_start_dt,

        prd_end_dt

    FROM dw_bronze.crm_prd_info
),

product_dated AS
(
    SELECT
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,

        LEAD(prd_start_dt) OVER
        (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) AS next_start_dt

    FROM product_prepared
)

SELECT
    prd_id,

    cat_id,

    prd_key,

    prd_nm,

    prd_cost,

    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M'
            THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R'
            THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S'
            THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T'
            THEN 'Touring'
        WHEN prd_line IS NULL
            OR TRIM(prd_line) = ''
            THEN 'Not Available'
        ELSE TRIM(prd_line)
    END,

    prd_start_dt,

    CASE
        WHEN next_start_dt IS NOT NULL
            THEN DATE_SUB(next_start_dt, INTERVAL 1 DAY)
        ELSE NULL
    END,

    CURRENT_TIMESTAMP

FROM product_dated;

SELECT '>> crm_prd_info Silver load completed' AS message;


/*
===============================================================================
CRM SALES
===============================================================================

Transformations:
    - Trim product key.
    - Convert YYYYMMDD integer dates into DATE.
    - Standardize price.
    - Correct invalid sales using quantity * absolute price.
    - Protect calculations involving NULL/zero values.
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.crm_sales_details' AS message;

TRUNCATE TABLE dw_silver.crm_sales_details;

SELECT '>> Transforming and loading dw_silver.crm_sales_details' AS message;

INSERT INTO dw_silver.crm_sales_details
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price,
    dwh_create_date
)
SELECT
    TRIM(sls_ord_num),

    TRIM(sls_prd_key),

    sls_cust_id,

    CASE
        WHEN sls_order_dt IS NULL
             OR sls_order_dt = 0
            THEN NULL
        ELSE STR_TO_DATE(
            CAST(sls_order_dt AS CHAR),
            '%Y%m%d'
        )
    END,

    CASE
        WHEN sls_ship_dt IS NULL
             OR sls_ship_dt = 0
            THEN NULL
        ELSE STR_TO_DATE(
            CAST(sls_ship_dt AS CHAR),
            '%Y%m%d'
        )
    END,

    CASE
        WHEN sls_due_dt IS NULL
             OR sls_due_dt = 0
            THEN NULL
        ELSE STR_TO_DATE(
            CAST(sls_due_dt AS CHAR),
            '%Y%m%d'
        )
    END,

    CASE
        WHEN sls_sales IS NULL
             OR sls_sales <= 0
             OR sls_quantity IS NULL
             OR sls_quantity <= 0
             OR sls_price IS NULL
             OR sls_price = 0
             OR sls_sales <> sls_quantity * ABS(sls_price)
        THEN
            CASE
                WHEN sls_quantity > 0
                     AND sls_price IS NOT NULL
                     AND sls_price <> 0
                THEN sls_quantity * ABS(sls_price)
                ELSE NULL
            END
        ELSE sls_sales
    END,

    sls_quantity,

    CASE
        WHEN sls_price IS NULL
             OR sls_price = 0
        THEN
            CASE
                WHEN sls_quantity IS NOT NULL
                     AND sls_quantity <> 0
                     AND sls_sales IS NOT NULL
                THEN sls_sales / sls_quantity
                ELSE NULL
            END
        ELSE ABS(sls_price)
    END,

    CURRENT_TIMESTAMP

FROM dw_bronze.crm_sales_details;

SELECT '>> crm_sales_details Silver load completed' AS message;


/*
===============================================================================
ERP TABLES
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Loading ERP Silver tables' AS message;
SELECT '============================================================' AS message;


/*
===============================================================================
ERP CUSTOMER
===============================================================================

Transformations:
    - Remove NAS prefix from customer ID.
    - Validate birth dates.
    - Standardize gender.
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.erp_cust_az12' AS message;

TRUNCATE TABLE dw_silver.erp_cust_az12;

SELECT '>> Transforming and loading dw_silver.erp_cust_az12' AS message;

INSERT INTO dw_silver.erp_cust_az12
(
    cid,
    bdate,
    gen,
    dwh_create_date
)
SELECT

    CASE
        WHEN UPPER(TRIM(cid)) LIKE 'NAS%'
            THEN SUBSTRING(TRIM(cid), 4)
        ELSE TRIM(cid)
    END,

    CASE
        WHEN bdate > CURRENT_DATE
            THEN NULL
        ELSE bdate
    END,

    CASE
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
            THEN 'Male'

        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
            THEN 'Female'

        WHEN gen IS NULL
             OR TRIM(gen) = ''
            THEN 'Not Available'

        ELSE TRIM(gen)
    END,

    CURRENT_TIMESTAMP

FROM dw_bronze.erp_cust_az12;

SELECT '>> erp_cust_az12 Silver load completed' AS message;


/*
===============================================================================
ERP LOCATION
===============================================================================

Transformations:
    - Remove '-' from customer ID.
    - Standardize country values.
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.erp_loc_a101' AS message;

TRUNCATE TABLE dw_silver.erp_loc_a101;

SELECT '>> Transforming and loading dw_silver.erp_loc_a101' AS message;

INSERT INTO dw_silver.erp_loc_a101
(
    cid,
    cntry,
    dwh_create_date
)
SELECT

    REPLACE(
        TRIM(cid),
        '-',
        ''
    ),

    CASE
        WHEN UPPER(TRIM(cntry)) IN
             ('US', 'USA', 'UNITED STATES')
            THEN 'United States'

        WHEN UPPER(TRIM(cntry)) IN
             ('UK', 'UNITED KINGDOM')
            THEN 'United Kingdom'

        WHEN UPPER(TRIM(cntry)) IN
             ('DE', 'GERMANY')
            THEN 'Germany'

        WHEN UPPER(TRIM(cntry)) IN
             ('AU', 'AUSTRALIA')
            THEN 'Australia'

        WHEN UPPER(TRIM(cntry)) IN
             ('CA', 'CANADA')
            THEN 'Canada'

        WHEN UPPER(TRIM(cntry)) IN
             ('FR', 'FRANCE')
            THEN 'France'

        WHEN cntry IS NULL
             OR TRIM(cntry) = ''
            THEN 'Not Available'

        ELSE TRIM(cntry)
    END,

    CURRENT_TIMESTAMP

FROM dw_bronze.erp_loc_a101;

SELECT '>> erp_loc_a101 Silver load completed' AS message;


/*
===============================================================================
ERP PRODUCT CATEGORY
===============================================================================

The ERP category source is comparatively clean.

Transformations:
    - Trim values.
    - Handle empty values.
    - Add warehouse metadata.
===============================================================================
*/

SELECT '>> Truncating dw_silver.erp_px_cat_g1v2' AS message;

TRUNCATE TABLE dw_silver.erp_px_cat_g1v2;

SELECT '>> Transforming and loading dw_silver.erp_px_cat_g1v2' AS message;

INSERT INTO dw_silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintenance,
    dwh_create_date
)
SELECT

    TRIM(id),

    CASE
        WHEN cat IS NULL
             OR TRIM(cat) = ''
            THEN 'Not Available'
        ELSE TRIM(cat)
    END,

    CASE
        WHEN subcat IS NULL
             OR TRIM(subcat) = ''
            THEN 'Not Available'
        ELSE TRIM(subcat)
    END,

    CASE
        WHEN maintenance IS NULL
             OR TRIM(maintenance) = ''
            THEN 'Not Available'
        ELSE TRIM(maintenance)
    END,

    CURRENT_TIMESTAMP

FROM dw_bronze.erp_px_cat_g1v2;

SELECT '>> erp_px_cat_g1v2 Silver load completed' AS message;


/*
===============================================================================
COMPLETION
===============================================================================
*/

SELECT '============================================================' AS message;
SELECT 'Silver layer full load completed' AS message;
SELECT '============================================================' AS message;