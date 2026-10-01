# Issue #9 --- Analyze CRM and ERP Source Systems

**Project:** Data Warehouse ETL Pipeline\
**Issue:** #9\
**Type:** Source Analysis / Architecture Discovery / Documentation\
**Epic:** Bronze Layer & Source Ingestion\
**Status:** Completed

------------------------------------------------------------------------

## 1. Objective

The objective of this issue is to analyze the CRM and ERP source systems
before implementing source acquisition, ingestion, and Bronze-layer
loading.

The analysis establishes the information required to make engineering
decisions about:

-   source acquisition
-   extraction mechanisms
-   data scope
-   loading strategy
-   source-to-target mapping
-   Bronze table design
-   validation requirements
-   performance considerations
-   security and access
-   future Silver and Gold modeling

The reference Bronze-layer approach follows this sequence:

``` text
Analyze
   ↓
Code / Ingest
   ↓
Validate
   ↓
Document & Version
```

The source-analysis stage is completed before implementation begins.

------------------------------------------------------------------------

## 2. Source Analysis Principle

The purpose of source analysis is not simply to collect documentation.
The objective is to convert source-system knowledge into engineering
requirements.

``` text
Source-System Information
        ↓
Source Analysis
        ↓
Engineering Requirements
        ↓
Architecture Decisions
        ↓
Pipeline Components
        ↓
Implementation
```

For a real enterprise source, the Data Engineer would obtain this
information from source-system owners, developers, DBAs, business SMEs,
documentation, and other responsible teams.

For this portfolio project, the CRM and ERP systems are represented by
provided source files. Therefore, the analysis will be based on
observable files and available metadata. Information that cannot be
established will be explicitly marked as unknown rather than fabricated.

------------------------------------------------------------------------

# 3. Business Context & Ownership

## 3.1 Source System Identity

### Questions

-   What is the source system?
-   What business/domain area does it represent?
-   What major entities or datasets does it contain?

### Engineering relevance

The answers establish:

-   source-to-warehouse lineage
-   source grouping
-   naming conventions
-   documentation requirements
-   future Bronze table organization

Expected source grouping:

``` text
CRM
  ↓
CRM source datasets
  ↓
dw_bronze

ERP
  ↓
ERP source datasets
  ↓
dw_bronze
```

------------------------------------------------------------------------

## 3.2 Data Ownership

### Questions

-   Who owns the source system?
-   Who owns the data?
-   Which department or team is responsible?
-   Who should be contacted when the source changes?
-   Who is responsible for resolving source-data issues?

### Engineering relevance

Ownership information supports:

-   incident resolution
-   source-change communication
-   data-quality ownership
-   operational escalation
-   change management

For this project, actual source-system ownership information is not
provided. No specific owner is therefore claimed.

------------------------------------------------------------------------

## 3.3 Business Process

### Questions

-   What business process does the source support?
-   Does it support customer transactions?
-   Supply-chain operations?
-   Finance?
-   Inventory?
-   Another business process?
-   Which downstream activities depend on the data?

### Engineering relevance

Business-process understanding helps establish:

-   business importance
-   data criticality
-   expected consumers
-   source entity meaning
-   future analytical requirements
-   future warehouse modeling

The meaning of a field should not be invented when authoritative source
documentation is unavailable.

------------------------------------------------------------------------

# 4. System & Data Documentation

### Questions

-   Is source-system documentation available?
-   Is there a data dictionary?
-   Are tables/entities documented?
-   Are columns documented?
-   Are business definitions available?
-   Is an architecture diagram available?
-   Is a data catalog available?

### Engineering relevance

Existing documentation can reduce ambiguity during:

-   source mapping
-   Bronze design
-   Silver transformations
-   data-quality rule creation
-   dimensional modeling
-   table joins
-   business-rule implementation

Where documentation is unavailable, observed facts must be separated
from assumptions.

------------------------------------------------------------------------

# 5. Source Data Model

### Questions

-   What entities/tables/files exist?
-   What does each entity represent?
-   What are the primary keys?
-   What are the foreign keys?
-   Which columns uniquely identify records?
-   What relationships exist between entities?
-   Are relationships formally defined or only implied?
-   Which columns contain business identifiers?
-   Which columns contain timestamps or dates?

### Engineering relevance

The source data model becomes input to:

-   source-to-Bronze mapping
-   key validation
-   duplicate detection
-   future Silver transformations
-   future Gold modeling
-   data lineage

Bronze should preserve the source structure rather than prematurely
redesigning the source into a business-oriented analytical model.

------------------------------------------------------------------------

