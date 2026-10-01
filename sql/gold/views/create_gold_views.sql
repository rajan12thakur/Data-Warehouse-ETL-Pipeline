/*
===============================================================================
Gold Layer: Create Business Views
===============================================================================
Script Purpose:
    This script creates the Gold-layer business views for the Data Warehouse.

    The Gold layer is the final business-facing layer of the warehouse.
    It integrates and enriches data from the Silver layer and presents it
    using a star-schema design for analytics and reporting.

Gold Objects:
    - dw_gold.dim_customer
    - dw_gold.dim_product
    - dw_gold.fact_sales

Design:
    - Gold objects are implemented as views.
    - Silver is the only source for Gold transformations.
    - Customer and Product are dimensions.
    - Sales is the fact.
    - Surrogate keys are generated for the dimensions.
    - Fact records use the dimension surrogate keys.
    - Source-system technical column names are replaced with
      business-friendly names.

Important:
    - This script does not modify Bronze or Silver data.
    - No physical Gold tables are created.
===============================================================================
*/


/*
===============================================================================
1. CUSTOMER DIMENSION
===============================================================================

Business Object:
    Customer

Source Systems:
    - CRM Customer
    - ERP Customer
    - ERP Location

Source Tables:
    - dw_silver.crm_cust_info
    - dw_silver.erp_cust_az12
    - dw_silver.erp_loc_a101

Business Rules:
    - CRM customer is the master customer source.
    - ERP customer provides additional customer information.
    - ERP location provides country information.
    - CRM gender has priority.
    - ERP gender is used as a fallback when CRM gender is
      "Not Available".
    - LEFT JOIN is used so that CRM customers are preserved
      even when ERP enrichment is missing.

Target:
    dw_gold.dim_customer
===============================================================================
*/

DROP VIEW IF EXISTS dw_gold.dim_customer;

CREATE VIEW dw_gold.dim_customer AS

SELECT
    /*
    ---------------------------------------------------------------------------
    Surrogate Key
    ---------------------------------------------------------------------------
    Generates a Gold-layer customer key.

    The current implementation uses ROW_NUMBER() because Gold objects
    are implemented as views.
    ---------------------------------------------------------------------------
    */
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    /*
    ---------------------------------------------------------------------------
    Customer Identifiers
    ---------------------------------------------------------------------------
    */
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,

    /*
    ---------------------------------------------------------------------------
    Customer Personal Information
    ---------------------------------------------------------------------------
    */
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,

    /*
    ---------------------------------------------------------------------------
    Customer Location
    ---------------------------------------------------------------------------
    Country comes from the ERP location source.
    ---------------------------------------------------------------------------
    */
    la.cntry AS country,

    /*
    ---------------------------------------------------------------------------
    Customer Attributes
    ---------------------------------------------------------------------------
    */
    ci.cst_marital_status AS marital_status,

    /*
    ---------------------------------------------------------------------------
    Gender Integration Rule

    CRM is the preferred source.

    If CRM contains a usable gender:
        use CRM gender.

    Otherwise:
        use ERP gender.

    If ERP also has no value:
        return "Not Available".
    ---------------------------------------------------------------------------
    */
    CASE
        WHEN ci.cst_gndr <> 'Not Available'
            THEN ci.cst_gndr
        ELSE COALESCE(
            ca.gen,
            'Not Available'
        )
    END AS gender,

    /*
    ---------------------------------------------------------------------------
    ERP Customer Enrichment
    ---------------------------------------------------------------------------
    */
    ca.bdate AS birth_date,

    /*
    ---------------------------------------------------------------------------
    CRM Customer Creation Date
    ---------------------------------------------------------------------------
    */
    ci.cst_create_date AS create_date

FROM dw_silver.crm_cust_info ci

/*
===============================================================================
ERP CUSTOMER ENRICHMENT
===============================================================================
CRM customer remains the master record.

Therefore LEFT JOIN is used.
===============================================================================
*/
LEFT JOIN dw_silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

/*
===============================================================================
ERP LOCATION ENRICHMENT
===============================================================================
Country information is obtained from ERP location.

Again, LEFT JOIN preserves the CRM customer if location information
does not exist.
===============================================================================
*/
LEFT JOIN dw_silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*
===============================================================================
2. PRODUCT DIMENSION
===============================================================================

Business Object:
    Product

Source Systems:
    - CRM Product
    - ERP Product Category

Source Tables:
    - dw_silver.crm_prd_info
    - dw_silver.erp_px_cat_g1v2

