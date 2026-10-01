/*
===============================================================================
Gold Layer: Test Suite
===============================================================================
Script Purpose:
    This script performs structured tests against the Gold-layer business views.

Gold Objects:
    - dw_gold.dim_customer
    - dw_gold.dim_product
    - dw_gold.fact_sales

Testing Approach:
    Each test returns a clear PASS or FAIL result.

Important:
    - This script does not modify any data.
    - Customer and Product tests operate on currently available Gold data.
    - Sales fact tests are currently limited because the Silver sales table
      contains 0 rows.
    - Fact-level tests will become meaningful once Silver sales data is loaded.
===============================================================================
*/


/*
===============================================================================
TEST 1: CUSTOMER DIMENSION EXISTS
===============================================================================
Purpose:
    Verify that the customer dimension view exists.
===============================================================================
*/

SELECT
    'TEST 1 - Customer Dimension Exists' AS test_name,
    CASE
        WHEN COUNT(*) = 1
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'dw_gold'
  AND TABLE_NAME = 'dim_customer';


/*
===============================================================================
TEST 2: PRODUCT DIMENSION EXISTS
===============================================================================
Purpose:
    Verify that the product dimension view exists.
===============================================================================
*/

SELECT
    'TEST 2 - Product Dimension Exists' AS test_name,
    CASE
        WHEN COUNT(*) = 1
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'dw_gold'
  AND TABLE_NAME = 'dim_product';


/*
===============================================================================
TEST 3: SALES FACT EXISTS
===============================================================================
Purpose:
    Verify that the Sales fact view exists.
===============================================================================
*/

SELECT
    'TEST 3 - Sales Fact Exists' AS test_name,
    CASE
        WHEN COUNT(*) = 1
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'dw_gold'
  AND TABLE_NAME = 'fact_sales';


/*
===============================================================================
TEST 4: CUSTOMER SURROGATE KEYS ARE NOT NULL
===============================================================================
Purpose:
    Every customer record must have a generated customer_key.

Expected:
    0 NULL customer keys.
===============================================================================
*/

SELECT
    'TEST 4 - Customer Keys Not Null' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.dim_customer
WHERE customer_key IS NULL;


/*
===============================================================================
TEST 5: CUSTOMER SURROGATE KEYS ARE UNIQUE
===============================================================================
Purpose:
    Verify that customer_key identifies only one customer record.

Expected:
    0 duplicate customer keys.
===============================================================================
*/

SELECT
    'TEST 5 - Customer Keys Unique' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM (
    SELECT
        customer_key
    FROM dw_gold.dim_customer
    GROUP BY customer_key
    HAVING COUNT(*) > 1
) duplicate_customer_keys;


/*
===============================================================================
TEST 6: CUSTOMER BUSINESS IDs ARE UNIQUE
===============================================================================
Purpose:
    Verify that customer_id is unique in the Gold customer dimension.

Expected:
    0 duplicate customer IDs.
===============================================================================
*/

SELECT
    'TEST 6 - Customer IDs Unique' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM (
    SELECT
        customer_id
    FROM dw_gold.dim_customer
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) duplicate_customer_ids;


/*
===============================================================================
TEST 7: CUSTOMER GENDER VALUES ARE STANDARDIZED
===============================================================================
Purpose:
    Verify that Gold gender values belong to the approved set.

Expected values:
    - Male
    - Female
    - Not Available
===============================================================================
*/

SELECT
    'TEST 7 - Customer Gender Values' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.dim_customer
WHERE gender NOT IN (
    'Male',
    'Female',
    'Not Available'
)
OR gender IS NULL;


/*
===============================================================================
TEST 8: PRODUCT SURROGATE KEYS ARE NOT NULL
===============================================================================
Purpose:
    Every current product must have a product_key.

Expected:
    0 NULL product keys.
===============================================================================
*/

SELECT
    'TEST 8 - Product Keys Not Null' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.dim_product
WHERE product_key IS NULL;


/*
===============================================================================
TEST 9: PRODUCT SURROGATE KEYS ARE UNIQUE
===============================================================================
Purpose:
    Verify that product_key identifies only one product.

Expected:
    0 duplicate product keys.
===============================================================================
*/

SELECT
    'TEST 9 - Product Keys Unique' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM (
    SELECT
        product_key
    FROM dw_gold.dim_product
    GROUP BY product_key
    HAVING COUNT(*) > 1
) duplicate_product_keys;


/*
===============================================================================
TEST 10: PRODUCT BUSINESS NUMBERS ARE UNIQUE
===============================================================================
Purpose:
    Verify that product_number is unique in the current Gold product
    dimension.

Expected:
    0 duplicate product numbers.
===============================================================================
*/