# 6. Data Catalog and Column-Level Understanding

For each source file/table, capture the following where available:

  Attribute              Engineering purpose
  ---------------------- ------------------------------------------
  Source file/table      Identifies source asset
  Column name            Identifies source attribute
  Description            Defines technical/business meaning
  Data type              Supports schema design
  Key indicator          Identifies primary/business keys
  Nullable               Supports data-quality checks
  Example value          Shows actual representation
  Date/timestamp field   Supports loading/history analysis
  Relationship           Supports source data-model understanding

### Engineering relevance

Column-level knowledge becomes input to:

-   Bronze DDL
-   source-to-target mapping
-   schema validation
-   data-quality rules
-   transformation requirements
-   later dimensional modeling

------------------------------------------------------------------------

# 7. Architecture & Technology Stack

## 7.1 Storage Technology

### Questions

-   Is the source on-premises?
-   Is it cloud-hosted?
-   Is it a database?
-   Is it file-based?
-   Is it exposed through an API?
-   Is it hybrid?
-   What technology stores the data?

Examples include:

-   SQL Server
-   Oracle
-   PostgreSQL
-   cloud storage
-   Azure services
-   AWS services
-   APIs
-   files

### Engineering relevance

The storage technology determines possible:

-   connectors/drivers
-   extraction mechanisms
-   connectivity
-   security requirements
-   performance strategy

------------------------------------------------------------------------

# 8. Integration Capabilities

### Questions

-   Does the source expose an API?
-   Does it provide file extracts?
-   Can the database be accessed directly?
-   Is Kafka or another messaging mechanism involved?
-   Is an existing integration platform available?
-   What extraction mechanism is officially supported?

### Engineering relevance

Examples:

``` text
API
 ↓
Python/API client
 ↓
Raw/Landing
```

``` text
Files
 ↓
Python file acquisition
 ↓
Raw/Landing
```

``` text
Source Database
 ↓
Database connector
 ↓
Raw/Landing / Bronze
```

``` text
Message Stream
 ↓
Consumer
 ↓
Streaming ingestion
```

The extraction mechanism should be selected based on actual source
capabilities and constraints.

------------------------------------------------------------------------

# 9. Extract & Load Requirements

## 9.1 Full vs Incremental Loading

### Questions

-   Is a full extraction possible?
-   Is incremental extraction possible?
-   What identifies new records?
-   What identifies modified records?
-   Is there an `updated_at` or equivalent field?
-   Does the source support CDC?
-   Is there another mechanism for identifying changes?
-   Which loading approach is expected?

### Engineering relevance

A full-load source can lead to:

``` text
Source
  ↓
Complete extraction
  ↓
Bronze
```

An incremental source may require:

``` text
Change indicator
      ↓
Watermark / CDC
      ↓
Incremental extraction
      ↓
Load
```

The initial Bronze implementation for this project follows the reference
full-load approach. The source analysis still records whether
incremental extraction is technically possible because this may
influence future pipeline evolution.

------------------------------------------------------------------------

# 10. Data Scope & Historical Requirements

### Questions

-   Do we need all source data?
-   What historical period is required?
-   Is historical data already available?
-   How far back does the source retain data?
-   Are records archived?
-   Does the warehouse require more history than the source exposes?
-   Does historization need to be implemented in the warehouse?

### Engineering relevance

The answers affect:

-   initial-load scope
-   storage requirements
-   extraction filters
-   historical retention
-   Silver/Gold modeling
-   SCD strategies
-   future incremental processing

Source history and warehouse history must be treated as separate design
questions.

------------------------------------------------------------------------

# 11. Extract Volume

### Questions

-   What is the expected extract size?
-   How many records are expected?
-   What is the largest source entity?
-   What is the expected daily/weekly/monthly volume?
-   How quickly does the volume grow?

### Engineering relevance

Expected volume affects:

-   ingestion technology
-   bulk loading
-   batching
-   memory requirements
-   partitioning
-   storage
-   runtime expectations
-   monitoring

A small file-based source and a multi-terabyte source should not
automatically receive the same ingestion architecture.

------------------------------------------------------------------------

# 12. Source Volume and Performance Limitations

### Questions

-   Are there source-side extraction limits?
-   Is there an API request limit?
-   Is there a maximum number of records per request?
-   Are database query limits present?
-   Can large extraction queries affect source performance?
-   Are there restricted extraction windows?
-   Are read replicas or dedicated extraction environments available?
-   Are there recommended query patterns?

### Engineering relevance

Possible requirements include:

``` text
Pagination
Batching
Chunking
Incremental extraction
Scheduled extraction windows
Query optimization
Read replicas
Rate-limit handling
```

