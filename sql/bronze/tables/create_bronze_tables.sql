/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates the six empty tables in the MySQL 'dw_bronze' database.

    Before writing this DDL, the incoming CRM and ERP CSV files were opened and
    inspected to understand their metadata, column names, observed values,
    data types, date formats, and source structure.

    The Bronze layer follows these principles:

        1. Source-oriented table names
        2. Source column names are preserved
        3. No business transformations
        4. No dimensional/business data model
        5. Full-load strategy will be used later
        6. This script only defines the table structure
        7. Data ingestion will be handled separately

    The six source files produce six Bronze tables:

        CRM
            cust_info.csv       -> crm_cust_info
            prd_info.csv        -> crm_prd_info
            sales_details.csv   -> crm_sales_details

        ERP
            CUST_AZ12.csv       -> erp_cust_az12
            LOC_A101.csv        -> erp_loc_a101
            PX_CAT_G1V2.csv     -> erp_px_cat_g1v2

    Running this script again drops and recreates the Bronze tables so that
    the DDL structure can be redefined during development.

    IMPORTANT:
        This script creates EMPTY tables.
        It does NOT load the CSV data.
===============================================================================
*/


-- ============================================================================
-- 1. CRM CUSTOMER INFORMATION
-- Source file: data/raw/crm/cust_info.csv
-- Bronze table: dw_bronze.crm_cust_info
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.crm_cust_info;

CREATE TABLE dw_bronze.crm_cust_info (

    /*
    Source column: cst_id

    Observed source values are integer-like customer identifiers,
    for example: 11000.

    INT is therefore used to represent the source value.
    The source column name is preserved for Bronze traceability.
    
    We do not automatically define this as PRIMARY KEY because Bronze
    should not introduce an unverified uniqueness rule.
    */
    cst_id INT,

    /*
    Source column: cst_key

    Observed values are alphanumeric identifiers, for example:
    AW00011000.

    VARCHAR is used because the value contains both letters and digits.
    VARCHAR(50) follows the source-schema design demonstrated by the
    speaker and provides sufficient space for the observed source key.
    */
    cst_key VARCHAR(50),

    /*
    Source column: cst_firstname

    Observed as descriptive text, for example: Jon.

    VARCHAR is therefore appropriate.
    The source column name is preserved exactly.
    */
    cst_firstname VARCHAR(50),

    /*
    Source column: cst_lastname

    Observed as descriptive text, for example: Yang.

    VARCHAR is used because the source contains textual values.
    */
    cst_lastname VARCHAR(50),

    /*
    Source column: cst_marital_status

    Observed as a short source/category value, for example: M.

    We preserve the source representation instead of transforming it.
    VARCHAR is therefore used.
    */
    cst_marital_status VARCHAR(50),

    /*
    Source column: cst_gndr

    Observed as a short categorical source value, for example: M.

    No standardization is performed in Bronze.
    The source value is stored as text.
    */
    cst_gndr VARCHAR(50),

    /*
    Source column: cst_create_date

    Observed in date format such as:
    2025-10-06

    The source represents a calendar date rather than a timestamp,
    so MySQL DATE is used instead of DATETIME.
    */
    cst_create_date DATE
);


-- ============================================================================
-- 2. CRM PRODUCT INFORMATION
-- Source file: data/raw/crm/prd_info.csv
-- Bronze table: dw_bronze.crm_prd_info
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.crm_prd_info;

CREATE TABLE dw_bronze.crm_prd_info (

    /*
    Source column: prd_id

    Observed as an integer-like product identifier, for example: 210.

    INT is used to represent the source value.
    */
    prd_id INT,

    /*
    Source column: prd_key

    Observed as an alphanumeric product key, for example:
    CO-RF-FR-R92B-58.

    VARCHAR is required because the value contains letters,
    numbers, and separators.
    */
    prd_key VARCHAR(50),

    /*
    Source column: prd_nm

    Observed as descriptive product text, for example:
    HL Road Frame - Black- 58.

    VARCHAR is used to preserve the source text.
    */
    prd_nm VARCHAR(50),

    /*
    Source column: prd_cost

    The inspected source contains numeric-looking product cost values,
    but empty values were also observed.

    We therefore preserve the source field as nullable.
    INT is used here following the observed/source design.
    
    If complete profiling later shows decimal values, the datatype should
    be revised to an appropriate DECIMAL definition.
    */
    prd_cost INT,

    /*
    Source column: prd_line

    Observed as a short categorical/source value, for example:
    R

    VARCHAR preserves the source representation, including any source
    formatting such as spaces.
    */
    prd_line VARCHAR(50),

    /*
    Source column: prd_start_dt

    Observed in date format such as:
    2003-07-01

    The source contains a date rather than a time-of-day value,
    therefore DATE is used.
    */
    prd_start_dt DATE,

    /*
    Source column: prd_end_dt

    The source contains date-like values and empty values were observed.

    DATE is used because the source represents a calendar date.
    NULL remains possible when the source value is empty.
    
    We do not replace an empty end date with an artificial business value
    such as 9999-12-31 because Bronze does not perform that transformation.
    */
    prd_end_dt DATE
);


-- ============================================================================
-- 3. CRM SALES DETAILS
-- Source file: data/raw/crm/sales_details.csv
-- Bronze table: dw_bronze.crm_sales_details
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.crm_sales_details;