SELECT
    'TEST 10 - Product Numbers Unique' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM (
    SELECT
        product_number
    FROM dw_gold.dim_product
    GROUP BY product_number
    HAVING COUNT(*) > 1
) duplicate_product_numbers;


/*
===============================================================================
TEST 11: GOLD CONTAINS ONLY CURRENT PRODUCTS
===============================================================================
Purpose:
    Verify that every Gold product corresponds to a current Silver product.

Current product definition:

    prd_end_dt IS NULL

Expected:
    0 Gold products without a current Silver source record.
===============================================================================
*/

SELECT
    'TEST 11 - Current Product Rule' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.dim_product gp
LEFT JOIN dw_silver.crm_prd_info sp
    ON gp.product_number = sp.prd_key
WHERE sp.prd_key IS NULL
   OR sp.prd_end_dt IS NOT NULL;


/*
===============================================================================
TEST 12: ALL CURRENT PRODUCTS ARE REPRESENTED
===============================================================================
Purpose:
    Verify that no current Silver products are missing from Gold.

Expected:
    0 missing products.
===============================================================================
*/

SELECT
    'TEST 12 - Current Products Complete' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_silver.crm_prd_info sp
LEFT JOIN dw_gold.dim_product gp
    ON sp.prd_key = gp.product_number
WHERE sp.prd_end_dt IS NULL
  AND gp.product_number IS NULL;


/*
===============================================================================
TEST 13: SALES FACT CUSTOMER KEYS ARE VALID
===============================================================================
Purpose:
    Verify that every non-null customer_key in the fact exists in the
    customer dimension.

Expected:
    0 invalid customer references.
===============================================================================
*/

SELECT
    'TEST 13 - Sales Customer Keys Valid' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.fact_sales fs
LEFT JOIN dw_gold.dim_customer dc
    ON fs.customer_key = dc.customer_key
WHERE fs.customer_key IS NOT NULL
  AND dc.customer_key IS NULL;


/*
===============================================================================
TEST 14: SALES FACT PRODUCT KEYS ARE VALID
===============================================================================
Purpose:
    Verify that every non-null product_key in the fact exists in the
    product dimension.

Expected:
    0 invalid product references.
===============================================================================
*/

SELECT
    'TEST 14 - Sales Product Keys Valid' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.fact_sales fs
LEFT JOIN dw_gold.dim_product dp
    ON fs.product_key = dp.product_key
WHERE fs.product_key IS NOT NULL
  AND dp.product_key IS NULL;


/*
===============================================================================
TEST 15: SALES AMOUNT CALCULATION
===============================================================================
Purpose:
    Verify the business rule:

        sales_amount = quantity * price

Expected:
    0 inconsistent records.
===============================================================================
*/

SELECT
    'TEST 15 - Sales Amount Consistency' AS test_name,
    CASE
        WHEN COUNT(*) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM dw_gold.fact_sales
WHERE sales_amount IS NOT NULL
  AND quantity IS NOT NULL
  AND price IS NOT NULL
  AND sales_amount <> quantity * price;


/*
===============================================================================
TEST 16: FACT ROW COUNT CONSISTENCY
===============================================================================
Purpose:
    Compare the Gold fact row count with its Silver source.

Because fact_sales is a view directly based on Silver sales records,
the counts should match.

Current expected result:
    0 = 0

This test becomes more meaningful when Silver sales contains data.
===============================================================================
*/

SELECT
    'TEST 16 - Fact Row Count Consistency' AS test_name,
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM dw_gold.fact_sales
        ) = (
            SELECT COUNT(*)
            FROM dw_silver.crm_sales_details
        )
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result;


/*
===============================================================================
TEST 17: GOLD FACT IS CURRENTLY EMPTY BECAUSE SILVER SALES IS EMPTY
===============================================================================
Purpose:
    Document the current pipeline state explicitly.

Expected:
    PASS while both counts are zero.

This is a state-validation test, not a permanent business requirement.
Once Silver sales is populated, this test will return FAIL and should then
be removed or replaced with an appropriate non-empty fact expectation.
===============================================================================
*/

SELECT
    'TEST 17 - Current Sales Pipeline State' AS test_name,
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM dw_silver.crm_sales_details
        ) = 0
        AND (
            SELECT COUNT(*)
            FROM dw_gold.fact_sales
        ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result;


/*
===============================================================================
TEST 18: GOLD DIMENSION COUNTS
===============================================================================
Purpose:
    Display the current Gold dimension counts for test evidence.

Expected:
    Customer = 18,484
    Product  = 295
===============================================================================
*/

SELECT
    'Customer Dimension' AS object_name,
    COUNT(*) AS row_count
FROM dw_gold.dim_customer

UNION ALL

SELECT
    'Product Dimension' AS object_name,
    COUNT(*) AS row_count
FROM dw_gold.dim_product;


/*
===============================================================================
END OF GOLD TEST SUITE
===============================================================================
*/