The pipeline should not solve the warehouse ingestion problem by
unnecessarily degrading the source system.

------------------------------------------------------------------------

# 13. Source Update Frequency

### Questions

-   How frequently does the source change?
-   Is data generated continuously?
-   Hourly?
-   Daily?
-   Weekly?
-   On demand?
-   What freshness is expected by downstream consumers?

### Engineering relevance

Update frequency influences:

-   pipeline frequency
-   scheduling
-   freshness requirements
-   incremental design
-   future orchestration
-   monitoring

Example:

``` text
Daily source
   ↓
Daily batch pipeline
```

Whereas continuous changes may require a higher-frequency incremental or
streaming architecture.

------------------------------------------------------------------------

# 14. Source Performance Protection

### Questions

-   When is the source least busy?
-   Are heavy queries allowed?
-   Are extraction queries restricted?
-   Can a read replica be used?
-   Can extracts be generated separately from production?
-   Is there a preferred extraction window?
-   Are query-duration or connection limits present?

### Engineering relevance

Potential decisions include:

``` text
Low-traffic extraction window
        ↓
Controlled/batched extraction
        ↓
Incremental extraction where supported
        ↓
Read-only access
```

Source-system performance is an operational constraint that must be
considered during pipeline design.

------------------------------------------------------------------------

# 15. Authentication & Authorization

### Questions

-   How does the pipeline authenticate?
-   Username/password?
-   API token?
-   API key?
-   OAuth?
-   SSH key?
-   VPN?
-   IP whitelisting?
-   What permissions are required?
-   Is read-only access sufficient?
-   Are credentials rotated?

### Engineering relevance

Authentication requirements affect:

-   connection configuration
-   secret management
-   network configuration
-   connector implementation
-   deployment
-   least-privilege access

For local development, environment variables can hold configuration such
as:

``` text
SOURCE_DATA_PATH
DB_HOST
DB_PORT
DB_USER
DB_PASSWORD
```

Real secrets must remain outside version control.

The repository should contain:

``` text
.env.example
```

with placeholders, while `.env` remains local and ignored.

------------------------------------------------------------------------

# 16. Question → Answer → Engineering Decision

The core purpose of the discovery process is to convert source
information into engineering decisions.

``` text
Source Answer
      ↓
Technical Requirement
      ↓
Architecture Decision
      ↓
Pipeline Component
```

Examples:

  --------------------------------------------------------------------------------------
  Source finding          Engineering requirement      Resulting design
  ----------------------- ---------------------------- ---------------------------------
  Source is CSV           File acquisition required    Python file handling

  Source is API           API extraction required      Python API client

  Source is database      Database connectivity        DB connector
                          required                     

  Incremental extraction  Changes must be tracked      Watermark/CDC
  supported                                            

  Only full extraction    Complete reload required     Full-load pipeline
  available                                            

  `updated_at` identifies Incremental filter required  Watermark logic
  changes                                              

  API returns 1,000       Pagination required          Paginated extraction
  rows/request                                         

  Source is very large    Scalable ingestion required  Bulk/batched processing

  Source is               Extraction must be           Batching/scheduling/incremental
  performance-sensitive   controlled                   strategy

  VPN required            Network access required      Network/infrastructure
                                                       configuration

  API token required      Secret management required   Environment/secrets configuration

  No source history       Warehouse history may be     Historization/SCD design
                          required                     

  Primary key exists      Uniqueness can be validated  Key validation

  No formal key exists    Business uniqueness must be  Business-key analysis
                          established                  

  Source changes daily    Batch scheduling required    Daily orchestration

  Source changes          Higher-frequency/streaming   Incremental/streaming
  continuously            design may be required       architecture
  --------------------------------------------------------------------------------------

This conversion is the main engineering value of source discovery.

------------------------------------------------------------------------

# 17. Source Analysis as Requirements Engineering

Source-system discovery can be treated as the requirements-engineering
phase of a data pipeline.

``` text
Source-System Experts / Documentation
                 ↓
          Source Knowledge
                 ↓
        Data Engineering
          Requirements
                 ↓
            Architecture
                 ↓
          Pipeline Components
                 ↓
           Implementation
                 ↓
            Validation
```

The Data Engineer therefore does not simply receive data and start
writing Python or SQL.

The Data Engineer first determines the technical conditions under which
the data can be:

-   accessed
-   extracted
-   transported
-   landed
-   loaded
-   validated
-   monitored
-   eventually modeled

------------------------------------------------------------------------

# 18. Portfolio Project Adaptation

