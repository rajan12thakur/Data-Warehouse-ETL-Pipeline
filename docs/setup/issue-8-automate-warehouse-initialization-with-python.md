# Issue 8 — Automate Warehouse Initialization with Python

## 1. Issue Overview

**Issue:** Automate warehouse initialization with Python

**Goal:**  
Automate the creation of the MySQL databases required for the Data Warehouse ETL Pipeline.

The initialization process should:

1. Load database configuration from environment variables.
2. Connect to the MySQL Server.
3. Locate the SQL initialization script.
4. Execute the SQL statements.
5. Verify that the required warehouse databases exist.
6. Report success or failure clearly.
7. Close the database connection safely.

### Design principle

> **SQL defines the database structure. Python automates the execution.**

Python is not replacing SQL. It is acting as the automation/orchestration layer around the SQL setup script.

---

# 2. Project Architecture

The project uses a three-layer data warehouse architecture:

```text
                    MySQL Server
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
      dw_bronze      dw_silver       dw_gold
       Bronze         Silver           Gold
         │              │              │
         ▼              ▼              ▼
       Raw data     Cleaned data   Business-ready
                                    analytical data
```

## Bronze

`dw_bronze`

Stores raw/source-preserving data.

Purpose:

- Preserve source data.
- Maintain traceability.
- Support debugging.
- Keep data close to the original source representation.

## Silver

`dw_silver`

Stores cleaned and standardized data.

Typical responsibilities:

- Cleaning.
- Standardization.
- Data type normalization.
- Basic transformations.
- Removing or handling invalid records.

## Gold

`dw_gold`

Stores business-ready analytical data.

Typical responsibilities:

- Business rules.
- Integrations.
- Aggregations.
- Analytical models.
- Dimensions.
- Facts.
- Analytical views.

At Issue 8, these databases are intentionally empty.

No Bronze, Silver, or Gold tables are created yet.

---

# 3. MySQL Design Decision

The original conceptual architecture may use one database with separate schemas such as:

```text
DataWarehouse
├── bronze
├── silver
└── gold
```

In MySQL, databases and schemas are effectively equivalent concepts.

Therefore, this project uses separate databases:

```text
MySQL Server
├── dw_bronze
├── dw_silver
└── dw_gold
```

This keeps the Bronze/Silver/Gold boundaries explicit while remaining natural for MySQL.

This is an implementation decision for this project, not a claim that every MySQL warehouse must use separate databases.

---

# 4. Why Automate Database Initialization?

The databases could be created manually using:

```sql
CREATE DATABASE ...
```

or through a MySQL client.

However, manual setup creates several problems:

- It depends on a developer remembering the correct commands.
- It is easy to miss a database.
- Different developers may configure environments differently.
- Reproducing the project on another machine takes more manual work.
- CI/CD or deployment automation cannot depend on someone manually opening MySQL.
- The initialization process is not easily repeatable.

Python automation makes the setup reproducible.

Instead of manually performing:

```text
Open MySQL
    ↓
Connect
    ↓
Find SQL file
    ↓
Execute SQL
    ↓
Check databases
```

we can run:

```text
python scripts/setup_database.py
```

and let the script perform those steps.

---

# 5. Technologies Used

## Python

Used as the automation/orchestration layer.

## python-dotenv

Used to load environment variables from `.env`.

## mysql-connector-python

Used by Python to connect to MySQL Server and execute SQL statements.

## MySQL Server

The actual database engine.

It stores and manages:

- databases
- tables
- data
- users
- permissions
- transactions
- SQL execution

## MySQL Client

The `mysql` command-line program is a client used to connect to the MySQL Server.

For example:

```text
mysql -u root -p
```

The client sends SQL to the server.

## MySQL Workbench

Workbench is an optional graphical client for MySQL.

It is not required for this project.

The project can be operated using:

- MySQL CLI
- MySQL Workbench
- Python `mysql-connector-python`

---

# 6. Environment Setup

Python version used:

```text
Python 3.11.0
```

The project uses a virtual environment:

```text
.venv/
```

Create it with:

```powershell
python -m venv .venv
```

Activate it in PowerShell:

```powershell
.venv/Scripts/Activate.ps1
```

The virtual environment is local to the developer's machine.

It must not be committed to Git.

---

# 7. Python Dependencies

The project's `requirements.txt` contains:

```text
pandas
python-dotenv
mysql-connector-python
```

Install them with:

```powershell
pip install -r requirements.txt
```

The important packages for this issue are:

### `python-dotenv`

Allows Python to read configuration from `.env`.

### `mysql-connector-python`

Provides the Python API used to connect to MySQL Server.

### `pandas`

Not required by the database initialization script itself.

It is included because the broader ETL project will use pandas for data processing where appropriate.

---