Business Rules:
    - CRM product is the master product source.
    - ERP category provides category enrichment.
    - Only current products are included.
    - A product is considered current when prd_end_dt IS NULL.

Target:
    dw_gold.dim_product
===============================================================================
*/

DROP VIEW IF EXISTS dw_gold.dim_product;

CREATE VIEW dw_gold.dim_product AS

SELECT

    /*
    ---------------------------------------------------------------------------
    Surrogate Product Key
    ---------------------------------------------------------------------------
    The ordering provides a deterministic ordering for the current
    view-based surrogate-key generation.
    ---------------------------------------------------------------------------
    */
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    /*
    ---------------------------------------------------------------------------
    Product Identifiers
    ---------------------------------------------------------------------------
    */
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,

    /*
    ---------------------------------------------------------------------------
    Product Information
    ---------------------------------------------------------------------------
    */
    pn.prd_nm AS product_name,

    /*
    ---------------------------------------------------------------------------
    Category Information
    ---------------------------------------------------------------------------
    */
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,

    /*
    ---------------------------------------------------------------------------
    Product Financial / Classification Information
    ---------------------------------------------------------------------------
    */
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,

    /*
    ---------------------------------------------------------------------------
    Product Start Date
    ---------------------------------------------------------------------------
    */
    pn.prd_start_dt AS start_date

FROM dw_silver.crm_prd_info pn

/*
===============================================================================
ERP CATEGORY ENRICHMENT
===============================================================================
CRM product is the master source.

ERP category information enriches the product.
===============================================================================
*/
LEFT JOIN dw_silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

/*
===============================================================================
CURRENT PRODUCT FILTER
===============================================================================
Only the currently active product version is exposed in Gold.

A NULL end date means there is no known end date for the current record.
===============================================================================
*/
WHERE pn.prd_end_dt IS NULL;


/*
===============================================================================
3. SALES FACT
===============================================================================

Business Object:
    Sales Transaction

Source:
    - CRM Sales

Dimension Lookups:
    - Gold Customer Dimension
    - Gold Product Dimension

Business Rules:
    - Sales represents transactional business activity.
    - Source customer identifier is converted into customer_key.
    - Source product identifier is converted into product_key.
    - Dimension lookups use LEFT JOIN.
    - Fact columns are organized as:
        1. Transaction identifier
        2. Dimension keys
        3. Dates
        4. Measures

Target:
    dw_gold.fact_sales
===============================================================================
*/

DROP VIEW IF EXISTS dw_gold.fact_sales;

CREATE VIEW dw_gold.fact_sales AS

SELECT

    /*
    ---------------------------------------------------------------------------
    Transaction Identifier
    ---------------------------------------------------------------------------
    */
    sd.sls_ord_num AS order_number,

    /*
    ---------------------------------------------------------------------------
    Product Dimension Key

    The source product number from Sales is used to find the corresponding
    Gold product dimension record.
    ---------------------------------------------------------------------------
    */
    pr.product_key AS product_key,

    /*
    ---------------------------------------------------------------------------
    Customer Dimension Key

    The source customer ID from Sales is used to find the corresponding
    Gold customer dimension record.
    ---------------------------------------------------------------------------
    */
    cu.customer_key AS customer_key,

    /*
    ---------------------------------------------------------------------------
    Transaction Dates
    ---------------------------------------------------------------------------
    */
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,

    /*
    ---------------------------------------------------------------------------
    Measures
    ---------------------------------------------------------------------------
    */
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM dw_silver.crm_sales_details sd

/*
===============================================================================
PRODUCT DIMENSION LOOKUP
===============================================================================

Sales contains:

    sls_prd_key

Gold Product contains:

    product_number

Therefore:

    sd.sls_prd_key = pr.product_number
===============================================================================
*/
LEFT JOIN dw_gold.dim_product pr
    ON sd.sls_prd_key = pr.product_number

/*
===============================================================================
CUSTOMER DIMENSION LOOKUP
===============================================================================

Sales contains:

    sls_cust_id

Gold Customer contains:

    customer_id

Therefore:

    sd.sls_cust_id = cu.customer_id
===============================================================================
*/
LEFT JOIN dw_gold.dim_customer cu
    ON sd.sls_cust_id = cu.customer_id;


/*
===============================================================================
END OF GOLD VIEW CREATION
===============================================================================
Gold objects created:

    dw_gold.dim_customer
    dw_gold.dim_product
    dw_gold.fact_sales

Next step:
    Execute Gold quality checks after verifying that all three views
    were created successfully.
===============================================================================
*/