CREATE TABLE dw_bronze.crm_sales_details (

    /*
    Source column: sls_ord_num

    Observed as an alphanumeric order identifier, for example:
    SO43697.

    VARCHAR is used because the value contains letters and numbers.
    */
    sls_ord_num VARCHAR(50),

    /*
    Source column: sls_prd_key

    Observed as an alphanumeric product key, for example:
    BK-R93R-62.

    VARCHAR preserves the source key exactly.
    */
    sls_prd_key VARCHAR(50),

    /*
    Source column: sls_cust_id

    Observed as an integer-like customer identifier, for example:
    21768.

    INT is therefore used.
    
    We do not create a foreign key here because Bronze is preserving
    source data rather than enforcing an integrated business model.
    */
    sls_cust_id INT,

    /*
    Source column: sls_order_dt

    Observed source representation:
    20101229

    IMPORTANT:
    The source represents the date as YYYYMMDD rather than YYYY-MM-DD.

    The Bronze definition therefore preserves the source representation
    as an integer-like value at this stage.

    Any date standardization/conversion belongs to a later transformation
    layer unless the ingestion design explicitly requires conversion.
    */
    sls_order_dt INT,

    /*
    Source column: sls_ship_dt

    Observed source representation:
    YYYYMMDD, for example 20110105.

    The source format is preserved in Bronze.
    */
    sls_ship_dt INT,

    /*
    Source column: sls_due_dt

    Observed source representation:
    YYYYMMDD, for example 20110110.

    The source format is preserved in Bronze.
    */
    sls_due_dt INT,

    /*
    Source column: sls_sales

    Observed as a numeric sales measure, for example: 3578.

    INT is used based on the observed/source design.
    
    Complete profiling should be used to confirm whether decimal values
    occur. If decimals are present, DECIMAL would be more appropriate.
    */
    sls_sales INT,

    /*
    Source column: sls_quantity

    Observed as an integer-like quantity, for example: 1.

    INT is appropriate for this source representation.
    */
    sls_quantity INT,

    /*
    Source column: sls_price

    Observed as a numeric price value, for example: 3578.

    INT follows the current source design.
    
    If complete profiling identifies decimal prices, this should be
    changed to an appropriate DECIMAL datatype.
    */
    sls_price INT
);


-- ============================================================================
-- 4. ERP LOCATION
-- Source file: data/raw/erp/LOC_A101.csv
-- Bronze table: dw_bronze.erp_loc_a101
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.erp_loc_a101;

CREATE TABLE dw_bronze.erp_loc_a101 (

    /*
    Source column: CID

    Observed as an alphanumeric customer identifier, for example:
    AW-00011000.

    VARCHAR is used because the source value contains letters,
    numbers, and separators.

    The column name is normalized to lowercase to follow our project's
    MySQL naming convention, while preserving the source meaning.
    */
    cid VARCHAR(50),

    /*
    Source column: CNTRY

    Observed as text, for example:
    Australia.

    VARCHAR preserves the source country value.
    We do not convert Australia into AU in Bronze.
    */
    cntry VARCHAR(50)
);


-- ============================================================================
-- 5. ERP CUSTOMER
-- Source file: data/raw/erp/CUST_AZ12.csv
-- Bronze table: dw_bronze.erp_cust_az12
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.erp_cust_az12;

CREATE TABLE dw_bronze.erp_cust_az12 (

    /*
    Source column: CID

    Observed as an alphanumeric customer identifier, for example:
    NASAW00011000.

    VARCHAR is used because the value contains letters and numbers.
    */
    cid VARCHAR(50),

    /*
    Source column: BDATE

    Observed in date format such as:
    1971-10-06.

    The source contains a calendar date, so DATE is used.
    */
    bdate DATE,

    /*
    Source column: GEN

    Observed as a text/category value, for example:
    Male.

    We preserve the source representation.
    We do not convert Male to M in Bronze.
    */
    gen VARCHAR(50)
);


-- ============================================================================
-- 6. ERP PRODUCT CATEGORY
-- Source file: data/raw/erp/PX_CAT_G1V2.csv
-- Bronze table: dw_bronze.erp_px_cat_g1v2
-- ============================================================================

DROP TABLE IF EXISTS dw_bronze.erp_px_cat_g1v2;

CREATE TABLE dw_bronze.erp_px_cat_g1v2 (

    /*
    Source column: ID

    Observed as an alphanumeric category identifier, for example:
    AC_BR.

    VARCHAR is therefore used.
    */
    id VARCHAR(50),

    /*
    Source column: CAT

    Observed as category text, for example:
    Accessories.

    VARCHAR preserves the source value.
    */
    cat VARCHAR(50),

    /*
    Source column: SUBCAT

    Observed as subcategory text, for example:
    Bike Racks.

    VARCHAR preserves the source value.
    */
    subcat VARCHAR(50),

    /*
    Source column: MAINTENANCE

    Observed as a categorical text value, for example:
    Yes.

    We preserve the source representation instead of converting
    Yes/No into 1/0 in the Bronze layer.
    */
    maintenance VARCHAR(50)
);


/*
===============================================================================
END OF BRONZE DDL
===============================================================================

After this script runs successfully:

    dw_bronze
    |
    +-- crm_cust_info
    +-- crm_prd_info
    +-- crm_sales_details
    +-- erp_loc_a101
    +-- erp_cust_az12
    +-- erp_px_cat_g1v2

The six tables should exist, but they should contain no source data yet.

The next step is Bronze Data Ingestion:

    data/raw/*.csv
            |
            v
       TRUNCATE TABLE
            |
            v
       LOAD / INSERT
            |
            v
       dw_bronze tables

So this script answers:

    "What should the Bronze tables look like?"

The next loading script will answer:

    "How do we put the source CSV data into those tables?"

===============================================================================
*/