# 8. Environment Variables

The committed file is:

```text
.env.example
```

It contains placeholders:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password
```

The real local configuration is stored in:

```text
.env
```

The `.env` file must not be committed.

Example local configuration:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_actual_password
```

The actual password must remain local and secret.

---

# 9. Why There Is No DB_NAME

Normally, an application connecting to a database might specify:

```text
database = dw_bronze
```

However, this initialization script is responsible for creating the databases themselves.

Therefore, it connects to the MySQL Server without specifying a database:

```python
connection = mysql.connector.connect(
    host=DB_HOST,
    port=int(DB_PORT),
    user=DB_USER,
    password=DB_PASSWORD,
)
```

The connection is therefore server-level.

The script can then execute:

```sql
CREATE DATABASE IF NOT EXISTS dw_bronze;
CREATE DATABASE IF NOT EXISTS dw_silver;
CREATE DATABASE IF NOT EXISTS dw_gold;
```

A `DB_NAME` environment variable is unnecessary for this particular setup script.

Later ETL scripts may have different connection requirements.

---

# 10. MySQL User Verification

The MySQL user can be inspected with:

```sql
SELECT User, Host
FROM mysql.user;
```

The development environment currently contains:

```text
Raj             %
mysql.infoschema localhost
mysql.session    localhost
mysql.sys        localhost
root             localhost
```

The active development connection was verified using:

```sql
SELECT USER();
```

and:

```sql
SELECT CURRENT_USER();
```

Both returned:

```text
root@localhost
```

For this local development setup, the script therefore uses the existing `root` account.

A dedicated least-privilege application user can be introduced later when appropriate.

---

# 11. SQL Initialization Script

File:

```text
sql/setup/create_databases.sql
```

Final script:

```sql
/*
===============================================================================
Script: create_databases.sql

Purpose:
    Initialize the empty MySQL data warehouse foundation for the
    Data Warehouse ETL Pipeline project.

Description:
    This script creates three separate MySQL databases representing the
    major layers of the data warehouse:

        1. dw_bronze
           Raw/source-preserving data.

        2. dw_silver
           Cleaned and standardized data.

        3. dw_gold
           Business-ready analytical data.

    At this stage, the databases are intentionally empty.
    No tables, source data, transformations, dimensions, or facts
    are created by this script.

Execution:
    This script is executed automatically by the Python database
    initialization script:

        scripts/setup_database.py

    It can also be executed directly using a MySQL client when required.

Safety:
    This script does NOT drop existing databases.

    CREATE DATABASE IF NOT EXISTS is used so that re-running the
    script does not destroy existing databases or their data.

Dependencies:
    - MySQL Server must be running.
    - The executing MySQL user must have sufficient privileges
      to create databases.

===============================================================================
*/

-- ============================================================================
-- BRONZE DATABASE
-- ============================================================================
-- Stores raw/source-preserving data during the Bronze ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_bronze
    CHARACTER SET utf8mb4;

-- ============================================================================
-- SILVER DATABASE
-- ============================================================================
-- Stores cleaned and standardized data during the Silver ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_silver
    CHARACTER SET utf8mb4;

-- ============================================================================
-- GOLD DATABASE
-- ============================================================================
-- Stores business-ready analytical data during the Gold ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_gold
    CHARACTER SET utf8mb4;
```

---

# 12. Why `IF NOT EXISTS` Is Important

The script uses:

```sql
CREATE DATABASE IF NOT EXISTS dw_bronze;
```

instead of:

```sql
CREATE DATABASE dw_bronze;
```

Without `IF NOT EXISTS`, running the script when the database already exists would produce an error.

With `IF NOT EXISTS`, the command becomes idempotent for database creation.

That means the initialization can safely be run again without attempting to recreate an existing database.

Important:

The script does not contain:

```sql
DROP DATABASE
```

This is intentional.

The initialization script must not destroy existing warehouse data.

---

# 13. Why `utf8mb4` Is Used

The database creation statements use:

```sql
CHARACTER SET utf8mb4
```

`utf8mb4` provides broad Unicode support.

This allows the database to correctly store a wide range of characters.

Using an explicit character set also makes the database configuration intentional rather than relying entirely on server defaults.

---

# 14. Project Structure After Issue 8

Relevant project structure:

```text
Data-warehouse-ETL-Pipeline/
│
├── data/
│   ├── raw/
│   │   ├── crm/
│   │   │   └── .gitkeep
│   │   └── erp/
│   │       └── .gitkeep
│   └── sample/
│       └── .gitkeep
│
├── docs/
│   ├── architecture/
│   │   └── README.md
│   ├── data_dictionary/
│   │   └── README.md
│   ├── data_model/
│   │   └── README.md
│   ├── decisions/
│   │   └── README.md
│   ├── etl/
│   │   └── README.md
│   └── project_plan/
│       └── README.md
│
├── scripts/
│   └── setup_database.py
│
├── sql/
│   ├── bronze/
│   │   ├── loading/
│   │   ├── tables/
│   │   └── validations/
│   ├── silver/
│   │   ├── loading/
│   │   ├── transformations/
│   │   └── validations/
│   ├── gold/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   ├── views/
│   │   └── validations/
│   └── setup/
│       └── create_databases.sql
│
├── tests/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── .env
├── .env.example
├── .gitignore
└── requirements.txt
```

`.env` and `.venv/` remain local and ignored by Git.

---

# 15. Python Automation Script

File:

```text
scripts/setup_database.py
```

Final implementation:

```python
"""
Automate MySQL data warehouse initialization.

This script:

1. Loads environment variables.
2. Reads MySQL connection settings.
3. Connects to the MySQL Server.
4. Locates the warehouse database initialization SQL file.
5. Executes the SQL statements.
6. Verifies the required databases.
7. Reports success or failure.

Design decision:
    SQL defines the database structure.
    Python automates the execution.
"""

from pathlib import Path
import os

import mysql.connector
from dotenv import load_dotenv


# ============================================================================
# CONFIGURATION
# ============================================================================

# Load environment variables from the project's .env file.
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# Databases that must exist after initialization.
EXPECTED_DATABASES = [
    "dw_bronze",
    "dw_silver",
    "dw_gold",
]


# ============================================================================
# PATHS
# ============================================================================

# Get the root directory of the project.
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Locate the SQL initialization script.
SQL_FILE = PROJECT_ROOT / "sql" / "setup" / "create_databases.sql"


# ============================================================================
# VALIDATION
# ============================================================================

def validate_configuration():
    """Validate required environment variables and SQL file."""

    required_variables = {
        "DB_HOST": DB_HOST,
        "DB_PORT": DB_PORT,
        "DB_USER": DB_USER,
        "DB_PASSWORD": DB_PASSWORD,
    }

    missing_variables = [
        name
        for name, value in required_variables.items()
        if not value
    ]

    if missing_variables:
        raise ValueError(
            "Missing required environment variables: "
            + ", ".join(missing_variables)
        )

    if not SQL_FILE.exists():
        raise FileNotFoundError(
            f"SQL initialization file was not found: {SQL_FILE}"
        )


# ============================================================================
# DATABASE INITIALIZATION
# ============================================================================

def initialize_databases():
    """Execute the SQL initialization script."""

    connection = None
    cursor = None

    try:
        print("Starting data warehouse initialization...")
        print()

        validate_configuration()

        print(f"SQL file: {SQL_FILE}")
        print(f"MySQL host: {DB_HOST}")
        print(f"MySQL port: {DB_PORT}")
        print(f"MySQL user: {DB_USER}")
        print()

        # Connect to the MySQL Server.
        # No database is specified because the databases themselves
        # are being created by this script.
        connection = mysql.connector.connect(
            host=DB_HOST,
            port=int(DB_PORT),
            user=DB_USER,
            password=DB_PASSWORD,
        )

        print("Connected to MySQL Server successfully.")
        print()

        cursor = connection.cursor()

        # Read the SQL initialization script.
        sql_script = SQL_FILE.read_text(encoding="utf-8")

        # Split the script into individual SQL statements.
        statements = [
            statement.strip()
            for statement in sql_script.split(";")
            if statement.strip()
        ]

        print("Executing database initialization SQL...")

        for statement in statements:
            cursor.execute(statement)

        print("Database initialization SQL executed successfully.")
        print()

        # Verify that all expected databases exist.
        print("Verifying databases...")

        for database in EXPECTED_DATABASES:
            cursor.execute(
                "SHOW DATABASES LIKE %s",
                (database,)
            )

            result = cursor.fetchone()

            if result is None:
                raise RuntimeError(
                    f"Database verification failed: {database}"
                )

            print(f"  ✓ {database}")

        print()
        print("Data warehouse initialization completed successfully.")

    except mysql.connector.Error as error:
        print()
        print(f"MySQL error: {error}")
        raise

    except (ValueError, FileNotFoundError, RuntimeError) as error:
        print()
        print(f"Initialization error: {error}")
        raise

    finally:
        if cursor is not None:
            cursor.close()

        if connection is not None and connection.is_connected():
            connection.close()
            print("MySQL connection closed.")


# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    initialize_databases()
```

---

# 16. Python Script — Detailed Explanation

## Imports

```python
from pathlib import Path
```

`Path` provides an operating-system-independent way to construct and manipulate file paths.

It is used to locate:

```text
sql/setup/create_databases.sql
```

without hardcoding the user's machine-specific absolute path.

