/*
===============================================================================
Gold Layer: Quality Checks
===============================================================================
Script Purpose:
    This script validates the quality and integrity of the Gold-layer
    business views.

Gold Objects:
    - dw_gold.dim_customer
    - dw_gold.dim_product
    - dw_gold.fact_sales

Validation Areas:
    1. Row counts
    2. Dimension surrogate-key uniqueness
    3. Business-key uniqueness
    4. NULL surrogate keys
    5. Expected categorical values
    6. Current-product completeness
    7. Fact-to-dimension connectivity
    8. Missing dimension lookups
    9. Sales measure consistency

Important:
    These queries do not modify any data.

    The current Silver sales table contains 0 rows, so the Gold sales
    validation queries are expected to return zero records until Silver
    sales data is available.
===============================================================================
*/


/*
===============================================================================
1. CUSTOMER DIMENSION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
1.1 Customer Row Count
-------------------------------------------------------------------------------

Purpose:
    Determine how many customer records are exposed by the Gold dimension.

Expected:
    18,484 based on the current Silver customer data.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS customer_count
FROM dw_gold.dim_customer;


/*
-------------------------------------------------------------------------------
1.2 Duplicate Customer Surrogate Keys
-------------------------------------------------------------------------------

Purpose:
    Verify that each customer_key identifies only one Gold customer record.

Expected:
    0 rows.
-------------------------------------------------------------------------------
*/

SELECT
    customer_key,
    COUNT(*) AS record_count
FROM dw_gold.dim_customer
GROUP BY customer_key
HAVING COUNT(*) > 1;


/*
-------------------------------------------------------------------------------
1.3 Duplicate Customer Business IDs
-------------------------------------------------------------------------------

Purpose:
    Verify that customer_id is unique in the Gold customer dimension.

Expected:
    0 rows.
-------------------------------------------------------------------------------
*/

SELECT
    customer_id,
    COUNT(*) AS record_count
FROM dw_gold.dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;


/*
-------------------------------------------------------------------------------
1.4 NULL Customer Surrogate Keys
-------------------------------------------------------------------------------

Purpose:
    Verify that every customer receives a surrogate key.

Expected:
    0.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS null_customer_keys
FROM dw_gold.dim_customer
WHERE customer_key IS NULL;


/*
-------------------------------------------------------------------------------
1.5 Customer Gender Values
-------------------------------------------------------------------------------

Purpose:
    Inspect the standardized gender values exposed by Gold.

Expected values:
    - Male
    - Female
    - Not Available
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    gender
FROM dw_gold.dim_customer
ORDER BY gender;


/*
===============================================================================
2. PRODUCT DIMENSION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
2.1 Product Row Count
-------------------------------------------------------------------------------

Purpose:
    Determine how many current products are exposed by Gold.

Expected:
    397 based on the current Silver product data.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS product_count
FROM dw_gold.dim_product;


/*
-------------------------------------------------------------------------------
2.2 Duplicate Product Surrogate Keys
-------------------------------------------------------------------------------

Purpose:
    Verify that each product_key identifies only one product.

Expected:
    0 rows.
-------------------------------------------------------------------------------
*/

SELECT
    product_key,
    COUNT(*) AS record_count
FROM dw_gold.dim_product
GROUP BY product_key
HAVING COUNT(*) > 1;


/*
-------------------------------------------------------------------------------
2.3 Duplicate Product Business Numbers
-------------------------------------------------------------------------------

Purpose:
    Verify that product_number is unique in the current product dimension.

Expected:
    0 rows.
-------------------------------------------------------------------------------
*/

SELECT
    product_number,
    COUNT(*) AS record_count
FROM dw_gold.dim_product
GROUP BY product_number
HAVING COUNT(*) > 1;


/*
-------------------------------------------------------------------------------
2.4 NULL Product Surrogate Keys
-------------------------------------------------------------------------------

Purpose:
    Verify that every Gold product receives a surrogate key.

Expected:
    0.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS null_product_keys
FROM dw_gold.dim_product
WHERE product_key IS NULL;


/*
-------------------------------------------------------------------------------
2.5 Current Product Completeness
-------------------------------------------------------------------------------

Purpose:
    Verify that every current Silver product appears in the Gold product
    dimension.

Source definition of a current product:

    prd_end_dt IS NULL

Expected:
    0 missing products.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS missing_current_products
FROM dw_silver.crm_prd_info sp
LEFT JOIN dw_gold.dim_product gp
    ON sp.prd_key = gp.product_number
WHERE sp.prd_end_dt IS NULL
  AND gp.product_number IS NULL;


/*
===============================================================================
3. SALES FACT
===============================================================================
*/


