# Gold Layer Data Dictionary

## 1. Purpose

This document defines the business-facing columns exposed by the Gold layer.

The Gold layer replaces source-system technical names with readable analytical names.

## 2. Customer Dimension

Object:

```text
dw_gold.dim_customer
```

| Gold Column | Source | Transformation | Business Meaning |
|---|---|---|---|
| `customer_key` | Generated | `ROW_NUMBER()` | Gold surrogate customer identifier |
| `customer_id` | `crm_cust_info.cst_id` | Direct mapping | CRM customer identifier |
| `customer_number` | `crm_cust_info.cst_key` | Direct mapping | Customer business number |
| `first_name` | `crm_cust_info.cst_firstname` | Direct mapping | Customer first name |
| `last_name` | `crm_cust_info.cst_lastname` | Direct mapping | Customer last name |
| `country` | `erp_loc_a101.cntry` | Customer lookup | Customer country |
| `marital_status` | `crm_cust_info.cst_marital_status` | Silver-standardized value | Customer marital status |
| `gender` | CRM + ERP | CRM priority, ERP fallback | Customer gender |
| `birth_date` | `erp_cust_az12.bdate` | Customer lookup | Customer birth date |
| `create_date` | `crm_cust_info.cst_create_date` | Direct mapping | Customer creation date |

## 3. Product Dimension

Object:

```text
dw_gold.dim_product
```

| Gold Column | Source | Transformation | Business Meaning |
|---|---|---|---|
| `product_key` | Generated | `ROW_NUMBER()` | Gold surrogate product identifier |
| `product_id` | `crm_prd_info.prd_id` | Direct mapping | CRM product identifier |
| `product_number` | `crm_prd_info.prd_key` | Direct mapping | Product business number |
| `product_name` | `crm_prd_info.prd_nm` | Silver-standardized value | Product name |
| `category_id` | `crm_prd_info.cat_id` | Derived in Silver | Product category identifier |
| `category` | `erp_px_cat_g1v2.cat` | Category lookup | Product category |
| `subcategory` | `erp_px_cat_g1v2.subcat` | Category lookup | Product subcategory |
| `maintenance` | `erp_px_cat_g1v2.maintenance` | Category lookup | Maintenance classification |
| `cost` | `crm_prd_info.prd_cost` | Silver-standardized value | Product cost |
| `product_line` | `crm_prd_info.prd_line` | Silver-standardized value | Product line |
| `start_date` | `crm_prd_info.prd_start_dt` | Direct mapping | Product start date |

## 4. Sales Fact

Object:

```text
dw_gold.fact_sales
```

| Gold Column | Source | Transformation | Business Meaning |
|---|---|---|---|
| `order_number` | `crm_sales_details.sls_ord_num` | Direct mapping | Sales order number |
| `product_key` | Product dimension | Dimension lookup | Gold product surrogate key |
| `customer_key` | Customer dimension | Dimension lookup | Gold customer surrogate key |
| `order_date` | `crm_sales_details.sls_order_dt` | Silver standardized date | Order date |
| `shipping_date` | `crm_sales_details.sls_ship_dt` | Silver standardized date | Shipping date |
| `due_date` | `crm_sales_details.sls_due_dt` | Silver standardized date | Due date |
| `sales_amount` | `crm_sales_details.sls_sales` | Silver-standardized value | Sales amount |
| `quantity` | `crm_sales_details.sls_quantity` | Direct mapping | Quantity sold |
| `price` | `crm_sales_details.sls_price` | Silver-standardized value | Sales price |

## 5. Gender Business Rule

CRM gender is the preferred source.

Rule:

```text
IF CRM gender is available
    use CRM gender
ELSE
    use ERP gender
```

If neither source provides a usable value:

```text
Not Available
```

## 6. Customer Master Rule

CRM customer data is the master customer source.

ERP customer and location data enrich the CRM customer record.

A `LEFT JOIN` preserves the CRM customer even if an ERP match is missing.

## 7. Product Current-State Rule

The Gold product dimension contains current products only.

Condition:

```sql
prd_end_dt IS NULL
```

Historical product records are not exposed in the current Gold product dimension.

## 8. Naming Convention

Gold columns use lowercase snake_case.

Examples:

```text
customer_key
customer_number
product_key
product_number
sales_amount
shipping_date
```

Technical source prefixes are removed where the business meaning is clear.