---

```python
import os
```

Used to access environment variables:

```python
os.getenv("DB_HOST")
```

---

```python
import mysql.connector
```

Imports the MySQL Connector/Python package.

This provides the Python interface to the MySQL Server.

---

```python
from dotenv import load_dotenv
```

Imports the function that loads variables from `.env`.

---

# 17. Loading Environment Variables

```python
load_dotenv()
```

This searches for `.env` and loads variables into the process environment.

For example:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=...
```

Python can then retrieve them using:

```python
os.getenv(...)
```

---

# 18. Reading Configuration

```python
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
```

This separates configuration from application code.

The script does not contain:

```python
password = "actual_password"
```

That would expose a secret in source code.

Instead:

```text
.env
  ↓
environment variables
  ↓
Python
  ↓
MySQL connection
```

---

# 19. Expected Databases

```python
EXPECTED_DATABASES = [
    "dw_bronze",
    "dw_silver",
    "dw_gold",
]
```

This list defines what the script expects after initialization.

It is also used for verification.

This avoids writing the same database names repeatedly throughout the verification logic.

---

# 20. Finding the Project Root

```python
PROJECT_ROOT = Path(__file__).resolve().parent.parent
```

`__file__` represents the current Python file:

```text
scripts/setup_database.py
```

`.resolve()` converts it to an absolute path.

`.parent` gives:

```text
scripts/
```

The second `.parent` gives the project root:

```text
Data-warehouse-ETL-Pipeline/
```

Therefore:

```python
PROJECT_ROOT
```

points to the project root.

---

# 21. Locating the SQL File

```python
SQL_FILE = PROJECT_ROOT / "sql" / "setup" / "create_databases.sql"
```

This constructs:

```text
project_root/
    sql/
        setup/
            create_databases.sql
```

The important benefit is that the script does not depend on the user's current working directory.

It calculates the path from the location of the script itself.

---

# 22. Configuration Validation

The function:

```python
def validate_configuration():
```

checks that the required configuration exists before connecting.

Required values:

```python
DB_HOST
DB_PORT
DB_USER
DB_PASSWORD
```

If any value is missing:

```python
raise ValueError(...)
```

This prevents confusing downstream connection errors.

The function also verifies that:

```text
create_databases.sql
```

exists.

If the SQL file is missing:

```python
raise FileNotFoundError(...)
```

---

# 23. Why Validate Before Connecting?

The sequence is intentional:

```text
Load configuration
      ↓
Validate configuration
      ↓
Validate SQL file
      ↓
Connect to MySQL
      ↓
Execute SQL
```

There is no point attempting a database connection if the required configuration is missing.

Likewise, there is no point connecting if the initialization script cannot be found.

---

# 24. Database Connection

The connection is created with:

```python
connection = mysql.connector.connect(
    host=DB_HOST,
    port=int(DB_PORT),
    user=DB_USER,
    password=DB_PASSWORD,
)
```

The important detail is that there is no:

```python
database=...
```

because the databases do not exist yet.

The script connects to the MySQL Server first and then creates the databases.

Conceptually:

```text
Python
  │
  │ connection
  ▼
MySQL Server
  │
  ├── create dw_bronze
  ├── create dw_silver
  └── create dw_gold
```

---

# 25. Cursor

After connecting:

```python
cursor = connection.cursor()
```

A cursor is the object used to execute SQL statements through the connection.

Conceptually:

```text
Python
  │
  ▼
Connection
  │
  ▼
Cursor
  │
  ▼
SQL statement
  │
  ▼
MySQL Server
```

The connection represents the communication channel.

The cursor is used to send SQL commands and retrieve results.

---

# 26. Reading the SQL File

```python
sql_script = SQL_FILE.read_text(encoding="utf-8")
```

This reads the entire SQL file as text.

For example:

```text
CREATE DATABASE IF NOT EXISTS dw_bronze ...;

CREATE DATABASE IF NOT EXISTS dw_silver ...;

CREATE DATABASE IF NOT EXISTS dw_gold ...;
```

Python now has the SQL script in memory.

---

# 27. Splitting SQL Statements

The script currently uses:

```python
statements = [
    statement.strip()
    for statement in sql_script.split(";")
    if statement.strip()
]
```

The purpose is to convert one SQL file containing multiple statements into individual statements.

For example:

```text
statement 1:
CREATE DATABASE ...

statement 2:
CREATE DATABASE ...

statement 3:
CREATE DATABASE ...
```

Each statement is then passed separately to:

```python
cursor.execute(statement)
```

### Important limitation

This simple approach is sufficient for the current database initialization script because it contains simple `CREATE DATABASE` statements.

It should not automatically be considered a general SQL parser.

Later, when the project contains:

- stored procedures
- triggers
- complex delimiter usage
- procedural SQL

this approach may need to be replaced with a more robust execution strategy.

That limitation is intentionally documented rather than hidden.

---

# 28. Executing SQL

The script loops through the statements:

```python
for statement in statements:
    cursor.execute(statement)