The reference approach assumes that a Data Engineer can interview
source-system experts.

This portfolio project uses provided CRM and ERP source files instead of
live enterprise applications.

Therefore, the project uses:

``` text
Provided source files
        ↓
File and metadata inspection
        ↓
Source analysis
        ↓
Documented observations
        ↓
Engineering requirements
```

The project does **not** claim that a real CRM/ERP owner or
source-system developer was interviewed.

Information that cannot be established from the provided datasets will
be recorded as:

``` text
Not provided
```

or:

``` text
Not explicitly documented; inferred from observed data
```

This keeps the documentation factual and separates observation from
assumption.

------------------------------------------------------------------------

# 19. Planned Source-Analysis Documentation

The analysis will be maintained under:

``` text
docs/
└── source_analysis/
    ├── crm.md
    └── erp.md
```

Each source document should contain:

1.  Source overview
2.  Business context
3.  Ownership information
4.  Source documentation
5.  Source files/entities
6.  Data model
7.  Columns and data types
8.  Keys and relationships
9.  Source technology
10. Integration capabilities
11. Full/incremental load characteristics
12. Historical scope
13. Expected volume
14. Source performance constraints
15. Authentication/access requirements
16. Data-quality observations
17. Ingestion requirements
18. Known limitations and unknowns

------------------------------------------------------------------------

# 20. Relationship to the Bronze Layer

Source analysis is performed before Bronze implementation because its
results become inputs to Bronze design.

The intended progression is:

``` text
Source Analysis
      ↓
Source Acquisition Design
      ↓
Python Source Acquisition
      ↓
Raw/Landing Data
      ↓
Bronze Table Design
      ↓
Bronze Full Load
      ↓
Bronze Validation
```

The Bronze layer remains focused on preserving source data and loading
it reliably. The reference approach emphasizes source-to-warehouse
loading, full loading, and avoiding transformations/data modeling at
this stage.

------------------------------------------------------------------------

# 21. Relationship to Source Acquisition Configuration

The upcoming source-acquisition implementation will keep
environment-specific paths outside the Python source code.

For example:

``` text
.env
    ↓
SOURCE_DATA_PATH
    ↓
Python ingestion
```

The design principle is:

``` text
Source location changes
        ↓
Change configuration
        ↓
Ingestion logic remains unchanged
```

This separates environment-specific configuration from reusable pipeline
logic.

The same principle already applies to the project's MySQL connection
configuration.

------------------------------------------------------------------------

# 22. Acceptance Criteria

-   [x] CRM and ERP source locations identified.
-   [x] Source-analysis methodology defined.
-   [x] Business-context questions defined.
-   [x] Ownership questions defined.
-   [x] Documentation and data-model questions defined.
-   [x] Architecture and technology questions defined.
-   [x] Integration-capability questions defined.
-   [x] Full vs incremental loading questions defined.
-   [x] Historical/data-scope questions defined.
-   [x] Extract-volume questions defined.
-   [x] Source-performance questions defined.
-   [x] Authentication and authorization questions defined.
-   [x] Source findings mapped to potential engineering requirements.
-   [x] Observed facts, inference, and unavailable information
    explicitly separated.
-   [x] CRM and ERP source-analysis documentation structure defined.
-   [x] Analysis aligned with the Bronze-layer reference workflow.

------------------------------------------------------------------------

# 23. Engineering Outcome

The outcome of Issue #9 is a **source-discovery and
engineering-requirements baseline**, not executable ingestion code.

The resulting workflow is:

``` text
ISSUE #9
Source Analysis
       ↓
Known source characteristics
       ↓
Engineering requirements
       ↓
ISSUE #10
Source Acquisition / Landing Design
       ↓
ISSUE #11
Python Automated Ingestion
       ↓
Bronze Implementation
```

This prevents the ingestion and Bronze implementation from being based
on unsupported assumptions.

------------------------------------------------------------------------

# 24. Key Engineering Principle

> **Understand the source before designing the pipeline.**

Source-analysis questions exist to determine the correct extraction
method, loading strategy, validation approach, security requirements,
performance controls, and future warehouse design.

The reference speaker's central point is that asking the right questions
helps a Data Engineer design the correct extraction scripts and avoid
mistakes and challenges.

------------------------------------------------------------------------

# 25. Issue Closure Summary

Issue #9 establishes the source-discovery foundation for the CRM and ERP
data sources.

The project can now move from:

``` text
Understand the source
```

to:

``` text
Design source acquisition
```

before implementing the Python ingestion and Bronze-loading components.

**Next stage:** Source Acquisition / Landing Strategy.
