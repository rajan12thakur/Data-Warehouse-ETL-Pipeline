# Issue 6 — Initialize Data Warehouse Foundation

## 1. Issue Overview

**Issue:** Initialize Data Warehouse Foundation  
**Branch:** `6-initialize-data-warehouse-foundation`  
**Repository:** `Data-Warehouse-ETL-Pipeline`

### Objective

Create the initial, empty MySQL warehouse foundation for the Data Warehouse ETL Pipeline.

The warehouse is divided into three logical layers:

- `retail_bronze` — raw/source-preserving data
- `retail_silver` — cleaned and standardized data
- `retail_gold` — business-ready analytical data

At this stage, the databases are intentionally empty. We do **not** create source tables, transformations, dimensions, facts, or load data yet.

---

# 2. Why This Issue Exists

The project follows a staged ETL/data-warehouse development process:

```text
Project Initialization
        ↓
Initialize Empty Warehouse Foundation   ← CURRENT ISSUE
        ↓
Analyze Source Systems
        ↓
Design & Build Bronze
        ↓
Design & Build Silver
        ↓
Design & Build Gold
        ↓
ETL Automation / Data Quality / Monitoring
```

The important idea is:

> First establish the target warehouse environment. Then analyze the source systems and determine what the warehouse actually needs.

This prevents us from prematurely creating tables before understanding the source data and business requirements.

---

# 3. Relationship to the Speaker's Architecture

The speaker's project used SQL Server and conceptually created:

```text
DataWarehouse
├── bronze
├── silver
└── gold
```

SQL Server supports separate schemas inside a database.

For this project, MySQL is being used instead.

In MySQL, database and schema are effectively synonymous concepts. Therefore, instead of trying to reproduce SQL Server's separate schemas, this project uses separate databases:

```text
MySQL Server
│
├── retail_bronze
├── retail_silver
└── retail_gold
```

This is an intentional adaptation rather than a direct copy of the speaker's implementation.

---

# 4. Project Environment

Project path:

```text
C:\Users\Rajan Thakur\OneDrive\Desktop\SQL\Data Warehouse\Data-warehouse-ETL-Pipeline
```

Python virtual environment:

```text
.venv
```

The Python virtual environment is used for future ETL development and packages such as:

```text
pandas
python-dotenv
mysql-connector-python
```

However, the database initialization in this issue was performed through the MySQL command-line client, not Python.

---

# 5. Git Branch

The work was performed on:

```text
6-initialize-data-warehouse-foundation
```

The branch was obtained from the remote repository with:

```powershell
git fetch origin
git checkout 6-initialize-data-warehouse-foundation
git status
```

The resulting status was:

```text
On branch 6-initialize-data-warehouse-foundation
Your branch is up to date with
'origin/6-initialize-data-warehouse-foundation'.

nothing to commit, working tree clean
```

This confirmed that the branch was available locally and there were no existing uncommitted changes before the issue work began.

---

# 6. MySQL Version Verification

The installed MySQL command-line client was checked with:

```powershell
mysql --version
```

Output showed:

```text
C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe
Ver 26.7.0 for Win64 on x86_64
(MySQL Community Server - GPL)
```

This established that the MySQL command-line client was available on the machine.

---

# 7. MySQL Server vs MySQL Client

This distinction is extremely important.

## MySQL Server

The **MySQL Server** is the database system that actually:

- stores databases
- stores tables
- stores data
- executes SQL
- manages connections
- manages users and permissions
- performs database operations

Conceptually:

```text
MySQL Server
│
├── retail_bronze
├── retail_silver
└── retail_gold
```

The server is responsible for the actual database state.

## MySQL Client

The **MySQL Client** is a program used to communicate with the MySQL Server.

One important client is:

```text
mysql.exe
```

It provides a command-line interface where SQL and MySQL client commands can be entered.

The relationship is:

```text
User
  ↓
MySQL Client
(mysql.exe)
  ↓
connection
  ↓
MySQL Server
  ↓
Databases / Tables / Data
```

---

# 8. What Is MySQL Workbench?

MySQL Workbench is a graphical interface for working with MySQL.

It is **not required** for this project.

There are multiple ways to communicate with the same MySQL Server:

```text
                    MySQL Server
                    /           \
                   /             \
                  ↓               ↓
        MySQL Command Line     MySQL Workbench
             Client                GUI
                  ↑
                  |
             mysql.exe
```

For this issue, the command-line client was used instead of MySQL Workbench.

Therefore, it was not necessary to open Workbench.

---

# 9. Connecting to MySQL

The following command was used:

```powershell
mysql -u root -p
```

Breakdown:

- `mysql` — starts the MySQL command-line client.
- `-u` — specifies the MySQL username.
- `root` — the username used for the connection.
- `-p` — tells the client to request the user's password.

The complete flow is:

```text
mysql -u root -p
        │
        ├── Start MySQL Client
        ├── Username = root
        └── Ask for password
                ↓
        Connect to MySQL Server
```

After successful authentication, the prompt changed to:

```text
mysql>
```

This meant the MySQL command-line client was connected and ready to receive commands.

---

# 10. What Does `mysql>` Mean?

The prompt:

```text
mysql>
```

means the MySQL command-line client is running and waiting for input.

For example:

```sql
mysql> SHOW DATABASES;
```

The client sends the SQL statement to the MySQL Server.

The server executes it and returns the result.

Then the client displays:

```text
mysql>
```

again.

---

# 11. The `create_databases.sql` File

The project contains:

```text
sql/
└── setup/
    └── create_databases.sql
```

This is a SQL script file.

A `.sql` file is essentially a text file containing SQL statements and comments.

Important:

> Creating a `.sql` file does not execute anything.

The file must be executed by a SQL client or another database tool.

The analogy is similar to a Python script: creating `hello.py` does not execute it. It must be run using Python.

Similarly, `create_databases.sql` must be executed by a MySQL client.

---

# 12. Purpose of `create_databases.sql`

The script was designed to create the initial warehouse databases.

Its responsibilities are limited to:

```text
Create retail_bronze
Create retail_silver
Create retail_gold
```

It does **not**:

```text
Create Bronze tables
Create Silver tables
Create Gold dimensions
Create Gold facts
Load source data
Transform data
Run ETL
```

Those responsibilities belong to later issues.

---

# 13. Structure of the SQL Script

The script contains a descriptive header followed by database creation statements.

The header documents:

- script name
- purpose
- description
- execution
- safety
- dependencies

Comments are for humans and are not executed as SQL.

For example:

```sql
/*
This is documentation.
MySQL does not execute this comment.
*/
```

This makes the project easier to maintain.

---

# 14. Bronze Database Creation

The important statement is:

```sql
CREATE DATABASE IF NOT EXISTS retail_bronze
    CHARACTER SET utf8mb4;
```

Breakdown:

- `CREATE DATABASE` — tells MySQL to create a database.
- `retail_bronze` — the database name.
- `IF NOT EXISTS` — create it only if it does not already exist.
- `CHARACTER SET utf8mb4` — specifies the character encoding for text stored in the database.

---

# 15. Silver Database Creation

The script contains:

```sql
CREATE DATABASE IF NOT EXISTS retail_silver
    CHARACTER SET utf8mb4;
```

This creates the database representing the Silver layer.

The Silver layer will eventually contain cleaned and standardized data.

---

# 16. Gold Database Creation

The script contains:

```sql
CREATE DATABASE IF NOT EXISTS retail_gold
    CHARACTER SET utf8mb4;
```

This creates the database representing the Gold layer.

The Gold layer will eventually contain business-ready analytical data.

---

# 17. Why `IF NOT EXISTS` Was Used

Without `IF NOT EXISTS`:

```sql
CREATE DATABASE retail_bronze;
```

would produce an error if the database already existed.

With:

```sql
CREATE DATABASE IF NOT EXISTS retail_bronze;
```

the script can be executed again without attempting to recreate an existing database.

The important safety principle is:

```text
Existing database
       ↓
Do not destroy it
       ↓
Do not recreate it
```

---

# 18. Why We Did Not Use `DROP DATABASE`

We deliberately did not put:

```sql
DROP DATABASE retail_bronze;
```

into the normal initialization script.

`DROP DATABASE` is destructive because it removes the database and everything stored inside it.

For a professional project, a normal initialization script should not unexpectedly destroy existing data.

If a complete development reset is needed later, a separate explicitly destructive script can be created, for example:

```text
sql/setup/reset_databases.sql
```

That is separate from the normal initialization process.

---

# 19. Executing the SQL Script

After connecting to MySQL, the script was executed using:

```sql
SOURCE C:/Users/Rajan Thakur/OneDrive/Desktop/SQL/Data Warehouse/Data-warehouse-ETL-Pipeline/sql/setup/create_databases.sql;
```

`SOURCE` is a **MySQL command-line client command**.

It means approximately:

> Read this file and execute the commands contained in it.

The flow is:

```text
create_databases.sql
        ↓
SOURCE command
        ↓
MySQL Client
        ↓
SQL statements
        ↓
MySQL Server
        ↓
Databases created
```

---

# 20. Important: `SOURCE` vs SQL

There is an important distinction.

```sql
SOURCE create_databases.sql;
```

is a MySQL client command.

Whereas:

```sql
CREATE DATABASE retail_bronze;
```

is a SQL statement executed by the MySQL Server.

Similarly:

```sql
SELECT *
FROM customers;
```

is SQL.

The client accepts the command/statement, communicates with the server as appropriate, and displays the result.

---

# 21. What Actually Happened When the Script Was Executed?

The complete sequence was:

```text
PowerShell
    ↓
mysql -u root -p
    ↓
MySQL Command-Line Client
    ↓
MySQL Server connection
    ↓
mysql>
    ↓
SOURCE create_databases.sql
    ↓
Client reads SQL file
    ↓
SQL statements are executed
    ↓
MySQL Server creates databases
```

This is why the databases appeared even though MySQL Workbench was never opened.

---

# 22. Verification — Check That the Databases Exist

The following command was executed:

```sql
SHOW DATABASES LIKE 'retail_%';
```

`SHOW DATABASES` lists databases available to the MySQL Server.

The:

```sql
LIKE 'retail_%'
```

part filters the results to names matching the `retail_` pattern.

The result was:

```text
retail_bronze
retail_gold
retail_silver
```

This proved that all three databases were created.

---

# 23. What Is `information_schema`?

MySQL provides a special metadata database called:

```text
information_schema
```

It contains information about the database system, including metadata about:

- databases
- tables
- columns
- indexes
- other database objects

It is not our business-data warehouse.

For example:

```text
information_schema
        ↓
information ABOUT databases/tables
```

while:

```text
retail_bronze
        ↓
actual warehouse data
```

---

# 24. Checking Whether the Warehouse Is Empty

The following query was executed:

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

This is expected.

It means there are currently no matching tables in those databases.

The reason the result says `Empty set` rather than displaying three rows with zero is that the query starts from:

```text
information_schema.tables
```

and there are no matching table records to group.

Therefore:

```text
No tables found
        ↓
Empty set
```

This does NOT mean the databases do not exist.

We already verified that they exist using:

```sql
SHOW DATABASES LIKE 'retail_%';
```

---

# 25. Current Warehouse State

After this issue, the MySQL Server contains:

```text
MySQL Server
│
├── retail_bronze
│   └── 0 tables
│
├── retail_silver
│   └── 0 tables
│
└── retail_gold
    └── 0 tables
```