```

Each statement is sent to MySQL.

The SQL file therefore remains the source of truth for the database creation logic.

Python only automates its execution.

---

# 29. Verification

After execution, the script verifies each expected database:

```python
for database in EXPECTED_DATABASES:
```

It runs:

```python
cursor.execute(
    "SHOW DATABASES LIKE %s",
    (database,)
)
```

The parameterized form:

```text
%s
```

is used instead of constructing SQL using string concatenation.

The result is retrieved with:

```python
result = cursor.fetchone()
```

If no database is found:

```python
raise RuntimeError(...)
```

Otherwise:

```text
✓ dw_bronze
✓ dw_silver
✓ dw_gold
```

is printed.

---

# 30. Why Verification Matters

Executing SQL successfully does not necessarily mean that the desired final state has been verified.

The script therefore follows:

```text
Execute
   ↓
Verify
   ↓
Report
```

This is an important automation pattern.

A production ETL system should not blindly assume that an operation succeeded simply because no immediate error was displayed.

---

# 31. Error Handling

The script catches MySQL-specific errors:

```python
except mysql.connector.Error as error:
```

It also catches configuration and initialization errors:

```python
except (ValueError, FileNotFoundError, RuntimeError) as error:
```

The error is printed and then re-raised:

```python
raise
```

Re-raising is important because the script should still terminate with a failure status.

This is useful for automation systems and CI/CD pipelines.

---

# 32. `finally`

The `finally` block executes regardless of whether the operation succeeds or fails.

```python
finally:
    if cursor is not None:
        cursor.close()

    if connection is not None and connection.is_connected():
        connection.close()
```

This prevents leaving resources open.

The general pattern is:

```text
Try
  ↓
Do work
  ↓
Success or Error
  ↓
Finally
  ↓
Clean up resources
```

---

# 33. Script Entry Point

The final section is:

```python
if __name__ == "__main__":
    initialize_databases()
```

This means:

- If the file is executed directly, run `initialize_databases()`.
- If the file is imported into another Python module, do not automatically execute it.

This is standard Python script design.

---

# 34. Running the Automation

From the project root:

```powershell
python .\scripts\setup_database.py
```

Expected output:

```text
Starting data warehouse initialization...

SQL file: <project-root>/sql/setup/create_databases.sql
MySQL host: localhost
MySQL port: 3306
MySQL user: root

Connected to MySQL Server successfully.

Executing database initialization SQL...
Database initialization SQL executed successfully.

Verifying databases...
  ✓ dw_bronze
  ✓ dw_silver
  ✓ dw_gold

Data warehouse initialization completed successfully.
MySQL connection closed.
```

The exact SQL file path will depend on the developer's machine.

---

# 35. Verification Through MySQL

The databases can also be checked manually.

Connect:

```powershell
mysql -u root -p
```

Then:

```sql
SHOW DATABASES LIKE 'dw_%';
```

Expected result:

```text
dw_bronze
dw_gold
dw_silver
```

The databases should exist but contain no warehouse tables yet.

---

# 36. Checking for Tables

The MySQL metadata database can be queried:

```sql
SELECT
    table_schema,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema IN (
    'dw_bronze',
    'dw_silver',
    'dw_gold'
)
GROUP BY table_schema
ORDER BY table_schema;
```

At this stage, the expected state is that no warehouse tables exist.

This confirms that Issue 8 only initialized the databases.

---

# 37. Old `retail_*` Databases

Earlier development iterations created:

```text
retail_bronze
retail_silver
retail_gold
```

The databases were checked with:

```sql
SELECT
    table_schema,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema IN (
    'retail_bronze',
    'retail_silver',
    'retail_gold'
)
GROUP BY table_schema
ORDER BY table_schema;
```

The result was:

```text
Empty set
```

This means those earlier databases contained no tables at the time of verification.

The final project naming convention is:

```text
dw_bronze
dw_silver
dw_gold
```

If the old databases still exist locally, they can be removed after confirming they are no longer needed:

```sql
DROP DATABASE retail_bronze;
DROP DATABASE retail_silver;
DROP DATABASE retail_gold;
```

Then verify:

```sql
SHOW DATABASES LIKE 'retail_%';
```

and:

```sql
SHOW DATABASES LIKE 'dw_%';
```

The cleanup commands are intentionally not part of `create_databases.sql`.

The initialization script must create the required warehouse databases, not destroy unrelated or legacy databases.

---

# 38. Direct SQL Execution vs Python Automation

The SQL file can be executed manually using the MySQL client.

For example:

```sql
SOURCE C:/path/to/project/sql/setup/create_databases.sql;
```

The automated approach is:

```text
python scripts/setup_database.py
```

### Manual approach

```text
Developer
   ↓
