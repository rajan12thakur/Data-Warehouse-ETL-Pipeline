# Gold Layer Data Model

## 1. Model Type

The Gold layer uses a logical star-schema data model.

The model contains:

- one customer dimension
- one product dimension
- one sales fact

## 2. Logical Model

```text
                    dim_customer
                         |
                         | 1
                         |
                         | *
                    fact_sales
                         |
                         | *
                         |
                         | 1
                    dim_product
```

## 3. Customer Dimension

Object:

```text
dw_gold.dim_customer
```

Purpose:

Provides descriptive information about customers.

Columns:

| Column | Description |
|---|---|
| `customer_key` | Gold surrogate key |
| `customer_id` | CRM customer identifier |
| `customer_number` | CRM customer business number |
| `first_name` | Customer first name |
| `last_name` | Customer last name |
| `country` | Customer country |
| `marital_status` | Standardized marital status |
| `gender` | Customer gender |
| `birth_date` | Customer birth date from ERP |
| `create_date` | CRM customer creation date |

## 4. Product Dimension

Object:

```text
dw_gold.dim_product
```

Purpose:

Provides descriptive information about current products.

Columns:

| Column | Description |
|---|---|
| `product_key` | Gold surrogate key |
| `product_id` | CRM product identifier |
| `product_number` | CRM product business number |
| `product_name` | Product name |
| `category_id` | Derived category identifier |
| `category` | Product category |
| `subcategory` | Product subcategory |
| `maintenance` | Maintenance classification |
| `cost` | Product cost |
| `product_line` | Standardized product line |
| `start_date` | Product start date |

Only records where `prd_end_dt IS NULL` are represented as current products.

## 5. Sales Fact

Object:

```text
dw_gold.fact_sales
```

Purpose:

Represents sales transactions and their measurable values.

Columns:

| Column | Description |
|---|---|
| `order_number` | Sales order number |
| `product_key` | Surrogate key of the related product |
| `customer_key` | Surrogate key of the related customer |
| `order_date` | Order date |
| `shipping_date` | Shipping date |
| `due_date` | Due date |
| `sales_amount` | Sales amount |
| `quantity` | Quantity sold |
| `price` | Sales price |

## 6. Relationships

### Customer to Sales

One customer can have many sales transactions.

```text
dim_customer 1 ---- * fact_sales
```

Relationship:

```text
dim_customer.customer_key
        =
fact_sales.customer_key
```

### Product to Sales

One product can appear in many sales transactions.

```text
dim_product 1 ---- * fact_sales
```

Relationship:

```text
dim_product.product_key
        =
fact_sales.product_key
```

## 7. Business Keys vs Surrogate Keys

Customer:

```text
customer_id
customer_number
```

are source/business identifiers.

`customer_key` is the Gold surrogate key.

Product:

```text
product_id
product_number
```

are source/business identifiers.

`product_key` is the Gold surrogate key.

The fact uses the surrogate keys to connect transactions to dimensions.

## 8. Grain

### Customer Dimension

One row represents one customer business record after the Silver customer integration.

### Product Dimension

One row represents one current product.

### Sales Fact

One row represents one sales transaction record from the Silver sales source.

## 9. Logical Data Flow

```text
Silver Customer Sources
        |
        v
dim_customer
        |
        |
        +------------------+
                           |
                           v
                       fact_sales
                           ^
                           |
        +------------------+
        |
dim_product
        ^
        |
Silver Product Sources
```

## 10. Modeling Principle

The Gold layer is designed around business objects rather than around the physical structure of the source systems.

CRM and ERP structures are therefore integrated where they describe the same business entity.
