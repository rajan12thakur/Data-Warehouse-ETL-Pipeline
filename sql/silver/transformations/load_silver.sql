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
    - Silver reads from dw_bronze.
    - Silver does not read CSV files directly.
    - This is a FULL LOAD strategy.
===============================================================================
*/
 
 
SELECT 'SCRIPT VERSION: FINAL v4 - ARITHMETIC DATE CONVERSION' AS message;
SELECT '============================================================' AS message;
SELECT 'Loading CRM Silver tables' AS message;
SELECT '============================================================' AS message;
 
 
/*
===============================================================================
CRM CUSTOMER
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
CRM SALES DETAILS
 
DATE HANDLING
    Bronze stores sales dates as integers such as 20101229.
    Some records contain invalid values such as 32154.
 
    Direct text-to-date parsing is deliberately NOT used: MySQL can
    evaluate them on bad values and raise ERROR 1411, which aborts the whole
    INSERT (0 rows). Dates are built arithmetically instead, so a bad value
    can only ever produce NULL, never an error.
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
 
WITH sales_base AS
(
    SELECT
        TRIM(sls_ord_num)                    AS ord_num,
        TRIM(sls_prd_key)                    AS prd_key,
        sls_cust_id,
        CAST(sls_order_dt AS SIGNED)         AS od,
        CAST(sls_ship_dt  AS SIGNED)         AS sd,
        CAST(sls_due_dt   AS SIGNED)         AS dd,
        CAST(sls_sales    AS DECIMAL(18,4))  AS sales_raw,
        ABS(CAST(sls_quantity AS SIGNED))    AS qty,
        CAST(sls_price    AS DECIMAL(18,4))  AS price_raw
    FROM dw_bronze.crm_sales_details
),
 
sales_parts AS
(
    SELECT
        ord_num, prd_key, sls_cust_id,
        sales_raw, qty, price_raw,
 
        od, od DIV 10000 AS oy, (od MOD 10000) DIV 100 AS om, od MOD 100 AS odd,
        sd, sd DIV 10000 AS sy, (sd MOD 10000) DIV 100 AS sm, sd MOD 100 AS sdd,
        dd, dd DIV 10000 AS dy, (dd MOD 10000) DIV 100 AS dm, dd MOD 100 AS ddd
    FROM sales_base
),
 
sales_dates AS
(
    SELECT
        ord_num, prd_key, sls_cust_id, sales_raw, qty, price_raw,
 
        CASE
            WHEN od BETWEEN 10000101 AND 99991231
                 AND om BETWEEN 1 AND 12
                 AND odd BETWEEN 1 AND 31
                 AND odd <= DAY(LAST_DAY(MAKEDATE(oy, 1) + INTERVAL (om - 1) MONTH))
            THEN MAKEDATE(oy, 1) + INTERVAL (om - 1) MONTH + INTERVAL (odd - 1) DAY
            ELSE NULL
        END AS order_date,
 
        CASE
            WHEN sd BETWEEN 10000101 AND 99991231
                 AND sm BETWEEN 1 AND 12
                 AND sdd BETWEEN 1 AND 31
                 AND sdd <= DAY(LAST_DAY(MAKEDATE(sy, 1) + INTERVAL (sm - 1) MONTH))
            THEN MAKEDATE(sy, 1) + INTERVAL (sm - 1) MONTH + INTERVAL (sdd - 1) DAY
            ELSE NULL
        END AS ship_date,
 
        CASE
            WHEN dd BETWEEN 10000101 AND 99991231
                 AND dm BETWEEN 1 AND 12
                 AND ddd BETWEEN 1 AND 31
                 AND ddd <= DAY(LAST_DAY(MAKEDATE(dy, 1) + INTERVAL (dm - 1) MONTH))
            THEN MAKEDATE(dy, 1) + INTERVAL (dm - 1) MONTH + INTERVAL (ddd - 1) DAY
            ELSE NULL
        END AS due_date
    FROM sales_parts
),
 
sales_price_fixed AS
(
    SELECT
        *,
        CASE
            WHEN price_raw IS NULL OR price_raw = 0
            THEN
                CASE
                    WHEN qty > 0 AND sales_raw IS NOT NULL AND sales_raw <> 0
                    THEN ABS(sales_raw) / qty
                    ELSE NULL
                END
            ELSE ABS(price_raw)
        END AS price_final
    FROM sales_dates
)
 
SELECT
    ord_num,
    prd_key,
    sls_cust_id,
    order_date,
    ship_date,
    due_date,
 
    /*
    Business rule: Sales = Quantity x Price.
    If source sales is NULL, zero/negative, or inconsistent with
    quantity x price, recalculate it.
    */
    CASE
        WHEN sales_raw IS NULL
             OR sales_raw <= 0
             OR ROUND(sales_raw, 2) <> ROUND(qty * price_final, 2)
        THEN
            CASE
                WHEN qty > 0 AND price_final IS NOT NULL
                THEN qty * price_final
                ELSE NULL
            END
        ELSE sales_raw
    END AS sls_sales,
 
    qty,
    price_final,
    CURRENT_TIMESTAMP
 
FROM sales_price_fixed;
 
 
SELECT '>> crm_sales_details Silver load completed' AS message;
 
 
/*
===============================================================================
ERP SILVER TABLES
===============================================================================
*/
 
SELECT '============================================================' AS message;
SELECT 'Loading ERP Silver tables' AS message;
SELECT '============================================================' AS message;
 
 
/*
===============================================================================
ERP CUSTOMER
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
 
 
/*
===============================================================================
ROW COUNT CHECK (Bronze vs Silver)
===============================================================================
*/
 
SELECT 'crm_sales_details' AS table_name,
       (SELECT COUNT(*) FROM dw_bronze.crm_sales_details) AS bronze_rows,
       (SELECT COUNT(*) FROM dw_silver.crm_sales_details) AS silver_rows;