MySQL client
   ↓
SOURCE SQL file
   ↓
MySQL Server
```

### Automated approach

```text
Developer / CI / deployment
          ↓
      Python script
          ↓
     MySQL Connector
          ↓
      MySQL Server
          ↓
      SQL script
```

Both approaches use the same SQL definition.

The Python version simply makes the process repeatable and automatable.

---

# 39. Important Distinction: MySQL Server vs Client vs Python Connector

These three things should not be confused.

## MySQL Server

The actual database engine.

It stores and manages:

```text
databases
tables
data
users
permissions
transactions
```

## MySQL CLI Client

The `mysql.exe` command-line application.

Example:

```powershell
mysql -u root -p
```

It provides an interface for humans to send SQL to MySQL Server.

## Python Connector

`mysql-connector-python`

It allows Python programs to communicate with MySQL Server.

Example:

```python
mysql.connector.connect(...)
```

Therefore:

```text
Human
  ↓
MySQL CLI
  ↓
MySQL Server
```

and:

```text
Python program
  ↓
mysql-connector-python
  ↓
MySQL Server
```

Both are clients of the same server.

---

# 40. Why Python Is an Automation Layer

The responsibilities are deliberately separated:

```text
SQL
 │
 └── Defines database objects and SQL logic

Python
 │
 └── Automates execution, validation and orchestration

MySQL Server
 │
 └── Executes SQL and stores/manages data
```

This separation is useful in a data engineering project because later the same pattern can be extended to:

```text
Python
  ↓
Extract source data
  ↓
Load Bronze
  ↓
Transform
  ↓
Load Silver
  ↓
Transform
  ↓
Load Gold
  ↓
Validate
  ↓
Report result
```

---

# 41. Issue 8 Scope

Issue 8 is only about **warehouse initialization automation**.

It does NOT yet implement:

- Source extraction.
- CRM ingestion.
- ERP ingestion.
- Bronze table creation.
- Bronze loading.
- Silver transformations.
- Gold dimensions.
- Gold facts.
- Data quality framework.
- Incremental loading.
- SCD Type 2.
- Scheduling.
- Airflow.
- Spark.
- Production orchestration.

Those belong to later issues.

---

# 42. What Has Been Completed

## Environment

- Python virtual environment created.
- Required packages installed.
- `.env` configured locally.
- `.env` ignored by Git.

## MySQL

- MySQL Server confirmed available.
- MySQL CLI connection tested.
- MySQL user verified.
- Root account used for local development.

## SQL

Created:

```text
dw_bronze
dw_silver
dw_gold
```

The SQL script is stored at:

```text
sql/setup/create_databases.sql
```

## Python

Created:

```text
scripts/setup_database.py
```

The script:

- loads configuration
- validates configuration
- finds the SQL file
- connects to MySQL
- executes the SQL
- verifies databases
- closes the connection

## Verification

Successful output confirmed:

```text
✓ dw_bronze
✓ dw_silver
✓ dw_gold
```

---

# 43. What Is Not Yet Completed

Issue 8 does not create warehouse tables.

The current state is:

```text
MySQL Server
│
├── dw_bronze
│     └── empty
│
├── dw_silver
│     └── empty
│
└── dw_gold
      └── empty