This is the intended result.

---

# 26. Why the Warehouse Is Empty

We have not analyzed the source systems yet.

Later, the source systems may contain things such as:

```text
CRM
├── customers
├── customer_addresses
└── customer_contacts

ERP
├── products
├── orders
├── order_items
└── inventory
```

But we should not assume the exact source structure before analyzing it.

Therefore, the current issue establishes only the target environment.

---

# 27. Future Warehouse Architecture

Eventually, the project will evolve toward something conceptually like:

```text
                 SOURCE SYSTEMS
                 /            \
               CRM            ERP
                │              │
                └──────┬───────┘
                       │
                       ▼
                  Python ETL
                       │
                       ▼
                MySQL Server
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
       BRONZE        SILVER        GOLD
          │            │            │
       Raw data     Cleaned       Analytics
```

Eventually Gold may contain objects such as:

```text
dim_customer
dim_product
dim_date
fact_sales
```

But those are **future implementation decisions**, not part of this issue.

---

# 28. MySQL Client Commands Learned

## Connect

```powershell
mysql -u root -p
```

General form:

```powershell
mysql -h HOST -P 3306 -u USER -p
```

Where:

```text
-h → host
-P → port
-u → username
-p → ask for password
```

## List databases

```sql
SHOW DATABASES;
```

## Filter databases

```sql
SHOW DATABASES LIKE 'retail_%';
```

## Select a database

```sql
USE retail_bronze;
```

## Check current database

```sql
SELECT DATABASE();
```

## List tables

```sql
SHOW TABLES;
```

## Inspect table structure

```sql
DESCRIBE customers;
```

or:

```sql
DESC customers;
```

## See exact table definition

```sql
SHOW CREATE TABLE customers;
```

## Execute a SQL file

```sql
SOURCE file.sql;
```

## Check version

From PowerShell:

```powershell
mysql --version
```

Inside MySQL:

```sql
SELECT VERSION();
```

## Check warnings

```sql
SHOW WARNINGS;
```

## Check current user

```sql
SELECT USER();
```

## Exit MySQL

```sql
EXIT;
```

or:

```sql
QUIT;
```

---

# 29. Important SQL Statements for Data Engineering

Not all commands typed at `mysql>` are technically MySQL client commands.

For example:

```sql
SELECT *
FROM customers;
```

is a SQL statement.

Frequently used SQL concepts include:

```text
SELECT
WHERE
GROUP BY
HAVING
ORDER BY
JOIN
CTE
WINDOW FUNCTIONS
INSERT
UPDATE
DELETE
CREATE TABLE
ALTER TABLE
DROP TABLE
```

The distinction is:

```text
MySQL Client
    │
    ├── Client commands
    │      └── SOURCE
    │
    └── SQL statements
           ├── SELECT
           ├── CREATE DATABASE
           ├── CREATE TABLE
           ├── INSERT
           └── etc.
```

---

# 30. `.venv` vs MySQL

The Python virtual environment:

```text
.venv/
```

was not responsible for creating these databases.

The database creation was performed through:

```text
mysql.exe
    ↓
MySQL Server
```

The Python environment will become important later when implementing the ETL pipeline.

Eventually:

```text
Python ETL
     │
     │ mysql-connector-python
     ▼
MySQL Server
     │
     ▼
retail_bronze
```

---

# 31. MySQL Client vs Python Connector

Another useful distinction:

```text
MySQL Command-Line Client
mysql.exe
```

is a command-line tool for humans and scripts.

Whereas:

```text
mysql-connector-python
```

is a Python library that allows Python code to connect to MySQL.

Conceptually:

```text
Human
  ↓
mysql.exe
  ↓
MySQL Server
```

versus:

```text
Python ETL
  ↓
mysql-connector-python
  ↓
MySQL Server
```

Both communicate with the same database server.

---

# 32. Why Workbench Was Not Needed