/*
-------------------------------------------------------------------------------
3.1 Sales Fact Row Count
-------------------------------------------------------------------------------

Purpose:
    Determine how many sales transactions are currently available in Gold.

Current expected result:
    0

Reason:
    dw_silver.crm_sales_details currently contains 0 rows.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS sales_count
FROM dw_gold.fact_sales;


/*
-------------------------------------------------------------------------------
3.2 Missing Customer Dimension Keys
-------------------------------------------------------------------------------

Purpose:
    Identify Sales records that could not be matched to a customer dimension
    record.

Expected:
    0

Note:
    With the current Silver sales count of 0, this query will return 0.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS missing_customer_keys
FROM dw_gold.fact_sales
WHERE customer_key IS NULL;


/*
-------------------------------------------------------------------------------
3.3 Missing Product Dimension Keys
-------------------------------------------------------------------------------

Purpose:
    Identify Sales records that could not be matched to a product dimension
    record.

Expected:
    0

Note:
    With the current Silver sales count of 0, this query will return 0.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS missing_product_keys
FROM dw_gold.fact_sales
WHERE product_key IS NULL;


/*
===============================================================================
4. FACT-TO-DIMENSION CONNECTIVITY
===============================================================================
*/


/*
-------------------------------------------------------------------------------
4.1 Unmatched Customer Dimension Records
-------------------------------------------------------------------------------

Purpose:
    Verify that every non-null customer_key in the fact corresponds to
    an existing customer dimension record.

Expected:
    0
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS unmatched_customer_records
FROM dw_gold.fact_sales fs
LEFT JOIN dw_gold.dim_customer dc
    ON fs.customer_key = dc.customer_key
WHERE fs.customer_key IS NOT NULL
  AND dc.customer_key IS NULL;


/*
-------------------------------------------------------------------------------
4.2 Unmatched Product Dimension Records
-------------------------------------------------------------------------------

Purpose:
    Verify that every non-null product_key in the fact corresponds to
    an existing product dimension record.

Expected:
    0
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS unmatched_product_records
FROM dw_gold.fact_sales fs
LEFT JOIN dw_gold.dim_product dp
    ON fs.product_key = dp.product_key
WHERE fs.product_key IS NOT NULL
  AND dp.product_key IS NULL;


/*
===============================================================================
5. SALES MEASURE VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
5.1 Sales Calculation Consistency
-------------------------------------------------------------------------------

Business rule:

    sales_amount = quantity * price

Purpose:
    Identify transactions where the stored sales amount does not match
    quantity multiplied by price.

Expected:
    0 rows.

NULL values are excluded from this comparison because NULL represents
unknown/missing data rather than a numerical mismatch.
-------------------------------------------------------------------------------
*/

SELECT
    order_number,
    quantity,
    price,
    sales_amount
FROM dw_gold.fact_sales
WHERE sales_amount IS NOT NULL
  AND quantity IS NOT NULL
  AND price IS NOT NULL
  AND sales_amount <> quantity * price;


/*
===============================================================================
6. SAMPLE GOLD DATA
===============================================================================
*/


/*
-------------------------------------------------------------------------------
6.1 Customer Sample
-------------------------------------------------------------------------------
*/

SELECT *
FROM dw_gold.dim_customer
LIMIT 20;


/*
-------------------------------------------------------------------------------
6.2 Product Sample
-------------------------------------------------------------------------------
*/

SELECT *
FROM dw_gold.dim_product
LIMIT 20;


/*
-------------------------------------------------------------------------------
6.3 Sales Sample
-------------------------------------------------------------------------------
*/

SELECT *
FROM dw_gold.fact_sales
LIMIT 20;


/*
===============================================================================
END OF GOLD QUALITY CHECKS
===============================================================================

Interpretation:

    Customer:
        Validate row count, uniqueness, surrogate keys, and categorical values.

    Product:
        Validate row count, uniqueness, surrogate keys, and current-product
        completeness.

    Sales:
        Validate row count, dimension lookups, relationships, and measures.

Current Pipeline State:

    Silver sales currently contains 0 rows.
    Therefore Gold fact_sales is currently empty.

This is expected until Silver sales data is populated.
===============================================================================
*/