```

This is expected.

The next issues will introduce actual warehouse structures and ETL processing.

---

# 44. Git Workflow for Issue 8

The work was performed on:

```text
8-automate-warehouse-initialization-with-python
```

The branch should be based on the current `develop` branch.

Before starting work:

```powershell
git fetch origin
git checkout 8-automate-warehouse-initialization-with-python
git status
```

The expected initial state was a clean working tree.

---

# 45. Files Changed for Issue 8

Expected changes include:

```text
.env.example
sql/setup/create_databases.sql
scripts/setup_database.py
```

The local `.env` is not committed.

The local `.venv/` is not committed.

---

# 46. Review Before Commit

Run:

```powershell
git status
```

Then:

```powershell
git diff
```

Check specifically that:

- `.env` is not staged.
- `.venv/` is not staged.
- passwords are not present in tracked files.
- SQL contains `dw_bronze`, `dw_silver`, `dw_gold`.
- Python references the correct SQL path.
- Python uses environment variables.
- no machine-specific absolute paths are hardcoded.
- the script does not contain destructive `DROP DATABASE` statements.
- verification logic checks all three databases.

---

# 47. Recommended Test Sequence

## Test 1 — Run Python initialization

```powershell
python .\scripts\setup_database.py
```

Expected:

```text
Connected to MySQL Server successfully.
Database initialization SQL executed successfully.
✓ dw_bronze
✓ dw_silver
✓ dw_gold
Data warehouse initialization completed successfully.
```

## Test 2 — Verify through MySQL

```powershell
mysql -u root -p
```

Then:

```sql
SHOW DATABASES LIKE 'dw_%';
```

## Test 3 — Verify empty initial state

```sql
SELECT
    table_schema,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema IN (
    'dw_bronze',
    'dw_silver',
    'dw_gold'
)
GROUP BY table_schema
ORDER BY table_schema;
```

At this issue, there should be no warehouse tables.

---

# 48. Idempotency Test

Because the SQL uses:

```sql
CREATE DATABASE IF NOT EXISTS
```

the initialization script can be run more than once.

Run:

```powershell
python .\scripts\setup_database.py
```

again.

It should still complete successfully.

The second execution should not delete or recreate the existing databases destructively.

This is an important property of infrastructure/setup automation.

---

# 49. Git Commit Strategy

A clean commit sequence could be:

```text
feat(setup): automate warehouse database initialization
```

If the SQL and Python changes are intentionally separated, another valid approach is:

```text
feat(setup): define warehouse databases
feat(setup): automate database initialization
```

For this issue, one focused commit is acceptable if all changes form one logical unit.

---

# 50. Push the Branch

After testing:

```powershell
git add .
```

Before committing, inspect the staged files:

```powershell
git status
```

Then:

```powershell
git diff --cached
```

Commit:

```powershell
git commit -m "feat(setup): automate warehouse database initialization"
```

Push:

```powershell
git push -u origin 8-automate-warehouse-initialization-with-python
```

---

# 51. Pull Request

Create a Pull Request:

```text
8-automate-warehouse-initialization-with-python
                    ↓
                 develop
```

PR title:

```text
feat(setup): automate warehouse database initialization
```

Suggested PR description:

```markdown
## Summary

Automates MySQL warehouse initialization using Python.

## Changes

- Added Python database initialization script.
- Added environment-based MySQL configuration.
- Added SQL database initialization for Bronze, Silver and Gold.
- Added database verification.
- Added safe connection cleanup.

## Databases

- dw_bronze
- dw_silver
- dw_gold

## Validation

- Python initialization script executed successfully.
- MySQL connection verified.
- All three databases verified successfully.
- Databases remain empty as expected for this issue.

## Safety

- Uses `CREATE DATABASE IF NOT EXISTS`.
- Does not drop existing databases.
- Credentials remain in local `.env`.
```

---

# 52. Merge Strategy

After PR review:

```text
feature branch
      ↓
    develop
```

Do not directly push feature work to `main`.

The intended workflow is:

```text
main
  ↑
develop
  ↑
feature branch
```

This keeps `main` stable while development happens through feature branches.

---

# 53. Final Git Verification

After the PR is merged:

```powershell
git checkout develop
git pull origin develop
git status
```

Expected:

```text
On branch develop
Your branch is up to date with 'origin/develop'.

nothing to commit, working tree clean
```

---

# 54. Interview Explanation

If asked:

> How did you automate warehouse initialization?

A strong concise answer is:

> I separated the database definition from the automation logic. The SQL script defines the Bronze, Silver and Gold databases, while a Python script loads MySQL credentials from environment variables, connects to the MySQL Server using `mysql-connector-python`, reads and executes the SQL initialization script, verifies that all required databases were created, and closes the connection safely. I also used `CREATE DATABASE IF NOT EXISTS` so the initialization is safe to rerun.

---

# 55. Interview Follow-Up: Why Python?

Possible answer:

> Python provides a convenient automation and orchestration layer. Instead of requiring a developer to manually connect to MySQL and execute setup commands, the project can initialize the required warehouse environment through a repeatable script. The same approach can later be extended to automate ETL tasks.

---

# 56. Interview Follow-Up: Why Keep SQL if Python Is Automating It?

Answer:

> SQL is still the natural language for defining and manipulating relational database structures and data. Python is responsible for orchestration. Keeping SQL separate makes the database logic easier to inspect, test and maintain, while Python controls when and how that logic is executed.

---

# 57. Interview Follow-Up: Why No Database Name in the Connection?

Answer:

> The initialization script is creating the databases themselves, so they do not exist at connection time. Therefore, the Python connector connects to the MySQL Server without selecting a database, executes the `CREATE DATABASE` statements, and then verifies the resulting databases.

---

# 58. Interview Follow-Up: What Is the Difference Between MySQL Server and MySQL Client?

Answer:

> MySQL Server is the database engine that stores and manages the data and executes SQL. The MySQL CLI is a client program used to communicate with the server. In this project, Python with `mysql-connector-python` is another client that communicates with the same MySQL Server.

---

# 59. Interview Follow-Up: Why Use Environment Variables?

Answer:

> Environment variables keep configuration and credentials outside the source code. This prevents passwords from being hardcoded into the repository and allows the same application code to work across different environments by changing configuration rather than code.

---

# 60. Interview Follow-Up: Why `IF NOT EXISTS`?

Answer:

> It makes the initialization safer to rerun. If the database already exists, MySQL does not attempt to create it again and the existing database is not dropped. This gives the initialization script an idempotent database-creation behavior.

---

# 61. Interview Follow-Up: Why Verify After Execution?

Answer:

> Verification gives the automation an explicit final-state check. Instead of assuming that SQL execution produced the required environment, the script checks that `dw_bronze`, `dw_silver`, and `dw_gold` actually exist.

---

# 62. Important Engineering Insight

This issue demonstrates a basic but important data engineering pattern:

```text
Declarative database logic
          +