MySQL Workbench is simply another interface:

```text
                     MySQL Server
                    /      |       \
                   /       |        \
                  ↓        ↓         ↓
             mysql.exe  Workbench  Python
                CLI        GUI      Connector
```

The database server remains the central component.

For this issue, the command-line client was sufficient.

---

# 33. Useful Daily Data Engineering Investigation Workflow

A practical workflow could look like:

```sql
SHOW DATABASES;

USE retail_bronze;

SHOW TABLES;

DESC customer;

SELECT COUNT(*)
FROM customer;

SELECT *
FROM customer
LIMIT 10;
```

This means:

```text
1. What databases exist?
        ↓
2. Which database am I using?
        ↓
3. What tables exist?
        ↓
4. What does the table look like?
        ↓
5. How many rows exist?
        ↓
6. Show me a small sample.
```

This type of workflow is useful during source analysis, ETL development, and debugging.

---

# 34. Why `LIMIT` Is Useful

When inspecting large tables, avoid immediately running:

```sql
SELECT *
FROM huge_table;
```

Instead:

```sql
SELECT *
FROM huge_table
LIMIT 10;
```

This allows you to inspect a small sample without requesting the entire table.

---

# 35. What Was Actually Completed in This Issue?

## Completed

```text
✓ MySQL installation verified
✓ MySQL command-line client verified
✓ MySQL Server connection verified
✓ create_databases.sql prepared
✓ Bronze database created
✓ Silver database created
✓ Gold database created
✓ Database existence verified
✓ Warehouse table count checked
✓ Confirmed no warehouse tables exist yet
```

## Not done yet

```text
✗ Source-system analysis
✗ Bronze tables
✗ Bronze loading
✗ Silver transformations
✗ Gold dimensions
✗ Gold facts
✗ ETL automation
✗ Data quality framework
```

These belong to later issues.

---

# 36. Final Mental Model

The most important thing to remember from this issue is:

```text
                 YOUR PROJECT
                      │
             create_databases.sql
                      │
                      │ SOURCE
                      ▼
               MySQL Client
                mysql.exe
                      │
                      │ SQL
                      ▼
               MySQL Server
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
   retail_bronze retail_silver retail_gold
          │           │           │
        EMPTY       EMPTY       EMPTY
```

The `.sql` file is the **instruction file**.

The MySQL Client is the **interface used to send/execute those instructions**.

The MySQL Server is the **system that actually creates and manages the databases and data**.

MySQL Workbench is simply an **optional graphical interface** to the same server.

---

# 37. Git Closeout

After final verification, inspect the changes:

```powershell
git status
```

Then:

```powershell
git diff
```

If the SQL file is the intended change:

```powershell
git add sql/setup/create_databases.sql
```

Review:

```powershell
git diff --cached
```

Commit:

```powershell
git commit -m "feat(setup): initialize warehouse databases"
```

Push:

```powershell
git push origin 6-initialize-data-warehouse-foundation
```

Then create a Pull Request from:

```text
6-initialize-data-warehouse-foundation
```

into:

```text
develop
```

---

# 38. One-Sentence Interview Explanation

> **I initialized the MySQL data warehouse foundation by creating separate Bronze, Silver, and Gold databases, verified them through the MySQL command-line client, and intentionally left them empty so that the warehouse structure can be designed after analyzing the source systems.**

---

# 39. Issue Completion Checklist

- [x] Warehouse databases created.
- [x] Bronze database exists.
- [x] Silver database exists.
- [x] Gold database exists.
- [x] Databases use the intended naming convention.
- [x] Databases are intentionally empty.
- [x] No source data has been loaded.
- [x] No Bronze/Silver/Gold tables have been prematurely created.
- [x] Database creation was verified from the MySQL client.
- [x] MySQL Server and MySQL Client roles are understood.
- [x] `SOURCE` command is understood.
- [x] Basic MySQL CLI workflow is understood.
