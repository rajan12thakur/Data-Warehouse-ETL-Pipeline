# Gold Layer Design Decisions

## Decision 1: Use a Star Schema

### Decision

The Gold layer uses a star-schema design.

### Reason

The business model contains descriptive entities and transactional activity.

Therefore:

```text
Dimensions
    |
    v
Fact
```

is appropriate for analytical use cases.

Dimensions:

```text
dim_customer
dim_product
```

Fact:

```text
fact_sales
```

## Decision 2: Gold Reads from Silver

### Decision

Gold transformations use Silver as their input layer.

### Reason

Silver already contains cleaned and standardized data.

This creates a clear layered lineage:

```text
Source
  ↓
Bronze
  ↓
Silver
  ↓
Gold
```

Gold should not bypass Silver and directly transform Bronze data.

## Decision 3: Gold Objects Are Views

### Decision

The initial Gold implementation uses MySQL views.

### Reason

The project follows a view-based Gold implementation.

Views:

```text
dw_gold.dim_customer
dw_gold.dim_product
dw_gold.fact_sales
```

This keeps Gold logic directly queryable and maintains a clear relationship with Silver.

## Decision 4: CRM Customer Is the Master

### Decision

CRM customer information is the master customer source.

### Reason

ERP customer and location data are treated as enrichment sources.

Therefore the customer model starts from:

```text
dw_silver.crm_cust_info
```

and uses `LEFT JOIN` for ERP enrichment.

## Decision 5: CRM Gender Has Priority

### Decision

CRM gender is preferred when it is available.

ERP gender is used as a fallback when CRM contains `Not Available`.

### Reason

The business rule gives the CRM customer source priority while still allowing ERP data to enrich incomplete customer information.

## Decision 6: Current Products Only

### Decision

The Gold product dimension represents current products.

### Rule

```sql
prd_end_dt IS NULL
```

### Reason

The initial analytical product dimension is intended to represent the current product catalog rather than historical product versions.

## Decision 7: Use Surrogate Keys in Gold

### Decision

Customer and Product dimensions expose surrogate keys:

```text
customer_key
product_key
```

### Reason

The fact table should reference dimensions through Gold keys rather than depending directly on source-system identifiers.

## Decision 8: Business-Friendly Names

### Decision

Gold exposes readable business names.

Examples:

```text
cst_firstname -> first_name
cst_gndr      -> gender
sls_ord_num   -> order_number
sls_sales     -> sales_amount
```

### Reason

Gold is the business-facing analytical layer.

Consumers should not need to understand CRM/ERP technical naming conventions.

## Decision 9: LEFT JOIN for Dimension Enrichment

### Decision

Customer and product enrichment uses `LEFT JOIN`.

### Reason

The primary business record should not disappear simply because enrichment data is missing.

Missing relationships are instead detected through validation.

## Decision 10: Fact Uses Dimension Surrogate Keys

### Decision

`fact_sales` exposes:

```text
customer_key
product_key
```

rather than only source identifiers.

### Reason

This establishes the intended star-schema relationships between the fact and its dimensions.

## Decision 11: Validate Before Completion

### Decision

Gold implementation is not considered complete merely because the views can be created.

Validation must confirm:

- dimension uniqueness
- surrogate-key uniqueness
- completeness
- dimension lookups
- fact-to-dimension relationships
- measure consistency

## Decision 12: Keep Gold Business-Oriented

### Decision

Gold should represent business objects rather than reproduce source-system structures.

### Reason

CRM and ERP are source-system models.

Gold is the analytical business model.

Therefore multiple source systems can contribute to one Gold business object.