Programmatic orchestration
          +
Environment-based configuration
          +
Validation
          +
Safe cleanup
```

That pattern scales beyond simple database creation.

Later, the same concepts can support:

```text
Extract
  ↓
Validate source
  ↓
Load Bronze
  ↓
Validate Bronze
  ↓
Transform
  ↓
Load Silver
  ↓
Validate Silver
  ↓
Build Gold
  ↓
Validate Gold
```

---

# 63. Current Project State

At the completion of Issue 8:

```text
                 MySQL Server
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
      dw_bronze   dw_silver   dw_gold
          │           │           │
       empty       empty       empty
```

Automation:

```text
scripts/setup_database.py
             │
             ▼
   create_databases.sql
             │
             ▼
       MySQL Server
             │
             ▼
    Verify final state
```

The project is now ready to move from infrastructure initialization into actual source-system analysis and warehouse ETL development.

---

# 64. Next Logical Development Stages

The next stages are expected to follow the warehouse lifecycle:

```text
Issue 8
Warehouse initialization
        ↓
Source-system analysis
        ↓
Bronze layer
        ↓
Silver layer
        ↓
Gold layer
        ↓
Data quality / validation
        ↓
ETL automation
        ↓
Orchestration / scheduling
```

The next implementation should not prematurely mix all of these responsibilities into the initialization script.

Keep each layer and responsibility separated.

---

# 65. Issue 8 Completion Checklist

## Environment

- [x] Python virtual environment created.
- [x] Required dependencies installed.
- [x] `.env.example` created/updated.
- [x] `.env` kept local.
- [x] `.venv/` ignored.

## MySQL

- [x] MySQL Server available.
- [x] MySQL CLI connection tested.
- [x] MySQL user verified.
- [x] Server-level connection tested from Python.

## SQL

- [x] `dw_bronze` defined.
- [x] `dw_silver` defined.
- [x] `dw_gold` defined.
- [x] `IF NOT EXISTS` used.
- [x] No destructive `DROP DATABASE` commands in initialization script.
- [x] `utf8mb4` configured.

## Python

- [x] Environment loading implemented.
- [x] Configuration validation implemented.
- [x] SQL file discovery implemented.
- [x] MySQL connection implemented.
- [x] SQL execution implemented.
- [x] Database verification implemented.
- [x] Error handling implemented.
- [x] Connection cleanup implemented.
- [x] Direct script entry point implemented.

## Testing

- [x] Python initialization executed successfully.
- [x] `dw_bronze` verified.
- [x] `dw_silver` verified.
- [x] `dw_gold` verified.
- [x] Warehouse databases confirmed empty at this stage.

## Git

- [ ] Review `git diff`.
- [ ] Confirm `.env` is not staged.
- [ ] Confirm `.venv/` is not staged.
- [ ] Remove legacy `retail_*` databases locally if still present and confirmed unnecessary.
- [ ] Commit Issue 8 changes.
- [ ] Push feature branch.
- [ ] Open PR into `develop`.
- [ ] Merge after review.
- [ ] Pull updated `develop`.
- [ ] Confirm clean working tree.

---

# 66. Final Mental Model

Remember the entire Issue 8 flow as:

```text
Developer
   │
   │ runs
   ▼
python scripts/setup_database.py
   │
   ├── load .env
   │
   ├── validate configuration
   │
   ├── locate create_databases.sql
   │
   ├── connect to MySQL Server
   │
   ├── execute SQL
   │       │
   │       ├── CREATE dw_bronze
   │       ├── CREATE dw_silver
   │       └── CREATE dw_gold
   │
   ├── verify databases
   │
   └── close connection
```

The key architectural idea is:

> **SQL defines what the warehouse infrastructure should look like; Python automates making that state exist and verifies the result.**

This completes the warehouse initialization foundation without prematurely implementing the actual ETL pipeline.
